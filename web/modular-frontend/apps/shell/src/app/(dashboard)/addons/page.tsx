"use client";

import dynamic from "next/dynamic";

const AddonsClient = dynamic(() => import("./AddonsClient"), {
  ssr: false,
});

export default function AddonsPage() {
  return <AddonsClient />;
}
