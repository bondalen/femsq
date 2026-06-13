USE [FishEye];
GO

-- =============================================================================
-- Файл:    01d_BACKFILL_factDoc.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Одноразовая миграция существующих данных в factDoc / factDocCost.
--   1) factDoc + *_fdKey для всех строк подклассов
--   2) factDocCost из плоских полей
--   3) Дополнение из ra_summCt / ra_change_summCt (прочие stcKey, в т.ч. 182 из Ct)
-- Предусловия: 01b, 01c применены. Триггеры временно отключаются.
-- Повторный запуск: идемпотентен (пропускает уже связанные строки и пары fd+stc).
-- Автор:   Александр
-- Дата:    2026-06-05 | Обновлён: 2026-06-13 (work→195)
-- =============================================================================

PRINT '=== 01d: BACKFILL factDoc / factDocCost ===';

-- -----------------------------------------------------------------------------
-- Отключить триггеры на время массовой загрузки
-- -----------------------------------------------------------------------------
DISABLE TRIGGER ags.trgRaSumm_syncFactDoc ON ags.ra_summ;
DISABLE TRIGGER ags.trgRaChangeSumm_syncFactDoc ON ags.ra_change_summ;
DISABLE TRIGGER ags.trgOgAgFeeP_syncFactDoc ON ags.ogAgFeeP;
DISABLE TRIGGER ags.trgRalpRaAu_syncFactDoc ON ags.ralpRaAu;
DISABLE TRIGGER ags.trgCn_PrDocP_syncFactDoc ON ags.cn_PrDocP;
DISABLE TRIGGER ags.trgCstAgPnMnrl_syncFactDoc ON ags.cstAgPnMnrl;
GO

PRINT 'Триггеры отключены.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 1: factDoc для всех подклассов
-- -----------------------------------------------------------------------------
INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'RaSumm', rs.ras_key
FROM ags.ra_summ rs
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'RaSumm' AND fd.fdNKey = rs.ras_key
);
PRINT 'factDoc RaSumm: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'RaChangeSumm', rcs.raсs_key
FROM ags.ra_change_summ rcs
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'RaChangeSumm' AND fd.fdNKey = rcs.raсs_key
);
PRINT 'factDoc RaChangeSumm: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'OgAgFeeP', p.oafpKey
FROM ags.ogAgFeeP p
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'OgAgFeeP' AND fd.fdNKey = p.oafpKey
);
PRINT 'factDoc OgAgFeeP: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'RalpRaAu', r.ralpraKey
FROM ags.ralpRaAu r
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'RalpRaAu' AND fd.fdNKey = r.ralpraKey
);
PRINT 'factDoc RalpRaAu: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'PrDocP', p.pdpKey
FROM ags.cn_PrDocP p
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'PrDocP' AND fd.fdNKey = p.pdpKey
);
PRINT 'factDoc PrDocP: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDoc (fdDocType, fdNKey)
SELECT N'CstAgPnMnrl', m.amKey
FROM ags.cstAgPnMnrl m
WHERE NOT EXISTS (
    SELECT 1 FROM ags.factDoc fd
    WHERE fd.fdDocType = N'CstAgPnMnrl' AND fd.fdNKey = m.amKey
);
PRINT 'factDoc CstAgPnMnrl: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

-- -----------------------------------------------------------------------------
-- Шаг 2: привязка *_fdKey
-- -----------------------------------------------------------------------------
UPDATE rs
SET rs.ras_fdKey = fd.fdKey
FROM ags.ra_summ rs
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RaSumm' AND fd.fdNKey = rs.ras_key
WHERE rs.ras_fdKey IS NULL;
PRINT 'ras_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

UPDATE rcs
SET rcs.racs_fdKey = fd.fdKey
FROM ags.ra_change_summ rcs
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RaChangeSumm' AND fd.fdNKey = rcs.raсs_key
WHERE rcs.racs_fdKey IS NULL;
PRINT 'racs_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

UPDATE p
SET p.oafp_fdKey = fd.fdKey
FROM ags.ogAgFeeP p
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'OgAgFeeP' AND fd.fdNKey = p.oafpKey
WHERE p.oafp_fdKey IS NULL;
PRINT 'oafp_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

UPDATE r
SET r.ralpra_fdKey = fd.fdKey
FROM ags.ralpRaAu r
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'RalpRaAu' AND fd.fdNKey = r.ralpraKey
WHERE r.ralpra_fdKey IS NULL;
PRINT 'ralpra_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

UPDATE p
SET p.pdp_fdKey = fd.fdKey
FROM ags.cn_PrDocP p
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'PrDocP' AND fd.fdNKey = p.pdpKey
WHERE p.pdp_fdKey IS NULL;
PRINT 'pdp_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

UPDATE m
SET m.am_fdKey = fd.fdKey
FROM ags.cstAgPnMnrl m
INNER JOIN ags.factDoc fd ON fd.fdDocType = N'CstAgPnMnrl' AND fd.fdNKey = m.amKey
WHERE m.am_fdKey IS NULL;
PRINT 'am_fdKey: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

-- -----------------------------------------------------------------------------
-- Шаг 3: factDocCost из плоских полей
-- -----------------------------------------------------------------------------
INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT rs.ras_fdKey, 212, rs.ras_total
FROM ags.ra_summ rs
WHERE rs.ras_fdKey IS NOT NULL AND rs.ras_total IS NOT NULL AND rs.ras_total <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey AND c.fdcoStCost = 212)
UNION ALL
SELECT rs.ras_fdKey, 195, rs.ras_work
FROM ags.ra_summ rs
WHERE rs.ras_fdKey IS NOT NULL AND rs.ras_work IS NOT NULL AND rs.ras_work <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey AND c.fdcoStCost = 195)
UNION ALL
SELECT rs.ras_fdKey, 172, rs.ras_equip
FROM ags.ra_summ rs
WHERE rs.ras_fdKey IS NOT NULL AND rs.ras_equip IS NOT NULL AND rs.ras_equip <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey AND c.fdcoStCost = 172)
UNION ALL
SELECT rs.ras_fdKey, 187, rs.ras_others
FROM ags.ra_summ rs
WHERE rs.ras_fdKey IS NOT NULL AND rs.ras_others IS NOT NULL AND rs.ras_others <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey AND c.fdcoStCost = 187);
PRINT 'factDocCost ra_summ (flat): ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT rcs.racs_fdKey, 212, rcs.raсs_total
FROM ags.ra_change_summ rcs
WHERE rcs.racs_fdKey IS NOT NULL AND rcs.raсs_total IS NOT NULL AND rcs.raсs_total <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rcs.racs_fdKey AND c.fdcoStCost = 212)
UNION ALL
SELECT rcs.racs_fdKey, 195, rcs.raсs_work
FROM ags.ra_change_summ rcs
WHERE rcs.racs_fdKey IS NOT NULL AND rcs.raсs_work IS NOT NULL AND rcs.raсs_work <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rcs.racs_fdKey AND c.fdcoStCost = 195)
UNION ALL
SELECT rcs.racs_fdKey, 172, rcs.raсs_equip
FROM ags.ra_change_summ rcs
WHERE rcs.racs_fdKey IS NOT NULL AND rcs.raсs_equip IS NOT NULL AND rcs.raсs_equip <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rcs.racs_fdKey AND c.fdcoStCost = 172)
UNION ALL
SELECT rcs.racs_fdKey, 187, rcs.raсs_others
FROM ags.ra_change_summ rcs
WHERE rcs.racs_fdKey IS NOT NULL AND rcs.raсs_others IS NOT NULL AND rcs.raсs_others <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rcs.racs_fdKey AND c.fdcoStCost = 187);
PRINT 'factDocCost ra_change_summ (flat): ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT p.oafp_fdKey, 148, p.oafpTotal
FROM ags.ogAgFeeP p
WHERE p.oafp_fdKey IS NOT NULL AND p.oafpTotal <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = p.oafp_fdKey AND c.fdcoStCost = 148);
PRINT 'factDocCost ogAgFeeP: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT r.ralpra_fdKey, 150, r.ralpraCostAndVat
FROM ags.ralpRaAu r
WHERE r.ralpra_fdKey IS NOT NULL AND r.ralpraCostAndVat IS NOT NULL AND r.ralpraCostAndVat <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = r.ralpra_fdKey AND c.fdcoStCost = 150);
PRINT 'factDocCost ralpRaAu: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT p.pdp_fdKey, z.stCostEl, p.costVAT
FROM ags.cn_PrDocP p
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
    WHERE d.cnpdKey = p.pdpPrDoc
) z
WHERE p.pdp_fdKey IS NOT NULL
  AND p.costVAT IS NOT NULL AND p.costVAT <> 0
  AND z.stCostEl IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM ags.factDocCost c
      WHERE c.fdcoFd = p.pdp_fdKey AND c.fdcoStCost = z.stCostEl
  );
PRINT 'factDocCost cn_PrDocP: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT m.am_fdKey, 169, m.amSum
FROM ags.cstAgPnMnrl m
WHERE m.am_fdKey IS NOT NULL AND m.amSum <> 0
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = m.am_fdKey AND c.fdcoStCost = 169);
PRINT 'factDocCost cstAgPnMnrl: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

-- -----------------------------------------------------------------------------
-- Шаг 4: дополнение из ra_summCt (исторические и прочие stcKey)
-- Плоские поля (шаг 3) имеют приоритет для 212/195/172/187
-- -----------------------------------------------------------------------------
INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT rs.ras_fdKey, ct.rscStCost, ct.rscSumm
FROM ags.ra_summCt ct
INNER JOIN ags.ra_summ rs ON rs.ras_key = ct.rscRaSumm
WHERE rs.ras_fdKey IS NOT NULL
  AND ct.rscSumm IS NOT NULL AND ct.rscSumm <> 0
  AND NOT EXISTS (
      SELECT 1 FROM ags.factDocCost c
      WHERE c.fdcoFd = rs.ras_fdKey AND c.fdcoStCost = ct.rscStCost
  );
PRINT 'factDocCost ra_summCt (доп.): ' + CAST(@@ROWCOUNT AS varchar(10));
GO

INSERT INTO ags.factDocCost (fdcoFd, fdcoStCost, fdcoSumm)
SELECT rcs.racs_fdKey, ct.rcscStCost, ct.rcscLim
FROM ags.ra_change_summCt ct
INNER JOIN ags.ra_change_summ rcs ON rcs.raсs_key = ct.rcscRaChSumm
WHERE rcs.racs_fdKey IS NOT NULL
  AND ct.rcscLim IS NOT NULL AND ct.rcscLim <> 0
  AND NOT EXISTS (
      SELECT 1 FROM ags.factDocCost c
      WHERE c.fdcoFd = rcs.racs_fdKey AND c.fdcoStCost = ct.rcscStCost
  );
PRINT 'factDocCost ra_change_summCt (доп.): ' + CAST(@@ROWCOUNT AS varchar(10));
GO

-- -----------------------------------------------------------------------------
-- Включить триггеры
-- -----------------------------------------------------------------------------
ENABLE TRIGGER ags.trgRaSumm_syncFactDoc ON ags.ra_summ;
ENABLE TRIGGER ags.trgRaChangeSumm_syncFactDoc ON ags.ra_change_summ;
ENABLE TRIGGER ags.trgOgAgFeeP_syncFactDoc ON ags.ogAgFeeP;
ENABLE TRIGGER ags.trgRalpRaAu_syncFactDoc ON ags.ralpRaAu;
ENABLE TRIGGER ags.trgCn_PrDocP_syncFactDoc ON ags.cn_PrDocP;
ENABLE TRIGGER ags.trgCstAgPnMnrl_syncFactDoc ON ags.cstAgPnMnrl;
GO

PRINT 'Триггеры включены.';
GO

-- -----------------------------------------------------------------------------
-- Проверка
-- -----------------------------------------------------------------------------
PRINT '--- Сводка factDoc по типам ---';
SELECT fdDocType, COUNT(*) AS cnt
FROM ags.factDoc
GROUP BY fdDocType
ORDER BY fdDocType;
GO

PRINT '--- Строки без *_fdKey (должно быть 0) ---';
SELECT
    (SELECT COUNT(*) FROM ags.ra_summ WHERE ras_fdKey IS NULL) AS ra_summ_null,
    (SELECT COUNT(*) FROM ags.ra_change_summ WHERE racs_fdKey IS NULL) AS ra_change_null,
    (SELECT COUNT(*) FROM ags.ogAgFeeP WHERE oafp_fdKey IS NULL) AS ogAgFeeP_null,
    (SELECT COUNT(*) FROM ags.ralpRaAu WHERE ralpra_fdKey IS NULL) AS ralp_null,
    (SELECT COUNT(*) FROM ags.cn_PrDocP WHERE pdp_fdKey IS NULL) AS prDocP_null,
    (SELECT COUNT(*) FROM ags.cstAgPnMnrl WHERE am_fdKey IS NULL) AS mnrl_null;
GO

PRINT '--- factDocCost: всего строк ---';
SELECT COUNT(*) AS factDocCost_total FROM ags.factDocCost;
GO

PRINT '--- ra_summ: строки с плоскими суммами без factDocCost ---';
SELECT COUNT(*) AS orphan_with_flat_sums
FROM ags.ra_summ rs
WHERE rs.ras_fdKey IS NOT NULL
  AND (
      (rs.ras_total IS NOT NULL AND rs.ras_total <> 0)
      OR (rs.ras_work IS NOT NULL AND rs.ras_work <> 0)
      OR (rs.ras_equip IS NOT NULL AND rs.ras_equip <> 0)
      OR (rs.ras_others IS NOT NULL AND rs.ras_others <> 0)
  )
  AND NOT EXISTS (SELECT 1 FROM ags.factDocCost c WHERE c.fdcoFd = rs.ras_fdKey);
GO

PRINT '=== 01d: завершено ===';
GO
