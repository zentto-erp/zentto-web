// Zoho API Integration Configuration
// All Zoho services use the same OAuth2 app credentials

export const ZOHO_CONFIG = {
  clientId: process.env.ZOHO_CLIENT_ID || '1000.GUAYFGJKP74OEV5YVFZQCKB9EQF99Q',
  clientSecret: process.env.ZOHO_CLIENT_SECRET || '1399ef936e26acd50c8b3338387be781bc0d33a047',
  redirectUri: process.env.ZOHO_REDIRECT_URI || 'https://api.zentto.net/v1/integrations/zoho/callback',

  // OAuth2 endpoints (US data center)
  authUrl: 'https://accounts.zoho.com/oauth/v2/auth',
  tokenUrl: 'https://accounts.zoho.com/oauth/v2/token',
  revokeUrl: 'https://accounts.zoho.com/oauth/v2/token/revoke',
  userInfoUrl: 'https://accounts.zoho.com/oauth/v2/userinfo',

  // API base URLs
  apis: {
    mail: 'https://mail.zoho.com/api',
    sign: 'https://sign.zoho.com/api/v1',
    people: 'https://people.zoho.com/people/api',
    desk: 'https://desk.zoho.com/api/v1',
    analytics: 'https://analyticsapi.zoho.com/api',
    workdrive: 'https://workdrive.zoho.com/api/v1',
    cliq: 'https://cliq.zoho.com/api/v2',
  },

  // Scopes per service
  scopes: {
    mail: 'ZohoMail.messages.ALL,ZohoMail.accounts.READ',
    sign: 'ZohoSign.documents.ALL,ZohoSign.templates.ALL',
    people: 'ZohoPeople.employee.ALL,ZohoPeople.attendance.ALL,ZohoPeople.leave.ALL',
    desk: 'Desk.tickets.ALL,Desk.contacts.ALL,Desk.settings.READ',
    analytics: 'ZohoAnalytics.data.ALL,ZohoAnalytics.embed.ALL',
    workdrive: 'WorkDrive.files.ALL,WorkDrive.workspace.ALL',
    cliq: 'ZohoCliq.Webhooks.CREATE,ZohoCliq.Messages.ALL',
  },

  getAllScopes(): string {
    return Object.values(this.scopes).join(',');
  },
};
