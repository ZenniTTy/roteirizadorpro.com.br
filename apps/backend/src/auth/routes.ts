import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import {
  ErrorResponseSchema,
  LoginRequestSchema,
  LoginResponseSchema,
  MeResponseSchema,
  RefreshRequestSchema,
  RefreshResponseSchema,
  RegisterRequestSchema,
  RegisterResponseSchema,
} from './schemas.js';
import { loginHandler, meHandler, refreshHandler, registerHandler } from './handlers.js';

const authRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.post('/register', {
    schema: {
      body: RegisterRequestSchema,
      response: { 201: RegisterResponseSchema, 409: ErrorResponseSchema },
    },
    config: { rateLimit: { max: 3, timeWindow: '1 hour' } },
  }, registerHandler);

  app.post('/login', {
    schema: {
      body: LoginRequestSchema,
      response: { 200: LoginResponseSchema, 401: ErrorResponseSchema },
    },
    config: { rateLimit: { max: 5, timeWindow: '15 minutes' } },
  }, loginHandler);

  app.post('/refresh', {
    schema: {
      body: RefreshRequestSchema,
      response: { 200: RefreshResponseSchema, 401: ErrorResponseSchema },
    },
    config: { rateLimit: { max: 10, timeWindow: '1 minute' } },
  }, refreshHandler);

  app.get('/me', {
    onRequest: [app.authenticate],
    schema: {
      response: { 200: MeResponseSchema, 401: ErrorResponseSchema, 404: ErrorResponseSchema },
    },
  }, meHandler);
};

export default authRoutes;
