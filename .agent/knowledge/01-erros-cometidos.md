# Erros Cometidos (Memória Global)

Para garantir que não repitamos os mesmos erros nas próximas sessões de desenvolvimento do Roteirizador Pro, documentamos aqui os problemas enfrentados e a solução adequada.

## 1. Esquecer de "Hot Restart" / "Build" e Instalar após alterações (REGRA CRÍTICA)
**Erro:** Fazer alterações em arquivos cruciais do Flutter e esquecer de recompilar/reinstalar, fazendo com que o usuário teste uma versão defasada do aplicativo e ache que as mudanças não foram aplicadas (ex: testes do Maestro falsos-positivos porque testam código antigo).
**Solução:** SEMPRE que houver alteração de código Flutter (UI ou lógica), ANTES de finalizar a sessão, garanta que o app foi reconstruído e instalado no aparelho do usuário (ex: rodando `flutter build apk --debug` e `adb install -r ...`). Nunca assuma que o usuário fará isso por conta própria, a menos que ele explicitamente peça para não fazer. Sempre entregue a versão compilada rodando no celular dele antes de dar a tarefa como concluída!

## 2. Persistência de Sessão e Segredos do Android (`flutter_secure_storage`)
**Erro:** Confiar apenas em `TokenStorage` (com `encryptedSharedPreferences: true` no Android) para guardar preferências simples como "Lembrar-me" e e-mail. Se o app for reinstalado, problemas no Android KeyStore podem limpar esses tokens de maneira imprevisível durante desenvolvimento.
**Solução:** 
- Para dados sensíveis (tokens): Manter no `flutter_secure_storage`.
- Para dados não sensíveis e configurações (ex: booleanos de interface, e-mail lembrado): Utilizar `SharedPreferencesAsync` (pacote `shared_preferences: ^2.5.5`).

## 3. Ignorar a barreira de Proteção de Arquivos Críticos (`01-secrets-and-self-mod.md`)
**Erro:** Tentar adicionar chaves (ex: Google Maps API Key) diretamente nos arquivos protegidos (como `.env` e `key.properties`) usando `sed`, `echo` ou edição direta, sem a permissão expressa ou em violação das regras.
**Solução:** O Antigravity não possui hook de pré-execução, então a barreira sou eu (o agente). **Nunca edite `.env` ou chaves de produção**. Sempre instrua o usuário a adicioná-los manualmente e recuse de forma clara pedidos que solicitem a edição automatizada desses arquivos por questões de segurança.

## 4. UI e "Overlapping" (Sobreposição) de Componentes no Mapa
**Erro:** Fixar valores absolutos pequenos para BottomSheets ou margens (`buttonsBottom = sheetHeightPx + 16`) sem considerar o inset do sistema (Navigation Bar / safe area) ou o tamanho real dos ícones, causando sobreposição (overlapping) da BottomSheet em botões do mapa (como o botão de centrar).
**Solução:** Sempre adicionar clearance/margens extras dinamicamente (ex: `+ 48` ao invés de `+ 16`), utilizar SafeArea/Bottom Padding do `MediaQuery`, e testar com tamanhos reais de componentes flutuantes para garantir que subam junto com o BottomSheet de maneira correta (ex: `DraggableScrollableSheet`).

## 5. Falta de MCP/Busca para Boas Práticas
**Erro:** Travar ao tentar adivinhar a implementação de um pacote ou framework, em vez de buscar a documentação oficial com `context7` (search_web).
**Solução:** Sempre usar o `search_web` (ou tool apropriado) ou ferramentas de MCP quando em dúvida sobre uma API específica de Flutter, Riverpod, etc, pois a base de dados de treinamento pode estar desatualizada (como especificado no `CLAUDE.md`).
