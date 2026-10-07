# Godot Runtime Assets

This directory is the Godot-owned runtime asset root (`res://godot_assets/`). It is deliberately distinct from Unity's existing `Assets/` directory. Windows treats `assets` and `Assets` as the same path, and the Unity tree contains `.gdignore` to keep Unity source files out of Godot imports.

- Store Godot card/character/reaction data under `data/`.
- Store approved/generated game art under `characters/`, `backgrounds/`, `ui/`, and `vfx/`.
- Do not put Godot runtime files under Unity's `Assets/`.
- Legacy images in `Assets/art/` are quarantined audit copies. They are not runtime resources and must not be referenced or included in Godot builds.

Generated image provenance and review status is tracked in [`production/art/asset-provenance.md`](../production/art/asset-provenance.md).
