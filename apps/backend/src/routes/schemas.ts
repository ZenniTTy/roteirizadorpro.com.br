import { Type, type Static } from '@sinclair/typebox';

export const StopSchema = Type.Object({
  lat: Type.Number({ minimum: -90, maximum: 90 }),
  lng: Type.Number({ minimum: -180, maximum: 180 }),
  label: Type.Optional(Type.String()),
});
export type Stop = Static<typeof StopSchema>;

export const OptimizeRequestSchema = Type.Object({
  stops: Type.Array(StopSchema, { minItems: 2, maxItems: 50 }),
  home: Type.Optional(StopSchema),
});
export type OptimizeRequest = Static<typeof OptimizeRequestSchema>;

// EVOLVED in slice 2: replaces the 501-placeholder shape.
// Slice 2's mock returns input order with zeroed metrics.
// Slice 3 reuses this shape against the real GraphHopper+TSP solver.
export const OptimizeResponseSchema = Type.Object({
  optimizedOrder: Type.Array(Type.Integer({ minimum: 0 })),
  totalDistanceM: Type.Number({ minimum: 0 }),
  totalDurationS: Type.Number({ minimum: 0 }),
});
export type OptimizeResponse = Static<typeof OptimizeResponseSchema>;
