// Regenerate all app icons from the approved SVG; run from any directory.
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '../..');
const sizes = [16, 20, 24, 32, 40, 48, 64, 72, 96, 128, 144, 192, 256, 384, 512, 768, 1024];
const icoSizes = [16, 20, 24, 32, 40, 48, 64, 128, 256];
const densities = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
const res = 'android/app/src/main/res';

async function write(relative, data) {
  const destination = path.join(root, relative);
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await fs.writeFile(destination, data);
}

async function main() {
  const svg = await fs.readFile(path.join(root, 'assets/icons/app_icon.svg'), 'utf8');
  const background = svg.match(/<rect[^>]+fill="(#[0-9A-Fa-f]{6})"/)[1];
  const artwork = svg.match(/<path d="([^"]+)"/)[1];
  const transform = svg.match(/translate\(([\d.]+) ([\d.]+)\) scale\(([\d.]+)\)/);
  const render = (size) => sharp(Buffer.from(svg), { density: 72 * size / 512 }).resize(size, size);

  for (const size of sizes) {
    await write(`assets/icons/webp/app_icon_${size}.webp`, await render(size).webp({ lossless: true }).toBuffer());
  }
  for (const size of [512, 1024]) {
    await write(`assets/icons/app_icon_${size}.png`, await render(size).png().toBuffer());
  }
  // Inno Setup's welcome/completion image uses a 164:314 aspect ratio.
  await write('assets/icons/installer-wizard.png', await sharp({
    create: { width: 328, height: 628, channels: 4, background },
  }).composite([{ input: await render(256).png().toBuffer(), gravity: 'centre' }]).png().toBuffer());
  for (const [density, size] of Object.entries(densities)) {
    await write(`${res}/mipmap-${density}/ic_launcher.png`, await render(size).png().toBuffer());
  }

  // Adaptive layers are 108dp; the visible 72dp area retains the SVG's 80% scale.
  // The resulting 57.6dp artwork fits inside Android's central 66dp safe zone.
  const scale = Number(transform[3]) * 72 / 512;
  const translateX = 18 + Number(transform[1]) * 72 / 512;
  const translateY = 18 + Number(transform[2]) * 72 / 512;
  await write(`${res}/drawable/ic_launcher_foreground.xml`, `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <group android:scaleX="${scale}" android:scaleY="${scale}"
        android:translateX="${translateX}" android:translateY="${translateY}">
        <path android:fillColor="#000000" android:pathData="${artwork}" />
    </group>
</vector>
`);
  await write(`${res}/values/ic_launcher_colors.xml`, `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${background}</color>
</resources>
`);
  for (const version of [26, 33]) {
    await write(`${res}/mipmap-anydpi-v${version}/ic_launcher.xml`, `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
${version >= 33 ? '    <monochrome android:drawable="@drawable/ic_launcher_foreground" />\n' : ''}</adaptive-icon>
`);
  }

  // Windows Vista and newer support PNG-compressed ICO entries.
  const images = [];
  for (const size of icoSizes) images.push(await render(size).png().toBuffer());
  const header = Buffer.alloc(6 + 16 * images.length);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  let offset = header.length;
  images.forEach((png, i) => {
    const entry = 6 + i * 16;
    header[entry] = icoSizes[i] === 256 ? 0 : icoSizes[i];
    header[entry + 1] = header[entry];
    header.writeUInt16LE(1, entry + 4);
    header.writeUInt16LE(32, entry + 6);
    header.writeUInt32LE(png.length, entry + 8);
    header.writeUInt32LE(offset, entry + 12);
    offset += png.length;
  });
  await write('windows/runner/resources/app_icon.ico', Buffer.concat([header, ...images]));
  console.log(`Generated ${sizes.length} WebP sizes, PNGs, Android resources, and Windows ICO.`);
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
