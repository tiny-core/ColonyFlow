# Phase 07: Auto-Setup + Compatibilidade MP

## Objetivo

Reduzir atrito de instalação/atualização e garantir operação previsível em singleplayer e multiplayer:

- `config.ini` ausente → gerar com defaults
- Diagnóstico acionável de periféricos e permissões

## Escopo

- Gerar `config.ini` com defaults na primeira execução, preservando o arquivo do usuário nas execuções seguintes.
- Logar “defaults aplicados” de forma explícita.
- Checklist de multiplayer e ajustes de robustez onde necessário.

## Fora de escopo

- Equivalências padrão obrigatórias.

