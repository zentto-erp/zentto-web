#!/usr/bin/env node
/**
 * Security precheck — reproduce el escaneo Trivy + Semgrep + OSV
 * que corre el workflow reutilizable zentto-erp/.github/security.yml.
 *
 * Uso:
 *   node scripts/security-precheck.cjs              # modo report (no falla)
 *   node scripts/security-precheck.cjs --strict     # mismo gate que CI (fail-on critical)
 *   node scripts/security-precheck.cjs --fail-on=high
 *   node scripts/security-precheck.cjs --skip=trivy,osv
 *
 * Outputs (gitignored):
 *   .zentto/security/{semgrep,trivy,osv}.json
 *   .zentto/security/REPORT.md
 *
 * Requisitos:
 *   - Docker disponible (preferido), O semgrep en PATH + binarios trivy/osv en .zentto/security/bin/
 */
"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const ROOT = path.resolve(__dirname, "..");
const REPO_ROOT = path.resolve(ROOT, "..", "..");
const OUT_DIR = path.join(REPO_ROOT, ".zentto", "security");
const BIN_DIR = path.join(OUT_DIR, "bin");
const TARGET_REL = path.relative(REPO_ROOT, ROOT).replace(/\\/g, "/") || ".";

const SEMGREP_CONFIGS = [
  "p/ci",
  "p/security-audit",
  "p/owasp-top-ten",
  "p/javascript",
  "p/typescript",
  "p/nodejs",
];

const SKIP_DIRS = ["node_modules", ".next", "dist", "build", "coverage", ".turbo", ".cache"];

const args = process.argv.slice(2);
const flags = {
  strict: args.includes("--strict"),
  failOn: "none",
  skip: new Set(),
  noPull: args.includes("--no-pull"),
};
for (const a of args) {
  if (a.startsWith("--fail-on=")) flags.failOn = a.split("=")[1].toLowerCase();
  if (a.startsWith("--skip=")) a.split("=")[1].split(",").forEach(s => flags.skip.add(s.trim()));
}
if (flags.strict && flags.failOn === "none") flags.failOn = "critical";

function log(...m) { console.log("[security-precheck]", ...m); }
function die(msg, code = 1) { console.error("[security-precheck] FATAL:", msg); process.exit(code); }

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.mkdirSync(BIN_DIR, { recursive: true });

function which(cmd) {
  const r = spawnSync(process.platform === "win32" ? "where" : "which", [cmd], { encoding: "utf8" });
  if (r.status === 0) return r.stdout.split(/\r?\n/)[0].trim();
  return null;
}

function dockerOk() {
  if (!which("docker")) return false;
  const r = spawnSync("docker", ["info", "--format", "{{.ServerVersion}}"], { encoding: "utf8" });
  return r.status === 0 && r.stdout.trim().length > 0;
}

function dockerVolumeMount() {
  // Maps repo root to /repo inside container; honors Windows drive letters via MSYS_NO_PATHCONV.
  const mountSpec = `${REPO_ROOT.replace(/\\/g, "/")}:/repo`;
  return ["-v", mountSpec, "-w", "/repo"];
}

// Safe: cmd values are hardcoded in this file (docker/semgrep/trivy/osv-scanner only),
// args are passed as arrays (no shell interpretation), no user input reaches spawnSync.
function runStream(cmd, args, opts = {}) {
  log(">", cmd, args.join(" "));
  const env = { ...process.env, MSYS_NO_PATHCONV: "1" };
  // nosemgrep: javascript.lang.security.detect-child-process.detect-child-process
  const r = spawnSync(cmd, args, { stdio: "inherit", env, ...opts });
  return r.status ?? -1;
}

function runSemgrep() {
  const outFile = path.join(OUT_DIR, "semgrep.json");
  if (fs.existsSync(outFile)) fs.unlinkSync(outFile);

  const useDocker = dockerOk();
  const baseArgs = [
    "scan", TARGET_REL,
    ...SEMGREP_CONFIGS.flatMap(c => ["--config", c]),
    "--json", "--output", `.zentto/security/semgrep.json`,
    "--metrics=off",
    "--timeout", "600",
    "--max-target-bytes", "5000000",
    ...SKIP_DIRS.flatMap(d => ["--exclude", d]),
  ];

  if (useDocker) {
    if (!flags.noPull) runStream("docker", ["pull", "semgrep/semgrep:latest"]);
    return runStream("docker", [
      "run", "--rm",
      ...dockerVolumeMount(),
      "semgrep/semgrep:latest",
      "semgrep", ...baseArgs,
    ]);
  }
  const local = which("semgrep");
  if (!local) {
    log("WARN: semgrep no disponible (sin docker ni binario local). Skip.");
    return -2;
  }
  return runStream("semgrep", baseArgs, { cwd: REPO_ROOT });
}

function runTrivy() {
  const outFile = path.join(OUT_DIR, "trivy.json");
  if (fs.existsSync(outFile)) fs.unlinkSync(outFile);

  const useDocker = dockerOk();
  const trivyIgnoreRel = path.posix.join(TARGET_REL, ".trivyignore");
  const trivyIgnoreAbs = path.join(REPO_ROOT, trivyIgnoreRel);
  // NOTE: secret scanning removed per Trivy upstream recommendation
  // (https://trivy.dev/docs/guide/scanner/secret#recommendation):
  // "If your scanning is slow, please try '--scanners vuln,misconfig' to
  // disable secret scanning". Secret detection is owned by gitleaks
  // (run-gitleaks: true en el workflow security.yml reusable).
  const baseArgs = [
    "fs", TARGET_REL,
    "--scanners", "vuln,misconfig",
    ...SKIP_DIRS.flatMap(d => ["--skip-dirs", d]),
    "--timeout", "30m",
    "--format", "json",
    "--output", ".zentto/security/trivy.json",
  ];
  if (fs.existsSync(trivyIgnoreAbs)) {
    baseArgs.push("--ignorefile", trivyIgnoreRel);
    log("Using Trivy ignorefile:", trivyIgnoreRel);
  }

  if (useDocker) {
    if (!flags.noPull) runStream("docker", ["pull", "aquasec/trivy:latest"]);
    return runStream("docker", [
      "run", "--rm",
      ...dockerVolumeMount(),
      "aquasec/trivy:latest",
      ...baseArgs,
    ]);
  }
  const local = which("trivy") || path.join(BIN_DIR, "trivy.exe");
  if (!fs.existsSync(local) && !which("trivy")) {
    log("WARN: trivy no disponible (sin docker ni binario local). Skip.");
    return -2;
  }
  return runStream(local, baseArgs, { cwd: REPO_ROOT });
}

function runOsv() {
  const outFile = path.join(OUT_DIR, "osv.json");
  if (fs.existsSync(outFile)) fs.unlinkSync(outFile);

  const useDocker = dockerOk();
  const lockfileRel = path.posix.join(TARGET_REL, "package-lock.json");
  const osvConfigRel = path.posix.join(TARGET_REL, ".osv-scanner.toml");
  const osvConfigAbs = path.join(REPO_ROOT, osvConfigRel);
  const baseArgs = [
    `--lockfile=${lockfileRel}`,
    "--format=json",
    "--output=.zentto/security/osv.json",
  ];
  if (fs.existsSync(osvConfigAbs)) {
    baseArgs.unshift(`--config=${osvConfigRel}`);
    log("Using OSV config:", osvConfigRel);
  }

  if (useDocker) {
    if (!flags.noPull) runStream("docker", ["pull", "ghcr.io/google/osv-scanner:latest"]);
    return runStream("docker", [
      "run", "--rm",
      ...dockerVolumeMount(),
      "ghcr.io/google/osv-scanner:latest",
      ...baseArgs,
    ]);
  }
  const localExe = which("osv-scanner") || (process.platform === "win32" ? path.join(BIN_DIR, "osv-scanner.exe") : path.join(BIN_DIR, "osv-scanner"));
  if (!fs.existsSync(localExe) && !which("osv-scanner")) {
    log("WARN: osv-scanner no disponible (sin docker ni binario local). Skip.");
    return -2;
  }
  return runStream(localExe, baseArgs, { cwd: REPO_ROOT });
}

function aggregateReport() {
  const aggregator = path.join(__dirname, "security-aggregate.cjs");
  if (!fs.existsSync(aggregator)) {
    log("WARN: agregador no encontrado en", aggregator);
    return { fails: 0, passed: true };
  }
  const r = spawnSync(process.execPath, [aggregator, `--fail-on=${flags.failOn}`], {
    stdio: "inherit", env: { ...process.env },
  });
  return { exit: r.status };
}

function main() {
  log("Target:", TARGET_REL);
  log("Output dir:", OUT_DIR);
  log("Mode:", flags.strict ? `STRICT (fail-on=${flags.failOn})` : `REPORT (fail-on=${flags.failOn})`);
  log("Skip:", [...flags.skip].join(",") || "none");

  const usingDocker = dockerOk();
  log("Backend:", usingDocker ? "docker" : "native binaries");

  const results = {};
  if (!flags.skip.has("semgrep")) results.semgrep = runSemgrep();
  if (!flags.skip.has("trivy")) results.trivy = runTrivy();
  if (!flags.skip.has("osv")) results.osv = runOsv();

  log("Scanner exit codes:", JSON.stringify(results));

  const agg = aggregateReport();
  log("Aggregator exit:", agg.exit);

  if (flags.strict && agg.exit !== 0) {
    log("STRICT mode: failing build because gate detected critical findings.");
    process.exit(1);
  }
  process.exit(0);
}

main();
