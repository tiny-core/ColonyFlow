local args = { ... }

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

local ok, bootstrap = pcall(require, "lib.bootstrap")
if not ok then
  print("Falha ao carregar bootstrap: " .. tostring(bootstrap))
  return
end

bootstrap.run()
