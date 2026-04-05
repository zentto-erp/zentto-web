// Global type declarations for web components used in Zentto Panel

import type { DetailedHTMLProps, HTMLAttributes } from "react";

type WCProps = DetailedHTMLProps<HTMLAttributes<HTMLElement> & Record<string, unknown>, HTMLElement>;

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace JSX {
    interface IntrinsicElements {
      "zs-landing-designer": WCProps;
      "zs-landing-wizard": WCProps;
      "zs-landing-page": WCProps;
      "zentto-studio-app": WCProps;
      "zs-whatsapp-button": WCProps;
      "zs-social-share": WCProps;
      "zs-social-embed": WCProps;
    }
  }
}

export {};
