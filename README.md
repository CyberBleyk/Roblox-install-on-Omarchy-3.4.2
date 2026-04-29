# 🎮 Roblox on Linux — Universal Installer

> Run **Roblox on Linux (2026)** with one command using **Sober + Flatpak + Wayland fixes**
> Supports Arch, Ubuntu, Fedora, Debian, Kali and more.

---

![GitHub stars](https://img.shields.io/github/stars/TU-USUARIO/TU-REPO?style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/TU-USUARIO/TU-REPO?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/TU-USUARIO/TU-REPO?style=for-the-badge)
![License](https://img.shields.io/github/license/TU-USUARIO/TU-REPO?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/TU-USUARIO/TU-REPO?style=for-the-badge)

---

## ⚡ One-line install (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TU-USUARIO/TU-REPO/main/instalar-roblox-linux-v4.sh)
```

---

## 🔥 Why this exists

Running Roblox on Linux is usually:

* Broken on Wayland ❌
* Missing portals ❌
* No display detected ❌
* Weird scaling / fullscreen ❌

This project fixes all of that automatically.

---

## 🧠 What makes this different

✔ Auto-detects distro (Arch, Ubuntu, Fedora, etc.)
✔ Auto-detects Wayland session
✔ Fixes SDL + display issues
✔ Installs correct desktop portal
✔ Handles AMD / Intel / NVIDIA
✔ Works with Hyprland, GNOME, KDE
✔ Zero manual config required

---

## 🖥 Supported Systems

| Category               | Support       |
| ---------------------- | ------------- |
| Arch / Omarchy         | ✅ Full        |
| Ubuntu / Debian / Kali | ✅ Full        |
| Fedora                 | ✅ Full        |
| NixOS                  | ⚠️ Manual     |
| Wayland                | ✅ Recommended |
| X11                    | ⚠️ Fallback   |

---

## 🎯 Result

After install:

* Roblox launches ✅
* Fullscreen works ✅
* Input works ✅
* Discord RPC works ✅

---

## 🧩 Tech Stack

* Flatpak (Flathub)
* Sober (VinegarHQ)
* Wayland (Hyprland / GNOME / KDE)
* SDL fixes

---

## 🐞 Troubleshooting

### Roblox does nothing

```bash
flatpak run org.vinegarhq.Sober
```

---

### Wayland error

```bash
echo $WAYLAND_DISPLAY
```

---

### Scaling issues

```bash
hyprctl monitors
```

Set scale = 1 if needed.

---

## 📦 Project Structure

```
.
├── instalar-roblox-linux-v4.sh
├── fix-sober-wayland.sh
└── README.md
```

---

## 🔐 Security

Always review scripts before running:

```bash
curl -fsSL https://raw.githubusercontent.com/TU-USUARIO/TU-REPO/main/instalar-roblox-linux-v4.sh
```

---

## 🚀 Roadmap

* [ ] GUI Launcher (search + play games)
* [ ] Multi-monitor support
* [ ] Dynamic resolution detection
* [ ] AUR package
* [ ] NixOS module

---

## 🤝 Contributing

PRs welcome.
Open an issue with logs + distro.

---

## ⭐ Support

Star the repo if it worked for you.

---

## ⚠️ Disclaimer

Roblox is not officially supported on Linux.
This project may break if Roblox changes something.
