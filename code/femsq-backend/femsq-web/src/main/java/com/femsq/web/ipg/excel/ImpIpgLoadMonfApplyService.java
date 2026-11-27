package com.femsq.web.ipg.excel;

import com.femsq.database.exception.DaoException;
import com.femsq.database.ipglog.ImpIpgLoadLogContext;
import com.femsq.database.model.ImpIpgLoad;
import com.femsq.database.model.ImpIpgLoadMonf;
import com.femsq.database.model.ImpIpgMonfApplyResult;
import com.femsq.database.model.ImpIpgMonfParseResult;
import com.femsq.database.model.ImpIpgMonfParseRow;
import com.femsq.database.model.IpgPn;
import com.femsq.database.service.ImpIpgLoadMonfService;
import com.femsq.database.service.ImpIpgLoadService;
import com.femsq.database.service.IpgLeavesService;
import com.femsq.database.service.IpgUtPlService;
import com.femsq.database.util.FemsqMoney;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.stereotype.Service;

/**
 * Apply Monf staging → {@code ipgUtPlP} / LmMn@212 (C2 §6.6).
 *
 * <p>Сопоставление как Access: {@code cstapIpgPnN} + {@code ipgpSmTtl} ≈ limYear на текущей ИП;
 * уникальный пункт → запись месяцев TOTAL@212 (без PART C).
 */
@Service
public class ImpIpgLoadMonfApplyService {

    private static final Logger log = Logger.getLogger(ImpIpgLoadMonfApplyService.class.getName());
    private static final int MAX_PROBLEMS = 40;

    private final ImpIpgLoadMonfService monfService;
    private final ImpIpgLoadService loadService;
    private final ImpIpgLoadMonfParseService parseService;
    private final IpgLeavesService leavesService;
    private final IpgUtPlService utPlService;

    public ImpIpgLoadMonfApplyService(
            ImpIpgLoadMonfService monfService,
            ImpIpgLoadService loadService,
            ImpIpgLoadMonfParseService parseService,
            IpgLeavesService leavesService,
            IpgUtPlService utPlService) {
        this.monfService = Objects.requireNonNull(monfService, "monfService");
        this.loadService = Objects.requireNonNull(loadService, "loadService");
        this.parseService = Objects.requireNonNull(parseService, "parseService");
        this.leavesService = Objects.requireNonNull(leavesService, "leavesService");
        this.utPlService = Objects.requireNonNull(utPlService, "utPlService");
    }

    /**
     * Parse + apply (или dryRun).
     *
     * @param monfKey ключ Monf ({@code iilmUtPl} обязателен)
     * @param dryRun  true — только сверка матчей, без записи
     */
    public ImpIpgMonfApplyResult apply(int monfKey, boolean dryRun) {
        ImpIpgLoadMonf monf = monfService.get(monfKey)
                .orElseThrow(() -> new DaoException("impIpgLoadMonf не найден: " + monfKey));
        if (monf.iilmUtPl() == null) {
            throw new DaoException("У Monf=" + monfKey + " не задан план UtPl (iilmUtPl)");
        }
        int utPlKey = monf.iilmUtPl();
        ImpIpgLoad load = loadService.getLoad(monf.iilmLoad())
                .orElseThrow(() -> new DaoException("impIpgLoad не найден: " + monf.iilmLoad()));
        int ipgKey = load.iilIpg();

        StringBuilder html = new StringBuilder();
        html.append("<div class=\"monf-apply\">");
        html.append("<p><b>LdM / Monf apply</b> · monf=").append(monfKey)
                .append(" · utPl=").append(utPlKey)
                .append(" · ipg=").append(ipgKey)
                .append(dryRun ? " · <i>dryRun</i>" : "")
                .append("</p>");

        log.info(() -> "applyMonf monf=" + monfKey + " utPl=" + utPlKey
                + " ipg=" + ipgKey + " dryRun=" + dryRun);

        ImpIpgMonfParseResult parsed = parseService.parse(monfKey, null);
        html.append("<p>Parse: loaded=").append(parsed.loadedCount())
                .append(" skipped=").append(parsed.skippedCount())
                .append("</p>");

        Map<String, List<IpgPn>> byCode = indexPnsByCode(leavesService.listPns(ipgKey));
        int applied = 0;
        int unmatched = 0;
        int ambiguous = 0;
        int errors = 0;
        List<String> problems = new ArrayList<>();

        for (ImpIpgMonfParseRow row : parsed.rows()) {
            BigDecimal lim = FemsqMoney.roundMln(row.limYear());
            List<IpgPn> candidates = byCode.getOrDefault(row.cstCode(), List.of());
            // Access: код+SmTtl. Fallback: единственный пункт с этим кодом на ИП
            // (Excel limYear часто ≠ ipgpSmTtl — это лимит UtPl, не смета пункта).
            List<IpgPn> byLim = new ArrayList<>();
            for (IpgPn pn : candidates) {
                if (moneyEquals(lim, pn.ipgpSmTtl())) {
                    byLim.add(pn);
                }
            }
            List<IpgPn> matched;
            String matchMode;
            if (byLim.size() == 1) {
                matched = byLim;
                matchMode = "код+SmTtl";
            } else if (byLim.isEmpty() && candidates.size() == 1) {
                matched = candidates;
                matchMode = "код(unique)";
            } else if (byLim.size() > 1) {
                ambiguous++;
                addProblem(problems, "row " + row.rowNo() + " " + row.cstCode()
                        + " lim=" + plain(lim) + ": " + byLim.size() + " пунктов по SmTtl");
                continue;
            } else if (candidates.isEmpty()) {
                unmatched++;
                addProblem(problems, "row " + row.rowNo() + " " + row.cstCode()
                        + " lim=" + plain(lim) + ": нет ipgPn с кодом");
                continue;
            } else {
                ambiguous++;
                addProblem(problems, "row " + row.rowNo() + " " + row.cstCode()
                        + " lim=" + plain(lim) + ": " + candidates.size()
                        + " пунктов по коду, SmTtl не совпал");
                continue;
            }
            IpgPn pn = matched.get(0);
            if (dryRun) {
                applied++;
                if (problems.size() < 8) {
                    addProblem(problems, "ok " + row.cstCode() + " → pn=" + pn.ipgpKey()
                            + " (" + matchMode + ")");
                }
                continue;
            }
            try {
                utPlService.applyTotalMonths212(
                        utPlKey,
                        pn.ipgpKey(),
                        row.months(),
                        lim,
                        row.quarters().isEmpty() ? null : row.quarters());
                applied++;
                log.fine(() -> "applyMonf " + row.cstCode() + " → pn=" + pn.ipgpKey()
                        + " (" + matchMode + ")");
            } catch (RuntimeException ex) {
                errors++;
                addProblem(problems, "row " + row.rowNo() + " " + row.cstCode()
                        + " pn=" + pn.ipgpKey() + ": " + ex.getMessage());
                log.log(Level.WARNING, "applyMonf row failed monf=" + monfKey
                        + " code=" + row.cstCode(), ex);
            }
        }

        html.append("<p class=\"ok\">applied=").append(applied)
                .append(" · unmatched=").append(unmatched)
                .append(" · ambiguous=").append(ambiguous)
                .append(" · errors=").append(errors)
                .append("</p>");
        if (!problems.isEmpty()) {
            html.append("<ul>");
            for (String problem : problems) {
                html.append("<li>").append(ImpIpgLoadLogContext.esc(problem)).append("</li>");
            }
            if (unmatched + ambiguous + errors > problems.size()) {
                html.append("<li>… ещё проблемы не показаны</li>");
            }
            html.append("</ul>");
        }
        html.append("</div>");
        String logHtml = (parsed.logHtml() == null ? "" : parsed.logHtml()) + html;
        try {
            monfService.updateResults(monfKey, logHtml);
        } catch (RuntimeException persistEx) {
            log.log(Level.WARNING, "Не удалось сохранить iilmResults monf=" + monfKey, persistEx);
        }

        return new ImpIpgMonfApplyResult(
                monfKey,
                utPlKey,
                ipgKey,
                dryRun,
                parsed.loadedCount(),
                applied,
                unmatched,
                ambiguous,
                errors,
                List.copyOf(problems),
                logHtml);
    }

    private static Map<String, List<IpgPn>> indexPnsByCode(List<IpgPn> points) {
        Map<String, List<IpgPn>> map = new HashMap<>();
        for (IpgPn pn : points) {
            String code = pn.cstAgPnCode();
            if (code == null || code.isBlank()) {
                continue;
            }
            map.computeIfAbsent(code.trim(), key -> new ArrayList<>()).add(pn);
        }
        return map;
    }

    private static boolean moneyEquals(BigDecimal a, BigDecimal b) {
        BigDecimal left = FemsqMoney.roundMln(a);
        BigDecimal right = FemsqMoney.roundMln(b);
        if (left == null && right == null) {
            return true;
        }
        if (left == null || right == null) {
            return false;
        }
        return left.compareTo(right) == 0;
    }

    private static void addProblem(List<String> problems, String message) {
        if (problems.size() < MAX_PROBLEMS) {
            problems.add(message);
        }
    }

    private static String plain(BigDecimal value) {
        return value == null ? "—" : value.toPlainString();
    }
}
