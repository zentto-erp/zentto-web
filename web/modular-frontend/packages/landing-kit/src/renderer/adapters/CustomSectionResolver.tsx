/**
 * CustomSectionResolver — Server Component.
 *
 * Patrón Builder.io: el schema declara `customConfig.componentId` + `props`,
 * y el host pasa `registry[componentId] = SomeComponent`. Si no está
 * registrado, log silencioso + render null (no rompe la página).
 *
 * Nota: `type: "custom"` aún no está en `@zentto/studio-core@0.14` — es una
 * extensión propia. Cuando landing-kit 2.0 salga a producción pediremos a
 * studio-core que lo agregue (o usaremos `type: "html"` + prefijo mágico
 * `__CUSTOM__:component-id` como workaround temporal).
 */

import * as React from "react";
import type { SectionAdapterProps } from "../types";

export function CustomSectionResolver({
  section,
  tokens,
  registry,
}: SectionAdapterProps) {
  const cfg = section.customConfig as
    | { componentId: string; props?: Record<string, unknown> }
    | undefined;

  if (!cfg || !cfg.componentId) {
    if (typeof console !== "undefined" && console.warn) {
      console.warn(
        `[landing-kit] Section "${section.id}" de tipo 'custom' sin componentId`,
      );
    }
    return null;
  }

  const Component = registry[cfg.componentId];
  if (!Component) {
    if (typeof console !== "undefined" && console.warn) {
      console.warn(
        `[landing-kit] Custom component "${cfg.componentId}" no registrado en registry`,
      );
    }
    return null;
  }

  return <Component tokens={tokens} {...(cfg.props ?? {})} />;
}
