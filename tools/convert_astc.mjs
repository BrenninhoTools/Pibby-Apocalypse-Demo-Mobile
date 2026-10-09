#!/usr/bin/env node
/*
Converts the game's PNGs to ASTC (.astc) textures for the mobile builds.

    node tools/convert_astc.mjs --astcenc /path/to/astcenc [--delete-png] [folders...]

The game (source/AstcTexture.hx) uploads the .astc straight to the GPU, so the image
never sits in RAM as a 4-bytes-per-pixel bitmap.

 - Alpha is premultiplied here because that's what OpenFL's renderer expects.
 - Needs astcenc from https://github.com/ARM-software/astc-encoder/releases
 - Converted files are written next to the png as <name>.astc and are git-ignored.
 - --delete-png removes each png once its .astc is written. Use it in CI, where the
   checkout is thrown away. Without it the png stays as the fallback for GPUs with no ASTC.

Options:
    --block 6x6        ASTC block size. 4x4 = best quality, 8x8 = smallest (default 6x6)
    --quality medium   fastest | fast | medium | thorough | verythorough | exhaustive
    --jobs N           parallel astcenc processes (default: CPU count)
    --force            reconvert even if the .astc is newer than the png
*/
import { execFile } from "node:child_process";
import { existsSync, readdirSync, statSync, unlinkSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// assets/exclude is never packaged. Animate spritemaps get copyPixels'd, which a GPU-only texture can't do.
const SKIP_DIRS = new Set(["exclude"]);
const SKIP_PREFIXES = ["spritemap"];

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    astcenc: { type: "string" },
    block: { type: "string", default: "6x6" },
    quality: { type: "string", default: "medium" },
    jobs: { type: "string", default: String(os.availableParallelism()) },
    force: { type: "boolean", default: false },
    "delete-png": { type: "boolean", default: false },
  },
});

const astcenc = opt.astcenc ?? process.env.ASTCENC;
if (!astcenc) {
  console.error("astcenc not found. Pass --astcenc <path> or set ASTCENC.");
  process.exit(1);
}

function* walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) yield* walk(full);
    } else if (entry.name.toLowerCase().endsWith(".png") && !SKIP_PREFIXES.some((p) => entry.name.toLowerCase().startsWith(p))) {
      yield full;
    }
  }
}

function run(args) {
  return new Promise((resolve) => {
    execFile(astcenc, args, { maxBuffer: 1 << 26 }, (error, stdout, stderr) => resolve({ error, output: (stderr || stdout).trim() }));
  });
}

async function convert(png) {
  const out = png.slice(0, -4) + ".astc";
  let status = "up to date";
  if (opt.force || !existsSync(out) || statSync(out).mtimeMs < statSync(png).mtimeMs) {
    const { error, output } = await run(["-cl", png, out, opt.block, `-${opt.quality}`, "-pp-premultiply", "-j", "1", "-silent"]);
    if (error || !existsSync(out)) {
      if (existsSync(out)) unlinkSync(out);
      return { png, ok: false, info: output || String(error) };
    }
    status = "converted";
  }
  if (opt["delete-png"]) unlinkSync(png);
  return { png, ok: true, info: status };
}

const roots = positionals.length ? positionals : [path.join(repo, "assets")];
const pngs = roots.flatMap((root) => [...walk(root)]).sort();
const jobs = Math.max(1, Number(opt.jobs));
console.log(`${pngs.length} pngs, block ${opt.block}, quality ${opt.quality}, ${jobs} jobs, ${astcenc}`);

let next = 0;
let done = 0;
const failed = [];
await Promise.all(
  Array.from({ length: jobs }, async () => {
    while (next < pngs.length) {
      const { png, ok, info } = await convert(pngs[next++]);
      const rel = path.relative(repo, png);
      done++;
      if (ok) {
        console.log(`[${done}/${pngs.length}] ${info}: ${rel}`);
      } else {
        console.log(`[${done}/${pngs.length}] FAILED: ${rel}\n${info}`);
        failed.push(rel);
      }
    }
  }),
);

if (failed.length) {
  console.error(`${failed.length} file(s) failed, their pngs were not deleted.`);
  process.exit(1);
}
