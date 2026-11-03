#!/usr/bin/env python3
"""Print stacks from stacks.yaml as TSV: name, path, compose file, tier, enabled.
Usage: bin/stacks.py [--all] [name ...]   (default: enabled stacks only, tier order)
Needs PyYAML (python3-yaml)."""
import sys, os, yaml
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
data = yaml.safe_load(open(os.path.join(root, "stacks.yaml")))
args = [a for a in sys.argv[1:] if a != "--all"]
show_all = "--all" in sys.argv
for s in sorted(data.get("stacks", []), key=lambda s: (s.get("tier", 1), s["name"])):
    if args and s["name"] not in args: continue
    if not show_all and not args and not s.get("enabled", True): continue
    print("\t".join([s["name"], os.path.join(root, s["path"]), s["compose"], str(s.get("tier", 1)), str(s.get("enabled", True)).lower()]))
