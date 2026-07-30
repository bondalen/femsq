#!/usr/bin/env bash
# Rewrite Access-export INSERT scripts to target ags.i_ra_* shadow tables (Docker dry-run).
# Usage: ./rewrite_to_shadow.sh /path/to/export_dir /path/to/out_dir
set -euo pipefail
SRC="${1:?export dir}"
DST="${2:?out dir}"
mkdir -p "$DST"
# UTF-16 LE from Access VBA → UTF-8 for sqlcmd/DBHub
for f in "$SRC"/0*.sql; do
  base="$(basename "$f")"
  # strip BOM / convert UTF-16 if needed
  if file "$f" | grep -qi 'UTF-16\|Little-endian'; then
    iconv -f UTF-16LE -t UTF-8 "$f" | sed '1s/^\xEF\xBB\xBF//' > "$DST/_tmp_$base"
  else
    # may already be UTF-8 / ASCII
    sed '1s/^\xEF\xBB\xBF//' "$f" > "$DST/_tmp_$base" || cp "$f" "$DST/_tmp_$base"
  fi
  sed -E \
    -e 's/ags\.ra_at/ags.i_ra_at/g' \
    -e 's/ags\.ra_dir/ags.i_ra_dir/g' \
    -e 's/ags\.ra_ft_st/ags.i_ra_ft_st/g' \
    -e 's/ags\.ra_ft_sn/ags.i_ra_ft_sn/g' \
    -e 's/ags\.ra_ft_s/ags.i_ra_ft_s/g' \
    -e 's/ags\.ra_ft([^_])/ags.i_ra_ft\1/g' \
    -e 's/ags\.ra_ft;/ags.i_ra_ft;/g' \
    -e 's/ags\.ra_ft$/ags.i_ra_ft/g' \
    -e 's/ags\.ra_a([^-zA-Z_])/ags.i_ra_a\1/g' \
    -e 's/ags\.ra_a;/ags.i_ra_a;/g' \
    -e 's/ags\.ra_f([^_a-zA-Z])/ags.i_ra_f\1/g' \
    -e 's/ags\.ra_f;/ags.i_ra_f;/g' \
    "$DST/_tmp_$base" > "$DST/$base"
  rm -f "$DST/_tmp_$base"
  echo "rewrote $base"
done
echo "OUT=$DST"
