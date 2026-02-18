export type FrontendAddon = { id: string; name: string; entry: string };

export async function loadFrontendAddons() {
  const response = await fetch("/addons/registry.json");
  if (!response.ok) return [] as FrontendAddon[];
  return (await response.json()) as FrontendAddon[];
}
