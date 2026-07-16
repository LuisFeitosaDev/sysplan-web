import { forwardRef, type InputHTMLAttributes } from 'react';
import { X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SearchInputProps extends InputHTMLAttributes<HTMLInputElement> {
  onClear?: () => void;
}

export const SearchInput = forwardRef<HTMLInputElement, SearchInputProps>(
  ({ className, value, onClear, ...props }, ref) => {
    const hasValue = value && String(value).length > 0;

    return (
      <div className="relative w-full">
        <input
          type="text"
          ref={ref}
          value={value}
          className={cn(
            'flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 pr-9 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50',
            className,
          )}
          {...props}
        />
        {hasValue && (
          <button
            type="button"
            onClick={() => {
              if (onClear) onClear();
            }}
            className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <X size={16} />
          </button>
        )}
      </div>
    );
  },
);
SearchInput.displayName = 'SearchInput';
