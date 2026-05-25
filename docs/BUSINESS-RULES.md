# BUSINESS-RULES.md — Regras de Negócio

- **Status:** Accepted
- **Última atualização:** 2026-05-24
- **Decisão arquitetural:** [ADR-0030](./decisions/0030-stripe-pix-30-day-access-pass.md) (Stripe Pix + 30-day access pass; supersedes ADR-0007)

> Fonte de verdade para regras de negócio do produto. Leia antes de implementar qualquer funcionalidade de pagamento, paywall ou assinatura. Para a decisão técnica e options-considered, ver ADR-0030.

---

## 1. Produto

Roteirizador Pro é um app Android para motoboys fazerem entregas com rota otimizada. O usuário adiciona paradas, o app calcula o menor caminho e abre o Waze ou Google Maps para navegação.

**Distribuição atual:** APK direto em `roteirizadorpro.com.br/download`. Não está na Play Store.
**Distribuição futura:** Google Play Store — ver seção 14 para o impacto no pagamento.

---

## 2. Modelo de monetização

- Preço: **R$ 25,90 por 30 dias de acesso** (não é assinatura recorrente — é um pass que dura 30 dias)
- Pagamento: Pix exclusivamente (nenhum outro método em V1)
- Gateway: **Stripe** (ADR-0030)
- Split: 50/50 entre dois sócios via Stripe Connect (Separate Charges and Transfers)
- Taxa Stripe Pix: ~1,5% + R$ 0,40 = ~R$ 0,79 por transação sobre R$ 25,90
- Líquido por sócio: ~R$ 12,56

> **Sutileza importante:** "R$ 25,90 por mês" no marketing/UI = "R$ 25,90 a cada renovação manual de 30 dias". Não há cobrança automática mensal. Cada renovação é um novo `PaymentIntent` que o usuário inicia ativamente no app — Pix Automático é invite-only no Brasil e o produto explicitamente escolheu o modelo de renovação manual. Ver §8 (inviolable).

---

## 3. Stripe Connect — arquitetura de split

Modelo: **Separate Charges and Transfers** (não Destination Charges — Destination só transfere para 1 conta, inviável para 50/50).

Contas necessárias:
- Platform account: conta Stripe do cliente (dono do app)
- Connected account A: conta Stripe do sócio 1
- Connected account B: conta Stripe do sócio 2

Variáveis de ambiente:

```
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECTED_ACCOUNT_SOCIO_1=acct_...
STRIPE_CONNECTED_ACCOUNT_SOCIO_2=acct_...
SUBSCRIPTION_AMOUNT_CENTS=2590
SUBSCRIPTION_DURATION_DAYS=30
```

> Stripe Pix no Brasil pode ser invite-only. Verificar em Dashboard → Settings → Payment Methods antes de testar em produção.

---

## 4. O que funciona SEM assinatura (gratuito para sempre)

- Criar conta e fazer login
- Adicionar paradas: manual (texto/CEP), voz (speech-to-text pt-BR), OCR (câmera lê etiqueta)
- Ver e gerenciar lista de paradas
- Reordenar paradas arrastando
- Deletar paradas
- Marcar paradas como entregues
- Editar endereço de uma parada
- Otimizar a rota (calcular a ordem ideal)
- Ver o mapa com todas as paradas
- Ver o tempo estimado de conclusão
- Configurar ponto de casa (sentido casa)
- Compartilhar link do app (WhatsApp, copiar link, QR Code)

**Regra crítica:** nenhuma dessas funções pede pagamento em nenhuma circunstância. Não adicionar paywall em nenhuma dessas telas.

---

## 5. O que REQUER assinatura

Apenas um elemento: **o botão "Iniciar Navegação"**.

Fluxo exato (decisão do cliente):

```
1. Adicionar paradas          — GRATUITO
2. Otimizar rota              — GRATUITO
3. Ver rota otimizada         — GRATUITO
4. Tocar "Iniciar Navegação"  — PAYWALL APARECE SE INATIVO
5. Pagar via Pix              — webhook confirma
6. Botão desbloqueado         — abre Waze ou Google Maps
```

**Regra crítica:** é apenas este botão. Não há nenhum outro paywall em nenhuma outra tela do app.

---

## 6. Fluxo completo de pagamento Stripe Pix

1. Usuário toca "Pagar com Pix" no modal de paywall
2. Backend cria `PaymentIntent`: `amount=2590`, `currency=brl`, `payment_method_types=['pix']`, `metadata={userId}`
3. Backend salva `Payment` no banco com `status='pending'`
4. Backend retorna `next_action.pix_display_qr_code` para o app
5. App exibe QR Code + código copia-e-cola
6. Usuário paga no banco
7. Stripe dispara webhook `payment_intent.succeeded`
8. Backend valida assinatura do webhook (`stripe.webhooks.constructEvent`)
9. Backend verifica idempotência (stripeEventId já processado? retorna 200 imediatamente)
10. Backend executa split: 2 `stripe.transfers.create` para os Connected Accounts
11. Backend cria `Subscription`: `status='active'`, `expires_at=now+30dias`
12. App descobre o `status='active'` via polling de `GET /subscription/status` a cada 5 s (sem WebSocket — ADR-0030 escolheu polling pra simplicidade)
13. App desbloqueia "Iniciar Navegação"

---

## 7. Ciclo de vida da assinatura

| Evento | Ação |
|---|---|
| Webhook confirmado | `status='active'`, `expires_at=now+30d` |
| Cron 03:00 BRT diário | Subscriptions com `expires_at < now()` → `status='inactive'` |
| Usuário toca "Iniciar Navegação" após expirar | Paywall aparece novamente → mesmo fluxo |

---

## 8. O que NÃO existe — inviolável

**SEM CANCELAMENTO**
- Não existe botão "Cancelar assinatura" em nenhuma tela
- Não existe endpoint `DELETE /subscription` ou `POST /subscription/cancel`
- A única forma de "cancelar" é não renovar quando expirar
- Motivo: prevenir chargeback abuse (pagar, cancelar, pedir estorno do Pix)

**SEM REEMBOLSO**
- Não existe fluxo de reembolso no app
- Não existe endpoint `POST /payments/:id/refund`
- Mesmo que Stripe suporte tecnicamente, o produto não oferece
- Deve ser declarado nos Termos de Serviço

**SEM RENOVAÇÃO AUTOMÁTICA**
- Cada renovação é um novo `PaymentIntent` iniciado manualmente pelo usuário
- Não usar Stripe Billing recorrente
- Não usar Stripe Subscriptions (o modelo de produto é "pague e use por 30 dias")

---

## 9. Configurações — seção assinatura

Somente leitura. Sem nenhuma ação disponível.

- Ativa: `"Ativa até DD/MM/AAAA"` em cor `#22C55E` (verde)
- Inativa: `"Sem assinatura ativa"` em cor `#6B6880` (texto secundário)

**Não mostrar:** botão cancelar, botão renovar, botão gerenciar, link para página de gerenciamento.

---

## 10. Verificação server-side obrigatória

O estado local da assinatura (Riverpod, cache) é usado **apenas para UX** (mostrar/esconder o botão visualmente).

A verificação autoritativa **sempre** acontece no servidor:
- A cada toque em "Iniciar Navegação": backend executa `GET /subscription/status`
- Se o servidor diz inativo, o paywall aparece independente do estado local

---

## 11. Idempotência no webhook Stripe

Stripe pode reenviar o mesmo evento. O handler deve:

1. Validar assinatura: `stripe.webhooks.constructEvent(payload, sig, secret)`
2. Verificar `stripeEventId` em `webhook_events` — se `processed=true`: retornar `200` imediatamente
3. Salvar evento com `processed=false`
4. Processar (subscription + split)
5. Marcar `processed=true`
6. Retornar `200`

**Nunca retornar 4xx/5xx para o Stripe** — causa reenvio infinito.

Eventos a tratar:
- `payment_intent.succeeded` → ativar subscription + executar split
- `payment_intent.payment_failed` → `payment.status='failed'`
- `payment_intent.canceled` → `payment.status='expired'`

---

## 12. Navegação externa (após assinatura confirmada)

1. App verifica apps instalados
2. Se Waze E Google Maps: bottom sheet "Abrir com Waze" / "Abrir com Google Maps"
3. Se apenas um: abre direto
4. Se nenhum: abre browser como fallback

Deep links:
- Waze: `waze://?ll={lat},{lng}&navigate=yes`
- Google Maps: `google.navigation:q={lat},{lng}`
- Fallback: `https://maps.google.com/?daddr={lat},{lng}`

O app não tem navegação turn-by-turn interna. Delega para GPS externo.

---

## 13. Visual do modal de paywall

Seguir `docs/06-DESIGN-SYSTEM.md`:
- Cor primária: `#6C3FC5`
- Fundo: `#FFFFFF`
- Botão "Pagar com Pix": pill shape, `#6C3FC5`, branco, 52dp de altura
- Preço "R$ 25,90": heading-xl, `#6C3FC5`, centralizado
- Subtexto: *"Acesso por 30 dias. Sem renovação automática."*
- QR Code: borda `#6C3FC5`, border-radius 12dp
- Código copia-e-cola: fonte mono, fundo `#F8F7FC`, botão "Copiar" à direita
- Botão fantasma "Já paguei": sem preenchimento, texto `#6C3FC5`

**Não incluir:** "cancele quando quiser", "garantia de reembolso", link de cancelamento, referência a renovação automática.

---

## 14. Estratégia de distribuição e impacto no pagamento

### Fase atual — APK direto (V1, em produção)

- Total liberdade de implementação — nenhuma loja tem jurisdição
- Stripe Pix direto no app
- Taxa efetiva: ~2-3% por transação
- Split automático via Stripe Connect Transfers

### Fase futura — Google Play Store

- **Google Play Billing obrigatório** para bens digitais no Brasil
- **Stripe dentro do app não será permitido**
- Taxa Google Play: 15% a 30% por transação
- Sobre R$ 25,90 com 15%: recebem ~R$ 22,00 bruto antes do split
- Sobre R$ 25,90 com 30%: recebem ~R$ 18,13 bruto antes do split
- Split entre sócios precisaria ser feito manualmente (Google Play Billing não tem split nativo)

**Alternativa viável para Play Store sem perder o Pix:**
- Botão "Assinar" redireciona para `roteirizadorpro.com.br/assinar` no browser
- Usuário paga via Stripe/Pix no site
- Webhook ativa a conta no backend
- App consulta `GET /subscription/status` normalmente
- Google permite redirecionamento para site externo (com restrições de UX)

### Implicação para o código agora

Isolar toda a lógica de pagamento em módulos dedicados:
- Backend: `apps/backend/src/payments/`
- Mobile: `apps/mobile/lib/features/payments/`

O `PaywallController` no Flutter deve receber o status via API sem saber qual gateway está por baixo. Isso permite trocar Stripe por Google Play Billing no futuro sem reescrever as telas.

---

## 15. Resumo

```
LIVRE (sem assinatura):
  Criar conta → Login → Adicionar paradas (texto/voz/OCR)
  → Reordenar → Otimizar rota → Ver rota → Ver mapa
  → Configurar casa → Compartilhar app

BLOQUEADO (requer assinatura):
  Iniciar Navegação  ← único ponto de bloqueio

INEXISTENTE (não criar em hipótese alguma):
  Cancelar → Reembolsar → Renovação automática → Gerenciar assinatura
```
