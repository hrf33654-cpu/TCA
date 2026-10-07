# TCA — CCGS Legacy Project Reference

This project-specific reference supports CCGS workflows that still read `CLAUDE.md`. It is a legacy mirror; `project.yaml` is the machine-readable source of truth for project configuration.

## Project Context

TCA is a 2D card battler themed around chemical elements. The existing Unity project, its C# gameplay prototype, scenes, and source assets are the migration baseline. Preserve that Unity baseline while building and validating the Godot version; do not treat the Godot setup as authorization to remove or overwrite Unity project files.

## Technology Stack

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Version Control**: Git
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: engine-specific reference path for the pinned Godot version. -->
@docs/engine-reference/godot/VERSION.md

## Configuration Ownership

`project.yaml` at the repository root is the primary configuration source. `.claude/docs/technical-preferences.md` is the human-readable CCGS legacy mirror and fallback for workflows that still require that document. When the two disagree, use `project.yaml` and reconcile the mirror as part of the relevant configuration change.

This document contains only project context and the engine-version reference. It does not import or depend on template documentation paths that are not present in this repository.

## Migration Context

The Unity project remains the behavioral and content baseline during migration. Port gameplay rules and assets deliberately, record behavior differences, and establish Godot parity before proposing a Unity cutover. The approved migration plan is maintained separately under `docs/migration/`.