import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { OptimizeRequestSchema, OptimizeResponseSchema } from './schemas.js';

const routesRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.post('/optimize', {
    onRequest: [app.authenticate],
    schema: {
      body: OptimizeRequestSchema,
      response: { 200: OptimizeResponseSchema },
    },
  }, async (request) => {
    const { stops } = request.body;
    // Slice 2 mock: input order, zeroed metrics.
    // Slice 3 will replace the body of this handler with the real solver
    // (GraphHopper distance matrix → nearest-neighbor + 2-opt).
    return {
      optimizedOrder: stops.map((_, i) => i),
      totalDistanceM: 0,
      totalDurationS: 0,
    };
  });
};

export default routesRoutes;
