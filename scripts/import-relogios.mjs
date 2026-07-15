// Migração do controle de RELOGIOS (Excel BaseCompras) para controle_compras.
// Uso: node scripts/import-relogios.mjs [caminho do xlsx]
// Requer 00007_relogios_acompanhamento.sql aplicado (colunas exclusivas de relógio).
import path from 'node:path';
import { createRequire } from 'node:module';
import { ROOT, loadEnv, restRequest } from './lib.mjs';

const require = createRequire(import.meta.url);
const XLSX = require('xlsx');

const env = loadEnv();
const arquivo = process.argv[2] ?? path.join(ROOT, '..', 'ControleCompras_RELOGIO - Migração Sysplan.xlsx');

const wb = XLSX.readFile(arquivo, { cellDates: true });
const linhas = XLSX.utils.sheet_to_json(wb.Sheets['BaseCompras'], { header: 1, defval: null });
const dados = linhas.slice(2); // linha 1 = ações, linha 2 = cabeçalho

const s = (v) => {
  if (v == null) return null;
  const t = String(v).trim();
  return t === '' ? null : t;
};
const num = (v) => (v == null || v === '' ? 0 : Number(v) || 0);
const dt = (v) => {
  if (v instanceof Date) {
    if (v.getFullYear() < 1990) return null;
    return v.toISOString().slice(0, 10);
  }
  return null;
};

/** Junta "Malha ou link?" + "Silicouro?" em Tipo Pulseira */
function tipoPulseira(malhaLink, silicouro) {
  const partes = [];
  const m = (s(malhaLink) ?? '').toUpperCase();
  const si = (s(silicouro) ?? '').toUpperCase();
  if (m && m !== 'NÃO' && m !== 'NAO') partes.push(m);
  if (si === 'SIM' || si === 'SILICOURO') partes.push('SILICOURO');
  return partes.join(' / ') || null;
}

const registros = dados
  .filter((r) => s(r[2])) // precisa ter Grupo
  .map((r) => ({
    dc_canal: s(r[1]),
    dc_grupo: s(r[2]),
    dc_subgrupo: s(r[3]),
    dc_formato: s(r[4]),
    dc_sexo: s(r[5]),
    dc_grupo_planejamento: s(r[6]),
    dc_linha: s(r[7]),
    dc_griffe: s(r[9]),
    dc_segmentacao: s(r[10]),
    dc_material1: s(r[12]),
    dc_material2: s(r[13]),
    dc_atributo1: s(r[14]),
    dc_atributo2: s(r[15]),
    dc_tipo_pulseira: tipoPulseira(r[16], r[17]),
    dc_tipo_dial: s(r[18]),
    dc_numeros: s(r[19])?.toUpperCase() ?? null,
    dc_num_maquina: s(r[20]),
    dc_tamanho: s(r[21])?.toUpperCase().trim() ?? null,
    dc_medidas: s(r[22]),
    dc_acabamento_caixa: s(r[23]),
    dc_tipo_visor: s(r[24]),
    dc_fornecedor: s(r[25]),
    dc_montadora: s(r[26]),
    dc_modal: s(r[27]),
    nr_quantidade: num(r[28]),
    nr_fob_negociado: num(r[29]),
    nr_total_fob: num(r[34]),
    nr_preco_varejo: num(r[35]),
    dt_recebimento: dt(r[46]),
    dc_status: s(r[50])?.toUpperCase() ?? 'CARTEIRA',
    cd_codigo_compra: s(r[51]),
    cd_pedido_fornecedor: s(r[52]),
    cd_pedido_sap: s(r[53]),
    cd_spare_parts: s(r[54]),
    cd_material_pai: s(r[55]),
    cd_material_fornecedor: s(r[56]),
    dt_delivery: dt(r[58]),
    dt_revised_delivery: dt(r[59]),
    dc_gaveta: s(r[63]),
    dc_nf_seculus: s(r[65]),
    dc_observacao: s(r[66]),
    dc_fup_produto: s(r[70]),
  }));

console.log(`Planilha: ${dados.length} linhas; válidas para migração: ${registros.length}`);
const grupos = {};
for (const r of registros) grupos[r.dc_grupo] = (grupos[r.dc_grupo] ?? 0) + 1;
console.log('Por grupo:', JSON.stringify(grupos));

let inseridos = 0;
for (let i = 0; i < registros.length; i += 500) {
  await restRequest(env, 'POST', '/rest/v1/controle_compras', registros.slice(i, i + 500), {
    Prefer: 'return=minimal',
  });
  inseridos += Math.min(500, registros.length - i);
  process.stdout.write(`\r${inseridos}/${registros.length}`);
}
console.log('\nMigração de relógios concluída.');
