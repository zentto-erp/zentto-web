SET NOCOUNT ON;

SELECT
    fk.name AS fk_name,
    sch_parent.name AS parent_schema,
    tab_parent.name AS parent_table,
    col_parent.name AS parent_column,
    sch_ref.name AS referenced_schema,
    tab_ref.name AS referenced_table,
    col_ref.name AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables tab_parent
    ON tab_parent.object_id = fk.parent_object_id
JOIN sys.schemas sch_parent
    ON sch_parent.schema_id = tab_parent.schema_id
JOIN sys.columns col_parent
    ON col_parent.object_id = tab_parent.object_id
   AND col_parent.column_id = fkc.parent_column_id
JOIN sys.tables tab_ref
    ON tab_ref.object_id = fk.referenced_object_id
JOIN sys.schemas sch_ref
    ON sch_ref.schema_id = tab_ref.schema_id
JOIN sys.columns col_ref
    ON col_ref.object_id = tab_ref.object_id
   AND col_ref.column_id = fkc.referenced_column_id
ORDER BY fk.name;
