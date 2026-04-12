# MineColonies ME Automation

Automação in-world (Lua) para **CC: Tweaked** em um **Advanced Computer**, integrando **MineColonies**, **Applied Energistics 2 (ME/AE2)** e **Advanced Peripherals** para fechar o ciclo completo:

1. Ler requisições pendentes da colônia
2. Validar disponibilidade real (ME + destino)
3. Solicitar autocrafting apenas do faltante
4. Entregar automaticamente ao destino correto
5. Exibir operação em UI ASCII (2 monitores) e registrar logs estruturados

## Recursos

- **Requisições MineColonies**: normalização e fila de processamento
- **Integração ME Bridge (AE2)**: consulta de estoque, craftabilidade e abertura de jobs
- **Entrega automática**: validação do destino antes de craftar e entrega pós-craft
- **Equivalências entre mods + tiers**: resolver de candidatos e tier gating por building/worker
- **UI dual-monitor**: um painel para fila e outro painel misto (operação/colônia/estoque crítico)
- **Logs em português** com rotação
- **Testes** via `startup test`
- **Instalador/atualizador in-game** via HTTP (raw Git) com update seguro e rollback

## Pré-requisitos (Mods/Periféricos)

- **CC: Tweaked**
  - Recomenda-se **Advanced Computer**
  - Para o instalador: **HTTP habilitado** no modpack/servidor
- **MineColonies** (com periférico integrável via Advanced Peripherals)
- **Applied Energistics 2** + **Advanced Peripherals** (ME Bridge)
- **Modem** (rede)
- **2× Advanced Monitor** (recomendado) para a UI
- Inventários/destinos conectados como periféricos (baús, interfaces, etc.)

## Estrutura do Projeto

O computador mantém apenas:

- `startup.lua`
- `config.ini`

O restante fica em subpastas:

- `lib/` utilitários, config, bootstrap, logger, cache
- `modules/` engine, minecolonies, me, scheduler, tiers/equivalências, periféricos
- `components/` UI
- `tools/` ferramentas (ex.: instalador)
- `tests/` test runner
- `data/` dados do usuário (ex.: `mappings.json`)

## Instalação (recomendado): Instalador in-game (HTTP / raw Git)

O instalador suporta `doctor`, `install` e `update`. Ele baixa os arquivos definidos no `manifest.json`, faz download em temporário, cria snapshot e aplica com rollback automático em falhas.

### 1) Bootstrap em computador “limpo”

No computador vazio:

```bash
wget run https://raw.githubusercontent.com/OWNER/REPO/main/tools/install.lua install --repo OWNER/REPO --ref main
```

- Substitua `OWNER/REPO` pelo repositório.
- Se você usa outra branch/tag/commit, troque `--ref`.

### 2) Configuração do instalador (persistida)

O comando acima grava/atualiza:

- `data/install.json` (config do instalador)
- `data/version.json` (ref instalada + lista de arquivos gerenciados)

Também é possível configurar manualmente `data/install.json`:

```json
{
  "base_url": "https://raw.githubusercontent.com/OWNER/REPO/",
  "ref": "main",
  "manifest_path": "manifest.json"
}
```

### 3) Diagnóstico

```bash
tools/install.lua doctor
```

Se HTTP estiver desabilitado, o `doctor` deve explicar o que habilitar.

### 4) Atualização

```bash
tools/install.lua update
```

Preservados por padrão:

- `config.ini`
- `data/mappings.json`
- `data/install.json`
- `data/version.json`

## Execução e Comandos

### Rodar o sistema

No computador:

```bash
startup
```

### Testes

```bash
startup test
```

### Editor de mapeamentos (equivalências/tiers)

```bash
startup map
```

## Configuração (alto nível)

- `config.ini`: parâmetros de operação, periféricos, timeouts, UI/logs
- `data/mappings.json`: base de equivalências e overrides de tier (formato v2)

## Checklist de validação (Fase 09)

Os testes manuais do instalador estão em:

- [.planning/phases/09-instalador-git/09-VERIFICATION.md](file:///d:/Game/Minecraft/Instances/All%20the%20Mods%2010%20-%20ATM10/saves/Tests/computercraft/computer/0/.planning/phases/09-instalador-git/09-VERIFICATION.md)
- [.planning/phases/09-instalador-git/09-HUMAN-UAT.md](file:///d:/Game/Minecraft/Instances/All%20the%20Mods%2010%20-%20ATM10/saves/Tests/computercraft/computer/0/.planning/phases/09-instalador-git/09-HUMAN-UAT.md)

## Desenvolvimento / Contribuição

- Preferir mudanças pequenas e commits atômicos.
- Manter mensagens e logs em português.
- Rodar `startup test` após mudanças em módulos críticos.

