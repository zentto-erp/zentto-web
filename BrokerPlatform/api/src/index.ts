import "dotenv/config";
import { createApp } from "./app.js";
import { env } from "./config/env.js";
import { aggregatorWorker } from "./cron/aggregator.js";

async function main() {
    const app = await createApp();

    // Inicia el recolector de datos Cron Engine en segundo plano
    aggregatorWorker.start();

    app.listen(env.port, () => {
        console.log(`🚀 Broker API running on http://localhost:${env.port}`);
        console.log(`   Environment: ${env.nodeEnv}`);
        console.log(`   Database:    ${env.db.server}/${env.db.database}`);
    });
}

main().catch((err) => {
    console.error("Failed to start Broker API:", err);
    process.exit(1);
});
