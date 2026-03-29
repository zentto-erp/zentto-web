export function getSharedAssetUrl(assetPath: string): string {
  const normalizedPath = assetPath.startsWith('/') ? assetPath : `/${assetPath}`;

  if (typeof window === 'undefined') {
    return normalizedPath;
  }

  const shellUrl = process.env.NEXT_PUBLIC_SHELL_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : window.location.origin);
  return `${shellUrl}${normalizedPath}`;
}