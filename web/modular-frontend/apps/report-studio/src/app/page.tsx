"use client";

import dynamic from "next/dynamic";

const ReportesClient = dynamic(() => import("./reportes/ReportesClient"), { ssr: false });

export default function ReportStudioPage() {
  return <ReportesClient />;
}
