"use client";

import dynamic from "next/dynamic";

const ReportPreviewClient = dynamic(
  () => import("../../report-studio/preview/ReportPreviewClient"),
  { ssr: false }
);

export default function ReportesPreviewPage() {
  return <ReportPreviewClient basePath="/reportes" />;
}
