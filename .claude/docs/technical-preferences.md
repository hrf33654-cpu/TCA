# Technical Preferences

<!-- `project.yaml` at the repository root is the machine-readable source of truth for engine, specialists, naming, performance, platform, and testing.framework. This document is the human-readable CCGS legacy mirror and fallback. `project.yaml` takes precedence when a value is present there. Forbidden patterns and allowed libraries are maintained here. -->

## Engine & Language

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Rendering**: Forward+
- **Physics**: Godot Physics 2D

## Input & Platform

- **Target Platforms**: PC (Steam / Epic)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial
- **Touch Support**: None
- **Platform Notes**: PC is the target platform. Keyboard and mouse are primary, and every critical operation must be reachable with keyboard and mouse. Gamepad support is partial; touch input is unsupported.

## Naming Conventions

- **Classes**: PascalCase
- **Variables / Functions**: snake_case
- **Signals / Events**: past-tense snake_case
- **Files**: snake_case
- **Scenes / Prefabs**: snake_case
- **Constants**: SCREAMING_SNAKE_CASE

## Performance Budgets

These are provisional prototype targets and should be revisited with profiling evidence.

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: Maximum 1,000 2D draw calls
- **Memory Ceiling**: 2 GB runtime memory

## Testing

- **Framework**: gdUnit4 6.2.1
- **Minimum Coverage**: To be decided
- **Required Tests**: Battle logic, content validation, and critical keyboard/mouse flows. Add networking tests only if multiplayer is introduced.

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- gdUnit4 v6.2.1 — Godot automated test framework and runner.

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-specialist
- **Additional Specialists**: godot-gdextension-specialist
- **Routing Notes**: Use the Godot specialist for engine-level integration and UI work; route GDScript gameplay code, shaders, and native extensions to their dedicated specialists.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.gd` gameplay code | godot-gdscript-specialist |
| `.gdshader` shader / material code | godot-shader-specialist |
| Godot UI screens and controls | godot-specialist |
| `.tscn` scenes and `.tres` resources | godot-specialist |
| GDExtension / native plugin code | godot-gdextension-specialist |
| General architecture review | godot-specialist |