<div align="center">

# ✦ Runeforge

**A heavily customized fork of**
[illogical-impulse](https://github.com/end-4/dots-hyprland) by [@end-4](https://github.com/end-4)

Refined, reforged, and repeatedly repaired.

</div>

---

## ✦ Overview

Runeforge is a personal customization layer built on top of the
[illogical-impulse](https://github.com/end-4/dots-hyprland) ecosystem.

This fork focuses on:

* deeper Quickshell customization
* workflow improvements fueled by repeated annoyance
* recovery tooling for when experiments become incidents
* preserving a cohesive aesthetic despite constant tinkering

Runeforge manages configuration through a small set of rituals:

| Ritual   | Purpose                            |
| -------- | ---------------------------------- |
| `forge`  | Reforge the environment            |
| `seal`   | Preserve runes within Runeforge    |
| `awaken` | Restore runes from Runeforge       |
| `purge`  | Remove obsolete relics and backups |

Because apparently normal names like `sync.sh` lacked sufficient dramatic energy.

---

## ✦ Restore after an OS reinstall (Arch Linux / CachyOS)

Use a regular user with sudo access, internet, and a working Hyprland installation.
These commands also work from Fish:

```bash
sudo pacman -Syu --needed git base-devel
git clone --recurse-submodules --branch main https://github.com/hamiha/dots-hyprland.git
cd dots-hyprland
./forge
quickshell --private-check-compat
```

`./forge` uses `main` and runs `./setup install`, then installs fork-specific
packages. The full installer installs dependencies and services, then copies the
repository's configs. Use it on a fresh system; back up any existing configs first. Only settings
already saved in this repository are restored, not unsaved changes from the old OS.

Quickshell is built from `sdata/dist-arch/illogical-impulse-quickshell-git/PKGBUILD`.
Its `prepare()` step automatically applies `qt6-metatype.patch`, including on a
clean clone. This keeps the pinned Quickshell revision, rather than following the
latest upstream version. The patch was tested with Qt 6.12.0; future Qt releases
may need additional fixes.

### Rebuild only Quickshell after a Qt update

On an existing installation with dependencies already installed, run from the
repository root:

```bash
./forge quickshell
```

A successful compatibility check prints nothing. Check the exit status with
`echo $status` in Fish or `echo $?` in Bash; `0` means passed. After installation,
restart the shell from your Hyprland session:

```bash
qs kill -c ii
qs -c ii &
```

This package-only rebuild verifies Qt compatibility without overwriting settings
or restarting the shell. Add `--no-pull` to use local files without pulling `main`.
Rebuild against the new OS's Qt libraries instead of restoring an old compiled
package.

---

## ✦ Ritual Workflow

### Seal runes into Runeforge

Preserve the current state of selected runes from the live system.

```bash
./seal              # quickshell rune (default)
./seal hypr         # hyprland rune
./seal fish         # fish rune
./seal kitty        # kitty rune
./seal hypr kitty   # multiple runes
./seal all          # all runes
```

### Awaken runes from Runeforge

Restore selected runes from Runeforge into the live system.

Legacy: `awaken` still targets the `runeforge` branch. It is not part of the
`main` installation path; migrate it before deleting that branch.

```bash
./awaken              # quickshell rune (default)
./awaken hypr         # hyprland rune
./awaken fish         # fish rune
./awaken kitty        # kitty rune
./awaken hypr kitty   # multiple runes
./awaken all          # all runes
```

### Reforge Quickshell

Rebuild the Quickshell environment.

```bash
./forge quickshell
```

This uses `main`, rebuilds only the package, and preserves live settings.
Restart Quickshell manually afterward.

### Full Reforging

Run the full setup from `main` (installs repository configs).

```bash
./forge             # default: full setup
./forge all         # equivalent explicit mode
./forge --no-pull   # full setup using local files
```

### Purge Relics

Remove obsolete backups and forgotten artifacts from previous reforgings.

```bash
./purge
```

---

## ✦ Credits

Massive respect to the people who made this possible:

* **[@end-4](https://github.com/end-4)**

  Creator of the original
  [dots-hyprland / illogical-impulse](https://github.com/end-4/dots-hyprland)

* **[@gh0stzk](https://github.com/gh0stzk)**

  Weather integration inspiration and related shell utilities

---

<div align="center">

Built with questionable decisions, excessive shell customization,
and a persistent refusal to leave well enough alone.

</div>
