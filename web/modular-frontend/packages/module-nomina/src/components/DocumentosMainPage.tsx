"use client";
import React, { useState } from "react";
import DocumentosPage from "./DocumentosPage";
import TemplateEditorPage from "./TemplateEditorPage";

export default function DocumentosMainPage() {
  const [editing, setEditing] = useState<string | null>(null);

  if (editing !== null) {
    return (
      <TemplateEditorPage
        templateCode={editing === '__new__' ? undefined : editing}
        onBack={() => setEditing(null)}
      />
    );
  }

  return <DocumentosPage onEditTemplate={setEditing} />;
}
