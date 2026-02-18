import { promises as fs } from "fs";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";
import type { Express } from "express";

export type AddonManifest = {
  id: string;
  name: string;
  version: string;
  description?: string;
  entry: string;
};

export type LoadedAddon = {
  manifest: AddonManifest;
};

const currentDir = path.dirname(fileURLToPath(import.meta.url));

export async function loadPluginManifests(app: Express) {
  const isProd = process.env.NODE_ENV === "production";
  const pluginsRoot = isProd
    ? path.resolve(currentDir, "..", "..", "..", "..", "plugins")
    : path.resolve(currentDir, "..", "..", "..", "..", "plugins");

  let entries: string[] = [];
  try {
    entries = await fs.readdir(pluginsRoot);
  } catch {
    return [];
  }

  const addons: LoadedAddon[] = [];

  for (const entry of entries) {
    const manifestPath = path.join(pluginsRoot, entry, "manifest.json");
    try {
      const raw = await fs.readFile(manifestPath, "utf-8");
      const manifest = JSON.parse(raw) as AddonManifest;
      const entryPath = path.join(pluginsRoot, entry, manifest.entry);
      const modUrl = pathToFileURL(entryPath).href;
      const mod = await import(modUrl);

      if (typeof mod.register === "function") {
        await mod.register(app, { addon: manifest });
      }

      addons.push({ manifest });
    } catch {
      continue;
    }
  }

  return addons;
}
