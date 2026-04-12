# Verificação: Phase 09

## Checklist

- [ ] Em um computador “limpo”: `wget run <raw-url>/tools/install.lua install` instala o sistema e o `startup.lua` roda sem crash.
- [ ] Após instalar, `tools/install.lua doctor` confirma HTTP disponível (ou mostra instrução acionável quando indisponível).
- [ ] `tools/install.lua update` não sobrescreve `config.ini` nem `data/mappings.json` por padrão (mostra `SKIP(preserved)` no output).
- [ ] Em update, arquivos órfãos (gerenciados na versão anterior e ausentes no manifesto novo) são removidos sem tocar preservados.
- [ ] Em falha de HTTP/URL inválida/permissão, o instalador imprime mensagem acionável (incluindo o erro) e sai limpo.
- [ ] Se falhar no meio do apply, o instalador executa rollback automático via snapshot e não deixa o sistema em estado parcial.
