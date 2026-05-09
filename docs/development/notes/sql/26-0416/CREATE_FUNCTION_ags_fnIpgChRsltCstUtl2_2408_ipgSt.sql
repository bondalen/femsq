USE [FishEye]
GO

/****** Object:  UserDefinedFunction [ags].[fnIpgChRsltCstUtl2_2408_ipgSt]    Script Date: 16.04.2026 12:19:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<bondale>
-- Create date: <20.03.2026>
-- Description:	<Получаем освоение лимитов по каждой *Стройке* для *Цепи инвестпрограмм* для определенного пункта структуры инвестпрограммы>
-- =============================================
CREATE FUNCTION [ags].[fnIpgChRsltCstUtl2_2408_ipgSt] 
(	
	-- Параметры
	@ipgChKey	int,			-- цепочка инвестпрограмм
	@ipgSt		nvarchar(255)	-- строковое обозначение пункта структуры инвестпрограммы 
)
RETURNS TABLE 
AS
RETURN 
(
	select s.cst_type, f.*
		from [ags].[fnIpgChRsltCstUtl2_2408](@ipgChKey) f
			join ags.[importIpgSt_26-0320] s on f.cstAgPnCode = s.cst
		where s.cst_type = @ipgSt
)
GO


