export async function register(app, ctx) {
  app.get(`/addons/${ctx.addon.id}/ping`, (_req, res) => {
    res.json({ addon: ctx.addon.id, ok: true });
  });
}
