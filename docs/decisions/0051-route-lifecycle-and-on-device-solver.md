# ADR-0051: Route lifecycle (`RouteState`) + solver on-device Dart (Área 7)

- **Status:** Accepted
- **Date:** 2026-06-13
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0010 (clone positioning), ADR-0030 (paywall só em Navegar), ADR-0035 (Spoke white-label hierarchy), ADR-0045 (static dump baseline — fonte dos fatos)

## Context

A Área 7 (Otimizar rota) precisa de duas coisas que o modelo atual não tem:

1. **Um modelo de lifecycle da rota** com mais estados que o `enum RouteStatus { draft, optimized, running, completed }` de hoje (`lib/features/routes/domain/route.dart`). O funil de otimização do Spoke distingue DRAFT, otimizando, pré-confirmação (otimizado mas não confirmado), pronto-para-rodar (confirmado), editando (mexeu numa rota já otimizada) e estados de erro — não cabem num eixo linear de 4 valores.
2. **Uma fonte de ordem otimizada + métricas** (tempo/km), já que o backend real (GraphHopper) é Slice 3 e ainda não existe.

O dump estático do Spoke v3.65.1 (`~/spoke-dump/jadx-out`) prova a estrutura por código:

- `core/entity/RouteState.java` usa **flags + timestamps ortogonais** (`started/startedAt/optimizedAt/completed/completedAt/optimizing/optimizationErroredAt/optimizationAttemptedAt/optimizationAcknowledged/confirmed`) + um `OptimizationState`.
- `core/entity/OptimizationState.java` = `CREATING / OPTIMIZED / EDITING`.
- `core/entity/OptimizationRoutingSolver.java` = `GOOGLE_MAPS / GRAPH_HOPPER` — o Spoke **alterna solvers de backend nativamente** atrás de uma fronteira.

A validação dump-first corrigiu uma proposta inicial de enum linear de 6 valores: o estado visual (PRE-CONFIRM, Ready-to-Run, erro) é **derivado** dessas flags, não um campo.

## Decision

1. **Substituir `enum RouteStatus`** por uma classe `RouteState` (flags + timestamps) espelhando `core/entity/RouteState.java`: `OptimizationState { creating, optimized, editing }` + `confirmed`/`started`/`optimizing`/`optimizationAcknowledged`/`completed` + os timestamps `optimizedAt`/`optimizationErroredAt`/`optimizationAttemptedAt`. O estado visual (DRAFT/otimizando/PRE-CONFIRM/Ready-to-Run/erro) é **DERIVADO por getters**, nunca armazenado.

2. **Otimização via interface `RouteOptimizer`**; a implementação do Slice 2 é `LocalRouteOptimizer` (nearest-neighbor + refinamento 2-opt, distância Haversine via `Geolocator.distanceBetween`). O Slice 3 injeta um `GraphHopperRouteOptimizer` via override de provider, **sem tocar UI/estado**. A UI pós-otimização (PRE-CONFIRM, summary, chips A1..AN) só faz sentido com ordem + métricas reais — um mock zerado pareceria quebrado.

3. **Cortes honestos (botão fiel + ação "Em breve" observável):** "Carregar veículo" (barcode/ML Kit) e "Compartilhar rota em tempo real" (live-tracking backend) ficam para o Slice 3 — o botão existe no layout (estrutura fiel ao Spoke) mas a ação é um SnackBar "Em breve" (sem bug silencioso). O gate "10 paradas/assinar" do Spoke **NÃO é clonado** (divergência de negócio per ADR-0030: acesso único R$ 25,90/30d, paywall só em "Navegar" na Á8, otimização grátis). Como consequência dump-confirmada, a ação "Desfazer otimização" do Spoke — acoplada exclusivamente a esse paywall — também cai (não há controle órfão).

## Consequences

- **Nenhuma dependência nova de stack.** `geolocator ^14.0.2` já está no `pubspec.yaml` (`Geolocator.distanceBetween`). O solver é Dart puro sobre o que já existe.
- A migração do `enum RouteStatus` toca o seed + os helpers de `routes_provider.dart` (localizada — `RouteStatus.optimized` não tinha consumidor) e os ~10 testes que constroem `Route(status: …)`. Sem `// TODO` de migração (zero débito).
- O default do chip de identificação é **Moderno** (escolha de produto — mais legível para etiquetar pacotes), enquanto o fallback hard-coded do Spoke é Clássico. A geração é parametrizada por `PackageLabelFormat { moderno, classico }`; o toggle Moderno/Clássico vive na Área 10 (débito declarado no TODO), e o braço Clássico já fica fiel-mas-dormente.
- A fronteira `RouteOptimizer` deixa o swap para GraphHopper (Slice 3) sem refatorar a Área 7. Quando o solver real chegar, `RouteOptimizationResult` ganha um DTO espelhando a resposta TypeBox (ADR-0013) — mas isso é Slice 3.
