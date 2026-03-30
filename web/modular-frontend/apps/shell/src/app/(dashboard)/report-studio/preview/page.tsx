"use client";

import dynamic from "next/dynamic";

const ReportPreviewClient = dynamic(() => import("./ReportPreviewClient"), { ssr: false });

export default function ReportPreviewPage() {
  return <ReportPreviewClient />;
}
