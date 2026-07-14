import { useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ImageOff, Upload } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase';
import { buscarFotoProduto, salvarFotoProduto } from '@/lib/cloudinary';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

/**
 * Foto do produto por referência do fornecedor.
 * Fonte principal: banco de imagens (Cloudinary, mapeado em fotos_produto);
 * fallback: bucket legado do Supabase Storage.
 */
function useFotoProduto(refFornecedor: string | null) {
  return useQuery({
    queryKey: ['foto_produto', refFornecedor],
    enabled: !!refFornecedor,
    staleTime: 5 * 60_000,
    queryFn: async () => {
      const cloudinary = await buscarFotoProduto(refFornecedor!).catch(() => null);
      if (cloudinary) return cloudinary;
      return supabase.storage.from('fotos-produto').getPublicUrl(`${refFornecedor}.jpg`).data.publicUrl;
    },
  });
}

function Imagem({ url, refFornecedor, altura }: { url: string | null | undefined; refFornecedor: string; altura: number }) {
  const [erro, setErro] = useState(false);
  if (!url || erro) {
    return (
      <div
        className="flex w-full flex-col items-center justify-center gap-1 rounded-md border text-muted-foreground"
        style={{ height: altura }}
      >
        <ImageOff className="h-6 w-6" />
        <span className="text-xs">Sem foto</span>
      </div>
    );
  }
  return (
    <img
      key={url}
      src={url}
      alt={refFornecedor}
      className="w-full rounded-md border object-contain"
      style={{ maxHeight: altura }}
      onError={() => setErro(true)}
    />
  );
}

export function FotoInline({
  refFornecedor,
  altura = 160,
  permitirUpload = false,
}: {
  refFornecedor: string | null;
  altura?: number;
  permitirUpload?: boolean;
}) {
  const { data: url } = useFotoProduto(refFornecedor);
  const qc = useQueryClient();
  const fileRef = useRef<HTMLInputElement>(null);
  const [enviando, setEnviando] = useState(false);

  const enviar = async (file: File) => {
    if (!refFornecedor) {
      toast.error('Informe a Ref. Fornecedor antes de enviar a foto.');
      return;
    }
    setEnviando(true);
    try {
      await salvarFotoProduto(refFornecedor, file);
      toast.success('Foto enviada ao banco de imagens.');
      qc.invalidateQueries({ queryKey: ['foto_produto', refFornecedor] });
    } catch (e: any) {
      toast.error(e.message ?? String(e));
    } finally {
      setEnviando(false);
    }
  };

  return (
    <div className="space-y-1">
      <Imagem url={url} refFornecedor={refFornecedor ?? ''} altura={altura} />
      {permitirUpload && (
        <>
          <Button
            variant="outline"
            size="sm"
            className="h-6 w-full text-xs"
            loading={enviando}
            disabled={!refFornecedor}
            onClick={() => fileRef.current?.click()}
          >
            <Upload className="h-3 w-3" /> Enviar foto
          </Button>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) enviar(f);
              e.target.value = '';
            }}
          />
        </>
      )}
    </div>
  );
}

export function FotoProduto({ refFornecedor }: { refFornecedor: string | null }) {
  const { data: url } = useFotoProduto(refFornecedor);
  if (!refFornecedor) return null;
  return (
    <Card className="fixed bottom-4 right-4 z-40 w-44 shadow-lg">
      <CardContent className="p-2">
        <Imagem url={url} refFornecedor={refFornecedor} altura={144} />
        <p className="mt-1 truncate text-center text-xs text-muted-foreground">{refFornecedor}</p>
      </CardContent>
    </Card>
  );
}
