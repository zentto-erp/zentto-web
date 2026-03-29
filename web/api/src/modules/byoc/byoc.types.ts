export type CloudProvider = "hetzner" | "digitalocean" | "aws" | "gcp" | "azure" | "ssh";

export interface ByocDeployConfig {
  provider: CloudProvider;
  region?: string;
  serverSize?: string;
  domain: string;          // dominio propio del cliente: erp.miempresa.com
  sshPublicKey?: string;   // para agregar al servidor cloud
}

export interface ByocCredentials {
  // Hetzner
  hetznerApiToken?: string;
  // DigitalOcean
  doApiToken?: string;
  // AWS
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  awsRegion?: string;
  // GCP
  gcpServiceAccountJson?: string;
  // SSH directo (VPS propio)
  sshHost?: string;
  sshPort?: number;
  sshUsername?: string;
  sshPrivateKey?: string;
}

export interface ByocDeployJob {
  jobId: number;
  companyId: number;
  provider: CloudProvider;
  status: "PENDING" | "PROVISIONING" | "INSTALLING" | "DONE" | "FAILED";
  serverIp?: string;
  tenantUrl?: string;
  logOutput?: string;
  errorMessage?: string;
  startedAt?: Date;
  completedAt?: Date;
}

export interface StartByocInput {
  companyId: number;
  config: ByocDeployConfig;
  credentials: ByocCredentials;
}
