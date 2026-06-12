# ADR-0050: `path_provider` para fotos de pacote 100% locais (Área 6)

- **Status:** Accepted
- **Date:** 2026-06-12
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0045 (static dump baseline — fonte do fato F12)

## Context

A Área 6 (Editar parada) inclui anexar fotos de pacote às notas da parada. O dump estático do Spoke v3.65.1 prova (fato F12 do spec `docs/superpowers/specs/2026-06-11-area6-edit-stop-design.md`) que o Spoke guarda essas fotos **somente no device** (`files/package_photos/<user>/<route>/<stop>`, via `PackagePhotoManager` + `getFilesDir()`), **sem upload** — proof-of-delivery é um modelo separado do produto B2B (Dispatch). Replicamos o comportamento local-only.

`image_picker ^1.2.2` já estava no pubspec (câmera). Faltava apenas uma forma portável de resolver o diretório de dados do app para persistir as cópias.

## Decision

Adicionar **`path_provider ^2.1.5`** (resolvido 2.1.5, plugin first-party flutter.dev; API confirmada via Context7 em 2026-06-12) como dependência direta do `apps/mobile`.

- Produção usa `getApplicationSupportDirectory()` — paralelo fiel ao `getFilesDir()` do Spoke (hardening H17): arquivos internos do app, fora do espaço visível ao usuário, sem permissão extra de storage.
- O acesso é encapsulado em `PackagePhotoStore` (`lib/features/routes/data/package_photo_store.dart`), que recebe o diretório-base **injetado** (`Future<Directory> Function()`) — testes usam temp dir, sem mock do plugin.
- Estrutura: `package_photos/<routeId>/<stopId>/<uuid>.jpg`. Falhas de I/O degradam com `debugPrint` + retorno vazio/null/false (H15); remover stop apaga o diretório; duplicar stop **copia os arquivos** (paths nunca compartilhados, H16).

## Consequences

- **Sem upload e sem novas permissões Android** — delta de permissões esperado no `aapt2 dump permissions`: ZERO (CAMERA já existia para OCR; `image_picker` pede grant em runtime sozinho).
- Fotos órfãs após restart do app são aceitas até a persistência real de rotas (Slice 3); worker de limpeza estilo Spoke (30 dias) fica registrado como TODO da Á8/Slice 3 (spec §3.3).
- Única mudança de stack da MS-A6; nenhuma outra dependência entra.
