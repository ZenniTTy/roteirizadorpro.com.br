import { Type, type Static } from '@sinclair/typebox';

export const UserSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String({ format: 'email' }),
  name: Type.String(),
  phone: Type.Union([Type.String(), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' }),
});
export type User = Static<typeof UserSchema>;

export const ErrorResponseSchema = Type.Object({
  error: Type.String(),
  message: Type.String(),
});
export type ErrorResponse = Static<typeof ErrorResponseSchema>;

export const RegisterRequestSchema = Type.Object({
  email: Type.String({ format: 'email', maxLength: 254 }),
  password: Type.String({ minLength: 8, maxLength: 100 }),
  name: Type.String({ minLength: 2, maxLength: 100 }),
  phone: Type.Optional(Type.String({ maxLength: 20 })),
});
export type RegisterRequest = Static<typeof RegisterRequestSchema>;

export const RegisterResponseSchema = Type.Object({ user: UserSchema });
export type RegisterResponse = Static<typeof RegisterResponseSchema>;

export const LoginRequestSchema = Type.Object({
  email: Type.String({ format: 'email' }),
  password: Type.String({ minLength: 1 }),
});
export type LoginRequest = Static<typeof LoginRequestSchema>;

export const TokensSchema = Type.Object({
  access: Type.String(),
  refresh: Type.String(),
});
export type Tokens = Static<typeof TokensSchema>;

export const LoginResponseSchema = Type.Intersect([
  TokensSchema,
  Type.Object({ user: UserSchema }),
]);
export type LoginResponse = Static<typeof LoginResponseSchema>;

export const RefreshRequestSchema = Type.Object({
  refresh: Type.String({ minLength: 1 }),
});
export type RefreshRequest = Static<typeof RefreshRequestSchema>;

export const RefreshResponseSchema = TokensSchema;
export type RefreshResponse = Static<typeof RefreshResponseSchema>;

export const MeResponseSchema = Type.Object({ user: UserSchema });
export type MeResponse = Static<typeof MeResponseSchema>;
