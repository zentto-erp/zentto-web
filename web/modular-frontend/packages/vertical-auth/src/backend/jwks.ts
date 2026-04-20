import { createRemoteJWKSet } from "jose";
import type { JWSHeaderParameters, FlattenedJWSInput } from "jose";

export type JwksResolver = (
  protectedHeader?: JWSHeaderParameters,
  token?: FlattenedJWSInput,
) => Promise<CryptoKey | Uint8Array>;

/**
 * Cache JWKS remoto con rotación transparente. Ver:
 * https://github.com/panva/jose/blob/main/docs/functions/jwks_remote.createRemoteJWKSet.md
 */
export function createJwksResolver(jwksUrl: string): JwksResolver {
  return createRemoteJWKSet(new URL(jwksUrl)) as unknown as JwksResolver;
}
