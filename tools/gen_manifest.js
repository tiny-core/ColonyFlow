const fs = require("fs");
const path = require("path");

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function isoUtcNoMs() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function isValidSemverSimple(s) {
  if (typeof s !== "string") return false;
  const m = s.match(/^(\d+)\.(\d+)\.(\d+)$/);
  if (!m) return false;
  const parts = [m[1], m[2], m[3]];
  for (const p of parts) {
    if (p.length > 1 && p.startsWith("0")) return false;
  }
  return true;
}

function toPosix(p) {
  return p.replace(/\\/g, "/");
}

function listLuaFilesUnder(dir) {
  const rootAbs = process.cwd();
  const abs = path.join(rootAbs, dir);
  if (!fs.existsSync(abs)) return [];

  const out = [];

  function walk(currentAbs) {
    const entries = fs.readdirSync(currentAbs, { withFileTypes: true })
      .sort((a, b) => a.name.localeCompare(b.name));

    for (const ent of entries) {
      const entAbs = path.join(currentAbs, ent.name);
      if (ent.isDirectory()) {
        walk(entAbs);
        continue;
      }
      if (!ent.isFile()) continue;
      if (!ent.name.endsWith(".lua")) continue;
      const rel = toPosix(path.relative(rootAbs, entAbs));
      out.push(rel);
    }
  }

  walk(abs);
  return out;
}

function statSize(relPath) {
  const abs = path.join(process.cwd(), relPath);
  const raw = fs.readFileSync(abs);
  // GitHub raw serves text files with LF bytes from git blob. On Windows
  // working tree may be CRLF, so normalize before counting to avoid mismatch.
  if (raw.includes(0)) return raw.length;
  const text = raw.toString("utf8");
  if (Buffer.byteLength(text, "utf8") !== raw.length) return raw.length;
  return Buffer.byteLength(text.replace(/\r\n/g, "\n"), "utf8");
}

function main() {
  const version = readText("VERSION").trim();
  if (!isValidSemverSimple(version)) {
    console.error("VERSION invalido: esperado X.Y.Z (somente numeros) sem zeros a esquerda");
    process.exit(1);
  }

  const preserveSet = new Set([
    "config.ini",
    "data/mappings.json",
  ]);

  const explicit = [
    "startup.lua",
    "config.ini",
    "tests/run.lua",
    "tools/install.lua",
    "data/mappings.json",
  ];

  const allowlistedLuaDirs = [
    "lib",
    "modules",
    "components",
  ];

  const paths = new Set();
  for (const p of explicit) paths.add(p);
  for (const dir of allowlistedLuaDirs) {
    for (const p of listLuaFilesUnder(dir)) paths.add(p);
  }

  const files = Array.from(paths)
    .filter((p) => p !== "manifest.json")
    .sort((a, b) => a.localeCompare(b))
    .map((p) => {
      if (!fs.existsSync(p)) {
        console.error("Arquivo faltando (allowlist): " + p);
        process.exit(1);
      }
      const obj = { path: p, size: statSize(p) };
      if (preserveSet.has(p)) obj.preserve = true;
      return obj;
    });

  const manifest = {
    manifest_version: 2,
    version,
    generated_utc: isoUtcNoMs(),
    files,
  };

  fs.writeFileSync("manifest.json", JSON.stringify(manifest, null, 2) + "\n", "utf8");
  console.log("OK: manifest.json gerado (" + files.length + " arquivos)");
}

main();
