#### A.  Engine & Project Skeleton

1. **Engine**: Godot 4.2 (GDScript) — smallest boilerplate, single export click.
2. **Folder layout**

   ```
   /scenes
	 ├── main.tscn          # root autoload
	 ├── ui/
	 ├── battle/
	 └── cards/
   /scripts
   /data                   # JSON card/enemy definitions
   /art (placeholders)
   /audio (placeholders)
   ```
3. **Autoload singletons**
   *GameState.gd* (current\_wave, hero\_hp, deck, resources, rng)
   *CardDB.gd* and *EnemyDB.gd* (load JSON → dictionaries)

---

#### B.  Data-Driven Definitions

```jsonc
// data/cards.json (example entry)
{
  "Strike": {
	"type": "attack",
	"cost": {"ammo":0,"mana":0},
	"damage": 2,
	"max_uses": -1,        // −1 = infinite
	"rarity": "common",
	"single_copy": false
  },
  "HeavySlash": {
	"type": "attack",
	"cost": {"ammo":0,"mana":0},
	"requires_charge": 1,  // skips first loop
	"damage": 5,
	"max_uses": -1,
	"rarity": "rare",
	"single_copy": true
  }
}
```

Same idea for **enemies.json**: `hp, speed, dmg_on_contact, ranged? {interval, damage}`.

---

#### C.  Scene Breakdown

| Scene                 | Purpose                  | Key Nodes                                |
| --------------------- | ------------------------ | ---------------------------------------- |
| **Main.tscn**         | Boot → Title → Wave loop | `SceneTreeTimer` for fades               |
| **PrepScreen.tscn**   | Loop strip UI            | `HBoxContainer` of 8 `CardSlot` controls |
| **Battle.tscn**       | 3 × 6 tile grid          | `GridContainer` + `Enemy` instances      |
| **RewardScreen.tscn** | 3 card buttons           | simple `Button` + signal                 |
| **EndScreen.tscn**    | Win/Lose summary         | buttons                                  |

---

#### D.  Core Logic Pseudocode

```gdscript
# Battle.gd
func _ready():
	wave_enemies = EnemyDB.spawn_wave(GameState.current_wave)
	loop_index = 0
	start_loop()

func start_loop():
	for card_id in GameState.deck:
		execute_card(card_id)
	advance_enemies()
	check_end_conditions()
	loop_index += 1
	yield(get_tree().create_timer(0.4), "timeout")
	if not battle_over:
		start_loop()

func execute_card(card_id):
	var card = CardDB.get(card_id)
	if !requirements_met(card): return          # whiff
	apply_effect(card)
	decrement_uses(card)

func advance_enemies():
	for e in enemies:
		e.move_tiles(e.speed)
		if e.x <= 0:
			GameState.hero_hp -= e.contact_dmg
			e.queue_free()
```

---

#### E.  UI Flow

```plaintext
Title → click START
 └─> GameState.reset()
	 └─> load PrepScreen
		 └─> click RUN
			 └─> Battle
				 └─> Wave_clear() ?
					   ├─ if wave 3/7 → RewardScreen
					   ├─ if wave 6   → RestScreen
					   └─ else         → next PrepScreen
				 └─> Boss dead → EndScreen(Victory)
				 └─> HP ≤ 0   → EndScreen(Defeat)
```

---

#### F.  Keeping It Simple

* **No pathfinding**: enemies only decrement `x`.
* **One update loop**: battle recursion above acts as tick; physics disabled.
* **Drag-and-swap**: swap `CardSlot` `card_id`, emit changed signal. No duplication logic in UI.
* **Balance via JSON**: Tweaking numbers post-jam = edit text file, no recompile.
* **Assets**: gummy-bear colored rectangles for monsters, playing-card PNGs for cards, Kenney UI audio bleeps.

---

#### G.  Day-by-Day Checklist (for the agent to schedule)

1. **Friday evening** — project setup, JSON loader, card strip widget.
2. **Saturday morning** — enemy node, advance logic, loop executor.
3. **Saturday afternoon** — 12 cards coded, 3 enemies, wave spawner.
4. **Saturday night** — reward / rest screens, rare-card flagging.
5. **Sunday morning** — boss, end screen, persistent HP.
6. **Sunday afternoon** — polish pass: particles, camera shake, SFX.
7. **Sunday one hour before deadline** — build, itch.io export, screenshots.

---

#### H.  Coding Style Rules for the Agent

* 1 class per `.gd`, PascalCase names.
* No singletons apart from `GameState`, `CardDB`, `EnemyDB`.
* Signals over tight coupling for UI callbacks.
* Comment every function with one-line `# doc`.
* Keep functions ≤ 25 LOC; split helpers.
