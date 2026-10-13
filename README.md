# Do not Wakeup the Brainrot

A Roblox **Steal a Brainrot** game: sneak through a night nursery, pick up sleeping Italian brainrot memes, park them on your base for cash, and steal from other players. Sprint, jump, or make a scene and they **wake up**.

## How to play

1. You spawn on your nursery plot around the map.
2. **Walk** (do not sprint) into the purple sleep zone.
3. Hold the prompt to **gently pick up** a sleeper.
4. Walk onto an empty glowing pillow on **your** base to place it. Placed brainrots pay cash every second.
5. Sneak onto someone else's plot and **steal quietly**.
6. Press **G** to set a carried brainrot down. Press **B** (or Night Market) to buy Quiet Socks, padlocks, and luck.

If the wake bar fills, the brainrot wakes, chases you, can make you drop what you are carrying, and fines you.

| Rarity | Examples | Income |
| --- | --- | --- |
| Common | Tralalero Tralala, Tung Tung Tung Sahur | low |
| Rare | Lirili Larila, Bombardiro Crocodilo | medium |
| Epic | Brr Brr Patapim, Ballerina Cappuccina | high |
| Legendary | Cappuccino Assassino, Chimpanzini Bananini | very high |
| Mythic | Trippi Troppi, La Vaca Saturno Saturnita | jackpot |

## Open in Roblox Studio (Rojo)

1. Install [Rojo](https://rojo.space/) (`aftman add rojo-rbx/rojo` or the VS Code / Cursor Rojo plugin) and the **Rojo plugin** inside Roblox Studio.
2. In a terminal here:

   ```bash
   rojo serve
   ```

3. In Studio: Plugins → Rojo → Connect.
4. Press **Play**. The map, plots, sleepers, and HUD generate at runtime (empty baseplate is fine).

### Without Rojo

Create matching folders in a new place:

- `ReplicatedStorage/Shared` ← files from `src/shared`
- `ServerScriptService/Server` ← files from `src/server` (`init.server.lua` must be a **Script**)
- `StarterPlayer/StarterPlayerScripts/Client` ← `src/client/init.client.lua` as a **LocalScript**

Rename `init.server.lua` → Script `init`, `init.client.lua` → LocalScript `init`. ModuleScripts keep the same names (`Config`, `BrainrotCatalog`, and so on).

## Project layout

```
src/shared    catalogs + tuning
src/server    map, spawning, steal, wake, shop, income
src/client    HUD, wake meter, night market
```

Tune spawn rates, wake sensitivity, and prices in `src/shared/Config.lua` and the catalogs.
