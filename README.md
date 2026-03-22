# Nic Copy Tooltip

A World of Warcraft addon and Discord bot system that lets players share item tooltips as rich, in-game-style rendered images.

---

## Project Goals

### WoW Addon — Nic Copy Tooltip
- Add a UI button or keybind that opens a copy box when hovering over any item (in bags, equipment, loot windows, etc.)
- The copy box will contain the full item detail string, including item name, quality/rarity, stats, flavor text, and other relevant tooltip data
- Make it easy for players to copy this string with one click

### Discord Bot
- Accept a pasted item detail string from a user in any channel
- Parse the item string and extract key identifiers
- Query the Wowhead API to retrieve additional item metadata (icon, set bonuses, source, etc.)
- Render a tooltip image that visually matches the in-game item tooltip (correct border color for rarity, stat layout, icons, etc.)
- Reply to the user's message with the rendered tooltip image, replacing or supplementing the raw text paste

### Tooltip Renderer
- Faithfully recreate the WoW tooltip visual style using item data
- Support item quality border colors (Poor, Common, Uncommon, Rare, Epic, Legendary, etc.)
- Render item name, type, stats, flavor text, sell price, and other tooltip fields
- Output as a clean PNG or similar image format

---

## Project Structure (planned)

```
nic-copytooltip/        # This repo — WoW addon source
discord-bot/            # Discord bot + tooltip renderer (separate repo or subfolder, TBD)
```

---

## Tech Stack (planned)

| Component | Tech |
|---|---|
| WoW Addon | Lua, WoW API |
| Discord Bot | Node.js or Python |
| Tooltip Rendering | Canvas / Pillow / Sharp |
| Item Data | Wowhead API / Blizzard Battle.net API |

---

## Status

> Early planning phase. Addon scaffolding in progress.
