-- ============================================================
-- Zentto PostgreSQL Ã¢â‚¬â€ Shipping Module Functions
-- Portal de paqueterÃƒÂ­a para clientes
-- ============================================================

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Customer Register Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customer_register(
  p_company_id      INT,
  p_email           VARCHAR(200),
  p_password_hash   VARCHAR(200),
  p_display_name    VARCHAR(200),
  p_phone           VARCHAR(60) DEFAULT NULL,
  p_fiscal_id       VARCHAR(30) DEFAULT NULL,
  p_company_name    VARCHAR(200) DEFAULT NULL,
  p_country_code    VARCHAR(3) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM logistics."ShippingCustomer" WHERE "CompanyId" = p_company_id AND LOWER("Email") = LOWER(p_email)) THEN
    RETURN QUERY SELECT 0, 'Email ya registrado'::VARCHAR;
    RETURN;
  END IF;

  INSERT INTO logistics."ShippingCustomer" ("CompanyId","Email","PasswordHash","DisplayName","Phone","FiscalId","CompanyName","CountryCode")
  VALUES (p_company_id, LOWER(TRIM(p_email)), p_password_hash, p_display_name, p_phone, p_fiscal_id, p_company_name, p_country_code);

  RETURN QUERY SELECT 1, 'Registro exitoso'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Customer Login Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customer_login(
  p_company_id INT DEFAULT NULL,
  p_email      VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE(
  "ShippingCustomerId" BIGINT, "CompanyId" INT, "Email" VARCHAR, "PasswordHash" VARCHAR,
  "DisplayName" VARCHAR, "Phone" VARCHAR, "FiscalId" VARCHAR, "CompanyName" VARCHAR,
  "CountryCode" VARCHAR, "PreferredLanguage" VARCHAR, "IsActive" BOOLEAN,
  "IsEmailVerified" BOOLEAN, "LastLoginAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT sc."ShippingCustomerId", sc."CompanyId", sc."Email"::VARCHAR, sc."PasswordHash"::VARCHAR,
         sc."DisplayName"::VARCHAR, sc."Phone"::VARCHAR, sc."FiscalId"::VARCHAR, sc."CompanyName"::VARCHAR,
         sc."CountryCode"::VARCHAR, sc."PreferredLanguage"::VARCHAR, sc."IsActive",
         sc."IsEmailVerified", sc."LastLoginAt"
  FROM logistics."ShippingCustomer" sc
  WHERE LOWER(sc."Email") = LOWER(p_email)
    AND (p_company_id IS NULL OR sc."CompanyId" = p_company_id);
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Customer Profile Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customer_profile(
  p_shipping_customer_id BIGINT
)
RETURNS TABLE(
  "ShippingCustomerId" BIGINT, "CompanyId" INT, "Email" VARCHAR, "DisplayName" VARCHAR,
  "Phone" VARCHAR, "FiscalId" VARCHAR, "CompanyName" VARCHAR, "CountryCode" VARCHAR,
  "PreferredLanguage" VARCHAR, "IsActive" BOOLEAN, "IsEmailVerified" BOOLEAN,
  "LastLoginAt" TIMESTAMP, "CreatedAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT sc."ShippingCustomerId", sc."CompanyId", sc."Email"::VARCHAR, sc."DisplayName"::VARCHAR,
         sc."Phone"::VARCHAR, sc."FiscalId"::VARCHAR, sc."CompanyName"::VARCHAR, sc."CountryCode"::VARCHAR,
         sc."PreferredLanguage"::VARCHAR, sc."IsActive", sc."IsEmailVerified",
         sc."LastLoginAt", sc."CreatedAt"
  FROM logistics."ShippingCustomer" sc
  WHERE sc."ShippingCustomerId" = p_shipping_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Address List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_address_list(
  p_shipping_customer_id BIGINT
)
RETURNS TABLE(
  "ShippingAddressId" BIGINT, "ShippingCustomerId" BIGINT, "Label" VARCHAR,
  "ContactName" VARCHAR, "Phone" VARCHAR, "AddressLine1" VARCHAR, "AddressLine2" VARCHAR,
  "City" VARCHAR, "State" VARCHAR, "PostalCode" VARCHAR, "CountryCode" VARCHAR,
  "Latitude" DECIMAL, "Longitude" DECIMAL, "IsDefault" BOOLEAN, "CreatedAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT a."ShippingAddressId", a."ShippingCustomerId", a."Label"::VARCHAR,
         a."ContactName"::VARCHAR, a."Phone"::VARCHAR, a."AddressLine1"::VARCHAR, a."AddressLine2"::VARCHAR,
         a."City"::VARCHAR, a."State"::VARCHAR, a."PostalCode"::VARCHAR, a."CountryCode"::VARCHAR,
         a."Latitude", a."Longitude", a."IsDefault", a."CreatedAt"
  FROM logistics."ShippingAddress" a
  WHERE a."ShippingCustomerId" = p_shipping_customer_id
  ORDER BY a."IsDefault" DESC, a."CreatedAt" DESC;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Address Upsert Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_address_upsert(
  p_shipping_address_id  BIGINT DEFAULT NULL,
  p_shipping_customer_id BIGINT DEFAULT NULL,
  p_label                VARCHAR(60) DEFAULT 'Principal',
  p_contact_name         VARCHAR(150) DEFAULT NULL,
  p_phone                VARCHAR(60) DEFAULT NULL,
  p_address_line1        VARCHAR(300) DEFAULT NULL,
  p_address_line2        VARCHAR(300) DEFAULT NULL,
  p_city                 VARCHAR(100) DEFAULT NULL,
  p_state                VARCHAR(100) DEFAULT NULL,
  p_postal_code          VARCHAR(20) DEFAULT NULL,
  p_country_code         VARCHAR(3) DEFAULT 'VE',
  p_is_default           BOOLEAN DEFAULT FALSE
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
  IF p_is_default THEN
    UPDATE logistics."ShippingAddress" SET "IsDefault" = FALSE WHERE "ShippingCustomerId" = p_shipping_customer_id;
  END IF;

  IF p_shipping_address_id IS NULL OR p_shipping_address_id = 0 THEN
    INSERT INTO logistics."ShippingAddress" ("ShippingCustomerId","Label","ContactName","Phone","AddressLine1","AddressLine2","City","State","PostalCode","CountryCode","IsDefault")
    VALUES (p_shipping_customer_id, p_label, p_contact_name, p_phone, p_address_line1, p_address_line2, p_city, p_state, p_postal_code, p_country_code, p_is_default);
    RETURN QUERY SELECT 1, 'DirecciÃƒÂ³n creada'::VARCHAR;
  ELSE
    UPDATE logistics."ShippingAddress" SET
      "Label" = p_label, "ContactName" = p_contact_name, "Phone" = p_phone,
      "AddressLine1" = p_address_line1, "AddressLine2" = p_address_line2,
      "City" = p_city, "State" = p_state, "PostalCode" = p_postal_code,
      "CountryCode" = p_country_code, "IsDefault" = p_is_default
    WHERE "ShippingAddressId" = p_shipping_address_id AND "ShippingCustomerId" = p_shipping_customer_id;
    RETURN QUERY SELECT 1, 'DirecciÃƒÂ³n actualizada'::VARCHAR;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Carrier Config List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_carrierconfig_list(
  p_company_id INT
)
RETURNS TABLE(
  "CarrierConfigId" BIGINT, "CompanyId" INT, "CarrierCode" VARCHAR, "CarrierName" VARCHAR,
  "CarrierType" VARCHAR, "SupportedCountries" VARCHAR, "IsActive" BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT c."CarrierConfigId", c."CompanyId", c."CarrierCode"::VARCHAR, c."CarrierName"::VARCHAR,
         c."CarrierType"::VARCHAR, c."SupportedCountries"::VARCHAR, c."IsActive"
  FROM logistics."CarrierConfig" c
  WHERE c."CompanyId" = p_company_id AND c."IsActive" = TRUE
  ORDER BY c."CarrierName";
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment Create Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_create(
  p_company_id           INT,
  p_shipping_customer_id BIGINT,
  p_carrier_code         VARCHAR(30) DEFAULT NULL,
  p_service_type         VARCHAR(30) DEFAULT 'STANDARD',
  p_origin_contact_name  VARCHAR(150) DEFAULT NULL,
  p_origin_phone         VARCHAR(60) DEFAULT NULL,
  p_origin_address       VARCHAR(500) DEFAULT NULL,
  p_origin_city          VARCHAR(100) DEFAULT NULL,
  p_origin_state         VARCHAR(100) DEFAULT NULL,
  p_origin_postal_code   VARCHAR(20) DEFAULT NULL,
  p_origin_country_code  VARCHAR(3) DEFAULT 'VE',
  p_dest_contact_name    VARCHAR(150) DEFAULT NULL,
  p_dest_phone           VARCHAR(60) DEFAULT NULL,
  p_dest_address         VARCHAR(500) DEFAULT NULL,
  p_dest_city            VARCHAR(100) DEFAULT NULL,
  p_dest_state           VARCHAR(100) DEFAULT NULL,
  p_dest_postal_code     VARCHAR(20) DEFAULT NULL,
  p_dest_country_code    VARCHAR(3) DEFAULT 'VE',
  p_declared_value       DECIMAL(18,2) DEFAULT NULL,
  p_currency             VARCHAR(3) DEFAULT 'USD',
  p_description          VARCHAR(500) DEFAULT NULL,
  p_notes                VARCHAR(500) DEFAULT NULL,
  p_reference            VARCHAR(100) DEFAULT NULL,
  p_packages_json        JSONB DEFAULT NULL
)
RETURNS TABLE("ok" BIGINT, "mensaje" VARCHAR) AS $$
DECLARE
  v_shipment_id BIGINT;
  v_shipment_number VARCHAR(30);
  v_seq BIGINT;
  v_is_intl BOOLEAN;
  v_pkg JSONB;
  v_pkg_num INT := 0;
BEGIN
  SELECT COALESCE(MAX("ShipmentId"), 0) + 1 INTO v_seq FROM logistics."Shipment";
  v_shipment_number := 'ZS-' || LPAD(v_seq::TEXT, 6, '0');
  v_is_intl := (p_origin_country_code IS DISTINCT FROM p_dest_country_code);

  INSERT INTO logistics."Shipment" (
    "CompanyId","ShippingCustomerId","ShipmentNumber","CarrierCode",
    "OriginContactName","OriginPhone","OriginAddress","OriginCity","OriginState","OriginPostalCode","OriginCountryCode",
    "DestContactName","DestPhone","DestAddress","DestCity","DestState","DestPostalCode","DestCountryCode",
    "ServiceType","DeclaredValue","Currency","Description","Notes","Reference","IsInternational"
  ) VALUES (
    p_company_id, p_shipping_customer_id, v_shipment_number, p_carrier_code,
    p_origin_contact_name, p_origin_phone, p_origin_address, p_origin_city, p_origin_state, p_origin_postal_code, p_origin_country_code,
    p_dest_contact_name, p_dest_phone, p_dest_address, p_dest_city, p_dest_state, p_dest_postal_code, p_dest_country_code,
    p_service_type, p_declared_value, p_currency, p_description, p_notes, p_reference, v_is_intl
  )
  RETURNING "ShipmentId" INTO v_shipment_id;

  -- Insert packages
  IF p_packages_json IS NOT NULL THEN
    FOR v_pkg IN SELECT * FROM jsonb_array_elements(p_packages_json)
    LOOP
      v_pkg_num := v_pkg_num + 1;
      INSERT INTO logistics."ShipmentPackage" ("ShipmentId","PackageNumber","Weight","WeightUnit","Length","Width","Height","DimensionUnit","ContentDescription","DeclaredValue","HsCode","CountryOfOrigin")
      VALUES (
        v_shipment_id, v_pkg_num,
        COALESCE((v_pkg->>'weight')::DECIMAL, 0), COALESCE(v_pkg->>'weightUnit', 'kg'),
        (v_pkg->>'length')::DECIMAL, (v_pkg->>'width')::DECIMAL, (v_pkg->>'height')::DECIMAL,
        COALESCE(v_pkg->>'dimensionUnit', 'cm'),
        v_pkg->>'contentDescription', (v_pkg->>'declaredValue')::DECIMAL,
        v_pkg->>'hsCode', v_pkg->>'countryOfOrigin'
      );
    END LOOP;
  END IF;

  -- Creation event
  INSERT INTO logistics."ShipmentEvent" ("ShipmentId","EventType","Status","Description","Source")
  VALUES (v_shipment_id, 'CREATED', 'DRAFT', 'EnvÃƒÂ­o creado', 'CUSTOMER');

  -- Total weight
  UPDATE logistics."Shipment"
  SET "TotalWeight" = (SELECT COALESCE(SUM("Weight"), 0) FROM logistics."ShipmentPackage" WHERE "ShipmentId" = v_shipment_id)
  WHERE "ShipmentId" = v_shipment_id;

  RETURN QUERY SELECT v_shipment_id, v_shipment_number::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_list(
  p_shipping_customer_id BIGINT,
  p_status               VARCHAR(30) DEFAULT NULL,
  p_search               VARCHAR(100) DEFAULT NULL,
  p_page                 INT DEFAULT 1,
  p_limit                INT DEFAULT 20
)
RETURNS TABLE(
  "ShipmentId" BIGINT, "ShipmentNumber" VARCHAR, "TrackingNumber" VARCHAR,
  "CarrierCode" VARCHAR, "OriginCity" VARCHAR, "OriginCountryCode" VARCHAR,
  "DestCity" VARCHAR, "DestCountryCode" VARCHAR, "DestContactName" VARCHAR,
  "ServiceType" VARCHAR, "Status" VARCHAR, "ShippingCost" DECIMAL,
  "Currency" VARCHAR, "TotalWeight" DECIMAL, "EstimatedDelivery" DATE,
  "ActualDelivery" TIMESTAMP, "IsInternational" BOOLEAN, "CustomsStatus" VARCHAR,
  "LabelUrl" VARCHAR, "CreatedAt" TIMESTAMP, "LastEvent" VARCHAR, "TotalCount" BIGINT
) AS $$
DECLARE
  v_offset INT := (GREATEST(p_page, 1) - 1) * LEAST(GREATEST(p_limit, 1), 100);
  v_limit INT := LEAST(GREATEST(p_limit, 1), 100);
  v_total BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM logistics."Shipment" s
  WHERE s."ShippingCustomerId" = p_shipping_customer_id
    AND (p_status IS NULL OR s."Status" = p_status)
    AND (p_search IS NULL OR s."ShipmentNumber" ILIKE '%' || p_search || '%' OR s."TrackingNumber" ILIKE '%' || p_search || '%' OR s."DestContactName" ILIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT s."ShipmentId", s."ShipmentNumber"::VARCHAR, s."TrackingNumber"::VARCHAR,
         s."CarrierCode"::VARCHAR, s."OriginCity"::VARCHAR, s."OriginCountryCode"::VARCHAR,
         s."DestCity"::VARCHAR, s."DestCountryCode"::VARCHAR, s."DestContactName"::VARCHAR,
         s."ServiceType"::VARCHAR, s."Status"::VARCHAR, s."ShippingCost",
         s."Currency"::VARCHAR, s."TotalWeight", s."EstimatedDelivery",
         s."ActualDelivery", s."IsInternational", s."CustomsStatus"::VARCHAR,
         s."LabelUrl"::VARCHAR, s."CreatedAt",
         (SELECT e."Description"::VARCHAR FROM logistics."ShipmentEvent" e WHERE e."ShipmentId" = s."ShipmentId" ORDER BY e."EventAt" DESC LIMIT 1),
         v_total
  FROM logistics."Shipment" s
  WHERE s."ShippingCustomerId" = p_shipping_customer_id
    AND (p_status IS NULL OR s."Status" = p_status)
    AND (p_search IS NULL OR s."ShipmentNumber" ILIKE '%' || p_search || '%' OR s."TrackingNumber" ILIKE '%' || p_search || '%' OR s."DestContactName" ILIKE '%' || p_search || '%')
  ORDER BY s."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment Get Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
-- Note: In PG we return multiple result sets via separate calls from service layer

CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_get(
  p_shipment_id          BIGINT,
  p_shipping_customer_id BIGINT DEFAULT NULL
)
RETURNS TABLE(
  "ShipmentId" BIGINT, "CompanyId" INT, "ShippingCustomerId" BIGINT, "ShipmentNumber" VARCHAR,
  "TrackingNumber" VARCHAR, "CarrierCode" VARCHAR, "CarrierTrackingUrl" VARCHAR,
  "OriginContactName" VARCHAR, "OriginPhone" VARCHAR, "OriginAddress" VARCHAR,
  "OriginCity" VARCHAR, "OriginState" VARCHAR, "OriginPostalCode" VARCHAR, "OriginCountryCode" VARCHAR,
  "DestContactName" VARCHAR, "DestPhone" VARCHAR, "DestAddress" VARCHAR,
  "DestCity" VARCHAR, "DestState" VARCHAR, "DestPostalCode" VARCHAR, "DestCountryCode" VARCHAR,
  "ServiceType" VARCHAR, "PaymentMethod" VARCHAR, "DeclaredValue" DECIMAL,
  "Currency" VARCHAR, "InsuredAmount" DECIMAL, "ShippingCost" DECIMAL,
  "TotalWeight" DECIMAL, "Description" VARCHAR, "Notes" VARCHAR, "Reference" VARCHAR,
  "Status" VARCHAR, "EstimatedDelivery" DATE, "ActualDelivery" TIMESTAMP,
  "DeliveredToName" VARCHAR, "LabelUrl" VARCHAR, "IsInternational" BOOLEAN,
  "CustomsStatus" VARCHAR, "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT s."ShipmentId", s."CompanyId", s."ShippingCustomerId", s."ShipmentNumber"::VARCHAR,
         s."TrackingNumber"::VARCHAR, s."CarrierCode"::VARCHAR, s."CarrierTrackingUrl"::VARCHAR,
         s."OriginContactName"::VARCHAR, s."OriginPhone"::VARCHAR, s."OriginAddress"::VARCHAR,
         s."OriginCity"::VARCHAR, s."OriginState"::VARCHAR, s."OriginPostalCode"::VARCHAR, s."OriginCountryCode"::VARCHAR,
         s."DestContactName"::VARCHAR, s."DestPhone"::VARCHAR, s."DestAddress"::VARCHAR,
         s."DestCity"::VARCHAR, s."DestState"::VARCHAR, s."DestPostalCode"::VARCHAR, s."DestCountryCode"::VARCHAR,
         s."ServiceType"::VARCHAR, s."PaymentMethod"::VARCHAR, s."DeclaredValue",
         s."Currency"::VARCHAR, s."InsuredAmount", s."ShippingCost",
         s."TotalWeight", s."Description"::VARCHAR, s."Notes"::VARCHAR, s."Reference"::VARCHAR,
         s."Status"::VARCHAR, s."EstimatedDelivery", s."ActualDelivery",
         s."DeliveredToName"::VARCHAR, s."LabelUrl"::VARCHAR, s."IsInternational",
         s."CustomsStatus"::VARCHAR, s."CreatedAt", s."UpdatedAt"
  FROM logistics."Shipment" s
  WHERE s."ShipmentId" = p_shipment_id
    AND (p_shipping_customer_id IS NULL OR s."ShippingCustomerId" = p_shipping_customer_id);
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment Events Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_events(
  p_shipment_id BIGINT
)
RETURNS TABLE(
  "ShipmentEventId" BIGINT, "EventType" VARCHAR, "Status" VARCHAR,
  "Description" VARCHAR, "Location" VARCHAR, "City" VARCHAR,
  "CountryCode" VARCHAR, "CarrierEventCode" VARCHAR, "Source" VARCHAR, "EventAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT e."ShipmentEventId", e."EventType"::VARCHAR, e."Status"::VARCHAR,
         e."Description"::VARCHAR, e."Location"::VARCHAR, e."City"::VARCHAR,
         e."CountryCode"::VARCHAR, e."CarrierEventCode"::VARCHAR, e."Source"::VARCHAR, e."EventAt"
  FROM logistics."ShipmentEvent" e
  WHERE e."ShipmentId" = p_shipment_id
  ORDER BY e."EventAt" DESC;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment Packages Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_packages(
  p_shipment_id BIGINT
)
RETURNS TABLE(
  "ShipmentPackageId" BIGINT, "PackageNumber" INT, "Weight" DECIMAL,
  "WeightUnit" VARCHAR, "Length" DECIMAL, "Width" DECIMAL, "Height" DECIMAL,
  "DimensionUnit" VARCHAR, "ContentDescription" VARCHAR, "DeclaredValue" DECIMAL,
  "HsCode" VARCHAR, "CountryOfOrigin" VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT p."ShipmentPackageId", p."PackageNumber", p."Weight",
         p."WeightUnit"::VARCHAR, p."Length", p."Width", p."Height",
         p."DimensionUnit"::VARCHAR, p."ContentDescription"::VARCHAR, p."DeclaredValue",
         p."HsCode"::VARCHAR, p."CountryOfOrigin"::VARCHAR
  FROM logistics."ShipmentPackage" p
  WHERE p."ShipmentId" = p_shipment_id
  ORDER BY p."PackageNumber";
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shipment Update Status Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_updatestatus(
  p_shipment_id       BIGINT,
  p_new_status        VARCHAR(30),
  p_event_description VARCHAR(500),
  p_location          VARCHAR(200) DEFAULT NULL,
  p_city              VARCHAR(100) DEFAULT NULL,
  p_country_code      VARCHAR(3) DEFAULT NULL,
  p_carrier_event_code VARCHAR(50) DEFAULT NULL,
  p_source            VARCHAR(20) DEFAULT 'SYSTEM'
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics."Shipment" WHERE "ShipmentId" = p_shipment_id) THEN
    RETURN QUERY SELECT 0, 'EnvÃƒÂ­o no encontrado'::VARCHAR;
    RETURN;
  END IF;

  UPDATE logistics."Shipment"
  SET "Status" = p_new_status,
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "ActualDelivery" = CASE WHEN p_new_status = 'DELIVERED' THEN NOW() AT TIME ZONE 'UTC' ELSE "ActualDelivery" END,
      "CustomsStatus" = CASE WHEN p_new_status IN ('IN_CUSTOMS','CUSTOMS_HELD','CUSTOMS_CLEARED') THEN p_new_status ELSE "CustomsStatus" END
  WHERE "ShipmentId" = p_shipment_id;

  INSERT INTO logistics."ShipmentEvent" ("ShipmentId","EventType","Status","Description","Location","City","CountryCode","CarrierEventCode","Source")
  VALUES (p_shipment_id, p_new_status, p_new_status, p_event_description, p_location, p_city, p_country_code, p_carrier_event_code, p_source);

  RETURN QUERY SELECT 1, 'Estado actualizado'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Track (public) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_track(
  p_tracking_number VARCHAR(100)
)
RETURNS TABLE(
  "ShipmentId" BIGINT, "ShipmentNumber" VARCHAR, "TrackingNumber" VARCHAR,
  "CarrierCode" VARCHAR, "OriginCity" VARCHAR, "OriginCountryCode" VARCHAR,
  "DestCity" VARCHAR, "DestCountryCode" VARCHAR, "Status" VARCHAR,
  "ServiceType" VARCHAR, "EstimatedDelivery" DATE, "ActualDelivery" TIMESTAMP,
  "DeliveredToName" VARCHAR, "CreatedAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT s."ShipmentId", s."ShipmentNumber"::VARCHAR, s."TrackingNumber"::VARCHAR,
         s."CarrierCode"::VARCHAR, s."OriginCity"::VARCHAR, s."OriginCountryCode"::VARCHAR,
         s."DestCity"::VARCHAR, s."DestCountryCode"::VARCHAR, s."Status"::VARCHAR,
         s."ServiceType"::VARCHAR, s."EstimatedDelivery", s."ActualDelivery",
         s."DeliveredToName"::VARCHAR, s."CreatedAt"
  FROM logistics."Shipment" s
  WHERE s."TrackingNumber" = p_tracking_number OR s."ShipmentNumber" = p_tracking_number;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Track Events (public) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_track_events(
  p_tracking_number VARCHAR(100)
)
RETURNS TABLE(
  "ShipmentEventId" BIGINT, "EventType" VARCHAR, "Status" VARCHAR,
  "Description" VARCHAR, "Location" VARCHAR, "City" VARCHAR,
  "CountryCode" VARCHAR, "EventAt" TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT e."ShipmentEventId", e."EventType"::VARCHAR, e."Status"::VARCHAR,
         e."Description"::VARCHAR, e."Location"::VARCHAR, e."City"::VARCHAR,
         e."CountryCode"::VARCHAR, e."EventAt"
  FROM logistics."ShipmentEvent" e
  INNER JOIN logistics."Shipment" s ON s."ShipmentId" = e."ShipmentId"
  WHERE s."TrackingNumber" = p_tracking_number OR s."ShipmentNumber" = p_tracking_number
  ORDER BY e."EventAt" DESC;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Customs Upsert Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customs_upsert(
  p_shipment_id          BIGINT,
  p_content_type         VARCHAR(30) DEFAULT 'MERCHANDISE',
  p_total_declared_value DECIMAL(18,2) DEFAULT 0,
  p_currency             VARCHAR(3) DEFAULT 'USD',
  p_exporter_name        VARCHAR(200) DEFAULT NULL,
  p_exporter_fiscal_id   VARCHAR(30) DEFAULT NULL,
  p_importer_name        VARCHAR(200) DEFAULT NULL,
  p_importer_fiscal_id   VARCHAR(30) DEFAULT NULL,
  p_origin_country_code  VARCHAR(3) DEFAULT NULL,
  p_dest_country_code    VARCHAR(3) DEFAULT NULL,
  p_hs_code              VARCHAR(20) DEFAULT NULL,
  p_item_description     VARCHAR(500) DEFAULT NULL,
  p_quantity             INT DEFAULT 1,
  p_weight_kg            DECIMAL(10,3) DEFAULT NULL,
  p_notes                VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR) AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM logistics."CustomsDeclaration" WHERE "ShipmentId" = p_shipment_id) THEN
    UPDATE logistics."CustomsDeclaration" SET
      "ContentType" = p_content_type, "TotalDeclaredValue" = p_total_declared_value, "Currency" = p_currency,
      "ExporterName" = p_exporter_name, "ExporterFiscalId" = p_exporter_fiscal_id,
      "ImporterName" = p_importer_name, "ImporterFiscalId" = p_importer_fiscal_id,
      "OriginCountryCode" = p_origin_country_code, "DestCountryCode" = p_dest_country_code,
      "HsCode" = p_hs_code, "ItemDescription" = p_item_description, "Quantity" = p_quantity,
      "WeightKg" = p_weight_kg, "Notes" = p_notes, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ShipmentId" = p_shipment_id;
    RETURN QUERY SELECT 1, 'DeclaraciÃƒÂ³n actualizada'::VARCHAR;
  ELSE
    INSERT INTO logistics."CustomsDeclaration" (
      "ShipmentId","ContentType","TotalDeclaredValue","Currency",
      "ExporterName","ExporterFiscalId","ImporterName","ImporterFiscalId",
      "OriginCountryCode","DestCountryCode","HsCode","ItemDescription","Quantity","WeightKg","Notes"
    ) VALUES (
      p_shipment_id, p_content_type, p_total_declared_value, p_currency,
      p_exporter_name, p_exporter_fiscal_id, p_importer_name, p_importer_fiscal_id,
      p_origin_country_code, p_dest_country_code, p_hs_code, p_item_description, p_quantity, p_weight_kg, p_notes
    );
    RETURN QUERY SELECT 1, 'DeclaraciÃƒÂ³n creada'::VARCHAR;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
CREATE OR REPLACE FUNCTION logistics.usp_shipping_dashboard(
  p_shipping_customer_id BIGINT
)
RETURNS TABLE(
  "TotalShipments" BIGINT, "DraftCount" BIGINT, "InTransitCount" BIGINT,
  "DeliveredCount" BIGINT, "InCustomsCount" BIGINT, "ExceptionCount" BIGINT,
  "TotalSpent" DECIMAL, "Currency" VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT,
    COUNT(*) FILTER (WHERE s."Status" = 'DRAFT'),
    COUNT(*) FILTER (WHERE s."Status" IN ('PICKED_UP','IN_TRANSIT','OUT_FOR_DELIVERY')),
    COUNT(*) FILTER (WHERE s."Status" = 'DELIVERED'),
    COUNT(*) FILTER (WHERE s."Status" IN ('IN_CUSTOMS','CUSTOMS_HELD')),
    COUNT(*) FILTER (WHERE s."Status" = 'EXCEPTION'),
    COALESCE(SUM(s."ShippingCost"), 0)::DECIMAL,
    MAX(s."Currency")::VARCHAR
  FROM logistics."Shipment" s
  WHERE s."ShippingCustomerId" = p_shipping_customer_id;
END;
$$ LANGUAGE plpgsql;
