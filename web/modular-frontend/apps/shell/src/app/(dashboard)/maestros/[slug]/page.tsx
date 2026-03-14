import { notFound } from 'next/navigation';
import CatalogoCrudPage from '@/components/modules/inventario/CatalogoCrudPage';

type MaestroConfig = {
  title: string;
  endpoint: string;
  tableName: string;
  schema?: string;
};

const MAESTROS: Record<string, MaestroConfig> = {
  correlativo: { title: 'Correlativos', endpoint: 'maestros/correlativo', tableName: 'DocumentSequence', schema: 'cfg' },
  empresa: { title: 'Empresa', endpoint: 'maestros/empresa', tableName: 'CompanyProfile', schema: 'cfg' },
  feriados: { title: 'Feriados', endpoint: 'maestros/feriados', tableName: 'Holiday', schema: 'cfg' },
  moneda: { title: 'Moneda', endpoint: 'maestros/moneda', tableName: 'Currency', schema: 'cfg' },
  monedas: { title: 'Monedas', endpoint: 'maestros/monedas', tableName: 'Currency', schema: 'cfg' },
  'tasa-moneda': { title: 'Tasa Moneda', endpoint: 'maestros/tasa-moneda', tableName: 'ExchangeRateDaily', schema: 'cfg' },
  reportes: { title: 'Reportes', endpoint: 'maestros/reportes', tableName: 'ReportTemplate', schema: 'cfg' },
  'query-reporte': { title: 'Query Reporte', endpoint: 'maestros/query-reporte', tableName: 'ReportTemplate', schema: 'cfg' },
  reportez: { title: 'Reporte Z', endpoint: 'maestros/reportez', tableName: 'ReportTemplate', schema: 'cfg' },
  'linea-proveedores': { title: 'Linea Proveedores', endpoint: 'maestros/linea-proveedores', tableName: 'SupplierLine', schema: 'master' },
};

export default async function MaestroPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const config = MAESTROS[slug];
  if (!config) notFound();

  return <CatalogoCrudPage endpoint={config.endpoint} title={config.title} tableName={config.tableName} schema={config.schema} />;
}
