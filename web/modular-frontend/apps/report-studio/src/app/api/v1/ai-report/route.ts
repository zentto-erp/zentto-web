import { NextResponse } from "next/server";

// AI proxy — keeps API keys server-side, never exposed to browser
// Supports: OpenAI GPT, Anthropic Claude
// Keys from .env.local: OPENAI_API_KEY, ANTHROPIC_API_KEY

const OPENAI_KEY = process.env.OPENAI_API_KEY || "";
const ANTHROPIC_KEY = process.env.ANTHROPIC_API_KEY || "";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { system, messages, provider } = body;

    if (!system || !messages) {
      return NextResponse.json({ error: "Missing system or messages" }, { status: 400 });
    }

    // Try OpenAI first (cheaper), then Anthropic
    const useProvider = provider === "anthropic" && ANTHROPIC_KEY
      ? "anthropic"
      : OPENAI_KEY
        ? "openai"
        : ANTHROPIC_KEY
          ? "anthropic"
          : null;

    if (!useProvider) {
      return NextResponse.json({
        content: "No hay API key configurada en el servidor. Agrega OPENAI_API_KEY o ANTHROPIC_API_KEY en .env.local",
      });
    }

    if (useProvider === "openai") {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [{ role: "system", content: system }, ...messages],
          max_tokens: 4096,
        }),
      });
      const data = await res.json();
      return NextResponse.json({
        content: data.choices?.[0]?.message?.content || `Error: ${data.error?.message || "no response"}`,
        provider: "openai",
      });
    }

    if (useProvider === "anthropic") {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": ANTHROPIC_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 4096,
          system,
          messages,
        }),
      });
      const data = await res.json();
      return NextResponse.json({
        content: data.content?.[0]?.text || `Error: ${data.error?.message || "no response"}`,
        provider: "anthropic",
      });
    }
  } catch (err: any) {
    return NextResponse.json({ content: `Error del servidor: ${err.message}` }, { status: 500 });
  }
}
