# CCLib Architecture

![alt text](resources/image.png)

## Estrutura de pastas

```text
cclib/
├── main.lua
├── CCLIB.md
├── core/
│   ├── const.lua
│   ├── class.lua
│   ├── guard.lua
│   ├── result.lua
│   ├── str.lua
│   ├── tbl.lua
│   ├── math.lua
│   ├── fmt.lua
│   ├── state.lua
├── system/
│   ├── log.lua
│   ├── event.lua
│   ├── timer.lua
│   ├── peripheral.lua
│   ├── snapshot.lua
│   ├── session.lua
├── state/
│   ├── store.lua
│   ├── persist.lua
│   ├── migrate.lua
├── ui/
│   ├── screen.lua
│   ├── router.lua
│   ├── theme.lua
│   ├── base.lua
│   └── components/
│       ├── button.lua
│       ├── label.lua
│       ├── input.lua
│       ├── table.lua
│       ├── grid.lua
│       ├── progress.lua
│       ├── spinner.lua
│       ├── toggle.lua
│       ├── modal.lua
│       ├── toast.lua
│       ├── tabs.lua
│       ├── selector.lua
│       ├── chart.lua
│       ├── sparkline.lua
└── lang/
    └── init.lua
    └── pt_BR.lua
    └── en.lua

```	