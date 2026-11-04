#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Migrate legacy `scene_data` payloads into the field the engine actually reads: `scene`.

The Godot stages (LabStage / Lab3DStage / SequenceStage) read `s.get("scene", {})`
and require it to be a Dictionary. Older generated content stored the payload in
`scene_data`, which no runtime code reads, so those "explore" questions were not
interactive at all. This script renames the key in place.

Special case: some levels use `scene` as a scene-path string (e.g.
"res://scenes/LabStage.tscn") while carrying the payload in `scene_data`.
For those the payload wins.
"""
import glob
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

DATA = r'E:\MathGates-main\data'

renamed = 0
overwritten = 0
files = 0
for path in sorted(glob.glob(os.path.join(DATA, '*_levels.json'))):
    data = json.load(open(path, 'r', encoding='utf-8'))
    changed = False
    for sec in data.values():
        if not isinstance(sec, dict):
            continue
        for q in sec.get('levels', []):
            if not isinstance(q, dict) or 'scene_data' not in q:
                continue
            payload = q['scene_data']
            if not isinstance(payload, dict):
                continue
            if isinstance(q.get('scene'), str):
                overwritten += 1
            q['scene'] = payload
            del q['scene_data']
            renamed += 1
            changed = True
    if changed:
        files += 1
        json.dump(data, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

print(f"files changed : {files}")
print(f"scene_data -> scene : {renamed}")
print(f"overwrote scene-path string : {overwritten}")
