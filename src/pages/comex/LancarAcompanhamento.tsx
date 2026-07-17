import { useMemo, useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { CalendarSearch, Ship, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/context/AuthContext';
import { DataTable, type Coluna } from '@/components/DataTable';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/misc';
import { formatDate, formatNumber, anoMes } from '@/lib/utils';

/**
 * Lançar no Acompanhamento de Importações
 * -----------------------------------------
 * Tela separada (permissão `lancar_acompanhamento`) para alimentar o controle
 * de importações a partir da lista de compras Web.
 *
 * O usuário filtra pelo AnoMês do Revised Delivery (ex.: 202608),
 * visualiza o que seria lançado e confirma com o botão "Lançar".
 * Quem usa o acompanhamento NÃO precisa ter acesso a esta tela.
 */
export default function LancarAcompanhamento() {
  const { podeEditar, registraLog } = useAuth();
  const editavel = podeEditar('lancar_acompanhamento');

  const [anoMesBusca, setAnoMesBusca] = useState(String(anoMes(0)));
  const [buscado, setBuscado] = useState(false);

  // Preview: compras que seriam lançadas (Revised Delivery no mês, sem modal ROAD,
  // com Pedido SAP preenchido, e que ainda não estão no acompanhamento)
  const { data: preview, isLoading: loadingPreview, refetch } = useQuery({
    queryKey: ['lancar_preview', anoMesBusca],
    enabled: buscado,
    queryFn: async () => {
      // Busca as compras elegíveis para lançamento (mesma lógica do fn_lancar_acompanhamento)
      const { data: compras, error: errC } = await supabase
        .from('controle_compras')
        .select(
          'cd_compra, dc_grupo, dc_canal, dc_fornecedor, cd_material_pai, cd_pedido_fornecedor, cd_pedido_sap, nr_quantidade, dc_modal, dt_revised_delivery, dt_recebimento',
        )
        .neq('dc_status', 'EXCLUIDO')
        .neq('dc_modal', 'ROAD')
        .not('cd_pedido_sap', 'is', null)
        .neq('cd_pedido_sap', '')
        .neq('cd_pedido_sap', 'N/I')
        .filter(
          'dt_revised_delivery',
          'gte',
          `${anoMesBusca.slice(0, 4)}-${anoMesBusca.slice(4, 6)}-01`,
        )
        .filter(
          'dt_revised_delivery',
          'lt',
          // Primeiro dia do mês seguinte
          (() => {
            const y = Number(anoMesBusca.slice(0, 4));
            const m = Number(anoMesBusca.slice(4, 6));
            const next = m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, '0')}-01`;
            return next;
          })(),
        )
        .order('dt_revised_delivery');

      if (errC) throw errC;

      // Busca os que já estão no acompanhamento para marcá-los
      const chaves = (compras ?? [])
        .map((c) => `${c.cd_pedido_sap ?? ''}${c.cd_material_pai ?? ''}`)
        .filter(Boolean);

      const { data: jaLancados } = chaves.length
        ? await supabase
            .from('acompanhamento_importacoes')
            .select('chave')
            .in('chave', chaves)
        : { data: [] };

      const jaSet = new Set((jaLancados ?? []).map((r: any) => r.chave));

      return (compras ?? []).map((c) => ({
        ...c,
        ja_lancado: jaSet.has(`${c.cd_pedido_sap ?? ''}${c.cd_material_pai ?? ''}`),
      }));
    },
  });

  const novos = useMemo(() => (preview ?? []).filter((r) => !r.ja_lancado), [preview]);
  const jaLancados = useMemo(() => (preview ?? []).filter((r) => r.ja_lancado), [preview]);

  const lancar = useMutation({
    mutationFn: async () => {
      if (!anoMesBusca || anoMesBusca.length !== 6) {
        throw new Error('Informe o AnoMês no formato YYYYMM (ex: 202608).');
      }
      if (novos.length === 0) {
        throw new Error('Não há registros novos para lançar neste mês.');
      }
      const { data, error } = await supabase.rpc('fn_lancar_acompanhamento', {
        p_anomes: anoMesBusca,
      });
      if (error) throw error;
      registraLog('LancarAcompanhamento - Lancamento', 0, '', `AnoMes ${anoMesBusca} → ${data} registros`);
      return Number(data ?? 0);
    },
    onSuccess: (qtd) => {
      toast.success(`${qtd} registro(s) lançado(s) no Acompanhamento de Importações!`);
      refetch();
    },
    onError: (e: any) => toast.error(e.message ?? String(e)),
  });

  const colunas: Coluna<any>[] = [
    {
      key: 'ja_lancado',
      titulo: 'Situação',
      render: (r) =>
        r.ja_lancado ? (
          <Badge variant="secondary">Já lançado</Badge>
        ) : (
          <Badge variant="default">Novo</Badge>
        ),
    },
    { key: 'dc_grupo', titulo: 'Grupo' },
    { key: 'dc_canal', titulo: 'Canal' },
    { key: 'dc_fornecedor', titulo: 'Fornecedor' },
    { key: 'cd_material_pai', titulo: 'Material Pai' },
    { key: 'cd_pedido_fornecedor', titulo: 'PI' },
    { key: 'cd_pedido_sap', titulo: 'Pedido SAP' },
    { key: 'nr_quantidade', titulo: 'Qtde', render: (r) => formatNumber(r.nr_quantidade, 0) },
    { key: 'dc_modal', titulo: 'Modal' },
    {
      key: 'dt_revised_delivery',
      titulo: 'Revised Delivery',
      render: (r) => formatDate(r.dt_revised_delivery),
    },
    {
      key: 'dt_recebimento',
      titulo: 'Recebimento',
      render: (r) => formatDate(r.dt_recebimento),
    },
  ];

  const isValido = anoMesBusca.length === 6 && /^\d{6}$/.test(anoMesBusca);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Lançar no Acompanhamento</h1>
          <p className="text-sm text-muted-foreground">
            Filtre pelo AnoMês do Revised Delivery e lance no Acompanhamento de Importações
          </p>
        </div>
      </div>

      <Card>
        <CardContent className="flex flex-wrap items-end gap-3 p-3">
          <div className="w-40">
            <Label>AnoMês (Revised Delivery)</Label>
            <Input
              placeholder="Ex: 202608"
              value={anoMesBusca}
              onChange={(e) => {
                const v = e.target.value.replace(/\D/g, '').slice(0, 6);
                setAnoMesBusca(v);
                setBuscado(false);
              }}
            />
          </div>
          <Button
            onClick={() => {
              if (!isValido) {
                toast.error('Informe o AnoMês no formato YYYYMM (ex: 202608).');
                return;
              }
              setBuscado(true);
              refetch();
            }}
          >
            <CalendarSearch /> Buscar
          </Button>
          {buscado && (
            <Button variant="outline" onClick={() => refetch()}>
              <RefreshCw /> Atualizar
            </Button>
          )}
        </CardContent>
      </Card>

      {buscado && (
        <>
          {/* Resumo */}
          <div className="flex flex-wrap gap-3">
            <div className="rounded-md border bg-card px-4 py-2">
              <p className="text-xs text-muted-foreground">Total encontrado</p>
              <p className="text-2xl font-bold">{(preview ?? []).length}</p>
            </div>
            <div className="rounded-md border border-primary/40 bg-primary/5 px-4 py-2">
              <p className="text-xs text-muted-foreground">Novos para lançar</p>
              <p className="text-2xl font-bold text-primary">{novos.length}</p>
            </div>
            <div className="rounded-md border bg-muted/40 px-4 py-2">
              <p className="text-xs text-muted-foreground">Já lançados (ignorados)</p>
              <p className="text-2xl font-bold text-muted-foreground">{jaLancados.length}</p>
            </div>

            {editavel && novos.length > 0 && (
              <Button
                className="ml-auto"
                size="lg"
                loading={lancar.isPending}
                onClick={() => {
                  if (
                    confirm(
                      `Lançar ${novos.length} registro(s) do AnoMês ${anoMesBusca} no Acompanhamento de Importações?\n\nRegistros já lançados serão ignorados.`,
                    )
                  ) {
                    lancar.mutate();
                  }
                }}
              >
                <Ship /> Lançar {novos.length} registro(s) no Acompanhamento
              </Button>
            )}
            {!editavel && (
              <div className="ml-auto flex items-center rounded-md border border-destructive/40 bg-destructive/5 px-3 py-2 text-sm text-destructive">
                Você não tem permissão para lançar registros.
              </div>
            )}
          </div>

          {/* Tabela */}
          <DataTable
            colunas={colunas}
            dados={preview ?? []}
            carregando={loadingPreview}
            rowKey={(r) => r.cd_compra}
            paginacao={200}
          />
        </>
      )}

      {!buscado && (
        <div className="flex h-64 flex-col items-center justify-center gap-2 text-muted-foreground">
          <CalendarSearch className="h-12 w-12 opacity-30" />
          <p className="text-sm">Informe o AnoMês e clique em Buscar para visualizar os registros.</p>
        </div>
      )}
    </div>
  );
}
