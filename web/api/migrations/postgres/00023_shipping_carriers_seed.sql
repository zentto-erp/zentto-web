-- +goose Up
-- Seed: Carriers iniciales para Zentto Shipping
-- Zoom, MRW, Liberty Express con CompanyId=1 (tenant demo)
-- Los adapters usan GenericAdapter hasta tener credenciales reales.

BEGIN;

INSERT INTO logistics."CarrierConfig" (
  "CompanyId", "CarrierCode", "CarrierName", "IsActive",
  "TrackingUrlTemplate", "CredentialsJson", "SupportedServiceTypes"
)
VALUES
  (
    1, 'ZOOM', 'Zoom Delivery', TRUE,
    'https://zoom.net/rastreo?guia={tracking}',
    '{"note":"pendiente credenciales API"}',
    '["STANDARD","EXPRESS"]'
  ),
  (
    1, 'MRW', 'MRW Venezuela', TRUE,
    'https://mrw.com.ve/rastreo?n={tracking}',
    '{"note":"pendiente credenciales API"}',
    '["STANDARD","OVERNIGHT"]'
  ),
  (
    1, 'LIBERTY', 'Liberty Express', TRUE,
    'https://libertyexpress.com/track?code={tracking}',
    '{"note":"pendiente credenciales API"}',
    '["STANDARD","EXPRESS","ECONOMY"]'
  )
ON CONFLICT DO NOTHING;

COMMIT;

-- +goose Down
BEGIN;
DELETE FROM logistics."CarrierConfig"
WHERE "CompanyId" = 1
  AND "CarrierCode" IN ('ZOOM', 'MRW', 'LIBERTY');
COMMIT;
