-- SysPlan Web — v11: correções de segurança (auditoria do relatório)
-- Rodar no SQL Editor do Supabase.

-- =====================================================================
-- 1. Escalada de privilégio via metadata de signup
-- =====================================================================
-- O trigger antigo lia o perfil de raw_user_meta_data. Se o signup público
-- estiver habilitado, um atacante poderia se cadastrar como 'admin'.
-- Agora todo novo usuário nasce 'usuario'; a promoção a admin só é possível
-- por um administrador (política RLS usuarios_admin_all) ou pelo service_role
-- (script create-admin). O trigger de vínculo com o legado é preservado.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.usuarios (id, email, nome, perfil)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)),
    'usuario'::perfil_usuario   -- nunca confia no perfil enviado pelo cliente
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- =====================================================================
-- 2. Impede que um usuário altere o próprio perfil/bloqueio
-- =====================================================================
-- (defensivo: mesmo sem política de update para não-admin, deixa explícito)
-- A tabela usuarios só permite UPDATE/DELETE por admin (usuarios_admin_all).
-- Garante que a política de admin exista e esteja correta.
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public'
      and tablename = 'usuarios' and policyname = 'usuarios_admin_all'
  ) then
    create policy usuarios_admin_all on usuarios for all to authenticated
      using (fn_is_admin()) with check (fn_is_admin());
  end if;
end $$;

-- =====================================================================
-- 3. Confirma RLS habilitado em todas as tabelas de dados
-- =====================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'usuarios','telas','permissoes','log_transacoes','controle_compras',
    'followup_fornecedor','ext_fup_comex','ext_fup_despachante','ext_pedido_sap',
    'ext_sap_pedido_bw','stg_entrada_sap_mb51','pasta_pi','pi_cores',
    'acompanhamento_importacoes','fotos_produto','prm_modal_lancamento',
    'usuarios_legado','importacoes','cadastro_essential','depara_essential',
    'cadastro_material','cadastro_material_pai','desenvolvimento_design',
    'cartela_cor_design','pdv_cadastro_loja','pdv_cadastro_pdv','pdv_base_cadastro',
    'pdv_depara','pdv_status'
  ]
  loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table %I enable row level security', t);
    end if;
  end loop;
end $$;
