'use client';

import { apiGet, apiPost } from './api';

export interface SupervisorBiometricCredential {
    biometricCredentialId: number;
    supervisorUserCode: string;
    credentialId: string;
    credentialLabel?: string | null;
    deviceInfo?: string | null;
    isActive: boolean;
    lastValidatedAtUtc?: string | null;
}

function toBase64Url(bytes: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < bytes.length; i += 1) binary += String.fromCharCode(bytes[i]);
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function fromBase64Url(value: string): ArrayBuffer {
    const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
    const binary = atob(padded);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
    return Uint8Array.from(bytes).buffer;
}

function randomChallenge(size = 32): ArrayBuffer {
    const bytes = new Uint8Array(size);
    globalThis.crypto.getRandomValues(bytes);
    return Uint8Array.from(bytes).buffer;
}

export function isWebAuthnSupported(): boolean {
    return typeof window !== 'undefined' && !!window.PublicKeyCredential && !!navigator.credentials;
}

function assertWebAuthnSupported() {
    if (!isWebAuthnSupported()) {
        throw new Error('Este navegador/equipo no soporta autenticacion biometrica WebAuthn.');
    }
}

function normalizeSupervisorUser(value: string): string {
    return String(value ?? '').trim().toUpperCase();
}

export async function listSupervisorBiometricCredentials(supervisorUser?: string): Promise<SupervisorBiometricCredential[]> {
    const normalizedUser = normalizeSupervisorUser(supervisorUser ?? '');
    const query = normalizedUser ? { supervisorUser: normalizedUser } : undefined;
    const data = await apiGet('/v1/supervision/biometric/credentials', query);
    return Array.isArray(data?.rows) ? data.rows as SupervisorBiometricCredential[] : [];
}

export async function enrollSupervisorBiometricCredential(input: {
    supervisorUser: string;
    supervisorPassword: string;
    credentialLabel?: string;
}) {
    assertWebAuthnSupported();
    const supervisorUser = normalizeSupervisorUser(input.supervisorUser);
    const supervisorPassword = String(input.supervisorPassword ?? '');
    if (!supervisorUser || !supervisorPassword) {
        throw new Error('Debe indicar usuario y clave de supervisor para registrar huella.');
    }

    const credential = await navigator.credentials.create({
        publicKey: {
            challenge: randomChallenge(32),
            rp: {
                id: window.location.hostname,
                name: 'DatqBox',
            },
            user: {
                id: new TextEncoder().encode(`SUP:${supervisorUser}`),
                name: `${supervisorUser}@datqbox.local`,
                displayName: `Supervisor ${supervisorUser}`,
            },
            pubKeyCredParams: [
                { type: 'public-key', alg: -7 },
                { type: 'public-key', alg: -257 },
            ],
            timeout: 60000,
            attestation: 'none',
            authenticatorSelection: {
                userVerification: 'required',
                residentKey: 'preferred',
            },
        },
    });

    if (!credential || !(credential instanceof PublicKeyCredential)) {
        throw new Error('No se pudo registrar la credencial biometrica.');
    }

    const credentialId = toBase64Url(new Uint8Array(credential.rawId));
    const deviceInfo = `${credential.authenticatorAttachment ?? 'platform'} | ${navigator.userAgent}`.slice(0, 300);

    const saved = await apiPost('/v1/supervision/biometric/enroll', {
        supervisorUser,
        supervisorPassword,
        credentialId,
        credentialLabel: (input.credentialLabel ?? '').trim() || `Equipo ${window.location.hostname}`,
        deviceInfo,
    });

    if (!saved?.ok) {
        throw new Error(String(saved?.message ?? saved?.error ?? 'No se pudo guardar la credencial biometrica.'));
    }

    return {
        credentialId,
        biometricCredentialId: Number(saved.biometricCredentialId),
        supervisorUser: String(saved.supervisorUser ?? supervisorUser),
        supervisorName: String(saved.supervisorName ?? supervisorUser),
    };
}

export async function authenticateSupervisorBiometricCredential(supervisorUser?: string) {
    assertWebAuthnSupported();
    const normalizedUser = normalizeSupervisorUser(supervisorUser ?? '');
    const LAST_CREDENTIAL_KEY = 'datqbox:last-biometric-credential-id';

    const credentials = await listSupervisorBiometricCredentials(normalizedUser || undefined);
    if (credentials.length === 0) {
        throw new Error(normalizedUser
            ? 'El supervisor no tiene huella registrada en este sistema.'
            : 'No hay huellas de supervisor registradas en este sistema.');
    }

    const toAllowCredential = (row: SupervisorBiometricCredential) => {
        try {
            return {
                id: fromBase64Url(String(row.credentialId)),
                type: 'public-key' as const,
                transports: ['internal'] as AuthenticatorTransport[],
            };
        } catch {
            return null;
        }
    };

    const allowCredentialsAll = credentials
        .map(toAllowCredential)
        .filter((row): row is { id: ArrayBuffer; type: 'public-key'; transports: AuthenticatorTransport[] } => row !== null);

    if (allowCredentialsAll.length === 0) {
        throw new Error('No hay credenciales biometricas validas para este supervisor.');
    }

    const getAssertion = async (allowCredentials: Array<{ id: ArrayBuffer; type: 'public-key'; transports: AuthenticatorTransport[] }>) => {
        return navigator.credentials.get({
            publicKey: {
                challenge: randomChallenge(32),
                allowCredentials,
                userVerification: 'required',
                timeout: 60000,
                rpId: window.location.hostname,
            },
        });
    };

    let assertion: Credential | null = null;
    const lastCredentialId = typeof window !== 'undefined' ? window.localStorage.getItem(LAST_CREDENTIAL_KEY) : null;
    if (lastCredentialId) {
        const preferred = credentials.find((row) => String(row.credentialId) === String(lastCredentialId));
        const preferredAllow = preferred ? toAllowCredential(preferred) : null;
        if (preferredAllow) {
            try {
                assertion = await getAssertion([preferredAllow]);
            } catch {
                assertion = null;
            }
        }
    }

    if (!assertion) {
        assertion = await getAssertion(allowCredentialsAll);
    }

    if (!assertion || !(assertion instanceof PublicKeyCredential)) {
        throw new Error('No se pudo validar la huella del supervisor.');
    }

    const credentialId = toBase64Url(new Uint8Array(assertion.rawId));
    const matchedCredential = credentials.find((row) => String(row.credentialId) === credentialId);
    if (!matchedCredential?.supervisorUserCode) {
        throw new Error('La huella validada no corresponde a un supervisor registrado.');
    }

    if (typeof window !== 'undefined') {
        window.localStorage.setItem(LAST_CREDENTIAL_KEY, credentialId);
    }

    return {
        credentialId,
        supervisorUser: String(matchedCredential.supervisorUserCode).trim().toUpperCase(),
    };
}
