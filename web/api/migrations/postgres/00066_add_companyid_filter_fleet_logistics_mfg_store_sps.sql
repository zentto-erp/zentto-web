-- +goose Up
-- Migration 00066: Add p_company_id filter to fleet, logistics, mfg, store SPs
-- that currently lack tenant isolation.

-- ============================================================
-- FLEET: Parent-table functions (MaintenanceOrder, Vehicle, Trip)
-- ============================================================

-- 1. usp_fleet_maintenanceorder_cancel: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_maintenanceorder_cancel(
    p_company_id integer,
    p_maintenance_order_id integer,
    p_user_id integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM fleet."MaintenanceOrder"
        WHERE "MaintenanceOrderId" = p_maintenance_order_id
          AND "CompanyId" = p_company_id
          AND "Status" IN ('PENDING', 'SCHEDULED')
          AND "IsDeleted" IS NOT TRUE
    ) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede cancelar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "Status"          = 'CANCELLED',
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "MaintenanceOrderId" = p_maintenance_order_id
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'Orden cancelada'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 2. usp_fleet_maintenanceorder_complete: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_maintenanceorder_complete(
    p_company_id integer,
    p_maintenance_order_id integer,
    p_actual_cost numeric DEFAULT 0,
    p_completed_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM fleet."MaintenanceOrder"
        WHERE "MaintenanceOrderId" = p_maintenance_order_id
          AND "CompanyId" = p_company_id
          AND "Status" IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS')
          AND "IsDeleted" IS NOT TRUE
    ) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede completar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "TotalCost"      = p_actual_cost,
        "CompletedAt"    = COALESCE(p_completed_date, NOW() AT TIME ZONE 'UTC'),
        "Status"         = 'COMPLETED',
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "MaintenanceOrderId" = p_maintenance_order_id
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'Orden completada'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 3. usp_fleet_maintenanceorder_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_maintenanceorder_get(
    p_company_id integer,
    p_maintenance_order_id integer
) RETURNS TABLE("MaintenanceOrderId" bigint, "OrderNumber" character varying, "OrderDate" timestamp without time zone, "VehicleId" bigint, "LicensePlate" character varying, "Brand" character varying, "Model" character varying, "MaintenanceTypeId" bigint, "MaintenanceTypeName" character varying, "Category" character varying, "OdometerAtService" numeric, "ScheduledDate" timestamp without time zone, "StartedAt" timestamp without time zone, "CompletedAt" timestamp without time zone, "WorkshopName" character varying, "TechnicianName" character varying, "TotalLaborCost" numeric, "TotalPartsCost" numeric, "TotalCost" numeric, "CurrencyCode" character, "Status" character varying, "Priority" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR,
        mo."OrderDate",
        mo."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        mo."MaintenanceTypeId",
        mt."TypeName"::VARCHAR,
        mt."Category"::VARCHAR,
        mo."OdometerAtService",
        mo."ScheduledDate",
        mo."StartedAt",
        mo."CompletedAt",
        mo."WorkshopName"::VARCHAR,
        mo."TechnicianName"::VARCHAR,
        mo."TotalLaborCost",
        mo."TotalPartsCost",
        mo."TotalCost",
        mo."CurrencyCode"::VARCHAR,
        mo."Status"::VARCHAR,
        mo."Priority"::VARCHAR,
        mo."Notes"::VARCHAR,
        mo."CreatedAt",
        mo."UpdatedAt"
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."MaintenanceOrderId" = p_maintenance_order_id
      AND mo."CompanyId" = p_company_id
      AND mo."IsDeleted" IS NOT TRUE;
END;
$$;
-- +goose StatementEnd

-- 4. usp_fleet_vehicle_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_vehicle_get(
    p_company_id integer,
    p_vehicle_id integer
) RETURNS TABLE("VehicleId" bigint, "CompanyId" integer, "VehicleCode" character varying, "LicensePlate" character varying, "VinNumber" character varying, "EngineNumber" character varying, "Brand" character varying, "Model" character varying, "Year" integer, "Color" character varying, "VehicleType" character varying, "FuelType" character varying, "TankCapacity" numeric, "CurrentOdometer" numeric, "OdometerUnit" character varying, "PurchaseDate" date, "PurchaseCost" numeric, "InsurancePolicy" character varying, "InsuranceExpiry" date, "DefaultDriverId" bigint, "WarehouseId" bigint, "Status" character varying, "Notes" character varying, "IsActive" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v."VehicleId",
        v."CompanyId",
        v."VehicleCode"::VARCHAR,
        v."LicensePlate"::VARCHAR,
        v."VinNumber"::VARCHAR,
        v."EngineNumber"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        v."Year",
        v."Color"::VARCHAR,
        v."VehicleType"::VARCHAR,
        v."FuelType"::VARCHAR,
        v."TankCapacity",
        v."CurrentOdometer",
        v."OdometerUnit"::VARCHAR,
        v."PurchaseDate",
        v."PurchaseCost",
        v."InsurancePolicy"::VARCHAR,
        v."InsuranceExpiry",
        v."DefaultDriverId",
        v."WarehouseId",
        v."Status"::VARCHAR,
        v."Notes"::VARCHAR,
        v."IsActive",
        v."CreatedAt",
        v."UpdatedAt"
    FROM fleet."Vehicle" v
    WHERE v."VehicleId" = p_vehicle_id
      AND v."CompanyId" = p_company_id
      AND v."IsDeleted" IS NOT TRUE;
END;
$$;
-- +goose StatementEnd

-- 5. usp_fleet_vehicledocument_list: add p_company_id, JOIN to Vehicle for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_vehicledocument_list(
    p_company_id integer,
    p_vehicle_id integer
) RETURNS TABLE("VehicleDocumentId" bigint, "VehicleId" bigint, "DocumentType" character varying, "DocumentNumber" character varying, "Description" character varying, "IssuedAt" timestamp without time zone, "ExpiresAt" timestamp without time zone, "FileUrl" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."VehicleDocumentId",
        d."VehicleId",
        d."DocumentType"::VARCHAR,
        d."DocumentNumber"::VARCHAR,
        d."Description"::VARCHAR,
        d."IssuedAt",
        d."ExpiresAt",
        d."FileUrl"::VARCHAR,
        d."Notes"::VARCHAR,
        d."CreatedAt"
    FROM fleet."VehicleDocument" d
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = d."VehicleId"
    WHERE d."VehicleId" = p_vehicle_id
      AND v."CompanyId" = p_company_id
      AND d."IsDeleted" IS NOT TRUE
      AND v."IsDeleted" IS NOT TRUE
    ORDER BY d."ExpiresAt" DESC;
END;
$$;
-- +goose StatementEnd

-- 6. usp_fleet_trip_complete: add p_company_id, filter Trip by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_fleet_trip_complete(
    p_company_id integer,
    p_trip_id integer,
    p_end_mileage numeric,
    p_arrival_date timestamp without time zone,
    p_fuel_used numeric DEFAULT NULL::numeric,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_vehicle_id INT;
    v_odometer_start NUMERIC;
BEGIN
    SELECT t."VehicleId", t."OdometerStart" INTO v_vehicle_id, v_odometer_start
    FROM fleet."Trip" t
    WHERE t."TripId" = p_trip_id
      AND t."CompanyId" = p_company_id
      AND t."Status" = 'IN_PROGRESS'
      AND t."IsDeleted" IS NOT TRUE;

    IF v_vehicle_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Viaje no encontrado o ya completado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."Trip" SET
        "OdometerEnd"     = p_end_mileage,
        "ArrivedAt"       = p_arrival_date,
        "DistanceKm"      = p_end_mileage - v_odometer_start,
        "Status"          = 'COMPLETED',
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "TripId" = p_trip_id
      AND "CompanyId" = p_company_id;

    UPDATE fleet."Vehicle"
    SET "CurrentOdometer" = p_end_mileage,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "VehicleId" = v_vehicle_id AND "CurrentOdometer" < p_end_mileage;

    RETURN QUERY SELECT 1, 'Viaje completado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- LOGISTICS: Parent-table functions (DeliveryNote, GoodsReceipt, GoodsReturn)
-- ============================================================

-- 7. usp_logistics_deliverynote_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_deliverynote_get(
    p_company_id integer,
    p_delivery_note_id integer
) RETURNS TABLE("DeliveryNoteId" bigint, "CompanyId" integer, "BranchId" integer, "DeliveryNumber" character varying, "SalesDocumentNumber" character varying, "CustomerId" bigint, "WarehouseId" bigint, "DeliveryDate" date, "CarrierId" bigint, "DriverId" bigint, "VehiclePlate" character varying, "ShipToAddress" character varying, "ShipToContact" character varying, "EstimatedDelivery" date, "ActualDelivery" date, "Status" character varying, "DeliveredToName" character varying, "DeliverySignature" text, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "CarrierName" character varying, "DriverName" character varying, "Lines" jsonb, "Serials" jsonb)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT dn."DeliveryNoteId", dn."CompanyId", dn."BranchId", dn."DeliveryNumber",
           dn."SalesDocumentNumber", dn."CustomerId", dn."WarehouseId",
           dn."DeliveryDate", dn."CarrierId", dn."DriverId", dn."VehiclePlate",
           dn."ShipToAddress", dn."ShipToContact", dn."EstimatedDelivery",
           dn."ActualDelivery",
           dn."Status", dn."DeliveredToName", dn."DeliverySignature",
           dn."Notes",
           dn."CreatedAt", dn."UpdatedAt",
           c."CarrierName", d."DriverName",
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'LineId', l."LineId",
                   'ProductId', l."ProductId",
                   'Quantity', l."Quantity",
                   'UnitCost', l."UnitCost",
                   'LotNumber', l."LotNumber",
                   'BinId', l."BinId",
                   'Notes', l."Notes"
               ) ORDER BY l."LineId")
               FROM logistics."DeliveryNoteLine" l
               WHERE l."DeliveryNoteId" = dn."DeliveryNoteId"
           ), '[]'::JSONB),
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'Id', s."Id",
                   'LineId', s."LineId",
                   'SerialNumber', s."SerialNumber"
               ))
               FROM logistics."DeliveryNoteSerial" s
               INNER JOIN logistics."DeliveryNoteLine" l2 ON s."LineId" = l2."LineId"
               WHERE l2."DeliveryNoteId" = dn."DeliveryNoteId"
           ), '[]'::JSONB)
    FROM logistics."DeliveryNote" dn
    LEFT JOIN logistics."Carrier" c ON dn."CarrierId" = c."CarrierId"
    LEFT JOIN logistics."Driver" d ON dn."DriverId" = d."DriverId"
    WHERE dn."DeliveryNoteId" = p_delivery_note_id
      AND dn."CompanyId" = p_company_id
      AND dn."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- 8. usp_logistics_deliverynote_deliver: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_deliverynote_deliver(
    p_company_id integer,
    p_delivery_note_id integer,
    p_delivered_to_name character varying DEFAULT NULL::character varying,
    p_delivery_signature text DEFAULT NULL::text,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM logistics."DeliveryNote"
        WHERE "DeliveryNoteId" = p_delivery_note_id
          AND "CompanyId" = p_company_id
          AND "Status" = 'DISPATCHED'
    ) THEN
        RETURN QUERY SELECT 0, 'Nota de entrega no encontrada o no esta despachada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."DeliveryNote"
    SET "Status" = 'DELIVERED',
        "DeliveredToName" = p_delivered_to_name,
        "DeliverySignature" = p_delivery_signature,
        "ActualDelivery" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DeliveryNoteId" = p_delivery_note_id
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'Entrega confirmada'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 9. usp_logistics_deliverynote_dispatch: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_deliverynote_dispatch(
    p_company_id integer,
    p_delivery_note_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_id INT;
    v_warehouse_id INT;
    v_delivery_number VARCHAR(20);
BEGIN
    SELECT "BranchId", "WarehouseId", "DeliveryNumber"
    INTO v_branch_id, v_warehouse_id, v_delivery_number
    FROM logistics."DeliveryNote"
    WHERE "DeliveryNoteId" = p_delivery_note_id
      AND "CompanyId" = p_company_id
      AND "Status" = 'DRAFT';

    IF v_branch_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Nota de entrega no encontrada o no esta en borrador'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."DeliveryNote"
    SET "Status" = 'DISPATCHED', "DispatchedByUserId" = p_user_id, "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DeliveryNoteId" = p_delivery_note_id
      AND "CompanyId" = p_company_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId", "FromBinId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT p_company_id, v_branch_id, l."ProductId", v_warehouse_id, l."BinId",
           'SALE_OUT', l."Quantity", l."UnitCost", 'DELIVERY_NOTE',
           v_delivery_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."DeliveryNoteLine" l
    WHERE l."DeliveryNoteId" = p_delivery_note_id AND l."Quantity" > 0;

    RETURN QUERY SELECT 1, 'Nota de entrega despachada y movimientos de inventario generados'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 10. usp_logistics_goodsreceipt_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_goodsreceipt_get(
    p_company_id integer,
    p_goods_receipt_id integer
) RETURNS TABLE("GoodsReceiptId" bigint, "CompanyId" integer, "BranchId" integer, "ReceiptNumber" character varying, "PurchaseDocumentNumber" character varying, "SupplierId" bigint, "WarehouseId" bigint, "ReceiptDate" date, "CarrierId" bigint, "DriverName" character varying, "VehiclePlate" character varying, "Notes" character varying, "Status" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "CarrierName" character varying, "Lines" jsonb)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT gr."GoodsReceiptId", gr."CompanyId", gr."BranchId", gr."ReceiptNumber",
           gr."PurchaseDocumentNumber", gr."SupplierId", gr."WarehouseId",
           gr."ReceiptDate", gr."CarrierId", gr."DriverName", gr."VehiclePlate",
           gr."Notes", gr."Status", gr."CreatedAt", gr."UpdatedAt",
           c."CarrierName",
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'GoodsReceiptLineId', l."GoodsReceiptLineId",
                   'LineNumber', l."LineNumber",
                   'ProductId', l."ProductId",
                   'ProductCode', l."ProductCode",
                   'Description', l."Description",
                   'OrderedQuantity', l."OrderedQuantity",
                   'ReceivedQuantity', l."ReceivedQuantity",
                   'RejectedQuantity', l."RejectedQuantity",
                   'UnitCost', l."UnitCost",
                   'TotalCost', l."TotalCost",
                   'LotNumber', l."LotNumber",
                   'ExpiryDate', l."ExpiryDate",
                   'WarehouseId', l."WarehouseId",
                   'BinId', l."BinId",
                   'InspectionStatus', l."InspectionStatus",
                   'Notes', l."Notes"
               ) ORDER BY l."LineNumber")
               FROM logistics."GoodsReceiptLine" l
               WHERE l."GoodsReceiptId" = gr."GoodsReceiptId"
           ), '[]'::JSONB)
    FROM logistics."GoodsReceipt" gr
    LEFT JOIN logistics."Carrier" c ON gr."CarrierId" = c."CarrierId"
    WHERE gr."GoodsReceiptId" = p_goods_receipt_id
      AND gr."CompanyId" = p_company_id
      AND gr."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- 11. usp_logistics_goodsreceipt_approve: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_goodsreceipt_approve(
    p_company_id integer,
    p_goods_receipt_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_id INT;
    v_warehouse_id INT;
    v_receipt_number VARCHAR(20);
BEGIN
    SELECT "BranchId", "WarehouseId", "ReceiptNumber"
    INTO v_branch_id, v_warehouse_id, v_receipt_number
    FROM logistics."GoodsReceipt"
    WHERE "GoodsReceiptId" = p_goods_receipt_id
      AND "CompanyId" = p_company_id
      AND "Status" = 'DRAFT';

    IF v_branch_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Recepcion no encontrada o ya aprobada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."GoodsReceipt"
    SET "Status" = 'COMPLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GoodsReceiptId" = p_goods_receipt_id
      AND "CompanyId" = p_company_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "ToWarehouseId", "ToBinId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT p_company_id, v_branch_id, l."ProductId", v_warehouse_id, l."BinId",
           'PURCHASE_IN', l."ReceivedQuantity", l."UnitCost", 'GOODS_RECEIPT',
           v_receipt_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."GoodsReceiptLine" l
    WHERE l."GoodsReceiptId" = p_goods_receipt_id AND l."ReceivedQuantity" > 0;

    RETURN QUERY SELECT 1, 'Recepcion aprobada y movimientos de inventario generados'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 12. usp_logistics_goodsreturn_approve: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_logistics_goodsreturn_approve(
    p_company_id integer,
    p_goods_return_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_id INT;
    v_warehouse_id INT;
    v_return_number VARCHAR(20);
BEGIN
    SELECT "BranchId", "WarehouseId", "ReturnNumber"
    INTO v_branch_id, v_warehouse_id, v_return_number
    FROM logistics."GoodsReturn"
    WHERE "GoodsReturnId" = p_goods_return_id
      AND "CompanyId" = p_company_id
      AND "Status" = 'DRAFT';

    IF v_branch_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Devolucion no encontrada o ya aprobada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."GoodsReturn"
    SET "Status" = 'COMPLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GoodsReturnId" = p_goods_return_id
      AND "CompanyId" = p_company_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT p_company_id, v_branch_id, l."ProductId", v_warehouse_id,
           'RETURN_OUT', l."Quantity", l."UnitCost", 'GOODS_RETURN',
           v_return_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."GoodsReturnLine" l
    WHERE l."GoodsReturnId" = p_goods_return_id AND l."Quantity" > 0;

    RETURN QUERY SELECT 1, 'Devolucion aprobada y movimientos de inventario generados'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- SHIPPING (logistics schema): Add p_company_id to customer/shipment SPs
-- ============================================================

-- 13. usp_shipping_address_list: add p_company_id, JOIN ShippingCustomer for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_address_list(
    p_company_id integer,
    p_shipping_customer_id bigint
) RETURNS TABLE("ShippingAddressId" bigint, "ShippingCustomerId" bigint, "Label" character varying, "ContactName" character varying, "Phone" character varying, "AddressLine1" character varying, "AddressLine2" character varying, "City" character varying, "State" character varying, "PostalCode" character varying, "CountryCode" character varying, "Latitude" numeric, "Longitude" numeric, "IsDefault" boolean, "CreatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a."ShippingAddressId", a."ShippingCustomerId", a."Label"::VARCHAR,
         a."ContactName"::VARCHAR, a."Phone"::VARCHAR, a."AddressLine1"::VARCHAR, a."AddressLine2"::VARCHAR,
         a."City"::VARCHAR, a."State"::VARCHAR, a."PostalCode"::VARCHAR, a."CountryCode"::VARCHAR,
         a."Latitude", a."Longitude", a."IsDefault", a."CreatedAt"
  FROM logistics."ShippingAddress" a
  INNER JOIN logistics."ShippingCustomer" sc ON sc."ShippingCustomerId" = a."ShippingCustomerId"
  WHERE a."ShippingCustomerId" = p_shipping_customer_id
    AND sc."CompanyId" = p_company_id
  ORDER BY a."IsDefault" DESC, a."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- 14. usp_shipping_address_upsert: add p_company_id, validate ownership
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_address_upsert(
    p_company_id integer,
    p_shipping_address_id bigint DEFAULT NULL::bigint,
    p_shipping_customer_id bigint DEFAULT NULL::bigint,
    p_label character varying DEFAULT 'Principal'::character varying,
    p_contact_name character varying DEFAULT NULL::character varying,
    p_phone character varying DEFAULT NULL::character varying,
    p_address_line1 character varying DEFAULT NULL::character varying,
    p_address_line2 character varying DEFAULT NULL::character varying,
    p_city character varying DEFAULT NULL::character varying,
    p_state character varying DEFAULT NULL::character varying,
    p_postal_code character varying DEFAULT NULL::character varying,
    p_country_code character varying DEFAULT 'VE'::character varying,
    p_is_default boolean DEFAULT false
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate customer belongs to company
  IF NOT EXISTS (SELECT 1 FROM logistics."ShippingCustomer" WHERE "ShippingCustomerId" = p_shipping_customer_id AND "CompanyId" = p_company_id) THEN
    RETURN QUERY SELECT 0, 'Cliente no encontrado'::VARCHAR;
    RETURN;
  END IF;

  IF p_is_default THEN
    UPDATE logistics."ShippingAddress" SET "IsDefault" = FALSE WHERE "ShippingCustomerId" = p_shipping_customer_id;
  END IF;

  IF p_shipping_address_id IS NULL OR p_shipping_address_id = 0 THEN
    INSERT INTO logistics."ShippingAddress" ("ShippingCustomerId","Label","ContactName","Phone","AddressLine1","AddressLine2","City","State","PostalCode","CountryCode","IsDefault")
    VALUES (p_shipping_customer_id, p_label, p_contact_name, p_phone, p_address_line1, p_address_line2, p_city, p_state, p_postal_code, p_country_code, p_is_default);
    RETURN QUERY SELECT 1, 'Direccion creada'::VARCHAR;
  ELSE
    UPDATE logistics."ShippingAddress" SET
      "Label" = p_label, "ContactName" = p_contact_name, "Phone" = p_phone,
      "AddressLine1" = p_address_line1, "AddressLine2" = p_address_line2,
      "City" = p_city, "State" = p_state, "PostalCode" = p_postal_code,
      "CountryCode" = p_country_code, "IsDefault" = p_is_default
    WHERE "ShippingAddressId" = p_shipping_address_id AND "ShippingCustomerId" = p_shipping_customer_id;
    RETURN QUERY SELECT 1, 'Direccion actualizada'::VARCHAR;
  END IF;
END;
$$;
-- +goose StatementEnd

-- 15. usp_shipping_customer_profile: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customer_profile(
    p_company_id integer,
    p_shipping_customer_id bigint
) RETURNS TABLE("ShippingCustomerId" bigint, "CompanyId" integer, "Email" character varying, "DisplayName" character varying, "Phone" character varying, "FiscalId" character varying, "CompanyName" character varying, "CountryCode" character varying, "PreferredLanguage" character varying, "IsActive" boolean, "IsEmailVerified" boolean, "LastLoginAt" timestamp without time zone, "CreatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT sc."ShippingCustomerId", sc."CompanyId", sc."Email"::VARCHAR, sc."DisplayName"::VARCHAR,
         sc."Phone"::VARCHAR, sc."FiscalId"::VARCHAR, sc."CompanyName"::VARCHAR, sc."CountryCode"::VARCHAR,
         sc."PreferredLanguage"::VARCHAR, sc."IsActive", sc."IsEmailVerified",
         sc."LastLoginAt", sc."CreatedAt"
  FROM logistics."ShippingCustomer" sc
  WHERE sc."ShippingCustomerId" = p_shipping_customer_id
    AND sc."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- 16. usp_shipping_dashboard: add p_company_id, JOIN Shipment->ShippingCustomer for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_dashboard(
    p_company_id integer,
    p_shipping_customer_id bigint
) RETURNS TABLE("TotalShipments" bigint, "DraftCount" bigint, "InTransitCount" bigint, "DeliveredCount" bigint, "InCustomsCount" bigint, "ExceptionCount" bigint, "TotalSpent" numeric, "Currency" character varying)
    LANGUAGE plpgsql
AS $$
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
  WHERE s."ShippingCustomerId" = p_shipping_customer_id
    AND s."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- 17. usp_shipping_shipment_events: add p_company_id, JOIN Shipment for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_events(
    p_company_id integer,
    p_shipment_id bigint
) RETURNS TABLE("ShipmentEventId" bigint, "EventType" character varying, "Status" character varying, "Description" character varying, "Location" character varying, "City" character varying, "CountryCode" character varying, "CarrierEventCode" character varying, "Source" character varying, "EventAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT e."ShipmentEventId", e."EventType"::VARCHAR, e."Status"::VARCHAR,
         e."Description"::VARCHAR, e."Location"::VARCHAR, e."City"::VARCHAR,
         e."CountryCode"::VARCHAR, e."CarrierEventCode"::VARCHAR, e."Source"::VARCHAR, e."EventAt"
  FROM logistics."ShipmentEvent" e
  INNER JOIN logistics."Shipment" s ON s."ShipmentId" = e."ShipmentId"
  WHERE e."ShipmentId" = p_shipment_id
    AND s."CompanyId" = p_company_id
  ORDER BY e."EventAt" DESC;
END;
$$;
-- +goose StatementEnd

-- 18. usp_shipping_shipment_get: add p_company_id, filter Shipment by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_get(
    p_company_id integer,
    p_shipment_id bigint,
    p_shipping_customer_id bigint DEFAULT NULL::bigint
) RETURNS TABLE("ShipmentId" bigint, "CompanyId" integer, "ShippingCustomerId" bigint, "ShipmentNumber" character varying, "TrackingNumber" character varying, "CarrierCode" character varying, "CarrierTrackingUrl" character varying, "OriginContactName" character varying, "OriginPhone" character varying, "OriginAddress" character varying, "OriginCity" character varying, "OriginState" character varying, "OriginPostalCode" character varying, "OriginCountryCode" character varying, "DestContactName" character varying, "DestPhone" character varying, "DestAddress" character varying, "DestCity" character varying, "DestState" character varying, "DestPostalCode" character varying, "DestCountryCode" character varying, "ServiceType" character varying, "PaymentMethod" character varying, "DeclaredValue" numeric, "Currency" character varying, "InsuredAmount" numeric, "ShippingCost" numeric, "TotalWeight" numeric, "Description" character varying, "Notes" character varying, "Reference" character varying, "Status" character varying, "EstimatedDelivery" date, "ActualDelivery" timestamp without time zone, "DeliveredToName" character varying, "LabelUrl" character varying, "IsInternational" boolean, "CustomsStatus" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
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
    AND s."CompanyId" = p_company_id
    AND (p_shipping_customer_id IS NULL OR s."ShippingCustomerId" = p_shipping_customer_id);
END;
$$;
-- +goose StatementEnd

-- 19. usp_shipping_shipment_list: add p_company_id, filter Shipment by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_list(
    p_company_id integer,
    p_shipping_customer_id bigint,
    p_status character varying DEFAULT NULL::character varying,
    p_search character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 20
) RETURNS TABLE("ShipmentId" bigint, "ShipmentNumber" character varying, "TrackingNumber" character varying, "CarrierCode" character varying, "OriginCity" character varying, "OriginCountryCode" character varying, "DestCity" character varying, "DestCountryCode" character varying, "DestContactName" character varying, "ServiceType" character varying, "Status" character varying, "ShippingCost" numeric, "Currency" character varying, "TotalWeight" numeric, "EstimatedDelivery" date, "ActualDelivery" timestamp without time zone, "IsInternational" boolean, "CustomsStatus" character varying, "LabelUrl" character varying, "CreatedAt" timestamp without time zone, "LastEvent" character varying, "TotalCount" bigint)
    LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT := (GREATEST(p_page, 1) - 1) * LEAST(GREATEST(p_limit, 1), 100);
  v_limit INT := LEAST(GREATEST(p_limit, 1), 100);
  v_total BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM logistics."Shipment" s
  WHERE s."ShippingCustomerId" = p_shipping_customer_id
    AND s."CompanyId" = p_company_id
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
    AND s."CompanyId" = p_company_id
    AND (p_status IS NULL OR s."Status" = p_status)
    AND (p_search IS NULL OR s."ShipmentNumber" ILIKE '%' || p_search || '%' OR s."TrackingNumber" ILIKE '%' || p_search || '%' OR s."DestContactName" ILIKE '%' || p_search || '%')
  ORDER BY s."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- 20. usp_shipping_shipment_packages: add p_company_id, JOIN Shipment for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_packages(
    p_company_id integer,
    p_shipment_id bigint
) RETURNS TABLE("ShipmentPackageId" bigint, "PackageNumber" integer, "Weight" numeric, "WeightUnit" character varying, "Length" numeric, "Width" numeric, "Height" numeric, "DimensionUnit" character varying, "ContentDescription" character varying, "DeclaredValue" numeric, "HsCode" character varying, "CountryOfOrigin" character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT p."ShipmentPackageId", p."PackageNumber", p."Weight",
         p."WeightUnit"::VARCHAR, p."Length", p."Width", p."Height",
         p."DimensionUnit"::VARCHAR, p."ContentDescription"::VARCHAR, p."DeclaredValue",
         p."HsCode"::VARCHAR, p."CountryOfOrigin"::VARCHAR
  FROM logistics."ShipmentPackage" p
  INNER JOIN logistics."Shipment" s ON s."ShipmentId" = p."ShipmentId"
  WHERE p."ShipmentId" = p_shipment_id
    AND s."CompanyId" = p_company_id
  ORDER BY p."PackageNumber";
END;
$$;
-- +goose StatementEnd

-- 21. usp_shipping_shipment_updatestatus: add p_company_id, filter Shipment by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_shipment_updatestatus(
    p_company_id integer,
    p_shipment_id bigint,
    p_new_status character varying,
    p_event_description character varying,
    p_location character varying DEFAULT NULL::character varying,
    p_city character varying DEFAULT NULL::character varying,
    p_country_code character varying DEFAULT NULL::character varying,
    p_carrier_event_code character varying DEFAULT NULL::character varying,
    p_source character varying DEFAULT 'SYSTEM'::character varying
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics."Shipment" WHERE "ShipmentId" = p_shipment_id AND "CompanyId" = p_company_id) THEN
    RETURN QUERY SELECT 0, 'Envio no encontrado'::VARCHAR;
    RETURN;
  END IF;

  UPDATE logistics."Shipment"
  SET "Status" = p_new_status,
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "ActualDelivery" = CASE WHEN p_new_status = 'DELIVERED' THEN NOW() AT TIME ZONE 'UTC' ELSE "ActualDelivery" END,
      "CustomsStatus" = CASE WHEN p_new_status IN ('IN_CUSTOMS','CUSTOMS_HELD','CUSTOMS_CLEARED') THEN p_new_status ELSE "CustomsStatus" END
  WHERE "ShipmentId" = p_shipment_id
    AND "CompanyId" = p_company_id;

  INSERT INTO logistics."ShipmentEvent" ("ShipmentId","EventType","Status","Description","Location","City","CountryCode","CarrierEventCode","Source")
  VALUES (p_shipment_id, p_new_status, p_new_status, p_event_description, p_location, p_city, p_country_code, p_carrier_event_code, p_source);

  RETURN QUERY SELECT 1, 'Estado actualizado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 22. usp_shipping_customs_upsert: add p_company_id, validate Shipment belongs to company
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_customs_upsert(
    p_company_id integer,
    p_shipment_id bigint,
    p_content_type character varying DEFAULT 'MERCHANDISE'::character varying,
    p_total_declared_value numeric DEFAULT 0,
    p_currency character varying DEFAULT 'USD'::character varying,
    p_exporter_name character varying DEFAULT NULL::character varying,
    p_exporter_fiscal_id character varying DEFAULT NULL::character varying,
    p_importer_name character varying DEFAULT NULL::character varying,
    p_importer_fiscal_id character varying DEFAULT NULL::character varying,
    p_origin_country_code character varying DEFAULT NULL::character varying,
    p_dest_country_code character varying DEFAULT NULL::character varying,
    p_hs_code character varying DEFAULT NULL::character varying,
    p_item_description character varying DEFAULT NULL::character varying,
    p_quantity integer DEFAULT 1,
    p_weight_kg numeric DEFAULT NULL::numeric,
    p_notes character varying DEFAULT NULL::character varying
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate shipment belongs to company
  IF NOT EXISTS (SELECT 1 FROM logistics."Shipment" WHERE "ShipmentId" = p_shipment_id AND "CompanyId" = p_company_id) THEN
    RETURN QUERY SELECT 0, 'Envio no encontrado'::VARCHAR;
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM logistics."CustomsDeclaration" WHERE "ShipmentId" = p_shipment_id) THEN
    UPDATE logistics."CustomsDeclaration" SET
      "ContentType" = p_content_type, "TotalDeclaredValue" = p_total_declared_value, "Currency" = p_currency,
      "ExporterName" = p_exporter_name, "ExporterFiscalId" = p_exporter_fiscal_id,
      "ImporterName" = p_importer_name, "ImporterFiscalId" = p_importer_fiscal_id,
      "OriginCountryCode" = p_origin_country_code, "DestCountryCode" = p_dest_country_code,
      "HsCode" = p_hs_code, "ItemDescription" = p_item_description, "Quantity" = p_quantity,
      "WeightKg" = p_weight_kg, "Notes" = p_notes, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ShipmentId" = p_shipment_id;
    RETURN QUERY SELECT 1, 'Declaracion actualizada'::VARCHAR;
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
    RETURN QUERY SELECT 1, 'Declaracion creada'::VARCHAR;
  END IF;
END;
$$;
-- +goose StatementEnd

-- 23. usp_shipping_track: add p_company_id, filter Shipment by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_track(
    p_company_id integer,
    p_tracking_number character varying
) RETURNS TABLE("ShipmentId" bigint, "ShipmentNumber" character varying, "TrackingNumber" character varying, "CarrierCode" character varying, "OriginCity" character varying, "OriginCountryCode" character varying, "DestCity" character varying, "DestCountryCode" character varying, "Status" character varying, "ServiceType" character varying, "EstimatedDelivery" date, "ActualDelivery" timestamp without time zone, "DeliveredToName" character varying, "CreatedAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT s."ShipmentId", s."ShipmentNumber"::VARCHAR, s."TrackingNumber"::VARCHAR,
         s."CarrierCode"::VARCHAR, s."OriginCity"::VARCHAR, s."OriginCountryCode"::VARCHAR,
         s."DestCity"::VARCHAR, s."DestCountryCode"::VARCHAR, s."Status"::VARCHAR,
         s."ServiceType"::VARCHAR, s."EstimatedDelivery", s."ActualDelivery",
         s."DeliveredToName"::VARCHAR, s."CreatedAt"
  FROM logistics."Shipment" s
  WHERE (s."TrackingNumber" = p_tracking_number OR s."ShipmentNumber" = p_tracking_number)
    AND s."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- 24. usp_shipping_track_events: add p_company_id, filter Shipment by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION logistics.usp_shipping_track_events(
    p_company_id integer,
    p_tracking_number character varying
) RETURNS TABLE("ShipmentEventId" bigint, "EventType" character varying, "Status" character varying, "Description" character varying, "Location" character varying, "City" character varying, "CountryCode" character varying, "EventAt" timestamp without time zone)
    LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT e."ShipmentEventId", e."EventType"::VARCHAR, e."Status"::VARCHAR,
         e."Description"::VARCHAR, e."Location"::VARCHAR, e."City"::VARCHAR,
         e."CountryCode"::VARCHAR, e."EventAt"
  FROM logistics."ShipmentEvent" e
  INNER JOIN logistics."Shipment" s ON s."ShipmentId" = e."ShipmentId"
  WHERE (s."TrackingNumber" = p_tracking_number OR s."ShipmentNumber" = p_tracking_number)
    AND s."CompanyId" = p_company_id
  ORDER BY e."EventAt" DESC;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- MFG: Add p_company_id to functions that lack it
-- ============================================================

-- 25. usp_mfg_bom_activate: add p_company_id, filter BOM by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_bom_activate(
    p_company_id integer,
    p_bom_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE mfg."BillOfMaterials"
    SET    "Status" = 'ACTIVE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "BOMId" = p_bom_id
      AND  "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'BOM no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 26. usp_mfg_bom_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_bom_get(
    p_company_id integer,
    p_bom_id integer
) RETURNS TABLE("BOMId" bigint, "BOMCode" character varying, "BOMName" character varying, "CompanyId" integer, "ProductId" bigint, "OutputQuantity" numeric, "Status" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, _section character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BOMId", b."BOMCode", b."BOMName", b."CompanyId",
        b."ProductId", b."OutputQuantity",
        b."Status", b."CreatedAt", b."UpdatedAt",
        'header'::VARCHAR
    FROM mfg."BillOfMaterials" b
    WHERE b."BOMId" = p_bom_id
      AND b."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- 27. usp_mfg_bom_obsolete: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_bom_obsolete(
    p_company_id integer,
    p_bom_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE mfg."BillOfMaterials"
    SET    "Status" = 'OBSOLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "BOMId" = p_bom_id
      AND  "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'BOM no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 28. usp_mfg_routing_list: add p_company_id, JOIN BOM for CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_routing_list(
    p_company_id integer,
    p_bom_id integer
) RETURNS TABLE("RoutingId" bigint, "BOMId" bigint, "OperationNumber" integer, "WorkCenterId" bigint, "WorkCenterName" character varying, "OperationName" character varying, "SetupTimeMinutes" numeric, "RunTimeMinutes" numeric, "Notes" character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."RoutingId", r."BOMId", r."OperationNumber",
        r."WorkCenterId", wc."WorkCenterName",
        r."OperationName", r."SetupTimeMinutes", r."RunTimeMinutes",
        r."Notes"::VARCHAR
    FROM   mfg."Routing" r
    INNER JOIN mfg."BillOfMaterials" b ON b."BOMId" = r."BOMId"
    LEFT JOIN mfg."WorkCenter" wc ON wc."WorkCenterId" = r."WorkCenterId"
    WHERE  r."BOMId" = p_bom_id
      AND  b."CompanyId" = p_company_id
    ORDER BY r."OperationNumber";
END;
$$;
-- +goose StatementEnd

-- 29. usp_mfg_routing_upsert: add p_company_id, validate BOM belongs to company
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_routing_upsert(
    p_company_id integer,
    p_bom_id integer,
    p_routing_id integer DEFAULT NULL::integer,
    p_operation_number integer DEFAULT 0,
    p_work_center_id integer DEFAULT NULL::integer,
    p_operation_name character varying DEFAULT NULL::character varying,
    p_setup_time_minutes numeric DEFAULT 0,
    p_run_time_minutes numeric DEFAULT 0,
    p_notes character varying DEFAULT NULL::character varying,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate BOM belongs to company
    IF NOT EXISTS (SELECT 1 FROM mfg."BillOfMaterials" WHERE "BOMId" = p_bom_id AND "CompanyId" = p_company_id) THEN
        RETURN QUERY SELECT 0, 'BOM no encontrado'::VARCHAR;
        RETURN;
    END IF;

    IF p_routing_id IS NULL THEN
        INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "WorkCenterId", "OperationName", "SetupTimeMinutes", "RunTimeMinutes", "Notes", "CreatedAt", "UpdatedAt")
        VALUES (p_bom_id, p_operation_number, p_work_center_id, p_operation_name, p_setup_time_minutes, p_run_time_minutes, p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE mfg."Routing"
        SET    "OperationNumber"  = p_operation_number,
               "WorkCenterId"     = p_work_center_id,
               "OperationName"    = p_operation_name,
               "SetupTimeMinutes" = p_setup_time_minutes,
               "RunTimeMinutes"   = p_run_time_minutes,
               "Notes"            = p_notes,
               "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
        WHERE  "RoutingId" = p_routing_id AND "BOMId" = p_bom_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 30. usp_mfg_workorder_cancel: add p_company_id, filter WorkOrder by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_cancel(
    p_company_id integer,
    p_work_order_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id AND wo."CompanyId" = p_company_id;

    IF v_status IS NULL THEN
        RETURN QUERY SELECT 0, 'Orden no encontrada'::VARCHAR;
        RETURN;
    END IF;

    IF v_status IN ('COMPLETED', 'CANCELLED') THEN
        RETURN QUERY SELECT 0, ('No se puede cancelar una orden en estado ' || v_status)::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'CANCELLED', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 31. usp_mfg_workorder_complete: add p_company_id, filter WorkOrder by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_complete(
    p_company_id integer,
    p_work_order_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id AND wo."CompanyId" = p_company_id;

    IF v_status IS NULL THEN
        RETURN QUERY SELECT 0, 'Orden no encontrada'::VARCHAR;
        RETURN;
    END IF;

    IF v_status <> 'IN_PROGRESS' THEN
        RETURN QUERY SELECT 0, ('Solo se puede completar una orden en estado IN_PROGRESS. Estado actual: ' || v_status)::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'COMPLETED', "ActualEndDate" = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 32. usp_mfg_workorder_consumematerial: add p_company_id, validate WorkOrder belongs to company
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_consumematerial(
    p_company_id integer,
    p_work_order_id integer,
    p_product_id bigint DEFAULT NULL::bigint,
    p_quantity numeric DEFAULT 0,
    p_lot_number character varying DEFAULT NULL::character varying,
    p_warehouse_id integer DEFAULT NULL::integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_next_line INT;
BEGIN
    -- Validate WorkOrder belongs to company
    IF NOT EXISTS (SELECT 1 FROM mfg."WorkOrder" WHERE "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id) THEN
        RETURN QUERY SELECT 0, 'Orden no encontrada'::VARCHAR;
        RETURN;
    END IF;

    SELECT COALESCE(MAX("LineNumber"), 0) + 1 INTO v_next_line
    FROM   mfg."WorkOrderMaterial"
    WHERE  "WorkOrderId" = p_work_order_id;

    INSERT INTO mfg."WorkOrderMaterial" (
        "WorkOrderId", "LineNumber", "ProductId",
        "PlannedQuantity", "ConsumedQuantity", "UnitOfMeasure",
        "LotId", "BinId", "UnitCost", "Notes",
        "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_work_order_id, v_next_line, p_product_id,
        p_quantity, p_quantity, 'UND',
        NULL, NULL, 0, NULL,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- 33. usp_mfg_workorder_get: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_get(
    p_company_id integer,
    p_work_order_id integer
) RETURNS TABLE("WorkOrderId" bigint, "WorkOrderNumber" character varying, "CompanyId" integer, "BranchId" integer, "BOMId" bigint, "ProductId" bigint, "PlannedQuantity" numeric, "ProducedQuantity" numeric, "ScrapQuantity" numeric, "UnitOfMeasure" character varying, "Status" character varying, "Priority" character varying, "PlannedStartDate" timestamp without time zone, "PlannedEndDate" timestamp without time zone, "ActualStartDate" timestamp without time zone, "ActualEndDate" timestamp without time zone, "WarehouseId" bigint, "Notes" text, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, _section character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        wo."WorkOrderId", wo."WorkOrderNumber", wo."CompanyId", wo."BranchId",
        wo."BOMId", wo."ProductId",
        wo."PlannedQuantity", wo."ProducedQuantity",
        wo."ScrapQuantity", wo."UnitOfMeasure",
        wo."Status", wo."Priority",
        wo."PlannedStartDate", wo."PlannedEndDate",
        wo."ActualStartDate", wo."ActualEndDate",
        wo."WarehouseId",
        wo."Notes"::TEXT, wo."CreatedAt", wo."UpdatedAt",
        'header'::VARCHAR
    FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id
      AND wo."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- 34. usp_mfg_workorder_reportoutput: add p_company_id, validate WorkOrder belongs to company
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_reportoutput(
    p_company_id integer,
    p_work_order_id integer,
    p_quantity numeric,
    p_lot_number character varying DEFAULT NULL::character varying,
    p_warehouse_id integer DEFAULT NULL::integer,
    p_bin_id integer DEFAULT NULL::integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying, "OutputId" integer)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
    v_product_id INT;
BEGIN
    SELECT wo."ProductId" INTO v_product_id
    FROM   mfg."WorkOrder" wo
    WHERE  wo."WorkOrderId" = p_work_order_id
      AND  wo."CompanyId" = p_company_id;

    IF v_product_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Orden no encontrada'::VARCHAR, 0;
        RETURN;
    END IF;

    INSERT INTO mfg."WorkOrderOutput" (
        "WorkOrderId", "ProductId", "Quantity", "UnitOfMeasure",
        "LotNumber", "WarehouseId", "BinId", "UnitCost",
        "IsScrap", "Notes", "ProducedAt", "CreatedByUserId", "CreatedAt"
    ) VALUES (
        p_work_order_id, v_product_id, p_quantity, 'UND',
        p_lot_number, p_warehouse_id, p_bin_id, 0,
        FALSE, NULL, NOW() AT TIME ZONE 'UTC', p_user_id, NOW() AT TIME ZONE 'UTC'
    ) RETURNING "WorkOrderOutputId" INTO v_id;

    UPDATE mfg."WorkOrder"
    SET    "ProducedQuantity" = COALESCE("ProducedQuantity", 0) + p_quantity,
           "UpdatedByUserId"  = p_user_id,
           "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0;
END;
$$;
-- +goose StatementEnd

-- 35. usp_mfg_workorder_start: add p_company_id, filter WorkOrder by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_mfg_workorder_start(
    p_company_id integer,
    p_work_order_id integer,
    p_user_id integer DEFAULT NULL::integer
) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id AND wo."CompanyId" = p_company_id;

    IF v_status IS NULL THEN
        RETURN QUERY SELECT 0, 'Orden no encontrada'::VARCHAR;
        RETURN;
    END IF;

    IF v_status <> 'PLANNED' THEN
        RETURN QUERY SELECT 0, ('Solo se puede iniciar una orden en estado PLANNED. Estado actual: ' || v_status)::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'IN_PROGRESS', "ActualStartDate" = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- STORE: Add p_company_id to functions that lack it
-- ============================================================

-- 36. usp_store_customer_login: add p_company_id as FIRST param (was no param)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_customer_login(
    p_company_id integer,
    p_email character varying
) RETURNS TABLE("UserId" integer, "Email" character varying, "displayName" character varying, "passwordHash" character varying, "isActive" boolean, "customerCode" character varying, "customerName" character varying, phone character varying, address character varying, "fiscalId" character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserId", u."Email"::VARCHAR, u."DisplayName"::VARCHAR, u."PasswordHash"::VARCHAR,
           u."IsActive", c."CustomerCode"::VARCHAR, c."CustomerName"::VARCHAR,
           c."Phone"::VARCHAR, c."AddressLine"::VARCHAR, c."FiscalId"::VARCHAR
    FROM sec."User" u
    LEFT JOIN master."Customer" c ON c."Email" = u."Email" AND c."CompanyId" = p_company_id AND c."IsDeleted" = FALSE
    WHERE LOWER(u."Email") = LOWER(p_email)
      AND u."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- 37. usp_store_order_getbynumber_lines: add p_company_id, filter by CompanyId via SalesDocument
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_getbynumber_lines(
    p_company_id integer,
    p_order_number character varying DEFAULT NULL::character varying
) RETURNS TABLE("lineNumber" integer, "productCode" character varying, "productName" character varying, quantity numeric, "unitPrice" numeric, subtotal numeric, "taxRate" numeric, "taxAmount" numeric, "lineTotal" numeric)
    LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT l."LineNumber", l."ProductCode"::VARCHAR(80), l."Description"::VARCHAR(250),
        l."Quantity", l."UnitPrice", l."Subtotal",
        l."TaxRate", l."TaxAmount", l."LineTotal"
    FROM doc."SalesDocumentLine" l
    INNER JOIN doc."SalesDocument" d ON d."DocumentNumber" = l."DocumentNumber"
    WHERE l."DocumentNumber" = p_order_number
      AND l."SerialType" = 'ECOM'
      AND l."IsVoided" = FALSE
      AND d."CompanyId" = p_company_id
    ORDER BY l."LineNumber";
END;
$$;
-- +goose StatementEnd

-- 38. usp_store_paymentmethod_delete: add p_company_id, filter by CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_paymentmethod_delete(
    p_company_id integer,
    p_payment_method_id integer DEFAULT NULL::integer,
    p_customer_code character varying DEFAULT NULL::character varying
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                  WHERE "PaymentMethodId" = p_payment_method_id
                    AND "CustomerCode" = p_customer_code
                    AND "CompanyId" = p_company_id
                    AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Metodo de pago no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CustomerPaymentMethod"
    SET "IsDeleted" = TRUE, "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "PaymentMethodId" = p_payment_method_id
      AND "CustomerCode" = p_customer_code
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Revert all functions to their original signatures (without p_company_id as first param).
-- Since CREATE OR REPLACE changes the function in-place, the Down migration
-- would need to restore the original function bodies. For safety, we DROP the new
-- overloaded signatures. The baseline 005_functions.sql can be re-applied to restore originals.

-- Fleet
DROP FUNCTION IF EXISTS public.usp_fleet_maintenanceorder_cancel(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_fleet_maintenanceorder_complete(integer, integer, numeric, timestamp without time zone, integer);
DROP FUNCTION IF EXISTS public.usp_fleet_maintenanceorder_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_fleet_vehicle_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_fleet_vehicledocument_list(integer, integer);
DROP FUNCTION IF EXISTS public.usp_fleet_trip_complete(integer, integer, numeric, timestamp without time zone, numeric, integer);

-- Logistics
DROP FUNCTION IF EXISTS public.usp_logistics_deliverynote_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_logistics_deliverynote_deliver(integer, integer, character varying, text, integer);
DROP FUNCTION IF EXISTS public.usp_logistics_deliverynote_dispatch(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_logistics_goodsreceipt_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_logistics_goodsreceipt_approve(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_logistics_goodsreturn_approve(integer, integer, integer);

-- Shipping
DROP FUNCTION IF EXISTS logistics.usp_shipping_address_list(integer, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_address_upsert(integer, bigint, bigint, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, boolean);
DROP FUNCTION IF EXISTS logistics.usp_shipping_customer_profile(integer, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_dashboard(integer, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_shipment_events(integer, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_shipment_get(integer, bigint, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_shipment_list(integer, bigint, character varying, character varying, integer, integer);
DROP FUNCTION IF EXISTS logistics.usp_shipping_shipment_packages(integer, bigint);
DROP FUNCTION IF EXISTS logistics.usp_shipping_shipment_updatestatus(integer, bigint, character varying, character varying, character varying, character varying, character varying, character varying, character varying);
DROP FUNCTION IF EXISTS logistics.usp_shipping_customs_upsert(integer, bigint, character varying, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, numeric, character varying);
DROP FUNCTION IF EXISTS logistics.usp_shipping_track(integer, character varying);
DROP FUNCTION IF EXISTS logistics.usp_shipping_track_events(integer, character varying);

-- MFG
DROP FUNCTION IF EXISTS public.usp_mfg_bom_activate(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_bom_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_bom_obsolete(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_routing_list(integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_routing_upsert(integer, integer, integer, integer, integer, character varying, numeric, numeric, character varying, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_cancel(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_complete(integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_consumematerial(integer, integer, bigint, numeric, character varying, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_get(integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_reportoutput(integer, integer, numeric, character varying, integer, integer, integer);
DROP FUNCTION IF EXISTS public.usp_mfg_workorder_start(integer, integer, integer);

-- Store
DROP FUNCTION IF EXISTS public.usp_store_customer_login(integer, character varying);
DROP FUNCTION IF EXISTS public.usp_store_order_getbynumber_lines(integer, character varying);
DROP FUNCTION IF EXISTS public.usp_store_paymentmethod_delete(integer, integer, character varying);
