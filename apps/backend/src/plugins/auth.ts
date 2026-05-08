import fp from 'fastify-plugin';
import jwt from '@fastify/jwt';
import { env } from '../config/env.js';

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: import('fastify').FastifyRequest, reply: import('fastify').FastifyReply) => Promise<void>;
  }
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { sub: string };
    user: { sub: string; iat: number; exp: number };
  }
}

const unescapePem = (s: string): string => s.includes('\\n') ? s.replace(/\\n/g, '\n') : s;

export default fp(async (app) => {
  await app.register(jwt, {
    secret: {
      private: unescapePem(env.JWT_PRIVATE_KEY),
      public: unescapePem(env.JWT_PUBLIC_KEY),
    },
    sign: { algorithm: 'RS256' },
  });

  app.decorate('authenticate', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.code(401).send({ error: 'unauthorized', message: 'invalid or missing token' });
    }
  });
}, { name: 'auth', dependencies: [] });
