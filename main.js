require('@g-js-api/g.js');

$.exportConfig({
	type: 'live_editor', 
	// type can be 'savefile' to export to savefile, 'levelstring' to return levelstring 
	// or 'live_editor' to export to WSLiveEditor (must have Geode installed)
	options: {
		info: true,
		level_name: "touhou scs save",
	}
}).then(a => {
    // call trigger builder function stuff here

});
