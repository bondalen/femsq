/**
 * Хост-дерево КСДСФ: DTO совпадений и доменных веток → узлы FemsqTree.
 */
import type { CnDto, CnNumDto, CnSideDto } from '@/types/contracts';
import type {
  SudzSfDoubleAccntSmpl,
  SudzSfDoubleDomainMatch,
  SudzSfDoubleInvDbt
} from '@/types/sudz';

/** Вид узла контура `docs/development/notes/UI/02-12_femsq-tree/sudz-sf-double-tree.md`. */
export type SudzSfDoubleTreeKind =
  | 'sf-root'
  | 'sf-folder'
  | 'sf-num-group'
  | 'sf-item'
  | 'sf-cn-links'
  | 'sf-cn-link'
  | 'cn-num-group'
  | 'cn-item'
  | 'cn-parties'
  | 'cn-side'
  | 'cn-orgs'
  | 'cn-org'
  | 'sgk-simple'
  | 'sgk-smpl'
  | 'sgk-accnt'
  | 'sgk-dbt'
  | 'sf-debts'
  | 'inv-dbt'
  | 'inv-dbt-dbt'
  | 'dbt';

/** Строка детали узла. */
export interface SudzSfDoubleTreeField {
  label: string;
  value: string;
}

/** Узел host-tree для FemsqTree. */
export interface SudzSfDoubleTreeNode {
  id: string;
  kind: SudzSfDoubleTreeKind;
  title: string;
  subtitle?: string;
  current?: boolean;
  fields: SudzSfDoubleTreeField[];
  note?: string;
  children?: SudzSfDoubleTreeNode[];
  leaf?: boolean;
}

/** Карточка договора для ветки сторон/номеров. */
export interface SudzSfDoubleTreeContract {
  cn: CnDto | null;
  nums: CnNumDto[];
  sides: CnSideDto[];
}

/** Дополнительные ветки, загруженные по выбранному СФ. */
export interface SudzSfDoubleTreeExtras {
  contracts: Record<number, SudzSfDoubleTreeContract>;
  smpls: SudzSfDoubleAccntSmpl[];
  invDbts: SudzSfDoubleInvDbt[];
}

/** Результат сборки корня и стартового раскрытия. */
export interface SudzSfDoubleTreeBuild {
  nodes: SudzSfDoubleTreeNode[];
  expandedKeys: string[];
  selectedKey: string | null;
}

const EXPAND_KINDS: ReadonlySet<SudzSfDoubleTreeKind> = new Set([
  'sf-root',
  'sf-folder',
  'sf-num-group',
  'sf-cn-links',
  'sf-cn-link',
  'cn-num-group',
  'cn-parties',
  'cn-side',
  'cn-orgs',
  'sgk-simple',
  'sgk-smpl',
  'sgk-accnt',
  'sf-debts'
]);

/** Пустой контекст, если догрузка ещё не пришла. */
export const EMPTY_TREE_EXTRAS: SudzSfDoubleTreeExtras = {
  contracts: {},
  smpls: [],
  invDbts: []
};

/**
 * Собирает дерево «от выбранного СФ вверх».
 *
 * @param selected выбранная строка списка совпадений
 * @param matches все совпадения текущего номера
 * @param extras договор/стороны/СГК/invDbt
 * @return корни, ключи раскрытия и выбранный корень
 */
export function buildSudzSfDoubleTree(
  selected: SudzSfDoubleDomainMatch | null | undefined,
  matches: readonly SudzSfDoubleDomainMatch[],
  extras: SudzSfDoubleTreeExtras = EMPTY_TREE_EXTRAS
): SudzSfDoubleTreeBuild {
  if (!selected) {
    return { nodes: [], expandedKeys: [], selectedKey: null };
  }

  const prefix = `sf-root:${selected.invKey}`;
  const invoices = uniqueByInvKey([selected, ...matches]);
  const links = uniqueByCiKey(matches.filter((row) => row.invKey === selected.invKey && row.ciKey != null));
  const smpls = extras.smpls ?? [];
  const invDbts = extras.invDbts ?? [];

  const numChildren = invoices.map((row) =>
    makeNode(`${prefix}:nums:sf:${row.invKey}`, 'sf-item', `СФ, номер ${dash(row.invNum)}`, {
      subtitle: `inv=${row.invKey}`,
      current: row.invKey === selected.invKey,
      fields: sfFields(row),
      children: []
    })
  );

  const linkChildren = links.map((row, index) => {
    const ci = row.ciKey as number;
    const linkId = `${prefix}:links:ci:${ci}`;
    const cnId = `${linkId}:cn`;
    const pack = row.cnKey != null ? extras.contracts[row.cnKey] : undefined;
    const nums = pack?.nums?.length ? pack.nums : row.cnKey != null
      ? [{
          cnnKey: row.cnKey,
          cnnNum: row.cnNum,
          cnnCn: row.cnKey,
          cnnType: null,
          cnnTypeName: null,
          cnnNote: null
        } satisfies CnNumDto]
      : [];
    const cnNodes = nums.map((num, numIndex) => {
      const cn = pack?.cn;
      const cnKey = num.cnnCn;
      return makeNode(`${cnId}:item:${cnKey}:${num.cnnKey}`, 'cn-item', `Договор, номер ${dash(num.cnnNum)}`, {
        subtitle: `cn=${cnKey}`,
        current: numIndex === 0,
        fields: [
          { label: 'cnKey', value: dash(cnKey) },
          { label: 'cnNum', value: dash(num.cnnNum) },
          { label: 'cnnType', value: dash(num.cnnTypeName ?? num.cnnType) },
          { label: 'cnMark', value: dash(cn?.cnMark) },
          { label: 'cn_date', value: formatDate(cn?.cnDate) },
          { label: 'cn_note', value: dash(cn?.cnNote) },
          { label: 'cnnNote', value: dash(num.cnnNote) }
        ],
        children: []
      });
    });

    return makeNode(linkId, 'sf-cn-link', `Связь СФ и договора ${index + 1}`, {
      subtitle: `ci=${ci}`,
      fields: [
        { label: 'ciKey', value: dash(ci) },
        { label: 'ciCn / cnKey', value: dash(row.cnKey) },
        { label: 'cnNum', value: dash(row.cnNum) }
      ],
      children: [
        makeNode(cnId, 'cn-num-group', 'Договор, номера', {
          subtitle: row.cnKey != null ? `cn=${row.cnKey}` : undefined,
          fields: [
            { label: 'cnKey(и)', value: dash(row.cnKey) },
            { label: 'cnNum(и)', value: nums.map((num) => dash(num.cnnNum)).join(', ') },
            { label: 'количество', value: String(nums.length) }
          ],
          children: cnNodes
        }),
        buildPartiesNode(`${linkId}:parties`, pack?.sides ?? [])
      ]
    });
  });

  const root = makeNode(prefix, 'sf-root', `СФ, номер ${dash(selected.invNum)} (совпадающий)`, {
    subtitle: `inv=${selected.invKey}`,
    current: true,
    fields: sfFields(selected),
    children: [
      makeNode(`${prefix}:folder`, 'sf-folder', 'СФ', {
        subtitle: `inv=${selected.invKey}`,
        fields: [
          { label: 'invKey', value: dash(selected.invKey) },
          { label: 'invNum', value: dash(selected.invNum) }
        ],
        children: [
          makeNode(`${prefix}:nums`, 'sf-num-group', 'СФ, номера', {
            subtitle: `${invoices.length} шт.`,
            fields: [
              { label: 'InvNum-group', value: dash(selected.invNum) },
              { label: 'invEntered', value: enteredRange(invoices) },
              { label: 'количество', value: String(invoices.length) }
            ],
            note: 'Группа существующих СФ с тем же номером, что у кандидата Excel.',
            children: numChildren
          }),
          makeNode(`${prefix}:links`, 'sf-cn-links', 'СФ, связи с договорами', {
            subtitle: `${links.length} св.`,
            fields: [
              { label: 'ciKey(и)', value: joinKeys(links.map((row) => row.ciKey)) },
              { label: 'cnKey(и)', value: joinKeys(links.map((row) => row.cnKey)) },
              { label: 'количество связей', value: String(links.length) }
            ],
            note: 'Связь СФ ↔ договор через cnInv (ciKey).',
            children: [...linkChildren, buildSgkNode(`${prefix}:sgk`, smpls)]
          }),
          buildInvDbtFolder(`${prefix}:debts`, invDbts)
        ]
      })
    ]
  });

  return {
    nodes: [root],
    expandedKeys: collectExpandedKeys([root]),
    selectedKey: root.id
  };
}

/**
 * Ключи узлов, которые при открытии карточки сразу показывают каркас.
 *
 * @param nodes корни
 * @return список id
 */
export function collectExpandedKeys(nodes: readonly SudzSfDoubleTreeNode[]): string[] {
  const keys: string[] = [];
  walk(nodes, (node) => {
    if (EXPAND_KINDS.has(node.kind)) {
      keys.push(node.id);
    }
  });
  return keys;
}

/**
 * Текст для пустого значения.
 *
 * @param value ключ или подпись
 * @return строка или тире
 */
export function dash(value: string | number | null | undefined): string {
  if (value == null || value === '') {
    return '—';
  }
  return String(value);
}

function buildPartiesNode(id: string, sides: CnSideDto[]): SudzSfDoubleTreeNode {
  const types = [...new Set(sides.map((side) => side.cnSTypeName || String(side.cnSType)))];
  const sideNodes = sides.map((side, index) => {
    const sideId = `${id}:side:${side.cnSKey}`;
    const typeName = side.cnSTypeName || String(side.cnSType);
    const dates = side.smpls.flatMap((smpl) => smpl.orgs.map((org) => org.csoCnDate)).filter(Boolean);
    const orgGroupId = `${sideId}:orgs`;
    const orgNodes = side.smpls.map((smpl) =>
      makeNode(`${orgGroupId}:org:${smpl.csosOrgId}`, 'cn-org', dash(smpl.orgLabel), {
        subtitle: `org_id=${smpl.csosOrgId}`,
        fields: [
          { label: 'csosKey', value: dash(smpl.csosKey) },
          { label: 'csosOrgId', value: dash(smpl.csosOrgId) },
          { label: 'orgLabel', value: dash(smpl.orgLabel) },
          { label: 'csoCnDate', value: formatDate(smpl.orgs[0]?.csoCnDate) },
          { label: 'date_beg', value: formatDate(smpl.orgs[0]?.dateBeg) },
          { label: 'date_end', value: formatDate(smpl.orgs[0]?.dateEnd) },
          { label: 'cn_s_org_key', value: dash(smpl.orgs[0]?.cnSOrgKey) }
        ],
        children: []
      })
    );
    return makeNode(sideId, 'cn-side', `Сторона ${index + 1}. ${typeName}`, {
      subtitle: `cn_s=${side.cnSKey}`,
      fields: [
        { label: 'cn_s_key', value: dash(side.cnSKey) },
        { label: 'cn_s_type', value: `${side.cnSType} · ${typeName}` },
        { label: 'csoCnDate', value: dates.length ? dates.map((d) => formatDate(d)).join(', ') : '—' }
      ],
      children: [
        makeNode(orgGroupId, 'cn-orgs', `Сторона. ${typeName}. Организации`, {
          subtitle: `${side.smpls.length} шт.`,
          fields: [
            { label: 'orgKey(и)', value: joinKeys(side.smpls.map((smpl) => smpl.csosOrgId)) },
            { label: 'количество организаций', value: String(side.smpls.length) }
          ],
          children: orgNodes
        })
      ]
    });
  });

  return makeNode(id, 'cn-parties', 'Договор. Стороны', {
    subtitle: sides.length ? `${types.join(', ')} · ${sides.length}` : 'нет сторон',
    fields: [
      { label: 'cn_s_type', value: types.length ? types.join(', ') : '—' },
      { label: 'количество сторон', value: String(sides.length) }
    ],
    note: sides.length ? 'Роли заказчик/исполнитель из cn_s.' : 'В БД нет строк cn_s для этого договора.',
    children: sideNodes
  });
}

function buildSgkNode(id: string, smpls: SudzSfDoubleAccntSmpl[]): SudzSfDoubleTreeNode {
  const smplNodes = smpls.map((smpl) => {
    const smplId = `${id}:cias:${smpl.ciasKey}`;
    const accntNodes = (smpl.accounts ?? []).map((accnt) => {
      const accntId = `${smplId}:cia:${accnt.ciaKey}`;
      const dbtNodes = (accnt.debts ?? []).map((debt) =>
        makeNode(`${accntId}:cid:${debt.cnInvDbtKey}`, 'sgk-dbt', `cn_inv_dbt ${debt.cnInvDbtKey}`, {
          subtitle: `№ ${dash(debt.number)}`,
          fields: [
            { label: 'cn_inv_dbt_key', value: dash(debt.cnInvDbtKey) },
            { label: 'number', value: dash(debt.number) },
            { label: 'debt_type', value: dash(debt.debtType) },
            { label: 'date_start', value: formatDate(debt.dateStart) },
            { label: 'date_maturity', value: formatDate(debt.dateMaturity) },
            { label: 'dbt_ttl', value: formatMoney(debt.dbtTtl) },
            { label: 'dbt_overd', value: formatMoney(debt.dbtOverd) },
            { label: 'upl', value: dash(debt.uplKey) },
            { label: 'doc_base', value: dash(debt.docBase) },
            { label: 'link', value: dash(debt.link) },
            { label: 'mark', value: dash(debt.mark) }
          ],
          children: []
        })
      );
      return makeNode(accntId, 'sgk-accnt', `cnInvAccnt cia=${accnt.ciaKey}`, {
        subtitle: dash(accnt.ciaName),
        fields: [
          { label: 'ciaKey', value: dash(accnt.ciaKey) },
          { label: 'ciaCn_s_org', value: dash(accnt.ciaCnSOrg) },
          { label: 'ciaName', value: dash(accnt.ciaName) },
          { label: 'ciaNote', value: dash(accnt.ciaNote) },
          { label: 'ciaCnInvAccntSmpl', value: dash(accnt.ciaCnInvAccntSmpl) }
        ],
        children: dbtNodes
      });
    });
    return makeNode(smplId, 'sgk-smpl', `cnInvAccntSmpl ${smpl.ciasKey}`, {
      subtitle: `accnt=${dash(smpl.accountNum)} · ci=${smpl.ciasCnInv}`,
      fields: [
        { label: 'ciasKey', value: dash(smpl.ciasKey) },
        { label: 'ciasCnInv', value: dash(smpl.ciasCnInv) },
        { label: 'ciasAccnt', value: dash(smpl.ciasAccnt) },
        { label: 'account_num', value: dash(smpl.accountNum) },
        { label: 'ciasCn_s_org_smpl', value: dash(smpl.ciasCnSOrgSmpl) },
        { label: 'ciasNote', value: dash(smpl.ciasNote) }
      ],
      children: accntNodes
    });
  });

  return makeNode(id, 'sgk-simple', 'СФ, СГК простой', {
    subtitle: smpls.length ? `${smpls.length} smpl` : 'нет СГК',
    fields: [
      { label: 'cnInvAccntSmpl', value: smpls.length ? smpls.map((s) => String(s.ciasKey)).join(', ') : '—' },
      { label: 'количество', value: String(smpls.length) }
    ],
    note: smpls.length
      ? 'Старая структура: cnInvAccntSmpl → cnInvAccnt → cn_inv_dbt.'
      : 'В БД нет cnInvAccntSmpl для связей этого СФ.',
    children: smplNodes
  });
}

function buildInvDbtFolder(id: string, invDbts: SudzSfDoubleInvDbt[]): SudzSfDoubleTreeNode {
  const invNodes = invDbts.map((invDbt) => {
    const invId = `${id}:id:${invDbt.idKey}`;
    const linkNodes = (invDbt.links ?? []).map((link) => {
      const linkId = `${invId}:idd:${link.iddKey}`;
      const dbtNode = link.dbt
        ? [
            makeNode(`${linkId}:dbt:${link.dbt.dbtKey}`, 'dbt', `Dbt ${link.dbt.dbtKey}`, {
              subtitle: formatMoney(link.dbt.values[0]?.dvTtl),
              fields: [
                { label: 'dbtKey', value: dash(link.dbt.dbtKey) },
                { label: 'dbtNote', value: dash(link.dbt.dbtNote) },
                ...(link.dbt.values ?? []).flatMap((value) => [
                  { label: `dvKey ${value.dvKey} ttl`, value: formatMoney(value.dvTtl) },
                  { label: `dvKey ${value.dvKey} overd`, value: formatMoney(value.dvOverd) },
                  { label: `dvKey ${value.dvKey} upl`, value: dash(value.dvUpl) }
                ])
              ],
              children: []
            })
          ]
        : [];
      return makeNode(linkId, 'inv-dbt-dbt', `invDbtDbt ${link.iddKey}`, {
        subtitle: `Dbt=${dash(link.iddDbt)}`,
        fields: [
          { label: 'iddKey', value: dash(link.iddKey) },
          { label: 'iddInv', value: dash(link.iddInv) },
          { label: 'iddDbt', value: dash(link.iddDbt) },
          { label: 'iddInvDbt', value: dash(link.iddInvDbt) }
        ],
        children: dbtNode
      });
    });
    return makeNode(invId, 'inv-dbt', `invDbt ${invDbt.idKey}`, {
      subtitle: `idNum=${dash(invDbt.idNum)}`,
      fields: [
        { label: 'idKey', value: dash(invDbt.idKey) },
        { label: 'idInv', value: dash(invDbt.idInv) },
        { label: 'idNum', value: dash(invDbt.idNum) },
        { label: 'idNote', value: dash(invDbt.idNote) }
      ],
      children: linkNodes
    });
  });

  return makeNode(id, 'sf-debts', 'СФ, задолженности', {
    subtitle: invDbts.length ? `${invDbts.length} invDbt` : 'нет invDbt',
    fields: [
      { label: 'invDbt', value: invDbts.length ? invDbts.map((row) => String(row.idKey)).join(', ') : '—' },
      { label: 'количество', value: String(invDbts.length) }
    ],
    note: invDbts.length
      ? 'Новая структура: invDbt → invDbtDbt → Dbt.'
      : 'В БД нет invDbt для этого СФ (новая структура ещё не заполнена).',
    children: invNodes
  });
}

function makeNode(
  id: string,
  kind: SudzSfDoubleTreeKind,
  title: string,
  rest: Omit<SudzSfDoubleTreeNode, 'id' | 'kind' | 'title' | 'fields'> & {
    fields: SudzSfDoubleTreeField[];
  }
): SudzSfDoubleTreeNode {
  return { id, kind, title, ...rest };
}

function sfFields(row: SudzSfDoubleDomainMatch): SudzSfDoubleTreeField[] {
  return [
    { label: 'invKey', value: dash(row.invKey) },
    { label: 'invNum', value: dash(row.invNum) },
    { label: 'invNumKey', value: dash(row.invNumKey) },
    { label: 'invEntered', value: dash(row.invEntered) },
    { label: 'ciKey', value: dash(row.ciKey) },
    { label: 'договор', value: row.cnKey ? `${dash(row.cnNum)} (cn=${row.cnKey})` : dash(row.cnNum) }
  ];
}

function uniqueByInvKey(rows: readonly SudzSfDoubleDomainMatch[]): SudzSfDoubleDomainMatch[] {
  const seen = new Set<number>();
  const out: SudzSfDoubleDomainMatch[] = [];
  for (const row of rows) {
    if (seen.has(row.invKey)) {
      continue;
    }
    seen.add(row.invKey);
    out.push(row);
  }
  return out;
}

function uniqueByCiKey(rows: readonly SudzSfDoubleDomainMatch[]): SudzSfDoubleDomainMatch[] {
  const seen = new Set<number>();
  const out: SudzSfDoubleDomainMatch[] = [];
  for (const row of rows) {
    if (row.ciKey == null || seen.has(row.ciKey)) {
      continue;
    }
    seen.add(row.ciKey);
    out.push(row);
  }
  return out;
}

function joinKeys(values: Array<number | null | undefined>): string {
  const parts = values.filter((value): value is number => value != null).map(String);
  return parts.length > 0 ? parts.join(', ') : '—';
}

function enteredRange(rows: readonly SudzSfDoubleDomainMatch[]): string {
  const values = rows.map((row) => row.invEntered).filter((value): value is string => !!value);
  if (values.length === 0) {
    return '—';
  }
  const unique = [...new Set(values)];
  if (unique.length === 1) {
    return unique[0];
  }
  return unique.join(', ');
}

function formatDate(value: string | null | undefined): string {
  if (!value) {
    return '—';
  }
  return value.length >= 10 ? value.slice(0, 10) : value;
}

function formatMoney(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) {
    return '—';
  }
  return String(value);
}

function walk(nodes: readonly SudzSfDoubleTreeNode[], visit: (node: SudzSfDoubleTreeNode) => void): void {
  for (const node of nodes) {
    visit(node);
    if (node.children) {
      walk(node.children, visit);
    }
  }
}
