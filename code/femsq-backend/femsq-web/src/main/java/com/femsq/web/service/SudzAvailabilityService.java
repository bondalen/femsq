package com.femsq.web.service;

import com.femsq.database.connection.ConnectionFactory;
import com.femsq.database.connection.ConnectionFactoryException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Проверка наличия минимального слоя СУДЗ ({@code {schema}.yr}) для гейта R1.0 без M6.
 * <p>
 * На проде до cutover схема {@code sudz} отсутствует — UI и API СУДЗ должны быть изолированы,
 * а не падать с {@code Invalid object name}.
 * </p>
 */
@Service
public class SudzAvailabilityService {

    private static final Logger log = Logger.getLogger(SudzAvailabilityService.class.getName());

    private final ConnectionFactory connectionFactory;
    private final String sudzSchema;

    /**
     * @param connectionFactory фабрика подключений
     * @param sudzSchema        схема СУДЗ из {@code femsq.sudz.schema}
     */
    public SudzAvailabilityService(
            ConnectionFactory connectionFactory,
            @Value("${femsq.sudz.schema:sudz}") String sudzSchema) {
        this.connectionFactory = Objects.requireNonNull(connectionFactory, "connectionFactory");
        String trimmed = Objects.requireNonNull(sudzSchema, "sudzSchema").trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("femsq.sudz.schema не может быть пустым");
        }
        this.sudzSchema = trimmed;
    }

    /**
     * @return имя схемы СУДЗ из конфигурации
     */
    public String sudzSchema() {
        return sudzSchema;
    }

    /**
     * Есть ли таблица {@code {schema}.yr} (маркер развёрнутого слоя СУДЗ).
     *
     * @return {@code true} если объект найден
     */
    public boolean isSudzLayerPresent() {
        String objectIdArg = sudzSchema + ".yr";
        String sql = "SELECT CASE WHEN OBJECT_ID(?, N'U') IS NOT NULL THEN 1 ELSE 0 END";
        try (Connection connection = connectionFactory.createConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, objectIdArg);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                boolean present = rs.getInt(1) == 1;
                log.log(Level.FINE, "СУДЗ layer probe {0}: {1}", new Object[]{objectIdArg, present});
                return present;
            }
        } catch (ConnectionFactoryException | SQLException exception) {
            log.log(Level.WARNING, "Не удалось проверить наличие слоя СУДЗ (" + objectIdArg + ")", exception);
            return false;
        }
    }

    /**
     * Признак «объект СУДЗ отсутствует» в SQLException (для мягкой ошибки GraphQL).
     *
     * @param throwable любое исключение цепочки
     * @return {@code true} если похоже на missing object в схеме СУДЗ
     */
    public boolean isMissingSudzObject(Throwable throwable) {
        Throwable current = throwable;
        while (current != null) {
            String message = current.getMessage();
            if (message != null) {
                String lower = message.toLowerCase(Locale.ROOT);
                if (lower.contains("invalid object name")
                        && lower.contains(sudzSchema.toLowerCase(Locale.ROOT) + ".")) {
                    return true;
                }
            }
            current = current.getCause();
        }
        return false;
    }
}
