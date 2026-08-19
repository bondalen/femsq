/**
 * Registry host-side форм RelationTree по form-id из JSON.
 */
import type { FemsqTableColumn } from 'fequlib';

import type { SudzSfDoubleDomainMatch } from '@/types/sudz';
import type { RelationFormState, RelationPickerRow } from '@/trees/relation-forms';
import type { RelationTreeActionContext, RelationTreeSpec } from '@/trees/relation-tree';

export type RelationPickerCandidateRow = RelationPickerRow & {
  rowKey: string;
  cnKey?: number | null;
  cnNum?: string | null;
  invKey?: number | null;
  invNum?: string | null;
  label?: string | null;
};

export interface BuildCnInvLinkFormOptions {
  context: RelationTreeActionContext;
  domain?: SudzSfDoubleDomainMatch | null;
  cnCandidates: RelationPickerCandidateRow[];
  invCandidates: RelationPickerCandidateRow[];
  selectedCnCandidate: RelationPickerCandidateRow | null;
  selectedInvCandidate: RelationPickerCandidateRow | null;
  cnPickerSpec: RelationTreeSpec;
  invPickerSpec: RelationTreeSpec;
  pickerColumns: FemsqTableColumn<RelationPickerCandidateRow>[];
  invSearchValue?: string;
}

/**
 * Строит форму первой связи `cnInv.link`.
 */
export function buildCnInvLinkForm(options: BuildCnInvLinkFormOptions): RelationFormState {
  const {
    context,
    domain,
    cnCandidates,
    invCandidates,
    selectedCnCandidate,
    selectedInvCandidate,
    cnPickerSpec,
    invPickerSpec,
    pickerColumns,
    invSearchValue
  } = options;
  const relationTypeColumns: FemsqTableColumn<RelationPickerCandidateRow>[] = [
    { name: 'label', label: 'Тип связи', field: 'label', align: 'left' }
  ];
  const edge = context.node.edge;
  const invLocked = edge === 'inv.cnInv';
  const cnLocked = edge === 'cn.cnInv';
  const currentInvRow =
    selectedInvCandidate ??
    (domain
      ? {
          rowKey: String(domain.invKey),
          invKey: domain.invKey,
          invNum: domain.invNum,
          cnKey: domain.cnKey,
          cnNum: domain.cnNum
        }
      : null);
  const currentCnRow = selectedCnCandidate;
  return {
    id: 'cnInv.link',
    title: 'Связать СФ с договором',
    mode: 'create',
    fields: [
      {
        name: 'invId',
        label: 'СФ (inv)',
        kind: 'readonly-fixed',
        locked: invLocked,
        required: true,
        value: invLocked ? context.node.fromId : currentInvRow?.invKey ?? null,
        displayValue:
          invLocked && domain?.invNum
            ? `${domain.invNum} [inv=${context.node.fromId ?? '—'}]`
            : currentInvRow?.invNum != null
              ? `${currentInvRow.invNum} [inv=${currentInvRow.invKey ?? '—'}]`
              : null
      },
      {
        name: 'cnId',
        label: 'Договор (cn)',
        kind: 'fk-single',
        required: true,
        locked: cnLocked,
        value: cnLocked ? context.node.fromId : currentCnRow?.cnKey ?? null,
        displayValue:
          cnLocked && currentCnRow?.cnNum != null
            ? `${currentCnRow.cnNum} [cn=${context.node.fromId ?? '—'}]`
            : currentCnRow?.cnNum != null
              ? `${currentCnRow.cnNum} [cn=${currentCnRow.cnKey ?? '—'}]`
            : null
      },
      {
        name: 'relationTypeId',
        label: 'Тип связи',
        kind: 'enum-fk',
        value: null,
        displayValue: 'Пока не требуется для ags.cnInv'
      }
    ],
    pickers: [
      {
        id: 'cn',
        kind: 'table-tree-picker',
        tabLabel: 'Договор',
        valueField: 'cnKey',
        displayField: 'cnNum',
        disabled: cnLocked,
        rows: cnLocked && currentCnRow ? [currentCnRow] : cnCandidates,
        columns: pickerColumns,
        selected: currentCnRow ? [currentCnRow] : [],
        treeSpec: cnPickerSpec,
        treeRootId: currentCnRow?.cnKey ?? null
      },
      {
        id: 'inv',
        kind: 'table-tree-picker',
        tabLabel: 'СФ',
        valueField: 'invKey',
        displayField: 'invNum',
        disabled: invLocked,
        searchValue: invLocked ? undefined : invSearchValue ?? '',
        searchPlaceholder: invLocked ? undefined : 'Номер СФ',
        searchHint: invLocked ? undefined : 'Введите точный номер и нажмите «Найти».',
        rows: invLocked && currentInvRow ? [currentInvRow] : invCandidates,
        columns: pickerColumns,
        selected: currentInvRow ? [currentInvRow] : [],
        treeSpec: invPickerSpec,
        treeRootId: invLocked ? context.node.fromId : currentInvRow?.invKey ?? null
      },
      {
        id: 'relationType',
        kind: 'lookup-list',
        tabLabel: 'Тип связи',
        valueField: 'rowKey',
        displayField: 'label',
        disabled: true,
        rows: [{ rowKey: 'not-used', label: 'Для ags.cnInv отдельный тип связи пока не нужен' }],
        columns: relationTypeColumns,
        selected: []
      }
    ]
  };
}
