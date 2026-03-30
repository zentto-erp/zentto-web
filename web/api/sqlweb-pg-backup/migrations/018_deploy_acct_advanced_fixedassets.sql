\echo '  [018] Desplegando usp_acct_advanced (periodos, centros-costo, presupuestos, recurrentes)...'

\ir ../includes/sp/usp_acct_advanced.sql

\echo '  [018] Desplegando usp_acct_fixedassets (activos fijos)...'

\ir ../includes/sp/usp_acct_fixedassets.sql

\echo '  [018] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('018_deploy_acct_advanced_fixedassets', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [018] COMPLETO — acct_advanced y acct_fixedassets desplegados'
