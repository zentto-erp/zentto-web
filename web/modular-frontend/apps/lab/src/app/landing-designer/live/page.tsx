"use client";

import React, { useEffect, useState, useRef } from "react";

// Declare web component types
declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-studio-app": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

const STORAGE_KEY = "zentto-landing-designer-config";

export default function LandingLivePage() {
  const appRef = useRef<any>(null);
  const [ready, setReady] = useState(false);
  const [config, setConfig] = useState<any>(null);

  /* Hide lab shell chrome — full-screen landing */
  useEffect(() => {
    const orig = document.body.style.cssText;
    document.body.style.margin = "0";
    document.body.style.padding = "0";
    document.body.style.overflow = "auto";
    // Hide any parent lab wrapper
    const el = document.body.firstElementChild as HTMLElement | null;
    const prevDisplay = el?.style.display ?? "";
    // We don't hide the root — Next hydration needs it. Instead we style it fullscreen.
    return () => { document.body.style.cssText = orig; };
  }, []);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) setConfig(JSON.parse(saved));
    } catch { /* noop */ }

    Promise.all([
      import("@zentto/studio/app"),
      import("@zentto/studio/landing"),
    ]).then(() => setReady(true));
  }, []);

  useEffect(() => {
    if (!ready || !appRef.current || !config) return;
    appRef.current.config = config;
  }, [ready, config]);

  if (!config) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", fontFamily: "system-ui" }}>
        <div style={{ textAlign: "center" }}>
          <h2>No hay landing configurada</h2>
          <p style={{ color: "#666" }}>Crea una landing desde el <a href="/landing-designer">Designer</a></p>
        </div>
      </div>
    );
  }

  if (!ready) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh" }}>
        <div style={{ width: 40, height: 40, border: "3px solid #e5e7eb", borderTopColor: "#6366f1", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
        <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
      </div>
    );
  }

  return (
    <zentto-studio-app
      ref={appRef}
      style={{ display: "block", width: "100%", minHeight: "100vh" }}
    />
  );
}
