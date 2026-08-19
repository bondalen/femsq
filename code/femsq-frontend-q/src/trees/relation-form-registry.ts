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
  mode?: 'create' | 'edit';
  domain?: SudzSfDoubleDomainMatch | null;
  cnCandidates: RelationPickerCandidateRow[];
  invCandidates: RelationPickerCandidateRow[];
  selectedCnCandidate: RelationPickerCandidateRow | null;
  selectedInvCandidate: RelationPickerCandidateRow | null;
  cnPickerSpec: RelationTreeSpec;
  invPickerSpec: RelationTreeSpec;
  pickerColumns: FemsqTableColumn<RelationPickerCandidateRow>[];
  invSearchValue?: string;
  invSearchLoading?: boolean;
  invSearchStatus?: string;
}

/**
 * Строит форму первой связи `cnInv.link`.
 */
export function buildCnInvLinkForm(options: BuildCnInvLinkFormOptions): RelationFormState {
  const {
    context,
    mode = 'create',
    domain,
    cnCandidates,
    invCandidates,
    selectedCnCandidate,
    selectedInvCandidate,
    cnPickerSpec,
    invPickerSpec,
    pickerColumns,
    invSearchValue,
    invSearchLoading,
    invSearchStatus
  } = options;
  const relationTypeColumns: FemsqTableColumn<RelationPickerCandidateRow>[] = [
    { name: 'label', label: 'Тип связи', field: 'label', align: 'left' }
  ];
  const edge = context.node.edge;
  const nodeTable = context.node.table;
  const invLocked = edge === 'inv.cnInv' || (mode === 'edit' && nodeTable === 'cnInv' && context.root.table === 'invNum');
  const cnLocked = edge === 'cn.cnInv' || (mode === 'edit' && nodeTable === 'cnInv' && context.root.table === 'cn');
  const currentInvKey = Number(context.node.fields.ciInv ?? domain?.invKey ?? null);
  const currentCnKey = Number(context.node.fields.ciCn ?? domain?.cnKey ?? null);
  const currentInvRow =
    (mode === 'edit' && currentInvKey > 0 && selectedInvCandidate?.invKey !== currentInvKey
      ? null
      : selectedInvCandidate) ??
    (domain
      ? {
          rowKey: String(domain.invKey),
          invKey: domain.invKey,
          invNum: domain.invNum,
          cnKey: domain.cnKey,
          cnNum: domain.cnNum
        }
      : null);
  const currentCnRow =
    selectedCnCandidate ??
    (currentCnKey > 0
      ? {
          rowKey: String(currentCnKey),
          cnKey: currentCnKey,
          cnNum: null,
          invKey: null,
          invNum: null
        }
      : null);
  const fallbackInvRow =
    currentInvKey > 0
      ? {
          rowKey: String(currentInvKey),
          invKey: currentInvKey,
          invNum: null,
          cnKey: currentCnKey > 0 ? currentCnKey : null,
          cnNum: currentCnRow?.cnNum ?? null
        }
      : null;
  const effectiveInvRow = currentInvRow ?? fallbackInvRow;
  const fixedInvId = context.node.fromId ?? (currentInvKey > 0 ? currentInvKey : null);
  const fixedCnId = context.node.fromId ?? (currentCnKey > 0 ? currentCnKey : null);
  const title = mode === 'edit' ? 'Редактировать связь СФ с договором' : 'Связать СФ с договором';
  return {
    id: 'cnInv.link',
    title,
    mode,
    fields: [
      {
        name: 'invId',
        label: 'СФ (inv)',
        kind: 'readonly-fixed',
        locked: invLocked,
        required: true,
        value: invLocked ? fixedInvId : effectiveInvRow?.invKey ?? null,
        displayValue:
          invLocked && domain?.invNum
            ? `${domain.invNum} [inv=${context.node.fromId ?? '—'}]`
            : effectiveInvRow?.invNum != null
              ? `${effectiveInvRow.invNum} [inv=${effectiveInvRow.invKey ?? '—'}]`
              : effectiveInvRow?.invKey != null
                ? `[inv=${effectiveInvRow.invKey}]`
              : null
      },
      {
        name: 'cnId',
        label: 'Договор (cn)',
        kind: 'fk-single',
        required: true,
        locked: cnLocked,
        value: cnLocked ? fixedCnId : currentCnRow?.cnKey ?? null,
        displayValue:
          cnLocked && currentCnRow?.cnNum != null
            ? `${currentCnRow.cnNum} [cn=${context.node.fromId ?? '—'}]`
            : currentCnRow?.cnNum != null
              ? `${currentCnRow.cnNum} [cn=${currentCnRow.cnKey ?? '—'}]`
              : currentCnRow?.cnKey != null
                ? `[cn=${currentCnRow.cnKey}]`
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
        searchDebounceMs: invLocked ? undefined : 450,
        searchLoading: invLocked ? undefined : invSearchLoading ?? false,
        searchStatus: invLocked ? undefined : invSearchStatus,
        rows: invLocked && effectiveInvRow ? [effectiveInvRow] : invCandidates,
        columns: pickerColumns,
        selected: effectiveInvRow ? [effectiveInvRow] : [],
        treeSpec: invPickerSpec,
        treeRootId: invLocked ? fixedInvId : effectiveInvRow?.invKey ?? null
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
