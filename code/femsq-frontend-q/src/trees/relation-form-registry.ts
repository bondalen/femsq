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
  domain: SudzSfDoubleDomainMatch;
  cnCandidates: RelationPickerCandidateRow[];
  selectedCnCandidate: RelationPickerCandidateRow | null;
  cnPickerSpec: RelationTreeSpec;
  invPickerSpec: RelationTreeSpec;
  pickerColumns: FemsqTableColumn<RelationPickerCandidateRow>[];
}

/**
 * Строит форму первой связи `cnInv.link`.
 */
export function buildCnInvLinkForm(options: BuildCnInvLinkFormOptions): RelationFormState {
  const { context, domain, cnCandidates, selectedCnCandidate, cnPickerSpec, invPickerSpec, pickerColumns } =
    options;
  const relationTypeColumns: FemsqTableColumn<RelationPickerCandidateRow>[] = [
    { name: 'label', label: 'Тип связи', field: 'label', align: 'left' }
  ];
  const currentInvRow: RelationPickerCandidateRow = {
    rowKey: String(domain.invKey),
    invKey: domain.invKey,
    invNum: domain.invNum,
    cnKey: domain.cnKey,
    cnNum: domain.cnNum
  };
  return {
    id: 'cnInv.link',
    title: 'Связать СФ с договором',
    mode: 'create',
    fields: [
      {
        name: 'invId',
        label: 'СФ (inv)',
        kind: 'readonly-fixed',
        locked: true,
        required: true,
        value: context.node.fromId,
        displayValue: domain.invNum
          ? `${domain.invNum} [inv=${context.node.fromId ?? '—'}]`
          : String(context.node.fromId ?? '—')
      },
      {
        name: 'cnId',
        label: 'Договор (cn)',
        kind: 'fk-single',
        required: true,
        value: selectedCnCandidate?.cnKey ?? null,
        displayValue:
          selectedCnCandidate?.cnNum != null
            ? `${selectedCnCandidate.cnNum} [cn=${selectedCnCandidate.cnKey ?? '—'}]`
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
        rows: cnCandidates,
        columns: pickerColumns,
        selected: selectedCnCandidate ? [selectedCnCandidate] : [],
        treeSpec: cnPickerSpec,
        treeRootId: selectedCnCandidate?.cnKey ?? null
      },
      {
        id: 'inv',
        kind: 'table-tree-picker',
        tabLabel: 'СФ',
        valueField: 'invKey',
        displayField: 'invNum',
        disabled: true,
        rows: [currentInvRow],
        columns: pickerColumns,
        selected: [currentInvRow],
        treeSpec: invPickerSpec,
        treeRootId: context.node.fromId
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
