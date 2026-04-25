#!/usr/bin/env node
/**
 * Lee .zentto/security/{semgrep,trivy,osv}.json y produce REPORT.md +
 * exit code coherente con --fail-on (none|critical|high|medium).
 *
 * Uso: node scripts/security-aggregate.cjs --fail-on=critical
 */
"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const REPO_ROOT = path.resolve(ROOT, "..", "..");
const OUT_DIR = path.join(REPO_ROOT, ".zentto", "security");
const SEMGREP = path.join(OUT_DIR, "semgrep.json");
const TRIVY = path.join(OUT_DIR, "trivy.json");
const OSV = path.join(OUT_DIR, "osv.json");

const args = process.argv.slice(2);
let failOn = "none";
for (const a of args) if (a.startsWith("--fail-on=")) failOn = a.split("=")[1].toLowerCase();

function loadJson(p) {
  if (!fs.existsSync(p)) return null;
  try { return JSON.parse(fs.readFileSync(p, "utf8")); }
  catch (e) { return { __parseError: e.message }; }
}

function summarize() {
  const semgrep = loadJson(SEMGREP);
  const trivy = loadJson(TRIVY);
  const osv = loadJson(OSV);

  const out = [];
  out.push("# Security Baseline Report");
  out.push("");
  out.push(`Generated: ${new Date().toISOString()}`);
  out.push(`Mode: \`fail-on=${failOn}\``);
  out.push("");

  // SEMGREP
  out.push("## 1. Semgrep (SAST)");
  out.push("");
  let sgCrit = 0, sgHigh = 0;
  if (!semgrep || semgrep.__parseError) {
    out.push(semgrep?.__parseError ? `_Parse error: ${semgrep.__parseError}_` : "_Not run._");
  } else {
    const results = semgrep.results || [];
    const bySev = {};
    const byRule = {};
    for (const r of results) {
      const sev = r.extra?.severity || "INFO";
      bySev[sev] = (bySev[sev] || 0) + 1;
      const rule = r.check_id || "unknown";
      byRule[rule] = (byRule[rule] || 0) + 1;
    }
    sgCrit = bySev.ERROR || 0;
    sgHigh = bySev.WARNING || 0;
    out.push(`Total findings: **${results.length}** | Rules ran: ${semgrep.paths?.scanned?.length ? "scanned " + semgrep.paths.scanned.length + " files" : "n/a"}`);
    out.push("");
    out.push("| Severity | Count |");
    out.push("|----------|------:|");
    out.push(`| ERROR (critical) | ${sgCrit} |`);
    out.push(`| WARNING (high)   | ${sgHigh} |`);
    out.push(`| INFO             | ${bySev.INFO || 0} |`);
    out.push("");
    if (results.length) {
      const top = Object.entries(byRule).sort((a, b) => b[1] - a[1]).slice(0, 10);
      out.push("### Top 10 rules");
      out.push("");
      out.push("| Rule | Count |");
      out.push("|------|------:|");
      for (const [r, n] of top) out.push(`| \`${r}\` | ${n} |`);
      out.push("");
      const crits = results.filter(r => (r.extra?.severity || "") === "ERROR");
      if (crits.length) {
        out.push("### Critical findings");
        out.push("");
        for (const c of crits.slice(0, 30)) {
          const file = (c.path || "?").replace(/^\/repo\//, "");
          out.push(`- \`${c.check_id}\` — ${file}:${c.start?.line || "?"}`);
        }
        out.push("");
      }
    }
  }

  // TRIVY
  out.push("## 2. Trivy (deps + IaC + Secrets)");
  out.push("");
  let trCrit = 0, trHigh = 0;
  let trCritList = [];
  if (!trivy || trivy.__parseError) {
    out.push(trivy?.__parseError ? `_Parse error: ${trivy.__parseError}_` : "_Not run._");
  } else {
    const results = trivy.Results || [];
    const vsev = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };
    const msev = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };
    let secrets = 0;
    const critHigh = [];
    for (const res of results) {
      for (const v of res.Vulnerabilities || []) {
        const s = v.Severity || "UNKNOWN";
        if (vsev[s] !== undefined) vsev[s]++;
        if (s === "CRITICAL" || s === "HIGH") {
          critHigh.push({ sev: s, pkg: v.PkgName, installed: v.InstalledVersion, fixed: v.FixedVersion, id: v.VulnerabilityID });
        }
      }
      for (const m of res.Misconfigurations || []) {
        const s = m.Severity || "UNKNOWN";
        if (msev[s] !== undefined) msev[s]++;
      }
      secrets += (res.Secrets || []).length;
    }
    trCrit = vsev.CRITICAL + msev.CRITICAL;
    trHigh = vsev.HIGH + msev.HIGH;
    trCritList = critHigh.filter(v => v.sev === "CRITICAL");
    out.push("### Vulnerabilities (deps)");
    out.push("");
    out.push("| Severity | Count |");
    out.push("|----------|------:|");
    out.push(`| CRITICAL | ${vsev.CRITICAL} |`);
    out.push(`| HIGH     | ${vsev.HIGH} |`);
    out.push(`| MEDIUM   | ${vsev.MEDIUM} |`);
    out.push(`| LOW      | ${vsev.LOW} |`);
    out.push("");
    if (critHigh.length) {
      const seen = new Set();
      const dedup = critHigh.filter(v => { const k = `${v.pkg}@${v.installed}@${v.id}`; if (seen.has(k)) return false; seen.add(k); return true; });
      out.push(`### CRITICAL/HIGH dependency vulns (${dedup.length})`);
      out.push("");
      out.push("| Sev | Package | Installed | Fixed | CVE |");
      out.push("|-----|---------|-----------|-------|-----|");
      for (const v of dedup.slice(0, 50)) out.push(`| ${v.sev} | \`${v.pkg}\` | ${v.installed} | ${v.fixed || "—"} | ${v.id} |`);
      if (dedup.length > 50) out.push(`_(+${dedup.length - 50} more)_`);
      out.push("");
    }
    out.push(`Misconfigs: CRITICAL=${msev.CRITICAL} HIGH=${msev.HIGH} | Secrets: **${secrets}**`);
    out.push("");
  }

  // OSV
  out.push("## 3. OSV-Scanner (deps cross-check)");
  out.push("");
  let osvCrit = 0, osvHigh = 0;
  if (!osv || osv.__parseError) {
    out.push(osv?.__parseError ? `_Parse error: ${osv.__parseError}_` : "_Not run._");
  } else {
    const results = osv.results || [];
    const sev = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0, UNKNOWN: 0 };
    const byPkg = {};
    for (const r of results) for (const p of r.packages || []) {
      for (const g of p.groups || []) {
        const s = parseFloat(g.max_severity);
        let bucket = "UNKNOWN";
        if (!isNaN(s)) {
          if (s >= 9.0) bucket = "CRITICAL";
          else if (s >= 7.0) bucket = "HIGH";
          else if (s >= 4.0) bucket = "MEDIUM";
          else if (s > 0) bucket = "LOW";
        }
        sev[bucket]++;
        const key = `${p.package?.name}@${p.package?.version}`;
        byPkg[key] = byPkg[key] || { count: 0, top: [] };
        byPkg[key].count++;
        if (byPkg[key].top.length < 3) byPkg[key].top.push((g.ids || [])[0] || "?");
      }
    }
    osvCrit = sev.CRITICAL;
    osvHigh = sev.HIGH;
    out.push(`Total: **${Object.values(sev).reduce((a, b) => a + b, 0)}** vulns across **${Object.keys(byPkg).length}** packages`);
    out.push("");
    out.push("| Severity | Count |");
    out.push("|----------|------:|");
    out.push(`| CRITICAL | ${sev.CRITICAL} |`);
    out.push(`| HIGH     | ${sev.HIGH} |`);
    out.push(`| MEDIUM   | ${sev.MEDIUM} |`);
    out.push(`| LOW      | ${sev.LOW} |`);
    out.push(`| UNKNOWN  | ${sev.UNKNOWN} |`);
    out.push("");
    if (Object.keys(byPkg).length) {
      const sorted = Object.entries(byPkg).sort((a, b) => b[1].count - a[1].count);
      out.push(`### Affected packages (top 20)`);
      out.push("");
      out.push("| Package | Vulns | Top IDs |");
      out.push("|---------|------:|---------|");
      for (const [pkg, info] of sorted.slice(0, 20)) {
        out.push(`| \`${pkg}\` | ${info.count} | ${info.top.join(", ")} |`);
      }
      out.push("");
    }
  }

  // GATE
  out.push(`## 4. Gate decision (fail-on: ${failOn})`);
  out.push("");
  const totals = {
    critical: sgCrit + trCrit + osvCrit,
    high: sgHigh + trHigh + osvHigh,
  };
  out.push(`- Semgrep: critical=${sgCrit} high=${sgHigh}`);
  out.push(`- Trivy:   critical=${trCrit} high=${trHigh}`);
  out.push(`- OSV:     critical=${osvCrit} high=${osvHigh}`);
  out.push("");

  let fails = 0;
  if (failOn === "critical") fails = totals.critical;
  else if (failOn === "high") fails = totals.critical + totals.high;
  else if (failOn === "medium") fails = totals.critical + totals.high; // TODO: add medium
  else fails = 0;

  out.push(`### Verdict: ${fails === 0 ? "✅ PASS — gate would not block CI" : `❌ FAIL — ${fails} finding(s) at threshold "${failOn}"`}`);

  return { md: out.join("\n"), fails };
}

const { md, fails } = summarize();
const reportFile = path.join(OUT_DIR, "REPORT.md");
fs.writeFileSync(reportFile, md);
console.log(md);
console.log(`\n→ Written to: ${reportFile}`);
process.exit(fails > 0 ? 1 : 0);
