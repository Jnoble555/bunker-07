window.Bunker07Missions = window.Bunker07Missions || {};
window.Bunker07Missions.breach = {
  id: 'breach',
  title: 'BREACH',
  briefing: 'Disable the security bot, then follow the cyan CONTROL SECTOR sign and reach the entrance to complete the breach.',
  onboarding: [
    { id: 'move', trigger: 'move', text: 'Move with W/A/S/D or the Up and Down arrow keys.' },
    { id: 'aim', trigger: 'aim', text: 'Aim with the mouse or the Left and Right arrow keys.' },
    { id: 'fire', trigger: 'fire', text: 'Fire at the security bot with Click or Space.' },
    { id: 'reload', trigger: 'reload', text: 'Press R to reload your weapon.' }
  ],
  map: [
    '#############',
    '#...........#',
    '#...........#',
    '#..###......#',
    '#..#........#',
    '#...........#',
    '#......##...#',
    '#...........#',
    '#...........#',
    '#############'
  ],
  player: { x: 2, y: 2, angle: 0 },
  bots: [
    { id: 'security-1', x: 5, y: 2, hp: 2 }
  ],
  objective: {
    type: 'clear_bots',
    exit: { x: 11, y: 8 },
    exitLabel: 'CONTROL SECTOR'
  },
  markers: [
    { x: 5, y: 2, label: 'SECURITY BOT', color: '#ff4444' },
    { x: 11, y: 8, label: 'CONTROL SECTOR', color: '#44ddff' }
  ]
};
