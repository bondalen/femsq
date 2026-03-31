package com.femsq.web.audit.marker;

import com.femsq.database.connection.ConnectionFactory;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.util.logging.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Авто-очистка marker-таблицы для идемпотентности reconcile.
 *
 * <p>Реализация intentionally "best-effort": ошибка очистки не должна ломать работу приложения.</p>
 */
@Service
public class AuditMarkerCleanupService {

    private static final Logger log = Logger.getLogger(AuditMarkerCleanupService.class.getName());

    private final ConnectionFactory connectionFactory;
    private final int retentionDays;

    public AuditMarkerCleanupService(
            ConnectionFactory connectionFactory,
            @Value("${audit.marker.retention-days:180}") int retentionDays
    ) {
        this.connectionFactory = connectionFactory;
        this.retentionDays = retentionDays;
    }

    /**
     * Запуск раз в сутки (по умолчанию в 03:20). Время задаётся через cron.
     */
    @Scheduled(cron = "${audit.marker.cleanup-cron:0 20 3 * * *}")
    public void cleanup() {
        if (retentionDays <= 0) {
            return;
        }
        try (Connection connection = connectionFactory.createConnection()) {
            connection.setAutoCommit(true);
            ensureTableExists(connection);
            int deleted = deleteOldRows(connection);
            if (deleted > 0) {
                log.info(() -> "[AuditMarkerCleanup] deleted=" + deleted + ", retentionDays=" + retentionDays);
            }
        } catch (Exception ex) {
            log.warning("[AuditMarkerCleanup] cleanup failed: " + ex.getMessage());
        }
    }

    private void ensureTableExists(Connection connection) throws SQLException {
        String sql = """
                IF OBJECT_ID(N'ags.ra_reconcile_marker', N'U') IS NULL
                BEGIN
                    CREATE TABLE ags.ra_reconcile_marker (
                        rm_key BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                        exec_key BIGINT NOT NULL,
                        file_type INT NOT NULL,
                        step_code NVARCHAR(64) NOT NULL,
                        created_at DATETIME2 NOT NULL CONSTRAINT DF_ra_reconcile_marker_created_at DEFAULT SYSUTCDATETIME(),
                        details NVARCHAR(4000) NULL
                    );
                    CREATE UNIQUE INDEX UX_ra_reconcile_marker_exec_step
                        ON ags.ra_reconcile_marker(exec_key, file_type, step_code);
                    CREATE INDEX IX_ra_reconcile_marker_created_at
                        ON ags.ra_reconcile_marker(created_at);
                END
                """;
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.execute();
        }
    }

    private int deleteOldRows(Connection connection) throws SQLException {
        String sql = """
                DELETE FROM ags.ra_reconcile_marker
                WHERE created_at < DATEADD(day, -?, SYSUTCDATETIME())
                """;
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, retentionDays);
            return ps.executeUpdate();
        }
    }
}

