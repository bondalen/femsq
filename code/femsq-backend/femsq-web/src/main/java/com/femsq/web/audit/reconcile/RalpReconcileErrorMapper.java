package com.femsq.web.audit.reconcile;

import com.femsq.web.audit.stage2.RalpFkAnomalyFormatter;
import com.femsq.web.audit.stage2.RalpFkAnomalyRow;
import java.util.ArrayList;
import java.util.List;

/**
 * Преобразование Stage 2 A1–A4 ({@link RalpFkAnomalyRow}) в hit'ы дерева сверки (§9.3.8.4).
 * Primary: стройка → отправитель → иные (дата и пр.).
 */
public final class RalpReconcileErrorMapper {

    private RalpReconcileErrorMapper() {
    }

    /**
     * @param anomalies строки Stage 2 с незаполненным FK/датой
     * @return hit'ы для {@link Type5ReconcileErrorGrouper#group}
     */
    public static List<Type5ReconcileErrorGrouper.ErrorHit> toErrorHits(List<RalpFkAnomalyRow> anomalies) {
        if (anomalies == null || anomalies.isEmpty()) {
            return List.of();
        }
        List<Type5ReconcileErrorGrouper.ErrorHit> hits = new ArrayList<>(anomalies.size());
        for (RalpFkAnomalyRow row : anomalies) {
            if (row == null || !row.isUnresolved()) {
                continue;
            }
            boolean cstapMissing = row.cstAgPn() == null;
            boolean senderMissing = row.ogSender() == null;
            boolean dateMissing = row.reportDate() == null;
            String primary = Type5ReconcileErrorGrouper.primaryForCanonicalGaps(
                    cstapMissing, senderMissing, dateMissing, false);
            String groupValue = null;
            String reasonCode;
            String detail;
            if (Type5ReconcileErrorGrouper.PRIMARY_MISSING_CSTAP.equals(primary)) {
                reasonCode = "A1_A2_CST";
                String code = row.cstCodeStr();
                groupValue = (code == null || code.isBlank()) ? "(пусто)" : code.trim();
                List<String> lines = RalpFkAnomalyFormatter.reasonLines(row);
                detail = lines.isEmpty() ? "стройка не разрешена" : lines.get(0);
            } else if (Type5ReconcileErrorGrouper.PRIMARY_MISSING_SENDER.equals(primary)) {
                reasonCode = "A4_OG";
                String sender = row.ogSenderStr();
                String branch = row.ogBranchStr();
                if (sender != null && !sender.isBlank() && branch != null && !branch.isBlank()) {
                    groupValue = sender.trim() + " / " + branch.trim();
                } else if (sender != null && !sender.isBlank()) {
                    groupValue = sender.trim();
                } else {
                    groupValue = "(пусто)";
                }
                List<String> lines = RalpFkAnomalyFormatter.reasonLines(row);
                detail = lines.isEmpty() ? "отправитель не разрешён" : findSenderReason(lines);
            } else {
                reasonCode = dateMissing ? "A3_DATE" : "A_OTHER";
                List<String> lines = RalpFkAnomalyFormatter.reasonLines(row);
                detail = lines.isEmpty() ? "строка некорректна" : String.join("; ", lines);
            }
            hits.add(Type5ReconcileErrorGrouper.ErrorHit.of(
                    "RALP",
                    row.excelRow(),
                    primary,
                    groupValue,
                    reasonCode,
                    detail
            ));
        }
        return hits;
    }

    private static String findSenderReason(List<String> lines) {
        for (String line : lines) {
            if (line != null && line.toLowerCase().contains("отправител")) {
                return line;
            }
        }
        return lines.get(0);
    }
}
