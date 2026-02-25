const jsreport = require('jsreport')({
    httpPort: 5070,
    store: { provider: 'fs' },
    allowLocalFilesAccess: true,
    templatingEngines: {
        strategy: 'in-process'
    },
    extensions: {
        'chrome-pdf': {
            launchOptions: {
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            }
        }
    },
    logger: {
        console: { transport: 'console', level: 'info' }
    }
});

jsreport.init().then(() => {
    console.log(`
╔══════════════════════════════════════════════════════╗
║         DatqBox jsreport Server                     ║
║   Motor de Reportes Open Source (Node.js)            ║
╠══════════════════════════════════════════════════════╣
║   Studio:  http://localhost:5070                     ║
║   API:     http://localhost:5070/api/report          ║
╚══════════════════════════════════════════════════════╝
    `);
}).catch((e) => {
    console.error('[ERROR] No se pudo iniciar jsreport:', e.message);
    console.error(e.stack);
    process.exit(1);
});
