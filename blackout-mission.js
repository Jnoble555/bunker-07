window.Bunker07Missions = window.Bunker07Missions || {};
window.Bunker07Missions.blackout = {
  id: 'blackout',
  title: 'BLACKOUT',
  briefing: 'Find the cyan BACKUP POWER switch and press E beside it to restore power. Then follow the amber EXTRACTION LIFT sign and reach the lift to escape. Emergency lighting keeps both stations and their guidance visible during the blackout.',
  map: [
    '#############',
    '#...........#',
    '#.###...###.#',
    '#...#...#...#',
    '#...#.......#',
    '#.......###.#',
    '#.###.....#.#',
    '#...........#',
    '#...........#',
    '#############'
  ],
  player: { x: 1.5, y: 1.5, angle: 0 },
  bots: [
    { id: 'guard-1', x: 10.5, y: 3.5, hp: 3 }
  ],
  objective: {
    type: 'restore_power',
    powerSwitch: { x: 3.5, y: 7.5 },
    exit: { x: 11.5, y: 1.5 },
    exitLabel: 'EXTRACTION LIFT'
  },
  markers: [
    { x: 3.5, y: 7.5, label: 'POWER', color: '#00F5FF' },
    { x: 11.5, y: 1.5, label: 'LIFT', color: '#FFD400' }
  ]
};
