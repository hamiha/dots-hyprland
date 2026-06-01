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

### Full Reforging

Rebuild the entire environment.

```bash
./forge all
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
