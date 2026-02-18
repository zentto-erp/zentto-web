import { Router, type Express } from "express";
import { loadPluginManifests, type LoadedAddon } from "./registry.js";

export const addonsRouter = Router();

let cached: LoadedAddon[] = [];

addonsRouter.get("/", (_req, res) => {
  res.json({ addons: cached.map(({ manifest }) => manifest) });
});

export async function loadAddons(app: Express) {
  cached = await loadPluginManifests(app);
}
