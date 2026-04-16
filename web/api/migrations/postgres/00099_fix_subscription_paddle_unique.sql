-- +goose Up
-- Fix: Subscription_PaddleSubscriptionId_key era UNIQUE global, impidiendo
-- múltiples trial subscriptions con PaddleSubscriptionId vacío.
-- Reemplazado por partial unique index que solo aplica cuando hay un ID real.

ALTER TABLE sys."Subscription" DROP CONSTRAINT IF EXISTS "Subscription_PaddleSubscriptionId_key";
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Subscription_PaddleSubscriptionId"
  ON sys."Subscription" ("PaddleSubscriptionId")
  WHERE "PaddleSubscriptionId" IS NOT NULL AND "PaddleSubscriptionId" <> '';

-- +goose Down
DROP INDEX IF EXISTS sys."UQ_Subscription_PaddleSubscriptionId";
ALTER TABLE sys."Subscription"
  ADD CONSTRAINT "Subscription_PaddleSubscriptionId_key" UNIQUE ("PaddleSubscriptionId");
