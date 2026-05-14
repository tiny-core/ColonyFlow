-- cclib / lang / pt_BR.lua
-- Traduções em Português Brasileiro.
-- Todas as chaves definidas aqui DEVEM existir em todos os outros arquivos de idioma.
-- Novas chaves adicionadas à biblioteca devem ser adicionadas primeiro aqui e, em seguida, aos outros arquivos.

return {
  cclib = {
    name       = "CCLib",
    version    = "Versão %s",

    guard      = {
      must_be         = "'%s' deve ser %s, recebeu %s",
      must_not_be_nil = "'%s' não pode ser nil",
      must_be_between = "'%s' deve estar entre %s e %s, recebeu %s",
      must_be_one_of  = "'%s' deve ser um de [%s], recebeu '%s'",
    },

    log        = {
      level_debug = "DEBUG",
      level_info  = "INFO",
      level_warn  = "AVISO",
      level_error = "ERRO",
      level_fatal = "FATAL",
      rotated     = "Log rotacionado",
      closed      = "Log encerrado",
    },

    session    = {
      started = "Sessão iniciada",
      stopped = "Sessão encerrada após %d ciclos",
      error   = "Erro no loop de atualização: %s",
    },

    peripheral = {
      found        = "%s conectado em %s",
      lost         = "%s desconectado de %s",
      not_found    = "Periférico não encontrado: %s",
      scan_done    = "%d periférico(s) encontrado(s)",
      monitor_size = "Monitor pequeno demais (%dx%d), mínimo é %dx%d",
    },

    store      = {
      created       = "Store criado com %d chave(s)",
      watcher_limit = "Limite de watchers atingido para '%s'",
      reset         = "Store redefinido ao estado inicial",
    },

    persist    = {
      saved     = "Salvo '%s' (%d bytes)",
      loaded    = "Carregado '%s'",
      not_found = "Arquivo não encontrado: %s",
      corrupted = "Arquivo '%s' corrompido, tentando .bak",
      no_backup = "Sem backup disponível para '%s'",
      save_all  = "saveAll: %d ok, %d falhas",
    },

    migrate    = {
      already_at     = "Dados já na versão %d — sem migração necessária",
      migrating      = "Migrando dados da versão %d para %d",
      applying       = "Aplicando migração %d→%d",
      done           = "Migração concluída — dados na versão %d",
      not_registered = "Migração %d→%d não registrada",
      failed         = "Migração %d→%d falhou: %s",
      downgrade      = "Downgrade não suportado (dados v%d > alvo v%d)",
    },
  },

  -- ── Componentes de UI ──────────────────────────────────────────────────────

  ui = {

    button = {
      ok      = "OK",
      cancel  = "Cancelar",
      confirm = "Confirmar",
      back    = "Voltar",
      close   = "Fechar",
      save    = "Salvar",
      delete  = "Excluir",
      edit    = "Editar",
      add     = "Adicionar",
      remove  = "Remover",
      yes     = "Sim",
      no      = "Não",
      next    = "Próximo",
      prev    = "Anterior",
      submit  = "Enviar",
      reset   = "Redefinir",
      refresh = "Atualizar",
      search  = "Buscar",
      select  = "Selecionar",
      clear   = "Limpar",
      apply   = "Aplicar",
      loading = "Carregando...",
    },

    label = {
      error    = "Erro",
      warning  = "Aviso",
      info     = "Informação",
      success  = "Sucesso",
      empty    = "(vazio)",
      none     = "Nenhum",
      all      = "Todos",
      total    = "Total",
      page     = "Página %d de %d",
      item     = "item",
      items    = "itens",
      selected = "%d selecionado(s)",
      required = "Obrigatório",
      optional = "Opcional",
      new      = "Novo",
      unknown  = "Desconhecido",
    },

    input = {
      placeholder = "Digite aqui...",
      required    = "Este campo é obrigatório",
      too_long    = "Texto muito longo (máx. %d caracteres)",
      too_short   = "Texto muito curto (mín. %d caracteres)",
      invalid     = "Valor inválido",
    },

    table = {
      empty     = "Nenhum registro para exibir",
      loading   = "Carregando...",
      row_count = "%d linha(s)",
    },

    modal = {
      confirm_title = "Confirmar",
      confirm_msg   = "Tem certeza?",
      delete_title  = "Excluir",
      delete_msg    = "Esta ação não pode ser desfeita.",
      error_title   = "Erro",
      info_title    = "Informação",
    },

    toast = {
      saved   = "Salvo",
      deleted = "Excluído",
      error   = "Ocorreu um erro",
      copied  = "Copiado",
      updated = "Atualizado",
      created = "Criado",
      failed  = "Falhou",
    },

    tabs = {
      prev = "◄",
      next = "►",
    },

    progress = {
      label = "%d%%",
    },

    selector = {
      choose = "Escolha...",
    },
  },

  -- ── Tempo e datas ──────────────────────────────────────────────────────────

  time = {
    day      = "Dia",
    night    = "Noite",
    sunrise  = "Amanhecer",
    sunset   = "Pôr do sol",

    second   = "segundo",
    seconds  = "segundos",
    minute   = "minuto",
    minutes  = "minutos",
    hour     = "hora",
    hours    = "horas",

    ago      = "há %s",
    in_time  = "em %s",
    just_now = "agora mesmo",

    mc       = {
      tick = "tick %d",
      day  = "Dia %d",
    },
  },

  -- ── Status / feedback ──────────────────────────────────────────────────────

  status = {
    online  = "Online",
    offline = "Offline",
    busy    = "Ocupado",
    idle    = "Inativo",
    ready   = "Pronto",
    running = "Executando",
    stopped = "Parado",
    error   = "Erro",
    unknown = "Desconhecido",
  },
}
