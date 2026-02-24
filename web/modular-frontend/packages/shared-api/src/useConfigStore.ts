import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface FiscalPeriodConfig {
    startMonth: number; // 1 = Enero
    closeYearBehavior: 'soft' | 'hard';
}

export interface NominaConfig {
    periodoPago: 'semanal' | 'quincenal' | 'mensual';
    aplicaISR: boolean; // Impuesto Sobre la Renta (ISLR en VE, ISR en MX)
    aplicaSeguroSocial: boolean;
    aplicaParoForzoso: boolean;
}

export interface BancosConfig {
    precisionBancaria: number; // Decimales
    formatoExportacion: 'csv' | 'mt940' | 'qbo';
    defaultGateway?: string;
}

export interface ContabilidadConfig {
    formatoPlanCuentas: string; // ej. "X.X.XX.XX"
    nombreImpuestoPrincipal: string; // IVA, IGV, VAT, ITBIS
    nombreIdentificacion: string; // RIF, NIT, RFC, CUIT
    periodoFiscal: FiscalPeriodConfig;
}

export interface InventarioConfig {
    metodoCosteo: 'FIFO' | 'LIFO' | 'PROMEDIO';
    permitirStockNegativo: boolean;
    manejarLotesYVencimiento: boolean;
}

export interface GlobalParamsConfig {
    pais: string; // VE, CO, MX, US, ES...
    nombreEmpresa: string;
    contabilidad: ContabilidadConfig;
    nomina: NominaConfig;
    bancos: BancosConfig;
    inventario: InventarioConfig;
}

interface GlobalConfigState {
    config: GlobalParamsConfig;
    setConfig: (updates: Partial<GlobalParamsConfig>) => void;
    setContabilidadConfig: (updates: Partial<ContabilidadConfig>) => void;
    setNominaConfig: (updates: Partial<NominaConfig>) => void;
    setBancosConfig: (updates: Partial<BancosConfig>) => void;
    setInventarioConfig: (updates: Partial<InventarioConfig>) => void;
}

const defaultConfig: GlobalParamsConfig = {
    pais: 'VE',
    nombreEmpresa: 'Mi Empresa, C.A.',
    contabilidad: {
        formatoPlanCuentas: 'X.X.XX.XX.XX',
        nombreImpuestoPrincipal: 'IVA',
        nombreIdentificacion: 'RIF',
        periodoFiscal: {
            startMonth: 1,
            closeYearBehavior: 'soft'
        }
    },
    nomina: {
        periodoPago: 'quincenal',
        aplicaISR: true,
        aplicaSeguroSocial: true,
        aplicaParoForzoso: true
    },
    bancos: {
        precisionBancaria: 2,
        formatoExportacion: 'csv'
    },
    inventario: {
        metodoCosteo: 'PROMEDIO',
        permitirStockNegativo: false,
        manejarLotesYVencimiento: true
    }
};

export const useConfigStore = create<GlobalConfigState>()(
    persist(
        (set) => ({
            config: defaultConfig,
            setConfig: (updates) =>
                set((state) => ({ config: { ...state.config, ...updates } })),
            setContabilidadConfig: (updates) =>
                set((state) => ({ config: { ...state.config, contabilidad: { ...state.config.contabilidad, ...updates } } })),
            setNominaConfig: (updates) =>
                set((state) => ({ config: { ...state.config, nomina: { ...state.config.nomina, ...updates } } })),
            setBancosConfig: (updates) =>
                set((state) => ({ config: { ...state.config, bancos: { ...state.config.bancos, ...updates } } })),
            setInventarioConfig: (updates) =>
                set((state) => ({ config: { ...state.config, inventario: { ...state.config.inventario, ...updates } } })),
        }),
        {
            name: 'datqbox-global-config',
        }
    )
);
