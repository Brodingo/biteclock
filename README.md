# BiteClock 🧛‍♂️🐺⏲️

Add-on for Elder Scrolls Online

![Bite clock example for werewolf player](https://raw.githubusercontent.com/Brodingo/biteclock/refs/heads/main/media/bc_example1.jpg)
![Bite clock example for vampire seeking player](https://raw.githubusercontent.com/Brodingo/biteclock/refs/heads/main/media/bc_example2.jpg)

## Description

Provides a countdown timer for players that have a Vampire or Werewolf bite skill and want to know when it will be available for use. Players can also choose what kind of monster they want to be with guidance for finding shrines, which zones they are in, and how to locate them.

#### Motivation

This is my first Elder Scrolls Online add-on, I wanted to learn how they are created so I started with something I've wanted for myself. In game I like providing werewolf and vampire bites as a means to build community and save others money (since Zenimax offers bites at a premium that I think is too high). I've also really enjoyed learning Lua🌜. I look forward to using it in other places.

### Installing
Depends on [LibGPS](https://www.esoui.com/downloads/info601-LibGPS.html) for locating shrines.
Copy add-on directories to your ESO add-ons folder:

Win 📂`C:\Users\<username>\Documents\Elder Scrolls Online\live\AddOns`\
Mac 📂`~/Documents/Elder Scrolls Online/live/AddOns/`

### Slash Commands
| Command | Description |
| --- | --- |
| `/biteclockvamp` `/biteclockww`| Set your desired bite for guidance to a shrine |
| `/biteclockhide` `/biteclockshow` | Hide or Show the window |
| `/biteclockshort` `/biteclocklong` | Set the format for the cooldown timer |
| `/biteclockreset` | Reset all saved variables for the add-on |

## Roadmap
- [x] Zone assist, find a shrine to bite or get bitten
- [x] Character planning, pick a track
- [ ] Make LipGPS optional
- [ ] Account wide, track cooldowns across characters
- [ ] Bite request, a means for players to request or fulfill bites
- [ ] Settings menu for certain slash commands
- [ ] Localization
- [ ] UI updates for choosing track, checking shrines, character cooldowns
- [ ] UI refactor to support dynamic sizing
- [ ] Settings page for fonts, colors, window style, and text format

## Acknowledgements
* [Great intro to ESO add-ons](https://www.youtube.com/watch?v=ZYsr5pVqhso) by [@moshulu](https://github.com/moshulu)
* [DebugLogViewer by sirinsidiator](https://www.esoui.com/downloads/info2389-DebugLogViewer.html)

### Submit a pull request

If you'd like to contribute, please fork the repository and open a pull request to the `main` branch.
