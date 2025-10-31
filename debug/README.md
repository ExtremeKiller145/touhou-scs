# Trigger Debugger

A simple debugging tool to help trace and visualize how groups, triggers, and objects interact in your Touhou SCS project.

## Usage

From the **project root directory** (same directory as `triggers.json`), run:

```bash
node debug/debug.js
```

This will:
1. Read `triggers.json`
2. Build indexes for groups, properties, and dependencies
3. Generate `debug/report.html`
4. Print a success message

Then open `debug/report.html` in your browser.

## Features

### 🔍 Search by Group ID
Find all triggers that reference a specific group in any way:
- Direct group assignments (`GroupID`)
- Target groups (`TargetGroupID`)
- Remap strings
- Other group fields

### 🔍 Search by Property
Find triggers by specific property values:
- Object ID (`ObjID`)
- Group ID
- Target Group ID
- Type

### 🔗 Show Dependencies
See everything that affects a specific group:
- **Spawners**: Triggers that create objects in this group
- **Movers**: Triggers that target/modify this group
- **Remappers**: Triggers that mention this group in remap strings

### 📋 All Indexed Groups
Browse all groups found in the triggers and click any group to search for it instantly.

## Files

- `debug.js` - Main Node.js script that parses triggers and generates the report
- `enums.json` - Property ID mappings and object type definitions (easy to edit!)
- `template.html` - HTML structure for the report
- `report.js` - Interactive JavaScript for the browser
- `styles.css` - Styling for the interface
- `report.html` - Generated output (open this in your browser)
- `ENUMS_README.md` - Complete reference for `enums.json`

## Workflow Example

1. You see a buggy object in Geometry Dash (e.g., group 5123 is behaving wrong)
2. Run `node debug/debug.js` from project root
3. Open `debug/report.html`
4. Enter `5123` in "Show Dependencies for Group"
5. See all triggers that spawn, move, or remap that group
6. Click on any trigger to see its full details
7. Trace back through parent triggers to find the root cause

## Tips

- Use **Search by Group** for a broad view of where a group is used
- Use **Show Dependencies** to see the cause-and-effect chain
- Click on trigger details to expand and see all properties
- Use browser's Find (Ctrl+F) within expanded triggers to search for specific values
- The "All Indexed Groups" section at the bottom shows every group found in your triggers

## Customization

### Adding/Updating Properties

If you find missing properties or incorrect mappings:

1. Open `enums.json`
2. Add or update property mappings in the `Properties` section
3. If it's a group field, add its ID to the `GroupFields` array
4. See `ENUMS_README.md` for detailed instructions

**Example:**
```json
{
  "Properties": {
    "MY_NEW_PROPERTY": 999
  },
  "GroupFields": [57, 51, 71, 56, 80, 95, 401, 395, 999]
}
```

## Notes

- The tool reads from `triggers.json` (not the live Lua runtime)
- Property IDs are defined in `enums.json` - easy to update if something's wrong
- If you need `ComponentName` preserved, you can add it as a field when generating triggers
- Remap strings are parsed to extract group references (format: `10.6001.20.6002`)
- Unknown groups (like `unknown_g*`) are shown as-is (not yet resolved)
- For complete enums reference, see `ENUMS_README.md`