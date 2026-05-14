---@meta
---@version 1.0.0
-- cclib / types / lang.d.lua
-- Definições de tipo para lang/init.lua e estrutura das tabelas de tradução.

-- ── Resultado de inspeção ─────────────────────────────────────────────────────

---@class CCLib.Lang.InspectResult
---@field current string -- Código do idioma ativo
---@field fallback string -- Código do idioma de fallback
---@field languages table<string, integer> -- Mapa código → número de chaves folha
---@field cacheSize integer -- Entradas no cache de lookups

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Lang
local Lang = {}

--- Regista uma tabela de traduções com um código de idioma.
--- Pode ser chamado várias vezes com o mesmo código — faz merge.
---
--- ```lua
--- Lang.register("pt_BR", require("lang.pt_BR"))
--- Lang.register("en", require("lang.en"))
--- ```
---@param code string -- Código do idioma, ex: `"pt_BR"`, `"en"`
---@param translations table -- Tabela de traduções
function Lang.register(code, translations) end

--- Define o idioma ativo. Retorna `false, mensagem` se o código não foi registado.
---
--- ```lua
--- local ok, err = Lang.load("pt_BR")
--- if not ok then Log.warn("lang", err) end
--- ```
---@param code string
---@return boolean ok
---@return string? err -- Mensagem de erro se `ok` for false
function Lang.load(code) end

--- Define o idioma de fallback para quando uma chave não existe no ativo.
---@param code string -- (default `"en"`)
function Lang.setFallback(code) end

--- Retorna a tradução de uma chave com interpolação printf opcional.
--- Procura no idioma ativo → fallback → retorna a própria chave (nunca lança erro).
---
--- ```lua
--- Lang.get("ui.button.ok") -- "OK"
--- Lang.get("ui.label.page", 2, 10) -- "Página 2 de 10"
--- Lang.get("chave.inexistente") -- "chave.inexistente"
--- ```
---@param key string -- Chave em notação de ponto
---@param ... any -- Argumentos de interpolação printf
---@return string
function Lang.get(key, ...) end

--- Alias de `Lang.get`. Usa `local t = Lang.t` para um shortcut conveniente.
---@param key string
---@param ... any
---@return string
function Lang.t(key, ...) end

--- Retorna true se a chave existe no idioma ativo ou no fallback.
---@param key string
---@return boolean
function Lang.has(key) end

--- Faz merge de traduções no idioma ativo sem substituir toda a tabela.
--- Útil para projetos adicionarem strings próprias sem editar os ficheiros da lib.
---
--- ```lua
--- Lang.merge({
--- app = { title = "Meu Projeto", version = "v1.2" },
--- ui = { button = { ok = "Entendido" } },
--- })
--- ```
---@param translations table -- Subconjunto das traduções a sobrescrever
---@param code? string -- Idioma alvo (default: ativo)
function Lang.merge(translations, code) end

--- Define uma única chave de nível raiz.
---@param key string
---@param value any
---@param code? string -- Idioma alvo (default: ativo)
function Lang.set(key, value, code) end

--- Retorna o código do idioma ativo.
---@return string
function Lang.current() end

--- Retorna lista ordenada dos idiomas registados.
---@return string[]
function Lang.available() end

--- Repõe o idioma ativo ao fallback e limpa o cache.
function Lang.reset() end

--- Limpa o cache de lookups (após merge massivo).
function Lang.clearCache() end

--- Retorna métricas do motor i18n (para DEV inspector).
---@return CCLib.Lang.InspectResult
function Lang.inspect() end
