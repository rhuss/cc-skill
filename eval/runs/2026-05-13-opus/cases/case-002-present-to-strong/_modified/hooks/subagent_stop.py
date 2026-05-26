#!/usr/bin/env python3
import json, sys, shutil, os
d = json.load(sys.stdin)
p = d.get('agent_transcript_path', '')
dest = '/private/var/folders/3v/16m6pn090hl4d60grm1057ww0000gn/T/agent-eval/2026-05-13-opus/cases/case-002-present-to-strong/subagents'
if p and os.path.isfile(p) and not os.path.islink(p):
    os.makedirs(dest, exist_ok=True)
    shutil.copy2(p, os.path.join(dest, os.path.basename(p)))
