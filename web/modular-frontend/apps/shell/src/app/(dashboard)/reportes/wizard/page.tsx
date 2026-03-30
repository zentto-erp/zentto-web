"use client";

import dynamic from "next/dynamic";

const ReportWizardClient = dynamic(
  () => import("../../report-studio/wizard/ReportWizardClient"),
  { ssr: false }
);

export default function ReportesWizardPage() {
  return <ReportWizardClient basePath="/reportes" />;
}
