// report.js - Interactive functionality for the trigger debugger

// Data will be injected by debug.js
let triggers = [];
let indexes = {};
let propertyIds = {};
let propertyNames = {};
let objectTypes = {};
let groupFields = [];

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  if (window.TRIGGER_DATA) {
    triggers = window.TRIGGER_DATA.triggers;
    indexes = window.TRIGGER_DATA.indexes;
    propertyIds = window.TRIGGER_DATA.propertyIds || {};
    propertyNames = window.TRIGGER_DATA.propertyNames || {};
    objectTypes = window.TRIGGER_DATA.objectTypes || {};
    groupFields = window.TRIGGER_DATA.groupFields || [];

    // Display stats
    displayStats();

    // Display all groups
    displayAllGroups();
  } else {
    console.error('No trigger data found!');
  }
});

function displayStats() {
  const statsEl = document.getElementById('stats');
  statsEl.innerHTML = `
    <div class="stat-item">
      <span class="stat-label">Total Triggers:</span>
      <span class="stat-value">${triggers.length}</span>
    </div>
    <div class="stat-item">
      <span class="stat-label">Unique Groups:</span>
      <span class="stat-value">${indexes.groups.length}</span>
    </div>
  `;
}

function displayAllGroups() {
  const groupsEl = document.getElementById('allGroups');
  const groupsHTML = indexes.groups.map(group => {
    return `<button class="group-chip" onclick="searchByGroup(${group})">${group}</button>`;
  }).join(' ');
  groupsEl.innerHTML = groupsHTML;
}

function searchByGroup(groupID) {
  // If no parameter provided, read from input field
  if (groupID === undefined) {
    groupID = parseInt(document.getElementById('searchGroup').value);
  }

  if (isNaN(groupID) || groupID === null || groupID === undefined) {
    showError('Please enter a valid group ID');
    return;
  }

  const results = findByGroup(groupID);
  displayResults(`Group ${groupID}`, results);
}

function searchByProperty() {
  const prop = document.getElementById('searchProp').value;
  const value = document.getElementById('searchValue').value;

  if (!value) {
    showError('Please enter a value to search for');
    return;
  }

  const results = findByProperty(prop, value);
  displayResults(`${prop} = ${value}`, results);
}

function showDependencies(groupID) {
  // If no parameter provided, read from input field
  if (groupID === undefined) {
    groupID = parseInt(document.getElementById('depsGroup').value);
  }

  if (isNaN(groupID) || groupID === null || groupID === undefined) {
    showError('Please enter a valid group ID');
    return;
  }

  const deps = getDependencies(groupID);
  displayDependencies(groupID, deps);
}

// Core search functions (replicate logic from debug.js)
function findByGroup(groupID) {
  const results = [];
  const seen = new Set(); // Avoid duplicates

  triggers.forEach((trigger, index) => {
    let found = false;

    // Check known group fields from enums
    groupFields.forEach(fieldId => {
      if (trigger[fieldId] === groupID) {
        found = true;
      }
    });

    // Check remap strings
    const remapFields = [
      trigger[propertyIds.REMAP_STRING],
      trigger[propertyIds.SPAWN_ORDERED]
    ];

    remapFields.forEach(remapValue => {
      if (remapValue) {
        const remapGroups = parseRemapString(remapValue);
        if (remapGroups.includes(groupID)) {
          found = true;
        }
      }
    });

    if (found && !seen.has(index)) {
      results.push({ index, trigger });
      seen.add(index);
    }
  });

  return results;
}

function findByProperty(propName, value) {
  const results = [];
  const searchValue = isNaN(value) ? value : parseInt(value);

  // Map property name to property ID
  const propId = propertyIds[propName.toUpperCase()];
  if (!propId) {
    console.error('Unknown property:', propName);
    return results;
  }

  triggers.forEach((trigger, index) => {
    if (trigger[propId] == searchValue) {
      results.push({ index, trigger });
    }
  });

  return results;
}

function getDependencies(groupID) {
  const spawners = [];
  const movers = [];
  const remappers = [];

  triggers.forEach((trigger, index) => {
    // Spawners: triggers that create objects in this group
    if (trigger[propertyIds.GROUPS] === groupID && trigger[propertyIds.OBJ_ID]) {
      spawners.push({ index, trigger });
    }

    // Movers: triggers that target this group
    if (trigger[propertyIds.TARGET] === groupID) {
      movers.push({ index, trigger });
    }

    // Remappers: triggers that mention this group in remap strings
    const remapFields = [
      trigger[propertyIds.REMAP_STRING],
      trigger[propertyIds.SPAWN_ORDERED]
    ];

    remapFields.forEach(remapValue => {
      if (remapValue) {
        const remapGroups = parseRemapString(remapValue);
        if (remapGroups.includes(groupID)) {
          remappers.push({ index, trigger });
        }
      }
    });
  });

  return { spawners, movers, remappers };
}

function parseRemapString(remapStr) {
  if (!remapStr) return [];

  const parts = String(remapStr).split('.');
  const groups = [];

  for (let i = 0; i < parts.length; i += 2) {
    if (i + 1 < parts.length) {
      const value = parts[i + 1];
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

// Display functions
function displayResults(title, results) {
  const resultsEl = document.getElementById('resultsContent');

  if (results.length === 0) {
    resultsEl.innerHTML = `<p class="no-results">No results found for: <strong>${title}</strong></p>`;
    return;
  }

  let html = `<h3>Found ${results.length} trigger(s) for: ${title}</h3>`;
  html += '<div class="results-list">';

  results.forEach(({ index, trigger }) => {
    html += renderTrigger(index, trigger);
  });

  html += '</div>';
  resultsEl.innerHTML = html;
}

function displayDependencies(groupID, deps) {
  const resultsEl = document.getElementById('resultsContent');

  const total = deps.spawners.length + deps.movers.length + deps.remappers.length;

  if (total === 0) {
    resultsEl.innerHTML = `<p class="no-results">No dependencies found for group <strong>${groupID}</strong></p>`;
    return;
  }

  let html = `<h3>Dependencies for Group ${groupID}</h3>`;

  // Spawners
  html += `<details open class="dependency-section">
    <summary><strong>Spawners (${deps.spawners.length})</strong> - Triggers that create objects in this group</summary>
    <div class="results-list">`;

  if (deps.spawners.length === 0) {
    html += '<p class="empty">None</p>';
  } else {
    deps.spawners.forEach(({ index, trigger }) => {
      html += renderTrigger(index, trigger);
    });
  }
  html += '</div></details>';

  // Movers
  html += `<details open class="dependency-section">
    <summary><strong>Movers (${deps.movers.length})</strong> - Triggers that target/modify this group</summary>
    <div class="results-list">`;

  if (deps.movers.length === 0) {
    html += '<p class="empty">None</p>';
  } else {
    deps.movers.forEach(({ index, trigger }) => {
      html += renderTrigger(index, trigger);
    });
  }
  html += '</div></details>';

  // Remappers
  html += `<details class="dependency-section">
    <summary><strong>Remappers (${deps.remappers.length})</strong> - Triggers with this group in remap strings</summary>
    <div class="results-list">`;

  if (deps.remappers.length === 0) {
    html += '<p class="empty">None</p>';
  } else {
    deps.remappers.forEach(({ index, trigger }) => {
      html += renderTrigger(index, trigger);
    });
  }
  html += '</div></details>';

  resultsEl.innerHTML = html;
}

function renderTrigger(index, trigger) {
  const important = getImportantFields(trigger);

  let html = `<details class="trigger-item">
    <summary>
      <strong>Trigger #${index}</strong>
      ${important.summary}
    </summary>
    <div class="trigger-details">
      <table>`;

  // Display all properties with names
  Object.keys(trigger).sort((a, b) => parseInt(a) - parseInt(b)).forEach(key => {
    const value = trigger[key];
    const propName = propertyNames[key] || `Property_${key}`;
    html += `<tr>
      <td class="prop-name">${propName} (${key})</td>
      <td class="prop-value">${formatValue(key, value)}</td>
    </tr>`;
  });

  html += '</table></div></details>';
  return html;
}

function getImportantFields(trigger) {
  const parts = [];

  const objId = trigger[propertyIds.OBJ_ID];
  const groupId = trigger[propertyIds.GROUPS];
  const targetId = trigger[propertyIds.TARGET];

  if (objId) {
    // Find name from objectTypes
    let typeName = `Type${objId}`;
    for (const [name, id] of Object.entries(objectTypes)) {
      if (id === objId) {
        typeName = name;
        break;
      }
    }
    parts.push(typeName);
  }
  if (groupId) parts.push(`Group:${groupId}`);
  if (targetId) parts.push(`Target:${targetId}`);

  return {
    summary: parts.length > 0 ? `<span class="trigger-summary">[${parts.join(', ')}]</span>` : ''
  };
}

function formatValue(key, value) {
  if (value === null || value === undefined) {
    return '<span class="null">null</span>';
  }

  // Get property name for this key
  const propName = propertyNames[key] || `Prop_${key}`;

  // Format remap strings with better readability
  if (key == propertyIds.REMAP_STRING || key == propertyIds.SPAWN_ORDERED) {
    return `<code class="remap">${value}</code>`;
  }

  // Highlight group IDs
  if (propName.includes('GROUP') || propName.includes('TARGET') || propName.includes('BLOCK')) {
    return `<span class="highlight">${value}</span>`;
  }

  if (typeof value === 'object') {
    return `<pre>${JSON.stringify(value, null, 2)}</pre>`;
  }

  if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  }

  return value;
}

function showError(message) {
  const resultsEl = document.getElementById('resultsContent');
  resultsEl.innerHTML = `<p class="error">⚠️ ${message}</p>`;
}
