<div align="center">

# ✦ illogical-impulse: Runeforge

**A heavily customized fork of**  
[illogical-impulse](https://github.com/end-4/dots-hyprland) by [@end-4](https://github.com/end-4)

Refined, reforged, and repeatedly repaired by me.

</div>

---

## ✦ Overview

Runeforge is a personal customization layer built on top of the  
[illogical-impulse](https://github.com/end-4/dots-hyprland) ecosystem.

This fork focuses on:

* deeper Quickshell customization
* workflow tweaks
* recovery/rebuild tooling
* state synchronization
* experimental UI behaviors
* maintaining a cohesive aesthetic without completely destroying maintainability

The shell includes a lightweight ritual-based workflow:

| Ritual   | Purpose                                       |
| -------- | --------------------------------------------- |
| `forge`  | Rebuild/reforge the environment               |
| `seal`   | Preserve live shell state into the repository |
| `awaken` | Apply sealed state back into the live shell   |
| `purge`  | Remove old backup relics                      |

Because apparently normal names like `sync.sh` were too spiritually empty.

---

## ✦ Ritual Workflow

### Seal current shell state into the repository

```bash
./seal              # quickshell only (default)
./seal hypr         # hyprland config
./seal fish         # fish config
./seal kitty        # kitty config
./seal hypr kitty   # combine targets
./seal all          # everything
```

### Apply repository shell state into the live environment

```bash
./awaken              # quickshell only (default)
./awaken hypr         # hyprland config
./awaken fish         # fish config
./awaken kitty        # kitty config
./awaken hypr kitty   # combine targets
./awaken all          # everything
```

### Reforge Quickshell

```bash
./forge quickshell
```

### Full system reforging

```bash
./forge full
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

Built with questionable decisions and excessive shell customization.

</div>
