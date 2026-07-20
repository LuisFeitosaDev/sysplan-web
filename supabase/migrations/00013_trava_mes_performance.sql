-- SysPlan Web — v12: trava de recebimento por MÊS + índices de performance
-- Rodar no SQL Editor do Supabase.

-- =====================================================================
-- 1. TRAVA DA DATA DE RECEBIMENTO: bloqueia só MESES PASSADOS
-- =====================================================================
-- Antes: qualquer data de ontem para trás era imutável.
-- Agora: recebimento dentro do MÊS ATUAL pode ser alterado normalmente;
-- só datas de meses anteriores exigem a tela Checks de Recebimento.
create or replace function trg_calcula_controle_compras() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE'
     and old.dt_recebimento is not null
     and old.dt_recebimento < date_trunc('month', current_date)::date
     and new.dt_recebimento is distinct from old.dt_recebimento
     and coalesce(current_setting('app.liberar_recebimento', true), '') <> '1'
  then
    raise exception 'Data de recebimento de mês passado (%) não pode ser alterada pela lista de compras. Use a tela Checks de Recebimento.', old.dt_recebimento;
  end if;

  new.nr_lead_time := case
    when new.dt_recebimento is not null and new.dt_revised_delivery is not null
    then new.dt_recebimento - new.dt_revised_delivery
    else new.nr_lead_time
  end;
  new.nr_anomes := case
    when new.dt_recebimento is not null then to_char(new.dt_recebimento, 'YYYYMM')::numeric
    else new.nr_anomes
  end;
  new.dc_tamanho := coalesce(fn_tamanho_produto(new.dc_grupo, new.dc_medidas, new.dc_sexo), new.dc_tamanho);
  new.atualizado_em := now();
  return new;
end;
$$;

-- =====================================================================
-- 2. ÍNDICES DE PERFORMANCE
-- =====================================================================
-- O maior custo da vw_controle_compras_lista é o "lateral join" que busca a
-- última alteração de cada compra em log_transacoes (~285 mil linhas).
-- Este índice torna essa busca instantânea (index scan invertido):
create index if not exists idx_log_ultima_alteracao
  on log_transacoes (cd_item_transacao, dt_transacao desc)
  where coalesce(campo_editado, '') <> '';

-- Filtros mais comuns da lista de compras
create index if not exists idx_compras_status on controle_compras (dc_status);
create index if not exists idx_compras_anomes on controle_compras (nr_anomes);
create index if not exists idx_compras_recebimento on controle_compras (dt_recebimento);
create index if not exists idx_compras_pedido_material on controle_compras (cd_pedido_sap, cd_material_pai);

-- Follow-up fornecedor: tela filtra por follow aberto e junta por cd_compra
create index if not exists idx_follow_aberto on followup_fornecedor (cd_compra) where dt_fim_followup is null;
create index if not exists idx_follow_cd_compra on followup_fornecedor (cd_compra);
create index if not exists idx_follow_fim on followup_fornecedor (dt_fim_followup);

-- FUP Comex / Acompanhamento: buscas por chave (pedido + material pai)
create index if not exists idx_fup_comex_chave on ext_fup_comex (cd_pedido_sap, cd_material_pai);
create index if not exists idx_acomp_chave on acompanhamento_importacoes (cd_pedido_sap, cd_material_pai);

analyze log_transacoes;
analyze controle_compras;
analyze followup_fornecedor;
