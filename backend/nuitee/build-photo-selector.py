from pathlib import Path

root = Path(__file__).resolve().parents[2]
js = (root / 'backend/nuitee/photo-selector.js').read_text().split("if (typeof module")[0]
source = '''// Server-side byte verification; reusable by import and draft refresh.
function "supplier/production/select_room_photos" {
  input { json photos }
  stack {
    api.lambda {
      code = """
const {Jimp} = await import("npm:jimp@1.6.0");
const {Buffer} = await import("node:buffer");
const {createHash} = await import("node:crypto");
''' + js + '''
return await selectRoomPhotos($input.photos, {Jimp,Buffer,digest: bytes=>createHash('sha256').update(bytes).digest('hex')});
"""
      timeout = 60
    } as $selection
  }
  response = $selection
  history = false
}
'''
(root / 'backend/xano/production/select-room-photos.xs').write_text(source)
