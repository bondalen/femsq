package com.femsq.database.model.sudz;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Канонизация точек {@code DbtValue} для UI КСДД (дерево / динамика / советник).
 * <p>
 * Убирает PIT-копии Rslt ({@code upl} 801–899) и seed-песочницу ({@code upl} 900–909),
 * оставляет одну точку на дату среза (предпочтение большему {@code uplKey}: funnel 910
 * важнее seed 901).
 */
public final class SudzDbtValueUiCanonical {

    /** Нижняя граница synthetic PIT {@code upl} (включительно). */
    public static final int PIT_UPL_MIN = 801;

    /** Верхняя граница seed-блока {@code upl} (включительно): PIT 801–899 + seed 900–909. */
    public static final int SEED_UPL_MAX = 909;

    private SudzDbtValueUiCanonical() {
    }

    /**
     * Synthetic PIT / seed — не для операторского UI КСДД.
     *
     * @param uplKey ключ или null
     * @return true, если скрывать
     */
    public static boolean isPitUpl(Integer uplKey) {
        return uplKey != null && uplKey >= PIT_UPL_MIN && uplKey <= SEED_UPL_MAX;
    }

    /**
     * Канонический ряд для экрана разбора: без PIT, одна точка на {@code statusDate}.
     *
     * @param points сырой ряд слота
     * @return новый список (порядок по дате, затем upl)
     */
    public static List<SudzInvDbtTimelinePoint> canonicalize(List<SudzInvDbtTimelinePoint> points) {
        Objects.requireNonNull(points, "points");
        Map<LocalDate, SudzInvDbtTimelinePoint> byDate = new LinkedHashMap<>();
        List<SudzInvDbtTimelinePoint> undated = new ArrayList<>();
        for (SudzInvDbtTimelinePoint point : points) {
            if (point == null || isPitUpl(point.uplKey())) {
                continue;
            }
            LocalDate date = point.statusDate();
            if (date == null) {
                undated.add(point);
                continue;
            }
            SudzInvDbtTimelinePoint prev = byDate.get(date);
            if (prev == null || prefer(point, prev) > 0) {
                byDate.put(date, point);
            }
        }
        List<SudzInvDbtTimelinePoint> result = new ArrayList<>(byDate.values());
        result.sort(Comparator
                .comparing(SudzInvDbtTimelinePoint::statusDate)
                .thenComparing(p -> p.uplKey() == null ? Integer.MIN_VALUE : p.uplKey()));
        // Без даты среза не показываем в UI-ряде (нет оси X).
        undated.clear();
        return List.copyOf(result);
    }

    /**
     * @return &gt;0 если {@code a} предпочтительнее {@code b}
     */
    static int prefer(SudzInvDbtTimelinePoint a, SudzInvDbtTimelinePoint b) {
        int ua = a.uplKey() == null ? Integer.MIN_VALUE : a.uplKey();
        int ub = b.uplKey() == null ? Integer.MIN_VALUE : b.uplKey();
        return Integer.compare(ua, ub);
    }
}
