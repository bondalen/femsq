#!/usr/bin/env python3
"""One-shot: ITVF fnIpgChRsltCstUtl2_2606 → MSTVF v8 (materialized #temp tables)."""
from pathlib import Path
import re

SRC = Path(__file__).with_name("04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql")
OUT = SRC  # overwrite in place after backup

COLUMNS = """        yKey int NULL,
        yyyy int NULL,
        mKey int NOT NULL,
        mNum int NULL,
        mCs nvarchar(287) NULL,
        mNm nvarchar(255) NULL,
        mQ nvarchar(255) NULL,
        mHy int NULL,
        ipgKey int NULL,
        ipgNm nvarchar(255) NULL,
        ipgStr date NULL,
        ipgEnd date NULL,
        cstaInvestor int NULL,
        ogaKey int NOT NULL,
        ogNm nvarchar(255) NOT NULL,
        branch int NOT NULL,
        typeGr nvarchar(50) NOT NULL,
        typeGrTtl nvarchar(23) NULL,
        lim money NULL,
        iShKey int NULL,
        iShNm nvarchar(100) NULL,
        limPlan nvarchar(255) NULL,
        cstAgPnCode nvarchar(255) NOT NULL,
        cstAgPnKey int NOT NULL,
        presentedAll money NULL,
        presentedAllAccum money NULL,
        presentedAllModul money NULL,
        presentedAllModulAccum money NULL,
        presented money NULL,
        presentedAccum money NULL,
        accepted money NULL,
        acceptedAccum money NULL,
        returned money NULL,
        returnedAccum money NULL,
        inProcess money NULL,
        inProcessAccum money NULL,
        notArrived money NULL,
        notArrivedAccum money NULL,
        presentedPrevYears money NULL,
        presentedPrevYearsAccum money NULL,
        acceptedPrevYears money NULL,
        acceptedPrevYearsAccum money NULL,
        returnedPrevYears money NULL,
        returnedPrevYearsAccum money NULL,
        inProcessPrevYears money NULL,
        inProcessPrevYearsAccum money NULL,
        notArrivedPrevYears money NULL,
        notArrivedPrevYearsAccum money NULL,
        agFeePresented money NULL,
        agFeePresentedAccum money NULL,
        agFeeAccepted money NULL,
        agFeeAcceptedAccum money NULL,
        agFeeReturned money NULL,
        agFeeReturnedAccum money NULL,
        agFeeInProcess money NULL,
        agFeeInProcessAccum money NULL,
        agFeeNotArrived money NULL,
        agFeeNotArrivedAccum money NULL,
        presentedRalp money NULL,
        presentedRalpAccum money NULL,
        acceptedRalp money NULL,
        acceptedRalpAccum money NULL,
        returnedRalp money NULL,
        returnedRalpAccum money NULL,
        inProcessRalp money NULL,
        inProcessRalpAccum money NULL,
        notArrivedRalp money NULL,
        notArrivedRalpAccum money NULL,
        storageSum money NULL,
        storageSumAccum money NULL,
        cctSum money NULL,
        cctSumAccum money NULL,
        MnrlSum money NULL,
        MnrlSumAccum money NULL,
        presentedTtl money NULL,
        presentedTtlAccum money NULL,
        acceptedAndInProcessTtl money NULL,
        acceptedAndInProcessTtlAccum money NULL,
        acceptedTtl money NULL,
        acceptedTtlAccum money NULL,
        returnedTtl money NULL,
        returnedTtlAccum money NULL,
        inProcessTtl money NULL,
        inProcessTtlAccum money NULL,
        notArrivedTtl money NULL,
        notArrivedTtlAccum money NULL,
        restOfLimit money NULL,
        restOfLimitInProcess money NULL,
        percentDev money NULL,
        percentDevInProcess money NULL"""


def extract_cte(text: str, name: str) -> str:
    """Extract CTE body (inside parentheses) for given name."""
    pat = rf"(?:WITH|,)\s*(?:--[^\n]*\n\s*)*{re.escape(name)}\s+AS\s+\("
    m = re.search(pat, text)
    if not m:
        raise ValueError(f"CTE {name} not found")
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth:
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
        i += 1
    return text[start : i - 1].strip()


def remove_ctes(text: str, names: list[str]) -> str:
  for name in names:
    while True:
      pat = rf"(?:WITH|,|^)\s*(?:--[^\n]*\n\s*)*{re.escape(name)}\s+AS\s+\("
      m = re.search(pat, text, re.MULTILINE)
      if not m:
        break
      start = m.start()
      pos = m.end()
      depth = 1
      while pos < len(text) and depth:
        if text[pos] == "(":
          depth += 1
        elif text[pos] == ")":
          depth -= 1
        pos += 1
      if pos < len(text) and text[pos] == ",":
        pos += 1
      text = text[:start] + text[pos:]
  text = text.strip()
  text = re.sub(r"^,\s*", "", text)
  text = re.sub(r"^(?:--[^\n]*\n\s*)+", "", text)
  if not text.startswith("WITH"):
    text = "WITH " + text
  return text


def main() -> None:
    raw = SRC.read_text(encoding="utf-8")
    if "RETURNS @TblRslt TABLE" in raw:
        print("Already MSTVF, skip")
        return

    # body inside RETURN ( ... )
    m = re.search(r"RETURN\s+\(\s*\n", raw)
    if not m:
        raise SystemExit("RETURN ( not found")
    body_start = m.end()
    # find matching closing paren before GO
    depth = 1
    i = body_start
    while i < len(raw) and depth:
        if raw[i] == "(":
            depth += 1
        elif raw[i] == ")":
            depth -= 1
        i += 1
    body = raw[body_start : i - 1]

    ls_yy = extract_cte(body, "lsYy")
    ra_fact = extract_cte(body, "raFact2408")
    ra_ralp = extract_cte(body, "raFactRalp")
    ra_mnrl = extract_cte(body, "raFactMnrl")
    ra_storage = extract_cte(body, "raFactStorage")
    mast_month = extract_cte(body, "mastMonthEnd")
    mastering = extract_cte(body, "mastering")
    scheme_rows = extract_cte(body, "schemeRows")

    main = remove_ctes(
        body,
        [
            "lsYy",
            "raFact2408",
            "raFactRalp",
            "raFactMnrl",
            "raFactStorage",
            "mastMonthEnd",
            "mastering",
            "schemeRows",
        ],
    )

    # Replacements in main query
    main = main.replace("CROSS JOIN lsYy ly", "CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly")
    main = main.replace(
        "INNER JOIN lsYy ly ON",
        "INNER JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly ON",
    )
    main = main.replace("FROM raFact2408", "FROM @raFact2408")
    main = main.replace("JOIN raFact2408", "JOIN @raFact2408")
    main = main.replace("FROM raFactRalp", "FROM @raFactRalp")
    main = main.replace("JOIN raFactRalp", "JOIN @raFactRalp")
    main = main.replace("FROM raFactMnrl", "FROM @raFactMnrl")
    main = main.replace("JOIN raFactMnrl", "JOIN @raFactMnrl")
    main = main.replace("FROM raFactStorage", "FROM @raFactStorage")
    main = main.replace("JOIN raFactStorage", "JOIN @raFactStorage")
    main = re.sub(r"\bschemeRows\b", "@schemeRows", main)

    main = main.replace(
        "ags.fnCstAgPnBranch(GETDATE(), cap.cstapKey) AS branch",
        "bc.branch",
    )
    # Add branchCache join after cap join in each base CTE block
    main = re.sub(
        r"(INNER JOIN ags\.cstAgPn cap ON cap\.cstapKey = [^\n]+\n)",
        r"\1        LEFT JOIN @branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey\n",
        main,
    )

    # Prep: ra fact queries use @yKey instead of lsYy
    def fix_ls_yy(sql: str) -> str:
        sql = re.sub(
            r"INNER JOIN lsYy ly ON p\.y = ly\.yKey\n(\s*)GROUP BY",
            r"WHERE p.y = @yKey\n\1GROUP BY",
            sql,
        )
        sql = re.sub(
            r"SELECT ly\.yKey, mm\.mNum",
            "SELECT y.yKey, mm.mNum",
            sql,
        )
        sql = re.sub(
            r"SELECT ly\.yKey, mmr\.mNum",
            "SELECT ym.yKey, mmr.mNum",
            sql,
        )
        sql = re.sub(
            r"INNER JOIN lsYy ly ON y\.yKey = ly\.yKey\n(\s*)GROUP BY",
            r"WHERE y.yKey = @yKey\n\1GROUP BY",
            sql,
        )
        sql = re.sub(
            r"GROUP BY ly\.yKey, mm\.mNum",
            "GROUP BY y.yKey, mm.mNum",
            sql,
        )
        sql = re.sub(
            r"INNER JOIN lsYy ly ON ym\.yKey = ly\.yKey\n(\s*)GROUP BY",
            r"WHERE ym.yKey = @yKey\n\1GROUP BY",
            sql,
        )
        sql = re.sub(
            r"GROUP BY ly\.yKey, mmr\.mNum",
            "GROUP BY ym.yKey, mmr.mNum",
            sql,
        )
        sql = sql.replace(
            "INNER JOIN lsYy ly ON yh.yKey = ly.yKey\n        INNER JOIN ags.mmmm mh",
            "INNER JOIN ags.mmmm mh",
        )
        sql = sql.replace(
            "WHERE (d.cnpdTpOrd = 1 OR d.cnpdTpOrd = 2 OR d.cnpdTpOrd = 4)",
            "WHERE yh.yKey = @yKey\n          AND (d.cnpdTpOrd = 1 OR d.cnpdTpOrd = 2 OR d.cnpdTpOrd = 4)",
        )
        sql = re.sub(
            r"INNER JOIN lsYy ly ON yy\.yKey = ly\.yKey",
            "WHERE yy.yKey = @yKey",
            sql,
        )
        return sql

    ra_fact_p = fix_ls_yy(ra_fact)
    ra_ralp_p = fix_ls_yy(ra_ralp)
    ra_mnrl_p = fix_ls_yy(ra_mnrl)
    ra_storage_p = fix_ls_yy(ra_storage)

    scheme_body = scheme_rows  # still uses alias mastering from CTE below
    scheme_insert = f"""
    INSERT INTO @mastMonthEnd (ipgKey, dAll)
    SELECT v.ipgcrvIpg AS ipgKey, MAX(d.dAll) AS dAll
    FROM ags.fnIpgChDats_2606(@ipgChKey) d
    INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey
        AND d.dAll >= v.ipgcrvStr AND (v.ipgcrvEnd IS NULL OR d.dAll <= v.ipgcrvEnd)
    GROUP BY v.ipgcrvIpg, YEAR(d.dAll), MONTH(d.dAll);

    ;WITH mastering AS (
        SELECT m.*, me.ipgKey, MONTH(me.dAll) AS mNum, v.ipgcrvStr AS ipgActStr, v.ipgcrvEnd AS ipgActEnd
        FROM ags.fnMasteringStIpgStCost_2606(@ipgStKey, @ipgChKey, @stCostKey, NULL) m
        INNER JOIN @mastMonthEnd me ON me.dAll = m.dAll
        INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = me.ipgKey
    )
    INSERT INTO @schemeRows
    {scheme_body}
"""

    header = raw[: raw.index("CREATE OR ALTER FUNCTION")]
    header = header.replace(
        "v7.1: ipgSchemeCombo",
        "v8 MSTVF: @schemeRows, @raFact*, @branchCache",
    )

    func = f"""CREATE OR ALTER FUNCTION ags.fnIpgChRsltCstUtl2_2606
(
    @ipgChKey   int,
    @ipgStKey   int = NULL,
    @stCostKey  int = NULL
)
RETURNS @TblRslt TABLE
(
{COLUMNS}
)
AS
BEGIN
    DECLARE @yKey int, @yyyy int;
    DECLARE @raFact2408 TABLE (
        yKey int, mNum int, cstAgPnKey int, typeGr nvarchar(50) NOT NULL,
        presentedAll money, presentedAllModul money,
        presented money, accepted money, returned money, inProcess money, notArrived money,
        presentedPrevYears money, acceptedPrevYears money, returnedPrevYears money,
        inProcessPrevYears money, notArrivedPrevYears money
    );
    DECLARE @raFactRalp TABLE (
        yKey int, mNum int, cstAgPnKey int, typeGr nvarchar(50) NOT NULL,
        presentedRalp money, acceptedRalp money, returnedRalp money,
        inProcessRalp money, notArrivedRalp money
    );
    DECLARE @raFactMnrl TABLE (
        yKey int, mNum int, cstAgPnKey int, MnrlSum money
    );
    DECLARE @raFactStorage TABLE (
        mNum int, cstAgPnKey int, storageSum money
    );
    DECLARE @schemeRows TABLE (
        ipgpCstAgPn int, dAll date, mNum int, ipgKey int,
        ipgActStr date, ipgActEnd date,
        iShKey int, iShNm nvarchar(100), typeGr nvarchar(50),
        lim money, presented money, accepted money,
        agFeePresented money, agFeeAccepted money,
        presentedRalp money, acceptedRalp money,
        storageSum money, cctSum money, MnrlSum money
    );
    DECLARE @mastMonthEnd TABLE (ipgKey int NOT NULL, dAll date NOT NULL);
    DECLARE @branchCache TABLE (
        cstapbCstAgPn int NOT NULL PRIMARY KEY,
        branch int NULL
    );

    SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
    FROM (
        {ls_yy.split('FROM', 1)[1].strip() if 'FROM' in ls_yy else ls_yy}
    ) q;

    INSERT INTO @raFact2408
    {ra_fact_p};

    INSERT INTO @raFactRalp
    {ra_ralp_p};

    INSERT INTO @raFactMnrl
    {ra_mnrl_p};

    INSERT INTO @raFactStorage
    {ra_storage_p};

{scheme_insert}

    INSERT INTO @branchCache (cstapbCstAgPn, branch)
    SELECT b.cstapbCstAgPn, MAX(b.cstapbBranch)
    FROM ags.cstAgPnBranch b
    WHERE (b.cstapbEnd IS NULL OR b.cstapbEnd >= CAST(GETDATE() AS date))
      AND (b.cstapbStart IS NULL OR b.cstapbStart <= CAST(GETDATE() AS date))
    GROUP BY b.cstapbCstAgPn;

    INSERT INTO @TblRslt
    {main};

    RETURN;
END
"""

    # Fix lsYy extraction for @yKey init
    ls_init = ls_yy
    func = func.replace(
        f"""    SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
    FROM (
        {ls_yy.split('FROM', 1)[1].strip() if 'FROM' in ls_yy else ls_yy}
    ) q;""",
        f"""    SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
    FROM (
        SELECT MAX(y2.yyyy) AS mxY
        FROM ags.ipgChRl_2606 v
        INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
        INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
        WHERE v.ipgcrvChain = @ipgChKey
    ) x
    INNER JOIN ags.yyyy y ON y.yyyy = x.mxY;""",
    )

    tail = raw[raw.index("GO\n\nPRINT", i) :]
    out = header + func + "\n" + tail
    backup = SRC.with_suffix(".sql.v71_itvf.bak")
    backup.write_text(raw, encoding="utf-8")
    OUT.write_text(out, encoding="utf-8")
    print(f"Written {OUT} (backup {backup})")


if __name__ == "__main__":
    main()
