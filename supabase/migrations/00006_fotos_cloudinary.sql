-- SysPlan Web — Fotos de produto no Cloudinary
-- Mapeia a referência do fornecedor para a URL da foto no banco de imagens.
-- Rodar no SQL Editor do Supabase.

create table if not exists fotos_produto (
  cd_ref_fornecedor text primary key,
  url text not null,
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid references usuarios (id)
);

alter table fotos_produto enable row level security;

drop policy if exists fotos_produto_sel on fotos_produto;
create policy fotos_produto_sel on fotos_produto for select to authenticated using (true);

drop policy if exists fotos_produto_edit on fotos_produto;
create policy fotos_produto_edit on fotos_produto for all to authenticated
  using (fn_tem_permissao('lista_compras', true) or fn_tem_permissao('cadastro_pi', true))
  with check (fn_tem_permissao('lista_compras', true) or fn_tem_permissao('cadastro_pi', true));
