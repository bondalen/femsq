#!/usr/bin/env python3
"""
Скрипт импорта данных из MS Access таблицы ra_a в MS SQL Server
Дата: 2026-01-12
Автор: Александр
"""

import csv
import pyodbc
from datetime import datetime
import sys

# Параметры подключения к SQL Server
SERVER = 'localhost'
DATABASE = 'femsq'
USERNAME = 'sa'
PASSWORD = 'YourPassword123!'  # Замените на реальный пароль

# Путь к CSV файлу
CSV_FILE = '/tmp/ra_a_export.csv'

def parse_access_date(date_str):
    """Преобразование даты из MS Access формата в datetime"""
    if not date_str or date_str == '':
        return None
    try:
        # Формат: "04/05/22 15:39:11" (MM/DD/YY HH:MM:SS)
        return datetime.strptime(date_str, '%m/%d/%y %H:%M:%S')
    except:
        return None

def import_data():
    """Импорт данных из CSV в SQL Server"""
    
    # Подключение к SQL Server
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
    
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        print(f"Подключено к SQL Server: {SERVER}/{DATABASE}")
        
        # Открытие CSV файла
        with open(CSV_FILE, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            imported_count = 0
            skipped_count = 0
            
            for row in reader:
                try:
                    # Извлечение данных
                    adt_key = int(row['adt_key'])
                    adt_name = row['adt_name']
                    adt_date = parse_access_date(row['adt_date'])
                    adt_results = row['adt_results']
                    adt_dir = int(row['adt_dir'])
                    adt_type = int(row['adt_type'])
                    adt_AddRA = 1 if row['adt_AddRA'].lower() in ['true', '1', 'yes'] else 0
                    
                    # Вставка данных
                    sql = """
                    SET IDENTITY_INSERT ags.ra_a ON;
                    INSERT INTO ags.ra_a 
                        (adt_key, adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA, adt_created, adt_updated)
                    VALUES 
                        (?, ?, ?, ?, ?, ?, ?, GETDATE(), GETDATE());
                    SET IDENTITY_INSERT ags.ra_a OFF;
                    """
                    
                    cursor.execute(sql, (adt_key, adt_name, adt_date, adt_results, adt_dir, adt_type, adt_AddRA))
                    conn.commit()
                    
                    imported_count += 1
                    print(f"✓ Импортирована ревизия #{adt_key}: {adt_name}")
                    
                except Exception as e:
                    skipped_count += 1
                    print(f"✗ Ошибка импорта записи {row.get('adt_key', 'Unknown')}: {e}")
                    conn.rollback()
        
        print(f"\n{'='*60}")
        print(f"Импорт завершён!")
        print(f"Успешно импортировано: {imported_count} записей")
        print(f"Пропущено: {skipped_count} записей")
        print(f"{'='*60}")
        
        cursor.close()
        conn.close()
        
        return imported_count
        
    except Exception as e:
        print(f"Ошибка подключения к SQL Server: {e}")
        return 0

if __name__ == '__main__':
    result = import_data()
    sys.exit(0 if result > 0 else 1)
