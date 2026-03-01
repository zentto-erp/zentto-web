import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env.js";
import { healthRouter } from "./modules/health/routes.js";
import { authRouter } from "./modules/auth/routes.js";
import { providersRouter } from "./modules/providers/routes.js";
import { propertiesRouter } from "./modules/properties/routes.js";
import { bookingsRouter } from "./modules/bookings/routes.js";
import { customersRouter } from "./modules/customers/routes.js";
import { paymentsRouter } from "./modules/payments/routes.js";
import { reviewsRouter } from "./modules/reviews/routes.js";
import { searchRouter } from "./modules/search/routes.js";
import { promotionsRouter } from "./modules/promotions/routes.js";
import { amenitiesRouter } from "./modules/amenities/routes.js";
import { currenciesRouter } from "./modules/currencies/routes.js";
import { settingsRouter } from "./modules/settings/routes.js";
import { requireJwt } from "./middleware/auth.js";
import { errorHandler } from "./middleware/error.js";

export async function createApp() {
    const app = express();
    app.disable("etag");
    app.use(helmet());
    app.use(
        cors({
            origin: [
                "http://localhost:3100",
                "http://localhost:3000",
                "http://127.0.0.1:3100",
                "http://127.0.0.1:3000",
            ],
            credentials: true,
        })
    );
    app.use(express.json({ limit: "2mb" }));
    app.use(morgan("dev"));

    // Root
    app.get("/", (_req, res) => {
        res.json({ name: "Broker Platform API", env: env.nodeEnv, version: "v1" });
    });

    // Health (no auth)
    app.use("/health", healthRouter);

    // Auth (no JWT required for login/register)
    app.use("/v1/auth", authRouter);

    // Public search (no auth required)
    app.use("/v1/search", searchRouter);

    // Public property detail (no auth required)
    app.get("/v1/public/properties/:id", async (req, res, next) => {
        try {
            const { getProperty } = await import("./modules/properties/service.js");
            const data = await getProperty(Number(req.params.id));
            if (!data) return res.status(404).json({ error: "not_found" });
            res.json(data);
        } catch (err) { next(err); }
    });

    // JWT required for all other /v1 routes
    app.use("/v1", requireJwt);

    // Protected routes
    app.use("/v1/providers", providersRouter);
    app.use("/v1/properties", propertiesRouter);
    app.use("/v1/bookings", bookingsRouter);
    app.use("/v1/customers", customersRouter);
    app.use("/v1/payments", paymentsRouter);
    app.use("/v1/reviews", reviewsRouter);
    app.use("/v1/promotions", promotionsRouter);
    app.use("/v1/amenities", amenitiesRouter);
    app.use("/v1/currencies", currenciesRouter);
    app.use("/v1/settings", settingsRouter);

    // Error handler
    app.use(errorHandler);

    return app;
}
