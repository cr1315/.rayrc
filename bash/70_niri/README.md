

### install niri

### for wsl2:

- use GPU

### config

- `~/.config/niri/config.kdl`

```kdl
    keyboard {
        repeat-delay 200
        repeat-rate 50

        xkb {
            layout "jp"
        }

        // Enable numlock on startup, omitting this setting disables it.
        numlock
    }
```

- use a nerd font

### /etc/wsl.conf

```sh
ray@C11-09CZ0B9XAMT ~/.config/niri
:) "cat" /etc/wsl.conf
[boot]
systemd=true

[user]
default=ray
```

### /etc/pacman.conf: IgnorePkgでmesaをignoreしていた

```sh

IgnorePkg = mesa lib32-mesa

```
