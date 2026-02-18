"use client";

import { useMemo } from "react";
import { ColumnDef, getCoreRowModel, useReactTable } from "@tanstack/react-table";
import { Box, Table, TableBody, TableCell, TableHead, TableRow } from "@mui/material";

type FacturaRow = {
  NUM_FACT: string;
  FECHA?: string;
  NOMBRE?: string;
  TOTAL?: number;
  COD_USUARIO?: string;
};

export function FacturaTable({ rows }: { rows: FacturaRow[] }) {
  const columns = useMemo<ColumnDef<FacturaRow>[]>(
    () => [
      { header: "Numero", accessorKey: "NUM_FACT" },
      { header: "Fecha", accessorKey: "FECHA" },
      { header: "Cliente", accessorKey: "NOMBRE" },
      { header: "Total", accessorKey: "TOTAL" },
      { header: "Usuario", accessorKey: "COD_USUARIO" }
    ],
    []
  );

  const table = useReactTable({
    data: rows,
    columns,
    getCoreRowModel: getCoreRowModel()
  });

  return (
    <Box sx={{ overflowX: "auto", background: "#fff", borderRadius: 2, boxShadow: 1 }}>
      <Table size="small">
        <TableHead>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableCell key={header.id} sx={{ fontWeight: 600 }}>
                  {String(header.column.columnDef.header)}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableHead>
        <TableBody>
          {table.getRowModel().rows.map((row) => (
            <TableRow key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>{String(cell.getValue() ?? "")}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
}
