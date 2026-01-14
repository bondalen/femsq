#!/usr/bin/env python3
"""Вставка данных ra_a в SQL Server"""
import csv
import sys

csv.field_size_limit(10**7)

# Чтение CSV
print("Чтение данных из CSV...")
records = []
with open('/tmp/ra_a_export.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        # Парсинг даты из формата Access "04/05/22 15:39:11" в SQL Server формат
        date_parts = row['adt_date'].split(' ')
        date_part = date_parts[0].split('/')  # MM/DD/YY
        time_part = date_parts[1] if len(date_parts) > 1 else '00:00:00'
        
        # Преобразуем в 20YY-MM-DD HH:MM:SS
        year = '20' + date_part[2]
        month = date_part[0].zfill(2)
        day = date_part[1].zfill(2)
        sql_date = f"{year}-{month}-{day} {time_part}"
        
        # Экранирование одинарных кавычек в HTML
        results = row['adt_results'].replace("'", "''")
        name = row['adt_name'].replace("'", "''")
        
        records.append({
            'adt_key': row['adt_key'],
            'adt_name': name,
            'adt_date': sql_date,
            'adt_results': results,
            'adt_dir': row['adt_dir'],
            'adt_type': row['adt_type'],
            'adt_AddRA': '1' if row['adt_AddRA'].lower() in ['true', '1', 'yes', '-1'] else '0'
        })

print(f"Прочитано {len(records)} записей")

# Вывод SQL INSERT-ов
for rec in records:
    sql = f"""SET IDENTITY_INSERT ags.ra_a ON;
INSERT INTO ags.ra_a (adt_key, adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA, adt_created, adt_updated)
VALUES ({rec['adt_key']}, N'{rec['adt_name']}', '{rec['adt_date']}', N'{rec['adt_results']}', {rec['adt_dir']}, {rec['adt_type']}, {rec['adt_AddRA']}, GETDATE(), GETDATE());
SET IDENTITY_INSERT ags.ra_a OFF;
"""
    print(f"\n-- Запись {rec['adt_key']}: {rec['adt_name']}")
    print(sql)
