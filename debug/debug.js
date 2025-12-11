const fs = require('fs');
const path = require('path');

// File paths (relative to project root, since we run from there)
const TRIGGERS_PATH = './triggers.json';
const OUTPUT_HTML = './debug/report.html';
const TEMPLATE_HTML = './debug/template.html';
const REPORT_JS = './debug/report.js';
const ENUMS_PATH = './debug/enums.json';

// Load enums from JSON
let ENUMS = {};
let PROPERTY_IDS = {};
let PROPERTY_NAMES = {};
let OBJECT_TYPES = {};
let GROUP_FIELDS = [];

try {
  ENUMS = JSON.parse(fs.readFileSync(ENUMS_PATH, 'utf8'));
  PROPERTY_IDS = ENUMS.Properties;
  OBJECT_TYPES = ENUMS.ObjectID;
  GROUP_FIELDS = ENUMS.GroupFields || [];

  // Build reverse mapping for display
  Object.keys(PROPERTY_IDS).forEach(name => {
    PROPERTY_NAMES[PROPERTY_IDS[name]] = name;
  });

  console.log('✅ Loaded enums from enums.json');
} catch (err) {
  console.error('❌ Failed to load enums.json:', err.message);
  process.exit(1);
}

class TriggerDebugger {
  constructor(triggers) {
    this.triggers = triggers;
    this.indexes = {
      byGroup: new Map(),           // group -> [trigger indices]
      byProperty: new Map(),         // "propName:value" -> [trigger indices]
      byTargetGroup: new Map(),      // targetGroupID -> [trigger indices]
      byRemap: new Map(),            // group mentioned in remap -> [trigger indices]
    };
    this.buildIndexes();
  }

  buildIndexes() {
    this.triggers.forEach((trigger, index) => {
      // Index by all groups mentioned in the trigger
      this.indexGroups(trigger, index);

      // Index by specific properties
      this.indexProperties(trigger, index);

      // Index by target group
      if (trigger.TargetGroupID !== undefined) {
        this.addToIndex(this.indexes.byTargetGroup, trigger.TargetGroupID, index);
      }

      // Index by remap strings
      this.indexRemaps(trigger, index);
    });
  }

  indexGroups(trigger, triggerIndex) {
    // Collect all group references in this trigger
    const groups = new Set();

    // Check known group fields from enums
    GROUP_FIELDS.forEach(fieldId => {
      const value = trigger[fieldId];
      if (value !== undefined && typeof value === 'number' && value >= 1 && value <= 9999) {
        groups.add(value);
      }
    });

    // Add to index
    groups.forEach(group => {
      this.addToIndex(this.indexes.byGroup, group, triggerIndex);
    });
  }

  indexProperties(trigger, triggerIndex) {
    // Index common searchable properties using property IDs
    const propsToIndex = [
      { id: PROPERTY_IDS.OBJ_ID, name: 'ObjID' },
      { id: PROPERTY_IDS.GROUPS, name: 'GroupID' },
      { id: PROPERTY_IDS.TARGET, name: 'TargetGroupID' },
    ];

    propsToIndex.forEach(({ id, name }) => {
      if (trigger[id] !== undefined) {
        const key = `${name}:${trigger[id]}`;
        this.addToIndex(this.indexes.byProperty, key, triggerIndex);
      }
    });
  }

  indexRemaps(trigger, triggerIndex) {
    // Parse remap strings and extract group references using property IDs
    const remapFields = [
      PROPERTY_IDS.REMAP_STRING,  // 442
      PROPERTY_IDS.SPAWN_ORDERED, // 441
    ];

    remapFields.forEach(fieldId => {
      const remapValue = trigger[fieldId];
      if (remapValue) {
        const groups = this.parseRemapString(remapValue);
        groups.forEach(group => {
          this.addToIndex(this.indexes.byRemap, group, triggerIndex);
        });
      }
    });
  }

  parseRemapString(remapStr) {
    // Remap format: "10.6001.20.6002" or similar
    // Extract all numeric groups (skip the mapping keys like 10, 20, etc.)
    const parts = String(remapStr).split('.');
    const groups = [];

    for (let i = 0; i < parts.length; i += 2) {
      if (i + 1 < parts.length) {
        const value = parts[i + 1];
        // Check if it's a group number (numeric, not unknown_g)
        if (/^\d+$/.test(value)) {
          const groupNum = parseInt(value);
          if (groupNum >= 1 && groupNum <= 9999) {
            groups.push(groupNum);
          }
        }
      }
    }

    return groups;
  }

  addToIndex(indexMap, key, triggerIndex) {
    if (!indexMap.has(key)) {
      indexMap.set(key, []);
    }
    indexMap.get(key).push(triggerIndex);
  }

  // Query methods
  findByGroup(groupID) {
    const results = new Set();

    // Direct references
    if (this.indexes.byGroup.has(groupID)) {
      this.indexes.byGroup.get(groupID).forEach(i => results.add(i));
    }

    // Target references
    if (this.indexes.byTargetGroup.has(groupID)) {
      this.indexes.byTargetGroup.get(groupID).forEach(i => results.add(i));
    }

    // Remap references
    if (this.indexes.byRemap.has(groupID)) {
      this.indexes.byRemap.get(groupID).forEach(i => results.add(i));
    }

    return Array.from(results).map(i => ({ index: i, trigger: this.triggers[i] }));
  }

  findByProperty(propName, value) {
    const key = `${propName}:${value}`;
    const indices = this.indexes.byProperty.get(key) || [];
    return indices.map(i => ({ index: i, trigger: this.triggers[i] }));
  }

  getPropertyName(trigger) {
    // Get a human-readable name for the trigger type
    const objId = trigger[PROPERTY_IDS.OBJ_ID];

    // Find name from OBJECT_TYPES
    for (const [name, id] of Object.entries(OBJECT_TYPES)) {
      if (id === objId) {
        return name;
      }
    }

    return `Type ${objId}`;
  }

  getDependencies(groupID) {
    // Find all triggers that affect this group
    const spawners = [];  // Triggers that spawn objects in this group
    const movers = [];    // Triggers that move/modify objects in this group
    const remappers = []; // Triggers that remap to/from this group

    const results = this.findByGroup(groupID);

    results.forEach(({ index, trigger }) => {
      // Check if it's a spawner (has GroupID and ObjID)
      if (trigger[PROPERTY_IDS.GROUPS] === groupID && trigger[PROPERTY_IDS.OBJ_ID]) {
        spawners.push({ index, trigger });
      }
      // Check if it targets this group
      else if (trigger[PROPERTY_IDS.TARGET] === groupID) {
        movers.push({ index, trigger });
      }

      // Check if group is in remap strings
      const remapFields = [
        trigger[PROPERTY_IDS.REMAP_STRING],
        trigger[PROPERTY_IDS.SPAWN_ORDERED]
      ];

      remapFields.forEach(remapValue => {
        if (remapValue) {
          const remapGroups = this.parseRemapString(remapValue);
          if (remapGroups.includes(groupID)) {
            remappers.push({ index, trigger });
          }
        }
      });
    });

    return { spawners, movers, remappers };
  }

  generateReportData() {
    // Collect ALL unique groups from ALL indexes
    const allGroups = new Set();

    // From direct group references
    this.indexes.byGroup.forEach((_, group) => allGroups.add(group));

    // From target groups
    this.indexes.byTargetGroup.forEach((_, group) => allGroups.add(group));

    // From remap strings
    this.indexes.byRemap.forEach((_, group) => allGroups.add(group));

    // Convert to sorted array and filter out invalid groups (>9999 or <1)
    const validGroups = Array.from(allGroups)
      .filter(g => g >= 1 && g <= 9999)
      .sort((a, b) => a - b);

    // Generate data structure for the HTML report
    return {
      totalTriggers: this.triggers.length,
      groupCount: validGroups.length,
      triggers: this.triggers,
      indexes: {
        groups: validGroups,
        properties: Array.from(this.indexes.byProperty.keys()).sort(),
      },
      propertyIds: PROPERTY_IDS,
      propertyNames: PROPERTY_NAMES,
      objectTypes: OBJECT_TYPES,
      groupFields: GROUP_FIELDS,
    };
  }
}

function main() {
  console.log('🔍 Loading triggers.json...');

  // Read triggers
  let triggers;
  try {
    const data = fs.readFileSync(TRIGGERS_PATH, 'utf8');
    const parsed = JSON.parse(data);

    // Handle both formats: array or { triggers: [...] }
    if (Array.isArray(parsed)) {
      triggers = parsed;
    } else if (parsed.triggers && Array.isArray(parsed.triggers)) {
      triggers = parsed.triggers;
    } else {
      console.error('❌ Invalid triggers.json format. Expected array or { triggers: [...] }');
      process.exit(1);
    }

    console.log(`✅ Loaded ${triggers.length} triggers`);
  } catch (err) {
    console.error('❌ Failed to read triggers.json:', err.message);
    process.exit(1);
  }

  // Build analyzer
  console.log('🔨 Building indexes...');
  const analyzer = new TriggerDebugger(triggers);
  console.log(`✅ Indexed ${analyzer.indexes.byGroup.size} groups`);

  // Generate report data
  console.log('📊 Generating report data...');
  const reportData = analyzer.generateReportData();

  // Read HTML template
  let htmlTemplate;
  try {
    htmlTemplate = fs.readFileSync(TEMPLATE_HTML, 'utf8');
  } catch (err) {
    console.error('❌ Failed to read template.html:', err.message);
    process.exit(1);
  }

  // Inject data into HTML
  const html = htmlTemplate.replace(
    '/* DATA_INJECTION_POINT */',
    `window.TRIGGER_DATA = ${JSON.stringify(reportData, null, 2)};`
  );

  // Write output
  fs.writeFileSync(OUTPUT_HTML, html);
  console.log(`✅ Report generated: ${OUTPUT_HTML}`);
  console.log('🌐 Open report.html in your browser to view');
}

main();
