package com.femsq.database.dao;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.femsq.database.config.ConfigurationFileManager;
import com.femsq.database.config.ConfigurationValidator;
import com.femsq.database.config.DatabaseConfigurationService;
import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.model.sudz.SudzD644Row;
import com.femsq.database.model.sudz.SudzDebtCollection;
import com.femsq.database.model.sudz.SudzRsltDebt;
import com.femsq.database.model.sudz.SudzYear;
import com.femsq.database.model.sudz.SudzYearDetail;
import com.femsq.database.service.DefaultSudzService;
import com.femsq.database.service.SudzService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Smoke read/write СУДЗ на DEV ({@code sudz.*}, долги 82/85).
 */
class SudzDaoSmokeIT {

    private static final String SUDZ_SCHEMA = "sudz";

    @Test
    @DisplayName("Rslt/D644 содержат эталонные долги 82 и 85 для yr=901")
    void portfolioAndD644ContainGoldenDebts() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config), "нет ~/.femsq/database.properties");

        DatabaseConfigurationService configurationService = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator()
        );
        try (ConnectionFactory connectionFactory = new ConnectionFactory(configurationService)) {
            SudzService service = new DefaultSudzService(new JdbcSudzDao(connectionFactory, SUDZ_SCHEMA));

            List<SudzRsltDebt> portfolio = service.getYrDbtChanges(901, null);
            Set<Integer> keys = portfolio.stream().map(SudzRsltDebt::dbtKey).collect(Collectors.toSet());
            assertTrue(keys.contains(82), "ожидался dbtKey=82 в портфеле 901");
            assertTrue(keys.contains(85), "ожидался dbtKey=85 в портфеле 901");

            List<SudzD644Row> d644 = service.getD644(901, 902);
            Set<Integer> d644Keys = d644.stream().map(SudzD644Row::dbtKey).collect(Collectors.toSet());
            assertTrue(d644Keys.contains(82));
            assertTrue(d644Keys.contains(85));
            assertTrue(d644.stream().anyMatch(r -> r.dbtKey() == 82 && "7947".equals(r.invoice())));
            assertTrue(d644.stream().anyMatch(r -> r.dbtKey() == 85
                    && r.invoice() != null && r.invoice().startsWith("А19")));

            assertFalse(service.getD644Svod(901, 902).accounts().isEmpty());

            assertThrows(IllegalArgumentException.class, () -> service.getYrDbtChanges(99999, null));

            List<SudzRsltDebt> untilBase = service.getYrDbtChanges(901, 901);
            assertFalse(untilBase.isEmpty());
            assertTrue(untilBase.stream().allMatch(d ->
                    d.periods().stream().allMatch(p -> p.uplKey() == 901)));
            int maxPeriodsFull = portfolio.stream().mapToInt(d -> d.periods().size()).max().orElse(0);
            int maxPeriodsCut = untilBase.stream().mapToInt(d -> d.periods().size()).max().orElse(0);
            assertTrue(maxPeriodsCut <= maxPeriodsFull);
        }
    }

    @Test
    @DisplayName("Список лет обогащён lookup; disposable create+delete года")
    void yearsEnrichedAndDisposableCreateDelete() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config), "нет ~/.femsq/database.properties");

        DatabaseConfigurationService configurationService = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator()
        );
        try (ConnectionFactory connectionFactory = new ConnectionFactory(configurationService)) {
            SudzService service = new DefaultSudzService(new JdbcSudzDao(connectionFactory, SUDZ_SCHEMA));

            List<SudzYear> years = service.listYears();
            assertFalse(years.isEmpty());
            SudzYear y901 = years.stream().filter(y -> y.yrKey() == 901).findFirst().orElseThrow();
            assertNotNull(y901.baseUplName());
            assertNotNull(y901.yyyyValue());
            assertTrue(y901.yyyyValue() == 2026);

            SudzYearDetail detail = service.getYearDetail(901);
            assertFalse(detail.upls().isEmpty());

            String marker = "[smoke-yr] " + System.currentTimeMillis();
            SudzYearDetail created = service.createYear(
                    marker,
                    null,
                    marker + " upl",
                    LocalDate.of(2099, 1, 1),
                    LocalDate.of(2098, 12, 31),
                    28,
                    null
            );
            int disposableKey = created.year().yrKey();
            Integer disposableUpl = created.year().baseUpl();
            try {
                assertTrue(disposableKey > 0);
                assertTrue(created.year().yrVariant().contains("[smoke-yr]"));
                assertFalse(created.upls().isEmpty());
            } finally {
                service.deleteYear(disposableKey);
                // orphan upl без FK на yr — убираем вручную через DAO-слой createUpl/lookups нет deleteUpl;
                // для smoke достаточно, что год удалён; upl с датой 2099 удаляем SQL при наличии.
                if (disposableUpl != null) {
                    try (var connection = connectionFactory.createConnection();
                         var statement = connection.prepareStatement(
                                 "DELETE FROM sudz.cn_inv_dbt_upl WHERE upl_key = ?")) {
                        statement.setInt(1, disposableUpl);
                        statement.executeUpdate();
                    }
                }
            }
            assertThrows(IllegalArgumentException.class, () -> service.getYearDetail(disposableKey));
        }
    }

    @Test
    @DisplayName("Правка mery на долге 82 видна в D644 comment644")
    void meryUpdateVisibleInD644() throws Exception {
        Path config = Path.of(System.getProperty("user.home"), ".femsq", "database.properties");
        Assumptions.assumeTrue(Files.isRegularFile(config), "нет ~/.femsq/database.properties");

        DatabaseConfigurationService configurationService = new DatabaseConfigurationService(
                new ConfigurationFileManager(),
                new ConfigurationValidator()
        );
        try (ConnectionFactory connectionFactory = new ConnectionFactory(configurationService)) {
            SudzService service = new DefaultSudzService(new JdbcSudzDao(connectionFactory, SUDZ_SCHEMA));

            SudzRsltDebt debt82 = service.getYrDbtChanges(901, null).stream()
                    .filter(d -> d.dbtKey() == 82)
                    .findFirst()
                    .orElseThrow();
            String originalMery = debt82.mery();
            String marker = "[0068-smoke] " + System.currentTimeMillis();
            String newMery = (originalMery == null ? "" : originalMery) + "\n" + marker;

            try {
                SudzDebtCollection saved = service.updateDebtCollection(
                        901,
                        82,
                        debt82.curator(),
                        newMery,
                        debt82.cstCode()
                );
                assertTrue(saved.mery() != null && saved.mery().contains(marker));

                SudzD644Row row = service.getD644(901, 902).stream()
                        .filter(r -> r.dbtKey() == 82)
                        .findFirst()
                        .orElseThrow();
                assertTrue(row.comment644() != null && row.comment644().contains(marker),
                        "D644 comment644 должен содержать marker после save");
            } finally {
                service.updateDebtCollection(901, 82, debt82.curator(), originalMery, debt82.cstCode());
            }
        }
    }
}
