# Loop Cards

A loop-based card autobattler roguelite made for Godot 4.4.1

## Game Overview

**Loop Cards** is a unique card game where you craft a sequence of 8 cards that execute in a loop to battle through waves of enemies. Plan your strategy, manage your resources, and survive 10 waves to defeat the final boss!

### Core Mechanics

- **Loop System**: Arrange 8 cards in a sequence that repeats each turn
- **Resource Management**: Manage Ammo (⚙️) and Mana (✨) that reset each battle
- **Wave Progression**: Fight through 10 waves with increasing difficulty
- **Card Collection**: Gain new cards through treasure chests and rest areas

### Game Flow

1. **Prep Screen**: Arrange your 8-card loop by dragging cards
2. **Battle**: Watch your loop execute automatically against enemies
3. **Events**: Choose rewards at treasure waves (3, 7) or rest at wave 6
4. **Victory**: Defeat the boss on wave 10 to win!

## How to Play

### Controls
- **Drag & Drop**: Rearrange cards in your loop
- **Click**: Select rewards and make choices
- **RUN LOOP**: Start the battle with your current arrangement

### Card Types

#### Common Cards (6)
- **Strike**: Deal 2 damage (Free)
- **Gunfire**: Deal 3 damage (Costs 1 ⚙️)
- **Reload**: Gain 2 ⚙️ (Free)
- **Barrier**: Block 3 damage this loop (Costs 1 ✨)
- **Skip**: Do nothing - useful for timing (Free)
- **Mana Potion**: Gain 1 ✨ (Free)

#### Rare Cards (3) - Single Copy Only
- **Heavy Slash**: Deal 5 damage, skips first loop to charge (Free)
- **Fireball**: Deal 4 damage to all enemies in lane (Costs 2 ✨)
- **Energize**: Gain 1 ⚙️ and 1 ✨ (Free)

#### Consumables (3) - 3 Uses Each
- **Apple**: Heal 2 HP (Free)
- **Bomb**: Deal 3 damage to all enemies (Free)
- **Flash**: Block all damage this loop (Free)

### Enemy Types

- **Slime**: 3 HP, moves 1 tile/loop, deals 2 contact damage
- **Runner**: 2 HP, moves 2 tiles/loop, deals 1 contact damage
- **Tank**: 10 HP, moves 1 tile/loop, deals 4 contact damage
- **Boss**: 40 HP, doesn't move, deals 2 ranged damage every loop

### Strategy Tips

1. **Balance Resources**: Include both Ammo and Mana generation
2. **Plan for Defense**: Use Barrier or Flash for heavy damage waves
3. **Timing Matters**: Use Skip cards to control when effects trigger
4. **Manage Consumables**: Save powerful consumables for tough waves
5. **Single-Copy Cards**: Rare cards replace existing copies when added

## Technical Details

### Requirements
- Godot 4.4.1 or later
- Windows, macOS, or Linux

### Running the Game

1. Open the project in Godot 4.4.1
2. Press F5 or click "Play" to run the game
3. The main scene is `scenes/main.tscn`

### Project Structure

```
/scenes
  ├── main.tscn          # Main game scene
  ├── ui/                # UI screens
  ├── battle/            # Battle scene
  └── cards/             # Card-related scenes
/scripts                 # All GDScript files
/data                   # JSON card/enemy definitions
/art                    # Placeholder art assets
/audio                  # Placeholder audio assets
```

### Key Systems

- **GameState.gd**: Global game state management
- **CardDB.gd**: Card database and usage tracking
- **EnemyDB.gd**: Enemy definitions and wave generation
- **AudioManager.gd**: Simple audio system
- **Card.gd**: Card logic and execution
- **Enemy.gd**: Enemy behavior and stats
- **Battle.gd**: Main battle loop and grid management

## Development Notes

This game was designed as a complete, playable experience that can be created in a game jam timeframe. The architecture is modular and data-driven, making it easy to:

- Add new cards by editing `data/cards.json`
- Add new enemies by editing `data/enemies.json`
- Modify wave patterns in `EnemyDB.gd`
- Adjust balance by tweaking JSON values

### Future Enhancements

- More card types and mechanics
- Additional enemy varieties
- Visual effects and animations
- Music and sound effects
- Save/load system
- Difficulty modes
- Card upgrade system

## Credits

Created with Godot 4.4.1
Game design inspired by autobattler and roguelite genres

---

**Have fun crafting your perfect loop!**
