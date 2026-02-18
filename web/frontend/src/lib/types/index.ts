// lib/types/index.ts
/**
 * TIPOS COMPARTIDOS - Reutilizables para todos los módulos
 */

// ============================================================================
// TYPES BASE - Aplicable a cualquier entidad CRUD
// ============================================================================

export interface PaginatedResponse<T> {
  items: T[];
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
export interface Articulo {
  codigo: string;
  referencia: string;
  descripcion: string;
  descripcionCompleta: string;
  categoria: string;
  tipo: string;
  marca: string;
  clase: string;
  linea: string;
  unidad: string;
  precioVenta: number;
  precioCompra: number;
  porcentaje: number;
  precioVenta1: number;
  precioVenta2: number;
  precioVenta3: number;
  alicuota: number;
  stock: number;
  minimo: number;
  maximo: number;
  plu: number;
  barra: string;
  nParte: string;
  ubicacion: string;
  ubicaFisica: string;
  garantia: string;
  fecha: string | null;         // Fecha última compra
  fechaVence: string | null;    // Fecha vencimiento
  servicio: boolean;
  costoPromedio: number;
  estado: 'Activo' | 'Inactivo';
}

export interface CreateArticuloDTO {
  CODIGO?: string;
  DESCRIPCION: string;
  Categoria?: string;
  Tipo?: string;
  Marca?: string;
  Clase?: string;
  Linea?: string;
  Unidad?: string;
  PRECIO_VENTA?: number;
  PRECIO_COMPRA?: number;
  PORCENTAJE?: number;
  Referencia?: string;
  Barra?: string;
}

export interface UpdateArticuloDTO extends Partial<CreateArticuloDTO> {}

export interface ArticuloFilter extends CrudFilter {
  categoria?: string;
  marca?: string;
  linea?: string;
  tipo?: string;
  clase?: string;
  unidad?: string;
  ubicacion?: string;
  estado?: 'activo' | 'inactivo' | 'todos';
  precioMin?: number;
  precioMax?: number;
  stockMin?: number;
  stockMax?: number;
  servicio?: boolean;
  wildcard?: string;
}

/** Opciones disponibles para filtros de artículos (precargadas del cache) */
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
  movimiento: string;
  articulo: string;
  cantidad: number;
  tipo: 'Entrada' | 'Salida' | 'Ajuste';
  almacen: string;
  fecha: Date;
  referencia?: string;
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

// ============================================================================

// FACTURAS
export interface Factura {
  numero: string;
  cliente: string;
  fecha: Date;
  vencimiento: Date;
  total: number;
  impuesto: number;
  subtotal: number;
  estado: 'Borrador' | 'Emitida' | 'Pagada' | 'Cancelada';
  observaciones?: string;
}

export interface FacturaDetalle {
  numero: string;
  linea: number;
  articulo: string;
  cantidad: number;
  precio: number;
  descuento: number;
  total: number;
}

export interface CreateFacturaDTO {
  cliente: string;
  fecha: Date;
  vencimiento: Date;
  detalles: Array<{
    articulo: string;
    cantidad: number;
    precio: number;
    descuento?: number;
  }>;
}

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
  monto: number;
  fecha: Date;
  tipo: 'Efectivo' | 'Cheque' | 'Transferencia' | 'Tarjeta';
  referencia?: string;
}

export interface CreatePagoDTO {
  cliente: string;
  monto: number;
  fecha: Date;
  tipo: 'Efectivo' | 'Cheque' | 'Transferencia' | 'Tarjeta';
  referencia?: string;
}

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
  cliente: string;
  factura: string;
  monto: number;
  fecha: Date;
  referencia?: string;
}

export interface CreateAbonoDTO {
  cliente: string;
  factura: string;
  monto: number;
  referencia?: string;
}

export interface AbonoFilter extends CrudFilter {
  cliente?: string;
  factura?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
}

// ============================================================================

// CUENTAS POR PAGAR (P_PAGAR)
export interface CuentaPorPagar {
  numero: string;
  proveedor: string;
  compra: string;
  monto: number;
  saldo: number;
  fecha: Date;
  vencimiento: Date;
  estado: 'Pendiente' | 'Pagada' | 'Vencida';
}

export interface CreateCuentaPorPagarDTO {
  proveedor: string;
  compra: string;
  monto: number;
  fecha: Date;
  vencimiento: Date;
}

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

