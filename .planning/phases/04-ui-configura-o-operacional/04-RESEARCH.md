# Phase 04 Research: UI + Configuração Operacional

## Domain Investigation
- **UI System**: The current `components/ui.lua` renders the whole screen on every tick (`term.clear()`), which causes flicker. It also blindly paginates using `os.epoch` mod math.
- **Engine State**: `engine.lua` maintains `state.requests` and `self.work`. For substitutions, it checks if `chosen ~= reqItem`.
- **Mapping CLI**: `modules/mapping_cli.lua` is a rudimentary command-line script. It needs to become an interactive TUI.
- **Hot Reloading**: Currently, `Engine` loads `Equivalence` once. To support hot reloading without restarting, we need `Equivalence` to detect file changes (e.g., via `fs.attributes`) or expose a `reload()` method called by the main loop.

## Architectural Patterns
1. **Diff-based Rendering (Double Buffering)**:
   Instead of `term.clear()`, the UI should maintain a buffer of characters and colors, compare it with the previous frame, and only write the differences using `term.setCursorPos`, `term.blit`, or `term.write`.
2. **Event Loop for UI**:
   The `startup.lua` main loop should pass `os.pullEventRaw()` events to the UI so it can handle touch/clicks for pagination and filters.
3. **Interactive TUI for Editor**:
   The editor needs a state machine (menu -> select item -> edit equivalents -> save).

## Validation Architecture
- **UI Responsiveness**: Tested by resizing the monitor or using monitors of different scales.
- **Flicker-free**: Tested by observing the monitor during fast updates.
- **Mapping Hot Reload**: Edit mappings via the new editor, save, and verify that the next engine cycle uses the new mappings without restarting the computer.

## RESEARCH COMPLETE
