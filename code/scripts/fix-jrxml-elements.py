#!/usr/bin/env python3
"""
Скрипт для преобразования элементов <element kind="..."> в прямые элементы JasperReports
"""
import re
import sys
from xml.etree import ElementTree as ET
from xml.dom import minidom

def convert_element_to_direct(element_str):
    """Преобразует элемент <element kind="..."> в прямой элемент"""
    
    # Извлекаем тип элемента
    kind_match = re.search(r'kind="([^"]+)"', element_str)
    if not kind_match:
        return element_str
    kind = kind_match.group(1)
    
    # Извлекаем все атрибуты
    attrs = {}
    for attr in ['uuid', 'mode', 'x', 'y', 'width', 'height', 'forecolor', 'backcolor', 
                 'fontName', 'fontSize', 'hTextAlign', 'vTextAlign', 'bold', 'blankWhenNull',
                 'pattern']:
        match = re.search(rf'{attr}="([^"]+)"', element_str)
        if match:
            attrs[attr] = match.group(1)
    
    # Извлекаем содержимое (text или expression)
    text_match = re.search(r'<text><!\[CDATA\[(.*?)\]\]></text>', element_str, re.DOTALL)
    expression_match = re.search(r'<expression><!\[CDATA\[(.*?)\]\]></expression>', element_str, re.DOTALL)
    pen_match = re.search(r'<pen\s+([^>]+)/>', element_str)
    
    if kind == 'rectangle':
        # Преобразуем rectangle
        mode = attrs.get('mode', 'Transparent')
        backcolor = attrs.get('backcolor', '')
        result = f'<rectangle>\n'
        result += f'				<reportElement x="{attrs.get("x", "0")}" y="{attrs.get("y", "0")}" '
        result += f'width="{attrs.get("width", "0")}" height="{attrs.get("height", "0")}" '
        if attrs.get('uuid'):
            result += f'uuid="{attrs["uuid"]}" '
        if mode != 'Transparent':
            result += f'mode="{mode}" '
        if backcolor:
            result += f'backcolor="{backcolor}"'
        result += '/>\n'
        if pen_match:
            pen_attrs = pen_match.group(1)
            result += f'				<graphicElement>\n'
            result += f'					<pen {pen_attrs}/>\n'
            result += f'				</graphicElement>\n'
        result += '			</rectangle>'
        return result
    
    elif kind == 'staticText':
        # Преобразуем staticText
        result = '<staticText>\n'
        result += '				<reportElement '
        result += f'x="{attrs.get("x", "0")}" y="{attrs.get("y", "0")}" '
        result += f'width="{attrs.get("width", "0")}" height="{attrs.get("height", "0")}" '
        if attrs.get('uuid'):
            result += f'uuid="{attrs["uuid"]}" '
        if attrs.get('mode'):
            result += f'mode="{attrs["mode"]}" '
        if attrs.get('forecolor'):
            result += f'forecolor="{attrs["forecolor"]}" '
        if attrs.get('backcolor'):
            result += f'backcolor="{attrs["backcolor"]}"'
        result += '/>\n'
        
        # textElement
        h_align = attrs.get('hTextAlign', 'Left')
        v_align = attrs.get('vTextAlign', 'Top')
        text_align_map = {'Left': 'Left', 'Center': 'Center', 'Right': 'Right'}
        vert_align_map = {'Top': 'Top', 'Middle': 'Middle', 'Bottom': 'Bottom'}
        result += '				<textElement '
        result += f'textAlignment="{text_align_map.get(h_align, "Left")}" '
        result += f'verticalAlignment="{vert_align_map.get(v_align, "Top")}">\n'
        
        # font
        font_name = attrs.get('fontName', 'DejaVu Sans')
        font_size = attrs.get('fontSize', '10')
        is_bold = attrs.get('bold', 'false') == 'true'
        result += '					<font '
        result += f'fontName="{font_name}" size="{font_size}"'
        if is_bold:
            result += ' isBold="true"'
        result += '/>\n'
        result += '				</textElement>\n'
        
        # text
        if text_match:
            text_content = text_match.group(1)
            result += f'				<text><![CDATA[{text_content}]]></text>\n'
        result += '			</staticText>'
        return result
    
    elif kind == 'textField':
        # Преобразуем textField
        result = '<textField>\n'
        result += '				<reportElement '
        result += f'x="{attrs.get("x", "0")}" y="{attrs.get("y", "0")}" '
        result += f'width="{attrs.get("width", "0")}" height="{attrs.get("height", "0")}" '
        if attrs.get('uuid'):
            result += f'uuid="{attrs["uuid"]}" '
        if attrs.get('forecolor'):
            result += f'forecolor="{attrs["forecolor"]}" '
        if attrs.get('backcolor'):
            result += f'backcolor="{attrs["backcolor"]}"'
        result += '/>\n'
        
        # textElement
        h_align = attrs.get('hTextAlign', 'Left')
        v_align = attrs.get('vTextAlign', 'Top')
        text_align_map = {'Left': 'Left', 'Center': 'Center', 'Right': 'Right'}
        vert_align_map = {'Top': 'Top', 'Middle': 'Middle', 'Bottom': 'Bottom'}
        result += '				<textElement '
        result += f'textAlignment="{text_align_map.get(h_align, "Left")}" '
        result += f'verticalAlignment="{vert_align_map.get(v_align, "Top")}">\n'
        
        # font
        font_name = attrs.get('fontName', 'DejaVu Sans')
        font_size = attrs.get('fontSize', '10')
        is_bold = attrs.get('bold', 'false') == 'true'
        result += '					<font '
        result += f'fontName="{font_name}" size="{font_size}"'
        if is_bold:
            result += ' isBold="true"'
        result += '/>\n'
        result += '				</textElement>\n'
        
        # pattern
        if attrs.get('pattern'):
            result += f'				<patternExpression><![CDATA["{attrs["pattern"]}"]]></patternExpression>\n'
        
        # expression
        if expression_match:
            expr_content = expression_match.group(1)
            result += f'				<expression><![CDATA[{expr_content}]]></expression>\n'
        elif attrs.get('blankWhenNull') == 'true':
            result += '				<expression><![CDATA[]]></expression>\n'
        
        result += '			</textField>'
        return result
    
    return element_str

def fix_jrxml_file(input_file, output_file):
    """Исправляет JRXML файл, заменяя все <element kind="..."> на прямые элементы"""
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Находим все элементы <element kind="..."> ... </element>
    pattern = r'(\s*)<element kind="([^"]+)"([^>]*)>(.*?)</element>'
    
    def replace_element(match):
        indent = match.group(1)
        kind = match.group(2)
        attrs_str = match.group(3)
        inner_content = match.group(4)
        
        # Собираем полный элемент для обработки
        full_element = f'<element kind="{kind}"{attrs_str}>{inner_content}</element>'
        
        # Преобразуем
        converted = convert_element_to_direct(full_element)
        
        # Добавляем правильные отступы
        lines = converted.split('\n')
        indented_lines = [indent + line if line.strip() else line for line in lines]
        return '\n'.join(indented_lines)
    
    # Заменяем все элементы
    new_content = re.sub(pattern, replace_element, content, flags=re.DOTALL)
    
    # Сохраняем
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"Преобразовано элементов в файле {input_file}")
    print(f"Результат сохранён в {output_file}")

if __name__ == '__main__':
    input_file = 'code/femsq-backend/femsq-reports/src/main/resources/reports/embedded/mstrgAg_23_Branch_q2m_2408_25.jrxml'
    output_file = input_file  # Перезаписываем исходный файл
    
    fix_jrxml_file(input_file, output_file)

