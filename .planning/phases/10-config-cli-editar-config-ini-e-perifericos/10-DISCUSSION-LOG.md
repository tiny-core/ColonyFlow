# Phase 10: Config CLI (editar config.ini e perifericos) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 10-config-cli-editar-config-ini-e-perifericos
**Areas discussed:** Edicao do config.ini, Perifericos, Comandos/UX, Backup/rollback

---

## Edicao do config.ini

| Option | Description | Selected |
|--------|-------------|----------|
| So [peripherals] | Focado em nomes de perifericos/monitores/modem; o resto continua manual. | |
| Peripherals + operacao | [peripherals] + poucas chaves mais usadas (core.poll_interval_seconds, core.log_level, delivery.export_mode/export_direction). | |
| Tudo (todas as secoes) | Editor generico de INI: qualquer secao/chave. | |
| Peripherals + lista custom | Definir agora quais chaves entram no menu e travar esse conjunto no CLI. | ✓ |

**User's choice:** Peripherals + lista custom
**Notes:** Blocos escolhidos depois: core+logs e delivery.

### Blocos alem de [peripherals]

| Option | Description | Selected |
|--------|-------------|----------|
| core + logs | poll_interval_seconds, ui_refresh_seconds, log_level, log_dir, log_max_files, log_max_kb | ✓ |
| delivery | default_target_container, export_mode, export_direction, export_buffer_container, destination_cache_ttl_seconds | ✓ |
| cache | max_entries, default_ttl_seconds, me_*_ttl_seconds | |
| substitution/tiers/MC | substitution.*, tiers.*, minecolonies.* e progression.* | |

**User's choice:** core + logs, delivery

### Estrategia de salvar

| Option | Description | Selected |
|--------|-------------|----------|
| Patch in-place | Altera so linhas key= e insere faltantes; preserva comentarios, ordem e chaves desconhecidas. | ✓ |
| Regerar do template | Reescreve o arquivo inteiro a partir de um template padrao + valores. | |
| Arquivo novo + trocar | Gera config.new.ini e so troca se confirmar; antigo vira backup. | |
| Sem preservar comentarios | Escreve INI minimo, sem comentarios. | |

**User's choice:** Patch in-place

### Validacao de valores

| Option | Description | Selected |
|--------|-------------|----------|
| Bloquear e explicar | Nao salva; mostra erro e exemplos validos. | ✓ |
| Salvar mesmo assim | Salva qualquer string; o runtime lida. | |
| Salvar mas avisar | Salva, mas marca como WARN e sugere correcao. | |
| Auto-corrigir | Corrige (clamp/default) e salva o corrigido. | |

**User's choice:** Bloquear e explicar

---

## Perifericos: listar/validar

### Ajuda para escolher nomes

| Option | Description | Selected |
|--------|-------------|----------|
| Lista + escolher | Mostra peripheral.getNames() e escolha manual. | |
| Sugerir + confirmar | Auto-detect por tipo, sugere e pede confirmacao/ajuste. | ✓ |
| Auto-aplicar | Auto-detect e grava sem perguntar. | |
| So avisar | Apenas mostra erro/hint, sem ajuda. | |

**User's choice:** Sugerir + confirmar

### Nivel de validacao

| Option | Description | Selected |
|--------|-------------|----------|
| Presenca + wrap | isPresent + wrap; evita falsos negativos. | ✓ |
| Checar metodos | Verifica metodos minimos e falha se faltar. | |
| So presenca | Apenas isPresent. | |
| Checar tipo exato | Exige getType bater exatamente. | |

**User's choice:** Presenca + wrap

### Monitores duplicados

| Option | Description | Selected |
|--------|-------------|----------|
| Impedir | Nao deixa salvar se monitor_requests == monitor_status. | ✓ |
| Permitir | Deixa igual, operador assume risco. | |
| Permitir com aviso | Deixa salvar, mas avisa com WARN. | |
| Auto-ajustar | Se iguais, tenta escolher outro automaticamente. | |

**User's choice:** Impedir

### Fluxo

| Option | Description | Selected |
|--------|-------------|----------|
| Editar -> Testar -> Salvar | Sempre testa (discover) antes de gravar; salva so se OK. | ✓ |
| Editar -> Salvar -> Testar | Salva primeiro e depois diagnostica. | |
| Editar apenas | Sem teste. | |
| Testar apenas | Modo doctor sem editar. | |

**User's choice:** Editar -> Testar -> Salvar

---

## Comandos e UX do CLI

### Invocacao

| Option | Description | Selected |
|--------|-------------|----------|
| startup config | Novo modo no startup.lua chamando modules/config_cli.lua. | ✓ |
| startup cfg | Atalho curto. | |
| tools/config.lua | Rodar direto sem mexer no startup.lua. | |
| Integrar no startup map | Mesclar mapeamentos + config num unico menu. | |

**User's choice:** startup config

### Menu principal

| Option | Description | Selected |
|--------|-------------|----------|
| Menu por bloco | Perifericos | Core+Logs | Delivery | Sair | ✓ |
| Wizard guiado | Passo a passo e no final confirma e salva. | |
| Busca por chave | Lista com filtro/busca. | |
| So perifericos | O resto fica fora por enquanto. | |

**User's choice:** Menu por bloco

### Local do arquivo

| Option | Description | Selected |
|--------|-------------|----------|
| modules/config_cli.lua | Mesmo padrao do mapping_cli. | ✓ |
| tools/config.lua | Como ferramenta junto do install.lua. | |
| components/ | Nao recomendado. | |
| lib/ | Nao recomendado. | |

**User's choice:** modules/config_cli.lua

### Cores

| Option | Description | Selected |
|--------|-------------|----------|
| Usar cores se disponivel | term.isColor() decide; fallback mono. | ✓ |
| Sempre monocromatico | Simplifica. | |
| Config no ini | Flag para habilitar/desabilitar. | |
| Voce decide | Claude decide. | |

**User's choice:** Usar cores se disponivel

---

## Backup/rollback e seguranca

### Quando criar backup

| Option | Description | Selected |
|--------|-------------|----------|
| Sempre antes de salvar | Garante rollback; custo baixo. | ✓ |
| So quando houver mudanca | Backup apenas se tiver diff. | |
| Opcional por confirmacao | Pergunta antes de salvar. | |
| Nao criar | Sem backup. | |

**User's choice:** Sempre antes de salvar

### Onde guardar backups

| Option | Description | Selected |
|--------|-------------|----------|
| data/backups/ | Pasta dedicada com timestamp. | ✓ |
| logs/ | Mistura com logs. | |
| tools/backups/ | Mistura com ferramentas. | |
| Ao lado do arquivo | config.ini.bak na raiz. | |

**User's choice:** data/backups/

### Estrategia de gravacao

| Option | Description | Selected |
|--------|-------------|----------|
| Escrever .tmp e trocar | Escreve config.ini.tmp e troca; reduz corrupcao. | ✓ |
| Escrever direto | Mais simples, mais risco. | |
| Gerar .new e confirmar | config.new.ini e confirma. | |
| Voce decide | Claude decide. | |

**User's choice:** Escrever .tmp e trocar

### Preview

| Option | Description | Selected |
|--------|-------------|----------|
| Lista de chaves alteradas | secao.chave: antigo -> novo. | ✓ |
| Diff linha-a-linha | Patch verboso. | |
| Sem preview | So confirma salvar. | |
| Voce decide | Claude decide. | |

**User's choice:** Lista de chaves alteradas

---

## Claude's Discretion

- Heuristica de auto-detect quando houver multiplos candidatos por tipo.
- Layout exato do menu/atalhos, mantendo consistencia com o estilo do mapping_cli.
