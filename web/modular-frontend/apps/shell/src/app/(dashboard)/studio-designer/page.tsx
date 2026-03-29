"use client";

import dynamic from "next/dynamic";

const StudioDesignerClient = dynamic(() => import("./StudioDesignerClient"), {
  ssr: false,
});

export default function StudioDesignerPage() {
  return <StudioDesignerClient />;
}
