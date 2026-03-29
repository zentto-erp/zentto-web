"use client";

import dynamic from "next/dynamic";

const StudioWizardClient = dynamic(() => import("./StudioWizardClient"), {
  ssr: false,
});

export default function StudioWizardPage() {
  return <StudioWizardClient />;
}
