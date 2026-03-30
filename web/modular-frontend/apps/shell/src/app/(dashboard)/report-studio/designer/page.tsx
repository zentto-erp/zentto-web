"use client";
import dynamic from "next/dynamic";
const ReportDesignerClient = dynamic(() => import("./ReportDesignerClient"), { ssr: false });
export default function ReportDesignerPage() { return <ReportDesignerClient />; }
