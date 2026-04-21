-- Ponto de entrada do sistema (CC: Tweaked).
-- Suporta modos operacionais via argumento:
-- - `startup test`   -> roda o harness em tests/run.lua
-- - `startup map`    -> abre o editor de mapeamentos
-- - `startup config` -> abre a CLI de configuração
-- - `startup doctor` -> diagnóstico rápido do ambiente
-- Sem argumento: carrega lib/bootstrap.lua e inicia o loop principal.

local args = { ... }

if shell and type(shell.setDir) == "function" then
  shell.setDir("/")
end

local function runTests()
  if fs.exists("tests/run.lua") then
    shell.run("tests/run.lua")
    return
  end
  print("Pasta tests/ não encontrada.")
end

local function runMappingCli()
  if fs.exists("modules/mapping_cli.lua") then
    shell.run("modules/mapping_cli.lua")
    return
  end
  print("CLI de mapeamentos não encontrada.")
end

local function runConfigCli()
  if fs.exists("modules/config_cli.lua") then
    shell.run("modules/config_cli.lua")
    return
  end
  print("CLI de config nao encontrado.")
end

local function runDoctor()
  if fs.exists("modules/doctor.lua") then
    shell.run("modules/doctor.lua")
    return
  end
  print("Doctor nao encontrado.")
end

local mode = args[1]
if mode == "test" then
  runTests()
  return
end

if mode == "map" then
  runMappingCli()
  return
end

if mode == "config" then
  runConfigCli()
  return
end

if mode == "doctor" then
  runDoctor()
  return
end

if type(package) == "table" and type(package.loaded) == "table" then
  for k in pairs(package.loaded) do
    if type(k) == "string" then
      if k:sub(1, 4) == "lib." or k:sub(1, 8) == "modules." or k:sub(1, 11) == "components." then
        package.loaded[k] = nil
      end
    end
  end
end

local ok, bootstrap = pcall(require, "lib.bootstrap")
if not ok then
  print("Falha ao carregar bootstrap: " .. tostring(bootstrap))
  return
end

print("Sistema iniciado com sucesso.")
bootstrap.run()
