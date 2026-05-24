# Card RPG Future Systems Draft

Date: 2026-05-23
Status: Draft for confirmation
Scope: P3+ system reservation, plus resource-system redesign notes for P2.1/P2.2 planning

## 1. Current Direction

Phase 2 has already introduced character selection, stage selection, AI difficulty, expanded card types, and first-pass character skills.

Before entering larger P3 systems, this document records the future-facing card-data, inventory, forging, and resource-system plans. These items are not all scheduled for immediate implementation. After this document is confirmed, P3 work will be temporarily set aside, and development will return to P2 AI improvement and UI optimization.

## 2. New Rule Reservation: Straight Flush

Add a new hand type: `STRAIGHT_FLUSH`.

### Rule Position

Power ranking:

1. `ROYAL_BOMB`
2. `STRAIGHT_FLUSH`
3. `BOMB`
4. Other normal hands

### Draft Comparison Rule

`STRAIGHT_FLUSH` is based on `STRAIGHT`, but all cards must share one effective suit.

Draft comparison rules:

- A straight flush beats any non-royal-bomb and non-straight-flush hand, including bombs.
- Royal bomb still beats straight flush.
- Same straight flush type compares exactly like straight:
  - length must match;
  - then compare the straight anchor rank.

### Interface Draft

```gdscript
enum HandType {
	INVALID,
	SINGLE,
	PAIR,
	TRIPLE,
	TRIPLE_ONE,
	TRIPLE_PAIR,
	STRAIGHT,
	CONSECUTIVE_PAIRS,
	AIRPLANE_SINGLE,
	AIRPLANE_PAIR,
	FOUR_TWO,
	BOMB,
	STRAIGHT_FLUSH,
	ROYAL_BOMB,
}

static func is_straight_flush(cards: Array[Card]) -> bool
static func effective_numbers(card: Card) -> Array[int]
static func effective_suits(card: Card) -> Array[String]
```

## 3. Card Data v2 Reservation

Current card base layer:

- `number`
- `suit`
- `attributes`

Future card data should be expanded without breaking current basic-card gameplay.

### Proposed Card Model

```gdscript
class_name Card
extends RefCounted

var card_id: String = ""
var series_id: String = ""

var base_number: int = 0
var base_suit: String = ""
var base_color: String = ""

var rarity: String = "common"
var gem_slots: Array[GemSlot] = []
var skills: Array[CardSkill] = []
var equipment_slots: Array[CardEquipmentSlot] = []

var attributes: Array[String] = []
```

Compatibility note:

- Existing `number` and `suit` can remain during transition.
- Later migration can map `number -> base_number` and `suit -> base_suit`.
- All hand-rule logic should eventually read `effective_numbers()` and `effective_suits()` instead of only raw base values.

## 4. Gem Slot Reservation

Each card reserves gem slots. Default max slot count: `3`.

Gem slot categories:

- `number`
- `suit`
- `color`

### Number Gem

If a card has a number gem `5`, the card can count as either its base number or `5`.

Example:

```gdscript
base_number = 9
number_gem = 5
effective_numbers() => [9, 5]
```

### Suit Gem

If a card has a suit gem `hearts`, the card can count as either its base suit or `hearts`.

### Color Gem

Reserved for future color-based card sets such as UNO-like cards, elemental color rules, or special wild-color logic.

### Interface Draft

```gdscript
class_name GemSlot
extends RefCounted

enum GemSlotType {
	NUMBER,
	SUIT,
	COLOR,
}

var slot_type: int
var gem: GemData = null
var locked: bool = false

class_name GemData
extends RefCounted

var gem_id: String = ""
var gem_type: int
var value = null
var rarity: String = "common"
```

## 5. Card Skill Reservation

Each card can hold `0-3` skills.

Card skills consume combo points when played. When selected cards contain usable skills, those skills should be highlighted in the UI.

If multiple cards are played and enough combo points are available, the player can select multiple skills across multiple cards.

Open design issue:

- Skill release order is not finalized.
- Options include manual ordering, card-order execution, priority-based execution, or simultaneous resolution.

### Interface Draft

```gdscript
class_name CardSkill
extends RefCounted

var skill_id: String = ""
var display_name: String = ""
var description: String = ""
var combo_cost: int = 0
var trigger_timing: String = "on_play"
var target_rule: String = "none"
var effect_id: String = ""
```

```gdscript
class_name CardSkillChoice
extends RefCounted

var source_card: Card
var skill: CardSkill
var selected: bool = false
var order_index: int = 0
```

## 6. Rarity Reservation

Cards should have rarity, shown through border color.

Draft rarity values:

- `common`
- `uncommon`
- `rare`
- `epic`
- `legendary`

Future logic:

- Higher rarity may increase max gem slots.
- Higher rarity may increase max skill count.
- Higher rarity may improve forge growth potential.

For now, only reserve data fields and UI border display.

## 7. Card ID And Collection Reservation

Cards should reserve an ID display field because future cards may come from different series.

Use cases:

- Card collection book
- Card source tracking
- Duplicate card management
- Series-specific bonuses

### Interface Draft

```gdscript
var card_id: String = "basic_spades_7"
var series_id: String = "standard_54"
var display_id: String = "#STD-007"
```

## 8. Card Equipment Slot Reservation

Each card may reserve equipment slots. Exact usage is undecided.

Possible future uses:

- Attach relics to a card
- Add temporary modifiers
- Attach class-specific enhancements
- Lock special forge outcomes

### Interface Draft

```gdscript
class_name CardEquipmentSlot
extends RefCounted

var slot_id: String = ""
var equipment: CardEquipment = null
var locked: bool = false
```

## 9. Player Inventory Reservation

The player needs persistent storage for future long-term progression.

Inventory categories:

- Equipment
- Consumable items
- Potions
- Gems
- Forge materials
- Gold
- Cards

### Interface Draft

```gdscript
class_name PlayerInventory
extends RefCounted

var gold: int = 0
var cards: Array[Card] = []
var equipment: Array[EquipmentData] = []
var consumables: Array[ItemStack] = []
var gems: Array[GemData] = []
var forge_materials: Array[ItemStack] = []
```

```gdscript
class_name ItemStack
extends RefCounted

var item_id: String = ""
var count: int = 0
```

## 10. Card Forging System Reservation

Reserve a future forging system for:

- Fusion
- Upgrade
- Forge
- Reroll
- Gem insertion
- Gem removal
- Skill reroll
- Rarity upgrade

### Interface Draft

```gdscript
class_name CardForgeSystem
extends RefCounted

static func can_fuse(cards: Array[Card]) -> bool
static func fuse(cards: Array[Card]) -> Card

static func can_upgrade(card: Card, materials: Array[ItemStack]) -> bool
static func upgrade(card: Card, materials: Array[ItemStack]) -> Card

static func can_reroll(card: Card, cost_items: Array[ItemStack]) -> bool
static func reroll(card: Card, reroll_type: String) -> Card

static func can_socket_gem(card: Card, gem: GemData, slot_index: int) -> bool
static func socket_gem(card: Card, gem: GemData, slot_index: int) -> bool
```

## 11. Resource System Redesign

The current energy model has:

- virtual points
- real points
- energy points

Testing feedback: this model feels confusing and logically noisy.

New direction:

- Remove virtual points.
- Rename the combo resource to `combo_points`.
- Add an independent blue-bar resource: `mana`.

### Combo Points

Combo points are used to release card skills.

Future tutorial flow:

- The player should not start the full game with combo points unlocked.
- Combo points are introduced after the tutorial teaches card skills.
- In current testing, combo points can be enabled directly.

### Mana

Mana is a separate blue bar used to release character/class skills.

Future tutorial flow:

- Mana should be introduced after the tutorial teaches character skills.
- In current testing, mana can be enabled directly.

### Class Resource Identity

Different classes should have different starting maximums:

| Class | Combo Length | Mana Length |
| --- | --- | --- |
| Warrior | Short | Short |
| Mage | Medium | Long |
| Monk | Long | Medium |

These maximums should later be growable and player-adjustable, allowing different builds.

### Proposed Resource Model

```gdscript
class_name CombatResourceBar
extends RefCounted

var combo_points: int = 0
var max_combo_points: int = 0

var mana: int = 0
var max_mana: int = 0

func gain_combo(amount: int) -> void
func spend_combo(amount: int) -> bool

func gain_mana(amount: int) -> void
func spend_mana(amount: int) -> bool
```

### Character Resource Draft

```gdscript
class_name CharacterData
extends RefCounted

var id: String = ""
var display_name: String = ""
var max_hp: int = 0

var starting_max_combo_points: int = 0
var starting_max_mana: int = 0
var character_skill_mana_cost: int = 0
```

Draft testing values:

| Character | HP | Max Combo | Max Mana |
| --- | ---: | ---: | ---: |
| Warrior | 250 | 3 | 3 |
| Mage | 150 | 5 | 8 |
| Monk | 200 | 8 | 5 |

Confirmed for current testing:

- Trickster and Mage will be separate future classes.
- Current testing keeps only Mage in the former Trickster slot.
- Character skills consume mana immediately in P2.1, replacing the current energy-point cost.

Open confirmation:

- Exact combo and mana gain tuning values after hands-on testing.

## 12. P2.1 / P2.2 Work After This Document

After confirming this document, temporarily set aside P3 systems.

Next target:

1. P2.1 AI strengthening
   - Add played-card memory.
   - Improve hard AI counter logic.
   - Improve bomb and royal-bomb conservation.
   - Prefer fast hand-emptying when appropriate.

2. P2.2 UI optimization
   - Improve battle resource display.
   - Show combo points and mana clearly after resource redesign.
   - Show character skill status.
   - Show card-skill reservation UI later.
   - Make Trickster wild marks and Monk reflect state more visible.

## 13. P3 Mode Reservation: Deathmatch

Deathmatch is a future battle mode separate from the current HP-based battle mode.

Core direction:

- Remove HP as the win/loss condition.
- Each player uses their own card system instead of sharing one 54-card deck.
- Victory is decided by whether a player can refill to the standard hand size during the refill phase.
- Standard test hand size: `13`.

### Player Card Zones

Each deathmatch player should own these zones:

```gdscript
class_name DeathmatchPlayerState
extends RefCounted

var hand: Array[Card] = []
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var broken_pile: Array[Card] = []
var protected_zone: Array[Card] = []
```

Zone meaning:

- `hand`: current playable hand.
- `draw_pile`: cards not yet drawn.
- `discard_pile`: successfully played cards that can later cycle back.
- `broken_pile`: permanently broken cards for this match cycle; future source for forge/material drops.
- `protected_zone`: cards saved by the global protection rule before breaking.

### Basic Deathmatch Flow

Opening:

1. Each player starts with their own deck/card pool.
2. Each player draws to the standard hand size, initially `13`.

During play:

- Successfully played cards enter the owner's discard pile.
- If one player empties their hand, the battle enters a refill/settlement phase.

### Empty-Hand Settlement

If player A actively plays their final hand card:

1. A is the active finisher.
2. B is the unfinished player if B still has cards in hand.
3. Resolve B first.
4. B's remaining hand cards are about to break.
5. Before breaking, apply the global protection rule.
6. B's unprotected remaining hand cards enter `broken_pile`.
7. B's discard pile is shuffled into B's draw pile.
8. B attempts to draw a full standard hand of `13`.
9. If B cannot draw `13` normal cards, B loses.
10. If B succeeds, B's protected cards are released into hand after the normal draw.
11. A then refills normally.

The active finisher normally does not enter a breaking step because their hand is already empty.

### Refill Failure Example

Example:

```text
A hand: 1
A discard: 5
A draw pile: 0

B hand: 5
B discard: 5
B draw pile: 0
```

A plays the final hand card. B passes. Settlement begins.

B can only access:

```text
B current hand 5 + B discard 5 + B draw pile 0 = 10 cards
```

Because `10 < 13`, B cannot refill to the standard hand size.

Resolution:

1. B may protect one card before breaking.
2. B's remaining unprotected hand cards enter `broken_pile`.
3. B still cannot draw `13` normal cards.
4. B loses.

Important: protected cards do not count toward the required standard hand size.

### Global Highest-Priority Rule: Protect Before Break

Any time cards are about to enter `broken_pile`, the owner may choose one card from that breaking batch to protect.

This is a global highest-priority rule.

```text
cards about to break
-> owner chooses up to 1 protected card
-> protected card enters protected_zone
-> all other cards enter broken_pile
```

Protected cards:

- Do not count toward the standard refill hand size.
- Are released into hand only after the player successfully refills the normal standard hand.
- Can make the player temporarily exceed the standard hand size.

Example:

```text
standard hand size = 13
protected_zone = 1
successful normal refill = 13
final hand after release = 14
```

If the player only has `12` refillable normal cards plus `1` protected card, that is still a loss:

```text
12 normal refill cards + 1 protected card != successful 13-card refill
```

### Active Finisher Breaking Check

Under the base deathmatch rules, the active finisher does not break cards after emptying their hand.

Reason:

- Their hand is already empty.
- There is no remaining hand batch to break.
- They only perform a normal refill after the unfinished player's settlement.

The global protection rule still applies if a future card, skill, curse, equipment, or mode rule causes the active finisher to break cards for another reason.

### Interface Draft

```gdscript
class_name DeathmatchBattleState
extends RefCounted

var standard_hand_size: int = 13
var player_state: DeathmatchPlayerState
var enemy_state: DeathmatchPlayerState

func settle_empty_hand(finisher: DeathmatchPlayerState, unfinished: DeathmatchPlayerState) -> DeathmatchResult
func recycle_discard_into_draw(state: DeathmatchPlayerState) -> void
func draw_standard_hand(state: DeathmatchPlayerState) -> bool
func protect_before_break(state: DeathmatchPlayerState, cards_to_break: Array[Card]) -> Card
func break_unprotected_cards(state: DeathmatchPlayerState, cards_to_break: Array[Card], protected_card: Card) -> void
func release_protected_cards_to_hand(state: DeathmatchPlayerState) -> void
```

```gdscript
class_name DeathmatchResult
extends RefCounted

var battle_over: bool = false
var winner = null
var loser = null
var broken_cards: Array[Card] = []
var protected_cards: Array[Card] = []
```

### Future Reward Hook

Broken cards are a future source for rewards:

- forge materials
- enhancement materials
- gems
- class-specific crafting resources

Draft hook:

```gdscript
func generate_break_rewards(broken_cards: Array[Card]) -> Array[ItemStack]
```
