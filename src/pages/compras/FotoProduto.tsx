import { useEffect, useState } from 'react';
import { ImageOff } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/card';

/**
 * Foto do produto por referência do fornecedor (bucket fotos-produto).
 * Substitui o caminho de rede \\srvfs\...\13. FOTOS MIX do Access.
 */
export function FotoInline({ refFornecedor, altura = 160 }: { refFornecedor: string | null; altura?: number }) {
  const [erro, setErro] = useState(false);
  const url = refFornecedor
    ? supabase.storage.from('fotos-produto').getPublicUrl(`${refFornecedor}.jpg`).data.publicUrl
    : null;

  useEffect(() => setErro(false), [refFornecedor]);

  if (!refFornecedor || !url || erro) {
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
      src={url}
      alt={refFornecedor}
      className="w-full rounded-md border object-contain"
      style={{ maxHeight: altura }}
      onError={() => setErro(true)}
    />
  );
}

export function FotoProduto({ refFornecedor }: { refFornecedor: string | null }) {
  const [url, setUrl] = useState<string | null>(null);
  const [erro, setErro] = useState(false);

  useEffect(() => {
    setErro(false);
    setUrl(null);
    if (!refFornecedor) return;
    const { data } = supabase.storage.from('fotos-produto').getPublicUrl(`${refFornecedor}.jpg`);
    setUrl(data.publicUrl);
  }, [refFornecedor]);

  if (!refFornecedor) return null;

  return (
    <Card className="fixed bottom-4 right-4 z-40 w-44 shadow-lg">
      <CardContent className="p-2">
        {url && !erro ? (
          <img
            src={url}
            alt={refFornecedor}
            className="h-36 w-full rounded object-contain"
            onError={() => setErro(true)}
          />
        ) : (
          <div className="flex h-36 flex-col items-center justify-center gap-1 text-muted-foreground">
            <ImageOff className="h-6 w-6" />
            <span className="text-xs">Sem foto</span>
          </div>
        )}
        <p className="mt-1 truncate text-center text-xs text-muted-foreground">{refFornecedor}</p>
      </CardContent>
    </Card>
  );
}
