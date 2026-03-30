// HTTP observability middleware — powered by @zentto/obs SDK
import type { RequestHandler } from 'express';
import { httpMiddleware } from '@zentto/obs';
import { obs } from '../modules/integrations/observability.js';

export const observabilityMiddleware = httpMiddleware(obs) as unknown as RequestHandler;
