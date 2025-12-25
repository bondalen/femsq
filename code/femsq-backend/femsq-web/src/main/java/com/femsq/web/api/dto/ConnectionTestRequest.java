package com.femsq.web.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

/**
 * DTO запроса для тестирования и применения конфигурации подключения к БД.
 *
 * @param host     хост MS SQL Server
 * @param port     порт подключения
 * @param database имя базы данных
 * @param schema   имя схемы (опционально)
 * @param username имя пользователя (опционально, требуется для credentials)
 * @param password пароль (опционально, требуется для credentials)
 * @param authMode режим аутентификации (credentials, windows-integrated, kerberos)
 * @param realm    Kerberos realm для Windows Authentication на Linux (опционально, например ADM.GAZPROM.RU)
 */
public record ConnectionTestRequest(
        @NotBlank(message = "host обязателен")
        @Pattern(regexp = "^[a-zA-Z0-9-_.]+$", message = "host содержит недопустимые символы")
        String host,

        @NotNull(message = "port обязателен")
        @Positive(message = "port должен быть положительным числом")
        Integer port,

        @NotBlank(message = "database обязателен")
        @Size(max = 128, message = "database не должен превышать 128 символов")
        String database,

        @Size(max = 128, message = "schema не должен превышать 128 символов")
        @Pattern(regexp = "^[a-zA-Z0-9_]*$", message = "schema содержит недопустимые символы")
        String schema,

        @Size(max = 255, message = "username не должен превышать 255 символов")
        String username,

        @Size(max = 255, message = "password не должен превышать 255 символов")
        String password,

        @NotBlank(message = "authMode обязателен")
        @Pattern(regexp = "(?i)credentials|windows-integrated|kerberos", message = "Поддерживаются значения: credentials, windows-integrated, kerberos")
        String authMode,

        @Size(max = 255, message = "realm не должен превышать 255 символов")
        @Pattern(regexp = "^[A-Z0-9._-]*$", message = "realm должен содержать только заглавные буквы, цифры, точки, дефисы и подчеркивания")
        String realm
) {
}


