import { describe, it, expect } from "vitest";
import { buildEnvelope, topicName } from "../src/events/envelope.js";

describe("buildEnvelope", () => {
  it("produce un envelope con todos los campos requeridos", () => {
    const e = buildEnvelope({
      eventType: "crm.lead.created",
      tenantCode: "acme",
      source: "zentto-hotel",
      data: { leadId: 1 },
    });
    expect(e.eventId).toMatch(/^evt_[0-9a-f-]{36}$/);
    expect(e.eventType).toBe("crm.lead.created");
    expect(e.tenantCode).toBe("ACME"); // siempre upper
    expect(e.source).toBe("zentto-hotel");
    expect(e.version).toBe(1);
    expect(e.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T/);
    expect(e.data).toEqual({ leadId: 1 });
  });

  it("respeta overrides opcionales", () => {
    const e = buildEnvelope({
      eventType: "x",
      tenantCode: "X",
      source: "s",
      data: {},
      version: 3,
      correlationId: "req-1",
      eventId: "evt_fixed",
      timestamp: "2026-01-01T00:00:00Z",
    });
    expect(e.version).toBe(3);
    expect(e.correlationId).toBe("req-1");
    expect(e.eventId).toBe("evt_fixed");
    expect(e.timestamp).toBe("2026-01-01T00:00:00Z");
  });
});

describe("topicName", () => {
  it("arma zentto.<tenant>.<event> en lowercase del tenant", () => {
    expect(topicName("ACME", "crm.lead.created")).toBe("zentto.acme.crm.lead.created");
    expect(topicName("zentto", "hotel.reservation.confirmed"))
      .toBe("zentto.zentto.hotel.reservation.confirmed");
  });
});
