Attribute VB_Name = "rep_parsing_25-1204"
Option Compare Database
Option Explicit

' =====================================================================
' ИСПРАВЛЕННЫЙ VBA СКРИПТ ДЛЯ ЭКСПОРТА СТРУКТУРЫ ОТЧЁТА MS ACCESS
' =====================================================================
' Версия: 1.0.1 (исправлена ошибка с GroupLevel)
' Дата: 2025-12-05
' Автор: Александр (проект FEMSQ)
' =====================================================================

' ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
Private intFileNum As Integer

' =====================================================================
' ОСНОВНАЯ ПРОЦЕДУРА ЭКСПОРТА mstrgAg_23_Branch_q2m_2408_25
' =====================================================================
Sub ExportAccessReportStructure()
    On Error GoTo ErrorHandler
    
    Dim rpt As Report
    Dim strReportName As String
    Dim strOutputPath As String
    Dim strFilePath As String
    
    ' === НАСТРОЙКИ ===
    strReportName = InputBox("Введите имя отчёта для экспорта:", "Экспорт структуры отчёта", "")
    
    If strReportName = "" Then
        MsgBox "Операция отменена.", vbInformation
        Exit Sub
    End If
    
    ' Проверка существования отчёта
    If Not ReportExists(strReportName) Then
        MsgBox "Отчёт '" & strReportName & "' не найден в базе данных.", vbCritical
        Exit Sub
    End If
    
    ' Путь для сохранения
    strOutputPath = CurrentProject.path & "\"
    strFilePath = strOutputPath & strReportName & "_structure.txt"
    
    ' Предложить пользователю выбрать путь
    Dim strCustomPath As String
    strCustomPath = InputBox("Укажите полный путь для сохранения файла:" & vbCrLf & _
                            "(оставьте пустым для использования пути по умолчанию)", _
                            "Путь сохранения", strFilePath)
    
    If strCustomPath <> "" Then
        strFilePath = strCustomPath
    End If
    
    ' === ОТКРЫТИЕ ОТЧЁТА В РЕЖИМЕ КОНСТРУКТОРА ===
    DoCmd.Echo False
    DoCmd.OpenReport strReportName, acViewDesign
    Set rpt = Reports(strReportName)
    
    ' === СОЗДАНИЕ ВЫХОДНОГО ФАЙЛА ===
    intFileNum = FreeFile
    Open strFilePath For Output As intFileNum
    
    ' === ЗАГОЛОВОК ФАЙЛА ===
    WriteHeader strReportName
    
    ' === ЭКСПОРТ ОСНОВНЫХ СВОЙСТВ ОТЧЁТА ===
    WriteReportProperties rpt
    
    ' === ЭКСПОРТ ГРУПП (ГРУППИРОВКИ) ===
    WriteReportGroups rpt
    
    ' === ЭКСПОРТ СЕКЦИЙ ===
    WriteReportSections rpt
    
    ' === ЭКСПОРТ ЭЛЕМЕНТОВ УПРАВЛЕНИЯ ===
    WriteReportControls rpt
    
    ' === ЭКСПОРТ VBA КОДА (если есть) ===
    WriteReportVBACode rpt
    
    ' === ЗАВЕРШЕНИЕ ===
    Close #intFileNum
    DoCmd.Close acReport, strReportName, acSaveNo
    DoCmd.Echo True
    
    MsgBox "Структура отчёта успешно экспортирована!" & vbCrLf & vbCrLf & _
           "Файл: " & strFilePath, vbInformation, "Экспорт завершён"
    
    Exit Sub

ErrorHandler:
    If intFileNum <> 0 Then Close #intFileNum
    DoCmd.Echo True
    On Error Resume Next
    DoCmd.Close acReport, strReportName, acSaveNo
    On Error GoTo 0
    MsgBox "Ошибка при экспорте структуры отчёта:" & vbCrLf & vbCrLf & _
           "Описание: " & Err.Description & vbCrLf & _
           "Номер: " & Err.Number, vbCritical, "Ошибка"
End Sub

' =====================================================================
' ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ ЗАПИСИ
' =====================================================================

Private Sub WriteHeader(strReportName As String)
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "СТРУКТУРА ОТЧЁТА MS ACCESS"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "Имя отчёта: " & strReportName
    Print #intFileNum, "Дата экспорта: " & Format(Now(), "dd.mm.yyyy hh:nn:ss")
    Print #intFileNum, "База данных: " & CurrentProject.name
    Print #intFileNum, "Путь к БД: " & CurrentProject.path
    Print #intFileNum, "Версия Access: " & Application.Version
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
End Sub

Private Sub WriteReportProperties(rpt As Report)
    On Error Resume Next
    
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "ОСНОВНЫЕ СВОЙСТВА ОТЧЁТА"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
    
    Print #intFileNum, "[General]"
    Print #intFileNum, "Name = " & rpt.name
    Print #intFileNum, "Caption = " & rpt.Caption
    Print #intFileNum, "HasModule = " & rpt.HasModule
    Print #intFileNum, ""
    
    Print #intFileNum, "[Data Source]"
    Print #intFileNum, "RecordSource = " & rpt.RecordSource
    Print #intFileNum, "Filter = " & rpt.Filter
    Print #intFileNum, "FilterOn = " & rpt.FilterOn
    Print #intFileNum, "OrderBy = " & rpt.OrderBy
    Print #intFileNum, "OrderByOn = " & rpt.OrderByOn
    Print #intFileNum, ""
    
    Print #intFileNum, "[Page Setup]"
    Print #intFileNum, "Width = " & rpt.Width & " twips (" & TwipsToMM(rpt.Width) & " mm)"
    Print #intFileNum, "PictureAlignment = " & rpt.PictureAlignment
    Print #intFileNum, "PictureSizeMode = " & rpt.PictureSizeMode
    Print #intFileNum, ""
    
    Print #intFileNum, "[Printing]"
    Print #intFileNum, "Printer = " & rpt.Printer
    Print #intFileNum, ""
    
    On Error GoTo 0
End Sub

' ИСПРАВЛЕННАЯ ПРОЦЕДУРА - без использования переменной GroupLevel
Private Sub WriteReportGroups(rpt As Report)
    On Error Resume Next
    
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "Группировки и сортировка"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
    
    Dim i As Integer
    Dim hasGroups As Boolean
    
    ' Попытка получить первую группу для проверки наличия
    hasGroups = False
    On Error Resume Next
    If Not IsNull(rpt.GroupLevel(0).ControlSource) Then
        hasGroups = True
    End If
    On Error GoTo 0
    
    If Not hasGroups Then
        Print #intFileNum, "Группировки отсутствуют"
        Print #intFileNum, ""
    Else
        ' Проходим по группам до ошибки
        i = 0
        On Error Resume Next
        Do While Err.Number = 0
            Print #intFileNum, "[Group Level " & (i + 1) & "]"
            Print #intFileNum, "ControlSource = " & rpt.GroupLevel(i).ControlSource
            Print #intFileNum, "GroupOn = " & GetGroupOnName(rpt.GroupLevel(i).groupOn)
            Print #intFileNum, "GroupInterval = " & rpt.GroupLevel(i).GroupInterval
            Print #intFileNum, "KeepTogether = " & GetKeepTogetherName(rpt.GroupLevel(i).keepTogether)
            Print #intFileNum, "GroupHeader = " & rpt.GroupLevel(i).GroupHeader
            Print #intFileNum, "GroupFooter = " & rpt.GroupLevel(i).GroupFooter
            Print #intFileNum, "SortOrder = " & IIf(rpt.GroupLevel(i).SortOrder = False, "Ascending", "Descending")
            Print #intFileNum, ""
            
            i = i + 1
            ' Пробуем получить следующую группу
            Dim testVar As Variant
            testVar = rpt.GroupLevel(i).ControlSource
        Loop
        On Error GoTo 0
    End If
End Sub

Private Sub WriteReportSections(rpt As Report)
    On Error Resume Next
    
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "СЕКЦИИ ОТЧЁТА"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
    
    Dim sec As Section
    Dim i As Integer
    
    ' Проходим по секциям до ошибки (обычно до 10 секций максимум)
    i = 0
    Do While i < 20  ' Ограничение на 20 секций (с запасом)
        On Error Resume Next
        
        ' Пытаемся получить секцию
        Set sec = rpt.Section(i)
        
        ' Если ошибка - секций больше нет
        If Err.Number <> 0 Then
            Err.Clear
            Exit Do
        End If
        
        ' Выводим информацию о секции
        Print #intFileNum, "[" & GetSectionName(sec.name) & "]"
        Print #intFileNum, "Name = " & sec.name
        Print #intFileNum, "Height = " & sec.Height & " twips (" & TwipsToMM(sec.Height) & " mm)"
        Print #intFileNum, "Visible = " & sec.Visible
        Print #intFileNum, "CanGrow = " & sec.CanGrow
        Print #intFileNum, "CanShrink = " & sec.CanShrink
        Print #intFileNum, "ForceNewPage = " & GetForceNewPageName(sec.forceNewPage)
        Print #intFileNum, "NewRowOrCol = " & GetNewRowOrColName(sec.newRowOrCol)
        Print #intFileNum, "KeepTogether = " & sec.keepTogether
        Print #intFileNum, "RepeatSection = " & sec.RepeatSection
        Print #intFileNum, "BackColor = " & sec.BackColor & " (RGB: " & ColorToRGB(sec.BackColor) & ")"
        Print #intFileNum, "SpecialEffect = " & sec.specialEffect
        Print #intFileNum, ""
        
        i = i + 1
    Loop
    
    On Error GoTo 0
End Sub

Private Sub WriteReportControls(rpt As Report)
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "ЭЛЕМЕНТЫ УПРАВЛЕНИЯ (ВСЕГО: " & rpt.Controls.count & ")"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
    
    Dim ctl As Control
    Dim i As Integer
    
    i = 1
    For Each ctl In rpt.Controls
        Print #intFileNum, "---------------------------------------------------------------------"
        Print #intFileNum, "[Control #" & i & "]"
        Print #intFileNum, "---------------------------------------------------------------------"
        
        WriteControlBasicProperties ctl
        WriteControlLayout ctl
        WriteControlTextFormatting ctl
        WriteControlDataFormatting ctl
        WriteControlBorders ctl
        WriteControlSpecificProperties ctl
        
        Print #intFileNum, ""
        i = i + 1
    Next ctl
End Sub

Private Sub WriteControlBasicProperties(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== ОСНОВНЫЕ СВОЙСТВА =="
    Print #intFileNum, "Name = " & ctl.name
    Print #intFileNum, "Type = " & GetControlTypeName(ctl.ControlType) & " (" & ctl.ControlType & ")"
    Print #intFileNum, "Section = " & GetSectionName(ctl.Section)
    Print #intFileNum, "ControlSource = " & ctl.ControlSource
    Print #intFileNum, "Tag = " & ctl.Tag
    Print #intFileNum, "StatusBarText = " & ctl.StatusBarText
    
    On Error GoTo 0
End Sub

Private Sub WriteControlLayout(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== ПОЗИЦИЯ И РАЗМЕРЫ =="
    Print #intFileNum, "Left = " & ctl.Left & " twips (" & TwipsToMM(ctl.Left) & " mm)"
    Print #intFileNum, "Top = " & ctl.Top & " twips (" & TwipsToMM(ctl.Top) & " mm)"
    Print #intFileNum, "Width = " & ctl.Width & " twips (" & TwipsToMM(ctl.Width) & " mm)"
    Print #intFileNum, "Height = " & ctl.Height & " twips (" & TwipsToMM(ctl.Height) & " mm)"
    
    Print #intFileNum, "  [JasperReports units - points]"
    Print #intFileNum, "  x = " & TwipsToPoints(ctl.Left) & " pt"
    Print #intFileNum, "  y = " & TwipsToPoints(ctl.Top) & " pt"
    Print #intFileNum, "  width = " & TwipsToPoints(ctl.Width) & " pt"
    Print #intFileNum, "  height = " & TwipsToPoints(ctl.Height) & " pt"
    
    On Error GoTo 0
End Sub

Private Sub WriteControlTextFormatting(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== ФОРМАТИРОВАНИЕ ТЕКСТА =="
    Print #intFileNum, "FontName = " & ctl.FontName
    Print #intFileNum, "FontSize = " & ctl.FontSize
    Print #intFileNum, "FontWeight = " & ctl.FontWeight & " (Bold: " & ctl.FontBold & ")"
    Print #intFileNum, "FontItalic = " & ctl.FontItalic
    Print #intFileNum, "FontUnderline = " & ctl.FontUnderline
    Print #intFileNum, "TextAlign = " & GetTextAlignName(ctl.textAlign) & " (" & ctl.textAlign & ")"
    Print #intFileNum, "ForeColor = " & ctl.ForeColor & " (RGB: " & ColorToRGB(ctl.ForeColor) & ")"
    Print #intFileNum, "BackColor = " & ctl.BackColor & " (RGB: " & ColorToRGB(ctl.BackColor) & ")"
    Print #intFileNum, "BackStyle = " & GetBackStyleName(ctl.backStyle) & " (" & ctl.backStyle & ")"
    
    On Error GoTo 0
End Sub

Private Sub WriteControlDataFormatting(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== ФОРМАТИРОВАНИЕ ДАННЫХ =="
    Print #intFileNum, "Format = " & ctl.Format
    Print #intFileNum, "DecimalPlaces = " & ctl.DecimalPlaces
    Print #intFileNum, "InputMask = " & ctl.InputMask
    Print #intFileNum, "Caption = " & ctl.Caption
    Print #intFileNum, "DefaultValue = " & ctl.DefaultValue
    
    On Error GoTo 0
End Sub

Private Sub WriteControlBorders(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== ГРАНИЦЫ И ВИЗУАЛЬНЫЕ ЭФФЕКТЫ =="
    Print #intFileNum, "Visible = " & ctl.Visible
    Print #intFileNum, "DisplayWhen = " & GetDisplayWhenName(ctl.displayWhen) & " (" & ctl.displayWhen & ")"
    Print #intFileNum, "BorderStyle = " & GetBorderStyleName(ctl.borderStyle) & " (" & ctl.borderStyle & ")"
    Print #intFileNum, "BorderWidth = " & ctl.BorderWidth
    Print #intFileNum, "BorderColor = " & ctl.BorderColor & " (RGB: " & ColorToRGB(ctl.BorderColor) & ")"
    Print #intFileNum, "SpecialEffect = " & GetSpecialEffectName(ctl.specialEffect) & " (" & ctl.specialEffect & ")"
    
    On Error GoTo 0
End Sub

Private Sub WriteControlSpecificProperties(ctl As Control)
    On Error Resume Next
    
    Print #intFileNum, ""
    Print #intFileNum, "== Специфические свойства =="
    
    Select Case ctl.ControlType
        Case 109  ' TextBox
            Print #intFileNum, "Type: TextBox"
            Print #intFileNum, "RunningSum = " & GetRunningSumName(ctl.runningSum) & " (" & ctl.runningSum & ")"
            Print #intFileNum, "HideDuplicates = " & ctl.HideDuplicates
            Print #intFileNum, "CanGrow = " & ctl.CanGrow
            Print #intFileNum, "CanShrink = " & ctl.CanShrink
            Print #intFileNum, "IsHyperlink = " & ctl.IsHyperlink
            
        Case 100  ' Label
            Print #intFileNum, "Type: Label"
            Print #intFileNum, "Caption = " & ctl.Caption
            Print #intFileNum, "HyperlinkAddress = " & ctl.HyperlinkAddress
            Print #intFileNum, "HyperlinkSubAddress = " & ctl.HyperlinkSubAddress
            
        Case 106  ' Line
            Print #intFileNum, "Type: Line"
            Print #intFileNum, "LineSlant = " & IIf(ctl.LineSlant, "\\", "/")
            Print #intFileNum, "BorderWidth = " & ctl.BorderWidth
            Print #intFileNum, "BorderColor = " & ctl.BorderColor
            
        Case 102  ' Rectangle
            Print #intFileNum, "Type: Rectangle"
            Print #intFileNum, "BackStyle = " & ctl.backStyle
            Print #intFileNum, "SpecialEffect = " & ctl.specialEffect
            
        Case 103  ' Image
            Print #intFileNum, "Type: Image"
            Print #intFileNum, "Picture = " & ctl.Picture
            Print #intFileNum, "PictureType = " & GetPictureTypeName(ctl.pictureType) & " (" & ctl.pictureType & ")"
            Print #intFileNum, "SizeMode = " & GetSizeModeName(ctl.sizeMode) & " (" & ctl.sizeMode & ")"
            Print #intFileNum, "PictureAlignment = " & ctl.PictureAlignment
            
        Case 112  ' Subreport (acSubform/acSubreport)
            Print #intFileNum, "Type: Subreport"
            Print #intFileNum, "SourceObject = " & ctl.SourceObject
            Print #intFileNum, "LinkChildFields = " & ctl.LinkChildFields
            Print #intFileNum, "LinkMasterFields = " & ctl.LinkMasterFields
            Print #intFileNum, "CanGrow = " & ctl.CanGrow
            Print #intFileNum, "CanShrink = " & ctl.CanShrink
            
        Case 104, 122, 105  ' CheckBox, ToggleButton, OptionButton
            Print #intFileNum, "Type: " & GetControlTypeName(ctl.ControlType)
            Print #intFileNum, "DefaultValue = " & ctl.DefaultValue
            Print #intFileNum, "TripleState = " & ctl.TripleState
            
        Case 111, 110  ' ComboBox, ListBox
            Print #intFileNum, "Type: " & GetControlTypeName(ctl.ControlType)
            Print #intFileNum, "RowSource = " & ctl.RowSource
            Print #intFileNum, "RowSourceType = " & ctl.RowSourceType
            Print #intFileNum, "BoundColumn = " & ctl.BoundColumn
            Print #intFileNum, "ColumnCount = " & ctl.ColumnCount
            Print #intFileNum, "ColumnWidths = " & ctl.ColumnWidths
            
        Case Else
            Print #intFileNum, "Type: Other (" & ctl.ControlType & ")"
    End Select
    
    On Error GoTo 0
End Sub

Private Sub WriteReportVBACode(rpt As Report)
    On Error Resume Next
    
    Print #intFileNum, "====================================================================="
    Print #intFileNum, "VBA КОД ОТЧЁТА"
    Print #intFileNum, "====================================================================="
    Print #intFileNum, ""
    
    If rpt.HasModule Then
        Print #intFileNum, "Отчёт содержит VBA модуль с программным кодом."
        Print #intFileNum, "Для экспорта VBA кода используйте Visual Basic Editor (Alt+F11)."
        Print #intFileNum, ""
        Print #intFileNum, "ПРИМЕЧАНИЕ: VBA код требует ручного переноса в JasperReports."
    Else
        Print #intFileNum, "VBA модуль отсутствует."
    End If
    Print #intFileNum, ""
    
    On Error GoTo 0
End Sub

' =====================================================================
' ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
' =====================================================================

Private Function ReportExists(strReportName As String) As Boolean
    On Error Resume Next
    Dim obj As AccessObject
    
    For Each obj In CurrentProject.AllReports
        If obj.name = strReportName Then
            ReportExists = True
            Exit Function
        End If
    Next obj
    
    ReportExists = False
End Function

Private Function TwipsToMM(twips As Long) As Double
    TwipsToMM = Round(twips * 25.4 / 1440, 2)
End Function

Private Function TwipsToPoints(twips As Long) As Long
    TwipsToPoints = CLng(twips * 72 / 1440)
End Function

Private Function ColorToRGB(lngColor As Long) As String
    Dim r As Integer, g As Integer, b As Integer
    
    r = lngColor And &HFF
    g = (lngColor \ &H100) And &HFF
    b = (lngColor \ &H10000) And &HFF
    
    ColorToRGB = "R=" & r & ", G=" & g & ", B=" & b
End Function

Private Function GetControlTypeName(ctlType As Long) As String
    ' Используем Long вместо AcControlType для совместимости
    Select Case ctlType
        Case 100: GetControlTypeName = "Label"
        Case 109: GetControlTypeName = "TextBox"
        Case 106: GetControlTypeName = "Line"
        Case 102: GetControlTypeName = "Rectangle"
        Case 103: GetControlTypeName = "Image"
        Case 112: GetControlTypeName = "Subreport"
        Case 104: GetControlTypeName = "CheckBox"
        Case 111: GetControlTypeName = "ComboBox"
        Case 110: GetControlTypeName = "ListBox"
        Case 122: GetControlTypeName = "ToggleButton"
        Case 105: GetControlTypeName = "OptionButton"
        Case 108: GetControlTypeName = "OptionGroup"
        Case 114: GetControlTypeName = "BoundObjectFrame"
        Case 118: GetControlTypeName = "PageBreak"
        Case 104: GetControlTypeName = "CommandButton"
        Case 124: GetControlTypeName = "TabControl"
        Case 125: GetControlTypeName = "Page"
        Case Else: GetControlTypeName = "Unknown_" & ctlType
    End Select
End Function

Private Function GetSectionName(secName As Variant) As String
    Select Case secName
        Case acDetail: GetSectionName = "Detail"
        Case acHeader: GetSectionName = "Report Header"
        Case acFooter: GetSectionName = "Report Footer"
        Case acPageHeader: GetSectionName = "Page Header"
        Case acPageFooter: GetSectionName = "Page Footer"
        Case acGroupLevel1Header: GetSectionName = "Group Header 1"
        Case acGroupLevel1Footer: GetSectionName = "Group Footer 1"
        Case acGroupLevel2Header: GetSectionName = "Group Header 2"
        Case acGroupLevel2Footer: GetSectionName = "Group Footer 2"
        Case Else
            If IsNumeric(secName) Then
                GetSectionName = "Section_" & secName
            Else
                GetSectionName = CStr(secName)
            End If
    End Select
End Function

Private Function GetGroupOnName(groupOn As Integer) As String
    Select Case groupOn
        Case 0: GetGroupOnName = "Each Value"
        Case 1: GetGroupOnName = "Prefix Characters"
        Case 2: GetGroupOnName = "Year"
        Case 3: GetGroupOnName = "Quarter"
        Case 4: GetGroupOnName = "Month"
        Case 5: GetGroupOnName = "Week"
        Case 6: GetGroupOnName = "Day"
        Case 7: GetGroupOnName = "Hour"
        Case 8: GetGroupOnName = "Minute"
        Case 9: GetGroupOnName = "Interval"
        Case Else: GetGroupOnName = "Unknown_" & groupOn
    End Select
End Function

Private Function GetKeepTogetherName(keepTogether As Integer) As String
    Select Case keepTogether
        Case 0: GetKeepTogetherName = "No"
        Case 1: GetKeepTogetherName = "Whole Group"
        Case 2: GetKeepTogetherName = "With First Detail"
        Case Else: GetKeepTogetherName = "Unknown_" & keepTogether
    End Select
End Function

Private Function GetForceNewPageName(forceNewPage As Integer) As String
    Select Case forceNewPage
        Case 0: GetForceNewPageName = "None"
        Case 1: GetForceNewPageName = "Before Section"
        Case 2: GetForceNewPageName = "After Section"
        Case 3: GetForceNewPageName = "Before & After"
        Case Else: GetForceNewPageName = "Unknown_" & forceNewPage
    End Select
End Function

Private Function GetNewRowOrColName(newRowOrCol As Integer) As String
    Select Case newRowOrCol
        Case 0: GetNewRowOrColName = "None"
        Case 1: GetNewRowOrColName = "Before Section"
        Case 2: GetNewRowOrColName = "After Section"
        Case 3: GetNewRowOrColName = "Before & After"
        Case Else: GetNewRowOrColName = "Unknown_" & newRowOrCol
    End Select
End Function

Private Function GetTextAlignName(textAlign As Integer) As String
    Select Case textAlign
        Case 1: GetTextAlignName = "General (default)"
        Case 2: GetTextAlignName = "Left"
        Case 3: GetTextAlignName = "Center"
        Case 4: GetTextAlignName = "Right"
        Case 5: GetTextAlignName = "Distribute"
        Case Else: GetTextAlignName = "Unknown_" & textAlign
    End Select
End Function

Private Function GetBackStyleName(backStyle As Integer) As String
    Select Case backStyle
        Case 0: GetBackStyleName = "Transparent"
        Case 1: GetBackStyleName = "Normal (Opaque)"
        Case Else: GetBackStyleName = "Unknown_" & backStyle
    End Select
End Function

Private Function GetBorderStyleName(borderStyle As Integer) As String
    Select Case borderStyle
        Case 0: GetBorderStyleName = "Transparent"
        Case 1: GetBorderStyleName = "Solid"
        Case 2: GetBorderStyleName = "Dashes"
        Case 3: GetBorderStyleName = "Short Dashes"
        Case 4: GetBorderStyleName = "Dots"
        Case 5: GetBorderStyleName = "Sparse Dots"
        Case 6: GetBorderStyleName = "Dash Dot"
        Case 7: GetBorderStyleName = "Dash Dot Dot"
        Case Else: GetBorderStyleName = "Unknown_" & borderStyle
    End Select
End Function

Private Function GetSpecialEffectName(specialEffect As Integer) As String
    Select Case specialEffect
        Case 0: GetSpecialEffectName = "Flat"
        Case 1: GetSpecialEffectName = "Raised"
        Case 2: GetSpecialEffectName = "Sunken"
        Case 3: GetSpecialEffectName = "Etched"
        Case 4: GetSpecialEffectName = "Shadowed"
        Case 5: GetSpecialEffectName = "Chiseled"
        Case Else: GetSpecialEffectName = "Unknown_" & specialEffect
    End Select
End Function

Private Function GetDisplayWhenName(displayWhen As Integer) As String
    Select Case displayWhen
        Case 0: GetDisplayWhenName = "Always"
        Case 1: GetDisplayWhenName = "Print Only"
        Case 2: GetDisplayWhenName = "Screen Only"
        Case Else: GetDisplayWhenName = "Unknown_" & displayWhen
    End Select
End Function

Private Function GetRunningSumName(runningSum As Integer) As String
    Select Case runningSum
        Case 0: GetRunningSumName = "No"
        Case 1: GetRunningSumName = "Over Group"
        Case 2: GetRunningSumName = "Over All"
        Case Else: GetRunningSumName = "Unknown_" & runningSum
    End Select
End Function

Private Function GetPictureTypeName(pictureType As Integer) As String
    Select Case pictureType
        Case 0: GetPictureTypeName = "Embedded"
        Case 1: GetPictureTypeName = "Linked"
        Case Else: GetPictureTypeName = "Unknown_" & pictureType
    End Select
End Function

Private Function GetSizeModeName(sizeMode As Integer) As String
    Select Case sizeMode
        Case 0: GetSizeModeName = "Clip"
        Case 1: GetSizeModeName = "Stretch"
        Case 2: GetSizeModeName = "Zoom"
        Case Else: GetSizeModeName = "Unknown_" & sizeMode
    End Select
End Function

' =====================================================================
' ДОПОЛНИТЕЛЬНАЯ ПРОЦЕДУРА: ЭКСПОРТ ВСЕХ ОТЧЁТОВ
' =====================================================================
Sub ExportAllReportsStructure()
    On Error GoTo ErrorHandler
    
    Dim obj As AccessObject
    Dim strOutputPath As String
    Dim intCount As Integer
    Dim strExportFolder As String
    
    strOutputPath = CurrentProject.path & "\"
    strExportFolder = strOutputPath & "Reports_Export_" & Format(Now(), "yyyymmdd_hhnnss") & "\"
    MkDir strExportFolder
    
    intCount = 0
    
    For Each obj In CurrentProject.AllReports
        DoCmd.Echo True, "Экспорт отчёта: " & obj.name & " (" & (intCount + 1) & " из " & CurrentProject.AllReports.count & ")"
        
        ExportSingleReport obj.name, strExportFolder
        
        intCount = intCount + 1
    Next obj
    
    DoCmd.Echo True
    
    MsgBox "Экспорт завершён!" & vbCrLf & vbCrLf & _
           "Обработано отчётов: " & intCount & vbCrLf & _
           "Папка: " & strExportFolder, vbInformation, "Массовый экспорт"
    
    Exit Sub

ErrorHandler:
    DoCmd.Echo True
    MsgBox "Ошибка при массовом экспорте отчётов:" & vbCrLf & vbCrLf & _
           "Описание: " & Err.Description, vbCritical, "Ошибка"
End Sub

Private Sub ExportSingleReport(strReportName As String, strOutputFolder As String)
    On Error Resume Next
    
    Dim rpt As Report
    Dim strFilePath As String
    
    strFilePath = strOutputFolder & strReportName & "_structure.txt"
    
    DoCmd.OpenReport strReportName, acViewDesign
    Set rpt = Reports(strReportName)
    
    intFileNum = FreeFile
    Open strFilePath For Output As intFileNum
    
    WriteHeader strReportName
    WriteReportProperties rpt
    WriteReportGroups rpt
    WriteReportSections rpt
    WriteReportControls rpt
    WriteReportVBACode rpt
    
    Close #intFileNum
    DoCmd.Close acReport, strReportName, acSaveNo
End Sub

' =====================================================================
' КОНЕЦ СКРИПТА
' =====================================================================



