#!/usr/bin/env bash
# Read-only Docker host audit. Runs on the Docker host itself (locally, via
# `ssh host 'bash -s' < docker-audit.sh`, or pasted into any remote-shell tool).
# Changes nothing.
#
#   docker-audit.sh [section ...]
#
# Sections (default: all): host engine containers watchtower autostart disk
# Output: one "### <section>" header per section, then that section's lines.
# Container records are one JSON object per line.
# Every docker call is wrapped in a timeout so a wedged daemon cannot hang it.
set -uo pipefail

T="${DOCKER_AUDIT_TIMEOUT:-30}"
d() { timeout "$T" docker "$@"; }
SECTIONS=("$@")
[[ ${#SECTIONS[@]} -eq 0 ]] && SECTIONS=(host engine containers watchtower autostart disk)

host() {
  echo "hostname: $(hostname)"
  echo "os: $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
  echo "kernel: $(uname -r)"
  echo "nproc: $(nproc)"
  echo "loadavg: $(cut -d' ' -f1-3 /proc/loadavg)"
  echo "uptime: $(uptime -p 2>/dev/null)"
  free -h | awk 'NR<=3'
}

engine() {
  echo "server_version: $(d version --format '{{.Server.Version}}' 2>&1)"
  echo "client_version: $(d version --format '{{.Client.Version}}' 2>/dev/null)"
  echo "compose_version: $(d compose version --short 2>/dev/null || echo none)"
  echo "docker_root: $(d info --format '{{.DockerRootDir}}' 2>/dev/null)"
  echo "storage_driver: $(d info --format '{{.Driver}}' 2>/dev/null)"
  echo "logging_driver: $(d info --format '{{.LoggingDriver}}' 2>/dev/null)"
  echo "live_restore: $(d info --format '{{.LiveRestoreEnabled}}' 2>/dev/null)"
  echo "rootless: $(d info --format '{{range .SecurityOptions}}{{.}} {{end}}' 2>/dev/null | grep -q rootless && echo yes || echo no)"
  echo "docker_cli_path: $(command -v docker)"
  if [[ -d /etc/apt ]]; then
    echo "os_codename: $(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}")"
    grep -rhsE 'download\.docker\.com' /etc/apt/sources.list /etc/apt/sources.list.d/ \
      | grep -oE '(Suites: *[a-z]+|linux/ubuntu +[a-z]+|linux/debian +[a-z]+)' | sed 's/^/docker_apt_suite: /' \
      | grep . || echo "docker_apt_suite: none (no download.docker.com apt source)"
  fi
  if command -v apt-cache >/dev/null; then
    for p in docker-ce docker-ce-cli containerd.io docker-compose-plugin docker.io; do
      apt-cache policy "$p" 2>/dev/null | awk -v p="$p" '/Installed:/{i=$2} /Candidate:/{c=$2} END{if(i!="" && i!="(none)") print "apt " p ": installed=" i " candidate=" c}'
    done
  fi
  command -v snap >/dev/null && snap list docker 2>/dev/null | awk 'NR==2{print "snap docker: " $2}'
  [[ -f /etc/docker/daemon.json ]] && { echo "daemon.json:"; sed 's/^/  /' /etc/docker/daemon.json; } || echo "daemon.json: absent"
}

containers() {
  local ids; ids=$(d ps -aq)
  [[ -z "$ids" ]] && { echo "(no containers)"; return; }
  # shellcheck disable=SC2086
  d inspect --format '{"name":{{json .Name}},"image":{{json .Config.Image}},"image_id":{{json .Image}},"state":{{json .State.Status}},"health":{{if .State.Health}}{{json .State.Health.Status}}{{else}}null{{end}},"started_at":{{json .State.StartedAt}},"restart_policy":{{json .HostConfig.RestartPolicy.Name}},"restart_count":{{.RestartCount}},"compose_project":{{json (index .Config.Labels "com.docker.compose.project")}},"compose_working_dir":{{json (index .Config.Labels "com.docker.compose.project.working_dir")}},"compose_files":{{json (index .Config.Labels "com.docker.compose.project.config_files")}},"watchtower_enable":{{json (index .Config.Labels "com.centurylinklabs.watchtower.enable")}},"mounts":[{{range $i, $m := .Mounts}}{{if $i}},{{end}}{"type":{{json $m.Type}},"name":{{json $m.Name}},"source":{{json $m.Source}},"dest":{{json $m.Destination}},"rw":{{$m.RW}}}{{end}}],"declared_volumes":{{json .Config.Volumes}}}' $ids
}

watchtower() {
  local ids; ids=$(d ps -a --format '{{.ID}} {{.Image}} {{.Names}}' | awk 'tolower($0) ~ /watchtower/ {print $1}')
  [[ -z "$ids" ]] && { echo "installed: no"; return; }
  echo "installed: yes"
  for id in $ids; do
    d inspect --format 'container: {{.Name}}
image: {{.Config.Image}}
state: {{.State.Status}} since {{.State.StartedAt}}
restart_policy: {{.HostConfig.RestartPolicy.Name}}
cmd: {{join .Config.Cmd " "}}
compose_working_dir: {{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$id"
    local img; img=$(d inspect --format '{{.Image}}' "$id")
    echo "image_created: $(d image inspect --format '{{.Created}}' "$img" 2>/dev/null)"
    echo "image_version_label: $(d image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$img" 2>/dev/null)"
    echo "repo_digest: $(d image inspect --format '{{join .RepoDigests " "}}' "$img" 2>/dev/null)"
    echo "env (WATCHTOWER_*, secrets masked):"
    d inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$id" \
      | grep -E '^(WATCHTOWER_|TZ=|DOCKER_)' \
      | sed -E 's/^([^=]*(TOKEN|PASS|SECRET|KEY|URL)[^=]*)=.*/\1=<masked>/I; s/^/  /'
    echo "log (update activity, last 30 days, newest last):"
    d logs --since 720h "$id" 2>&1 \
      | grep -Ei 'found new|session (done|completed)|level=(warn|error|fatal)|error|fail|unable|scheduling' \
      | tail -40 | sed 's/^/  /'
  done
}

autostart() {
  if command -v systemctl >/dev/null; then
    for u in docker.service docker.socket containerd.service; do
      echo "systemd $u: enabled=$(systemctl is-enabled "$u" 2>/dev/null || true) active=$(systemctl is-active "$u" 2>/dev/null || true)"
    done
    systemctl --user is-enabled docker.service >/dev/null 2>&1 && echo "systemd --user docker.service: enabled=$(systemctl --user is-enabled docker.service)"
    echo "systemd units that start docker/compose:"
    grep -lsE 'docker( |-)compose|docker (run|start)' /etc/systemd/system/*.service "$HOME"/.config/systemd/user/*.service 2>/dev/null | sed 's/^/  /' || true
  fi
  echo "crontab @reboot docker entries:"
  { crontab -l 2>/dev/null; cat /etc/crontab /etc/cron.d/* 2>/dev/null; } | grep -E '@reboot.*docker' | sed 's/^/  /' || true
  echo "restart policies:"
  d ps -aq | xargs -r timeout "$T" docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' | sort | uniq -c | sed 's/^/  /'
}

disk() {
  # `docker system df` sizes every volume and can take minutes on a busy host.
  timeout "${DOCKER_DF_TIMEOUT:-150}" docker system df \
    || echo "docker system df: timed out after ${DOCKER_DF_TIMEOUT:-150}s"
  local root; root=$(d info --format '{{.DockerRootDir}}' 2>/dev/null)
  [[ -n "$root" ]] && df -h "$root" | sed 's/^/  /'
  echo "dangling images: $(d images -f dangling=true -q | wc -l)"
  echo "dangling volumes: $(d volume ls -f dangling=true -q | wc -l)"
  echo "exited containers: $(d ps -a -f status=exited -q | wc -l)"
}

for s in "${SECTIONS[@]}"; do
  echo "### $s"
  "$s" 2>&1
  echo
done
