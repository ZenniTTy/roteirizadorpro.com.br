import { Type, type Static } from '@sinclair/typebox';

export const HealthResponseSchema = Type.Object({
  status: Type.Literal('ok'),
  uptimeSeconds: Type.Number(),
});
export type HealthResponse = Static<typeof HealthResponseSchema>;

export const DependencyHealthSchema = Type.Object({
  status: Type.Union([Type.Literal('ok'), Type.Literal('degraded')]),
  latencyMs: Type.Optional(Type.Number()),
  error: Type.Optional(Type.String()),
});
export type DependencyHealth = Static<typeof DependencyHealthSchema>;
