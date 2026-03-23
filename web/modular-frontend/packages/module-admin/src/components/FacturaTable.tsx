"use client";

import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";

type FacturaRow = {
  NUM_FACT: string;
  FECHA?: string;
  NOMBRE?: string;
  TOTAL?: number;
  COD_USUARIO?: string;
};

const columns: ZenttoColDef[] = [
  { field: "NUM_FACT", headerName: "Numero", flex: 1 },
  { field: "FECHA", headerName: "Fecha", flex: 1 },
  { field: "NOMBRE", headerName: "Cliente", flex: 1.5 },
  { field: "TOTAL", headerName: "Total", flex: 1, type: "number", currency: true },
  { field: "COD_USUARIO", headerName: "Usuario", flex: 1 },
];

export function FacturaTable({ rows }: { rows: FacturaRow[] }) {
  return (
    <ZenttoDataGrid
      rows={rows}
      columns={columns}
      getRowId={(row) => row.NUM_FACT}
      hideToolbar
      autoHeight
    />
  );
}
