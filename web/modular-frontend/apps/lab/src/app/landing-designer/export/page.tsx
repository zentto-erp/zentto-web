"use client";

import React, { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box, Button, Typography, Paper, Alert, Tabs, Tab, Snackbar,
  TextField, CircularProgress,
} from "@mui/material";
import {
  ArrowBack as BackIcon,
  Download as DownloadIcon,
  ContentCopy as CopyIcon,
  Rocket as DeployIcon,
  Code as CodeIcon,
  Language as WebIcon,
  Terminal as TerminalIcon,
} from "@mui/icons-material";

const STORAGE_KEY = "zentto-landing-designer-config";

/* ------------------------------------------------------------------ */
/*  Static site generator — HTML autocontenido con CDN                 */
/* ------------------------------------------------------------------ */

function generateStaticSite(config: any): string {
  const title = config?.branding?.title || config?.landingConfig?.navbar?.title || "Mi Sitio";
  const description = config?.landingConfig?.seo?.description || `${title} — Creado con Zentto Studio`;
  const primaryColor = config?.branding?.primaryColor || "#6366f1";
  const configJson = JSON.stringify(config, null, 2);

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escHtml(title)}</title>
  <meta name="description" content="${escHtml(description)}">
  <meta name="theme-color" content="${primaryColor}">

  <!-- Open Graph -->
  <meta property="og:title" content="${escHtml(title)}">
  <meta property="og:description" content="${escHtml(description)}">
  <meta property="og:type" content="website">

  <!-- Favicon -->
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🚀</text></svg>">

  <style>
    *, *::before, *::after { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; min-height: 100vh; }
    body { font-family: system-ui, -apple-system, sans-serif; }

    /* Loading spinner */
    .zl-loading {
      display: flex; align-items: center; justify-content: center;
      height: 100vh; flex-direction: column; gap: 16px;
    }
    .zl-spinner {
      width: 40px; height: 40px;
      border: 3px solid #e5e7eb; border-top-color: ${primaryColor};
      border-radius: 50%; animation: zl-spin 0.8s linear infinite;
    }
    @keyframes zl-spin { to { transform: rotate(360deg); } }
    .zl-loading-text { color: #6b7280; font-size: 14px; }

    /* Hide app until ready */
    zentto-studio-app:not(:defined) { display: none; }
  </style>
</head>
<body>
  <!-- Loading indicator -->
  <div class="zl-loading" id="zl-loader">
    <div class="zl-spinner"></div>
    <span class="zl-loading-text">Cargando...</span>
  </div>

  <!-- Landing page app -->
  <zentto-studio-app id="zl-app" style="display:block;width:100%;min-height:100vh;"></zentto-studio-app>

  <!-- Zentto Studio from CDN -->
  <script type="module">
    import 'https://esm.sh/@zentto/studio@0.12.0/app';
    import 'https://esm.sh/@zentto/studio@0.12.0/landing';

    const config = ${configJson};

    const app = document.getElementById('zl-app');
    const loader = document.getElementById('zl-loader');

    // Wait for custom element to be defined
    customElements.whenDefined('zentto-studio-app').then(() => {
      app.config = config;
      if (loader) loader.remove();
    });
  </script>
</body>
</html>`;
}

function escHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

/* ------------------------------------------------------------------ */
/*  Vite project generator                                             */
/* ------------------------------------------------------------------ */

function generateViteProject(config: any): Record<string, string> {
  const title = config?.branding?.title || "Mi Sitio";

  return {
    "package.json": JSON.stringify({
      name: slugify(title),
      private: true,
      type: "module",
      scripts: {
        dev: "vite",
        build: "vite build",
        preview: "vite preview",
      },
      dependencies: {
        "@zentto/studio": "^0.12.0",
        "@zentto/studio-core": "^0.12.0",
      },
      devDependencies: {
        vite: "^6.0.0",
      },
    }, null, 2),

    "vite.config.js": `import { defineConfig } from 'vite';
export default defineConfig({ server: { port: 5555, open: true } });
`,

    "index.html": `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escHtml(title)}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; min-height: 100vh; }
    body { font-family: system-ui, -apple-system, sans-serif; }
  </style>
</head>
<body>
  <zentto-studio-app id="app" style="display:block;width:100%;min-height:100vh;"></zentto-studio-app>
  <script type="module" src="/src/main.js"></script>
</body>
</html>`,

    "src/main.js": `import '@zentto/studio/app';
import '@zentto/studio/landing';
import config from './config.json';

customElements.whenDefined('zentto-studio-app').then(() => {
  document.getElementById('app').config = config;
});
`,

    "src/config.json": JSON.stringify(config, null, 2),

    "README.md": `# ${title}

Sitio generado con Zentto Studio.

## Desarrollo local

\`\`\`bash
npm install
npm run dev    # Abre en http://localhost:5555
\`\`\`

## Build para produccion

\`\`\`bash
npm run build     # Genera en dist/
npm run preview   # Preview del build
\`\`\`

## Deploy

El contenido de \`dist/\` es un sitio estatico. Puedes desplegarlo en:
- **Netlify**: arrastra la carpeta dist/
- **Vercel**: \`npx vercel dist/\`
- **GitHub Pages**: push dist/ a rama gh-pages
- **Cloudflare Pages**: conecta el repo
- **Cualquier hosting**: sube los archivos de dist/
`,
  };
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "mi-sitio";
}

/* ------------------------------------------------------------------ */
/*  ZIP generator (in-browser)                                         */
/* ------------------------------------------------------------------ */

async function downloadAsZip(files: Record<string, string>, zipName: string) {
  // Simple ZIP without external deps using Blob + manual ZIP format
  // For production, use JSZip. For now, download as individual file or tar
  // Fallback: download the main HTML file
  const blob = new Blob([files["index.html"] || ""], { type: "text/html" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${zipName}.html`;
  a.click();
  URL.revokeObjectURL(url);
}

async function downloadViteZip(files: Record<string, string>, zipName: string) {
  // Download as a shell script that creates the project
  const script = Object.entries(files).map(([path, content]) => {
    const dir = path.includes("/") ? path.substring(0, path.lastIndexOf("/")) : "";
    const mkdirCmd = dir ? `mkdir -p "${dir}"\n` : "";
    const escaped = content.replace(/'/g, "'\\''");
    return `${mkdirCmd}cat > '${path}' << 'ZENTTO_EOF'\n${content}\nZENTTO_EOF`;
  }).join("\n\n");

  const fullScript = `#!/bin/bash
# Proyecto Vite generado por Zentto Studio
# Ejecutar: bash ${zipName}.sh && cd ${zipName} && npm install && npm run dev

mkdir -p "${zipName}" && cd "${zipName}"

${script}

echo ""
echo "✅ Proyecto creado en ./${zipName}"
echo "   cd ${zipName} && npm install && npm run dev"
echo ""
`;

  const blob = new Blob([fullScript], { type: "text/x-shellscript" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${zipName}.sh`;
  a.click();
  URL.revokeObjectURL(url);
}

/* ------------------------------------------------------------------ */
/*  Export Page Component                                               */
/* ------------------------------------------------------------------ */

export default function LandingExportPage() {
  const router = useRouter();
  const [config, setConfig] = useState<any>(null);
  const [tab, setTab] = useState(0);
  const [snack, setSnack] = useState({ open: false, msg: "" });
  const previewRef = useRef<HTMLIFrameElement>(null);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) setConfig(JSON.parse(saved));
    } catch { /* noop */ }
  }, []);

  if (!config) {
    return (
      <Box sx={{ p: 4, textAlign: "center" }}>
        <Typography variant="h6" color="text.secondary">No hay landing para exportar</Typography>
        <Button sx={{ mt: 2 }} onClick={() => router.push("/landing-designer")}>Ir al Designer</Button>
      </Box>
    );
  }

  const title = config?.branding?.title || "mi-sitio";
  const slug = slugify(title);
  const staticHtml = generateStaticSite(config);
  const viteFiles = generateViteProject(config);

  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setSnack({ open: true, msg: `${label} copiado al portapapeles` });
  };

  const handleDownloadHtml = () => {
    const blob = new Blob([staticHtml], { type: "text/html" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${slug}.html`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleDownloadVite = () => {
    downloadViteZip(viteFiles, slug);
  };

  const handlePreviewInNewTab = () => {
    const blob = new Blob([staticHtml], { type: "text/html" });
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank");
  };

  return (
    <Box sx={{ p: 3, maxWidth: 1000, mx: "auto" }}>
      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", gap: 2, mb: 3 }}>
        <Button size="small" startIcon={<BackIcon />} onClick={() => router.push("/landing-designer")}>
          Designer
        </Button>
        <Typography variant="h5" fontWeight={700}>Exportar y Desplegar</Typography>
      </Box>

      <Alert severity="info" sx={{ mb: 3 }}>
        Tu landing page es un <strong>sitio estatico autocontenido</strong> — no necesita servidor, base de datos ni framework.
        Descargalo y despliega en cualquier hosting.
      </Alert>

      {/* Tabs */}
      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3 }}>
        <Tab icon={<WebIcon />} label="HTML (un archivo)" />
        <Tab icon={<TerminalIcon />} label="Proyecto Vite" />
        <Tab icon={<CodeIcon />} label="JSON Config" />
      </Tabs>

      {/* Tab 0: Static HTML */}
      {tab === 0 && (
        <Box>
          <Paper sx={{ p: 2, mb: 2, bgcolor: "#f8fafc" }}>
            <Typography variant="subtitle2" gutterBottom>Un solo archivo HTML — listo para desplegar</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Incluye todo: estilos, scripts (via CDN esm.sh), y la configuracion de tu landing.
              Solo sube este archivo a cualquier hosting.
            </Typography>
            <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
              <Button variant="contained" startIcon={<DownloadIcon />} onClick={handleDownloadHtml}>
                Descargar {slug}.html
              </Button>
              <Button variant="outlined" startIcon={<CopyIcon />} onClick={() => handleCopy(staticHtml, "HTML")}>
                Copiar HTML
              </Button>
              <Button variant="outlined" onClick={handlePreviewInNewTab}>
                Preview en nueva pestana
              </Button>
            </Box>
          </Paper>

          <Paper sx={{ p: 2, bgcolor: "#1e293b", color: "#e2e8f0", borderRadius: 2, maxHeight: 400, overflow: "auto" }}>
            <pre style={{ margin: 0, fontSize: 12, fontFamily: "'Fira Code', monospace", whiteSpace: "pre-wrap" }}>
              {staticHtml}
            </pre>
          </Paper>

          <Paper sx={{ p: 2, mt: 2, bgcolor: "#f0fdf4", border: "1px solid #86efac" }}>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Donde desplegarlo:</Typography>
            <Typography variant="body2" component="div">
              <strong>Netlify:</strong> Arrastra el archivo a <a href="https://app.netlify.com/drop" target="_blank" rel="noopener">netlify.com/drop</a><br/>
              <strong>Vercel:</strong> <code>npx vercel {slug}.html</code><br/>
              <strong>GitHub Pages:</strong> Push a un repo → Settings → Pages<br/>
              <strong>Cloudflare Pages:</strong> Conecta repo o sube directo<br/>
              <strong>Cualquier hosting:</strong> Sube el archivo HTML por FTP/SFTP
            </Typography>
          </Paper>
        </Box>
      )}

      {/* Tab 1: Vite Project */}
      {tab === 1 && (
        <Box>
          <Paper sx={{ p: 2, mb: 2, bgcolor: "#f8fafc" }}>
            <Typography variant="subtitle2" gutterBottom>Proyecto Vite completo — desarrollo local + build</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Proyecto con hot-reload, build optimizado y deploy a produccion.
              Ideal si quieres personalizar mas o integrar con tu stack.
            </Typography>
            <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
              <Button variant="contained" startIcon={<DownloadIcon />} onClick={handleDownloadVite}>
                Descargar {slug}.sh
              </Button>
              <Button variant="outlined" startIcon={<CopyIcon />} onClick={() => handleCopy(JSON.stringify(viteFiles, null, 2), "Proyecto")}>
                Copiar archivos
              </Button>
            </Box>
          </Paper>

          <Paper sx={{ p: 2, bgcolor: "#1e293b", color: "#e2e8f0", borderRadius: 2 }}>
            <pre style={{ margin: 0, fontSize: 12, fontFamily: "'Fira Code', monospace" }}>
{`# 1. Descargar y ejecutar el script
bash ${slug}.sh

# 2. Instalar dependencias
cd ${slug}
npm install

# 3. Desarrollo local (puerto 5555)
npm run dev

# 4. Build para produccion
npm run build

# 5. Desplegar dist/ en cualquier hosting`}
            </pre>
          </Paper>

          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>Archivos del proyecto:</Typography>
          {Object.entries(viteFiles).map(([path, content]) => (
            <Paper key={path} sx={{ p: 1.5, mb: 1, bgcolor: "#f8fafc" }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <Typography variant="body2" fontFamily="monospace" fontWeight={600}>{path}</Typography>
                <Button size="small" onClick={() => handleCopy(content, path)}>Copiar</Button>
              </Box>
            </Paper>
          ))}
        </Box>
      )}

      {/* Tab 2: JSON Config */}
      {tab === 2 && (
        <Box>
          <Paper sx={{ p: 2, mb: 2, bgcolor: "#f8fafc" }}>
            <Typography variant="subtitle2" gutterBottom>Configuracion JSON — importar/exportar</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Este JSON contiene toda la configuracion de tu landing. Puedes guardarlo para restaurar despues
              o compartirlo con otros.
            </Typography>
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button variant="contained" startIcon={<CopyIcon />} onClick={() => handleCopy(JSON.stringify(config, null, 2), "JSON")}>
                Copiar JSON
              </Button>
              <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => {
                const blob = new Blob([JSON.stringify(config, null, 2)], { type: "application/json" });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = `${slug}-config.json`;
                a.click();
                URL.revokeObjectURL(url);
              }}>
                Descargar JSON
              </Button>
            </Box>
          </Paper>

          <Paper sx={{ p: 2, bgcolor: "#1e293b", color: "#e2e8f0", borderRadius: 2, maxHeight: 500, overflow: "auto" }}>
            <pre style={{ margin: 0, fontSize: 11, fontFamily: "'Fira Code', monospace", whiteSpace: "pre-wrap" }}>
              {JSON.stringify(config, null, 2)}
            </pre>
          </Paper>
        </Box>
      )}

      <Snackbar
        open={snack.open}
        autoHideDuration={2000}
        onClose={() => setSnack({ open: false, msg: "" })}
        message={snack.msg}
        anchorOrigin={{ vertical: "bottom", horizontal: "left" }}
      />
    </Box>
  );
}
