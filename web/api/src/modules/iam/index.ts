/**
 * IAM Module — Identity & Access Management
 *
 * Barrel export that consolidates roles, permissions, license enforcement,
 * and audit into a single public API surface. Existing modules remain in
 * their original locations to avoid import breakage; this barrel re-exports
 * what consumers need from a single entry point.
 *
 * New code should import from `modules/iam` instead of reaching into
 * individual sub-modules.
 */

// ── Re-exports from existing modules ─────────────────────────────────────────

export { checkUserLimit, checkCompanyLimit } from "../license/license-enforcement.service.js";
export { applyPlanModules, getLicenseByCompany } from "../license/license.service.js";
export * as rolesService from "../roles/roles.service.js";
export * as permissionsService from "../permisos/service.js";

// ── New enforcement guards ───────────────────────────────────────────────────

export { requireUserLimit } from "./enforcement/user-limit.guard.js";
export { requireCompanyLimit, validateCompanyLimit } from "./enforcement/company-limit.guard.js";
export { requireDemoProtection } from "./enforcement/demo-protection.guard.js";
export { syncPlanModules } from "./enforcement/plan-sync.service.js";

// ── Types ────────────────────────────────────────────────────────────────────

export type * from "./iam.types.js";
