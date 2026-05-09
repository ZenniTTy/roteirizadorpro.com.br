import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { OptimizeRequestSchema, OptimizeResponseSchema } from './schemas.js';

const routesRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.post('/optimize', {
    onRequest: [app.authenticate],
    schema: {
      body: OptimizeRequestSchema,
      response: { 501: OptimizeResponseSchema },
    },
  }, async (_request, reply) =>
    reply.code(501).send({
      status: 'not_implemented' as const,
      message: 'route optimization placeholder — full implementation lands in M2',
    }));
};

export default routesRoutes;
