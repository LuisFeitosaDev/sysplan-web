-- SysPlan Web — v9-4
-- Parâmetro de modais que devem ser lançados no Followup Agente de Carga.
-- Rodar no SQL Editor do Supabase.

create table if not exists prm_modal_lancamento (
  dc_modal text primary key,
  lancar boolean not null default true
);

-- Semeia com os modais existentes na carteira; ROAD (nacional) não é lançado.
insert into prm_modal_lancamento (dc_modal, lancar)
select distinct upper(trim(dc_modal)),
       case when upper(trim(dc_modal)) like 'ROAD%' then false else true end
from controle_compras
where coalesce(trim(dc_modal), '') <> ''
on conflict (dc_modal) do nothing;

alter table prm_modal_lancamento enable row level security;

drop policy if exists prm_modal_lancamento_sel on prm_modal_lancamento;
create policy prm_modal_lancamento_sel on prm_modal_lancamento for select to authenticated using (true);

drop policy if exists prm_modal_lancamento_adm on prm_modal_lancamento;
create policy prm_modal_lancamento_adm on prm_modal_lancamento for all to authenticated
  using (fn_tem_permissao('admin_parametros', true))
  with check (fn_tem_permissao('admin_parametros', true));
