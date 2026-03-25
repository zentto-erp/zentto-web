-- +goose Up
-- +goose StatementBegin
-- Seed: Carriers globales para Zentto Shipping (multi-país)
-- Solo ejecuta si la tabla tiene las columnas esperadas
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'logistics' AND table_name = 'CarrierConfig'
      AND column_name = 'TrackingUrlTemplate'
  ) THEN
    INSERT INTO logistics."CarrierConfig" (
      "CompanyId", "CarrierCode", "CarrierName", "IsActive",
      "TrackingUrlTemplate", "CredentialsJson", "SupportedServiceTypes"
    )
    VALUES
      (1, 'ZOOM', 'Zoom Envíos', TRUE,
       'https://zoom.red/tracking-de-envios-personas/?nro-guia={tracking}&tipo-consulta=1',
       '{"note":"scraping público, sin credenciales"}', '["STANDARD","EXPRESS"]'),
      (1, 'MRW', 'MRW Venezuela', TRUE,
       'https://www.mrwve.com/rastreo?n={tracking}',
       '{"note":"POST /api/tracking con nro_tracking"}', '["STANDARD","OVERNIGHT"]'),
      (1, 'TEALCA', 'Tealca Venezuela', TRUE,
       'https://www.tealca.com/rastrear-envio/?guia={tracking}',
       '{"note":"scraping HTML, best-effort"}', '["STANDARD","EXPRESS"]'),
      (1, 'LIBERTY', 'Liberty Express', TRUE,
       'https://iqpack.libertyexpress.com/SearchGuide?hreflang=es-ve',
       '{"note":"pendiente — iQPack requiere autenticación"}', '["STANDARD","EXPRESS","ECONOMY"]'),
      (1, 'CORREOS_ES', 'Correos España', TRUE,
       'https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number={tracking}',
       '{"note":"GET api1.correos.es — API pública sin credenciales"}', '["STANDARD","EXPRESS","REGISTERED","ECONOMY"]'),
      (1, 'MRW_ES', 'MRW España', TRUE,
       'https://www.mrw.es/seguimiento_envios/MRWEnvio_seguimiento.asp?envio={tracking}',
       '{"note":"POST HTML scraping mrw.es — sin credenciales"}', '["STANDARD","EXPRESS","OVERNIGHT"]'),
      (1, 'DOMESA', 'Domesa', TRUE,
       'https://www.domesa.com.co/rastreo/?guia={tracking}',
       '{"note":"POST JSON domesa.com.co/publico/consultatracking/GetApi — sin credenciales"}', '["STANDARD","EXPRESS"]'),
      (1, 'DHL', 'DHL Express', TRUE,
       'https://www.dhl.com/es-es/home/tracking/tracking-express.html?submit=1&tracking-id={tracking}',
       '{"note":"demo-key gratis 250/día — registrar en developer.dhl.com para producción"}', '["EXPRESS","ECONOMY","WORLDWIDE"]'),
      (1, 'TRACKINGMORE', 'TrackingMore (Aggregator)', FALSE,
       'https://www.trackingmore.com/track-{tracking}.html',
       '{"note":"Activar con API key de trackingmore.com","tmCode":"auto"}', '["STANDARD","EXPRESS","ECONOMY"]')
    ON CONFLICT DO NOTHING;
  ELSE
    RAISE NOTICE 'Skipping carrier seed: TrackingUrlTemplate column not found';
  END IF;
END $$;
-- +goose StatementEnd

-- +goose Down
DELETE FROM logistics."CarrierConfig"
WHERE "CompanyId" = 1
  AND "CarrierCode" IN ('ZOOM','MRW','TEALCA','LIBERTY','CORREOS_ES','MRW_ES','DOMESA','DHL','TRACKINGMORE');
