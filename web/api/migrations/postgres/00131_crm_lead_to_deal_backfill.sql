-- +goose Up
-- Backfill: Lead → Deal para leads existentes que tengan Stage asignado y
-- Status OPEN/WON/LOST. Marca los leads convertidos. Cada registro llevara
-- history ChangeType='BACKFILL' con origin=LeadId.
-- Es idempotente: si ya existe un Deal con SourceLeadId=x, no lo duplica.

-- +goose StatementBegin
DO $$
DECLARE
    v_lead      crm."Lead"%ROWTYPE;
    v_deal_id   BIGINT;
    v_new_status VARCHAR(10);
BEGIN
    FOR v_lead IN
        SELECT l.*
          FROM crm."Lead" l
         WHERE l."IsDeleted" = FALSE
           AND l."Status" IN ('OPEN','WON','LOST')
           AND NOT EXISTS (
               SELECT 1 FROM crm."Deal" d WHERE d."SourceLeadId" = l."LeadId"
           )
    LOOP
        v_new_status := CASE v_lead."Status"
                          WHEN 'WON'  THEN 'WON'
                          WHEN 'LOST' THEN 'LOST'
                          ELSE 'OPEN'
                        END;

        INSERT INTO crm."Deal" (
            "CompanyId","BranchId","Name","PipelineId","StageId",
            "Value","Currency","ExpectedCloseDate","Status","SourceLeadId",
            "Priority","Source","Notes","CreatedAt","UpdatedAt"
        ) VALUES (
            v_lead."CompanyId", v_lead."BranchId",
            COALESCE(v_lead."ContactName", 'Lead-' || v_lead."LeadId"::VARCHAR),
            v_lead."PipelineId", v_lead."StageId",
            COALESCE(v_lead."EstimatedValue", 0),
            COALESCE(v_lead."CurrencyCode", 'USD'),
            v_lead."ExpectedCloseDate",
            v_new_status,
            v_lead."LeadId",
            COALESCE(v_lead."Priority", 'MEDIUM'),
            COALESCE(v_lead."Source", 'OTHER'),
            v_lead."Notes",
            v_lead."CreatedAt",
            v_lead."UpdatedAt"
        )
        RETURNING "DealId" INTO v_deal_id;

        INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","Notes")
        VALUES (v_deal_id, 'BACKFILL',
                jsonb_build_object('sourceLeadId', v_lead."LeadId",
                                   'originalStatus', v_lead."Status"),
                'Backfill automatico desde crm.Lead');

        IF v_new_status IN ('WON','LOST') THEN
            UPDATE crm."Lead"
               SET "ConvertedToDealId" = v_deal_id
             WHERE "LeadId" = v_lead."LeadId";
        END IF;
    END LOOP;
END
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM crm."Deal" d
 WHERE EXISTS (
     SELECT 1 FROM crm."DealHistory" h
      WHERE h."DealId" = d."DealId"
        AND h."ChangeType" = 'BACKFILL'
 );
-- +goose StatementEnd

-- +goose StatementBegin
UPDATE crm."Lead" SET "ConvertedToDealId" = NULL WHERE "ConvertedToDealId" IS NOT NULL;
-- +goose StatementEnd
