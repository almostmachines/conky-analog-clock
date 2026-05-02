# Conky Analog Clock

An analog clock for Conky with transparent background.

![Screenshot of the analog clock](screenshot.png)

## Requirements

- [https://github.com/brndnmtthws/conky](Conky) *>= 1.22*

## Installation

```bash
mkdir -p ~/.config/conky/clock
```

Place `clock.lua` and `conky.conf` within `~/.config/quickshell/clock`.

Add to your window manager config:

```conf
exec --no-startup-id conky -d -c ~/.config/conky/clock/conky.conf
```

## Notes

`conky.conf` is configured for `i3` and other window managers which always display floating windows above non-floating windows, requiring conky to render to the root window with:

```conf
    own_window_type = 'override',
```

If your window manager *does not do that*, you may need to alter `own_window_type` to some other value (possibly `desktop`.)

## License

[MIT](LICENSE)
