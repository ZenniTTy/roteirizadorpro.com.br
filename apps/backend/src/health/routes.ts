import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { DependencyHealthSchema, HealthResponseSchema } from './schemas.js';

const GRAPHHOPPER_BASE_URL = process.env.GRAPHHOPPER_BASE_URL ?? 'http://127.0.0.1:8989';

const healthRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.get('/', {
    schema: { response: { 200: HealthResponseSchema } },
    config: { rateLimit: false },
  }, async () => ({
    status: 'ok' as const,
    uptimeSeconds: Math.round(process.uptime()),
  }));

  app.get('/db', {
    schema: { response: { 200: DependencyHealthSchema, 503: DependencyHealthSchema } },
    config: { rateLimit: false },
  }, async (_request, reply) => {
    const start = Date.now();
    try {
      await app.prisma.$queryRaw`SELECT 1`;
      return reply.code(200).send({ status: 'ok' as const, latencyMs: Date.now() - start });
    } catch (err) {
      const error = err instanceof Error ? err.message : 'unknown error';
      return reply.code(503).send({ status: 'degraded' as const, latencyMs: Date.now() - start, error });
    }
  });

  app.get('/graphhopper', {
    schema: { response: { 200: DependencyHealthSchema, 503: DependencyHealthSchema } },
    config: { rateLimit: false },
  }, async (_request, reply) => {
    const start = Date.now();
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 2000);
      const res = await fetch(`${GRAPHHOPPER_BASE_URL}/health`, {
        signal: controller.signal,
      }).finally(() => clearTimeout(timeout));
      const latencyMs = Date.now() - start;
      if (!res.ok) {
        return reply.code(503).send({ status: 'degraded' as const, latencyMs, error: `upstream ${res.status}` });
      }
      return reply.code(200).send({ status: 'ok' as const, latencyMs });
    } catch (err) {
      const error = err instanceof Error ? err.message : 'unknown error';
      return reply.code(503).send({ status: 'degraded' as const, latencyMs: Date.now() - start, error });
    }
  });
};

export default healthRoutes;
