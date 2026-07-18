# SysPlan Web — Documento de Contexto

> Cole este documento no início de uma conversa com qualquer IA para dar todo o
> contexto do sistema. Ele descreve o propósito, a arquitetura, o modelo de dados,
> as regras de negócio e as convenções do projeto.

## 1. O que é

**SysPlan** é o sistema de **planejamento de compras e importação** da Chilli Beans
(Fortuna Comércio S.A.), usado pelo time de Planejamento de Produtos (óculos, relógios,
smart watches, acessórios, materiais consumíveis). Ele controla toda a carteira de
compras — do pedido ao fornecedor até a chegada da mercadoria no CB (Centro de
Benefícios / entreposto) — passando por follow-up com fornecedores e com o agente de
carga (comex).

Foi originalmente construído em **Microsoft Access** (frontend .accdb + backend .accdb) e
**migrado para uma aplicação web moderna**. Toda a regra de negócio do Access foi
preservada. Também foi incorporado o controle de **relógios** (que era uma planilha
Excel separada) e o controle do **agente de carga** (que era a planilha do despachante
Hoffen).

## 2. Stack e infraestrutura

- **Frontend**: React 18 + TypeScript + Vite (SPA pura, sem SSR) + Tailwind CSS +
  componentes estilo shadcn/ui + Lucide Icons (sem emojis).
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Row Level Security). Não há
  servidor Node próprio — o "backend" é o Postgres com RLS, funções SQL (RPC) e views.
- **Banco de imagens**: Cloudinary (fotos de produto), cloud `r1dihzpf`, upload não
  assinado via preset `sysplan-fotos`.
- **Hospedagem**: Vercel (build estático do Vite). Deploy automático a cada push no
  repositório `equipe-bi/sysplan-web` (o `origin` faz push simultâneo para o fork
  pessoal e para o repo da organização).
- **Idioma**: pt-BR em toda a interface. Datas dd/mm/yyyy, números com separador BR.

### Variáveis de ambiente
- `.env` (vai para o navegador): `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`,
  `VITE_CLOUDINARY_CLOUD_NAME`, `VITE_CLOUDINARY_UPLOAD_PRESET`.
- `.env.migration` (só scripts locais, nunca no navegador): `SUPABASE_SERVICE_ROLE_KEY`,
  credenciais Cloudinary (API secret) e do admin inicial. **Nunca** expor a service_role
  key nem o API secret no frontend.

### Aplicação de SQL
DDL (criar tabelas/views/funções) é aplicado **manualmente pelo usuário** no SQL Editor
do Supabase — o agente não tem a senha do banco. As migrations ficam em
`supabase/migrations/000NN_*.sql` e há cópias avulsas `supabase/ajustes_*.sql` para colar.
Migração de dados e criação de admin usam a service_role key via scripts em `scripts/`.

## 3. Modelo de dados (principais tabelas)

- **`controle_compras`** — tabela central (a "carteira"). PK `cd_compra` (autonum, é o
  "CD Sysplan"). ~19 mil linhas. Cada linha é uma compra: classificação do produto
  (canal, grupo, subgrupo, formato, sexo, linha, griffe, materiais, atributos, medidas),
  valores (`nr_fob_negociado`, `nr_total_fob`, `nr_preco_varejo`, `nr_margem`),
  fornecedor/pedidos (`dc_fornecedor`, `cd_pedido_fornecedor`=PI, `cd_pedido_sap`=PO,
  `cd_material_fornecedor`=Ref, `cd_material_pai`), modal, datas (`dt_recebimento`,
  `dt_delivery`, `dt_revised_delivery`), `dc_status`, `dc_fup_produto`, `cd_essential`.
  Campos **exclusivos de relógio**: `dc_tipo_pulseira`, `dc_tipo_dial`, `dc_numeros`,
  `dc_num_maquina`, `dc_acabamento_caixa`, `dc_tipo_visor`, `dc_montadora`,
  `cd_codigo_compra`, `cd_spare_parts`, `dc_gaveta`, `dc_nf_seculus`. Campo `dc_gaveta`
  é comum a todos os grupos (unificado com o antigo Info 7). Exclusão é **lógica**
  (`dc_status='EXCLUIDO'`, nunca DELETE físico).
- **`followup_fornecedor`** — ciclos de cobrança de status junto ao fornecedor. PK
  `cd_follow_forn`. `cd_compra` **sem FK** (dados legados têm órfãos → nunca usar embed
  do PostgREST; fazer join manual). Aberto = `dt_fim_followup IS NULL`.
- **`ext_fup_comex`** — snapshot do FUP Comex (embarques). Atualizado por importação do
  arquivo `PRM_FUP_COMEX.xlsx` (substitui a base). Chave = Pedido SAP + Material Pai.
- **`ext_fup_despachante`** — legado do despachante (Hoffen).
- **`acompanhamento_importacoes`** — Followup Agente de Carga (controle do comex dentro
  do app; substituiu a planilha Hoffen). Campo `chave` = pedido_sap+material_pai. Status
  calculado por trigger (`fn_status_despachante`).
- **`ext_pedido_sap`** / **`ext_sap_pedido_bw`** — pedidos do SAP (BW).
- **`stg_entrada_sap_mb51`** — entradas físicas (MB51) para conferência de recebimento.
- Parâmetros: `prm_combos` (opções por grupo+tipo; grupo 2 = combos gerais),
  `prm_grupo`, `prm_grupo_planejamento`, `prm_definicao_custo` (dólar/fator/markup para
  margem), `prm_cluster_comprador` (grupo+canal→comprador), `prm_ajuste_fob`,
  `prm_lista_compras` (config de colunas), `prm_cor_pi`/`prm_depara_campos_pi` (PI),
  `prm_modal_lancamento` (modais que devem ser lançados no agente de carga).
- Cadastros: `cadastro_essential`, `depara_essential`, `cadastro_material(_pai)`.
- Fotos: `fotos_produto` (ref do fornecedor → URL Cloudinary).
- Auth/admin: `usuarios` (espelha auth.users; perfil admin|usuario), `usuarios_legado`,
  `telas` (catálogo de telas), `permissoes` (por usuário e tela: ver/editar),
  `log_transacoes` (auditoria completa), `importacoes` (histórico de imports).

### Views principais
- `vw_controle_compras_lista` — fonte da Lista de Compras: compras não excluídas +
  margem calculada + FOB SAP + status FUP consolidado + comprador + última alteração.
- `vw_resumo_fup_geral` — consolida o status por compra na ordem de prioridade
  **FUP Comex > Agente de Carga/Despachante > Fornecedor** (via `fn_prioriza_info_comex`).
- `vw_resumo_fup_despachante` — union do Hoffen legado + `acompanhamento_importacoes`.
- `vw_check_*` — checks de recebimento (auditoria).

## 4. Regras de negócio-chave

- **Margem**: `1 - (FOB × fator_imp × dólar) / (preço_varejo / markup - valor_agregado)`,
  com parâmetros de `prm_definicao_custo` por canal+grupo+modal+AnoMês. FOB usado = FOB
  SAP (média do pedido) se > 0, senão FOB negociado.
- **Tamanho do produto**: calculado a partir das medidas por grupo (óculos: lente+ponte;
  relógio: caixa em mm por sexo). Função SQL `fn_tamanho_produto` e TS `defineTamanhoProduto`.
- **Lead time** = `dt_recebimento - dt_revised_delivery`.
- **Grupo de Planejamento**: lookup em `prm_grupo_planejamento` por
  (grupo, subgrupo, sexo, formato).
- **Combos dependentes**: opções vêm de `prm_combos`; combos gerais usam `cd_grupo=2`,
  os específicos usam o `cd_grupo` do grupo selecionado.
- **Trava de recebimento passado**: `dt_recebimento` de ontem para trás é imutável na
  edição/lista (trigger no banco); só a tela **Checks de Recebimento** corrige, via
  `fn_corrigir_recebimento`.
- **Pedido SAP e Material Pai** são bloqueados na edição de compra; só se atualizam na
  tela dedicada "Atualização Pedido SAP / Material Pai" (import em massa ou 1 a 1).
- **Lock de edição**: ao abrir uma compra, ela é bloqueada para outros usuários por até
  2h (`fn_bloquear_compra`).
- **Auditoria**: toda alteração em `controle_compras` gera log campo a campo (trigger).

## 5. Telas (módulos)

**Compras**
- **Lista de Compras**: carteira. Colunas configuráveis, seletor de colunas, autofiltro
  estilo Excel (funil por coluna), filtros rápidos em cascata (canal/grupo/griffe/etc.),
  foto do produto (miniatura na 1ª coluna e no cabeçalho ao clicar), últimas alterações,
  edição individual (duplo clique, com lock), edição em massa (seleção múltipla + Shift;
  exige mesmo grupo; campos de relógio aparecem só p/ grupo relógio), cadastro em massa,
  exclusão lógica, export Excel/CSV/PDF.
- **Atualização Pedido SAP / Material Pai**: tela dedicada (esses campos são bloqueados
  na edição). Import em massa por Excel (modelo cd_compra/cd_pedido_sap/cd_material_pai)
  e edição unitária por duplo clique.
- **Follow-up Fornecedor**: exporta a máscara oficial (aba Orders + DePara, protegida com
  senha **Plan8**; A–L travadas, M–P o fornecedor preenche com dropdown de Production
  Status, Q–Z fórmulas de avaliação). Regra de geração por chave (Material Pai + Pedido
  SAP) contra FUP Comex e Agente de Carga: baixa sistema dos que já têm info; gera novas
  linhas para recebimento futuro copiando a última resposta. **Exporta 1 arquivo único**
  conforme o filtro (todos os fornecedores juntos, ou só o filtrado). Import atualiza o
  follow e aplica delivery/modal/recebimento na compra.
- **Cadastro de PI**: upload do Excel da Proforma Invoice; extrai campos por rótulo, foto
  embutida, mapa de cores C1–C8 com tradução EN→PT; vincula à compra.

**Comex**
- **Controle de Importação**: painel de status consolidado (Comex > Agente > Fornecedor),
  lista de entrega na origem.
- **Followup Agente de Carga** (antigo "Acompanhamento de Importações"): controle do
  agente de carga no app. Autofiltro no cabeçalho, edição individual/massa (Shift),
  inserir avulso, status calculado.
- **Lançar no Acompanhamento**: alimenta o Followup Agente de Carga a partir da carteira,
  filtrando pelo AnoMês do Revised Delivery. Status de preenchimento por chave (Material
  Pai 8 caracteres + Pedido SAP 10 dígitos), KPIs (Já lançado / A lançar / Erro de
  Preenchimento / Modal não lançável), coluna Lançar (por `prm_modal_lancamento`) e
  Responsável, export "a lançar".
- **Múltiplos Embarques**: pedidos SAP com >1 embarque; toggle "só pendentes";
  "Identificar novos" apaga pendentes e reidentifica.
- **Checks de Recebimento**: conferência MB51 × Controle (import do MB51 + classificação
  de divergências, com ações Alterar/Excluir) + checks PI/PO duplicado, GP não cadastrado,
  diferença de volume, FUP Comex fora do Sysplan, múltiplos pendentes.

**Cadastros**: Cadastro de PDV, Desenvolvimento Design.

**Administração** (só admin): Usuários (criar/editar/bloquear/reset senha), Permissões
(por tela: ver/editar), Parâmetros (CRUD de todas as tabelas PRM + rotinas de
manutenção), Importações (bases externas: FUP Comex, SAP BW, materiais, PDV), Logs.

## 6. Segurança

- **RLS** habilitada em todas as tabelas. Acesso anônimo retorna 0 linhas. Usuários
  autenticados acessam conforme `permissoes` (função `fn_tem_permissao(tela, editar)`);
  admins têm acesso total (`fn_is_admin`).
- Novos usuários **sempre nascem 'usuario'** (o trigger não confia no perfil enviado no
  signup); promoção a admin só por um admin. Recomenda-se desabilitar signup público no
  Supabase Auth.
- **Headers de segurança** no `vercel.json`: CSP restritivo (default-src 'self';
  connect só Supabase e Cloudinary; frame-ancestors 'none'), X-Frame-Options DENY,
  Referrer-Policy, Permissions-Policy, HSTS.
- O token JWT fica no localStorage (padrão do Supabase JS em SPA); o CSP mitiga o vetor
  de XSS. Migração para cookies HttpOnly exigiria um servidor (SSR), fora do escopo atual.

## 7. Convenções de código

- **Nunca** declarar componentes auxiliares dentro de outro componente e usá-los como
  `<Campo/>` — isso remonta os inputs a cada tecla (bug do "ano 0002"). Usar chamada de
  função: `{Campo({...})}`.
- Listas grandes: usar o helper `fetchAll()` (PostgREST limita 1000 linhas/requisição).
- `followup_fornecedor` não tem FK para `controle_compras` → join manual em 2 consultas.
- Mapeamento de nomes de coluna legados em `pages/compras/colunas.ts` (`MAPA_LEGADO`);
  o algoritmo camelCase erra nomes colados (ex.: SubGrupo → conferir o mapa).
- Exportações Excel com máscara/fórmulas/proteção usam **exceljs**; leituras usam **xlsx**.
- Componente `DataTable` genérico: `autofiltro` liga o funil por coluna; colunas com
  `render` JSX devem ter `valor:(row)=>...` para ordenar/filtrar corretamente.
