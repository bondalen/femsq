-- =============================================================================
-- test_sudz.invDbtVar — вариант контекста долга (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §2.3
-- =============================================================================

IF OBJECT_ID(N'test_sudz.invDbtVar', N'U') IS NULL
BEGIN
    CREATE TABLE test_sudz.invDbtVar
    (
        idvvKey         int         NOT NULL IDENTITY(1, 1),
        idvvCnNum       int         NOT NULL,
        idvvInvNum      int         NOT NULL,
        idvvAccnt       int         NOT NULL,
        idvvCn_s_org    int         NOT NULL,
        idvvTimeOfEntry datetime    NOT NULL
            CONSTRAINT DF_invDbtVar_idvvTimeOfEntry DEFAULT (getdate()),

        CONSTRAINT PK_invDbtVar PRIMARY KEY CLUSTERED (idvvKey),
        CONSTRAINT UX_invDbtVar_Context UNIQUE (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org),

        CONSTRAINT FK_invDbtVar_cnNum FOREIGN KEY (idvvCnNum)
            REFERENCES ags.cnNum (cnnKey),
        CONSTRAINT FK_invDbtVar_invNum FOREIGN KEY (idvvInvNum)
            REFERENCES ags.invNum (inKey),
        CONSTRAINT FK_invDbtVar_accnt FOREIGN KEY (idvvAccnt)
            REFERENCES ags.accnt (account_key),
        CONSTRAINT FK_invDbtVar_cn_s_org FOREIGN KEY (idvvCn_s_org)
            REFERENCES ags.cn_s_org (cn_s_org_key)
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    WHERE ep.major_id = OBJECT_ID(N'test_sudz.invDbtVar')
      AND ep.minor_id = 0
      AND ep.name = N'MS_Description'
)
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'СУДЗ песочница: вариант контекста долга (cnNum/invNum/accnt/cn_s_org). Без ciaName.',
        @level0type = N'SCHEMA', @level0name = N'test_sudz',
        @level1type = N'TABLE',  @level1name = N'invDbtVar';
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable, c.is_identity
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'test_sudz.invDbtVar')
ORDER BY c.column_id;
GO
