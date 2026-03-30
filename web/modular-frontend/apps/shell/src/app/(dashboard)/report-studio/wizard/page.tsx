"use client";
import dynamic from "next/dynamic";
const ReportWizardClient = dynamic(() => import("./ReportWizardClient"), { ssr: false });
export default function ReportWizardPage() { return <ReportWizardClient />; }
