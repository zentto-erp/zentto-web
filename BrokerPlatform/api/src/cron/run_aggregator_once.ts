import "dotenv/config";
import { aggregatorWorker } from "./aggregator.js";

async function main() {
    await aggregatorWorker.runManual();
    process.exit(0);
}

main().catch((error) => {
    console.error("[Aggregator] Manual run failed", error);
    process.exit(1);
});
