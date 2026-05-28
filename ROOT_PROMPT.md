# Prompt de Continuação - Roteirizador Pro (M2 - Slice 2)

**Para o Agente da próxima sessão:**

1. **Contexto:** Estamos no Milestone 2 (M2) do projeto Roteirizador Pro. O "Slice 1" (APK base) já foi entregue v1.0.0. Estamos atualmente nas tarefas do **Slice 2 e Slice 3**. O app utiliza Flutter, Riverpod 3, e um backend com Fastify v5 + Prisma 7 + PostgreSQL 16.
2. **O que foi feito recentemente:**
   - Adicionamos a funcionalidade do "Lembrar de mim" usando `SharedPreferencesAsync` para persistir o e-mail preenchido no login (persistência aprimorada).
   - O UI do Google Maps (RouteShellPage) foi ajustado. As margens da BottomSheet e a posição dos ícones flutuantes (centrar e alternar mapa) foram elevados para que fiquem acima dos ícones nativos de sistema e acompanhem a BottomSheet de forma responsiva (`buttonsBottom = sheetHeightPx + 48`).
   - O menu Hamburguer (`AppDrawer`) teve sua estilização melhorada. O botão "Assinar" já possui um gradiente verde neon (`AppColors.neon`) e o ícone de diamante (`LucideIcons.gem`).
   - A linha divisória abaixo do "Assinar" foi removida da primeira seção da lista de rotas.
   - As demais linhas divisórias entre as categorias de tempo ("Próximas", "Hoje", "Esta semana") no `DrawerRouteList` agora utilizam a cor neon com baixa opacidade para um look moderno e sutil.
3. **Erros anteriores:** Consulte `.agent/knowledge/01-erros-cometidos.md` para evitar cometer erros conhecidos, especialmente relacionados à injeção de chaves no `.env` e persistência de Secure Storage no Android. Lembre-se: chaves críticas (Maps SDK, etc) DEVEM ser adicionadas manualmente pelo usuário, o agente NÃO tem permissão de editá-las via bash ou MCP de acordo com a regra `01-secrets-and-self-mod.md`.

**Seu próximo passo (Instrução do Usuário):**
Revise o estado do `validate_ui.yaml` usando o Maestro para garantir a estabilidade do layout, e continue as próximas etapas do roadmap (`docs/08-ROADMAP-v2.md`). Verifique também com o usuário se o "Hot Restart" no dispositivo Samsung M54 ou Emulador atualizou com sucesso os assets visuais corrigidos nesta sessão. E valide se a Google Maps API Key `AIza...` já foi adicionada pelo usuário no seu arquivo `.env` local (`MAPS_API_KEY`).
