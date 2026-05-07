#!/usr/bin/env bun
/**
 * Analyze a Go and/or TypeScript codebase and emit a Mermaid architecture diagram.
 *
 * Module       = directory containing source files.
 * Interface    = exported top-level symbols (Go: capitalized; TS: `export`).
 * Implementation = non-blank, non-comment lines of code.
 * Module ratio = LOC / interface_count.
 *
 * Each module renders as a Mermaid subgraph (direction TB, so its symbols stack
 * vertically). Each public symbol becomes a node showing kind, signature, body
 * LOC, and (for callables) a per-symbol ratio = body_LOC / max(param_count, 1).
 *
 * Edges go FROM a callable's body TO every public symbol it references in another
 * (or the same) module — so the call graph is at the function level. The diagram
 * is `flowchart LR`, so flow naturally reads left-to-right from entry points.
 *
 * Usage:
 *   bun analyze.ts [TARGET_DIR]
 */

import { readdirSync, readFileSync, existsSync, statSync } from "node:fs";
import { resolve, relative, join, dirname, extname, sep } from "node:path";

const ROOT = resolve(process.argv[2] ?? ".");
const GO_EXT = new Set([".go"]);
const TS_EXT = new Set([".ts", ".tsx"]);
const SKIP_DIRS = new Set([
  ".git", "node_modules", "vendor", "dist", "build",
  ".next", "out", ".svelte-kit", ".turbo", ".cache", "coverage",
]);
const TEST_RE = /(?:_test\.go|\.test\.tsx?|\.spec\.tsx?)$/;
const MAX_DECLS_PER_MODULE = 15;
const SIG_MAX_CHARS = 140;
const SYM_MIN_WIDTH_PX = 360;
const RANK_SPACING_PX = 180;
const NODE_SPACING_PX = 40;

type Lang = "go" | "ts";

type Decl = {
  kind: string;
  name: string;
  display: string;
  bodyLOC: number;
  paramCount: number;
  hasBody: boolean;
  isCallable: boolean;
  filePath: string;
  bodyStart: number;
  bodyEnd: number;
};

function langOf(p: string): Lang | null {
  const ext = extname(p);
  if (GO_EXT.has(ext)) return "go";
  if (TS_EXT.has(ext)) return "ts";
  return null;
}

function collectFiles(root: string): string[] {
  const out: string[] = [];
  const walk = (dir: string) => {
    let entries;
    try { entries = readdirSync(dir, { withFileTypes: true }); }
    catch { return; }
    for (const e of entries) {
      if (e.isDirectory()) {
        if (SKIP_DIRS.has(e.name) || e.name.startsWith(".")) continue;
        walk(join(dir, e.name));
      } else if (e.isFile()) {
        const fp = join(dir, e.name);
        if (langOf(fp) && !TEST_RE.test(e.name)) out.push(fp);
      }
    }
  };
  walk(root);
  return out;
}

const BLOCK_COMMENT = /\/\*[\s\S]*?\*\//g;
const LINE_COMMENT = /\/\/[^\n]*/g;

function stripComments(src: string): string {
  return src.replace(BLOCK_COMMENT, "").replace(LINE_COMMENT, "");
}

function blankCommentsAndStrings(src: string): string {
  let out = src.replace(BLOCK_COMMENT, (m) => m.replace(/[^\n]/g, " "));
  out = out.replace(LINE_COMMENT, (m) => " ".repeat(m.length));
  out = out.replace(/"((?:\\.|[^"\\])*)"/g, (_, b: string) => '"' + " ".repeat(b.length) + '"');
  out = out.replace(/'((?:\\.|[^'\\])*)'/g, (_, b: string) => "'" + " ".repeat(b.length) + "'");
  out = out.replace(/`((?:\\.|[^`\\])*)`/g, (_, b: string) => "`" + " ".repeat(b.length) + "`");
  return out;
}

function loc(src: string): number {
  const stripped = stripComments(src);
  let n = 0;
  for (const line of stripped.split("\n")) if (line.trim()) n++;
  return n;
}

function nonBlankLines(s: string): number {
  let n = 0;
  for (const line of s.split("\n")) if (line.trim()) n++;
  return n;
}

function findBodyBrace(blanked: string, startIdx: number): number {
  let parenDepth = 0;
  for (let i = startIdx; i < blanked.length; i++) {
    const c = blanked[i];
    if (c === "(") parenDepth++;
    else if (c === ")") { if (parenDepth > 0) parenDepth--; }
    else if (c === "{" && parenDepth === 0) return i;
    else if (c === ";" && parenDepth === 0) return -1;
  }
  return -1;
}

function braceMatch(blanked: string, openIdx: number): number {
  let depth = 1;
  for (let i = openIdx + 1; i < blanked.length; i++) {
    const c = blanked[i];
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function findParenGroup(blanked: string, startIdx: number, which: number): string | null {
  let i = startIdx;
  let skipped = 0;
  while (i < blanked.length) {
    const c = blanked[i];
    if (c === "(") {
      let depth = 1;
      const start = i + 1;
      i++;
      while (i < blanked.length && depth > 0) {
        if (blanked[i] === "(") depth++;
        else if (blanked[i] === ")") depth--;
        i++;
      }
      skipped++;
      if (skipped === which) return blanked.slice(start, i - 1);
    } else if (c === "{") {
      return null;
    } else {
      i++;
    }
  }
  return null;
}

function countParams(group: string | null): number {
  if (group === null) return 0;
  const trimmed = group.trim();
  if (!trimmed) return 0;
  let depth = 0;
  let count = 1;
  for (const c of trimmed) {
    if (c === "(" || c === "[" || c === "{" || c === "<") depth++;
    else if (c === ")" || c === "]" || c === "}" || c === ">") depth--;
    else if (c === "," && depth === 0) count++;
  }
  return count;
}

function squashSig(s: string): string {
  return s.replace(/\s+/g, " ").trim();
}

function truncate(s: string, n: number): string {
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

function sanitizeLabel(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/\|/g, "&#124;");
}

function extractGoDecls(src: string, blanked: string, filePath: string): { decls: Decl[]; isMainPkg: boolean } {
  const out: Decl[] = [];
  const isMainPkg = /^package\s+main\b/m.test(blanked);

  const fnRe = isMainPkg
    ? /^func\s+(?:\(([^)]*)\)\s+)?([A-Z]\w*|main)\b/gm
    : /^func\s+(?:\(([^)]*)\)\s+)?([A-Z]\w*)\b/gm;
  for (const m of blanked.matchAll(fnRe)) {
    const startIdx = m.index!;
    const name = m[2];
    const isMethod = !!m[1];
    const openIdx = findBodyBrace(blanked, startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    if (closeIdx < 0) continue;
    const sig = squashSig(src.slice(startIdx, openIdx));
    const bodyLOC = nonBlankLines(blanked.slice(openIdx + 1, closeIdx));
    const groupIdx = isMethod ? 2 : 1;
    const paramCount = countParams(findParenGroup(blanked, startIdx, groupIdx));
    out.push({
      kind: isMethod ? "method" : "func",
      name, display: sig, bodyLOC, paramCount, hasBody: true, isCallable: true,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
    });
  }

  const typeStructRe = /^type\s+([A-Z]\w*)\s+(struct|interface)\s*\{/gm;
  for (const m of blanked.matchAll(typeStructRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const kind = m[2];
    const openIdx = blanked.indexOf("{", startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    const bodyLOC = closeIdx > 0 ? nonBlankLines(blanked.slice(openIdx + 1, closeIdx)) : 1;
    out.push({
      kind: kind === "struct" ? "struct" : "interface",
      name, display: `type ${name} ${kind}`,
      bodyLOC: Math.max(bodyLOC, 1), paramCount: 0, hasBody: true, isCallable: false,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx >= 0 ? closeIdx : openIdx + 1,
    });
  }

  const typeAliasRe = /^type\s+([A-Z]\w*)\s+(?!struct\s|interface\s)([^\n]+)$/gm;
  for (const m of blanked.matchAll(typeAliasRe)) {
    const name = m[1];
    const startIdx = m.index!;
    const lineEnd = src.indexOf("\n", startIdx);
    const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
    out.push({
      kind: "type", name, display: sig, bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
      filePath, bodyStart: -1, bodyEnd: -1,
    });
  }

  const varRe = /^(var|const)\s+([A-Z]\w*)([^\n]*)$/gm;
  for (const m of blanked.matchAll(varRe)) {
    const kw = m[1];
    const name = m[2];
    const startIdx = m.index!;
    const lineEnd = src.indexOf("\n", startIdx);
    const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
    out.push({
      kind: kw, name, display: sig, bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
      filePath, bodyStart: -1, bodyEnd: -1,
    });
  }

  return { decls: out, isMainPkg };
}

function extractTsDecls(src: string, blanked: string, filePath: string): Decl[] {
  const out: Decl[] = [];

  const fnRe = /^export\s+(?:default\s+)?(?:async\s+)?function\s*\*?\s+(\w+)/gm;
  for (const m of blanked.matchAll(fnRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const openIdx = findBodyBrace(blanked, startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    if (closeIdx < 0) continue;
    const sig = squashSig(src.slice(startIdx, openIdx));
    const bodyLOC = nonBlankLines(blanked.slice(openIdx + 1, closeIdx));
    const paramCount = countParams(findParenGroup(blanked, startIdx, 1));
    out.push({
      kind: "func", name, display: sig, bodyLOC, paramCount, hasBody: true, isCallable: true,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
    });
  }

  const classRe = /^export\s+(?:default\s+)?(?:abstract\s+)?class\s+(\w+)/gm;
  for (const m of blanked.matchAll(classRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const openIdx = findBodyBrace(blanked, startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    if (closeIdx < 0) continue;
    const sig = squashSig(src.slice(startIdx, openIdx));
    const bodyLOC = nonBlankLines(blanked.slice(openIdx + 1, closeIdx));
    out.push({
      kind: "class", name, display: sig, bodyLOC, paramCount: 0, hasBody: true, isCallable: false,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
    });
  }

  const interfaceRe = /^export\s+interface\s+(\w+)/gm;
  for (const m of blanked.matchAll(interfaceRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const openIdx = findBodyBrace(blanked, startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    if (closeIdx < 0) continue;
    const sig = squashSig(src.slice(startIdx, openIdx));
    const bodyLOC = nonBlankLines(blanked.slice(openIdx + 1, closeIdx));
    out.push({
      kind: "interface", name, display: sig, bodyLOC, paramCount: 0, hasBody: true, isCallable: false,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
    });
  }

  const enumRe = /^export\s+(?:const\s+)?enum\s+(\w+)/gm;
  for (const m of blanked.matchAll(enumRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const openIdx = findBodyBrace(blanked, startIdx);
    if (openIdx < 0) continue;
    const closeIdx = braceMatch(blanked, openIdx);
    if (closeIdx < 0) continue;
    const sig = squashSig(src.slice(startIdx, openIdx));
    const bodyLOC = nonBlankLines(blanked.slice(openIdx + 1, closeIdx));
    out.push({
      kind: "enum", name, display: sig, bodyLOC, paramCount: 0, hasBody: true, isCallable: false,
      filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
    });
  }

  const typeRe = /^export\s+type\s+(\w+)/gm;
  for (const m of blanked.matchAll(typeRe)) {
    const startIdx = m.index!;
    const name = m[1];
    const lineEnd = src.indexOf("\n", startIdx);
    const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
    out.push({
      kind: "type", name, display: sig, bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
      filePath, bodyStart: -1, bodyEnd: -1,
    });
  }

  const varRe = /^export\s+(?:default\s+)?(const|let|var)\s+(\w+)/gm;
  for (const m of blanked.matchAll(varRe)) {
    const startIdx = m.index!;
    const kw = m[1];
    const name = m[2];
    const lineEnd = src.indexOf("\n", startIdx);
    const eqIdx = blanked.indexOf("=", startIdx);

    if (eqIdx < 0 || (lineEnd > 0 && eqIdx > lineEnd && !/[=({]/.test(blanked.slice(startIdx, lineEnd)))) {
      const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
      out.push({
        kind: kw, name, display: sig, bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
        filePath, bodyStart: -1, bodyEnd: -1,
      });
      continue;
    }

    const afterEq = blanked.slice(eqIdx + 1);
    const trimmed = afterEq.trimStart();
    const arrowFnHead = /^(?:async\s+)?(?:<[^>]*>\s*)?\(/.test(trimmed) || /^(?:async\s+)?\w+\s*=>/.test(trimmed);
    const fnExpr = /^(?:async\s+)?function\b/.test(trimmed);

    if (arrowFnHead || fnExpr) {
      const openIdx = findBodyBrace(blanked, eqIdx + 1);
      const paramCount = countParams(findParenGroup(blanked, eqIdx + 1, 1));
      if (openIdx < 0) {
        const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
        out.push({
          kind: "func", name, display: sig, bodyLOC: 1, paramCount, hasBody: false, isCallable: true,
          filePath, bodyStart: -1, bodyEnd: -1,
        });
        continue;
      }
      const closeIdx = braceMatch(blanked, openIdx);
      const bodyLOC = closeIdx > 0 ? nonBlankLines(blanked.slice(openIdx + 1, closeIdx)) : 0;
      const sig = squashSig(src.slice(startIdx, openIdx));
      out.push({
        kind: "func", name, display: sig, bodyLOC, paramCount, hasBody: true, isCallable: true,
        filePath, bodyStart: openIdx + 1, bodyEnd: closeIdx,
      });
    } else {
      const sig = squashSig(src.slice(startIdx, lineEnd > 0 ? lineEnd : src.length));
      out.push({
        kind: kw, name, display: sig, bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
        filePath, bodyStart: -1, bodyEnd: -1,
      });
    }
  }

  const reExportRe = /export\s*\{([^}]+)\}\s*(?:from\s+['"][^'"]+['"])?/g;
  for (const m of blanked.matchAll(reExportRe)) {
    for (let n of m[1].split(",")) {
      n = n.trim();
      if (!n) continue;
      if (n.includes(" as ")) n = n.split(" as ")[1].trim();
      if (/^\w+$/.test(n)) {
        out.push({
          kind: "re-export", name: n, display: `re-export ${n}`,
          bodyLOC: 1, paramCount: 0, hasBody: false, isCallable: false,
          filePath, bodyStart: -1, bodyEnd: -1,
        });
      }
    }
  }

  return out;
}

function findGoModule(): { root: string | null; name: string | null } {
  let cur = ROOT;
  while (true) {
    const gm = join(cur, "go.mod");
    if (existsSync(gm)) {
      try {
        const txt = readFileSync(gm, "utf8");
        const m = txt.match(/^module\s+(\S+)/m);
        return { root: cur, name: m ? m[1] : null };
      } catch { return { root: cur, name: null }; }
    }
    const parent = dirname(cur);
    if (parent === cur) return { root: null, name: null };
    cur = parent;
  }
}

function goImports(src: string): Array<[string | null, string]> {
  const stripped = stripComments(src);
  const out: Array<[string | null, string]> = [];
  for (const blk of stripped.matchAll(/import\s*\(\s*([\s\S]*?)\)/g)) {
    for (const line of blk[1].split("\n")) {
      const m = line.trim().match(/^(?:(\w+|\.|_)\s+)?"([^"]+)"/);
      if (m) out.push([m[1] ?? null, m[2]]);
    }
  }
  for (const m of stripped.matchAll(/^import\s+(?:(\w+|\.|_)\s+)?"([^"]+)"/gm)) {
    out.push([m[1] ?? null, m[2]]);
  }
  return out;
}

const TS_IMPORT_RE = /import\s+(?:type\s+)?(?:(\*\s+as\s+\w+)|(\{[^}]*\})|(\w+)(?:\s*,\s*(\{[^}]*\}|\*\s+as\s+\w+))?)\s+from\s+['"]([^'"]+)['"]/gs;

type ImportSpec =
  | { kind: "ns"; alias: string; source: string }
  | { kind: "named"; names: Array<{ local: string; original: string }>; source: string }
  | { kind: "default"; alias: string; source: string };

function parseNamed(block: string): Array<{ local: string; original: string }> {
  const inner = block.replace(/^\{|\}$/g, "").trim();
  const out: Array<{ local: string; original: string }> = [];
  for (let piece of inner.split(",")) {
    piece = piece.trim();
    if (!piece) continue;
    if (piece.startsWith("type ")) piece = piece.slice(5).trim();
    let original: string;
    let local: string;
    if (piece.includes(" as ")) {
      const [o, l] = piece.split(" as ").map((x) => x.trim());
      original = o;
      local = l;
    } else {
      original = piece;
      local = piece;
    }
    if (/^\w+$/.test(local) && /^\w+$/.test(original)) out.push({ local, original });
  }
  return out;
}

function tsImports(src: string): ImportSpec[] {
  const stripped = stripComments(src);
  const out: ImportSpec[] = [];
  for (const m of stripped.matchAll(TS_IMPORT_RE)) {
    const [, ns, named, def, extra, source] = m;
    if (ns) {
      const alias = ns.split(/\s+as\s+/)[1].trim();
      out.push({ kind: "ns", alias, source });
    }
    if (named) {
      out.push({ kind: "named", names: parseNamed(named), source });
    }
    if (def) {
      out.push({ kind: "default", alias: def, source });
      if (extra) {
        if (extra.trim().startsWith("*")) {
          const alias = extra.split(/\s+as\s+/)[1].trim();
          out.push({ kind: "ns", alias, source });
        } else {
          out.push({ kind: "named", names: parseNamed(extra), source });
        }
      }
    }
  }
  return out;
}

function fileModule(p: string): string {
  const rel = relative(ROOT, dirname(resolve(p)));
  const s = rel.split(sep).join("/");
  return s === "" || s === "." ? "." : s;
}

function resolveGoImport(importPath: string, goRoot: string, goName: string): string | null {
  if (!goName || !importPath.startsWith(goName)) return null;
  const sub = importPath.slice(goName.length).replace(/^\/+/, "");
  const absDir = resolve(join(goRoot, sub));
  const rel = relative(ROOT, absDir);
  if (rel.startsWith("..")) return null;
  const s = rel.split(sep).join("/");
  return s === "" || s === "." ? "." : s;
}

function readTsconfigJSONC(start: string): { root: string | null; cfg: any } {
  let cur = start;
  while (true) {
    for (const name of ["tsconfig.json", "jsconfig.json"]) {
      const p = join(cur, name);
      if (existsSync(p)) {
        try {
          let txt = readFileSync(p, "utf8");
          txt = txt.replace(/\/\/[^\n]*/g, "");
          txt = txt.replace(/\/\*[\s\S]*?\*\//g, "");
          txt = txt.replace(/,(\s*[}\]])/g, "$1");
          return { root: cur, cfg: JSON.parse(txt) };
        } catch {
          return { root: cur, cfg: {} };
        }
      }
    }
    const parent = dirname(cur);
    if (parent === cur) return { root: null, cfg: {} };
    cur = parent;
  }
}

function tryStat(p: string): { file: boolean; dir: boolean } {
  try {
    const st = statSync(p);
    return { file: st.isFile(), dir: st.isDirectory() };
  } catch {
    return { file: false, dir: false };
  }
}

function resolveTsImport(
  source: string,
  filePath: string,
  tsRoot: string,
  tsPaths: Record<string, string[]>,
): string | null {
  let candidate: string | null = null;
  if (source.startsWith(".")) {
    candidate = resolve(dirname(filePath), source);
  } else if (Object.keys(tsPaths).length) {
    for (const [pattern, targets] of Object.entries(tsPaths)) {
      const pre = pattern.replace(/\*$/, "");
      if (pattern.endsWith("*") && source.startsWith(pre)) {
        const tail = source.slice(pre.length);
        for (const t of targets) {
          candidate = resolve(join(tsRoot, t.replace(/\*$/, "") + tail));
          break;
        }
        break;
      } else if (source === pattern) {
        for (const t of targets) {
          candidate = resolve(join(tsRoot, t));
          break;
        }
        break;
      }
    }
  }
  if (candidate === null) return null;

  const candStat = tryStat(candidate);
  let target: string | null = null;
  if (candStat.file) {
    target = candidate;
  } else {
    for (const suffix of [".ts", ".tsx", ".d.ts", "/index.ts", "/index.tsx"]) {
      const p = candidate + suffix;
      if (tryStat(p).file) { target = p; break; }
    }
  }
  if (target !== null) {
    const rel = relative(ROOT, dirname(target));
    if (rel.startsWith("..")) return null;
    const s = rel.split(sep).join("/");
    return s === "" || s === "." ? "." : s;
  }
  if (candStat.dir) {
    const rel = relative(ROOT, candidate);
    if (rel.startsWith("..")) return null;
    const s = rel.split(sep).join("/");
    return s === "" || s === "." ? "." : s;
  }
  return null;
}

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

type DeclEntry = { mod: string; decl: Decl };
type EdgeKey = string;
const edgeKey = (a: string, b: string) => `${a}\t${b}`;

function declRefKey(mod: string, name: string): string {
  return `${mod}\t${name}`;
}

function analyze() {
  const files = collectFiles(ROOT);
  if (files.length === 0) {
    console.error("// No Go or TypeScript source files found.");
    return null;
  }

  const { root: goRoot, name: goName } = findGoModule();
  const { root: tsRootDir, cfg: tsCfg } = readTsconfigJSONC(ROOT);
  const co = (tsCfg?.compilerOptions ?? {}) as { baseUrl?: string; paths?: Record<string, string[]> };
  const tsPaths = co.paths ?? {};
  const tsPathsRoot = tsRootDir ? resolve(join(tsRootDir, co.baseUrl ?? ".")) : ROOT;

  const modLoc = new Map<string, number>();
  const modDecls = new Map<string, Map<string, Decl>>();
  const blankedByFile = new Map<string, string>();
  const langByFile = new Map<string, Lang>();
  const modByFile = new Map<string, string>();
  const entryMods = new Set<string>();
  const fileGoImports = new Map<string, Array<[string | null, string]>>();
  const fileTsImports = new Map<string, ImportSpec[]>();

  for (const p of files) {
    let raw: string;
    try { raw = readFileSync(p, "utf8"); }
    catch { continue; }
    const lang = langOf(p)!;
    const mod = fileModule(p);
    const blanked = blankCommentsAndStrings(raw);
    blankedByFile.set(p, blanked);
    langByFile.set(p, lang);
    modByFile.set(p, mod);
    modLoc.set(mod, (modLoc.get(mod) ?? 0) + loc(raw));
    if (!modDecls.has(mod)) modDecls.set(mod, new Map());
    const bag = modDecls.get(mod)!;

    if (lang === "go") {
      const { decls, isMainPkg } = extractGoDecls(raw, blanked, p);
      if (isMainPkg) entryMods.add(mod);
      for (const d of decls) {
        const k = `${d.kind}:${d.name}`;
        const prev = bag.get(k);
        if (!prev || d.bodyLOC > prev.bodyLOC) bag.set(k, d);
      }
      fileGoImports.set(p, goImports(raw));
    } else {
      const decls = extractTsDecls(raw, blanked, p);
      for (const d of decls) {
        const k = `${d.kind}:${d.name}`;
        const prev = bag.get(k);
        if (!prev || d.bodyLOC > prev.bodyLOC) bag.set(k, d);
      }
      fileTsImports.set(p, tsImports(raw));
    }
  }

  const declByRef = new Map<string, DeclEntry>();
  for (const [mod, bag] of modDecls) {
    for (const d of bag.values()) {
      declByRef.set(declRefKey(mod, d.name), { mod, decl: d });
    }
  }

  const declSymsByMod = new Map<string, Set<string>>();
  for (const [mod, bag] of modDecls) {
    declSymsByMod.set(mod, new Set([...bag.values()].map((d) => d.name)));
  }

  const edges = new Map<EdgeKey, number>();
  const bumpEdge = (srcMod: string, srcName: string, dstMod: string, dstName: string, w: number) => {
    if (!declByRef.has(declRefKey(dstMod, dstName))) return;
    if (srcMod === dstMod && srcName === dstName) return;
    const k = edgeKey(declRefKey(srcMod, srcName), declRefKey(dstMod, dstName));
    edges.set(k, (edges.get(k) ?? 0) + w);
  };

  for (const [mod, bag] of modDecls) {
    for (const d of bag.values()) {
      if (!d.isCallable || !d.hasBody || d.bodyStart < 0 || d.bodyEnd < 0) continue;
      const blanked = blankedByFile.get(d.filePath);
      if (!blanked) continue;
      const region = blanked.slice(d.bodyStart, d.bodyEnd);
      const lang = langByFile.get(d.filePath)!;

      if (lang === "go") {
        if (!goRoot || !goName) continue;
        const imps = fileGoImports.get(d.filePath) ?? [];
        for (const [alias, ipath] of imps) {
          const dst = resolveGoImport(ipath, goRoot, goName);
          if (!dst) continue;
          const last = ipath.split("/").pop()!;
          const handle = alias && alias !== "." && alias !== "_" ? alias : last;
          if (alias === ".") {
            const dstSyms = declSymsByMod.get(dst);
            if (!dstSyms) continue;
            for (const sym of dstSyms) {
              const re = new RegExp("\\b" + escapeRegex(sym) + "\\b", "g");
              const hits = [...region.matchAll(re)].length;
              if (hits) bumpEdge(mod, d.name, dst, sym, hits);
            }
          } else if (alias === "_") {
            continue;
          } else {
            const re = new RegExp("\\b" + escapeRegex(handle) + "\\.([A-Z]\\w*)", "g");
            const counts = new Map<string, number>();
            for (const m of region.matchAll(re)) {
              const sym = m[1];
              counts.set(sym, (counts.get(sym) ?? 0) + 1);
            }
            for (const [sym, n] of counts) bumpEdge(mod, d.name, dst, sym, n);
          }
        }
      } else {
        const imps = fileTsImports.get(d.filePath) ?? [];
        for (const imp of imps) {
          const dst = resolveTsImport(imp.source, d.filePath, tsPathsRoot, tsPaths);
          if (!dst) continue;
          if (imp.kind === "ns") {
            const re = new RegExp("\\b" + escapeRegex(imp.alias) + "\\.(\\w+)", "g");
            const counts = new Map<string, number>();
            for (const m of region.matchAll(re)) {
              const sym = m[1];
              counts.set(sym, (counts.get(sym) ?? 0) + 1);
            }
            for (const [sym, n] of counts) bumpEdge(mod, d.name, dst, sym, n);
          } else if (imp.kind === "default") {
            // No reliable dst symbol name; skip.
            continue;
          } else {
            for (const { local, original } of imp.names) {
              const re = new RegExp("\\b" + escapeRegex(local) + "\\b", "g");
              const hits = [...region.matchAll(re)].length;
              if (hits > 0) bumpEdge(mod, d.name, dst, original, hits);
            }
          }
        }
      }
    }
  }

  return { modLoc, modDecls, edges, entryMods };
}

function bucket(value: number, sorted: number[]): number {
  if (sorted.length === 0) return 2;
  const n = sorted.length;
  const qs = [0.2, 0.4, 0.6, 0.8];
  for (let i = 0; i < qs.length; i++) {
    const idx = Math.min(Math.floor(n * qs[i]), n - 1);
    if (value <= sorted[idx]) return i;
  }
  return 4;
}

function edgeThickness(weight: number, sorted: number[]): number {
  if (sorted.length === 0) return 1;
  const n = sorted.length;
  const qs = [0.4, 0.7, 0.9];
  for (let i = 0; i < qs.length; i++) {
    const idx = Math.min(Math.floor(n * qs[i]), n - 1);
    if (weight <= sorted[idx]) return i + 1;
  }
  return 4;
}

function slug(mod: string): string {
  let s = mod.replace(/[^A-Za-z0-9]/g, "_");
  if (!s || !/^[A-Za-z_]/.test(s)) s = "m_" + s;
  return s;
}

function symbolRatio(d: Decl): number | null {
  if (!d.isCallable) return null;
  return d.bodyLOC / Math.max(d.paramCount, 1);
}

function symbolNodeId(mod: string, name: string): string {
  return `${slug(mod)}__${slug(name)}`;
}

function kindClass(kind: string): string {
  switch (kind) {
    case "func":
    case "method":
      return "k0";
    case "class":
      return "k1";
    case "interface":
      return "k2";
    case "struct":
      return "k3";
    case "enum":
      return "k4";
    case "type":
      return "k5";
    case "var":
    case "const":
    case "let":
      return "k6";
    case "re-export":
      return "k7";
    default:
      return "k8";
  }
}

const SYMBOL_LABEL_CSS =
  `.sb{text-align:left;min-width:${SYM_MIN_WIDTH_PX}px;padding:6px 10px;` +
  `font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:13px;line-height:1.4}` +
  `.sn{color:#111;font-weight:bold}` +
  `.ss{color:#333}` +
  `.sm{font-size:11px;margin-top:4px}` +
  `.sl{color:#999}` +
  `.sv{color:#222;font-weight:600}` +
  `.k0{color:#0660c0}.k1{color:#a02060}.k2{color:#066050}.k3{color:#a05010}` +
  `.k4{color:#5020a0}.k5{color:#666}.k6{color:#888}.k7{color:#999}.k8{color:#444}`;

function formatSymbolLabel(d: Decl): string {
  const sigRaw = truncate(d.display, SIG_MAX_CHARS);
  const sigSafe = sanitizeLabel(sigRaw);
  const nameSafe = sanitizeLabel(d.name);
  const kc = kindClass(d.kind);

  const idx = sigSafe.indexOf(nameSafe);
  let sigHtml: string;
  if (idx >= 0) {
    const before = sigSafe.slice(0, idx);
    const after = sigSafe.slice(idx + nameSafe.length);
    sigHtml =
      `<span class='${kc}'>${before}</span>` +
      `<b class='sn'>${nameSafe}</b>` +
      `<span class='ss'>${after}</span>`;
  } else {
    sigHtml = `<span class='ss'>${sigSafe}</span>`;
  }

  let metricsHtml = "";
  if (d.isCallable && d.hasBody) {
    const r = symbolRatio(d)!;
    metricsHtml =
      `<div class='sm'>` +
      `<span class='sl'>L:</span><span class='sv'>${d.bodyLOC}</span>&nbsp;&nbsp;` +
      `<span class='sl'>P:</span><span class='sv'>${d.paramCount}</span>&nbsp;&nbsp;` +
      `<span class='sl'>R:</span><span class='sv'>${r.toFixed(1)}</span>` +
      `</div>`;
  } else if (d.hasBody) {
    metricsHtml =
      `<div class='sm'><span class='sl'>L:</span><span class='sv'>${d.bodyLOC}</span></div>`;
  }

  return `<div class='sb'><div>${sigHtml}</div>${metricsHtml}</div>`;
}

function emit(
  modLoc: Map<string, number>,
  modDecls: Map<string, Map<string, Decl>>,
  edges: Map<string, number>,
  entryMods: Set<string>,
) {
  const modules = Array.from(new Set([...modLoc.keys(), ...modDecls.keys()])).sort();
  if (modules.length === 0) {
    console.log("// No modules detected.");
    return;
  }

  const moduleRatio = new Map<string, number>();
  for (const m of modules) {
    const declCount = modDecls.get(m)?.size ?? 0;
    if (declCount > 0 && !entryMods.has(m)) {
      moduleRatio.set(m, (modLoc.get(m) ?? 0) / declCount);
    }
  }
  const sortedModRatios = [...moduleRatio.values()].sort((a, b) => a - b);

  const allSymRatios: number[] = [];
  for (const bag of modDecls.values()) {
    for (const d of bag.values()) {
      const r = symbolRatio(d);
      if (r !== null) allSymRatios.push(r);
    }
  }
  allSymRatios.sort((a, b) => a - b);

  const visibleDecls = new Map<string, Decl[]>();
  for (const m of modules) {
    const bag = modDecls.get(m) ?? new Map<string, Decl>();
    const declList = [...bag.values()].sort((a, b) => b.bodyLOC - a.bodyLOC);
    visibleDecls.set(m, declList.slice(0, MAX_DECLS_PER_MODULE));
  }
  const visibleSet = new Set<string>();
  for (const [m, list] of visibleDecls) {
    for (const d of list) visibleSet.add(declRefKey(m, d.name));
  }

  const modBucketStyles = [
    "fill:#fde2e2,stroke:#b22,stroke-width:1px",
    "fill:#ffe9c8,stroke:#a63,stroke-width:1px",
    "fill:#f3f3f3,stroke:#666,stroke-width:1px",
    "fill:#e2f0d9,stroke:#373,stroke-width:2px",
    "fill:#cfe9bd,stroke:#161,stroke-width:2px",
  ];
  const modEntryStyle = "fill:#f5f5f5,stroke:#888,stroke-width:1px,stroke-dasharray:4 2";

  const symBucketStyles = [
    "fill:#fff,stroke:#b22,stroke-width:1px",
    "fill:#fff,stroke:#a63,stroke-width:1px",
    "fill:#fff,stroke:#666,stroke-width:1px",
    "fill:#fff,stroke:#373,stroke-width:2px",
    "fill:#fff,stroke:#161,stroke-width:3px",
  ];
  const symInertStyle = "fill:#fafafa,stroke:#aaa,stroke-width:1px";

  const weights = [...edges.values()].sort((a, b) => a - b);

  console.log("%% Architecture diagram generated by architecture-diagram skill.");
  console.log("%% flowchart LR — flow reads left-to-right; entry points (no incoming edges) sit on the left.");
  console.log("%% Subgraphs = modules (direction TB so symbols stack vertically).");
  console.log("%% Inner nodes = public symbols. Edges = function-level call references resolved via imports.");
  console.log("%% Labels use HTML; viewer must run Mermaid in 'loose' securityLevel (mermaid.live and VS Code default).");
  const initConfig = {
    maxTextSize: 5000000,
    maxEdges: 10000,
    flowchart: {
      htmlLabels: true,
      rankSpacing: RANK_SPACING_PX,
      nodeSpacing: NODE_SPACING_PX,
      curve: "basis",
      padding: 20,
      useMaxWidth: false,
    },
    themeCSS: SYMBOL_LABEL_CSS,
    securityLevel: "loose",
  };
  console.log(`%%{init: ${JSON.stringify(initConfig)}}%%`);
  console.log("flowchart LR");

  for (let i = 0; i < modBucketStyles.length; i++) {
    console.log(`  classDef mod${i} ${modBucketStyles[i]}`);
  }
  console.log(`  classDef modEntry ${modEntryStyle}`);
  for (let i = 0; i < symBucketStyles.length; i++) {
    console.log(`  classDef sym${i} ${symBucketStyles[i]}`);
  }
  console.log(`  classDef symInert ${symInertStyle}`);

  for (const m of modules) {
    const bag = modDecls.get(m) ?? new Map<string, Decl>();
    const declList = [...bag.values()].sort((a, b) => b.bodyLOC - a.bodyLOC);
    const iCount = declList.length;
    const lCount = modLoc.get(m) ?? 0;
    const labelPath = m === "." ? "(root)" : m;
    const modSlug = slug(m) || "root";

    const pathSafe = sanitizeLabel(labelPath);
    let header: string;
    let modClass: string;
    if (entryMods.has(m)) {
      header = `${pathSafe} • entry • L:${lCount}`;
      modClass = "modEntry";
    } else if (iCount === 0) {
      header = `${pathSafe} • entry • L:${lCount}`;
      modClass = "modEntry";
    } else {
      const r = moduleRatio.get(m)!;
      header = `${pathSafe} • I:${iCount} L:${lCount} R:${r.toFixed(1)}`;
      modClass = `mod${bucket(r, sortedModRatios)}`;
    }

    console.log(`  subgraph ${modSlug}["${header}"]`);
    console.log(`    direction TB`);

    if (iCount === 0) {
      console.log(`    ${modSlug}_empty[" "]:::symInert`);
    } else {
      const shown = declList.slice(0, MAX_DECLS_PER_MODULE);
      const overflow = declList.length - shown.length;
      for (const d of shown) {
        const id = symbolNodeId(m, d.name);
        let cls: string;
        if (d.isCallable && d.hasBody) {
          cls = `sym${bucket(symbolRatio(d)!, allSymRatios)}`;
        } else if (d.hasBody) {
          cls = `sym${bucket(d.bodyLOC, allSymRatios)}`;
        } else {
          cls = "symInert";
        }
        console.log(`    ${id}["${formatSymbolLabel(d)}"]:::${cls}`);
      }
      if (overflow > 0) {
        console.log(`    ${modSlug}__more["+ ${overflow} more"]:::symInert`);
      }
    }
    console.log(`  end`);
    console.log(`  class ${modSlug} ${modClass}`);
  }

  if (edges.size > 0) {
    console.log("");
    type EdgeRow = { srcMod: string; srcName: string; dstMod: string; dstName: string; w: number };
    const rows: EdgeRow[] = [];
    for (const [k, w] of edges) {
      const parts = k.split("\t");
      if (parts.length !== 4) continue;
      rows.push({ srcMod: parts[0], srcName: parts[1], dstMod: parts[2], dstName: parts[3], w });
    }
    const aggregated = new Map<string, number>();
    for (const r of rows) {
      const srcRef = declRefKey(r.srcMod, r.srcName);
      const dstRef = declRefKey(r.dstMod, r.dstName);
      const srcId = visibleSet.has(srcRef) ? symbolNodeId(r.srcMod, r.srcName) : slug(r.srcMod);
      const dstId = visibleSet.has(dstRef) ? symbolNodeId(r.dstMod, r.dstName) : slug(r.dstMod);
      const key = `${srcId}\t${dstId}`;
      aggregated.set(key, (aggregated.get(key) ?? 0) + r.w);
    }
    const finalRows = [...aggregated.entries()]
      .map(([k, w]) => { const [s, d] = k.split("\t"); return { s, d, w }; })
      .sort((x, y) => x.s.localeCompare(y.s) || x.d.localeCompare(y.d));
    const emitted: number[] = [];
    for (const r of finalRows) {
      console.log(`  ${r.s} -->|${r.w}| ${r.d}`);
      emitted.push(r.w);
    }
    console.log("");
    emitted.forEach((w, idx) => {
      const t = edgeThickness(w, weights);
      console.log(`  linkStyle ${idx} stroke-width:${t}px`);
    });
  }
}

const result = analyze();
if (result) emit(result.modLoc, result.modDecls, result.edges, result.entryMods);
