import { notFound } from 'next/navigation';
import CatalogoCrudPage from '@/components/modules/inventario/CatalogoCrudPage';

type MaestroConfig = {
  title: string;
  endpoint: string;
  tableName: string;
};

const MAESTROS: Record<string, MaestroConfig> = {
  correlativo: { title: 'Correlativos', endpoint: 'maestros/correlativo', tableName: 'Correlativo' },
  empresa: { title: 'Empresa', endpoint: 'maestros/empresa', tableName: 'Empresa' },
  feriados: { title: 'Feriados', endpoint: 'maestros/feriados', tableName: 'Feriados' },
  moneda: { title: 'Moneda', endpoint: 'maestros/moneda', tableName: 'Moneda' },
  monedas: { title: 'Monedas', endpoint: 'maestros/monedas', tableName: 'Monedas' },
  'tasa-moneda': { title: 'Tasa Moneda', endpoint: 'maestros/tasa-moneda', tableName: 'Tasa_moneda' },
  reportes: { title: 'Reportes', endpoint: 'maestros/reportes', tableName: 'QueryReport' },
  'query-reporte': { title: 'Query Reporte', endpoint: 'maestros/query-reporte', tableName: 'QueryReporte' },
  reportez: { title: 'Reporte Z', endpoint: 'maestros/reportez', tableName: 'ReporteZ' },
  'linea-proveedores': { title: 'Linea Proveedores', endpoint: 'maestros/linea-proveedores', tableName: 'Linea_proveedores' },
};

export default async function MaestroPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const config = MAESTROS[slug];
  if (!config) notFound();

  return <CatalogoCrudPage endpoint={config.endpoint} title={config.title} tableName={config.tableName} />;
}
