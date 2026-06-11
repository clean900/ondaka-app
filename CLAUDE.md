# ONDAKA Mobile — Contexto específico (Flutter)

> Lê primeiro o tronco comum em `~/.claude/CLAUDE.md` (comunicação, glossário PT-AO,
> regra de ouro do git, contas de produção). Este ficheiro cobre só o específico do mobile.

## Stack mobile
- Flutter + GetX (estado/rotas/DI) + Firebase FCM (push) + Pusher (realtime). Repo `clean900/ondaka-app`.
- Path: `~/ondaka-dev/ondaka_app/`.
- Estrutura: `lib/features/<feature>/{controllers,views,repositories,models}` + `lib/core/services` (api, auth, storage).
- Consome a API do backend Laravel (`ondaka-web`); não fala com a BD diretamente.

## Fluxo de trabalho / build
1. `[Mac]` editar código Dart
2. `[Mac]` validar: `flutter analyze` (e `flutter test` quando aplicável)
3. `[Mac]` `git add -A && git commit -m "..." && git push`
4. Build de release (APK/IPA) só quando for para distribuir — não vai por git pull como a web.
- Mantém commits pequenos (`fix:`, `feat:`). Git continua a ser a fonte de verdade.

## Padrões técnicos aprendidos
- **403 LiteSpeed em anexos:** trocar `/storage/` por `/ficheiros/` nos URLs de ficheiros
  (anexos de avisos, fotos de tickets, acta de assembleias, imagens de marketplace). O
  servidor bloqueia symlinks `/storage/` → o backend serve via `FicheirosController`.
- **Push (FCM):** notificações locais persistentes via `flutter_local_notifications`
  (canal `ondaka_default`, importance max) em foreground e background. Deep-link: tocar
  na notificação de aviso abre o detalhe do aviso.
- Glossário PT-AO aplica-se à UI tal como na web (Taxas de Condomínio, Pedidos, Imóvel…).

## Higiene do repo
- Existem vários `.bak-*` soltos na working tree de sessões anteriores. Não commitar `.bak`;
  preferir o git para histórico em vez de cópias `.bak` (limpar quando confirmado).
