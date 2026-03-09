# pbpctrl-plasmoid

A KDE Plasma 6 system tray plasmoid for controlling [Google Pixel Buds Pro](https://github.com/qzed/pbpctrl) on Linux.

## Features

- ANC mode control (Off / Active / Aware / Adaptive)
- Battery status (left, right, case)
- Auto-transparency (speech detection) toggle
- On-head detection toggle

## Requirements

- KDE Plasma 6
- [`pbpctrl`](https://github.com/qzed/pbpctrl) installed and in `$PATH` (available on the [AUR](https://aur.archlinux.org/packages/pbpctrl))

## Installation

### Manual

```sh
kpackagetool6 --install plasmoid
```

### From source

```sh
git clone https://github.com/ciarancoffey/pbpctrl-plasmoid.git
cd pbpctrl-plasmoid
kpackagetool6 --install plasmoid
```

To update an existing installation:

```sh
kpackagetool6 --upgrade plasmoid
```

## Usage

After installation, right-click the system tray and add the **Pixel Buds Pro Control** widget.

The plasmoid polls device state every 30 seconds. Use the refresh button to update manually.

## License

MIT
