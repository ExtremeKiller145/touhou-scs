# Enums Reference

This file explains the structure of `enums.json` and how to maintain it.

## Structure

```json
{
  "Properties": { ... },
  "ObjectID": { ... },
  "Easing": { ... },
  "GroupFields": [ ... ]
}
```

## Properties

Maps human-readable property names to Geometry Dash property IDs.

**Format:** `"NAME": number`

**Example:**
```json
"GROUPS": 57,
"TARGET": 51,
"OBJ_ID": 1
```

These are used when indexing and displaying trigger properties. The debugger uses these to:
- Identify which fields contain group references
- Display property names instead of just numbers
- Parse remap strings and other special fields

### Key Property Categories

**General:**
- `OBJ_ID` (1) - Trigger type
- `X` (2), `Y` (3) - Position
- `DURATION` (10) - Time duration
- `EASING` (30) - Easing type

**Groups:**
- `GROUPS` (57) - Spawn/caller group
- `TARGET` (51) - Target group
- `ACTIVATE_GROUP` (56) - Toggle activate group
- `FOLLOW_GROUP` (71) - Also used for rotate center, scale center, move direction target

**Collision:**
- `BLOCK_A` (80) - First collision block
- `BLOCK_B` (95) - Second collision block

**Remapping:**
- `REMAP_STRING` (442) - Remap string (format: "10.6001.20.6002")
- `SPAWN_ORDERED` (441) - Boolean for spawn ordering (also contains remap in some cases)

**Movement:**
- `MOVE_X` (28), `MOVE_Y` (29) - Movement deltas
- `MOVE_TARGET_MODE` (100) - Goto mode
- `MOVE_DIRECTION_MODE` (394) - Direction mode

**Rotation:**
- `ROTATE_ANGLE` (68) - Rotation degrees
- `ROTATE_CENTER` (71) - Center group
- `ROTATE_TARGET` (401) - Target for rotation

**Scale:**
- `SCALE_X` (150), `SCALE_Y` (151) - Scale factors
- `SCALE_CENTER` (71) - Center group

**Pulse:**
- `PULSE_FADE_IN` (45), `PULSE_HOLD` (46), `PULSE_FADE_OUT` (47) - Timing
- `PULSE_HSV_STRING` (49) - HSV values
- `PULSE_TARGET_TYPE` (52) - Boolean: group or color channel

## ObjectID

Maps trigger type names to their object IDs.

**Format:** `"Name": number`

**Example:**
```json
"Move": 901,
"Spawn": 1268,
"Rotate": 1346
```

Used to display trigger types in the debugger (e.g., "Move" instead of "901").

### Common Object Types
- Move (901)
- Pulse (1006)
- Alpha (1007)
- Toggle (1049)
- Spawn (1268)
- Rotate (1346)
- Follow (1347)
- Stop (1616)
- Collision (1815)

## Easing

Maps easing type names to their numeric IDs.

**Format:** `"NAME": number`

**Example:**
```json
"NONE": 0,
"EASE_IN_OUT": 1,
"SINE_IN": 14
```

Used when displaying or filtering by easing types.

## GroupFields

Array of property IDs that contain group references.

**Format:** `[number, number, ...]`

**Example:**
```json
[57, 51, 71, 56, 80, 95, 401, 395]
```

The debugger uses this list to:
1. Index all groups in triggers
2. Find triggers that reference a specific group
3. Build dependency graphs

### Current Group Fields:
- 57 (GROUPS) - Spawn/caller group
- 51 (TARGET) - General target group
- 71 (Multi-use: FOLLOW_GROUP, ROTATE_CENTER, SCALE_CENTER, MOVE_TARGET_DIR)
- 56 (ACTIVATE_GROUP) - Toggle target
- 80 (BLOCK_A) - Collision block A
- 95 (BLOCK_B) - Collision block B
- 401 (ROTATE_TARGET) - Rotation target
- 395 (MOVE_TARGET_CENTER) - Move target center

## How to Update

### Adding a New Property

1. Open `enums.json`
2. Add to the `Properties` section:
   ```json
   "NEW_PROPERTY_NAME": 123
   ```
3. If it's a group field, add its ID to `GroupFields`:
   ```json
   "GroupFields": [57, 51, 71, 56, 80, 95, 401, 395, 123]
   ```
4. Save and regenerate the report with `node debug/debug.js`

### Adding a New Object Type

1. Open `enums.json`
2. Add to the `ObjectID` section:
   ```json
   "NewTriggerType": 9999
   ```
3. Save and regenerate the report

### Source of Truth

The canonical source is `enums.lua` in the project root. When adding properties, cross-reference with:
```lua
enum.Properties = {
    PROPERTY_NAME = 123,
    ...
}
```

## Validation

After updating `enums.json`:

1. **Check syntax:** Ensure valid JSON (no trailing commas, proper quotes)
2. **Run the debugger:** `node debug/debug.js`
3. **Verify in browser:** Open `report.html` and check that:
   - Property names display correctly
   - Groups are properly indexed
   - Trigger types show readable names

## Troubleshooting

**"Failed to load enums.json"**
- Check JSON syntax (use a validator like jsonlint.com)
- Ensure file is in `debug/` folder

**Property not showing up**
- Verify the property ID is correct
- Check if it needs to be added to `GroupFields`
- Regenerate report after changes

**Wrong property names**
- Make sure property IDs match between `enums.json` and `enums.lua`
- Check for duplicate property IDs

## Notes

- Property ID 71 is used for multiple purposes (Follow, Rotate Center, Scale Center, Move Target)
- Some properties like REMAP_STRING can be in multiple fields (441, 442)
- Not all GD properties are listed - only ones relevant to this project
- Group IDs must be between 1-9999 (GD limitation)