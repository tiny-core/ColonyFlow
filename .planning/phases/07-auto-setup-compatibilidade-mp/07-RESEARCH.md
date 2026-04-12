# Phase 07 — Research: Auto-Setup + Compatibilidade MP

## Estado atual (baseline)

- `lib/bootstrap.lua` carrega `config.ini` via `Config.load("config.ini")`, mas **não cria** o arquivo quando ausente.
- `lib/config.lua` faz parse INI e retorna `data={}` quando o arquivo não existe; não há mecanismo de “defaults aplicados/criados”.
- `modules/peripherals.lua` tenta resolver periféricos via (1) nome no config e (2) `peripheral.find(type)`. Quando falha, loga apenas “Periférico não encontrado: …” e retorna `issues` genéricas.
- `modules/equivalence.lua` lê `data/mappings.json` fixo; se não existir, o DB vira `{}` (sem estrutura mínima garantida).

## Objetivos técnicos da fase (o que precisa mudar)

### CFG-02 — Auto-geração do `config.ini`

- Criar `config.ini` **somente quando ausente**, com um template padrão (o mesmo formato/keys que o projeto já usa).
- Preservar o arquivo do usuário em execuções seguintes (nunca sobrescrever).
- Registrar em log, de forma explícita, que o arquivo foi criado e **quais chaves/valores** foram gerados como default.

### CFG-03 — Mapeamentos via JSON (robustez do arquivo)

- Garantir que `data/mappings.json` existe com estrutura mínima válida quando ausente (skeleton), para evitar comportamento “vazio” inesperado (principalmente quando `allow_unmapped_mods=false`).
- Manter compatibilidade com o que `modules/equivalence.lua` já espera: `items`, `classes`, `tier_overrides`, `gating.by_building_type`.

### ROB-02 — Compatibilidade multiplayer (diagnóstico + fail previsível)

- Melhorar diagnóstico quando periféricos não são encontrados, distinguindo:
  - Nome configurado inválido vs. periférico inexistente.
  - Falta de modem/rede vs. periférico fora do alcance.
  - Possível restrição/permite do servidor (cenários MP).
- Evitar exceções de discovery (usar `pcall` ao envolver `peripheral.find`, `peripheral.wrap`, `peripheral.getNames`) e degradar com mensagens acionáveis.

## Proposta de abordagem

### 1) `Config.ensureDefaults(path)` antes de `Config.load`

- Implementar em `lib/config.lua`:
  - Uma constante/template `DEFAULT_INI` (string multi-linha) contendo o `config.ini` padrão.
  - Uma função `ensureDefaults(path)` que:
    - Se `fs.exists(path)` → retorna `{ created=false }`.
    - Se não existir → escreve o template e retorna `{ created=true, defaults=parseIni(DEFAULT_INI) }`.
    - Se falhar em escrever → retorna `{ created=false, err="..." }` (o bootstrap loga e segue com `Config.load`).
- No `lib/bootstrap.lua`, chamar `Config.ensureDefaults("config.ini")` **antes** de `Config.load`.
- Após criar o logger, se `created=true`, logar:
  - “config.ini criado com defaults”
  - As chaves principais por seção (ex.: `[core] log_level=INFO`, etc.).

### 2) “Skeleton” do `data/mappings.json`

- Estratégia mínima: ao inicializar o Equivalence, se o arquivo não existir:
  - Criar um JSON com os campos esperados vazios.
  - Logar uma vez (INFO/WARN) informando onde editar e que hot-reload já existe.

### 3) Diagnóstico de periféricos mais acionável

- Em `modules/peripherals.lua`:
  - Criar helper para coletar `peripheral.getNames()` com `pcall` e limitar o tamanho do log (exibir apenas os primeiros N nomes).
  - Ao falhar:
    - Incluir `key`, `typeName`, `config.ini` (seção + chave), e `name` configurado (se houver).
    - Sugerir ação: “Atualize `[peripherals] {key}=...`”.
    - Para modem ausente: explicar impacto (“rede de periféricos pode não funcionar”) e indicar que, em MP, o servidor pode restringir acesso.

## Riscos e mitigação

- **Risco:** sobrescrever config do usuário ao atualizar template.
  - **Mitigação:** escrever apenas quando `fs.exists("config.ini")` for false.
- **Risco:** logs gigantes ao listar periféricos disponíveis.
  - **Mitigação:** truncar lista e registrar contagem total.
- **Risco:** ambientes MP com permissões diferentes quebrarem discovery por erro.
  - **Mitigação:** `pcall` e mensagens claras, mantendo operação degradada.

## Verificações recomendadas

- Teste automatizado: simular `fs.exists=false` e capturar conteúdo escrito para validar que inclui seções/keys essenciais.
- Teste automatizado: simular ausência de `data/mappings.json` e garantir que o Equivalence inicializa DB com campos esperados.
- Teste manual (in-world):
  - Remover/renomear `config.ini` → reiniciar → confirmar que foi criado e logado.
  - Remover/renomear `data/mappings.json` → reiniciar → confirmar criação e que hot-reload continua funcional ao editar.
  - Em MP, desconectar modem/periférico → confirmar mensagens acionáveis e sem crash.

