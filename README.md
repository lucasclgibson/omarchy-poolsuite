# Poolsuite for Omarchy

A tiny [Poolsuite FM](https://poolsuite.net/) player that lives in the [Omarchy](https://omarchy.org/) bar. Click the pixel palm tree and a little 90s-style console drops down: now playing, transport keys, eight channels and a volume control. There's no browser and no window. The audio is a headless `mpv` playing Poolsuite's public SoundCloud playlists.

| Follows your Omarchy theme | Classic Poolsuite look |
| --- | --- |
| ![The player in the Omarchy theme](screenshots/omarchy-theme.png) | ![The player in the classic System 7 look](screenshots/classic-theme.png) |

> **Unofficial.** This is a fan-made client and isn't affiliated with or endorsed by Poolsuite. All the curation is theirs, so please support them: [poolsuite.net](https://poolsuite.net/), their apps, and [SoundCloud](https://soundcloud.com/poolsuite).

## Features

- **Lives in the bar.** A 1-bit palm tree that lights up in your accent colour while music plays.
- **Two looks.** One follows your current Omarchy theme and font and changes when you switch themes. The other is the classic System 7 look: cream, aqua and pink, Chicago and DOS VGA pixel type, raised keys and dithering. Switch with the button in the player's title bar.
- **Eight channels**, each shuffled: Poolsuite FM, Poolsuite FM Two, Balearic Sundown, Indie Summer, Tokyo Disco, Friday Nite Heat, Hangover Club and Mixtapes. There's also a 🎲 key that jumps to a random channel.
- **Proper track names everywhere.** These show in the player, the bar tooltip and Omarchy's media notifications, and they're right from the moment you skip.
- **Normal media controls.** It's an MPRIS player, so media keys and `playerctl` work as usual.
- **Light.** It only runs `mpv` while the radio is on. Stop (■) turns it off completely.

## Install

You need Omarchy with its Quickshell bar, plus:

```bash
omarchy pkg add mpv mpv-mpris yt-dlp jq socat
```

Then:

```bash
git clone https://github.com/lucasclgibson/omarchy-poolsuite.git
cd omarchy-poolsuite
./install.sh
```

The installer copies the widget, the `poolsuite` command and a small mpv safeguard into your home folder. It fetches the two free fonts used by the classic look and puts the palm tree at the start of the bar's right-hand section. It doesn't use `sudo` or change anything outside your home folder. If you want to hack on it, use `./install.sh --link` to symlink to the checkout instead.

### Optional extras

- **Super+Space menu entry:** paste the line from [`extras/omarchy-menu.jsonc`](extras/omarchy-menu.jsonc) into `~/.config/omarchy/extensions/omarchy-menu.jsonc`.
- **Keybinding** (Super+Alt+P): see [`extras/hyprland-binding.lua`](extras/hyprland-binding.lua).

## Use

In the bar:

| Action | What it does |
| --- | --- |
| Click | Open or close the player |
| Middle-click | Play / pause |
| Right-click | Next track |
| Scroll | Volume |

In the player, the four transport keys are play/pause, stop (turns the radio off), previous and next. The 🎲 key picks a random channel. The **Channel** box opens a pop-up menu, and the bars next to the speaker set the volume.

From a terminal:

```text
poolsuite                  open the bar player
poolsuite play [channel]   start the radio (last channel by default)
poolsuite toggle           play/pause, starting the radio if it's off
poolsuite next | previous | pause
poolsuite quit             turn the radio off
poolsuite channels         list channels
poolsuite theme [omarchy|poolsuite]
poolsuite refresh [ch…]    rebuild the cached track lists
```

The look is also a widget setting (`theme`: `Omarchy` or `Poolsuite`) on the widget's entry in `~/.config/omarchy/shell.json`.

## How it works

- **`bin/poolsuite`** runs `mpv --shuffle` on a channel. Before mpv can play a SoundCloud track it has to resolve it, and until then all it has for a title is a track number. So the script asks `yt-dlp` once for each channel's full track list and caches it as an `.m3u` with each track's `Artist - Title`, in `~/.cache/poolsuite/`. That takes about 20 seconds per channel and runs in the background the first time a channel plays, then weekly. With the cached list, the title is right from the first moment. If a list arrives while that channel is already playing, it's swapped in after the current song.
- **`mpv-mpris`** exposes the player on D-Bus. The bar widget finds that exact `mpv` (by PID) through Quickshell's MPRIS service and drives it directly.
- **`plugin/`** is the Omarchy shell plugin (Quickshell/QML). `Player.qml` is the popup. `PixelIcon`, `Bevel` and `PText` are the 1-bit sprites, raised keys and pixel type, and they take their colours from the active palette.
- **`share/guard.lua`** is an mpv script. If five tracks in a row fail to load, it stops the radio and the player shows "Offline" instead of racing through the playlist.

## Troubleshooting

- **"Offline: SoundCloud unavailable".** `yt-dlp` couldn't get tracks from SoundCloud. SoundCloud sometimes rate-limits it (try again later), and SoundCloud changes regularly break older `yt-dlp` versions, so update it. You can test with `yt-dlp -J https://soundcloud.com/poolsuite/sets/tokyo-disco`.
- **Changes to the QML don't show up.** Run `omarchy restart shell`.
- **The classic look uses the wrong font.** Re-run `./install.sh` and check that `fc-list | grep -i "chicago kare"` finds it.

## Uninstall

```bash
./uninstall.sh           # keeps the fonts
./uninstall.sh --fonts   # removes them too
```

## Credits and licences

- Code: [MIT](LICENSE).
- The channel list comes from [jamespember/poolsuite-cli](https://github.com/jamespember/poolsuite-cli) (MIT).
- [Chicago Kare](https://github.com/KingDuane/Chicago-Kare) by Duane King (MIT), downloaded at install time.
- IBM VGA 8x16 from [The Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) by VileR ([CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)), downloaded at install time.
- The music and its curation belong to Poolsuite and the artists. This player only plays their public SoundCloud playlists.
