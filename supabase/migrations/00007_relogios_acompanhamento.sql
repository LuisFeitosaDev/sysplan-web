-- SysPlan Web — v5
-- 1) Campos exclusivos de RELOGIOS/SMART WATCH no controle de compras
-- 2) Função de lançamento no Acompanhamento de Importações por AnoMês do Revised Delivery
-- 3) Tela "Lançar no Acompanhamento" (permissão separada de quem usa o acompanhamento)
-- Rodar no SQL Editor do Supabase.

-- =====================================================================
-- 1. CAMPOS EXCLUSIVOS DE RELÓGIOS
-- =====================================================================
alter table controle_compras
  add column if not exists dc_tipo_pulseira text,
  add column if not exists dc_tipo_dial text,
  add column if not exists dc_numeros text,
  add column if not exists dc_num_maquina text,
  add column if not exists dc_acabamento_caixa text,
  add column if not exists dc_tipo_visor text,
  add column if not exists dc_montadora text,
  add column if not exists cd_codigo_compra text,
  add column if not exists cd_spare_parts text,
  add column if not exists dc_gaveta text,
  add column if not exists dc_nf_seculus text;

-- A view usa c.* e precisa ser recriada para enxergar as novas colunas
drop view if exists vw_controle_compras_lista;
create view vw_controle_compras_lista as
select
  c.*,
  case when fob.fob_sap > 0 then fob.fob_sap else c.nr_fob_negociado end as fob_calc,
  case
    when cu.nr_markup is null or cu.nr_markup = 0 then null
    when (c.nr_preco_varejo / cu.nr_markup - cu.nr_valor_agregado) = 0 then null
    else 1 - ((case when fob.fob_sap > 0 then fob.fob_sap else c.nr_fob_negociado end) * cu.nr_fator_imp * cu.nr_dolar)
           / (c.nr_preco_varejo / cu.nr_markup - cu.nr_valor_agregado)
  end as margem_calc,
  fn_tamanho_produto(c.dc_grupo, c.dc_medidas, c.dc_sexo) as tamanho_calc,
  g.processo_calc as cd_embarque,
  g.entrega_calc as dt_entrega_origem_fup,
  coalesce(g.embarque_calc, g.prev_embarque_calc) as dt_embarque_fup,
  coalesce(g.atraque_calc, g.prev_atraque_calc) as dt_atraque_fup,
  g.status_calc as dc_status_comex,
  case when coalesce(c.cd_essential, 0) <> 0
       then c.cd_essential::text || ' - ' || coalesce(e.dc_essential, '')
       else '' end as essential_calc,
  cc.dc_comprador,
  cc.dc_comprador_grupo as dc_comprador_grupo
from controle_compras c
left join prm_definicao_custo cu
  on c.dc_grupo = cu.dc_grupo and c.dc_canal = cu.dc_canal
 and c.dc_modal = cu.dc_modal and c.nr_anomes = cu.nr_anomes
left join vw_fob_sap fob
  on c.cd_pedido_sap = fob.cd_pedido_sap and c.cd_material_pai = fob.cd_material_pai
left join prm_cluster_comprador cc
  on c.dc_grupo = cc.dc_grupo and c.dc_canal = cc.dc_canal
left join vw_resumo_fup_geral g on c.cd_compra = g.cd_compra
left join cadastro_essential e on c.cd_essential = e.cd_essential
where c.dc_status is distinct from 'EXCLUIDO';

-- =====================================================================
-- 2. LANÇAR NO ACOMPANHAMENTO POR ANOMÊS DO REVISED DELIVERY
-- =====================================================================
create or replace function fn_lancar_acompanhamento(p_anomes text) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_qtd integer;
begin
  insert into acompanhamento_importacoes
    (cd_compra, dc_grupo, dc_linha, dc_griffe, dc_canal, dc_fornecedor, cd_ref_fornecedor,
     cd_material_pai, cd_pedido_fornecedor, cd_pedido_sap, nr_quantidade, dt_recebimento,
     dc_modal, dt_delivery, dc_data_inicio)
  select
    c.cd_compra,
    case when c.dc_grupo = 'MATERIAIS CONSUMIVEIS' then c.dc_subgrupo else c.dc_grupo end,
    c.dc_linha, c.dc_griffe, c.dc_canal, c.dc_fornecedor, c.cd_material_fornecedor,
    c.cd_material_pai, c.cd_pedido_fornecedor, c.cd_pedido_sap, c.nr_quantidade,
    c.dt_recebimento, c.dc_modal, c.dt_revised_delivery,
    upper(to_char(c.dt_revised_delivery, 'TMMon/YY'))
  from controle_compras c
  left join acompanhamento_importacoes a
    on coalesce(c.cd_pedido_sap, '') || coalesce(c.cd_material_pai, '') = a.chave
  where a.id is null
    and c.dc_status is distinct from 'EXCLUIDO'
    and c.dc_modal is distinct from 'ROAD'
    and coalesce(c.cd_pedido_sap, '') <> '' and c.cd_pedido_sap <> 'N/I'
    and to_char(c.dt_revised_delivery, 'YYYYMM') = p_anomes;
  get diagnostics v_qtd = row_count;
  return v_qtd;
end;
$$;

-- =====================================================================
-- 3. TELA/PERMISSÃO SEPARADA PARA ALIMENTAR O ACOMPANHAMENTO
-- =====================================================================
insert into telas (codigo, nome, grupo, ordem) values
  ('lancar_acompanhamento', 'Lançar no Acompanhamento', 'Comex', 6)
on conflict (codigo) do nothing;
