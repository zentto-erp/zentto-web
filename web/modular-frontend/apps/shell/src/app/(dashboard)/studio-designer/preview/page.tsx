"use client";

import dynamic from "next/dynamic";

const StudioPreviewClient = dynamic(() => import("./StudioPreviewClient"), {
  ssr: false,
});

export default function StudioPreviewPage() {
  return <StudioPreviewClient />;
}
