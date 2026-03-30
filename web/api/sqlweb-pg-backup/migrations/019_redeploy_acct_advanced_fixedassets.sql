\echo '  [019] Re-desplegando usp_acct_advanced (periodos, centros-costo, presupuestos, recurrentes)...'

\ir ../includes/sp/usp_acct_advanced.sql

\echo '  [019] Re-desplegando usp_acct_fixedassets (activos fijos)...'

\ir ../includes/sp/usp_acct_fixedassets.sql

\echo '  [019] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('019_redeploy_acct_advanced_fixedassets', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [019] COMPLETO — funciones acct_advanced y acct_fixedassets re-desplegadas'
