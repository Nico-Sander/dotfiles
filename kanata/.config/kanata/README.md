# Kanata

Colemak with homerow mods and German special characters, for Ubuntu and Windows 11.
Requires **kanata v1.12.0 or newer**. Older versions can't read this config.

| File | What it is |
|------|------------|
| `kanata.kbd` | The config. The header comment lists every mapping. |
| `sync-kanata.sh` | Checks the config, copies it to `/etc/kanata` and restarts the service (Ubuntu). |
| `toggle-kanata.sh` | Starts or stops the kanata service (Ubuntu). |
| `plan.md` | Improvements that haven't been tried yet. |

## Quick reference

| Keys | Result |
|------|--------|
| hold `a` / `r` / `s` / `t` | meta / alt / shift / ctl |
| hold `n` / `e` / `i` / `o` | ctl / shift / alt / meta |
| ctl + `o` / `'` / `[` / `]` | ö / ä / ü / ß |
| ctl + shift + `o` / `'` / `[` | Ö / Ä / Ü |
| Caps Lock | Esc |
| hold LCtrl + Space + Esc | Emergency exit: stops kanata |

A homerow mod only counts when you press **and release** a key on the other hand while holding it.
Same-hand combos type letters, so for Ctrl+C use `n` + `c`, not `t` + `c`.

## Keyboard layout

kanata sends US QWERTY key codes and does the Colemak remapping itself.
So the OS layout must be US, **not** Colemak or German.

| OS | Layout |
|----|--------|
| Ubuntu | **English (US, intl., with AltGr dead keys)**, xkb name `us+altgr-intl` |
| Windows 11 | **US** (plain QWERTY). Don't use "United States-International": it turns `'` `"` `` ` `` `~` `^` into dead keys. |

On Ubuntu the umlauts are produced by the layout (AltGr + q/p/y/s), so they work in every app, including WezTerm.
On Windows kanata types them as unicode characters, which works without a special layout.

---

## 1. Fresh setup

### Ubuntu

1. Clone the dotfiles and run the populate script. It links this folder to `~/.config/kanata/`,
   and if kanata isn't installed yet it runs `scripts/install-kanata.sh` (asks for sudo):
   ```sh
   git clone https://github.com/Nico-Sander/dotfiles.git ~/workspace/github.com/Nico-Sander/dotfiles
   cd ~/workspace/github.com/Nico-Sander/dotfiles
   ./populate.sh
   ```
   The install script creates a `kanata` system user and a udev rule. It also downloads and
   checksum-verifies kanata, and sets up the hardened `kanata.service`.

2. Set the keyboard layout. Either go to *Settings → Keyboard → Input Sources → Add*,
   pick *English (US, intl., with AltGr dead keys)* and move it to the top, or run:
   ```sh
   gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us+altgr-intl')]"
   ```
   Add other layouts to the list if you want them, e.g. `('xkb', 'de')`.

3. Reboot so the udev rule takes effect, then check:
   ```sh
   systemctl status kanata.service
   ```

### Windows 11

> The Windows part of the config passes kanata's config check but hasn't been tested on a Windows machine yet.

1. Set the layout: *Settings → Time & language → Language & region → English (United States) → Language options → Keyboards*.
   Add **US** and remove "United States-International" if present.
   If you also have German installed, make sure US is active while kanata runs.

2. Download kanata and the config (PowerShell, as a normal user):
   ```powershell
   $dir = "$env:USERPROFILE\kanata"
   New-Item -ItemType Directory -Force $dir | Out-Null
   Invoke-WebRequest https://github.com/jtroo/kanata/releases/download/v1.12.0/windows-binaries-x64.zip -OutFile "$env:TEMP\kanata.zip"
   Expand-Archive "$env:TEMP\kanata.zip" "$env:TEMP\kanata" -Force
   Copy-Item "$env:TEMP\kanata\kanata_windows_gui_winIOv2_x64.exe" "$dir\kanata.exe" -Force
   Invoke-WebRequest https://raw.githubusercontent.com/Nico-Sander/dotfiles/main/kanata/.config/kanata/kanata.kbd -OutFile "$dir\kanata.kbd"
   ```
   `gui_winIOv2` is the tray-icon build that needs no extra driver.
   The `cmd_allowed` builds aren't needed, because the config runs no shell commands.

3. Start it automatically at login with a shortcut in the Startup folder:
   ```powershell
   $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Startup'))\kanata.lnk")
   $lnk.TargetPath = "$dir\kanata.exe"
   $lnk.Arguments = "--cfg `"$dir\kanata.kbd`""
   $lnk.WorkingDirectory = $dir
   $lnk.Save()
   ```
   Then double-click the shortcut once, or log out and back in. kanata runs as a tray icon.

   Note: winIOv2 can't remap keys inside windows running as administrator unless kanata itself runs as administrator.

---

## 2. Updating a machine that runs the old config

The old config ran on kanata v1.9.0 and used Ctrl + o/'/[/] with unicode for umlauts.
The new config needs **v1.12.0**, so update the binary **before** the config.
`sync-kanata.sh` refuses to install a config the running kanata can't read.

### Ubuntu

1. Pull the dotfiles and link the new files (`sync-kanata.sh`, this README):
   ```sh
   cd ~/workspace/github.com/Nico-Sander/dotfiles
   git pull
   stow --no-folding --target="$HOME" kanata
   ```

2. Install kanata v1.12.0. This also copies the new config to `/etc/kanata` and restarts the service:
   ```sh
   sudo bash scripts/install-kanata.sh
   ```
   It checks the config with the new binary before it replaces the old one.
   If anything fails, the old kanata keeps running.

3. Switch the layout from `us` to `us+altgr-intl` (keeps your other input sources):
   ```sh
   gsettings get org.gnome.desktop.input-sources sources
   # replace ('xkb', 'us') with ('xkb', 'us+altgr-intl') in that list, e.g.:
   gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us+altgr-intl'), ('xkb', 'us+colemak'), ('xkb', 'de')]"
   ```
   Without this step, ctl + o and the other umlaut keys type the wrong characters.

4. Test: type a few words, try ctl + o → ö and ctl + shift + o → Ö, also in the terminal.

From now on, after editing `kanata.kbd`, just run:
```sh
~/.config/kanata/sync-kanata.sh
```

### Windows 11

1. Quit kanata (right-click the tray icon → Exit).
2. Run step 2 of the [fresh Windows setup](#windows-11). It overwrites `kanata.exe` and `kanata.kbd`.
   If your old exe lived somewhere else (e.g. `kanata_gui_cmd_allowed.exe`), delete it and
   point your startup shortcut at the new one (step 3).
3. Keep the layout on **US**. Nothing changes there.
4. Start kanata again and test ctl + o → ö and ctl + shift + o → Ö.

## Troubleshooting (Ubuntu)

- Logs: `journalctl -u kanata.service -n 50`
- Check the config by hand: `sudo /usr/local/bin/kanata --check --cfg ~/.config/kanata/kanata.kbd`
- Keyboard acting strange: hold LCtrl + Space + Esc to stop kanata, then use `toggle-kanata.sh` to start it again.
