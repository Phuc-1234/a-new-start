---
trigger: always_on
---

This project is a Godot 4 game.

Requirements:
- Use GDScript only, do not use C#.
- Explain architecture before generating large amounts of code.
- Decoupling / node traversal constraints: Enforce "signal up, call down"; prohibit hardcoded absolute `get_node()` paths across subsystem boundaries (e.g., between `src/player/` and `src/world/`).
- Architecture map requirement: Consult `ARCHITECTURE.md` before making major changes (large features, cross-subsystem interactions, structural refactors). Check and update `ARCHITECTURE.md` whenever changes modify system boundaries, data flow, or scene hierarchy.
- Godot CLI command: Use `Godot_v4.7.2-stable_win64_console.exe` (do not use the GUI binary or `godot`).
- Validate changes headlessly via CLI when making code changes:
  - Script syntax: `Godot_v4.7.2-stable_win64_console.exe --headless --check-only -s <script>`
  - Scene/runtime check: `Godot_v4.7.2-stable_win64_console.exe --headless --quit-after 10`
  - Asset/import check: `Godot_v4.7.2-stable_win64_console.exe --editor --headless --quit`