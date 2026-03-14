SET NOCOUNT ON;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.create_date,
    t.modify_date,
    SUM(CASE WHEN p.index_id IN (0,1) THEN p.rows ELSE 0 END) AS approx_rows
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
GROUP BY s.name, t.name, t.create_date, t.modify_date
ORDER BY s.name, t.name;
