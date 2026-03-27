"use client";

import dynamic from "next/dynamic";

const ReportesClient = dynamic(() => import("./ReportesClient"), { ssr: false });

export default function ReportesPage() {
  return <ReportesClient />;
}
