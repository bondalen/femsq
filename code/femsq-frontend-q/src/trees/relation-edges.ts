/**
 * Whitelist рёбер v1. Имена совпадают с Java {@code RelationEdgeCatalog}.
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

/** Каталог КСДСФ / Договоров (19 рёбер v1 + org_id / og). */
export const RELATION_EDGES: Record<string, RelationEdgeMeta> = {
  'invNum.inv': { from: 'invNum', to: 'inv', card: 'N:1' },
  'inv.cnInv': { from: 'inv', to: 'cnInv', card: '1:N' },
  'cnInv.cn': { from: 'cnInv', to: 'cn', card: 'N:1' },
  'cnInv.inv': { from: 'cnInv', to: 'inv', card: 'N:1' },
  'cn.cnInv': { from: 'cn', to: 'cnInv', card: '1:N' },
  'cn.cnNum': { from: 'cn', to: 'cnNum', card: '1:N' },
  'cn.cn_s': { from: 'cn', to: 'cn_s', card: '1:N' },
  'cn_s.smpl': { from: 'cn_s', to: 'smpl', card: '1:N' },
  'smpl.org': { from: 'smpl', to: 'org', card: '1:N' },
  'smpl.orgId': { from: 'smpl', to: 'orgId', card: 'N:1' },
  'orgId.og': { from: 'orgId', to: 'og', card: 'N:1' },
  'og.orgId': { from: 'og', to: 'orgId', card: '1:N' },
  'cnInv.cias': { from: 'cnInv', to: 'cias', card: '1:N' },
  'cias.cia': { from: 'cias', to: 'cia', card: '1:N' },
  'cia.cid': { from: 'cia', to: 'cid', card: '1:N' },
  'cid.upl': { from: 'cid', to: 'upl', card: 'N:1' },
  'inv.invDbt': { from: 'inv', to: 'invDbt', card: '1:N' },
  'invDbt.idd': { from: 'invDbt', to: 'idd', card: '1:N' },
  'idd.dbt': { from: 'idd', to: 'dbt', card: 'N:1' },
  'dbt.dv': { from: 'dbt', to: 'dv', card: '1:N' }
};
