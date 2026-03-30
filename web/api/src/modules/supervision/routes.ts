import { Router } from "express";
import { z } from "zod";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import { validateSupervisorCredentials } from "../_shared/supervisor-override.service.js";
import {
  deactivateSupervisorBiometricCredential,
  enrollSupervisorBiometricCredential,
  listSupervisorBiometricCredentials,
} from "../_shared/supervisor-biometric.service.js";

export const supervisionRouter = Router();

const listSchema = z.object({
  supervisorUser: z.string().trim().min(1).optional(),
});

const enrollSchema = z.object({
  supervisorUser: z.string().trim().min(1),
  supervisorPassword: z.string().min(1),
  credentialId: z.string().trim().min(8).max(512),
  credentialLabel: z.string().trim().max(120).optional(),
  deviceInfo: z.string().trim().max(300).optional(),
});

const deactivateSchema = z.object({
  supervisorUser: z.string().trim().min(1),
  supervisorPassword: z.string().min(1),
  credentialId: z.string().trim().min(8).max(512),
});

supervisionRouter.get("/biometric/credentials", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const rows = await listSupervisorBiometricCredentials({
      supervisorUser: parsed.data.supervisorUser,
    });

    return res.json({ ok: true, rows });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

supervisionRouter.post("/biometric/enroll", async (req, res) => {
  try {
    const parsed = enrollSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    }

    const user = (req as AuthenticatedRequest).user;
    const validation = await validateSupervisorCredentials({
      supervisorUser: parsed.data.supervisorUser,
      supervisorPassword: parsed.data.supervisorPassword,
      requestedByUser: user?.sub,
      biometricBypass: false,
    });

    if (!validation.ok) {
      return res.status(403).json(validation);
    }

    const saved = await enrollSupervisorBiometricCredential({
      supervisorUser: validation.supervisorUser,
      credentialId: parsed.data.credentialId,
      credentialLabel: parsed.data.credentialLabel,
      deviceInfo: parsed.data.deviceInfo,
      actorUser: user?.sub ?? validation.supervisorUser,
    });

    return res.status(201).json({
      ok: true,
      supervisorUser: validation.supervisorUser,
      supervisorName: validation.supervisorName,
      biometricCredentialId: saved.biometricCredentialId,
    });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

supervisionRouter.post("/biometric/deactivate", async (req, res) => {
  try {
    const parsed = deactivateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    }

    const user = (req as AuthenticatedRequest).user;
    const validation = await validateSupervisorCredentials({
      supervisorUser: parsed.data.supervisorUser,
      supervisorPassword: parsed.data.supervisorPassword,
      requestedByUser: user?.sub,
      biometricBypass: false,
    });

    if (!validation.ok) {
      return res.status(403).json(validation);
    }

    const disabled = await deactivateSupervisorBiometricCredential({
      supervisorUser: validation.supervisorUser,
      credentialId: parsed.data.credentialId,
      actorUser: user?.sub ?? validation.supervisorUser,
    });

    if (!disabled.ok) {
      return res.status(404).json(disabled);
    }

    return res.json(disabled);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

