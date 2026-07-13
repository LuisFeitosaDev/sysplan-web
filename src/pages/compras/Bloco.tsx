import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

/**
 * Bloco visual do formulário (estilo do Access legado): borda colorida à
 * esquerda + título pequeno, campos compactos com rótulo à esquerda.
 */
const CORES_BLOCO = {
  ambar: 'border-amber-500/70',
  ciano: 'border-cyan-500/70',
  violeta: 'border-violet-500/70',
  verde: 'border-emerald-500/70',
  rosa: 'border-pink-500/70',
  marrom: 'border-orange-700/70',
  cinza: 'border-slate-400/70',
} as const;

export type CorBloco = keyof typeof CORES_BLOCO;

export function Bloco({
  titulo,
  cor,
  children,
  className,
}: {
  titulo: string;
  cor: CorBloco;
  children: ReactNode;
  className?: string;
}) {
  return (
    <fieldset className={cn('rounded-md border border-l-4 bg-card p-2', CORES_BLOCO[cor], className)}>
      <legend className="px-1 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
        {titulo}
      </legend>
      <div className="space-y-1">{children}</div>
    </fieldset>
  );
}

export function CampoLinha({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[96px_1fr] items-center gap-1.5">
      <span className="truncate text-xs text-muted-foreground" title={label}>
        {label}
      </span>
      {children}
    </div>
  );
}

/** Classe padrão dos controles compactos dentro dos blocos */
export const CTRL = 'h-7 px-2 text-xs';
