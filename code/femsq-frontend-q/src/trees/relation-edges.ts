/**
 * Whitelist рёбер среза 1. Имена совпадают с Java {@code RelationEdgeCatalog}.
 * Walker этот файл не читает (T4b).
 */
import type { RelationCard } from '@/trees/relation-tree';

export type { RelationCard };

/** Описание ребра на хосте (без SQL). */
export interface RelationEdgeMeta {
  from: string;
  to: string;
  card: RelationCard;
}

/** Каталог среза 1: только три ребра. */
export const RELATION_EDGES: Record<string, RelationEdgeMeta> = {
  'invNum.inv': { from: 'invNum', to: 'inv', card: 'N:1' },
  'inv.cnInv': { from: 'inv', to: 'cnInv', card: '1:N' },
  'cnInv.cn': { from: 'cnInv', to: 'cn', card: 'N:1' }
};
