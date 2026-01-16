#!/usr/bin/env python3
"""
Скрипт импорта данных из MS Access таблиц ra_f, ra_ft_st, ra_ft_s, ra_ft_sn в MS SQL Server
Дата: 2026-01-15
Автор: Александр
"""

import csv
import pyodbc
from datetime import datetime
import sys
import os

# Параметры подключения к SQL Server
SERVER = 'localhost'
DATABASE = 'FishEye'  # Используется база данных FishEye (не femsq)
USERNAME = 'sa'
PASSWORD = 'kolob_OK1'  # Пароль из code/config/env/femsq-db.env

# Пути к CSV файлам
CSV_RA_F = '/tmp/ra_f_export.csv'
CSV_RA_FT_ST = '/tmp/ra_ft_st_export.csv'
CSV_RA_FT_S = '/tmp/ra_ft_s_export.csv'
CSV_RA_FT_SN = '/tmp/ra_ft_sn_export.csv'

def parse_access_date(date_str):
    """Преобразование даты из MS Access формата в datetime"""
    if not date_str or date_str == '' or date_str.lower() == 'null':
        return None
    try:
        # Различные форматы дат из Access
        formats = [
            '%m/%d/%y %H:%M:%S',  # "04/05/22 15:39:11"
            '%m/%d/%Y %H:%M:%S',  # "04/05/2022 15:39:11"
            '%Y-%m-%d %H:%M:%S',  # "2022-04-05 15:39:11"
            '%m/%d/%y',           # "04/05/22"
            '%m/%d/%Y',           # "04/05/2022"
            '%Y-%m-%d',           # "2022-04-05"
        ]
        for fmt in formats:
            try:
                return datetime.strptime(date_str.strip(), fmt)
            except:
                continue
        return None
    except:
        return None

def parse_bool(value):
    """Преобразование значения в BIT (0 или 1)"""
    if value is None or value == '' or str(value).lower() in ['null', 'none']:
        return None
    if isinstance(value, bool):
        return 1 if value else 0
    if isinstance(value, (int, float)):
        return 1 if value != 0 else 0
    str_value = str(value).lower().strip()
    if str_value in ['true', '1', 'yes', 'y', '-1', 'on']:
        return 1
    if str_value in ['false', '0', 'no', 'n', 'off', '']:
        return 0
    return None

def parse_int(value):
    """Преобразование значения в INT или None"""
    if value is None or value == '' or str(value).lower() in ['null', 'none']:
        return None
    try:
        return int(float(value))
    except:
        return None

def import_ra_ft_st(cursor, conn):
    """Импорт данных из ra_ft_st (типы источников)"""
    if not os.path.exists(CSV_RA_FT_ST):
        print(f"⚠ CSV файл не найден: {CSV_RA_FT_ST}")
        print("  Пропуск импорта ra_ft_st (таблица может быть пустой)")
        return 0
    
    imported_count = 0
    skipped_count = 0
    
    with open(CSV_RA_FT_ST, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            try:
                st_key = parse_int(row.get('st_key', row.get('key')))
                st_name = row.get('st_name', row.get('name', '')).strip()
                
                if not st_name:
                    skipped_count += 1
                    print(f"✗ Пропущена запись: пустое имя")
                    continue
                
                sql = """
                SET IDENTITY_INSERT ags.ra_ft_st ON;
                INSERT INTO ags.ra_ft_st (st_key, st_name, st_created, st_updated)
                VALUES (?, ?, GETDATE(), GETDATE());
                SET IDENTITY_INSERT ags.ra_ft_st OFF;
                """
                
                cursor.execute(sql, (st_key, st_name))
                conn.commit()
                
                imported_count += 1
                print(f"✓ Импортирован тип источника #{st_key}: {st_name}")
                
            except Exception as e:
                skipped_count += 1
                print(f"✗ Ошибка импорта записи: {e}")
                conn.rollback()
    
    return imported_count

def import_ra_ft_s(cursor, conn):
    """Импорт данных из ra_ft_s (источники/листы)"""
    if not os.path.exists(CSV_RA_FT_S):
        print(f"⚠ CSV файл не найден: {CSV_RA_FT_S}")
        print("  Пропуск импорта ra_ft_s (таблица может быть пустой)")
        return 0
    
    imported_count = 0
    skipped_count = 0
    
    with open(CSV_RA_FT_S, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            try:
                ft_s_key = parse_int(row.get('ft_s_key', row.get('key')))
                ft_s_type = parse_int(row.get('ft_s_type', row.get('type')))
                ft_s_num = parse_int(row.get('ft_s_num', row.get('num')))
                ft_s_sheet_type = parse_int(row.get('ft_s_sheet_type', row.get('sheet_type')))
                
                if ft_s_type is None or ft_s_num is None or ft_s_sheet_type is None:
                    skipped_count += 1
                    print(f"✗ Пропущена запись: обязательные поля пусты")
                    continue
                
                sql = """
                SET IDENTITY_INSERT ags.ra_ft_s ON;
                INSERT INTO ags.ra_ft_s (ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type, ft_s_created, ft_s_updated)
                VALUES (?, ?, ?, ?, GETDATE(), GETDATE());
                SET IDENTITY_INSERT ags.ra_ft_s OFF;
                """
                
                cursor.execute(sql, (ft_s_key, ft_s_type, ft_s_num, ft_s_sheet_type))
                conn.commit()
                
                imported_count += 1
                print(f"✓ Импортирован источник #{ft_s_key}: тип={ft_s_type}, номер={ft_s_num}")
                
            except Exception as e:
                skipped_count += 1
                print(f"✗ Ошибка импорта записи: {e}")
                conn.rollback()
    
    return imported_count

def import_ra_ft_sn(cursor, conn):
    """Импорт данных из ra_ft_sn (имена источников)"""
    if not os.path.exists(CSV_RA_FT_SN):
        print(f"⚠ CSV файл не найден: {CSV_RA_FT_SN}")
        print("  Пропуск импорта ra_ft_sn (таблица может быть пустой)")
        return 0
    
    imported_count = 0
    skipped_count = 0
    
    with open(CSV_RA_FT_SN, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            try:
                ftsn_key = parse_int(row.get('ftsn_key', row.get('key')))
                ftsn_ft_s = parse_int(row.get('ftsn_ft_s', row.get('ft_s')))
                ftsn_name = row.get('ftsn_name', row.get('name', '')).strip()
                
                if ftsn_ft_s is None or not ftsn_name:
                    skipped_count += 1
                    print(f"✗ Пропущена запись: обязательные поля пусты")
                    continue
                
                sql = """
                SET IDENTITY_INSERT ags.ra_ft_sn ON;
                INSERT INTO ags.ra_ft_sn (ftsn_key, ftsn_ft_s, ftsn_name, ftsn_created, ftsn_updated)
                VALUES (?, ?, ?, GETDATE(), GETDATE());
                SET IDENTITY_INSERT ags.ra_ft_sn OFF;
                """
                
                cursor.execute(sql, (ftsn_key, ftsn_ft_s, ftsn_name))
                conn.commit()
                
                imported_count += 1
                print(f"✓ Импортировано имя источника #{ftsn_key}: {ftsn_name} (источник={ftsn_ft_s})")
                
            except Exception as e:
                skipped_count += 1
                print(f"✗ Ошибка импорта записи: {e}")
                conn.rollback()
    
    return imported_count

def import_ra_f(cursor, conn):
    """Импорт данных из ra_f (файлы для проверки)"""
    if not os.path.exists(CSV_RA_F):
        print(f"✗ CSV файл не найден: {CSV_RA_F}")
        print("  Импорт ra_f невозможен без CSV файла")
        return 0
    
    imported_count = 0
    skipped_count = 0
    
    with open(CSV_RA_F, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            try:
                af_key = parse_int(row.get('af_key', row.get('key')))
                af_name = row.get('af_name', row.get('name', '')).strip()
                af_dir = parse_int(row.get('af_dir', row.get('dir')))
                af_type = parse_int(row.get('af_type', row.get('type')))
                af_execute = parse_bool(row.get('af_execute', row.get('execute')))
                af_source = parse_int(row.get('af_source', row.get('source')))
                af_adt_key = parse_int(row.get('af_adt_key', row.get('adt_key')))
                af_is_done = parse_bool(row.get('af_is_done', row.get('is_done')))
                af_is_source = parse_bool(row.get('af_is_source', row.get('is_source')))
                
                # Обязательные поля
                if not af_name or af_dir is None or af_type is None:
                    skipped_count += 1
                    print(f"✗ Пропущена запись: обязательные поля пусты (af_name={af_name}, af_dir={af_dir}, af_type={af_type})")
                    continue
                
                # Значения по умолчанию
                if af_execute is None:
                    af_execute = 1
                if af_is_done is None:
                    af_is_done = 0
                if af_is_source is None:
                    af_is_source = 0
                
                sql = """
                SET IDENTITY_INSERT ags.ra_f ON;
                INSERT INTO ags.ra_f 
                    (af_key, af_name, af_dir, af_type, af_execute, af_source, 
                     af_adt_key, af_is_done, af_is_source, af_created, af_updated)
                VALUES 
                    (?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), GETDATE());
                SET IDENTITY_INSERT ags.ra_f OFF;
                """
                
                cursor.execute(sql, (
                    af_key, af_name, af_dir, af_type, af_execute, af_source,
                    af_adt_key, af_is_done, af_is_source
                ))
                conn.commit()
                
                imported_count += 1
                print(f"✓ Импортирован файл #{af_key}: {af_name} (тип={af_type}, директория={af_dir})")
                
            except Exception as e:
                skipped_count += 1
                print(f"✗ Ошибка импорта записи {row.get('af_key', 'Unknown')}: {e}")
                conn.rollback()
    
    return imported_count

def import_data():
    """Импорт всех данных из CSV в SQL Server"""
    
    # Подключение к SQL Server
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
    
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        print(f"Подключено к SQL Server: {SERVER}/{DATABASE}")
        print("")
        
        total_imported = 0
        total_skipped = 0
        
        # Импорт в порядке зависимостей (FK constraints)
        print("="*60)
        print("1. Импорт ra_ft_st (типы источников)")
        print("="*60)
        count = import_ra_ft_st(cursor, conn)
        total_imported += count
        print(f"Импортировано: {count} записей\n")
        
        print("="*60)
        print("2. Импорт ra_ft_s (источники/листы)")
        print("="*60)
        count = import_ra_ft_s(cursor, conn)
        total_imported += count
        print(f"Импортировано: {count} записей\n")
        
        print("="*60)
        print("3. Импорт ra_ft_sn (имена источников)")
        print("="*60)
        count = import_ra_ft_sn(cursor, conn)
        total_imported += count
        print(f"Импортировано: {count} записей\n")
        
        print("="*60)
        print("4. Импорт ra_f (файлы для проверки)")
        print("="*60)
        count = import_ra_f(cursor, conn)
        total_imported += count
        print(f"Импортировано: {count} записей\n")
        
        print("="*60)
        print("Импорт завершён!")
        print(f"Всего успешно импортировано: {total_imported} записей")
        print("="*60)
        
        cursor.close()
        conn.close()
        
        return total_imported
        
    except Exception as e:
        print(f"Ошибка подключения к SQL Server: {e}")
        import traceback
        traceback.print_exc()
        return 0

if __name__ == '__main__':
    result = import_data()
    sys.exit(0 if result >= 0 else 1)
