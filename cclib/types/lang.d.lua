---@meta
---@version 1.0.0
-- cclib / types / lang.d.lua
-- Definições de tipo para lang/init.lua e estrutura das tabelas de tradução.

-- ── Estrutura das tabelas de tradução ────────────────────────────────────────
-- Reflecte a estrutura de en.lua e pt_BR.lua.
-- Usar como referência ao criar um novo ficheiro de idioma.

---@class CCLib.Lang.Guard
---@field must_be         string  -- "'%s' deve ser %s, recebeu %s"
---@field must_not_be_nil string  -- "'%s' não pode ser nil"
---@field must_be_between string  -- "'%s' deve estar entre %s e %s, recebeu %s"
---@field must_be_one_of  string  -- "'%s' deve ser um de [%s], recebeu '%s'"

---@class CCLib.Lang.Log
---@field level_debug string
---@field level_info  string
---@field level_warn  string
---@field level_error string
---@field level_fatal string
---@field rotated     string
---@field closed      string

---@class CCLib.Lang.Session
---@field started string
---@field stopped string  -- Formato: "... após %d ciclos"
---@field error   string

---@class CCLib.Lang.Peripheral
---@field found        string
---@field lost         string
---@field not_found    string
---@field scan_done    string
---@field monitor_size string

---@class CCLib.Lang.Store
---@field created       string
---@field watcher_limit string
---@field reset         string

---@class CCLib.Lang.Persist
---@field saved     string
---@field loaded    string
---@field not_found string
---@field corrupted string
---@field no_backup string
---@field save_all  string

---@class CCLib.Lang.Migrate
---@field already_at     string
---@field migrating      string
---@field applying       string
---@field done           string
---@field not_registered string
---@field failed         string
---@field downgrade      string

---@class CCLib.Lang.CCLib
---@field name       string
---@field version    string
---@field guard      CCLib.Lang.Guard
---@field log        CCLib.Lang.Log
---@field session    CCLib.Lang.Session
---@field peripheral CCLib.Lang.Peripheral
---@field store      CCLib.Lang.Store
---@field persist    CCLib.Lang.Persist
---@field migrate    CCLib.Lang.Migrate

---@class CCLib.Lang.Button
---@field ok      string
---@field cancel  string
---@field confirm string
---@field back    string
---@field close   string
---@field save    string
---@field delete  string
---@field edit    string
---@field add     string
---@field remove  string
---@field yes     string
---@field no      string
---@field next    string
---@field prev    string
---@field submit  string
---@field reset   string
---@field refresh string
---@field search  string
---@field select  string
---@field clear   string
---@field apply   string
---@field loading string

---@class CCLib.Lang.Label
---@field error    string
---@field warning  string
---@field info     string
---@field success  string
---@field empty    string
---@field none     string
---@field all      string
---@field total    string
---@field page     string  -- Formato: "Página %d de %d"
---@field item     string
---@field items    string
---@field selected string  -- Formato: "%d selecionado(s)"
---@field required string
---@field optional string
---@field new      string
---@field unknown  string

---@class CCLib.Lang.Input
---@field placeholder string
---@field required    string
---@field too_long    string  -- Formato: "máx. %d caracteres"
---@field too_short   string
---@field invalid     string

---@class CCLib.Lang.Table
---@field empty     string
---@field loading   string
---@field row_count string

---@class CCLib.Lang.Modal
---@field confirm_title string
---@field confirm_msg   string
---@field delete_title  string
---@field delete_msg    string
---@field error_title   string
---@field info_title    string

---@class CCLib.Lang.Toast
---@field saved   string
---@field deleted string
---@field error   string
---@field copied  string
---@field updated string
---@field created string
---@field failed  string

---@class CCLib.Lang.UI
---@field button   CCLib.Lang.Button
---@field label    CCLib.Lang.Label
---@field input    CCLib.Lang.Input
---@field table    CCLib.Lang.Table
---@field modal    CCLib.Lang.Modal
---@field toast    CCLib.Lang.Toast
---@field tabs     { prev: string, next: string }
---@field progress { label: string }
---@field selector { choose: string }

---@class CCLib.Lang.Time
---@field day      string
---@field night    string
---@field sunrise  string
---@field sunset   string
---@field second   string
---@field seconds  string
---@field minute   string
---@field minutes  string
---@field hour     string
---@field hours    string
---@field ago      string  -- Formato: "há %s"
---@field in_time  string  -- Formato: "em %s"
---@field just_now string
---@field mc       { tick: string, day: string }

---@class CCLib.Lang.Status
---@field online  string
---@field offline string
---@field busy    string
---@field idle    string
---@field ready   string
---@field running string
---@field stopped string
---@field error   string
---@field unknown string

--- Tabela completa de um ficheiro de idioma.
--- Use esta classe ao criar `lang/xx.lua` — o LSP valida a estrutura.
---@class CCLib.Lang.Table
---@field cclib  CCLib.Lang.CCLib
---@field ui     CCLib.Lang.UI
---@field time   CCLib.Lang.Time
---@field status CCLib.Lang.Status

-- ── Resultado de inspeção ─────────────────────────────────────────────────────

---@class CCLib.Lang.InspectResult
---@field current   string            -- Código do idioma ativo
---@field fallback  string            -- Código do idioma de fallback
---@field languages table<string, integer>  -- Mapa código → número de chaves folha
---@field cacheSize integer          --  Entradas no cache de lookups

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Lang
local Lang = {}

--- Regista uma tabela de traduções com um código de idioma.
--- Pode ser chamado várias vezes com o mesmo código — faz merge.
---
--- ```lua
--- Lang.register("pt_BR", require("lang.pt_BR"))
--- Lang.register("en",    require("lang.en"))
--- ```
---@param code         string             -- Código do idioma, ex: `"pt_BR"`, `"en"`
---@param translations CCLib.Lang.Table   -- Tabela de traduções
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
--- Lang.get("ui.button.ok")           -- "OK"
--- Lang.get("ui.label.page", 2, 10)   -- "Página 2 de 10"
--- Lang.get("chave.inexistente")      -- "chave.inexistente"
--- ```
---@param key string  -- Chave em notação de ponto
---@param ... any     -- Argumentos de interpolação printf
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
---   app = { title = "Meu Projeto", version = "v1.2" },
---   ui  = { button = { ok = "Entendido" } },
--- })
--- ```
---@param translations table   -- Subconjunto das traduções a sobrescrever
---@param code?        string  -- Idioma alvo (default: ativo)
function Lang.merge(translations, code) end

--- Define uma única chave de nível raiz.
---@param key   string
---@param value any
---@param code? string  -- Idioma alvo (default: ativo)
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
