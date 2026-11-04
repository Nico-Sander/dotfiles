# Kanata: ideas not yet implemented or tried

Rough order: most useful first. Each item says what to change in `kanata.kbd` (or elsewhere).

## Layout and layers

### 1. Thumb layers (the old TODO)
The thumbs only press space right now.
- **Space: tap = space, hold = navigation/symbol layer.** Arrows on `n e i o` (h j k l style),
  Home/End/PgUp/PgDn nearby, brackets and other symbols on the left hand.
  Use `tap-hold-release` or `tap-hold-opposite-hand-release` so fast typing never triggers it.
  Then remove `spc` from the `neutral-keys` of the homerow templates, or keep it neutral there
  and just give space its own tap-hold.
- **Number layer** (e.g. hold right alt or a second thumb key): numbers on the homerow,
  so you don't have to reach for the top row.

### 2. Caps Lock: tap = Esc, hold = Ctrl (or a layer)
Currently Caps is just Esc. A hold action would give a non-homerow Ctrl for left-hand
shortcuts like Ctrl+C / Ctrl+V. That would remove the main downside of the opposite-hand rule.

### 3. Combos (`defchordsv2`)
Pressing two neighbouring keys at once for Esc, Enter, Backspace or Tab.
`concurrent-tap-hold yes` is already set, which chords v2 requires.
Needs tuning so fast rolls don't trigger them.

## Homerow mod tuning

### 4. Same-hand shortcuts
Right now a same-hand key always types letters (`t` + `c` → "tc").
If using the other hand's Ctrl gets annoying, try `(same-hand ignore)` in the templates.
Same-hand keys would then decide only by release order and timeout, like the original config.
Expect a few more misfires on rolls.

### 5. More keys you hit with both hands
`b` is in no hand (in `defhands`), so both shifts capitalize it.
Do the same for any other key you hit with either hand, e.g. `g` (physical `t`) or `h` (physical `h`).

### 6. Watch the side effect of `(unknown-hand hold)`
Numbers, Enter, Backspace and Tab now act like other-hand keys for every homerow mod.
If that causes misfires (e.g. "s1" → "!"), either put the number row into `defhands`
or add those keys to `neutral-keys`.

### 7. Timing
Current values: shift/ctl 220 ms, alt/meta 260 ms, `require-prior-idle` 150 ms (off for shift).
Ideas:
- Give shift a small prior-idle (e.g. 50–80 ms) instead of 0, if mid-word shift misfires show up.
- Lower ctl's prior-idle if shortcuts right after typing feel blocked.
- Try `tap-hold-order` (decides purely by which key is released first, no timeout) on one key and compare.

## Setup and scripts

### 8. `populate.sh` should set the keyboard layout
It doesn't set the GNOME input source yet. Add a `gsettings set org.gnome.desktop.input-sources sources ...`
step that puts `us+altgr-intl` first, so a fresh machine doesn't need the manual step.

### 9. `populate.sh` should upgrade kanata
It only runs `install-kanata.sh` when kanata is missing.
Compare `kanata --version` with `KANATA_VERSION` from the install script and upgrade when they differ.

### 10. `Restart=on-failure` in `kanata.service`
Currently `Restart=no`. With `on-failure`, a crash restarts kanata automatically.
The emergency exit (LCtrl+Space+Esc) exits with code 0, so it still stops kanata for good.

### 11. Toggle and sync without typing a password
`toggle-kanata.sh` and `sync-kanata.sh` need sudo or a polkit prompt.
A small polkit rule (or sudoers entry) for `systemctl start/stop/restart kanata.service`
would make them one-keypress actions, e.g. bound to a GNOME keyboard shortcut.

## Windows

### 12. Test the Windows side for real
The Windows umlaut block only passed `kanata --check`. Things to verify:
- ctl + o → ö: the unicode character is sent while ctl is held. Some apps might see a ctl shortcut.
  If so, find a way to release ctl first (`unmod` only takes plain keys, not unicode).
- ctl + shift + o → Ö (the `switch` on shift).
- Homerow mods in elevated (admin) windows: winIOv2 can't see them unless kanata runs as admin.
  Try running it elevated via Task Scheduler, or the `wintercept` build (needs the Interception driver).

### 13. Windows install script
A small PowerShell script in `scripts/` that does the README's Windows steps
(download, verify checksum, copy config, create the startup shortcut).
