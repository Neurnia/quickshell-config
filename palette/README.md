# Quickshell palette contract

Quickshell watches its cache path `palette.json` for a generated Material palette.
Use `quickshell ipc call palette path` to print the exact output path for this
configuration.

The generated document must:

- use schema version `1`;
- set `mode` to `dark` or `light`;
- provide every color role shown in `example.json` (additional roles are allowed);
- encode opaque colors as six-digit hexadecimal strings.

If the file is missing, malformed, incomplete, or unsupported, Quickshell keeps
using `services/FallbackPalette.qml`. Surface transparency is applied later by
`services/Colors.qml` and must not be included in generated colors.

The future Matugen template should provide at least the structure in `example.json`.
Its final output should replace `palette.json` atomically so Quickshell never
observes a partially written document.

Useful diagnostics:

```sh
quickshell ipc call palette status
quickshell ipc call palette reload
```
