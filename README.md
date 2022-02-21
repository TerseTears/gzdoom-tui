# :suspect: GZDoom Terminal User Interface

The `gzdoom-tui` is a tui written in `bash` using `whiptail` that tries to
facilitate running Doom mods from the terminal. Requirements are `bash` 4.x,
`whiptail`, and `gawk`.

## :film_strip: Interface

[![asciicast](https://asciinema.org/a/469025.svg)](https://asciinema.org/a/469025)

## :hammer: Installation

Copy the `gzdoom-tui` script, give it the required permissions and
execute the script.

## :wrench: Configuration

Two configurations are present. Where the `Gameplay` mods are, and
where the `level` mods are. Both can be written in a single file that is to be
sourced by `bash` located at either `XDG_CONFIG_HOME/gzdoom-tui` or
`~/.config/gzdoom-tui`. Both configuration values default to `~/.config/gzdoom`.
After the first run, the file can be edited for the desired values as well.

## Limitations

* Mod order is always fixed (alphabetically) and not affected by selection order
(`whiptail` limitation).
* Relies on `gzdoom`'s own graphical interface for selection of `iwad`s.

## Alternatives

* [twad](https://github.com/zmnpl/twad) with more features written in `golang`.
