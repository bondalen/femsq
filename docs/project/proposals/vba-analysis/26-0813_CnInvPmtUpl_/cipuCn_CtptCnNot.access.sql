-- Access QueryDef: cipuCn_CtptCnNot
-- Шаг 3 btnUpload (основа SqlCipuCn_CtptCnNot): пары (БУиРГ + № договора) из cipuCn_Ctpt,
-- которых нет как «исполнитель + номер» в agsCnCtptExequtorSmplBuirg.
-- CnName: пустой/Null → «NullИлиПусто» (как в CnInvPmtUplTblNull).
-- LEFT JOIN + HAVING Count(cn_key)=0: Count не считает Null — анти-join.
-- agsCnCtptExequtorSmplBuirg — объект Access (в FishEye нет такого имени);
-- ближайшая VIEW ags.cn_s_orgExeBuirg (cn_number + org_id_value_l, cn_s_type=2) —
-- не отождествлять до съёма QueryDef/TableDef.
-- VBA не читает CountCnKey: SqlCipuCn_CtptCnNot() делает FROM этого QueryDef
-- и отдельно Count(ags_cn/cnNum) AS countCn (схожий № договора в БД).
-- Nav: cipuCn_CtptCnNot / NotOld / NotOld2 — Old не снимать.
-- Снято 2026-08-17 (режим SQL).

SELECT u.CntrPrtNum, u.CntrPrtName, u.CnName, u.org_id_key, Count(u.cn_key) AS CountCnKey
FROM (SELECT z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, e.cn_key FROM (SELECT CntrPrtNum, CntrPrtName, IIf(isnull(a.CnName),"NullИлиПусто",IIf(a.CnName="","NullИлиПусто",a.CnName)) AS CnName, org_id_key FROM cipuCn_Ctpt AS a)  AS z LEFT JOIN agsCnCtptExequtorSmplBuirg AS e ON (z.CntrPrtNum = e.org_id_value_l) AND (z.CnName = e.cn_number) GROUP BY z.CntrPrtNum, z.CntrPrtName, z.CnName, z.org_id_key, e.cn_key)  AS u
GROUP BY u.CntrPrtNum, u.CntrPrtName, u.CnName, u.org_id_key
HAVING (((Count(u.cn_key))=0));
