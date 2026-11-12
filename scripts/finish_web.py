"""Add browser controls/legacy link and an observable deployed-source marker."""
import json
import re
from pathlib import Path
import sys
out = Path(sys.argv[1])
page = out / 'index.html'
html = re.sub(r'<title>.*?</title>', '<title>Bunker 07 — Deep Signal</title>', page.read_text(), flags=re.S)
extra = '''
<style>#edition-link{position:fixed;bottom:8px;left:12px;z-index:20;font:12px system-ui;color:#c2d6ce;background:#101a17cc;padding:5px 9px;border-radius:4px}#edition-link a{color:#80d6c2}</style>
<div id="edition-link">DEEP SIGNAL · Updated 3D edition · <a href="classic.html">Original browser edition</a></div>
<script>
window.addEventListener('keydown', function(event) {
  if (event.code === 'F5' && document.activeElement === document.getElementById('canvas')) event.preventDefault();
}, true);
document.addEventListener('pointerlockchange', function() {
 document.getElementById('edition-link').hidden = !!document.pointerLockElement;
});
</script>
'''
page.write_text(html.replace('</body>', extra + '\n</body>'))
(out/'build-info.json').write_text(json.dumps({'edition':'deep-signal-godot','source_commit':sys.argv[2],'engine':'4.6.3','threads':False},indent=2)+'\n')
