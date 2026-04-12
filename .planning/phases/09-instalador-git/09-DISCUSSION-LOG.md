# Phase 09: Instalador In-Game (Git) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 09-instalador-git
**Areas discussed:** Fonte e versão, Manifesto e escopo, Preservação e segurança, UX e comandos

---

## Fonte e versão

### Por padrão, o instalador deve baixar de qual “ref” do repositório?

| Option | Description | Selected |
|--------|-------------|----------|
| Configurável (padrão main) | Default usa o branch principal, mas permite fixar tag/commit em config. | ✓ |
| Sempre main/latest | Mais simples: sempre pega o estado atual do branch principal. | |
| Sempre tag fixa | Mais estável: só atualiza quando você troca a tag manualmente. | |
| Sempre commit fixo | Máxima reprodutibilidade, mas é mais chato de manter. | |

### Onde o usuário define URL do repo e a ref (branch/tag/commit)?

| Option | Description | Selected |
|--------|-------------|----------|
| data/install.json | Arquivo dedicado do instalador, fácil de preservar no update. | ✓ |
| config.ini | Centraliza configurações, mas mistura “setup” com config operacional. | |
| Hardcoded no install.lua | Zero configuração, mas obriga editar o script para trocar repo/ref. | |
| Perguntar na hora | Interativo: pergunta URL/ref sempre que rodar. | |

### Suportar trocar para fork/URL custom sem editar código?

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, via config | Permite usar seu fork ou mirrors. | |
| Não, só oficial | Mais simples e reduz risco de baixar coisa errada. | ✓ |
| Só via argumentos | Permite, mas exige passar parâmetros toda vez. | |
| Você decide | Eu escolho a opção mais simples/segura durante o planejamento. | |

### Como o sistema registra “qual versão está instalada”?

| Option | Description | Selected |
|--------|-------------|----------|
| data/version.json | Grava ref + timestamp + manifest hash/size para auditoria. | ✓ |
| Arquivo .version na raiz | Simples, mas adiciona mais um arquivo na raiz além de startup/config. | |
| Somente em log | Não cria arquivo, só registra no log durante install/update. | |
| Não registrar | Sem tracking; só confia no estado do disco. | |

---

## Manifesto e escopo

### Como o instalador descobre a lista de arquivos para baixar?

| Option | Description | Selected |
|--------|-------------|----------|
| Baixa manifest do repo | O install.lua baixa um `manifest.json` (raw) e segue a lista/metadata. | ✓ |
| Lista embutida | Lista fixa dentro do `install.lua` (precisa atualizar o script quando mudar arquivos). | |
| Manifest + fallback | Tenta manifest remoto; se falhar, usa uma lista mínima embutida. | |
| Você decide | Eu escolho o mais simples/robusto durante o planejamento. | |

### Que validação o instalador deve fazer por arquivo?

| Option | Description | Selected |
|--------|-------------|----------|
| Tamanho (quando disponível) | Confere `#conteúdo` contra `size` do manifest; se não tiver size, valida HTTP + não vazio. | ✓ |
| Só HTTP + não vazio | Mais simples, mas detecta menos corrupção/truncamento. | |
| CRC32 no conteúdo | Checksum leve; mais segurança que tamanho, menos custo que SHA. | |
| SHA-256 | Hash forte, porém adiciona custo/complexidade em Lua puro. | |

### O que conta como “arquivo gerenciado” no update?

| Option | Description | Selected |
|--------|-------------|----------|
| Somente o que está no manifest | Update sobrescreve apenas caminhos explícitos do manifest. | ✓ |
| Pastas de código inteiras | Atualiza tudo em `lib/`, `modules/`, `components/`, `tests/` e `startup.lua`. | |
| Tudo exceto preservados | Atualiza quase tudo e preserva só `config.ini` e `data/mappings.json`. | |
| Você decide | Eu escolho a política mais segura durante o planejamento. | |

### No update, se um arquivo gerenciado NÃO existir mais no manifest, o instalador deve…

| Option | Description | Selected |
|--------|-------------|----------|
| Deletar o órfão | Mantém instalação “limpa” e evita lixo de versões antigas. | ✓ |
| Manter no disco | Evita apagar algo acidentalmente, mas acumula lixo. | |
| Perguntar antes | Interativo: pede confirmação (pode atrapalhar uso normal). | |
| Você decide | Eu escolho o trade-off mais adequado durante o planejamento. | |

---

## Preservação e segurança

### Além de `config.ini` e `data/mappings.json`, o que mais deve ser preservado por padrão em updates?

| Option | Description | Selected |
|--------|-------------|----------|
| Só config + mappings (+ install config) | Preserva `config.ini`, `data/mappings.json`, `data/install.json` e `data/version.json`. | ✓ |
| Preservar toda pasta data/ | Protege dados do usuário, mas pode manter lixo indefinidamente. | |
| Preservar também logs/ | Garante histórico de logs mesmo que algum dia vire gerenciado. | |
| Você decide | Eu escolho a política mais segura durante o planejamento. | |

### Como fazer backup/rollback durante update?

| Option | Description | Selected |
|--------|-------------|----------|
| Backup por pasta (snapshot) | Copia arquivos que serão alterados para `data/backups/<ts>/...` antes de aplicar. | ✓ |
| Backup por arquivo .bak | Cria `arquivo.lua.bak` ao lado antes de sobrescrever. | |
| Sem backup (apenas logs) | Mais simples, mas arriscado se der falha no meio. | |
| Você decide | Eu escolho o mínimo seguro durante o planejamento. | |

### Aplicação do update deve ser…

| Option | Description | Selected |
|--------|-------------|----------|
| 2 fases (download → aplicar) | Baixa tudo para temp, valida, depois aplica. | ✓ |
| Best-effort (aplica conforme baixa) | Menos disco/complexidade, mas pode deixar estado parcial. | |
| Híbrido | Baixa+valida por arquivo e aplica um a um. | |
| Você decide | Eu escolho o trade-off mais adequado durante o planejamento. | |

### Se der falha no meio (HTTP/validação/disco), o instalador deve…

| Option | Description | Selected |
|--------|-------------|----------|
| Rollback automático | Restaura backups e tenta voltar ao estado anterior. | ✓ |
| Parar e manter backup | Interrompe e deixa backup para rollback manual. | |
| Continuar com o que der | Tenta concluir mesmo com falhas (pode quebrar o sistema). | |
| Você decide | Eu escolho a resposta mais segura durante o planejamento. | |

---

## UX e comandos

### Num computador “limpo”, como executar o instalador pela primeira vez?

| Option | Description | Selected |
|--------|-------------|----------|
| wget run URL | Fornecer 1-liner `wget run <raw-url>/install.lua` (ou similar). | ✓ |
| pastebin get | Distribuir via Pastebin e rodar localmente. | |
| Snippet http.get | Instruções para colar um trecho que baixa e salva `install.lua`. | |
| Você decide | Eu escolho a forma mais simples/compatível durante o planejamento. | |

### Quais comandos/modos o `install.lua` deve oferecer?

| Option | Description | Selected |
|--------|-------------|----------|
| install / update / doctor | `install.lua install`, `install.lua update`, `install.lua doctor`. | ✓ |
| Só install / update | Sem modo diagnóstico dedicado. | |
| Só update (install=default) | Sem subcomando install; rodar sem args instala. | |
| Você decide | Eu escolho o conjunto mínimo útil durante o planejamento. | |

### Depois que o sistema estiver instalado, o que fazer com o `install.lua` no disco?

| Option | Description | Selected |
|--------|-------------|----------|
| Manter em tools/ | Move para `tools/install.lua` como ferramenta local de update. | ✓ |
| Manter na raiz | Deixa `install.lua` na raiz junto com `startup.lua` e `config.ini`. | |
| Auto-apagar | Remove o próprio `install.lua` após instalar. | |
| Você decide | Eu escolho a opção mais consistente com as constraints. | |

### Durante install/update, qual nível de feedback?

| Option | Description | Selected |
|--------|-------------|----------|
| Por arquivo + resumo | Mostra cada arquivo com status + resumo final. | ✓ |
| Resumo compacto | Só contadores e status final. | |
| Silencioso + logs | Pouco output; detalhes vão para logs/arquivo. | |
| Você decide | Eu escolho o equilíbrio padrão. | |

---

## Claude's Discretion

- Timeouts, retries e formato exato do resumo, mantendo mensagens acionáveis em PT-BR.
- Nome exato/formato do manifesto, desde que seja um único arquivo raw com caminhos e `size` opcional.

## Deferred Ideas

- Assinatura criptográfica completa do conteúdo (hash+assinatura) para hardening futuro.

