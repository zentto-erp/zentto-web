// lib/types/index.ts
/**
 * TIPOS COMPARTIDOS - Reutilizables para todos los módulos
 */

// ============================================================================
// TYPES BASE - Aplicable a cualquier entidad CRUD
// ============================================================================

export interface PaginatedResponse<T> {
  items: T[];
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, string>;
}

export interface CrudFilter {
  search?: string;
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// ============================================================================
// ENTIDADES PRINCIPALES (Del análisis SQL_TO_SP_MAP_INITIAL.md)
// ============================================================================

// CLIENTES
export interface Cliente {
  codigo: string;
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
  estado: 'Activo' | 'Inactivo';
  saldo: number;
  fechaCreacion: Date;
  fechaUltimaModificacion?: Date;
}

export interface CreateClienteDTO {
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
}

export interface UpdateClienteDTO extends Partial<CreateClienteDTO> {}

export interface ClienteFilter extends CrudFilter {
  estado?: 'Activo' | 'Inactivo';
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// PROVEEDORES
export interface Proveedor {
  codigo: string;
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
  estado: 'Activo' | 'Inactivo';
  saldo: number;
  fechaCreacion: Date;
  fechaUltimaModificacion?: Date;
}

export interface CreateProveedorDTO {
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
}

export interface UpdateProveedorDTO extends Partial<CreateProveedorDTO> {}

export interface ProveedorFilter extends CrudFilter {
  estado?: 'Activo' | 'Inactivo';
}

// ============================================================================

// ARTÍCULOS
// La descripción completa se compone de: Categoria + Tipo + Descripcion + Marca + Clase
// El campo Linea actúa como departamento (ej: REPUESTOS)
export interface Articulo {
  codigo: string;
  descripcionCompleta: string;  // Campo calculado: Categoria + Tipo + Descripcion + Marca + Clase
  // Campos separados para edición individual
  descripcion: string;          // DESCRIPCION en la BD
  categoria: string;            // Categoria en la BD
  tipo: string;                 // Tipo en la BD (ej: DELANTERO, KIT, BIELA)
  marca: string;                // Marca en la BD
  clase: string;                // Clase en la BD (otra subdivisión)
  linea: string;                // Linea en la BD = departamento (ej: REPUESTOS)
  // Precios
  precio?: number;
  precioVenta: number;
  precioVenta1?: number;
  precioVenta2?: number;
  precioVenta3?: number;
  precioCompra: number;
  costoPromedio?: number;
  // Inventario
  stock: number;
  minimo?: number;
  maximo?: number;
  unidad: string;
  estado: string;
  // Campos adicionales
  referencia?: string;
  alicuota?: number;
  plu?: number;
  barra?: string;
  nParte?: string;
  ubicacion?: string;
  ubicaFisica?: string;
  garantia?: string;
  fecha?: string;
  fechaVence?: string;
  servicio?: boolean;
  id?: string;
  nombre?: string;              // Alias de descripcionCompleta para compatibilidad
  fechaCreacion?: string | Date;
  [key: string]: any;
}

export interface CreateArticuloDTO {
  nombre?: string;
  descripcion?: string;
  categoria?: string;
  precio?: number;
  precioVenta?: number;
  precioCompra?: number;
  stock: number;
  unidad?: string;
  estado?: string;
  [key: string]: any;
}

export interface UpdateArticuloDTO extends Partial<CreateArticuloDTO> {}

export interface ArticuloFilter extends CrudFilter {
  linea?: string;
  categoria?: string;
  marca?: string;
  tipo?: string;
  clase?: string;
  unidad?: string;
  ubicacion?: string;
  estado?: 'activo' | 'inactivo';
  precioMin?: number;
  precioMax?: number;
  stockMin?: number;
  stockMax?: number;
  servicio?: boolean;
  wildcard?: string;
}

export interface ArticuloFilterOptions {
  lineas: string[];
  categorias: string[];
  marcas: string[];
  tipos: string[];
  clases: string[];
  unidades: string[];
  ubicaciones: string[];
  garantias: string[];
  precioMin: number;
  precioMax: number;
}

// ============================================================================

// INVENTARIO
export interface Inventario {
  movimiento?: string;
  articulo?: string;
  codigoArticulo?: string;
  nombreArticulo?: string;
  cantidad: number;
  tipo?: string;
  almacen?: string;
  fecha?: string | Date;
  referencia?: string;
  stockActual?: number;
  ultimoPrecio?: number;
  [key: string]: any;
}

export interface InventarioMovimiento extends Inventario {
  id: string;
  usuario: string;
  observaciones?: string;
}

export interface InventarioFilter extends CrudFilter {
  tipo?: 'Entrada' | 'Salida' | 'Ajuste';
  almacen?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

export interface CreateInventarioDTO {
  articulo?: string;
  codigoArticulo?: string;
  cantidad: number;
  tipo?: string;
  motivo?: string;
  almacen?: string;
  observaciones?: string;
  [key: string]: any;
}

export interface UpdateInventarioDTO extends Partial<CreateInventarioDTO> {}

// ============================================================================

// FACTURAS
export interface Factura {
  numero: string;
  cliente: string;
  codigoCliente?: string;
  nombreCliente?: string;
  fecha: string | Date;
  vencimiento?: string | Date;
  total: number;
  impuesto?: number;
  subtotal?: number;
  estado?: string;
  observaciones?: string;
  referencia?: string;
  [key: string]: any;
}

export interface FacturaDetalle {
  numero?: string;
  linea?: number;
  articulo?: string;
  codigoArticulo?: string;
  nombreArticulo?: string;
  cantidad: number;
  precio?: number;
  precioUnitario?: number;
  descuento?: number;
  total?: number;
  [key: string]: any;
}

export interface CreateFacturaDTO {
  cliente?: string;
  codigoCliente?: string;
  nombreCliente?: string;
  fecha?: string | Date;
  vencimiento?: string | Date;
  referencia?: string;
  observaciones?: string;
  subtotal?: number;
  totalDescuentos?: number;
  iva?: number;
  totalFactura?: number;
  detalles?: Array<{
    articulo?: string;
    codigoArticulo?: string;
    nombreArticulo?: string;
    cantidad: number;
    precio?: number;
    precioUnitario?: number;
    descuento?: number;
    [key: string]: any;
  }>;
  [key: string]: any;
}

export interface UpdateFacturaDTO extends Partial<CreateFacturaDTO> {}

export interface FacturaFilter extends CrudFilter {
  cliente?: string;
  estado?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// COMPRAS
export interface Compra {
  numero: string;
  proveedor: string;
  fecha: Date;
  vencimiento: Date;
  total: number;
  impuesto: number;
  estado: 'Borrador' | 'Recibida' | 'Pagada';
}

export interface CreateCompraDTO {
  proveedor: string;
  fecha: Date;
  vencimiento: Date;
  detalles: Array<{
    articulo: string;
    cantidad: number;
    precio: number;
    descuento?: number;
  }>;
}

export interface CompraFilter extends CrudFilter {
  proveedor?: string;
  estado?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// PAGOS (A Clientes)
export interface Pago {
  numero: string;
  cliente: string;
  nombre: string;
  monto: number;
  fecha: string;
  tipo: string;
  metodoPago: string;
  referencia: string;
  observaciones: string;
  [key: string]: any;
}

export interface CreatePagoDTO {
  cliente?: string;
  nombre?: string;
  monto: number;
  fecha?: string | Date;
  tipo?: string;
  metodoPago?: string;
  referencia?: string;
  observaciones?: string;
  [key: string]: any;
}

export interface UpdatePagoDTO extends Partial<CreatePagoDTO> {}

export interface PagoFilter extends CrudFilter {
  cliente?: string;
  tipo?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// ABONOS
export interface Abono {
  numero: string;
  numeroAbono: string;
  cliente: string;
  factura: string;
  numeroFactura: string;
  nombreCliente: string;
  monto: number;
  fecha: string;
  referencia: string;
  observaciones?: string;
}

export interface CreateAbonoDTO {
  cliente?: string;
  factura?: string;
  numeroFactura?: string;
  nombreCliente?: string;
  monto: number;
  fecha?: string;
  referencia?: string;
  observaciones?: string;
}

export interface UpdateAbonoDTO extends Partial<CreateAbonoDTO> {}

export interface AbonoFilter extends CrudFilter {
  cliente?: string;
  factura?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// CUENTAS POR PAGAR (P_PAGAR)
export interface CuentaPorPagar {
  id: string;
  numero: string;
  proveedor?: string;
  codigoProveedor?: string;
  nombreProveedor?: string;
  compra?: string;
  numeroReferencia?: string;
  monto: number;
  montoTotal: number;
  saldo: number;
  fecha?: string | Date;
  fechaCreacion?: string;
  vencimiento?: string | Date;
  fechaVencimiento?: string;
  estado: string;
  descripcion?: string;
  [key: string]: any;
}

export interface CreateCuentaPorPagarDTO {
  proveedor?: string;
  codigoProveedor?: string;
  nombreProveedor?: string;
  compra?: string;
  numeroReferencia?: string;
  monto?: number;
  montoTotal?: number;
  saldo?: number;
  fecha?: string | Date;
  fechaCreacion?: string | Date;
  vencimiento?: string | Date;
  fechaVencimiento?: string | Date;
  descripcion?: string;
  [key: string]: any;
}

export interface UpdateCuentaPorPagarDTO extends Partial<CreateCuentaPorPagarDTO> {}

export interface CuentaPorPagarFilter extends CrudFilter {
  proveedor?: string;
  estado?: 'Pendiente' | 'Pagada' | 'Vencida';
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// FORMULARIO - Props Genéricas
// ============================================================================

export interface FormField {
  name: string;
  label: string;
  type: 'text' | 'email' | 'tel' | 'number' | 'date' | 'select' | 'textarea' | 'checkbox';
  required?: boolean;
  placeholder?: string;
  validation?: {
    min?: number;
    max?: number;
    pattern?: RegExp;
    message?: string;
  };
  options?: Array<{ label: string; value: string | number }>;
}

export interface TableColumn<T> {
  accessor: keyof T;
  header: string;
  type?: 'text' | 'number' | 'date' | 'currency' | 'percentage' | 'status';
  width?: string;
  sortable?: boolean;
  filterable?: boolean;
  formatFn?: (value: any) => string;
}

export interface TableAction<T> {
  id: string;
  label: string;
  icon?: string;
  color?: 'primary' | 'secondary' | 'error' | 'warning' | 'success';
  onClick: (row: T) => void;
  hidden?: (row: T) => boolean;
}

// ============================================================================

// USUARIO (Auth)
export interface Usuario {
  id: string;
  nombre: string;
  email: string;
  rol: 'Admin' | 'Vendedor' | 'Comprador' | 'Configurador';
  estado: 'Activo' | 'Inactivo';
  permisos: string[];
}

export interface AuthContext {
  usuario: Usuario | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  hasPermission: (permiso: string) => boolean;
}

