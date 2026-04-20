# Env vars — Ola 2 ecommerce (admin productos + uploads S3)

Documento vivo con las variables de entorno nuevas introducidas por la
Ola 2 (`feat/ecommerce-admin-productos`). Si alguna falta, el endpoint
`POST /store/admin/uploads/product-image` cae a disk storage con un
warning al arrancar la API.

## 1. Variables nuevas

| Nombre                                  | Tipo       | Obligatorio | Valor esperado                                  |
| --------------------------------------- | ---------- | :---------: | ----------------------------------------------- |
| `HETZNER_S3_PRODUCT_IMAGES_BUCKET`      | GH secret  |     sí      | `zentto-product-images`                         |
| `HETZNER_S3_PRODUCT_IMAGES_ENDPOINT`    | GH secret  |     sí      | `https://nbg1.your-objectstorage.com`           |
| `HETZNER_S3_PRODUCT_IMAGES_ACCESS_KEY`  | GH secret  |     sí      | Access key de la nueva API key de Hetzner      |
| `HETZNER_S3_PRODUCT_IMAGES_SECRET_KEY`  | GH secret  |     sí      | Secret key de la nueva API key de Hetzner      |
| `HETZNER_S3_PRODUCT_IMAGES_REGION`      | GH secret  |     no      | `nbg1` (default si no se configura)            |
| `HETZNER_S3_PRODUCT_IMAGES_PUBLIC_URL`  | GH secret  |     no      | `https://cdn.zentto.net` (si hay CDN delante)  |

## 2. Cómo añadirlas al deploy

Ya aplicado en `.github/workflows/deploy-api.yml`:

- Bloque `env:` del step `ssh-action`: se agregaron las 6 entradas
  `HETZNER_S3_PRODUCT_IMAGES_*` desde `${{ secrets.* }}`.
- Bloque `envs:` de `with`: se listaron las 6 variables para que lleguen
  al SSH.
- Bloque `script:` del deploy: se replicó el patrón `grep | sed | echo`
  existente para el bucket de backups (`HETZNER_S3_*`) y se añadió un
  bloque análogo debajo con el comentario
  `# ── Hetzner Object Storage (Ola 2: imágenes producto público) ──`.

## 3. Código consumidor

- `web/api/src/config/env.ts` — expone `env.productImagesS3` (bucket,
  endpoint, accessKey, secretKey, region, publicUrl).
- `web/api/src/modules/ecommerce/admin-products.routes.ts` — usa
  `multer.memoryStorage()` + `@aws-sdk/client-s3` `PutObjectCommand`.
  Si `env.productImagesS3.bucket` está vacío, emite un warning al
  arrancar y cae a disk storage.

## 4. Validación local

Sin bucket configurado (entorno dev sin S3):

```bash
cd web/api && npm run build  # debe pasar; warning visible al arrancar
```

Con bucket configurado:

```bash
export HETZNER_S3_PRODUCT_IMAGES_BUCKET=zentto-product-images
export HETZNER_S3_PRODUCT_IMAGES_ENDPOINT=https://nbg1.your-objectstorage.com
export HETZNER_S3_PRODUCT_IMAGES_ACCESS_KEY=...
export HETZNER_S3_PRODUCT_IMAGES_SECRET_KEY=...
cd web/api && npm start
# POST /store/admin/uploads/product-image con multipart file
# Respuesta: { url: "https://cdn.zentto.net/c1/b1/products/...", storageProvider: "hetzner-s3" }
```

## 5. Pendientes (fuera del scope Ola 2)

- Crear el bucket en Hetzner (Nuremberg) y configurar CORS
  `https://*.zentto.net`.
- Sembrar los secrets reales en GitHub Actions (
  `HETZNER_S3_PRODUCT_IMAGES_ACCESS_KEY`,
  `HETZNER_S3_PRODUCT_IMAGES_SECRET_KEY`).
- Levantar `cdn.zentto.net` en Cloudflare apuntando al bucket público
  (opcional — si no, el endpoint directo de Hetzner funciona).
- Migración de imágenes existentes en disk (`web/api/storage/media/`)
  al bucket: scripts a cargo de ops, fuera de esta PR.
