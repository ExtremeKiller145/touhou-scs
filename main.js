
console.log("\nRUNNING main.js:\n");

require('@g-js-api/g.js');

const PROPERTY_REMAP_STRING = '442';
const PROPERTY_GROUPS = '57';
const groupPropertyField = (key) => {
	const groupFields = ['51','71']; // expandable if needed
	return groupFields.includes(key);
};


$.exportConfig({
	type: 'live_editor', 
	// type can be 'savefile' to export to savefile, 'levelstring' to return levelstring 
	// or 'live_editor' to export to WSLiveEditor (must have Geode installed)
	options: {
		info: true,
		level_name: "ttests",
	}
}).then(a => {
	const jsonData = require('fs').readFileSync('triggers.json', 'utf8');
	const data = JSON.parse(jsonData);

	// Step 1: Scan all triggers for unknown groups
	const unknownG_dict = {}; // Maps "unknown_g1" -> actual unknown_g() result object

	// Helper function to register unknown groups in the registry
	const registerUnknownGroup = (val) => {
		if (typeof val === 'string') {
			// Check for single unknown group
			if (val.match(/^unknown_g\d+$/)) {
				if (!unknownG_dict[val]) {
					unknownG_dict[val] = unknown_g();
					console.log(`Registered ${val} -> Group ${unknownG_dict[val].value}`);
				}
			}
			// Check for unknown groups in strings (like remap strings)
			const unknownGroups = val.match(/unknown_g\d+/g);
			if (unknownGroups) {
				unknownGroups.forEach(group => {
					if (!unknownG_dict[group]) {
						unknownG_dict[group] = unknown_g();
						console.log(`Registered ${val} -> Group ${unknownG_dict[val].value}`);
					}
				});
			}
		} else if (Array.isArray(val)) {
			// Process arrays recursively
			val.forEach(item => registerUnknownGroup(item));
		}
	};

	// Step 2: Scan every property of every trigger
	data.triggers.forEach(trigger => {
		Object.values(trigger).forEach(value => {
			registerUnknownGroup(value);
		});
	});

	console.log(`Unknown group registry complete: ${Object.keys(unknownG_dict).length} groups registered\n`);

	// Step 3: Transform all triggers using the registry
	const triggers = data.triggers.map(trigger => {
		return Object.keys(trigger).reduce((acc, key) => {
			if (key === PROPERTY_GROUPS) {
				// Handle GROUPS property - both single values and arrays
				const groupData = trigger[key];
				const groupArray = Array.isArray(groupData) ? groupData : [groupData];

				acc['GROUPS'] = groupArray.map(val => {
					const isUnknownGroup = (typeof val === 'string' && val.match(/^unknown_g\d+$/));
					const registryVal = unknownG_dict[val];
					return isUnknownGroup && registryVal ? registryVal : group(val);
				});
			} else if (groupPropertyField(key)) {
				// Handle TARGET property - direct unknown group replacement
				let target = trigger[key];
				if (typeof target === 'string' && target.match(/^unknown_g\d+$/) && unknownG_dict[target]) {
					target = unknownG_dict[target].value;
				}
				acc[key] = target;
			} else if (key === PROPERTY_REMAP_STRING) {
				let str = trigger[key];
				if (typeof str === 'string') {
					Object.keys(unknownG_dict).forEach(unknownGroup => {
						const actualGroup = unknownG_dict[unknownGroup];
						if (actualGroup && actualGroup.value !== undefined) {
							str = str.replace(new RegExp(unknownGroup, 'g'), actualGroup.value);
						}
					});
				}
				acc[key] = str;
			} else {
				// Copy all other properties unchanged
				acc[key] = trigger[key];
			}
			return acc;
		}, {});
	});
	triggers.forEach(trigger => {
		$.add(object(trigger));
	});
});
