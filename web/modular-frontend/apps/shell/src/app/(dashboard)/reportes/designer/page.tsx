"use client";

import dynamic from "next/dynamic";

const ReportDesignerClient = dynamic(
  () => import("../../report-studio/designer/ReportDesignerClient"),
  { ssr: false }
);

export default function ReportesDesignerPage() {
  return <ReportDesignerClient basePath="/reportes" />;
}
