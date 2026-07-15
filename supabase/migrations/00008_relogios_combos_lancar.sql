-- SysPlan Web — v6 (Relógios + Lançar no Acompanhamento)
-- 1) Combos para os campos exclusivos de relógio (cd_grupo = grupo RELOGIOS)
-- 2) Garante a tela lancar_acompanhamento na tabela telas (já existe em 00007, mas por segurança)
-- Rodar no SQL Editor do Supabase.

-- =====================================================================
-- 1. BUSCAR O CD_GRUPO DE RELOGIOS (insere se não existir)
-- =====================================================================
insert into prm_grupo (dc_grupo) values ('RELOGIOS') on conflict (dc_grupo) do nothing;

-- =====================================================================
-- 2. COMBOS EXCLUSIVOS DE RELÓGIO
-- Usamos um bloco DO para descobrir o cd_grupo dinamicamente
-- =====================================================================
do $$
declare
  v_cd integer;
begin
  select cd_grupo into v_cd from prm_grupo where dc_grupo = 'RELOGIOS';

  -- ---------- TIPO PULSEIRA (unifica "Malha ou link?" + "Silicouro?") ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'TIPO PULSEIRA', '1 LINK'),
    (v_cd, 'TIPO PULSEIRA', '2 LINK'),
    (v_cd, 'TIPO PULSEIRA', '3 LINK'),
    (v_cd, 'TIPO PULSEIRA', '4 LINK'),
    (v_cd, 'TIPO PULSEIRA', '5 LINK'),
    (v_cd, 'TIPO PULSEIRA', '6 LINK'),
    (v_cd, 'TIPO PULSEIRA', '7 LINK'),
    (v_cd, 'TIPO PULSEIRA', '9 LINK'),
    (v_cd, 'TIPO PULSEIRA', 'CHAIN'),
    (v_cd, 'TIPO PULSEIRA', 'LINK'),
    (v_cd, 'TIPO PULSEIRA', 'MALHA'),
    (v_cd, 'TIPO PULSEIRA', 'NÃO'),
    (v_cd, 'TIPO PULSEIRA', 'SILICONE'),
    (v_cd, 'TIPO PULSEIRA', 'SILICOURO'),
    (v_cd, 'TIPO PULSEIRA', 'SIM')
  on conflict do nothing;

  -- ---------- TIPO DIAL ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'TIPO DIAL', 'ANA-DIG'),
    (v_cd, 'TIPO DIAL', 'ANALÓGICO'),
    (v_cd, 'TIPO DIAL', 'AUTOMÁTICO'),
    (v_cd, 'TIPO DIAL', 'DIGITAL'),
    (v_cd, 'TIPO DIAL', 'DIGITAL LCD'),
    (v_cd, 'TIPO DIAL', 'DIGITAL LED'),
    (v_cd, 'TIPO DIAL', 'MECÂNICO'),
    (v_cd, 'TIPO DIAL', 'MULTIFUNCTION'),
    (v_cd, 'TIPO DIAL', 'MULTIFUNCTION COM PUSHERS'),
    (v_cd, 'TIPO DIAL', 'SMART')
  on conflict do nothing;

  -- ---------- NÚMEROS ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'NUMEROS', 'SIM'),
    (v_cd, 'NUMEROS', 'NÃO'),
    (v_cd, 'NUMEROS', 'DIGITAL')
  on conflict do nothing;

  -- ---------- NUM MÁQUINA ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'NUM MAQUINA', 'ANA-DIGI'),
    (v_cd, 'NUM MAQUINA', 'DIGITAL'),
    (v_cd, 'NUM MAQUINA', 'DIGITAL LCD'),
    (v_cd, 'NUM MAQUINA', 'INDEFINIDO'),
    (v_cd, 'NUM MAQUINA', 'MAQ 3'),
    (v_cd, 'NUM MAQUINA', 'MAQ 4'),
    (v_cd, 'NUM MAQUINA', 'MAQ 5'),
    (v_cd, 'NUM MAQUINA', 'MAQ 6'),
    (v_cd, 'NUM MAQUINA', 'MAQ 7'),
    (v_cd, 'NUM MAQUINA', 'MAQ 8'),
    (v_cd, 'NUM MAQUINA', 'MAQ 28'),
    (v_cd, 'NUM MAQUINA', 'MAQ 29'),
    (v_cd, 'NUM MAQUINA', 'MAQ 31'),
    (v_cd, 'NUM MAQUINA', 'MAQ 33'),
    (v_cd, 'NUM MAQUINA', 'MAQ 34'),
    (v_cd, 'NUM MAQUINA', 'MAQ 35'),
    (v_cd, 'NUM MAQUINA', 'MAQ 36'),
    (v_cd, 'NUM MAQUINA', 'MAQ 37'),
    (v_cd, 'NUM MAQUINA', 'MAQ 38'),
    (v_cd, 'NUM MAQUINA', 'MAQ 39'),
    (v_cd, 'NUM MAQUINA', 'MAQ 40'),
    (v_cd, 'NUM MAQUINA', 'MAQ 41'),
    (v_cd, 'NUM MAQUINA', 'MAQ 42'),
    (v_cd, 'NUM MAQUINA', 'MAQ 43'),
    (v_cd, 'NUM MAQUINA', 'MAQ 44'),
    (v_cd, 'NUM MAQUINA', 'MAQ 45'),
    (v_cd, 'NUM MAQUINA', 'MAQ 46'),
    (v_cd, 'NUM MAQUINA', 'MAQ 47'),
    (v_cd, 'NUM MAQUINA', 'MAQ 48'),
    (v_cd, 'NUM MAQUINA', 'MAQ 49'),
    (v_cd, 'NUM MAQUINA', 'MAQ 50'),
    (v_cd, 'NUM MAQUINA', 'MAQ 51'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 1'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 2'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 6'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 11'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 12'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 13'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 14'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 17'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 18'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 19'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 20'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 21'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 22'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 23'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 24'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 25'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 26'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 35'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 43'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 51'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 59'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA 61'),
    (v_cd, 'NUM MAQUINA', 'MAQUINA DIGITAL'),
    (v_cd, 'NUM MAQUINA', 'SMART'),
    (v_cd, 'NUM MAQUINA', 'VX9J')
  on conflict do nothing;

  -- ---------- ACABAMENTO CAIXA ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'ACABAMENTO CAIXA', 'BRILHO'),
    (v_cd, 'ACABAMENTO CAIXA', 'ESCOVADO'),
    (v_cd, 'ACABAMENTO CAIXA', 'FOSCO'),
    (v_cd, 'ACABAMENTO CAIXA', 'MADEIRA')
  on conflict do nothing;

  -- ---------- TIPO VISOR ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'TIPO VISOR', 'CHANFRADO'),
    (v_cd, 'TIPO VISOR', 'CÚPULA'),
    (v_cd, 'TIPO VISOR', 'FACETADO'),
    (v_cd, 'TIPO VISOR', 'PLANO'),
    (v_cd, 'TIPO VISOR', 'SMART')
  on conflict do nothing;

  -- ---------- MONTADORA ----------
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo) values
    (v_cd, 'MONTADORA', 'MONTADO'),
    (v_cd, 'MONTADORA', 'ORIENT'),
    (v_cd, 'MONTADORA', 'SECULUS'),
    (v_cd, 'MONTADORA', 'VIVARA')
  on conflict do nothing;

end;
$$;

-- =====================================================================
-- 3. GARANTIR SMART WATCH TAMBÉM TEM OS MESMOS COMBOS
-- =====================================================================
do $$
declare
  v_cd_smart integer;
  v_cd_rel   integer;
begin
  -- Garante grupo SMART WATCH
  insert into prm_grupo (dc_grupo) values ('SMART WATCH') on conflict (dc_grupo) do nothing;
  select cd_grupo into v_cd_smart from prm_grupo where dc_grupo = 'SMART WATCH';
  select cd_grupo into v_cd_rel   from prm_grupo where dc_grupo = 'RELOGIOS';

  -- Copia todos os combos de relógio para smart watch (se não existir)
  insert into prm_combos (cd_grupo, dc_tipo_combo, dc_combo)
    select v_cd_smart, dc_tipo_combo, dc_combo
    from   prm_combos
    where  cd_grupo = v_cd_rel
    and    dc_tipo_combo in ('TIPO PULSEIRA','TIPO DIAL','NUMEROS','NUM MAQUINA','ACABAMENTO CAIXA','TIPO VISOR','MONTADORA')
  on conflict do nothing;
end;
$$;

-- =====================================================================
-- 4. PERMISSÃO "LANÇAR NO ACOMPANHAMENTO" (já criada no 00007, por segurança)
-- =====================================================================
insert into telas (codigo, nome, grupo, ordem) values
  ('lancar_acompanhamento', 'Lançar no Acompanhamento', 'Comex', 6)
on conflict (codigo) do nothing;
