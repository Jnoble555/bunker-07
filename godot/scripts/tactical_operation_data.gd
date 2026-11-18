extends RefCounted
## Original authored operation. Coordinates in meters; inventory is attempt-scoped.
static func definition() -> Dictionary:
	return {
		"id":"tactical-operation", "title":"DEEP SIGNAL", "objective":"tactical",
		"briefing":"1. Restore access at the amber SECURITY terminal.\n2. Follow the striped ramp to OPERATIONS and recover the archive.\n3. Extract through the northeast lift.\n\nTIP: The west MAINTENANCE route bypasses the security firing lane.\n\nWASD move · Mouse aim · Click fire · R reload\nF interact / collect · 1/2/3 weapons · Esc pause · F5 restart",
		"spawn":Vector3(5,0,44), "panel":Vector3(23,0,39), "core":Vector3(43,1.2,7), "exit":Vector3(45,1.2,4),
		"bots":[
			{"id":"security-smg","position":Vector3(24,0,38),"role":"smg","hp":5,"patrol":[Vector3(24,0,38),Vector3(28,0,36)]},
			{"id":"security-rifle","position":Vector3(27,0,30),"role":"rifle","hp":5,"patrol":[Vector3(27,0,30),Vector3(24,0,28)]},
			{"id":"maintenance-smg","position":Vector3(9,0,25),"role":"smg","hp":4,"patrol":[Vector3(9,0,25),Vector3(12,0,21)]},
			{"id":"relay-rifle","position":Vector3(26,0,21),"role":"rifle","hp":5,"patrol":[Vector3(26,0,21),Vector3(28,0,24)]},
			{"id":"armory-rifle","position":Vector3(43,0,39),"role":"rifle","hp":5,"patrol":[Vector3(43,0,39),Vector3(45,0,34)]},
			{"id":"ramp-smg","position":Vector3(38,0,25),"role":"smg","hp":5,"patrol":[Vector3(38,0,25),Vector3(42,0,25)]},
			{"id":"operations-rifle","position":Vector3(43,1.2,11),"role":"rifle","hp":6,"patrol":[Vector3(43,1.2,11),Vector3(45,1.2,7)]},
			{"id":"operations-smg","position":Vector3(37,1.2,9),"role":"smg","hp":4,"patrol":[Vector3(37,1.2,9),Vector3(37,1.2,13)]}
		]
	}
static func supplies() -> Array[Dictionary]:
	return [
		{"id":"smg","label":"TAKE SMG / SLOT 2","position":Vector3(7,0,43),"taken":false},
		{"id":"supply","label":"ENTRY AMMUNITION","position":Vector3(8,0,43),"taken":false},
		{"id":"supply","label":"MAINTENANCE AMMUNITION","position":Vector3(5,0,23),"taken":false},
		{"id":"medical","label":"MEDICAL SUPPLIES +40","position":Vector3(5,0,21),"taken":false},
		{"id":"shotgun","label":"TAKE SHOTGUN / SLOT 3","position":Vector3(44,0,43),"taken":false},
		{"id":"supply","label":"ARMORY AMMUNITION","position":Vector3(45,0,43),"taken":false},
		{"id":"medical","label":"ARMORY MEDICAL +40","position":Vector3(46,0,43),"taken":false},
		{"id":"supply","label":"RELAY AMMUNITION","position":Vector3(28,0,19),"taken":false},
		{"id":"supply","label":"OPERATIONS AMMUNITION","position":Vector3(35,1.2,13),"taken":false}
	]
