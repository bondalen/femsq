-- Access QueryDef: cn_PrDocImp
-- Type: 0

SELECT TOP 2147483647 cn_PrDocImp_26.*, IIf(IsNull([cnpdNum]),"NullИлиПусто",[cnpdNum]) AS cnpdNumNull, IIf(IsNull([cnpdDate]),#1/1/1900#,[cnpdDate]) AS cnpdDateNull, IIf(IsNull([cnpdCnInvNum]) Or [cnpdCnInvNum]="","NullИлиПусто",[cnpdCnInvNum]) AS cnpdCnInvNumNull, IIf(IsNull([cnpdCnInvDate]),#1/1/1900#,[cnpdCnInvDate]) AS cnpdCnInvDateNull, IIf(IsNull([cnpdCnNum]),"NullИлиПусто",[cnpdCnNum]) AS cnpdCnNumNull, IIf(IsNull([docOfAccountNum]) Or [docOfAccountNum]="","NullИлиПусто",[docOfAccountNum]) AS docOfAccountNumNull, IIf(IsNull([accountingDoc]) Or [accountingDoc]="","NullИлиПусто",[accountingDoc]) AS accountingDocNull, IIf(IsNull([object]) Or [object]="","NullИлиПусто",[object]) AS objectNull
FROM cn_PrDocImp_26;
