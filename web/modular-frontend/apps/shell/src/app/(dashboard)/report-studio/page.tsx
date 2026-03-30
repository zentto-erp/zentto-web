"use client";
import dynamic from "next/dynamic";
const ReportStudioClient = dynamic(() => import("./ReportStudioClient"), { ssr: false });
export default function ReportStudioPage() { return <ReportStudioClient />; }
