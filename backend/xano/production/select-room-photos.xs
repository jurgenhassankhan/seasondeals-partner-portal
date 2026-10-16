// Server-side byte verification; reusable by import and draft refresh.
function "supplier/production/select_room_photos" {
  input { json photos }
  stack {
    api.lambda {
      code = """
const {Jimp} = await import("npm:jimp@1.6.0");
const {Buffer} = await import("node:buffer");
const {createHash} = await import("node:crypto");
// Embedded in Xano by build-photo-selector.py. No client fingerprints are trusted.
async function selectRoomPhotos(candidates, { Jimp, Buffer, digest, fetchImpl = fetch }) {
  const maxBytes = 20 * 1024 * 1024;
  const selected = [], rejected = [];
  const started = Date.now();
  const distance = (a, b) => {
    let n = BigInt('0x' + a) ^ BigInt('0x' + b), count = 0;
    while (n) { count++; n &= n - 1n; }
    return count;
  };
  for (const candidate of (Array.isArray(candidates) ? candidates : []).slice(0, 40)) {
    if (selected.length === 5 || Date.now() - started > 45000) break;
    try {
      const u = new URL(candidate.url);
      if (u.protocol !== 'https:' || u.hostname !== 'static.cupid.travel' || u.username || u.password || (u.port && u.port !== '443')) throw Error('photo_host');
      if (selected.some(p => p.url === candidate.url)) { rejected.push({reason:'duplicate'}); continue; }
      const response = await fetchImpl(u.href, {redirect:'error', signal:AbortSignal.timeout(8000)});
      if (!response.ok || Number(response.headers.get('content-length')) > maxBytes) throw Error('download');
      const reader = response.body.getReader(), chunks = [];
      let length = 0;
      try {
        while (true) {
          const {done, value} = await reader.read();
          if (done) break;
          length += value.length;
          if (length > maxBytes) throw Error('photo_size');
          chunks.push(value);
        }
      } finally { await reader.cancel(); }
      const bytes = Buffer.concat(chunks);
      // Bound decoded allocation before invoking image codecs. Only JPEG/PNG accepted.
      let width = 0, height = 0;
      if (bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])) && bytes.length >= 24) {
        width = bytes.readUInt32BE(16); height = bytes.readUInt32BE(20);
      } else if (bytes[0] === 255 && bytes[1] === 216) {
        let i = 2;
        while (i + 8 < bytes.length) {
          if (bytes[i++] !== 255) throw Error('jpeg_header');
          while (bytes[i] === 255) i++;
          const marker = bytes[i++];
          if (marker === 218 || marker === 217) break;
          const size = bytes.readUInt16BE(i);
          if (size < 2 || i + size > bytes.length) throw Error('jpeg_header');
          if ([192,193,194,195,197,198,199,201,202,203,205,206,207].includes(marker)) {
            height = bytes.readUInt16BE(i + 3); width = bytes.readUInt16BE(i + 5); break;
          }
          i += size;
        }
      }
      if (Math.min(width,height) < 100 || width * height > 16000000) throw Error('dimensions_or_format');
      const sha256 = await digest(bytes);
      if (selected.some(p=>p.sha256 === sha256)) { rejected.push({reason:'duplicate'}); continue; }
      const image = await Jimp.read(bytes);
      const {data, width:w, height:h} = image.bitmap;
      // Area averages are stable across resizes and JPEG encodings; 9 x 8 grayscale grid.
      const sums = new Float64Array(72), counts = new Uint32Array(72);
      for (let y=0;y<h;y++) for(let x=0;x<w;x++) {
        const p=(y*w+x)*4, cell=Math.floor(y*8/h)*9+Math.floor(x*9/w);
        sums[cell] += .299*data[p]+.587*data[p+1]+.114*data[p+2]; counts[cell]++;
      }
      let bits=0n;
      for(let y=0;y<8;y++)for(let x=0;x<8;x++) {
        const p=y*9+x;
        bits=(bits<<1n)|(sums[p]/counts[p]>sums[p+1]/counts[p+1]?1n:0n);
      }
      const dhash=bits.toString(16).padStart(16,'0');
      if(selected.some(p=>distance(p.dhash,dhash)<=5)) { rejected.push({reason:'duplicate'}); continue; }
      selected.push({url:u.href,caption:String(candidate.caption||'Kamerfoto').slice(0,300),scope:'matched_room',sha256,dhash});
    } catch (error) { rejected.push({reason:error.message || 'unreadable'}); }
  }
  if (!selected.length) throw Error('No verified room photos; import blocked');
  return {photos:selected,algorithm:'sha256+dhash64-area-v2',rejected_count:rejected.length};
}

return await selectRoomPhotos($input.photos, {Jimp,Buffer,digest: bytes=>createHash('sha256').update(bytes).digest('hex')});
"""
      timeout = 60
    } as $selection
  }
  response = $selection
  history = false
}
