"use client";

// Module definition
export const MODULE_ID = "admin";
export const MODULE_TITLE = "Administración";

// Re-export hooks
export { useFacturasList, useFacturaById, useDetalleFactura, useCreateFactura, useUpdateFactura, useDeleteFactura } from './hooks/useFacturas';
export { usePedidosPendientes, useFacturarDesdePedido } from './hooks/usePedidosEcommerce';
export type { PedidoEcommerce } from './hooks/usePedidosEcommerce';
export { useComprasList, useCompraById, useDetalleCompra, useEmitirCompraTx, useCreateCompra, useDeleteCompra } from './hooks/useCompras';
export { useAbonosList, useAbonoById, useCreateAbono, useUpdateAbono, useDeleteAbono } from './hooks/useAbonos';
export { useArticulosList, useArticuloById, useCreateArticulo, useUpdateArticulo, useDeleteArticulo, useArticuloFilterOptions } from './hooks/useArticulos';
export { usePagosList, usePagoById, useCreatePago, useUpdatePago, useDeletePago } from './hooks/usePagos';
export { useCuentasPorPagarList, useCuentaPorPagarById, useCreateCuentaPorPagar, useUpdateCuentaPorPagar, useDeleteCuentaPorPagar } from './hooks/useCuentasPorPagar';
export { useInventarioList, useInventarioById, useCreateMovimiento, useUpdateInventario, useDeleteInventario } from './hooks/useInventario';
export { useProveedoresList, useProveedorById, useCreateProveedor, useUpdateProveedor, useDeleteProveedor } from './hooks/useProveedores';
export { useCxcDocumentosPendientes, useCxcSaldo, useAplicarCobroTx } from './hooks/useCxcTx';
export { useCxpDocumentosPendientes, useCxpSaldo, useAplicarPagoTx } from './hooks/useCxpTx';
export { useClientesList } from './hooks/useClientes';

// Re-export components — abonos
export { default as AbonosTable } from './components/modules/abonos/AbonosaTable';
export { default as AbonoForm } from './components/modules/abonos/AbonoForm';

// Re-export components — articulos
export { default as ArticulosTable } from './components/modules/articulos/ArticulosTable';
export { default as ArticuloForm } from './components/modules/articulos/ArticuloForm';

// Re-export components — compras
export { default as ComprasTable } from './components/modules/compras/ComprasTable';
export { default as CompraForm } from './components/modules/compras/CompraForm';
export { default as CompraDetail } from './components/modules/compras/CompraDetail';

// Re-export components — clientes
export { default as ClientesTable } from './components/modules/clientes/ClientesTable';
export { default as ClienteForm } from './components/modules/clientes/ClienteForm';

// Re-export components — cuentas-por-pagar
export { default as CuentasPorPagarTable } from './components/modules/cuentas-por-pagar/CuentasPorPagarTable';
export { default as CuentaPorPagarForm } from './components/modules/cuentas-por-pagar/CuentaPorPagarForm';

// Re-export components — cxc / cxp
export { default as CobroTxForm } from './components/modules/cxc/CobroTxForm';
export { default as CxcMasterPage } from './components/modules/cxc/CxcMasterPage';
export { default as PagoTxForm } from './components/modules/cxp/PagoTxForm';
export { default as CxpMasterPage } from './components/modules/cxp/CxpMasterPage';

// Re-export components — facturas
export { default as FacturasTable } from './components/modules/facturas/FacturasTable';
export { default as FacturaForm } from './components/modules/facturas/FacturaForm';
export { default as FacturaDetail } from './components/modules/facturas/FacturaDetail';
export { default as PedidosEcommercePage } from './components/modules/facturas/PedidosEcommercePage';

// Re-export components — inventario
export { default as AjusteInventarioForm } from './components/modules/inventario/AjusteInventarioForm';
export { default as CatalogoCrudPage } from './components/modules/inventario/CatalogoCrudPage';
export { default as GenericEntityCrudPage } from './components/modules/inventario/CatalogoCrudPage';

// Re-export components — pagos
export { default as PagosTable } from './components/modules/pagos/PagosTable';
export { default as PagoForm } from './components/modules/pagos/PagoForm';

// Re-export components — proveedores
export { default as ProveedoresTable } from './components/modules/proveedores/ProveedoresTable';
export { default as ProveedorForm } from './components/modules/proveedores/ProveedorForm';

// Re-export components — bancos
export { default as BancosPage } from './components/modules/bancos/BancosPage';
export { default as CuentasBancariasPage } from './components/modules/bancos/CuentasBancariasPage';
export { default as ConciliacionBancariaPage } from './components/modules/bancos/ConciliacionBancariaPage';

// Re-export common components
export { FacturaTable } from './components/FacturaTable';
export { ProtectedComponent, withProtection } from './components/ProtectedComponent';
export { default as EditableDataGrid } from './components/EditableDataGrid';

// ─── IAM (Identity & Access Management) ───────────────────────
// Hooks que consumen los endpoints /admin/* del microservicio
// zentto-auth via el proxy /api/iam/* del shell.
export {
  useIamUsers,
  useIamUser,
  useCreateIamUser,
  useUpdateIamUser,
  useDeleteIamUser,
  useIamUserModules,
  useSetIamUserModules,
  useIamUserCompanies,
  useSetIamUserCompanies,
  useIamCompanies,
  useCreateIamCompany,
  useIamApps,
  useIamAppModules,
  useIamModulePermissions,
} from './hooks/useIam';
export type {
  IamUser,
  IamUserListResponse,
  IamModule,
  IamPermission,
  IamApp,
  IamCompany,
  IamCompanyAccess,
  CreateUserInput,
  UpdateUserInput,
  CreateCompanyInput,
  UserModuleRow,
} from './hooks/useIam';

// Componentes IAM
export { default as IamUsersTable } from './components/modules/iam/IamUsersTable';
export { default as IamUserFormDialog } from './components/modules/iam/IamUserFormDialog';
export { default as IamUserModulesDialog } from './components/modules/iam/IamUserModulesDialog';
export { default as IamUserCompaniesDialog } from './components/modules/iam/IamUserCompaniesDialog';
export { default as IamCompaniesTable } from './components/modules/iam/IamCompaniesTable';
export { default as IamCompanyFormDialog } from './components/modules/iam/IamCompanyFormDialog';

// Home page
export { default as AdminHome } from './pages/AdminHome';
