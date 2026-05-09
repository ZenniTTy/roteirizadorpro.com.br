import { Type, type Static } from '@sinclair/typebox';

const StopSchema = Type.Object({
  lat: Type.Number({ minimum: -90, maximum: 90 }),
  lng: Type.Number({ minimum: -180, maximum: 180 }),
  label: Type.Optional(Type.String()),
});

export const OptimizeRequestSchema = Type.Object({
  stops: Type.Array(StopSchema, { minItems: 2, maxItems: 50 }),
  home: Type.Optional(StopSchema),
});
export type OptimizeRequest = Static<typeof OptimizeRequestSchema>;

export const OptimizeResponseSchema = Type.Object({
  status: Type.Literal('not_implemented'),
  message: Type.String(),
});
export type OptimizeResponse = Static<typeof OptimizeResponseSchema>;
