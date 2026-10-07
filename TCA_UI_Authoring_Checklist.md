# TCA UI Authoring Checklist

## BattlePrototype Scene

- `BattleManager` must have `BattlePrototypeController`.
- `BattlePrototypeController` must bind:
  - `cardViewPrefab`
  - `canvas`
  - `handContent`
  - `reactionLeftView`
  - `reactionRightView`
  - `reactionLeftZone`
  - `reactionRightZone`
  - `inspectView`
  - `enemyInfoText`
  - `playerInfoText`
  - `logText`
  - `turnText`
  - `reactionPreviewText`
  - `reactButton`
  - `clearReactionButton`
  - `endTurnButton`
  - `closeInspectButton`
  - `inspectPanel`
- `dropZones` must include:
  - enemy target zone
  - player target zone
  - reaction left zone
  - reaction right zone
- The scene must contain an `EventSystem`.
- All TMP text nodes must have a valid font asset.
- `ReactionLeft`, `ReactionRight`, and `InspectCard` should host a fully bound `CardView` instance instead of an empty shell component.

## CardView Prefab

- `CardView` must have all serialized visual bindings assigned.
- Root frame image must use the card frame sprite.
- `ArtRoot` must use the art frame sprite.
- `InfoBar` must use the info frame sprite.
- `CostBubble` must use the cost bubble sprite.
- All TMP text nodes must have a shared font asset and material.

## Addressables

- Run `TCA Tools/Sync Addressables` after changing art assets.
- Required groups:
  - `TCA UI`
  - `TCA Card Art`
  - `TCA Intro`
  - `TCA Battle`
- Every `CardDefinition.artAddress` must exist in Addressables.
- Core UI keys and intro/background keys must exist in Addressables before shipping.

## Validation Workflow

- Run `TCA Tools/Validate UI Setup` before committing UI changes.
- If the editor is already open in another instance, run the validation and upgrade menus from that active editor session instead of a second editor process.
