# Phase 09: Instalador In-Game (Git)

## Objetivo

Permitir instalar e atualizar o sistema dentro do jogo com um script único, baixando os arquivos do repositório via HTTP.

## Escopo

- Script `install.lua` com:
  - instalação inicial
  - atualização (overwrite apenas em arquivos “gerenciados”)
  - preservação por padrão de `config.ini` e `data/mappings.json`
- Manifesta de arquivos (lista fixa ou baixada do repositório).
- Mensagens claras para erros comuns:
  - HTTP desativado
  - URL inválida
  - falta de permissão/espaco em disco

## Fora de escopo

- Assinatura criptográfica completa (pode ser adicionada depois).

