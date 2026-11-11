extends RefCounted
## Native coordinates are twice the browser grid coordinates; source maps are unchanged.
static func all_missions() -> Array[Dictionary]:
	return [
		{"id":"breach", "title":"BREACH", "objective":"clear_bots",
		"briefing":"Disable the security scout, then reach the cyan CONTROL SECTOR entrance.",
		"map":["#############","#...........#","#...........#","#..###......#","#..#........#","#...........#","#......##...#","#...........#","#...........#","#############"],
		"spawn":Vector3(4,0,4), "panel":Vector3.ZERO,"core":Vector3.ZERO,"exit":Vector3(22,0,16),
		"bots":[{"id":"security-1","position":Vector3(10,0,4),"role":"scout","hp":2,"is_guard":false}]},
		{"id":"control-room", "title":"CONTROL ROOM", "objective":"alarm_core",
		"briefing":"Choose the guarded direct hall or maintenance route. Disable the alarm, secure the core and extract. Service power, a bulkhead and an overload terminal offer tactical choices; intel and a hidden cache are optional.",
		"map":["#############","##########..#","##########.##","##########.##","########...##","#........####","#.######.####","#........####","#.....#..####","#############"],
		"spawn":Vector3(3,0,17),"panel":Vector3(9,0,15),"core":Vector3(17,0,11),"exit":Vector3(23,0,3),
		"bots":[{"id":"guard_1","position":Vector3(9,0,11),"role":"armored","hp":3,"is_guard":true}]},
		{"id":"blackout", "title":"BLACKOUT", "objective":"restore_power",
		"briefing":"Find the southwest BACKUP POWER switch and press E. Then reach the extraction lift. Emergency guidance remains visible; the security turret is independent of backup power.",
		"map":["#############","#...........#","#.###...###.#","#...#...#...#","#...#.......#","#.......###.#","#.###.....#.#","#...........#","#...........#","#############"],
		"spawn":Vector3(3,0,3),"panel":Vector3(7,0,15),"core":Vector3.ZERO,"exit":Vector3(23,0,3),
		"bots":[{"id":"guard-1","position":Vector3(21,0,7),"role":"turret","hp":3,"is_guard":false}]}
	]
