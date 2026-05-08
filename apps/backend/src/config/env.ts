import 'dotenv/config';
import { Type } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';

const EnvSchema = Type.Object({
  NODE_ENV: Type.Union([
    Type.Literal('development'),
    Type.Literal('test'),
    Type.Literal('production'),
  ]),
  PORT: Type.Number({ minimum: 1, maximum: 65535 }),
  DATABASE_URL: Type.String({ minLength: 1 }),
  JWT_PRIVATE_KEY: Type.String({ minLength: 1 }),
  JWT_PUBLIC_KEY: Type.String({ minLength: 1 }),
  ACCESS_TOKEN_TTL_SECONDS: Type.Number({ minimum: 60 }),
  REFRESH_TOKEN_TTL_SECONDS: Type.Number({ minimum: 60 }),
  CORS_ORIGINS: Type.String(),
});

const raw = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 3000),
  DATABASE_URL: process.env.DATABASE_URL ?? '',
  JWT_PRIVATE_KEY: process.env.JWT_PRIVATE_KEY ?? '',
  JWT_PUBLIC_KEY: process.env.JWT_PUBLIC_KEY ?? '',
  ACCESS_TOKEN_TTL_SECONDS: Number(process.env.ACCESS_TOKEN_TTL_SECONDS ?? 900),
  REFRESH_TOKEN_TTL_SECONDS: Number(process.env.REFRESH_TOKEN_TTL_SECONDS ?? 604800),
  CORS_ORIGINS: process.env.CORS_ORIGINS ?? '',
};

const errors = [...Value.Errors(EnvSchema, raw)];
if (errors.length > 0) {
  const summary = errors.map((e) => `${e.path} ${e.message}`).join('\n  ');
  throw new Error(`Invalid environment configuration:\n  ${summary}`);
}

export const env = Value.Decode(EnvSchema, raw);
export type Env = typeof env;
