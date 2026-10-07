package com.femsq.database.model.sudz;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Дерево строек, у которых есть код {@code cstAgPn} с заданным хвостом из 6 символов.
 * Корень — {@code ags.cst}, дети — все {@code cstAg} этой стройки, затем все их {@code cstAgPn}.
 * {@code sameSuffix} отмечает код, чей хвост совпал с аргументом запроса.
 */
public record SudzPmtUplCstMatch(
        int cstKey,
        String cstName,
        List<Agent> agents
) {

    /** Длина хвоста {@code RIGHT(cstapIpgPnN, 6)} / {@code sh} очереди. */
    public static final int CODE_SUFFIX_LENGTH = 6;

    /**
     * Агент стройки. Подпись — {@code ogAgCs.ogaNm}, код — {@code ogAg.ogaCode}.
     *
     * @param cstaKey ключ {@code cstAg}
     * @param agentLabel подпись или null
     * @param ogaCode код агента или null
     * @param points коды САК
     */
    public record Agent(
            int cstaKey,
            String agentLabel,
            String ogaCode,
            List<Point> points
    ) {
        /**
         * @param cstaKey ключ агента
         * @param agentLabel подпись
         * @param ogaCode код
         * @param points коды
         */
        public Agent {
            agentLabel = blankToNull(agentLabel);
            ogaCode = blankToNull(ogaCode);
            points = List.copyOf(points);
        }
    }

    /**
     * Код САК на агенте.
     *
     * @param cstapKey ключ {@code cstAgPn}
     * @param cstapIpgPnN полный код
     * @param sameSuffix хвост кода равен аргументу запроса
     */
    public record Point(
            int cstapKey,
            String cstapIpgPnN,
            boolean sameSuffix
    ) {
        /**
         * @param cstapKey ключ
         * @param cstapIpgPnN код
         * @param sameSuffix отметка хвоста
         */
        public Point {
            if (cstapIpgPnN == null || cstapIpgPnN.isBlank()) {
                throw new IllegalArgumentException("cstapIpgPnN обязателен");
            }
            cstapIpgPnN = cstapIpgPnN.trim();
        }
    }

    /**
     * Плоская строка выборки до сборки дерева.
     *
     * @param cstKey стройка
     * @param cstName имя
     * @param cstaKey агент или null, если у стройки нет агентов
     * @param agentLabel подпись агента
     * @param ogaCode код агента
     * @param cstapKey код или null, если у агента нет САК
     * @param cstapIpgPnN полный код
     */
    public record Flat(
            int cstKey,
            String cstName,
            Integer cstaKey,
            String agentLabel,
            String ogaCode,
            Integer cstapKey,
            String cstapIpgPnN
    ) {
    }

    /**
     * @param cstKey ключ стройки
     * @param cstName имя
     * @param agents агенты
     */
    public SudzPmtUplCstMatch {
        if (cstName == null || cstName.isBlank()) {
            throw new IllegalArgumentException("cstName обязателен");
        }
        cstName = cstName.trim();
        agents = List.copyOf(agents);
    }

    /**
     * Проверяет аргумент хвоста: ровно {@link #CODE_SUFFIX_LENGTH} символов после trim.
     *
     * @param codeSuffix хвост строки очереди
     * @return нормализованный хвост
     */
    public static String requireCodeSuffix(String codeSuffix) {
        if (codeSuffix == null || codeSuffix.isBlank()) {
            throw new IllegalArgumentException("codeSuffix обязателен: 6 символов");
        }
        String suffix = codeSuffix.trim();
        if (suffix.length() != CODE_SUFFIX_LENGTH) {
            throw new IllegalArgumentException("codeSuffix должен быть из 6 символов: " + suffix);
        }
        return suffix;
    }

    /**
     * Собирает дерево, сохраняя порядок первой встречи стройки, агента и кода.
     *
     * @param rows плоские строки
     * @param codeSuffix хвост из 6 символов
     * @return корни {@code cst}
     */
    public static List<SudzPmtUplCstMatch> assemble(List<Flat> rows, String codeSuffix) {
        Objects.requireNonNull(rows, "rows");
        String suffix = requireCodeSuffix(codeSuffix);
        Map<Integer, SiteAcc> sites = new LinkedHashMap<>();
        for (Flat row : rows) {
            SiteAcc site = sites.computeIfAbsent(row.cstKey(), key -> new SiteAcc(row.cstKey(), row.cstName()));
            if (row.cstaKey() == null) {
                continue;
            }
            AgentAcc agent = site.agents.computeIfAbsent(
                    row.cstaKey(),
                    key -> new AgentAcc(row.cstaKey(), row.agentLabel(), row.ogaCode()));
            if (row.cstapKey() == null) {
                continue;
            }
            String code = blankToNull(row.cstapIpgPnN());
            if (code == null || agent.points.containsKey(row.cstapKey())) {
                continue;
            }
            boolean same = code.length() >= CODE_SUFFIX_LENGTH
                    && code.substring(code.length() - CODE_SUFFIX_LENGTH).equals(suffix);
            agent.points.put(row.cstapKey(), new Point(row.cstapKey(), code, same));
        }
        List<SudzPmtUplCstMatch> result = new ArrayList<>();
        for (SiteAcc site : sites.values()) {
            List<Agent> agents = new ArrayList<>();
            for (AgentAcc agent : site.agents.values()) {
                agents.add(new Agent(agent.cstaKey, agent.agentLabel, agent.ogaCode, List.copyOf(agent.points.values())));
            }
            result.add(new SudzPmtUplCstMatch(site.cstKey, site.cstName, agents));
        }
        return List.copyOf(result);
    }

    private static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static final class SiteAcc {
        private final int cstKey;
        private final String cstName;
        private final Map<Integer, AgentAcc> agents = new LinkedHashMap<>();

        private SiteAcc(int cstKey, String cstName) {
            this.cstKey = cstKey;
            this.cstName = cstName;
        }
    }

    private static final class AgentAcc {
        private final int cstaKey;
        private final String agentLabel;
        private final String ogaCode;
        private final Map<Integer, Point> points = new LinkedHashMap<>();

        private AgentAcc(int cstaKey, String agentLabel, String ogaCode) {
            this.cstaKey = cstaKey;
            this.agentLabel = agentLabel;
            this.ogaCode = ogaCode;
        }
    }
}
