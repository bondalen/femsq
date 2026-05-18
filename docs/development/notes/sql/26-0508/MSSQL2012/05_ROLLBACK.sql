USE [FishEye]
GO

-- =============================================================================
-- Файл:    05_ROLLBACK.sql
-- Пакет:   docs/development/notes/sql/26-0508/MSSQL2012/
-- Назначение: Откат _2605 (SQL Server 2012 SP4+).
-- =============================================================================

IF OBJECT_ID(N'ags.spMstrg_2605', N'P') IS NOT NULL
    DROP PROCEDURE [ags].[spMstrg_2605];
GO
PRINT 'DROP: ags.spMstrg_2605'
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2605', N'IF') IS NOT NULL
    DROP FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2605];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtlPercentBrn_2605'
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtl2_2605', N'IF') IS NOT NULL
    DROP FUNCTION [ags].[fnIpgChRsltCstUtl2_2605];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtl2_2605'
GO

PRINT 'Откат _2605 завершён'
GO
