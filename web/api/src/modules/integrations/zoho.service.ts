import { ZOHO_CONFIG } from './zoho.config';

interface ZohoTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

// Token storage (in production, store in DB per company)
const tokenCache: Map<number, { tokens: ZohoTokens; expiresAt: number }> = new Map();

export async function getAuthorizationUrl(companyId: number, services: string[] = []): Promise<string> {
  const scopes = services.length > 0
    ? services.map(s => ZOHO_CONFIG.scopes[s as keyof typeof ZOHO_CONFIG.scopes]).filter(Boolean).join(',')
    : ZOHO_CONFIG.getAllScopes();

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: ZOHO_CONFIG.clientId,
    scope: scopes,
    redirect_uri: ZOHO_CONFIG.redirectUri,
    access_type: 'offline',
    prompt: 'consent',
    state: String(companyId),
  });

  return `${ZOHO_CONFIG.authUrl}?${params}`;
}

export async function exchangeCode(code: string): Promise<ZohoTokens> {
  const res = await fetch(ZOHO_CONFIG.tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: ZOHO_CONFIG.clientId,
      client_secret: ZOHO_CONFIG.clientSecret,
      redirect_uri: ZOHO_CONFIG.redirectUri,
      code,
    }),
  });
  return res.json();
}

export async function refreshAccessToken(refreshToken: string): Promise<ZohoTokens> {
  const res = await fetch(ZOHO_CONFIG.tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: ZOHO_CONFIG.clientId,
      client_secret: ZOHO_CONFIG.clientSecret,
      refresh_token: refreshToken,
    }),
  });
  return res.json();
}

export function cacheTokens(companyId: number, tokens: ZohoTokens): void {
  tokenCache.set(companyId, {
    tokens,
    expiresAt: Date.now() + (tokens.expires_in - 60) * 1000,
  });
}

export async function getValidToken(companyId: number): Promise<string | null> {
  const cached = tokenCache.get(companyId);
  if (!cached) return null;

  if (Date.now() >= cached.expiresAt && cached.tokens.refresh_token) {
    const refreshed = await refreshAccessToken(cached.tokens.refresh_token);
    cacheTokens(companyId, { ...refreshed, refresh_token: cached.tokens.refresh_token });
    return refreshed.access_token;
  }

  return cached.tokens.access_token;
}

// Generic Zoho API call
export async function zohoApi(
  companyId: number,
  baseUrl: string,
  path: string,
  options: { method?: string; body?: any; headers?: Record<string, string> } = {}
): Promise<any> {
  const token = await getValidToken(companyId);
  if (!token) throw new Error('Zoho not connected. Please authorize first.');

  const res = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      Authorization: `Zoho-oauthtoken ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Zoho API error ${res.status}: ${err}`);
  }

  return res.json();
}

// --- SERVICE-SPECIFIC HELPERS ---

// Zoho Mail — Send email from @zentto.net
export async function sendMailViaZoho(
  companyId: number,
  accountId: string,
  to: string,
  subject: string,
  html: string,
  from?: string
): Promise<any> {
  return zohoApi(companyId, ZOHO_CONFIG.apis.mail, `/accounts/${accountId}/messages`, {
    method: 'POST',
    body: {
      fromAddress: from || 'info@zentto.net',
      toAddress: to,
      subject,
      content: html,
      mailFormat: 'html',
    },
  });
}

// Zoho Sign — Send document for signature
export async function sendForSignature(
  companyId: number,
  documentName: string,
  recipientEmail: string,
  recipientName: string,
  fileBase64: string
): Promise<any> {
  return zohoApi(companyId, ZOHO_CONFIG.apis.sign, '/requests', {
    method: 'POST',
    body: {
      requests: {
        request_name: documentName,
        actions: [{
          action_type: 'SIGN',
          recipient_email: recipientEmail,
          recipient_name: recipientName,
          signing_order: 1,
        }],
        notes: 'Documento enviado desde Zentto ERP',
      },
    },
  });
}

// Zoho Desk — Create support ticket
export async function createSupportTicket(
  companyId: number,
  subject: string,
  description: string,
  contactEmail: string,
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT' = 'MEDIUM'
): Promise<any> {
  return zohoApi(companyId, ZOHO_CONFIG.apis.desk, '/tickets', {
    method: 'POST',
    body: {
      subject,
      description,
      priority,
      contact: { email: contactEmail },
      channel: 'Web',
    },
  });
}

// Zoho WorkDrive — Upload file
export async function uploadToWorkDrive(
  companyId: number,
  folderId: string,
  fileName: string,
  fileContent: Buffer
): Promise<any> {
  const token = await getValidToken(companyId);
  if (!token) throw new Error('Zoho not connected');

  const formData = new FormData();
  formData.append('content', new Blob([fileContent]), fileName);
  formData.append('parent_id', folderId);
  formData.append('override-name-exist', 'true');

  const res = await fetch(`${ZOHO_CONFIG.apis.workdrive}/upload`, {
    method: 'POST',
    headers: { Authorization: `Zoho-oauthtoken ${token}` },
    body: formData,
  });

  return res.json();
}

// Zoho Cliq — Send notification to channel
export async function sendCliqMessage(
  companyId: number,
  channelName: string,
  message: string
): Promise<any> {
  return zohoApi(companyId, ZOHO_CONFIG.apis.cliq, `/channelsbyname/${channelName}/message`, {
    method: 'POST',
    body: { text: message },
  });
}

// Zoho Analytics — Import data
export async function importToAnalytics(
  companyId: number,
  workspaceId: string,
  viewId: string,
  data: Record<string, any>[]
): Promise<any> {
  return zohoApi(companyId, ZOHO_CONFIG.apis.analytics, `/${workspaceId}/${viewId}`, {
    method: 'POST',
    body: {
      ZOHO_ACTION: 'IMPORT',
      ZOHO_IMPORT_TYPE: 'APPEND',
      ZOHO_IMPORT_DATA: JSON.stringify(data),
      ZOHO_IMPORT_FILETYPE: 'JSON',
    },
  });
}
