import bcrypt from 'bcrypt';
import type { FastifyReply, FastifyRequest } from 'fastify';
import { env } from '../config/env.js';
import { generateRefreshToken, hashRefreshToken } from './tokens.js';
import type {
  LoginRequest,
  LoginResponse,
  MeResponse,
  RefreshRequest,
  RefreshResponse,
  RegisterRequest,
  RegisterResponse,
  User,
} from './schemas.js';

const BCRYPT_COST = 12;

type PrismaUser = {
  id: string;
  email: string;
  name: string;
  phone: string | null;
  createdAt: Date;
};

const toUserDto = (u: PrismaUser): User => ({
  id: u.id,
  email: u.email,
  name: u.name,
  phone: u.phone,
  createdAt: u.createdAt.toISOString(),
});

const mintAccessToken = (request: FastifyRequest, userId: string): string =>
  request.server.jwt.sign({ sub: userId }, { expiresIn: `${env.ACCESS_TOKEN_TTL_SECONDS}s` });

const refreshExpiresAt = (): Date =>
  new Date(Date.now() + env.REFRESH_TOKEN_TTL_SECONDS * 1000);

export async function registerHandler(
  request: FastifyRequest<{ Body: RegisterRequest }>,
  reply: FastifyReply,
): Promise<RegisterResponse | void> {
  const { email, password, name, phone } = request.body;
  const normalizedEmail = email.toLowerCase().trim();

  const existing = await request.server.prisma.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (existing) {
    return reply.code(409).send({ error: 'email_taken', message: 'email already registered' });
  }

  const passwordHash = await bcrypt.hash(password, BCRYPT_COST);
  const user = await request.server.prisma.user.create({
    data: { email: normalizedEmail, passwordHash, name: name.trim(), phone: phone ?? null },
  });

  return reply.code(201).send({ user: toUserDto(user) });
}

export async function loginHandler(
  request: FastifyRequest<{ Body: LoginRequest }>,
  reply: FastifyReply,
): Promise<LoginResponse | void> {
  const { email, password } = request.body;
  const normalizedEmail = email.toLowerCase().trim();

  const user = await request.server.prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (!user) {
    return reply.code(401).send({ error: 'invalid_credentials', message: 'invalid email or password' });
  }

  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) {
    return reply.code(401).send({ error: 'invalid_credentials', message: 'invalid email or password' });
  }

  const access = mintAccessToken(request, user.id);
  const { token: refresh, hash } = generateRefreshToken();
  await request.server.prisma.refreshToken.create({
    data: { userId: user.id, tokenHash: hash, expiresAt: refreshExpiresAt() },
  });

  return reply.code(200).send({ access, refresh, user: toUserDto(user) });
}

export async function refreshHandler(
  request: FastifyRequest<{ Body: RefreshRequest }>,
  reply: FastifyReply,
): Promise<RefreshResponse | void> {
  const { refresh } = request.body;
  const incomingHash = hashRefreshToken(refresh);

  const stored = await request.server.prisma.refreshToken.findUnique({
    where: { tokenHash: incomingHash },
  });

  if (!stored) {
    return reply.code(401).send({ error: 'invalid_refresh', message: 'refresh token not recognised' });
  }

  if (stored.revokedAt !== null) {
    request.log.warn(
      { userId: stored.userId, refreshId: stored.id },
      'refresh token reuse detected — revoking all user tokens',
    );
    await request.server.prisma.refreshToken.updateMany({
      where: { userId: stored.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return reply.code(401).send({ error: 'token_reuse', message: 'session revoked, please log in again' });
  }

  if (stored.expiresAt.getTime() < Date.now()) {
    return reply.code(401).send({ error: 'refresh_expired', message: 'refresh token expired' });
  }

  const { token: newRefresh, hash: newHash } = generateRefreshToken();
  await request.server.prisma.$transaction([
    request.server.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    }),
    request.server.prisma.refreshToken.create({
      data: { userId: stored.userId, tokenHash: newHash, expiresAt: refreshExpiresAt() },
    }),
  ]);

  const access = mintAccessToken(request, stored.userId);
  return reply.code(200).send({ access, refresh: newRefresh });
}

export async function meHandler(
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<MeResponse | void> {
  const userId = request.user.sub;
  const user = await request.server.prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    return reply.code(404).send({ error: 'user_not_found', message: 'authenticated user no longer exists' });
  }
  return reply.code(200).send({ user: toUserDto(user) });
}
