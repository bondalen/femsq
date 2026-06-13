USE [FishEye];
GO

-- =============================================================================
-- Файл:    01c_CREATE_TRIGGER_factDoc_sync.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Триггеры синхронизации factDoc / factDocCost (Решение 9).
--   INSERT  → создать factDoc, присвоить *_fdKey подклассу
--   INSERT/UPDATE с суммами → factDocCost (фильтр UPDATE(column) для VBA)
--   ras_work / raсs_work → stCost 195 (СМР), не 182 — Решение 12, 2026-06-13
-- Автор:   Александр
-- Дата:    2026-06-05 | Обновлён: 2026-06-13
-- =============================================================================

PRINT '=== 01c: CREATE TRIGGER factDoc sync (×6) ===';

-- -----------------------------------------------------------------------------
-- DROP при перепрогоне
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'ags.trgRaSumm_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgRaSumm_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgRaChangeSumm_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgRaChangeSumm_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgOgAgFeeP_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgOgAgFeeP_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgRalpRaAu_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgRalpRaAu_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgCn_PrDocP_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgCn_PrDocP_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgCstAgPnMnrl_syncFactDoc', N'TR') IS NOT NULL
    DROP TRIGGER ags.trgCstAgPnMnrl_syncFactDoc;
GO

-- -----------------------------------------------------------------------------
-- 1. ra_summ (RaSumm) — stcKey 212/195/172/187 (work = СМР = 195)
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgRaSumm_syncFactDoc
ON ags.ra_summ
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'RaSumm', i.ras_key
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'RaSumm' AND fd.fdNKey = i.ras_key
        );

        UPDATE rs
        SET rs.ras_fdKey = fd.fdKey
        FROM ags.ra_summ rs
        INNER JOIN inserted i ON rs.ras_key = i.ras_key
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RaSumm' AND fd.fdNKey = i.ras_key
        WHERE rs.ras_fdKey IS NULL;
    END

    IF NOT (UPDATE(ras_total) OR UPDATE(ras_work) OR UPDATE(ras_equip) OR UPDATE(ras_others))
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.ra_summ rs ON c.fdcoFd = rs.ras_fdKey
    INNER JOIN inserted i ON rs.ras_key = i.ras_key
    WHERE rs.ras_fdKey IS NOT NULL
      AND c.fdcoStCost IN (212, 195, 172, 187);

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT rs.ras_fdKey, 212, i.ras_total
    FROM inserted i
    INNER JOIN ags.ra_summ rs ON rs.ras_key = i.ras_key
    WHERE rs.ras_fdKey IS NOT NULL AND i.ras_total IS NOT NULL AND i.ras_total <> 0
    UNION ALL
    SELECT rs.ras_fdKey, 195, i.ras_work
    FROM inserted i
    INNER JOIN ags.ra_summ rs ON rs.ras_key = i.ras_key
    WHERE rs.ras_fdKey IS NOT NULL AND i.ras_work IS NOT NULL AND i.ras_work <> 0
    UNION ALL
    SELECT rs.ras_fdKey, 172, i.ras_equip
    FROM inserted i
    INNER JOIN ags.ra_summ rs ON rs.ras_key = i.ras_key
    WHERE rs.ras_fdKey IS NOT NULL AND i.ras_equip IS NOT NULL AND i.ras_equip <> 0
    UNION ALL
    SELECT rs.ras_fdKey, 187, i.ras_others
    FROM inserted i
    INNER JOIN ags.ra_summ rs ON rs.ras_key = i.ras_key
    WHERE rs.ras_fdKey IS NOT NULL AND i.ras_others IS NOT NULL AND i.ras_others <> 0;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. ra_change_summ (RaChangeSumm) — имена raсs_* с кириллической «с»
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgRaChangeSumm_syncFactDoc
ON ags.ra_change_summ
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'RaChangeSumm', i.raсs_key
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'RaChangeSumm' AND fd.fdNKey = i.raсs_key
        );

        UPDATE rcs
        SET rcs.racs_fdKey = fd.fdKey
        FROM ags.ra_change_summ rcs
        INNER JOIN inserted i ON rcs.raсs_key = i.raсs_key
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RaChangeSumm' AND fd.fdNKey = i.raсs_key
        WHERE rcs.racs_fdKey IS NULL;
    END

    IF NOT (UPDATE(raсs_total) OR UPDATE(raсs_work) OR UPDATE(raсs_equip) OR UPDATE(raсs_others))
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.ra_change_summ rcs ON c.fdcoFd = rcs.racs_fdKey
    INNER JOIN inserted i ON rcs.raсs_key = i.raсs_key
    WHERE rcs.racs_fdKey IS NOT NULL
      AND c.fdcoStCost IN (212, 195, 172, 187);

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT rcs.racs_fdKey, 212, i.raсs_total
    FROM inserted i
    INNER JOIN ags.ra_change_summ rcs ON rcs.raсs_key = i.raсs_key
    WHERE rcs.racs_fdKey IS NOT NULL AND i.raсs_total IS NOT NULL AND i.raсs_total <> 0
    UNION ALL
    SELECT rcs.racs_fdKey, 195, i.raсs_work
    FROM inserted i
    INNER JOIN ags.ra_change_summ rcs ON rcs.raсs_key = i.raсs_key
    WHERE rcs.racs_fdKey IS NOT NULL AND i.raсs_work IS NOT NULL AND i.raсs_work <> 0
    UNION ALL
    SELECT rcs.racs_fdKey, 172, i.raсs_equip
    FROM inserted i
    INNER JOIN ags.ra_change_summ rcs ON rcs.raсs_key = i.raсs_key
    WHERE rcs.racs_fdKey IS NOT NULL AND i.raсs_equip IS NOT NULL AND i.raсs_equip <> 0
    UNION ALL
    SELECT rcs.racs_fdKey, 187, i.raсs_others
    FROM inserted i
    INNER JOIN ags.ra_change_summ rcs ON rcs.raсs_key = i.raсs_key
    WHERE rcs.racs_fdKey IS NOT NULL AND i.raсs_others IS NOT NULL AND i.raсs_others <> 0;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. ogAgFeeP (OgAgFeeP) — stcKey 148
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgOgAgFeeP_syncFactDoc
ON ags.ogAgFeeP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'OgAgFeeP', i.oafpKey
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'OgAgFeeP' AND fd.fdNKey = i.oafpKey
        );

        UPDATE p
        SET p.oafp_fdKey = fd.fdKey
        FROM ags.ogAgFeeP p
        INNER JOIN inserted i ON p.oafpKey = i.oafpKey
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'OgAgFeeP' AND fd.fdNKey = i.oafpKey
        WHERE p.oafp_fdKey IS NULL;
    END

    IF NOT UPDATE(oafpTotal)
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.ogAgFeeP p ON c.fdcoFd = p.oafp_fdKey
    INNER JOIN inserted i ON p.oafpKey = i.oafpKey
    WHERE p.oafp_fdKey IS NOT NULL AND c.fdcoStCost = 148;

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT p.oafp_fdKey, 148, i.oafpTotal
    FROM inserted i
    INNER JOIN ags.ogAgFeeP p ON p.oafpKey = i.oafpKey
    WHERE p.oafp_fdKey IS NOT NULL AND i.oafpTotal IS NOT NULL AND i.oafpTotal <> 0;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. ralpRaAu (RalpRaAu) — stcKey 150
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgRalpRaAu_syncFactDoc
ON ags.ralpRaAu
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'RalpRaAu', i.ralpraKey
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'RalpRaAu' AND fd.fdNKey = i.ralpraKey
        );

        UPDATE r
        SET r.ralpra_fdKey = fd.fdKey
        FROM ags.ralpRaAu r
        INNER JOIN inserted i ON r.ralpraKey = i.ralpraKey
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RalpRaAu' AND fd.fdNKey = i.ralpraKey
        WHERE r.ralpra_fdKey IS NULL;
    END

    IF NOT UPDATE(ralpraCostAndVat)
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.ralpRaAu r ON c.fdcoFd = r.ralpra_fdKey
    INNER JOIN inserted i ON r.ralpraKey = i.ralpraKey
    WHERE r.ralpra_fdKey IS NOT NULL AND c.fdcoStCost = 150;

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT r.ralpra_fdKey, 150, i.ralpraCostAndVat
    FROM inserted i
    INNER JOIN ags.ralpRaAu r ON r.ralpraKey = i.ralpraKey
    WHERE r.ralpra_fdKey IS NOT NULL
      AND i.ralpraCostAndVat IS NOT NULL AND i.ralpraCostAndVat <> 0;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. cn_PrDocP (PrDocP) — stcKey 205 (ZPTG/ZKTG) или 197 (ZUGH+счёт 350252)
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgCn_PrDocP_syncFactDoc
ON ags.cn_PrDocP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'PrDocP', i.pdpKey
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'PrDocP' AND fd.fdNKey = i.pdpKey
        );

        UPDATE p
        SET p.pdp_fdKey = fd.fdKey
        FROM ags.cn_PrDocP p
        INNER JOIN inserted i ON p.pdpKey = i.pdpKey
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'PrDocP' AND fd.fdNKey = i.pdpKey
        WHERE p.pdp_fdKey IS NULL;
    END

    IF NOT UPDATE(costVAT)
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.cn_PrDocP p ON c.fdcoFd = p.pdp_fdKey
    INNER JOIN inserted i ON p.pdpKey = i.pdpKey
    WHERE p.pdp_fdKey IS NOT NULL AND c.fdcoStCost IN (205, 197);

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT p.pdp_fdKey, z.stCostEl, i.costVAT
    FROM inserted i
    INNER JOIN ags.cn_PrDocP p ON p.pdpKey = i.pdpKey
    CROSS APPLY (
        SELECT
            CASE
                WHEN t.pdtoCode IN (N'ZPTG', N'ZKTG') THEN 205
                WHEN t.pdtoCode = N'ZUGH' AND a.account_num = 350252 THEN 197
                ELSE NULL
            END AS stCostEl
        FROM ags.cn_PrDoc d
        INNER JOIN ags.cn_PrDocT t ON d.cnpdTpOrd = t.pdtoKey
        INNER JOIN ags.cnInvAccntSmpl s ON d.cnpdCnInvAccntSmpl = s.ciasKey
        INNER JOIN ags.accnt a ON s.ciasAccnt = a.account_key
        WHERE d.cnpdKey = i.pdpPrDoc
    ) z
    WHERE p.pdp_fdKey IS NOT NULL
      AND i.costVAT IS NOT NULL AND i.costVAT <> 0
      AND z.stCostEl IS NOT NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 6. cstAgPnMnrl (CstAgPnMnrl) — stcKey 169
-- -----------------------------------------------------------------------------
CREATE TRIGGER ags.trgCstAgPnMnrl_syncFactDoc
ON ags.cstAgPnMnrl
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ags.factDoc (fdDocType, fdNKey)
        SELECT N'CstAgPnMnrl', i.amKey
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM ags.factDoc fd
            WHERE fd.fdDocType = N'CstAgPnMnrl' AND fd.fdNKey = i.amKey
        );

        UPDATE m
        SET m.am_fdKey = fd.fdKey
        FROM ags.cstAgPnMnrl m
        INNER JOIN inserted i ON m.amKey = i.amKey
        INNER JOIN ags.factDoc fd ON fd.fdDocType = N'CstAgPnMnrl' AND fd.fdNKey = i.amKey
        WHERE m.am_fdKey IS NULL;
    END

    IF NOT UPDATE(amSum)
        RETURN;

    DELETE c
    FROM ags.factDocCost c
    INNER JOIN ags.cstAgPnMnrl m ON c.fdcoFd = m.am_fdKey
    INNER JOIN inserted i ON m.amKey = i.amKey
    WHERE m.am_fdKey IS NOT NULL AND c.fdcoStCost = 169;

    INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
    SELECT m.am_fdKey, 169, i.amSum
    FROM inserted i
    INNER JOIN ags.cstAgPnMnrl m ON m.amKey = i.amKey
    WHERE m.am_fdKey IS NOT NULL AND i.amSum IS NOT NULL AND i.amSum <> 0;
END;
GO

-- -----------------------------------------------------------------------------
-- MS_Description
-- -----------------------------------------------------------------------------
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для ra_summ (RaSumm). INSERT → factDoc; UPDATE сумм → factDocCost.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'ra_summ',
    @level2type = N'TRIGGER', @level2name = N'trgRaSumm_syncFactDoc';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для ra_change_summ (RaChangeSumm).',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'ra_change_summ',
    @level2type = N'TRIGGER', @level2name = N'trgRaChangeSumm_syncFactDoc';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для ogAgFeeP (stcKey 148).',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'ogAgFeeP',
    @level2type = N'TRIGGER', @level2name = N'trgOgAgFeeP_syncFactDoc';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для ralpRaAu (stcKey 150).',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'ralpRaAu',
    @level2type = N'TRIGGER', @level2name = N'trgRalpRaAu_syncFactDoc';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для cn_PrDocP (205/197 по pdtoCode).',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'cn_PrDocP',
    @level2type = N'TRIGGER', @level2name = N'trgCn_PrDocP_syncFactDoc';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Синхронизация factDoc/factDocCost для cstAgPnMnrl (stcKey 169).',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'cstAgPnMnrl',
    @level2type = N'TRIGGER', @level2name = N'trgCstAgPnMnrl_syncFactDoc';
GO

PRINT 'Триггеры созданы (×6).';
GO

-- -----------------------------------------------------------------------------
-- Проверка: smoke-test ra_summ (VBA-паттерн: INSERT без сумм → UPDATE суммы)
-- -----------------------------------------------------------------------------
PRINT '--- Smoke-test trgRaSumm_syncFactDoc ---';

DECLARE @testRa int = (SELECT TOP 1 ra_key FROM ags.ra ORDER BY ra_key DESC);
DECLARE @rasKey int;

IF @testRa IS NOT NULL
BEGIN
    INSERT INTO ags.ra_summ (ras_ra, ras_date)
    VALUES (@testRa, GETDATE());

    SET @rasKey = SCOPE_IDENTITY();

    SELECT N'after INSERT (no sums)' AS step,
           ras_fdKey,
           (SELECT COUNT(*) FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey) AS cost_rows
    FROM ags.ra_summ rs WHERE rs.ras_key = @rasKey;

    UPDATE ags.ra_summ SET ras_total = 100.00, ras_work = 40.00 WHERE ras_key = @rasKey;

    SELECT N'after UPDATE sums' AS step,
           ras_fdKey,
           (SELECT COUNT(*) FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey) AS cost_rows
    FROM ags.ra_summ rs WHERE rs.ras_key = @rasKey;

    SELECT fdcoStCost, fdcoSumm
    FROM ags.factDocCost c
    INNER JOIN ags.ra_summ rs ON c.fdcoFd = rs.ras_fdKey
    WHERE rs.ras_key = @rasKey
    ORDER BY fdcoStCost;

    DECLARE @fdKey int = (SELECT ras_fdKey FROM ags.ra_summ WHERE ras_key = @rasKey);
    DELETE FROM ags.ra_summ WHERE ras_key = @rasKey;
    DELETE FROM ags.factDocCost WHERE fdcoFd = @fdKey;
    DELETE FROM ags.factDoc WHERE fdKey = @fdKey;

    PRINT 'Smoke-test ra_summ: OK (тестовая строка удалена).';
END
ELSE
    PRINT 'Smoke-test пропущен: нет строк в ags.ra.';
GO

PRINT '=== 01c: завершено ===';
GO
