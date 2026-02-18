#!/usr/bin/env node
/**
 * Script de Pruebas Simple - API DatQBox
 * Prueba endpoints básicos sin dependencias externas
 */

import http from 'http';

const API_BASE = process.env.API_URL || 'http://localhost:3001';
const TEST_USER = process.env.TEST_USER || 'SUP';
const TEST_PASS = process.env.TEST_PASS || 'SUP';

let token = null;
const results = { passed: 0, failed: 0, tests: [] };

// Función para hacer peticiones HTTP
function request(method, path, data = null, auth = true) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (auth && token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = data ? JSON.parse(data) : {};
          resolve({ status: res.statusCode, data: json });
        } catch {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Login primero
async function login() {
  console.log('🔑 Autenticando...');
  try {
    const response = await request('POST', '/v1/auth/login', {
      usuario: TEST_USER,
      clave: TEST_PASS
    }, false);
    
    if (response.status === 200 && response.data.token) {
      token = response.data.token;
      console.log('✅ Autenticación exitosa\n');
      return true;
    } else {
      console.log('❌ Error de autenticación:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error de conexión:', error.message);
    console.log('   Asegúrate de que la API esté corriendo en', API_BASE);
    return false;
  }
}

// Función de test
async function test(name, method, path, data = null) {
  try {
    const response = await request(method, path, data);
    const success = response.status >= 200 && response.status < 300;
    
    results.tests.push({
      name,
      method,
      path,
      status: response.status,
      success
    });
    
    if (success) {
      results.passed++;
      console.log(`✅ ${name} (${response.status})`);
    } else {
      results.failed++;
      console.log(`⚠️  ${name} (${response.status}) - No OK pero respondió`);
    }
    
    return response;
  } catch (error) {
    results.failed++;
    results.tests.push({
      name,
      method,
      path,
      error: error.message,
      success: false
    });
    console.log(`❌ ${name} - Error: ${error.message}`);
    return null;
  }
}

// Pruebas principales
async function runTests() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║     PRUEBAS DE API - DATQBOX ADMINISTRATIVO           ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log(`API: ${API_BASE}\n`);

  if (!(await login())) {
    console.log('\n❌ No se pudieron ejecutar las pruebas');
    process.exit(1);
  }

  // ============= DOCUMENTOS UNIFICADOS =============
  console.log('\n📄 DOCUMENTOS VENTA (UNIFICADOS)');
  console.log('────────────────────────────────────');
  await test('Listar documentos venta', 'GET', '/v1/documentos-venta');
  await test('Filtrar facturas', 'GET', '/v1/documentos-venta?tipoOperacion=FACT');
  
  // ============= DOCUMENTOS COMPRA =============
  console.log('\n📦 DOCUMENTOS COMPRA (UNIFICADOS)');
  console.log('────────────────────────────────────');
  await test('Listar documentos compra', 'GET', '/v1/documentos-compra');
  await test('Filtrar órdenes', 'GET', '/v1/documentos-compra?tipoOperacion=ORDEN');
  
  // ============= BANCOS Y CONCILIACIÓN =============
  console.log('\n🏦 BANCOS Y CONCILIACIÓN');
  console.log('────────────────────────────────────');
  await test('Listar bancos', 'GET', '/v1/bancos');
  await test('Listar cuentas bancarias', 'GET', '/v1/bancos/cuentas-bank');
  await test('Listar movimientos cuenta', 'GET', '/v1/bancos/movimientos-cuenta');
  await test('Listar conciliaciones', 'GET', '/v1/bancos/conciliaciones');
  
  // ============= NÓMINA =============
  console.log('\n💼 NÓMINA (CONCEPTO LEGAL)');
  console.log('────────────────────────────────────');
  await test('Listar conceptos legales', 'GET', '/v1/nomina/conceptos-legales');
  await test('Listar convenciones', 'GET', '/v1/nomina/convenciones');
  
  // ============= CxC / CxP =============
  console.log('\n💰 CUENTAS POR COBRAR/PAGAR');
  console.log('────────────────────────────────────');
  await test('Documentos pendientes CxC', 'GET', '/v1/cxc/documentos-pendientes?codCliente=C0001');
  await test('Documentos pendientes CxP', 'GET', '/v1/cxp/documentos-pendientes?codProveedor=P0001');
  
  // ============= CONTABILIDAD =============
  console.log('\n📊 CONTABILIDAD');
  console.log('────────────────────────────────────');
  await test('Plan de cuentas', 'GET', '/v1/contabilidad/plan-cuentas');
  await test('Listar asientos', 'GET', '/v1/contabilidad/asientos');
  await test('Balance general', 'GET', '/v1/contabilidad/balance-general?fechaCorte=2024-02-15');
  await test('Estado de resultados', 'GET', '/v1/contabilidad/estado-resultados?fechaDesde=2024-01-01&fechaHasta=2024-02-29');
  
  // ============= CATÁLOGOS =============
  console.log('\n📚 CATÁLOGOS');
  console.log('────────────────────────────────────');
  const catalogos = [
    'clientes', 'proveedores', 'inventario', 'categorias',
    'marcas', 'unidades', 'lineas', 'clases', 'grupos',
    'tipos', 'almacen', 'vendedores', 'empleados',
    'centro-costo', 'cuentas', 'retenciones'
  ];
  
  for (const cat of catalogos) {
    await test(`Listar ${cat}`, 'GET', `/v1/${cat}`);
  }
  
  // ============= CRUD Y METADATOS =============
  console.log('\n🔧 CRUD Y METADATOS');
  console.log('────────────────────────────────────');
  await test('Metadatos tabla Clientes', 'GET', '/v1/meta/Clientes');
  await test('Health check', 'GET', '/health', null, false);
  
  // ============= RESUMEN =============
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║                    RESUMEN DE PRUEBAS                  ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  const total = results.passed + results.failed;
  const percentage = total > 0 ? ((results.passed / total) * 100).toFixed(2) : 0;
  
  console.log(`\n✅ Tests Pasados:    ${results.passed}`);
  console.log(`❌ Tests Fallidos:   ${results.failed}`);
  console.log(`📊 Total:            ${total}`);
  console.log(`🎯 Éxito:            ${percentage}%`);
  
  // Detalle de fallos
  const fallos = results.tests.filter(t => !t.success);
  if (fallos.length > 0) {
    console.log('\n⚠️  DETALLE DE FALLOS:');
    console.log('────────────────────────────────────');
    fallos.forEach(f => {
      console.log(`❌ ${f.name}`);
      console.log(`   ${f.method} ${f.path}`);
      if (f.status) console.log(`   Status: ${f.status}`);
      if (f.error) console.log(`   Error: ${f.error}`);
      console.log('');
    });
  }
  
  console.log('\n✨ Pruebas completadas\n');
  process.exit(results.failed > 0 ? 1 : 0);
}

// Ejecutar
runTests().catch(err => {
  console.error('Error fatal:', err);
  process.exit(1);
});
