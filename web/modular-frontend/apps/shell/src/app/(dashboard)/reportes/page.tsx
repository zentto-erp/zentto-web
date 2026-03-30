"use client";

import dynamic from "next/dynamic";

const ReportStudioClient = dynamic(
  () => import("../report-studio/ReportStudioClient"),
  { ssr: false }
);

export default function ReportesPage() {
  return <ReportStudioClient basePath="/reportes" />;
}
