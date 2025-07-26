const lib = require('./library');
const spell = require('./spells');

require('@g-js-api/g.js');

$.exportConfig({
	type: 'live_editor', 
	// type can be 'savefile' to export to savefile, 'levelstring' to return levelstring 
	// or 'live_editor' to export to WSLiveEditor (must have Geode installed)geome
	options: {
		info: true,
		level_name: "ttests",
	}
}).then(a => {
	const jsonData = require('fs').readFileSync('triggers.json', 'utf8');
	const data = JSON.parse(jsonData);
	const triggers = data.triggers.map(trigger => {
		return Object.keys(trigger).reduce((acc, key) => {
			acc[key] = trigger[key];
			return acc;
		}, {});
	});
	triggers.forEach(trigger => {
		let modifiedGroups = [];
		// 57 is the group list property
		trigger['57'].forEach((g) => {
			// UNFINISHED NOT WORKINGGGGGG
			if (g == "unknown_g"){
				modifiedGroups.push(unknown_g());
			} else {
				modifiedGroups.push(group(g));
			}
		});
		trigger['57'] = modifiedGroups;
		console.log(object(trigger));
		$.add(object(trigger));
	});

	// to add object to level, write out "$.add(object(obj));"
    // call builder function stuff here
});
