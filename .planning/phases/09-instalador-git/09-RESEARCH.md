# Phase 09: Instalador In-Game (Git) — Research

## Summary

Esta fase implementa um instalador/atualizador in-world para CC: Tweaked baseado em HTTP (raw Git), com update seguro (2 fases + snapshot + rollback) e preservação por padrão de `config.ini`, `data/mappings.json`, `data/install.json` e `data/version.json`.

## CC: Tweaked / HTTP - Pontos práticos

- **HTTP pode estar desabilitado** por configuração do servidor/modpack. Quando `http` não existir ou estiver bloqueado, o instalador deve explicar *o que habilitar* e *o porquê*.
- `wget` normalmente está disponível e usa a mesma base de HTTP. Para o “bootstrap” em máquina limpa, `wget run <raw-url>/tools/install.lua install` é o caminho padrão.
- `http.get(url)` pode retornar `nil, err`; e o handle pode expor `readAll()`, `close()` e `getResponseCode()` (quando disponível). O instalador deve tratar ausência de `getResponseCode()` e validar pelo menos “conteúdo não vazio”.

## Design do Manifesto

Para suportar update seguro e remoção de órfãos, o manifesto remoto precisa ser determinístico e conter ao menos:

- `manifest_version` (inteiro)
- `files[]` com:
  - `path` (string; caminho relativo no disco do computador)
  - `size` (opcional; inteiro; valida truncamento/corrupção simples)

O manifesto **lista apenas arquivos gerenciados** (os que podem ser sobrescritos/deletados pelo update). Arquivos preservados por padrão continuam existindo no disco, mas:

- podem estar no manifesto para instalação inicial, desde que o instalador trate como “preservar se existir”
- não devem ser deletados como órfãos

## Update seguro (2 fases)

Estratégia recomendada alinhada ao contexto:

1. **Download/validação** para um diretório temporário (ex.: `data/.install_tmp/<ts>/...`)
2. **Snapshot backup** dos arquivos que serão alterados/deletados (ex.: `data/backups/<ts>/...`)
3. **Aplicar**: escrever/copiar do temporário para o destino final (skip para preservados existentes)
4. **Órfãos**: deletar arquivos que estavam na lista “gerenciada anterior” e não estão no manifesto novo (exceto preservados)
5. **Persistir versão** em `data/version.json` contendo ref instalada + lista de gerenciados (para comparação futura)
6. **Falha em qualquer etapa**: rollback automático a partir do snapshot

## Tratamento de erros (mensagens acionáveis)

Casos principais que precisam de mensagens claras:

- HTTP desabilitado / API `http` ausente
- URL inválida ou bloqueada (erro do `http.checkURL` quando existir)
- Falha de download/timeout
- Conteúdo vazio (possível 404 ou redirecionamento não seguido)
- Falta de espaço em disco (usar `fs.getFreeSpace("/")` quando aplicável)
- Permissão/FS inválido (falha ao `fs.open`/`fs.makeDir`)

## Validation Architecture

**Automatizado (rápido):**

- `startup test` deve continuar passando.
- Adicionar testes unitários para o instalador (mock de `http` e `fs`) é desejável, mas não é obrigatório se o custo de mock for alto no ambiente CC.

**Manual (in-world) — obrigatório para esta fase:**

1. **Bootstrap em computador limpo**: executar via `wget run` e confirmar instalação e boot do sistema.
2. **Update preservando config/dados**: editar `config.ini` e `data/mappings.json`, rodar update e confirmar preservação.
3. **Falha de HTTP**: desabilitar HTTP e rodar `doctor`/`install`, confirmar mensagem acionável.

Mapeamento de validação por requisito:

- **CFG-01**: confirma que a instalação final mantém apenas `startup.lua` e `config.ini` na raiz, com o restante em subpastas.
- **ROB-01**: confirma que falhas não travam o computador e sempre produzem diagnóstico + saída limpa, sem “estado meio aplicado”.

