import { query } from "../../db/query.js";

export async function getRelations() {
  return query<{
    fkName: string;
    parentSchema: string;
    parentTable: string;
    parentColumn: string;
    refSchema: string;
    refTable: string;
    refColumn: string;
  }>(`
    SELECT
      fk.name AS fkName,
      schParent.name AS parentSchema,
      tabParent.name AS parentTable,
      colParent.name AS parentColumn,
      schRef.name AS refSchema,
      tabRef.name AS refTable,
      colRef.name AS refColumn
    FROM sys.foreign_key_columns fkc
    JOIN sys.foreign_keys fk ON fk.object_id = fkc.constraint_object_id
    JOIN sys.tables tabParent ON tabParent.object_id = fkc.parent_object_id
    JOIN sys.schemas schParent ON schParent.schema_id = tabParent.schema_id
    JOIN sys.columns colParent ON colParent.object_id = fkc.parent_object_id AND colParent.column_id = fkc.parent_column_id
    JOIN sys.tables tabRef ON tabRef.object_id = fkc.referenced_object_id
    JOIN sys.schemas schRef ON schRef.schema_id = tabRef.schema_id
    JOIN sys.columns colRef ON colRef.object_id = fkc.referenced_object_id AND colRef.column_id = fkc.referenced_column_id
    ORDER BY schParent.name, tabParent.name
  `);
}

export async function getTablesAndColumns() {
  const tables = await query<{ schema: string; table: string }>(`
    SELECT TABLE_SCHEMA AS schema, TABLE_NAME AS table
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME
  `);

  const columns = await query<{ schema: string; table: string; column: string; type: string; nullable: string }>(`
    SELECT TABLE_SCHEMA AS schema, TABLE_NAME AS table, COLUMN_NAME AS column, DATA_TYPE AS type, IS_NULLABLE AS nullable
    FROM INFORMATION_SCHEMA.COLUMNS
    ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION
  `);

  return { tables, columns };
}
