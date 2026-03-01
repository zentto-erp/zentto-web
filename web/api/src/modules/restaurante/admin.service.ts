
import { query } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

interface DefaultScope {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
}

let scopeCache: DefaultScope | null = null;

async function getDefaultScope(): Promise<DefaultScope> {
  const activeScope = getActiveScope();
  if (scopeCache && activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (scopeCache) return scopeCache;

  const rows = await query<{ companyId: number; branchId: number; systemUserId: number | null }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId,
      su.UserId AS systemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
      ON b.CompanyId = c.CompanyId
     AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] su
      ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId
    `
  );

  const row = rows[0];
  scopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };
  if (activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  return scopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  if (!code) return (await getDefaultScope()).systemUserId;

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@code)
    ORDER BY UserId
    `,
    { code }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getDefaultScope()).systemUserId;
}

async function resolveSupplierId(value?: string) {
  const scope = await getDefaultScope();
  const key = String(value ?? "").trim();
  if (!key) return null;

  const rows = await query<{ supplierId: number }>(
    `
    SELECT TOP 1 SupplierId AS supplierId
    FROM [master].Supplier
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
        SupplierCode = @key
        OR CAST(SupplierId AS NVARCHAR(30)) = @key
      )
    ORDER BY SupplierId
    `,
    {
      companyId: scope.companyId,
      key,
    }
  );

  return rows[0]?.supplierId == null ? null : Number(rows[0].supplierId);
}

async function resolveInventoryProductId(value?: string) {
  const scope = await getDefaultScope();
  const key = String(value ?? "").trim();
  if (!key) return null;

  const rows = await query<{ productId: number }>(
    `
    SELECT TOP 1 ProductId AS productId
    FROM [master].Product
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
        ProductCode = @key
        OR CAST(ProductId AS NVARCHAR(30)) = @key
      )
    ORDER BY ProductId
    `,
    {
      companyId: scope.companyId,
      key,
    }
  );

  return rows[0]?.productId == null ? null : Number(rows[0].productId);
}

async function resolveMenuCategoryId(value?: number) {
  if (!value || value <= 0) return null;
  const rows = await query<{ id: number }>(
    `SELECT TOP 1 MenuCategoryId AS id FROM rest.MenuCategory WHERE MenuCategoryId = @id`,
    { id: value }
  );
  return rows[0]?.id == null ? null : Number(rows[0].id);
}

async function recalcPurchaseTotals(purchaseId: number) {
  await query(
    `
    UPDATE p
    SET
      SubtotalAmount = x.subtotal,
      TaxAmount = x.tax,
      TotalAmount = x.total,
      UpdatedAt = SYSUTCDATETIME()
    FROM rest.Purchase p
    CROSS APPLY (
      SELECT
        COALESCE(SUM(SubtotalAmount), 0) AS subtotal,
        COALESCE(SUM(SubtotalAmount * TaxRatePercent / 100.0), 0) AS tax,
        COALESCE(SUM(SubtotalAmount + (SubtotalAmount * TaxRatePercent / 100.0)), 0) AS total
      FROM rest.PurchaseLine
      WHERE PurchaseId = @purchaseId
    ) x
    WHERE p.PurchaseId = @purchaseId
    `,
    { purchaseId }
  );
}

async function adjustStock(inventoryProductId: number | null, deltaQty: number) {
  if (!inventoryProductId || !Number.isFinite(deltaQty) || deltaQty === 0) return;

  await query(
    `
    UPDATE [master].Product
    SET
      StockQty = COALESCE(StockQty, 0) + @deltaQty,
      UpdatedAt = SYSUTCDATETIME()
    WHERE ProductId = @productId
    `,
    {
      productId: inventoryProductId,
      deltaQty,
    }
  );
}

function toCode(name: string, fallback: string) {
  const normalized = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toUpperCase();
  return (normalized || fallback).slice(0, 30);
}

function extractStorageKeyFromUrl(url?: string | null) {
  const value = String(url ?? "").trim();
  const prefix = "/media-files/";
  const idx = value.indexOf(prefix);
  if (idx < 0) return null;
  return value.slice(idx + prefix.length).replace(/\\/g, "/").replace(/^\/+/, "");
}

async function syncMenuProductImageLink(
  companyId: number,
  branchId: number,
  menuProductId: number,
  imageUrl: string | null | undefined,
  userId: number | null
) {
  const storageKey = extractStorageKeyFromUrl(imageUrl);
  if (!storageKey) return;

  const mediaRows = await query<{ mediaAssetId: number }>(
    `
    SELECT TOP 1 MediaAssetId AS mediaAssetId
    FROM cfg.MediaAsset
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND StorageKey = @storageKey
      AND IsDeleted = 0
      AND IsActive = 1
    ORDER BY MediaAssetId DESC
    `,
    {
      companyId,
      branchId,
      storageKey,
    }
  );

  const mediaAssetId = Number(mediaRows[0]?.mediaAssetId ?? 0);
  if (!Number.isFinite(mediaAssetId) || mediaAssetId <= 0) return;

  await query(
    `
    UPDATE cfg.EntityImage
    SET
      IsPrimary = 0,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @userId
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND EntityType = N'REST_MENU_PRODUCT'
      AND EntityId = @entityId
      AND IsDeleted = 0
      AND IsActive = 1;

    IF EXISTS (
      SELECT 1
      FROM cfg.EntityImage
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND EntityType = N'REST_MENU_PRODUCT'
        AND EntityId = @entityId
        AND MediaAssetId = @mediaAssetId
    )
    BEGIN
      UPDATE cfg.EntityImage
      SET
        IsPrimary = 1,
        SortOrder = 0,
        IsActive = 1,
        IsDeleted = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND EntityType = N'REST_MENU_PRODUCT'
        AND EntityId = @entityId
        AND MediaAssetId = @mediaAssetId;
    END
    ELSE
    BEGIN
      INSERT INTO cfg.EntityImage (
        CompanyId,
        BranchId,
        EntityType,
        EntityId,
        MediaAssetId,
        SortOrder,
        IsPrimary,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @companyId,
        @branchId,
        N'REST_MENU_PRODUCT',
        @entityId,
        @mediaAssetId,
        0,
        1,
        @userId,
        @userId
      );
    END
    `,
    {
      companyId,
      branchId,
      entityId: menuProductId,
      mediaAssetId,
      userId,
    }
  );
}

export async function listAmbientes() {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT
      MenuEnvironmentId AS id,
      EnvironmentName AS nombre,
      ColorHex AS color,
      SortOrder AS orden
    FROM rest.MenuEnvironment
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND IsActive = 1
    ORDER BY SortOrder, EnvironmentName
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function upsertAmbiente(data: { id?: number; nombre: string; color?: string; orden?: number }) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuEnvironment
      SET
        EnvironmentName = @nombre,
        ColorHex = @color,
        SortOrder = @orden,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE MenuEnvironmentId = @id
      `,
      {
        id: data.id,
        nombre,
        color: data.color ?? null,
        orden: Number(data.orden ?? 0),
        userId,
      }
    );
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuEnvironment (
      CompanyId,
      BranchId,
      EnvironmentCode,
      EnvironmentName,
      ColorHex,
      SortOrder,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.MenuEnvironmentId AS id
    VALUES (
      @companyId,
      @branchId,
      @code,
      @nombre,
      @color,
      @orden,
      1,
      @userId,
      @userId
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      code: toCode(nombre, "AMBIENTE"),
      nombre,
      color: data.color ?? null,
      orden: Number(data.orden ?? 0),
      userId,
    }
  );

  return { ok: true, id: Number(inserted[0]?.id ?? 0) };
}

export async function listCategoriasMenu() {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT
      MenuCategoryId AS id,
      CategoryName AS nombre,
      DescriptionText AS descripcion,
      ColorHex AS color,
      SortOrder AS orden
    FROM rest.MenuCategory
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND IsActive = 1
    ORDER BY SortOrder, CategoryName
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
    }
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function upsertCategoriaMenu(data: { id?: number; nombre: string; descripcion?: string; color?: string; orden?: number }) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuCategory
      SET
        CategoryName = @nombre,
        DescriptionText = @descripcion,
        ColorHex = @color,
        SortOrder = @orden,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE MenuCategoryId = @id
      `,
      {
        id: data.id,
        nombre,
        descripcion: data.descripcion ?? null,
        color: data.color ?? null,
        orden: Number(data.orden ?? 0),
        userId,
      }
    );
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuCategory (
      CompanyId,
      BranchId,
      CategoryCode,
      CategoryName,
      DescriptionText,
      ColorHex,
      SortOrder,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.MenuCategoryId AS id
    VALUES (
      @companyId,
      @branchId,
      @code,
      @nombre,
      @descripcion,
      @color,
      @orden,
      1,
      @userId,
      @userId
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      code: toCode(nombre, "CATEGORIA"),
      nombre,
      descripcion: data.descripcion ?? null,
      color: data.color ?? null,
      orden: Number(data.orden ?? 0),
      userId,
    }
  );

  return { ok: true, id: Number(inserted[0]?.id ?? 0) };
}

export async function listProductosMenu(params: { categoriaId?: number; search?: string; soloDisponibles?: boolean }) {
  const scope = await getDefaultScope();
  const where: string[] = [
    "mp.CompanyId = @companyId",
    "mp.BranchId = @branchId",
    "mp.IsActive = 1",
  ];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    branchId: scope.branchId,
  };

  if (params.soloDisponibles ?? true) {
    where.push("mp.IsAvailable = 1");
  }
  if (params.categoriaId && params.categoriaId > 0) {
    where.push("mp.MenuCategoryId = @menuCategoryId");
    sqlParams.menuCategoryId = params.categoriaId;
  }
  if (params.search?.trim()) {
    where.push("(mp.ProductCode LIKE @search OR mp.ProductName LIKE @search)");
    sqlParams.search = `%${params.search.trim()}%`;
  }

  const rows = await query<any>(
    `
    SELECT
      mp.MenuProductId AS id,
      mp.ProductCode AS codigo,
      mp.ProductName AS nombre,
      mp.DescriptionText AS descripcion,
      mp.MenuCategoryId AS categoriaId,
      mc.CategoryName AS categoriaNombre,
      mp.PriceAmount AS precio,
      mp.EstimatedCost AS costoEstimado,
      mp.TaxRatePercent AS iva,
      mp.IsComposite AS esCompuesto,
      mp.PrepMinutes AS tiempoPreparacion,
      COALESCE(img.PublicUrl, mp.ImageUrl) AS imagen,
      mp.IsDailySuggestion AS esSugerenciaDelDia,
      mp.IsAvailable AS disponible,
      inv.ProductCode AS articuloInventarioId
    FROM rest.MenuProduct mp
    LEFT JOIN rest.MenuCategory mc ON mc.MenuCategoryId = mp.MenuCategoryId
    LEFT JOIN [master].Product inv ON inv.ProductId = mp.InventoryProductId
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = mp.CompanyId
        AND ei.BranchId = mp.BranchId
        AND ei.EntityType = N'REST_MENU_PRODUCT'
        AND ei.EntityId = mp.MenuProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE ${where.join(" AND ")}
    ORDER BY mp.ProductName
    `,
    sqlParams
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function getProductoMenu(id: number) {
  const scope = await getDefaultScope();
  const rows = await query<any>(
    `
    SELECT TOP 1
      mp.MenuProductId AS id,
      mp.ProductCode AS codigo,
      mp.ProductName AS nombre,
      mp.DescriptionText AS descripcion,
      mp.MenuCategoryId AS categoriaId,
      mp.PriceAmount AS precio,
      mp.EstimatedCost AS costoEstimado,
      mp.TaxRatePercent AS iva,
      mp.IsComposite AS esCompuesto,
      mp.PrepMinutes AS tiempoPreparacion,
      COALESCE(img.PublicUrl, mp.ImageUrl) AS imagen,
      mp.IsDailySuggestion AS esSugerenciaDelDia,
      mp.IsAvailable AS disponible,
      inv.ProductCode AS articuloInventarioId
    FROM rest.MenuProduct mp
    LEFT JOIN [master].Product inv ON inv.ProductId = mp.InventoryProductId
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = mp.CompanyId
        AND ei.BranchId = mp.BranchId
        AND ei.EntityType = N'REST_MENU_PRODUCT'
        AND ei.EntityId = mp.MenuProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE mp.MenuProductId = @id
      AND mp.IsActive = 1
    `,
    { id }
  );

  const producto = rows[0] ?? null;
  if (!producto) {
    return { producto: null, componentes: [], receta: [], executionMode: "ts_canonical" as const };
  }

  const componentRows = await query<any>(
    `
    SELECT
      c.MenuComponentId AS id,
      c.ComponentName AS nombre,
      c.IsRequired AS obligatorio,
      c.SortOrder AS orden,
      o.MenuOptionId AS opcionId,
      o.OptionName AS opcionNombre,
      o.ExtraPrice AS precioExtra,
      o.SortOrder AS opcionOrden
    FROM rest.MenuComponent c
    LEFT JOIN rest.MenuOption o
      ON o.MenuComponentId = c.MenuComponentId
     AND o.IsActive = 1
    WHERE c.MenuProductId = @id
      AND c.IsActive = 1
    ORDER BY c.SortOrder, c.MenuComponentId, o.SortOrder, o.MenuOptionId
    `,
    { id }
  );

  const componentMap: Record<number, any> = {};
  for (const row of componentRows) {
    const componentId = Number(row.id);
    if (!componentMap[componentId]) {
      componentMap[componentId] = {
        id: componentId,
        nombre: row.nombre,
        obligatorio: Boolean(row.obligatorio),
        orden: Number(row.orden ?? 0),
        opciones: [],
      };
    }
    if (row.opcionId != null) {
      componentMap[componentId].opciones.push({
        id: Number(row.opcionId),
        nombre: row.opcionNombre,
        precioExtra: Number(row.precioExtra ?? 0),
        orden: Number(row.opcionOrden ?? 0),
      });
    }
  }

  const receta = await query<any>(
    `
    SELECT
      r.MenuRecipeId AS id,
      r.MenuProductId AS productoId,
      p.ProductCode AS inventarioId,
      p.ProductName AS descripcion,
      img.PublicUrl AS imagen,
      r.Quantity AS cantidad,
      r.UnitCode AS unidad,
      r.Notes AS comentario
    FROM rest.MenuRecipe r
    INNER JOIN [master].Product p ON p.ProductId = r.IngredientProductId
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = p.CompanyId
        AND ei.BranchId = @branchId
        AND ei.EntityType = N'MASTER_PRODUCT'
        AND ei.EntityId = p.ProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE r.MenuProductId = @id
      AND r.IsActive = 1
    ORDER BY r.MenuRecipeId
    `,
    { id, branchId: scope.branchId }
  );

  return {
    producto,
    componentes: Object.values(componentMap),
    receta,
    executionMode: "ts_canonical" as const,
  };
}

export async function upsertProductoMenu(data: {
  id?: number;
  codigo: string;
  nombre: string;
  descripcion?: string;
  categoriaId?: number;
  precio?: number;
  costoEstimado?: number;
  iva?: number;
  esCompuesto?: boolean;
  tiempoPreparacion?: number;
  imagen?: string;
  esSugerenciaDelDia?: boolean;
  disponible?: boolean;
  articuloInventarioId?: string;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId();
  const code = String(data.codigo ?? "").trim().toUpperCase();
  const name = String(data.nombre ?? "").trim();
  if (!code || !name) throw new Error("codigo y nombre son obligatorios");

  const menuCategoryId = await resolveMenuCategoryId(data.categoriaId);
  const inventoryProductId = await resolveInventoryProductId(data.articuloInventarioId);

  const payload = {
    companyId: scope.companyId,
    branchId: scope.branchId,
    code,
    name,
    description: data.descripcion ?? null,
    menuCategoryId,
    price: Number(data.precio ?? 0),
    estimatedCost: Number(data.costoEstimado ?? 0),
    taxRatePercent: Number(data.iva ?? 16),
    isComposite: Boolean(data.esCompuesto ?? false),
    prepMinutes: Number(data.tiempoPreparacion ?? 0),
    imageUrl: data.imagen ?? null,
    isDailySuggestion: Boolean(data.esSugerenciaDelDia ?? false),
    isAvailable: data.disponible !== false,
    inventoryProductId,
    userId,
  };

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuProduct
      SET
        ProductCode = @code,
        ProductName = @name,
        DescriptionText = @description,
        MenuCategoryId = @menuCategoryId,
        PriceAmount = @price,
        EstimatedCost = @estimatedCost,
        TaxRatePercent = @taxRatePercent,
        IsComposite = @isComposite,
        PrepMinutes = @prepMinutes,
        ImageUrl = @imageUrl,
        IsDailySuggestion = @isDailySuggestion,
        IsAvailable = @isAvailable,
        InventoryProductId = @inventoryProductId,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @userId
      WHERE MenuProductId = @id
      `,
      {
        ...payload,
        id: data.id,
      }
    );
    await syncMenuProductImageLink(scope.companyId, scope.branchId, data.id, payload.imageUrl, userId);
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuProduct (
      CompanyId,
      BranchId,
      ProductCode,
      ProductName,
      DescriptionText,
      MenuCategoryId,
      PriceAmount,
      EstimatedCost,
      TaxRatePercent,
      IsComposite,
      PrepMinutes,
      ImageUrl,
      IsDailySuggestion,
      IsAvailable,
      InventoryProductId,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.MenuProductId AS id
    VALUES (
      @companyId,
      @branchId,
      @code,
      @name,
      @description,
      @menuCategoryId,
      @price,
      @estimatedCost,
      @taxRatePercent,
      @isComposite,
      @prepMinutes,
      @imageUrl,
      @isDailySuggestion,
      @isAvailable,
      @inventoryProductId,
      1,
      @userId,
      @userId
    )
    `,
    payload
  );

  const insertedId = Number(inserted[0]?.id ?? 0);
  if (insertedId > 0) {
    await syncMenuProductImageLink(scope.companyId, scope.branchId, insertedId, payload.imageUrl, userId);
  }
  return { ok: true, id: insertedId };
}

export async function deleteProductoMenu(id: number) {
  await query(
    `
    UPDATE rest.MenuProduct
    SET
      IsActive = 0,
      IsAvailable = 0,
      UpdatedAt = SYSUTCDATETIME()
    WHERE MenuProductId = @id
    `,
    { id }
  );
  return { ok: true };
}

export async function upsertComponente(data: { id?: number; productoId: number; nombre: string; obligatorio?: boolean; orden?: number }) {
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuComponent
      SET
        ComponentName = @nombre,
        IsRequired = @obligatorio,
        SortOrder = @orden,
        UpdatedAt = SYSUTCDATETIME()
      WHERE MenuComponentId = @id
      `,
      {
        id: data.id,
        nombre,
        obligatorio: Boolean(data.obligatorio ?? false),
        orden: Number(data.orden ?? 0),
      }
    );
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuComponent (
      MenuProductId,
      ComponentName,
      IsRequired,
      SortOrder,
      IsActive
    )
    OUTPUT INSERTED.MenuComponentId AS id
    VALUES (
      @productoId,
      @nombre,
      @obligatorio,
      @orden,
      1
    )
    `,
    {
      productoId: data.productoId,
      nombre,
      obligatorio: Boolean(data.obligatorio ?? false),
      orden: Number(data.orden ?? 0),
    }
  );

  return { ok: true, id: Number(inserted[0]?.id ?? 0) };
}

export async function upsertOpcion(data: { id?: number; componenteId: number; nombre: string; precioExtra?: number; orden?: number }) {
  const nombre = String(data.nombre ?? "").trim();
  if (!nombre) throw new Error("nombre obligatorio");

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuOption
      SET
        OptionName = @nombre,
        ExtraPrice = @precioExtra,
        SortOrder = @orden,
        UpdatedAt = SYSUTCDATETIME()
      WHERE MenuOptionId = @id
      `,
      {
        id: data.id,
        nombre,
        precioExtra: Number(data.precioExtra ?? 0),
        orden: Number(data.orden ?? 0),
      }
    );
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuOption (
      MenuComponentId,
      OptionName,
      ExtraPrice,
      SortOrder,
      IsActive
    )
    OUTPUT INSERTED.MenuOptionId AS id
    VALUES (
      @componenteId,
      @nombre,
      @precioExtra,
      @orden,
      1
    )
    `,
    {
      componenteId: data.componenteId,
      nombre,
      precioExtra: Number(data.precioExtra ?? 0),
      orden: Number(data.orden ?? 0),
    }
  );

  return { ok: true, id: Number(inserted[0]?.id ?? 0) };
}

export async function upsertRecetaItem(data: { id?: number; productoId: number; inventarioId: string; cantidad: number; unidad?: string; comentario?: string }) {
  const ingredientProductId = await resolveInventoryProductId(data.inventarioId);
  if (!ingredientProductId) {
    throw new Error("Insumo no encontrado");
  }

  if (data.id && data.id > 0) {
    await query(
      `
      UPDATE rest.MenuRecipe
      SET
        IngredientProductId = @ingredientProductId,
        Quantity = @quantity,
        UnitCode = @unitCode,
        Notes = @notes,
        IsActive = 1,
        UpdatedAt = SYSUTCDATETIME()
      WHERE MenuRecipeId = @id
      `,
      {
        id: data.id,
        ingredientProductId,
        quantity: Number(data.cantidad ?? 0),
        unitCode: data.unidad ?? null,
        notes: data.comentario ?? null,
      }
    );
    return { ok: true, id: data.id };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.MenuRecipe (
      MenuProductId,
      IngredientProductId,
      Quantity,
      UnitCode,
      Notes,
      IsActive
    )
    OUTPUT INSERTED.MenuRecipeId AS id
    VALUES (
      @productoId,
      @ingredientProductId,
      @quantity,
      @unitCode,
      @notes,
      1
    )
    `,
    {
      productoId: data.productoId,
      ingredientProductId,
      quantity: Number(data.cantidad ?? 0),
      unitCode: data.unidad ?? null,
      notes: data.comentario ?? null,
    }
  );

  return { ok: true, id: Number(inserted[0]?.id ?? 0) };
}

export async function deleteRecetaItem(id: number) {
  await query(
    `
    UPDATE rest.MenuRecipe
    SET
      IsActive = 0,
      UpdatedAt = SYSUTCDATETIME()
    WHERE MenuRecipeId = @id
    `,
    { id }
  );
  return { ok: true };
}

export async function listCompras(params: { estado?: string; from?: string; to?: string }) {
  const scope = await getDefaultScope();
  const where: string[] = ["p.CompanyId = @companyId", "p.BranchId = @branchId"];
  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    branchId: scope.branchId,
  };

  if (params.estado?.trim()) {
    where.push("p.Status = @status");
    sqlParams.status = params.estado.trim().toUpperCase();
  }
  if (params.from) {
    const fromDate = new Date(params.from);
    if (!Number.isNaN(fromDate.getTime())) {
      where.push("p.PurchaseDate >= @fromDate");
      sqlParams.fromDate = fromDate;
    }
  }
  if (params.to) {
    const toDate = new Date(params.to);
    if (!Number.isNaN(toDate.getTime())) {
      where.push("p.PurchaseDate <= @toDate");
      sqlParams.toDate = toDate;
    }
  }

  const rows = await query<any>(
    `
    SELECT
      p.PurchaseId AS id,
      p.PurchaseNumber AS numCompra,
      s.SupplierCode AS proveedorId,
      s.SupplierName AS proveedorNombre,
      p.PurchaseDate AS fechaCompra,
      p.Status AS estado,
      p.SubtotalAmount AS subtotal,
      p.TaxAmount AS iva,
      p.TotalAmount AS total,
      p.Notes AS observaciones
    FROM rest.Purchase p
    LEFT JOIN [master].Supplier s ON s.SupplierId = p.SupplierId
    WHERE ${where.join(" AND ")}
    ORDER BY p.PurchaseDate DESC, p.PurchaseId DESC
    `,
    sqlParams
  );

  return { rows, executionMode: "ts_canonical" as const };
}

export async function getCompraDetalle(compraId: number) {
  const headerRows = await query<any>(
    `
    SELECT TOP 1
      p.PurchaseId AS id,
      p.PurchaseNumber AS numCompra,
      s.SupplierCode AS proveedorId,
      s.SupplierName AS proveedorNombre,
      p.PurchaseDate AS fechaCompra,
      p.Status AS estado,
      p.SubtotalAmount AS subtotal,
      p.TaxAmount AS iva,
      p.TotalAmount AS total,
      p.Notes AS observaciones,
      u.UserCode AS codUsuario
    FROM rest.Purchase p
    LEFT JOIN [master].Supplier s ON s.SupplierId = p.SupplierId
    LEFT JOIN sec.[User] u ON u.UserId = p.CreatedByUserId
    WHERE p.PurchaseId = @compraId
    `,
    { compraId }
  );

  const detalle = await query<any>(
    `
    SELECT
      pl.PurchaseLineId AS id,
      pl.PurchaseId AS compraId,
      p.ProductCode AS inventarioId,
      pl.DescriptionText AS descripcion,
      pl.Quantity AS cantidad,
      pl.UnitPrice AS precioUnit,
      pl.SubtotalAmount AS subtotal,
      pl.TaxRatePercent AS iva
    FROM rest.PurchaseLine pl
    LEFT JOIN [master].Product p ON p.ProductId = pl.IngredientProductId
    WHERE pl.PurchaseId = @compraId
    ORDER BY pl.PurchaseLineId
    `,
    { compraId }
  );

  return {
    compra: headerRows[0] ?? null,
    detalle,
  };
}

export async function upsertCompraDetalle(data: {
  id?: number;
  compraId: number;
  inventarioId?: string;
  descripcion: string;
  cantidad: number;
  precioUnit: number;
  iva?: number;
}) {
  const ingredientProductId = await resolveInventoryProductId(data.inventarioId);
  const quantity = Number(data.cantidad ?? 0);
  const unitPrice = Number(data.precioUnit ?? 0);
  const iva = Number(data.iva ?? 16);
  const subtotal = Number((quantity * unitPrice).toFixed(2));

  if (data.id && data.id > 0) {
    const prev = await query<{ ingredientProductId: number | null; quantity: number }>(
      `
      SELECT TOP 1
        IngredientProductId AS ingredientProductId,
        Quantity AS quantity
      FROM rest.PurchaseLine
      WHERE PurchaseLineId = @id
        AND PurchaseId = @compraId
      `,
      {
        id: data.id,
        compraId: data.compraId,
      }
    );

    await query(
      `
      UPDATE rest.PurchaseLine
      SET
        IngredientProductId = @ingredientProductId,
        DescriptionText = @descripcion,
        Quantity = @quantity,
        UnitPrice = @unitPrice,
        TaxRatePercent = @iva,
        SubtotalAmount = @subtotal,
        UpdatedAt = SYSUTCDATETIME()
      WHERE PurchaseLineId = @id
        AND PurchaseId = @compraId
      `,
      {
        id: data.id,
        compraId: data.compraId,
        ingredientProductId,
        descripcion: String(data.descripcion ?? "").trim() || "SIN DESCRIPCION",
        quantity,
        unitPrice,
        iva,
        subtotal,
      }
    );

    const prevProductId = prev[0]?.ingredientProductId == null ? null : Number(prev[0].ingredientProductId);
    const prevQty = Number(prev[0]?.quantity ?? 0);

    if (prevProductId && ingredientProductId && prevProductId === ingredientProductId) {
      await adjustStock(ingredientProductId, quantity - prevQty);
    } else {
      await adjustStock(prevProductId, -prevQty);
      await adjustStock(ingredientProductId, quantity);
    }

    await recalcPurchaseTotals(data.compraId);
    return { ok: true, id: data.id, compraId: data.compraId };
  }

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.PurchaseLine (
      PurchaseId,
      IngredientProductId,
      DescriptionText,
      Quantity,
      UnitPrice,
      TaxRatePercent,
      SubtotalAmount
    )
    OUTPUT INSERTED.PurchaseLineId AS id
    VALUES (
      @compraId,
      @ingredientProductId,
      @descripcion,
      @quantity,
      @unitPrice,
      @iva,
      @subtotal
    )
    `,
    {
      compraId: data.compraId,
      ingredientProductId,
      descripcion: String(data.descripcion ?? "").trim() || "SIN DESCRIPCION",
      quantity,
      unitPrice,
      iva,
      subtotal,
    }
  );

  await adjustStock(ingredientProductId, quantity);
  await recalcPurchaseTotals(data.compraId);

  return {
    ok: true,
    id: Number(inserted[0]?.id ?? 0),
    compraId: data.compraId,
  };
}

export async function deleteCompraDetalle(compraId: number, detalleId: number) {
  const prev = await query<{ ingredientProductId: number | null; quantity: number }>(
    `
    SELECT TOP 1
      IngredientProductId AS ingredientProductId,
      Quantity AS quantity
    FROM rest.PurchaseLine
    WHERE PurchaseLineId = @detalleId
      AND PurchaseId = @compraId
    `,
    {
      compraId,
      detalleId,
    }
  );

  await query(
    `
    DELETE FROM rest.PurchaseLine
    WHERE PurchaseLineId = @detalleId
      AND PurchaseId = @compraId
    `,
    {
      compraId,
      detalleId,
    }
  );

  const prevProductId = prev[0]?.ingredientProductId == null ? null : Number(prev[0].ingredientProductId);
  const prevQty = Number(prev[0]?.quantity ?? 0);
  await adjustStock(prevProductId, -prevQty);
  await recalcPurchaseTotals(compraId);

  return { ok: true, compraId, detalleId };
}

export async function crearCompra(data: {
  proveedorId?: string;
  observaciones?: string;
  codUsuario?: string;
  detalle: Array<{ descripcion: string; cantidad: number; precioUnit: number; iva?: number; inventarioId?: string }>;
}) {
  const scope = await getDefaultScope();
  const userId = await resolveUserId(data.codUsuario);
  const supplierId = await resolveSupplierId(data.proveedorId);

  const seq = await query<{ seq: number }>(
    `
    SELECT COALESCE(MAX(PurchaseId), 0) + 1 AS seq
    FROM rest.Purchase
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
    }
  );

  const now = new Date();
  const yyyymm = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}`;
  const purchaseNumber = `RC-${yyyymm}-${String(Number(seq[0]?.seq ?? 1)).padStart(4, "0")}`;

  const inserted = await query<{ id: number }>(
    `
    INSERT INTO rest.Purchase (
      CompanyId,
      BranchId,
      PurchaseNumber,
      SupplierId,
      PurchaseDate,
      Status,
      Notes,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.PurchaseId AS id
    VALUES (
      @companyId,
      @branchId,
      @purchaseNumber,
      @supplierId,
      SYSUTCDATETIME(),
      N'PENDIENTE',
      @notes,
      @userId,
      @userId
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      purchaseNumber,
      supplierId,
      notes: data.observaciones ?? null,
      userId,
    }
  );

  const compraId = Number(inserted[0]?.id ?? 0);

  for (const item of data.detalle ?? []) {
    await upsertCompraDetalle({
      compraId,
      inventarioId: item.inventarioId,
      descripcion: item.descripcion,
      cantidad: item.cantidad,
      precioUnit: item.precioUnit,
      iva: item.iva,
    });
  }

  await recalcPurchaseTotals(compraId);
  return { ok: true, compraId };
}

export async function updateCompra(
  compraId: number,
  data: { proveedorId?: string; estado?: string; observaciones?: string }
) {
  const supplierId = await resolveSupplierId(data.proveedorId);

  await query(
    `
    UPDATE rest.Purchase
    SET
      SupplierId = COALESCE(@supplierId, SupplierId),
      Status = COALESCE(@status, Status),
      Notes = COALESCE(@notes, Notes),
      UpdatedAt = SYSUTCDATETIME()
    WHERE PurchaseId = @compraId
    `,
    {
      compraId,
      supplierId,
      status: data.estado ? String(data.estado).trim().toUpperCase() : null,
      notes: data.observaciones ?? null,
    }
  );

  return { ok: true, compraId };
}

export async function searchProveedores(search?: string, limit = 20) {
  const scope = await getDefaultScope();
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(100, Number(limit))) : 20;

  const rows = await query<any>(
    `
    SELECT TOP (${safeLimit})
      SupplierId AS id,
      SupplierCode AS codigo,
      SupplierName AS nombre,
      FiscalId AS rif,
      Phone AS telefono,
      AddressLine AS direccion
    FROM [master].Supplier
    WHERE CompanyId = @companyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
        @search IS NULL
        OR SupplierCode LIKE @search
        OR SupplierName LIKE @search
        OR FiscalId LIKE @search
      )
    ORDER BY SupplierName
    `,
    {
      companyId: scope.companyId,
      search: search?.trim() ? `%${search.trim()}%` : null,
    }
  );

  return { rows };
}

export async function searchInsumosRestaurante(search?: string, limit = 30) {
  const scope = await getDefaultScope();
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(100, Number(limit))) : 30;

  const rows = await query<any>(
    `
    SELECT TOP (${safeLimit})
      p.ProductCode AS codigo,
      p.ProductName AS descripcion,
      img.PublicUrl AS imagen,
      p.UnitCode AS unidad,
      p.StockQty AS existencia
    FROM [master].Product p
    OUTER APPLY (
      SELECT TOP 1 ma.PublicUrl
      FROM cfg.EntityImage ei
      INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
      WHERE ei.CompanyId = p.CompanyId
        AND ei.BranchId = @branchId
        AND ei.EntityType = N'MASTER_PRODUCT'
        AND ei.EntityId = p.ProductId
        AND ei.IsDeleted = 0
        AND ei.IsActive = 1
        AND ma.IsDeleted = 0
        AND ma.IsActive = 1
      ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE p.CompanyId = @companyId
      AND p.IsDeleted = 0
      AND p.IsActive = 1
      AND (
        @search IS NULL
        OR p.ProductCode LIKE @search
        OR p.ProductName LIKE @search
      )
    ORDER BY p.ProductCode
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      search: search?.trim() ? `%${search.trim()}%` : null,
    }
  );

  return { rows };
}
