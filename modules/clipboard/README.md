# Clipboard picker

Search clipboard history in the left pane and preview the selected image or
text in the right pane. The picker uses the shared dialog, palette, and font.
`services/ClipboardHistory.qml` handles cliphist reads, previews, restoration,
Hyprland paste dispatch, and error notifications.

Start these commands once in the Wayland session to collect history:

```sh
wl-paste --type text --watch cliphist store
wl-paste --type image --watch cliphist store
```

Bind `quickshell ipc call clipboard toggle` to a compositor shortcut. The
`clipboard` IPC target also exposes `open` and `close`.

Type to filter history, then use arrow keys or `Ctrl+J` / `Ctrl+K` to select an
entry. Press `Enter` or double-click to restore its original contents and paste
into the window that was focused before opening the picker. The dialog closes
before Hyprland sends `Ctrl+V`, or `Ctrl+Shift+V` for applications whose desktop
entry includes the `TerminalEmulator` category. `Ctrl+R` refreshes
history; `Esc` or a click outside the dialog closes it without pasting.

Images fit the preview pane while retaining their aspect ratio. Previews stay
in memory; long text previews are limited to 32,768 characters, while copying
always restores the complete entry. Run `cliphist wipe` to clear stored history.
