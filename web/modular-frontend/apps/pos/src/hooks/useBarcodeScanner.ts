'use client';

import { useEffect, useRef } from 'react';

/**
 * Hook para detectar lecturas de escáneres de código de barras.
 * Escucha globalmente los eventos de teclado y detecta pulsaciones
 * extremadamente rápidas seguidas de un Enter.
 */
export function useBarcodeScanner(onScan: (barcode: string) => void) {
    const buffer = useRef('');
    const lastKeyTime = useRef<number>(0);
    const onScanRef = useRef(onScan);

    useEffect(() => {
        onScanRef.current = onScan;
    }, [onScan]);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            const currentTime = performance.now();
            const timeDiff = currentTime - lastKeyTime.current;

            // Si pasa más de 100ms entre teclas, es escritura humana normal, limpiamos buffer
            if (timeDiff > 100 && buffer.current.length > 0) {
                buffer.current = '';
            }

            if (e.key === 'Enter') {
                // Si tenemos un texto lo suficientemente largo capturado a alta velocidad, es un escáner
                if (buffer.current.length >= 3) {
                    onScanRef.current(buffer.current);
                    // Opcionalmente podríamos hacer e.preventDefault() aquí
                }
                buffer.current = '';
            } else if (e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
                // Capturamos solo caracteres imprimibles
                buffer.current += e.key;
            }

            lastKeyTime.current = currentTime;
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, []);
}
