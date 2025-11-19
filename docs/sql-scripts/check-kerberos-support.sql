-- ================================================
-- Проверка поддержки Kerberos на SQL Server
-- ================================================

-- 1. Проверить зарегистрированные SPN (Service Principal Names)
-- Это основной индикатор настройки Kerberos
EXEC xp_readerrorlog 0, 1, 'SPN';
GO

-- 2. Проверить текущий метод аутентификации сессии
SELECT 
    session_id,
    login_name,
    host_name,
    program_name,
    auth_scheme,  -- Здесь будет 'KERBEROS' или 'NTLM'
    client_net_address
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
GO

-- 3. Проверить настройки сервера
SELECT 
    SERVERPROPERTY('IsIntegratedSecurityOnly') AS IsWindowsAuth,
    SERVERPROPERTY('MachineName') AS MachineName,
    SERVERPROPERTY('ServerName') AS ServerName;
GO

-- 4. Проверить все активные подключения и их методы аутентификации
SELECT 
    auth_scheme,
    COUNT(*) AS connection_count
FROM sys.dm_exec_connections
GROUP BY auth_scheme;
GO
