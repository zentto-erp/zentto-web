/**
 * Type declarations for Zentto web components (Lit-based).
 *
 * React 19 uses react/jsx-runtime — custom elements must be declared via
 * module augmentation of 'react', not via global JSX namespace.
 *
 * This file lives in shared-ui because every app imports it, ensuring the
 * declarations are always in scope.
 */

import 'react';

declare module 'react' {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, unknown>,
        HTMLElement
      >;
      'zentto-report-viewer': React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, unknown>,
        HTMLElement
      >;
      'zentto-report-designer': React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, unknown>,
        HTMLElement
      >;
    }
  }
}
