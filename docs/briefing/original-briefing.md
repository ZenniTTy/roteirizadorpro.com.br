# Original Briefing — Source of Truth

> **Status:** raw / imutável. Esta pasta existe por convenção da skill `saas-project-blueprint` (Karpathy pattern: briefing original separado das decisões derivadas).
>
> **Convenção:** o briefing original deste projeto **não é** um único documento isolado — ele entrou no repositório distribuído entre os artefatos canônicos abaixo. Re-condensá-lo aqui criaria uma terceira fonte da verdade. Em vez disso, este arquivo aponta para os locais onde o briefing original vive.

## Onde está o briefing original

| Conteúdo do briefing | Local canônico |
|---|---|
| Proposta Workana aceita (escopo, valor, prazo) | absorvida em [`../01-PROJECT.md`](../01-PROJECT.md) — seções "Business Model", "Milestones", "Constraints", "Out of Scope" |
| Conversa com cliente (decisões de produto: Efí Bank, 1GB workaround, sem Play Store, sem cancelamento) | absorvida em [`../01-PROJECT.md`](../01-PROJECT.md) e [`../decisions/0007-efi-bank-payment.md`](../decisions/0007-efi-bank-payment.md) |
| Posicionamento "fork funcional do Circuit" | [`../decisions/0010-clone-positioning.md`](../decisions/0010-clone-positioning.md) |
| UI aprovada pelo cliente | [`../../prototipo/`](../../prototipo/) — fonte canônica de identidade visual, telas, gestos, fluxos |
| Catálogo de features contratadas | [`../04-FEATURES.md`](../04-FEATURES.md) (F01–F15) |
| Telas mapeadas | [`../05-SCREENS.md`](../05-SCREENS.md) (19 telas) |

## Por que não copiar o briefing literal aqui

Três razões:

1. **Multi-fonte.** O briefing veio em três pedaços (proposta Workana + conversa cliente + protótipo aprovado). Não há um único arquivo "original" para preservar.
2. **Já absorvido.** Cada decisão extraída do briefing virou um ADR rastreável. O briefing literal acrescentaria duplicação sem ganho.
3. **Karpathy "Surgical Changes".** Tocar só o que é necessário. Se o protótipo é a fonte canônica de UX e os ADRs são a fonte canônica de stack, criar um quarto repositório de verdade é divergência futura garantida.

## Quando atualizar este arquivo

Quando o cliente reconfirmar o escopo M2 (após aceite M1), adicionar uma linha aqui apontando para o documento que registrar a reconfirmação. Não mais que isso.
