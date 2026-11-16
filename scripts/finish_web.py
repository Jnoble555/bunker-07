"""Add browser controls/legacy link and an observable deployed-source marker."""
import json
import re
from pathlib import Path
from validate_web import fingerprints


def finish(out, commit, engine):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("A full Git commit SHA is required")
    page = out / 'index.html'
    html = re.sub(r'<title>.*?</title>', '<title>Bunker 07 — Tactical Operations</title>', page.read_text(encoding="utf-8"), flags=re.S)
    extra = '''
    <style>#edition-link{position:fixed;bottom:8px;left:12px;z-index:20;font:12px system-ui;color:#c2d6ce;background:#101a17cc;padding:5px 9px;border-radius:4px}#edition-link a{color:#80d6c2}</style>
    <div id="edition-link">IRON RELAY / DEEP SIGNAL · Updated 3D edition · <a href="classic.html">Original browser edition</a> &middot; <a href="build-info.json" title="Full source commit and asset hashes">Build BUILD_SHA</a></div>
    <script>
    window.addEventListener('keydown', function(event) {
      if (event.code === 'F5' && document.activeElement === document.getElementById('canvas')) event.preventDefault();
    }, true);
    document.addEventListener('pointerlockchange', function() {
     document.getElementById('edition-link').hidden = !!document.pointerLockElement;
    });
    </script>
    '''
    page.write_text(html.replace('</body>', extra.replace('BUILD_SHA', commit[:12]) + '\n</body>'), encoding='utf-8')
    (out/'build-info.json').write_text(json.dumps({'edition':'deep-signal-godot', 'source_commit':commit, 'engine':engine, 'threads':False, 'clean_source':True, 'files':fingerprints(out)},indent=2)+'\n', encoding='utf-8')


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("commit")
    parser.add_argument("engine")
    args = parser.parse_args()
    finish(args.output, args.commit, args.engine)
