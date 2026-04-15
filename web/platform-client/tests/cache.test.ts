import { describe, it, expect, vi, afterEach } from "vitest";
import { TtlCache, memoAsync } from "../src/internal/cache.js";

describe("TtlCache", () => {
  afterEach(() => vi.useRealTimers());

  it("guarda y recupera valores", () => {
    const c = new TtlCache<number>({ ttlMs: 1000 });
    c.set("a", 1);
    expect(c.get("a")).toBe(1);
  });

  it("expira tras TTL", async () => {
    const c = new TtlCache<number>({ ttlMs: 10 });
    c.set("a", 1);
    await new Promise((r) => setTimeout(r, 15));
    expect(c.get("a")).toBeUndefined();
  });

  it("FIFO evict cuando excede maxEntries", () => {
    const c = new TtlCache<number>({ ttlMs: 10_000, maxEntries: 2 });
    c.set("a", 1); c.set("b", 2); c.set("c", 3);
    expect(c.get("a")).toBeUndefined(); // evicted
    expect(c.get("b")).toBe(2);
    expect(c.get("c")).toBe(3);
  });

  it("delete y clear limpian entradas", () => {
    const c = new TtlCache<number>({ ttlMs: 1000 });
    c.set("a", 1); c.set("b", 2);
    c.delete("a");
    expect(c.get("a")).toBeUndefined();
    expect(c.size()).toBe(1);
    c.clear();
    expect(c.size()).toBe(0);
  });
});

describe("memoAsync", () => {
  it("hit cache en segunda llamada", async () => {
    const c = new TtlCache<{ ok: boolean; n?: number }>({ ttlMs: 1000 });
    const fn = vi.fn(async () => ({ ok: true, n: 42 }));
    const a = await memoAsync(c, "k", fn);
    const b = await memoAsync(c, "k", fn);
    expect(a).toEqual(b);
    expect(fn).toHaveBeenCalledOnce();
  });

  it("NO cachea respuestas no-ok por default", async () => {
    const c = new TtlCache<{ ok: boolean; error?: string }>({ ttlMs: 1000 });
    const fn = vi.fn(async () => ({ ok: false, error: "nope" }));
    await memoAsync(c, "k", fn);
    await memoAsync(c, "k", fn);
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("single-flight: concurrent callers obtienen la misma promise", async () => {
    const c = new TtlCache<{ ok: boolean; val: number }>({ ttlMs: 1000 });
    let calls = 0;
    const fn = async () => { calls++; await new Promise((r) => setTimeout(r, 20)); return { ok: true, val: 1 }; };
    const [a, b, d] = await Promise.all([
      memoAsync(c, "k", fn),
      memoAsync(c, "k", fn),
      memoAsync(c, "k", fn),
    ]);
    expect(a).toEqual(b);
    expect(b).toEqual(d);
    expect(calls).toBe(1);
  });

  it("shouldCache custom override", async () => {
    const c = new TtlCache<{ status: string }>({ ttlMs: 1000 });
    const fn = vi.fn(async () => ({ status: "pending" }));
    await memoAsync(c, "k", fn, { shouldCache: (r) => r.status === "pending" });
    await memoAsync(c, "k", fn, { shouldCache: (r) => r.status === "pending" });
    expect(fn).toHaveBeenCalledOnce();
  });
});
