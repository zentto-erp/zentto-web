"use client";
// Side-effect: registers <zentto-report-designer> and <zentto-report-viewer> custom elements
// Must be imported dynamically to avoid SSR issues with Lit

import "@zentto/report-designer";
import "@zentto/report-viewer";

export const REGISTERED = true;
