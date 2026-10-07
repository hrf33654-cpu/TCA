# Godot battle fixture data

This directory contains only Godot runtime resources for the migration battle
fixture. It is deliberately separate from Unity's case-insensitive `Assets/`
tree, which is isolated from Godot import by `Assets/.gdignore`.

- `cards/*.tres` are static `CardDefinition` resources. Runtime card instances
  and their mutable state are created in the domain layer.
- `reactions/*.tres` are unordered element-card recipe resources.
- The resources carry `prototype_fixture` or `migration_temp` status. They are
  an executable fixture baseline, not approved final balance or chemistry.
- Reaction records are marked `scientific_review_status = unreviewed`. The
  game recipe abstraction must not be read as a balanced chemical equation.
- New effect types require a matching domain implementation and content tests;
  unknown effects and orphan recipe references fail catalog validation.

The application loader reads these resources through Godot's `ResourceLoader`.
Domain rules receive the validated in-memory catalog and do not read files.
