VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ra_aAllAgents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' класс *Ревизия отчётов агента. Проверка файла Отчётов всех агентов*

' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' !!! не нужно их писать в других местах, это приведет к ошибке. 07.07.2022
' ключ объекта *Ревизия отчётов агента. Проверка файла Отчётов всех агентов*
Private mlngRa_aAllAgentsKey As Long
' здесь, если -1 , то не реинициализировалась. Если 0, то реинициализировалась и объект не был найден

' вышестоящий класс *Ревизия отчётов агента*
Private mobjParent As ra_a

' № пп
Private mlngAf_num As Long
' файл, имя
Private mstrAf_name As String
' файл, директория
Private mlngAf_dir As Long
' тип файла
Private mlngAf_type As Long
' организация отправитель
Private mlngRa_org_sender As Long
' выполнять?
Private mblnAf_execute As Boolean
' обновлять по источнику?
Private mblnAf_source As Boolean
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

' геттер свойства ключ объекта *Ревизия отчётов агента. Проверка файла Отчётов всех агентов*
Public Property Get Ra_aAllAgentsKey() As Long
    Ra_aAllAgentsKey = mlngRa_aAllAgentsKey
End Property

' сеттер свойства вышестоящий класс *Ревизия отчётов агента*
Public Property Set parent(ByRef objParent As ra_a)
    If mobjParent Is Nothing Then
        Set mobjParent = objParent
    End If
End Property

' обработка встроенного события инициализации
Private Sub Class_Initialize()
    ' инициализируем объект с нулевым ключём. В таком виде он не имеет смысла.
    ' Требуется реинициализация.
    mlngRa_aAllAgentsKey = -1
End Sub

' реинициализируем объект *Ревизия отчётов агента. Проверка файла Отчётов всех агентов* по известному ключу такого объекта. 06.07.2022 **************
Public Sub riRa_aAllAgentReadKey(ByVal Ra_aAllAgentKey As Long, ByRef boResult As Boolean, db As DAO.Database)

    Dim rsRa_aAllAgent As DAO.Recordset, strSql As String
    
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект *Ревизия отчётов агента - проверка файла Отчётов всех агентов* по известному ключу такого объекта*."
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' объект не реинициализировался?
    If mlngRa_aAllAgentsKey = -1 Then
        ' да, объект не реинициализировался
        ' отыскиваем в БД *проверку файла Отчётов всех агентов* по известному ключу
        strSql = _
        "SELECT f.af_key, f.af_num, f.af_name, f.af_dir, f.af_type, f.ra_org_sender, f.af_execute, f.af_source " _
        & "FROM ra_f AS f " _
        & "WHERE (((f.af_key)=" & Ra_aAllAgentKey & ") AND ((f.af_type)=5))"
    
        Set rsRa_aAllAgent = db.OpenRecordset(strSql, dbOpenSnapshot)
    
        ' имеются ли записи с указанным ключём?
        With rsRa_aAllAgent
            If .RecordCount = 1 Then
                ' да, записи с указанным ключём имеются
                mlngRa_aAllAgentsKey = Ra_aAllAgentKey
                
                .MoveFirst
                    mlngAf_num = !af_num
                    mstrAf_name = !af_name
                    mlngAf_dir = !af_dir
                    mlngAf_type = !af_type
                    mlngRa_org_sender = !ra_org_sender
                    mblnAf_execute = !af_execute
                    mblnAf_source = !af_source
                
                boResult = True
                Else
                ' нет, записи с указанным ключём отсутствуют
                boResult = False
            End If
        End With
    End If

    ' закрываем набор записей
    rsRa_aAllAgent.Close: Set rsRa_aAllAgent = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Sub
' реинициализируем объект *Ревизия отчётов агента. Проверка файла Отчётов всех агентов* по известному ключу такого объекта. 06.07.2022. Окончание ***

' работаем с листом Отчётов всех агентов. 05.07.2022 ************************************************************************************************
Public Sub Audit( _
    xlS As Excel.Worksheet, db As DAO.Database, xlA As Object _
    )
    ' здесь:
    ' xlS - лист, с которым работаем, AddRA - потребность в корректировке БД, fff - объект отображающий записи о ходе ревизии
    ' db - база данных, открытая,
    ' AdtKey - идентификатор текущей ревизии, yyyy - год текущей ревизии, xlA - приложение эксель
    ' -------------------------------------------------------------------------------------------------------------------------------------
    
    Dim c As Range, PrDocNum As String, PrDocDate As Date, invNum As String, invDate As Date, CnNum As String
    
    Dim rstCn_PrDocImp As DAO.Recordset
    Dim qdFindSv As DAO.QueryDef, StringFindSv As String, rsFindSv As DAO.Recordset ' для поиска в SQL сервере
    Dim cstapKey As Long
    Dim strFFF As String ' для формирования дополнительных фрагментов текста и последующего дополнения их к fff
    Dim intFind As Integer, intFind2 As Integer, strFind As String, strFind2 As String ' для поисков
    Dim qd As DAO.QueryDef, strSql As String, Ra_aNew As ra_a
    
    Dim offsetCnpdDate As Integer, startColumn As Integer, offsetFindet As Integer
    
    Dim ra_RA As Range ' диапазон отчётов до нижней ячейки
    ' данные ячейки номера отчёта агента
    Dim cellRaNumFinded As Boolean, cellRaNum As Range, cellRaNumColumn As Integer
    ' данные ячейки даты отчёта агента
    Dim cellRaDateFinded As Boolean, cellRaDate As Range, cellRaDateOffset As Integer
    ' данные ячейки номеров строек
    Dim cellCstAgPnFinded As Boolean, cellCstAgPn As Range, cellCstAgPnOffset As Integer
    ' данные ячейки признака
    Dim cellSignFinded As Boolean, cellSign As Range, cellSignOffset As Integer
    ' данные ячейки "Всего"
    Dim cellTotalFinded As Boolean, cellTotal As Range, cellTotalOffset As Integer
    ' данные ячейки "СМР"
    Dim cellWorkFinded As Boolean, cellWork As Range, cellWorkOffset As Integer
    ' данные ячейки "Оборудование"
    Dim cellEquipFinded As Boolean, cellEquip As Range, cellEquipOffset As Integer
    ' данные ячейки "Прочее"
    Dim cellOthersFinded As Boolean, cellOthers As Range, cellOthersOffset As Integer
    ' данные ячейки "Поступило"
    Dim cellArrivedFinded As Boolean, cellArrived As Range, cellArrivedOffset As Integer
    ' данные ячейки "Поступило, дата"
    Dim cellArrivedDateFinded As Boolean, cellArrivedDate As Range, cellArrivedDateOffset As Integer
    ' данные ячейки "Поступило, дата, факт"
    Dim cellArrivedDateFactFinded As Boolean, cellArrivedDateFact As Range, cellArrivedDateFactOffset As Integer
    ' данные ячейки "Направлен"
    Dim cellSentFinded As Boolean, cellSent As Range, cellSentOffset As Integer
    ' данные ячейки "Направлен, дата"
    Dim cellSentDateFinded As Boolean, cellSentDate As Range, cellSentDateOffset As Integer
    ' данные ячейки "Возвращен"
    Dim cellReturnedFinded As Boolean, cellReturned As Range, cellReturnedOffset As Integer
    ' данные ячейки "Возвращен, дата"
    Dim cellReturnedDateFinded As Boolean, cellReturnedDate As Range, cellReturnedDateOffset As Integer
    ' данные ячейки "Возвращен, причина"
    Dim cellReturnedReasonFinded As Boolean, cellReturnedReason As Range, cellReturnedReasonOffset As Integer
    ' данные ячейки "Отдел Управления"
    Dim cellUnitFinded As Boolean, cellUnit As Range, cellUnitOffset As Integer
    ' данные ячейки "Кол-во листов ОА"
    Dim cellRaSheetsNumberFinded As Boolean, cellRaSheetsNumber As Range, cellRaSheetsNumberOffset As Integer
    ' данные ячейки "Кол-во листов ПУД"
    Dim cellTitleDocSheetsNumberFinded As Boolean, cellTitleDocSheetsNumber As Range, cellTitleDocSheetsNumberOffset As Integer
    ' данные ячейки "План кол-во"
    Dim cellPlanNumberFinded As Boolean, cellPlanNumber As Range, cellPlanNumberOffset As Integer
    ' данные ячейки "План дата"
    Dim cellPlanDateFinded As Boolean, cellPlanDate As Range, cellPlanDateOffset As Integer
    ' данные ячейки "Признак проверки ОА"
    Dim cellRaSignOfTestFinded As Boolean, cellRaSignOfTest As Range, cellRaSignOfTestOffset As Integer
    ' данные ячейки "Сумма переданных ОА"
    Dim cellRaSendedSumFinded As Boolean, cellRaSendedSum As Range, cellRaSendedSumOffset As Integer
    ' данные ячейки "Cумма возвращенных ОА"
    Dim cellRaReturnedSumFinded As Boolean, cellRaReturnedSum As Range, cellRaReturnedSumOffset As Integer
    
    ' данные ячейки "Агент"
    Dim cellSenderFinded As Boolean, cellSender As Range, cellSenderOffset As Integer
    ' данные ячейки "Наименование стройки"
    Dim cellCstNameFinded As Boolean, cellCstName As Range, cellCstNameOffset As Integer
    
    Dim str As String
    
    Dim fff As Variant ' текст в ТекстБоксе
    
    ' для второй части процедуры
    Dim rsRaAll As DAO.Recordset ' все обнаруженные отчёты
    Dim rsRaNew As DAO.Recordset ' отчёты не обнаруженные в БД
    Dim rsRaErr As DAO.Recordset ' отчёты имеющие несоответствия в данных
    Dim rsRaExr As DAO.Recordset ' отчёты имеющиеся в БД, но отсутствующие в источнике
    Dim raRaExr As ra, rcRcExr As rc
    Dim iii As Integer
    
    Const cstrTitle As String _
        = "Процедура *Работаем с листом Отчётов всех агентов*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' Здесь будем делать следующее:
    ' 1. Обновляем промежуточную таблицу если нужно
    ' ну и так далее...
    
    ' ===============================================================================================================================================
    ' ===============================================================================================================================================
    ' 1. Обновляем (или не обновляем) промежуточную таблицу по источнику данных =====================================================================
    ' ===============================================================================================================================================
    ' нужно ли обновлять промежуточную таблицу по источнику данных?
    If mblnAf_source Then
        ' да, обновлять промежуточную таблицу по источнику данных нужно
        
        ' снимаем фильтры листа, если есть
        If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
            xlS.ShowAllData
        End If
        
        ' очищаем таблицу сводных значений
        strSql = "DELETE * FROM ra_ImpNew"
        Set qd = db.CreateQueryDef("", strSql)
        qd.Execute dbFailOnError
        qd.Close
        Set qd = Nothing

        
        ' проверяем наличие всех необходимых колонок
        ' отыскиваем колонку номеров отчётов
        cellRaNumFinded = CellFind(xlS:=xlS, findStr:="№ ОА", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
            findedCell:=cellRaNum, findedColumn:=cellRaNumColumn)
    
        ' найдена ли ячейка номера отчёта?
        If cellRaNumFinded Then
            ' да, ячейка номера отчёта найдена
            ' другие необходимые колонки и их смещения
            ' отыскиваем колонку даты отчёта агента
            cellRaDateFinded = CellFind(xlS:=xlS, findStr:="Дата ОА", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellRaDate, startCellColumn:=cellRaNum.Column, findedOffset:=cellRaDateOffset)
            ' отыскиваем колонку номеров строек
            cellCstAgPnFinded = CellFind(xlS:=xlS, findStr:="Код стройки", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellCstAgPn, startCellColumn:=cellRaNum.Column, findedOffset:=cellCstAgPnOffset)
            ' отыскиваем колонку признака
            cellSignFinded = CellFind(xlS:=xlS, findStr:="Признак", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellSign, startCellColumn:=cellRaNum.Column, findedOffset:=cellSignOffset)
            ' отыскиваем колонку "Всего"
            cellTotalFinded = CellFind(xlS:=xlS, findStr:="Всего с НДС", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellTotal, startCellColumn:=cellRaNum.Column, findedOffset:=cellTotalOffset)
            ' отыскиваем колонку "СМР"
            cellWorkFinded = CellFind(xlS:=xlS, findStr:="СМР", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellWork, startCellColumn:=cellRaNum.Column, findedOffset:=cellWorkOffset)
            ' отыскиваем колонку "Оборудование"
            cellEquipFinded = CellFind(xlS:=xlS, findStr:="Оборудование", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellEquip, startCellColumn:=cellRaNum.Column, findedOffset:=cellEquipOffset)
            ' отыскиваем колонку "Прочее"
            cellOthersFinded = CellFind(xlS:=xlS, findStr:="Прочие", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellOthers, startCellColumn:=cellRaNum.Column, findedOffset:=cellOthersOffset)
            ' отыскиваем колонку "Поступило"
            ' оказалось, что новая строка по Enter в ячейке - это символ "перевод строки", Chr(10)? vbLf
            cellArrivedFinded = CellFind(xlS:=xlS, findStr:="Поступило " & vbLf & "(№ письма)", findAtXlLookAt:=xlWhole, _
                findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellArrived, startCellColumn:=cellRaNum.Column, findedOffset:=cellArrivedOffset)
            ' отыскиваем колонку "Поступило, дата"
            cellArrivedDateFinded = CellFind(xlS:=xlS, findStr:="Поступило (Дата письма)", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellArrivedDate, startCellColumn:=cellRaNum.Column, findedOffset:=cellArrivedDateOffset)
            ' отыскиваем колонку "Поступило, дата, факт"
            cellArrivedDateFactFinded = CellFind(xlS:=xlS, findStr:="Поступило (Фактическая дата)", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellArrivedDateFact, startCellColumn:=cellRaNum.Column, findedOffset:=cellArrivedDateFactOffset)
            ' отыскиваем колонку "Направлен"
            cellSentFinded = CellFind(xlS:=xlS, findStr:="Направлен в Бухгалтерию (№ СЗ)", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellSent, startCellColumn:=cellRaNum.Column, findedOffset:=cellSentOffset)
            ' отыскиваем колонку "Направлен, дата"
            cellSentDateFinded = CellFind(xlS:=xlS, findStr:="Направлен в Бухгалтерию (дата СЗ)", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellSentDate, startCellColumn:=cellRaNum.Column, findedOffset:=cellSentDateOffset)
            ' отыскиваем колонку "Возвращен"
            cellReturnedFinded = CellFind(xlS:=xlS, findStr:="Возвращен на доработку (№ письма) ", findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellReturned, startCellColumn:=cellRaNum.Column, findedOffset:=cellReturnedOffset)
            ' отыскиваем колонку "Возвращен"
            cellReturnedDateFinded = CellFind(xlS:=xlS, findStr:="Возвращен на доработку (дата письма)", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellReturnedDate, startCellColumn:=cellRaNum.Column, findedOffset:=cellReturnedDateOffset)
            ' отыскиваем колонку "Возвращен, причина"
            cellReturnedReasonFinded = CellFind(xlS:=xlS, findStr:="Причина возврата", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellReturnedReason, startCellColumn:=cellRaNum.Column, findedOffset:=cellReturnedReasonOffset)
            ' отыскиваем колонку "Отдел Управления"
            cellUnitFinded = CellFind(xlS:=xlS, findStr:="Отдел Управления", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellUnit, startCellColumn:=cellRaNum.Column, findedOffset:=cellUnitOffset)
            ' отыскиваем колонку "Кол-во листов ОА"
            cellRaSheetsNumberFinded = CellFind(xlS:=xlS, findStr:="Кол-во листов ОА", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellRaSheetsNumber, startCellColumn:=cellRaNum.Column, findedOffset:=cellRaSheetsNumberOffset)
            ' отыскиваем колонку "Кол-во листов ПУД"
            cellTitleDocSheetsNumberFinded = CellFind(xlS:=xlS, findStr:="Кол-во листов ПУД", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellTitleDocSheetsNumber, startCellColumn:=cellRaNum.Column, findedOffset:=cellTitleDocSheetsNumberOffset)
            ' отыскиваем колонку "План кол-во"
            cellPlanNumberFinded = CellFind(xlS:=xlS, findStr:="План кол-во", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellPlanNumber, startCellColumn:=cellRaNum.Column, findedOffset:=cellPlanNumberOffset)
            ' отыскиваем колонку "План дата"
            cellPlanDateFinded = CellFind(xlS:=xlS, findStr:="План дата", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellPlanDate, startCellColumn:=cellRaNum.Column, findedOffset:=cellPlanDateOffset)
            ' отыскиваем колонку "Признак проверки ОА"
            cellRaSignOfTestFinded = CellFind(xlS:=xlS, findStr:="Признак проверки ОА", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellRaSignOfTest, startCellColumn:=cellRaNum.Column, findedOffset:=cellRaSignOfTestOffset)
            ' отыскиваем колонку "Сумма переданных ОА"
            cellRaSendedSumFinded = CellFind(xlS:=xlS, findStr:="Сумма переданных ОА", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellRaSendedSum, startCellColumn:=cellRaNum.Column, findedOffset:=cellRaSendedSumOffset)
            ' отыскиваем колонку "Cумма возвращенных ОА"
            cellRaReturnedSumFinded = CellFind(xlS:=xlS, findStr:="Cумма возвращенных ОА", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellRaReturnedSum, startCellColumn:=cellRaNum.Column, findedOffset:=cellRaReturnedSumOffset)
            ' отыскиваем колонку "Агент"
            cellSenderFinded = CellFind(xlS:=xlS, findStr:="Агент", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellSender, startCellColumn:=cellRaNum.Column, findedOffset:=cellSenderOffset)
            ' отыскиваем колонку "Наименование стройки"
            cellCstNameFinded = CellFind(xlS:=xlS, findStr:="Наименование стройки", _
                findAtXlLookAt:=xlWhole, findTextBox:=mobjParent.obgRa_aResult, _
                findedCell:=cellCstName, startCellColumn:=cellRaNum.Column, findedOffset:=cellCstNameOffset)
        End If
    
        ' найдена ли ячейка номеров отчёта и смещения?
        If cellRaNumFinded And cellRaDateFinded And cellCstAgPnFinded And cellSignFinded And _
            cellTotalFinded And cellWorkFinded And cellEquipFinded And cellOthersFinded And _
            cellArrivedFinded And cellArrivedDateFinded And cellArrivedDateFactFinded And _
            cellSentFinded And cellSentDateFinded And cellReturnedFinded And cellReturnedDateFinded And cellReturnedReasonFinded And _
            cellUnitFinded And cellRaSheetsNumberFinded And cellTitleDocSheetsNumberFinded And _
            cellPlanNumberFinded And cellPlanDateFinded And cellRaSignOfTestFinded And _
            cellRaSendedSumFinded And cellRaReturnedSumFinded And cellSenderFinded And cellCstNameFinded _
            Then
            ' да, ячейка номеров отчёта и смещения найдены
            ' определяем диапазон отчётов до нижней ячейки
            Set ra_RA = xlS.Range( _
                xlS.Cells(cellRaNum.Offset(1, 0).Row, cellRaNum.Column), _
                xlS.Cells( _
                    xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                    xlS.Cells(cellRaNum.Offset(1, 0).Row, cellRaNum.Column).Column _
                    ) _
                )
                
            ' имеется ли диапазон отчётов?
            If Not ra_RA Is Nothing Then
                ' да, диапазон отчётов имеется
                ' проходим по отчётам
                str = "<P>  <font color=""gray"">Найден диапазон</font> <font color=""blue"">*Отчёты обычные*</font>, колонка - " _
                    & ra_RA.Column & ", первая строка - " & ra_RA.Row & ", " _
                    & "нижняя строка - " & ra_RA.Row + ra_RA.Rows.count - 1 & ". Адрес: <font color=""blue"">" & ra_RA.Address & "</font>.</P>"
                    
                fff = str & mobjParent.obgRa_aResult.value: str = ""
                mobjParent.obgRa_aResult.value = fff
                
                ' -------------------------------------------------------------------------------------------------------------------------
                ' -------------------------------------------------------------------------------------------------------------------------
                ' проходим по диапазону отчётов -------------------------------------------------------------------------------------------
                With ra_RA
                
                    ' количество ячеек в диапазоне больше одной?
                    If .count > 1 Then
                        ' да, количество ячеек в диапазоне больше одной ...................................................................
                        ' ищем собственно отчёт
                        ' Set c = .Find(what:="*-???????-*", LookAt:=xlPart) 07.02.2025 меняем формат из за ГИ Ф Надым-Пур-Таз
                        Set c = .Find(what:="*???????-*", LookAt:=xlPart)
                        ' имеется ли имя соответствующее форме имени отчёта?
                        If Not c Is Nothing Then
                            ' да имя соответствующее форме имени отчёта имеется
                            ' простой отчет нашелся в колонке имен отчётов?
                            If c.Column = cellRaNumColumn Then
                                ' да, простой отчёт нашелся в колонке имен отчётов
                                adr = c.Address
                                RaReadOfExcel _
                                    ra:=c.value, ra_date:=StrToDate(c.Offset(0, cellRaDateOffset).value), ra_Row:=c.Row, _
                                    Constraction:=c.Offset(0, cellCstAgPnOffset).value, ConstrName:=c.Offset(0, cellCstNameOffset).value, _
                                    addRa:=mobjParent.blnAdt_AddRA, _
                                    str:=str, db:=db, _
                                    total:=c.Offset(0, cellTotalOffset).value, work:=c.Offset(0, cellWorkOffset).value, _
                                    equipment:=c.Offset(0, cellEquipOffset).value, others:=c.Offset(0, cellOthersOffset).value, _
                                    arrived:=c.Offset(0, cellArrivedOffset).value, arrivedDate:=c.Offset(0, cellArrivedDateOffset).value, _
                                    arrivedDateFact:=c.Offset(0, cellArrivedDateFactOffset).value, _
                                    returned:=c.Offset(0, cellReturnedOffset).value, returnedDate:=c.Offset(0, cellReturnedDateOffset).value, _
                                    sent:=c.Offset(0, cellSentOffset).value, sendDate:=c.Offset(0, cellSentDateOffset).value, _
                                    returnedReason:=c.Offset(0, cellReturnedReasonOffset).value, ra_org_sender:=c.Offset(0, cellSenderOffset).value, _
                                    ra_type:=c.Offset(0, cellSignOffset).value
                            Else
                                ' нет, простой отчёт нашелся не в колонке имен отчётов
                                str = "<P>  В столбце ячейки номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. " _
                                    & "Отчёт нашелся не в колонке имен отчётов</P>"
                                'fff = str & fff
                                GoTo NotRA 'Exit Sub
                            End If
                        Else
                            ' нет имя соответствующее форме имени отчёта отсутствует
                            str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов " _
                                & "<B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                            'fff = str & fff
                            GoTo NotRA 'Exit Sub
                        End If
                        Do
                            Set c = .FindNext(c)
                            If (Not c.Address = adr) And (c.Column = cellRaNumColumn) Then
                            RaReadOfExcel _
                                    ra:=c.value, ra_date:=StrToDate(c.Offset(0, cellRaDateOffset).value), ra_Row:=c.Row, _
                                    Constraction:=c.Offset(0, cellCstAgPnOffset).value, ConstrName:=c.Offset(0, cellCstNameOffset).value, _
                                    addRa:=mobjParent.blnAdt_AddRA, _
                                    str:=str, db:=db, _
                                    total:=c.Offset(0, cellTotalOffset).value, work:=c.Offset(0, cellWorkOffset).value, _
                                    equipment:=c.Offset(0, cellEquipOffset).value, others:=c.Offset(0, cellOthersOffset).value, _
                                    arrived:=c.Offset(0, cellArrivedOffset).value, arrivedDate:=c.Offset(0, cellArrivedDateOffset).value, _
                                    arrivedDateFact:=c.Offset(0, cellArrivedDateFactOffset).value, _
                                    returned:=c.Offset(0, cellReturnedOffset).value, returnedDate:=c.Offset(0, cellReturnedDateOffset).value, _
                                    sent:=c.Offset(0, cellSentOffset).value, sendDate:=c.Offset(0, cellSentDateOffset).value, _
                                    returnedReason:=c.Offset(0, cellReturnedReasonOffset).value, ra_org_sender:=c.Offset(0, cellSenderOffset).value, _
                                    ra_type:=c.Offset(0, cellSignOffset).value
                            End If
                        Loop Until c.Address = adr
                        ' да, количество ячеек в диапазоне больше одной. Окончание ........................................................
                    Else
                        ' нет, количество ячеек в диапазоне не больше одной ...............................................................
                        ' ищем собственно отчёт
                        Set c = .Find(what:="*-???????-*", LookAt:=xlPart)
                        ' имеется ли имя соответствующее форме имени отчёта?
                        If Not c Is Nothing Then
                            ' да имя соответствующее форме имени отчёта имеется
                            ' простой отчет нашелся в колонке имен отчётов?
                            If c.Column = cellRaNumColumn Then
                            ' да, простой отчёт нашелся в колонке имен отчётов
                            adr = c.Address
                                RaReadOfExcel _
                                    ra:=c.value, ra_date:=StrToDate(c.Offset(0, cellRaDateOffset).value), ra_Row:=c.Row, _
                                    Constraction:=c.Offset(0, cellCstAgPnOffset).value, ConstrName:=c.Offset(0, cellCstNameOffset).value, _
                                    addRa:=mobjParent.blnAdt_AddRA, _
                                    str:=str, db:=db, _
                                    total:=c.Offset(0, cellTotalOffset).value, work:=c.Offset(0, cellWorkOffset).value, _
                                    equipment:=c.Offset(0, cellEquipOffset).value, others:=c.Offset(0, cellOthersOffset).value, _
                                    arrived:=c.Offset(0, cellArrivedOffset).value, arrivedDate:=c.Offset(0, cellArrivedDateOffset).value, _
                                    arrivedDateFact:=c.Offset(0, cellArrivedDateFactOffset).value, _
                                    returned:=c.Offset(0, cellReturnedOffset).value, returnedDate:=c.Offset(0, cellReturnedDateOffset).value, _
                                    sent:=c.Offset(0, cellSentOffset).value, sendDate:=c.Offset(0, cellSentDateOffset).value, _
                                    returnedReason:=c.Offset(0, cellReturnedReasonOffset).value, ra_org_sender:=c.Offset(0, cellSenderOffset).value, _
                                    ra_type:=c.Offset(0, cellSignOffset).value
                            Else
                                ' нет, простой отчёт нашелся не в колонке имен отчётов
                                str = "<P>  <font color=""silver"">В столбце ячейки номеров</font> обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. Простой отчёт нашелся не в колонке имен отчётов</P>"
                            End If
                            Else
                            ' нет имя соответствующее форме имени отчёта отсутствует
                            str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                        End If
                        ' нет, количество ячеек в диапазоне не больше одной. Окончание ....................................................
                    End If ' здесь проверка на количество ячеек в диапазоне
                    
    ' метка для продолжения в случае отсутствия отчётов
NotRA:
                    
                End With
                ' проходим по диапазону отчётов. Окончание --------------------------------------------------------------------------------
                ' -------------------------------------------------------------------------------------------------------------------------
                ' -------------------------------------------------------------------------------------------------------------------------
                
                fff = str & mobjParent.obgRa_aResult.value: str = ""
                mobjParent.obgRa_aResult.value = fff
            End If ' да, диапазон отчётов имеется
        End If ' да, ячейка номеров отчёта и смещения найдены
    Else
        ' нет, обновлять промежуточную таблицу по источнику данных не нужно
    End If
    ' ===============================================================================================================================================
    ' 1. Обновляем (или не обновляем) промежуточную таблицу по источнику данных. Окончание ==========================================================
    ' ===============================================================================================================================================
    ' ===============================================================================================================================================
    
    
    
    ' ===============================================================================================================================================
    ' Сверяем информацию по найденным отчётам агента с данными в БД
    ' открываем набор записей всех отчётов ' --------------------------------------------------------------------------------------------------------
    Set rsRaAll = db.OpenRecordset("ra_ImpNewQuRa", dbOpenSnapshot)
    rsRaAll.MoveLast: rsRaAll.MoveFirst
    mobjParent.obgRa_aResult.value = "<P>Всего найдено отчётов: <b>" & rsRaAll.RecordCount & "</b></P>" _
        & mobjParent.obgRa_aResult.value
    ' закрываем набор записей всех отчётов
    rsRaAll.Close: Set rsRaAll = Nothing ' ----------------------------------------------------------------------------------------------------------
        
    ' открываем набор записей отчётов отсутствующих в БД --------------------------------------------------------------------------------------------
    Set rsRaNew = db.OpenRecordset("select * from ra_ImpNewQuRa where ra_key is null", dbOpenSnapshot)
    ' имеются ли отчёты отсутствующие в БД?
    If rsRaNew.RecordCount > 0 Then
        ' да, отчёты отсутствующие в БД имеются
        rsRaNew.MoveLast: rsRaNew.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено отчётов</font> отсутствующих в БД: <b>" & rsRaNew.RecordCount & "</b></P>" _
            & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи отчёта отсутствующего в БД
        iii = 0
        Do Until rsRaNew.EOF 'Or iii > 2
            str = "": iii = iii + 1
            ' создаём отчёт агента по источнику
            AuditRaCreateNew rsRaNew, str, iii, db
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaNew.MoveNext
        Loop
    Else
        ' нет, отчёты отсутствующие в БД отсутствуют
        mobjParent.obgRa_aResult.value = "<P><font color=""SeaGreen"">Не найдены отчёты</font> <b>отсутствующие в БД</b>.</P>" _
            & mobjParent.obgRa_aResult.value
    End If ' имеются ли отчёты отсутствующие в БД?
    ' закрываем набор записей отчётов отсутствующих в БД --------------------------------------------------------------------------------------------
    rsRaNew.Close: Set rsRaNew = Nothing
    
    ' открываем набор записей отчётов имеющих несоответствия в данных -------------------------------------------------------------------------------
    Set rsRaErr = db.OpenRecordset("select * from ra_ImpNewQuRa where ra_key is not null and rs = false order by rainRow", dbOpenSnapshot)
    ' имеются ли отчёты имеющие несоответствия в данных?
    If rsRaErr.RecordCount > 0 Then
        ' да, отчёты имеющие несоответствия в данных имеются
        rsRaErr.MoveLast: rsRaErr.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено отчётов</font> имеющих несоответствия в данных: <b>" & rsRaErr.RecordCount & "</b></P>" _
            & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи отчёта имеющего несоответствия в данных
        iii = 0
        Do Until rsRaErr.EOF 'Or iii > 400
            str = "": iii = iii + 1
            ' корректируем отчёт агента по источнику
            AuditRaEdit rsRaErr, str, iii, db
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaErr.MoveNext
        Loop
    Else
        ' да, отчёты имеющие несоответствия в данных отсутствуют
        mobjParent.obgRa_aResult.value = "<P><font color=""SeaGreen"">Не найдены отчёты</font> <b>имеющие несоответствия в данных</b>.</P>" _
            & mobjParent.obgRa_aResult.value
    End If ' имеются ли отчёты имеющие несоответствия в данных? Окончание.
    ' закрываем набор записей отчётов имеющих несоответствия в данных
    rsRaErr.Close: Set rsRaErr = Nothing ' ----------------------------------------------------------------------------------------------------------
    
    ' открываем набор записей отчётов имеющихся в БД, но отсутствующих в источнике ------------------------------------------------------------------
    strSql = "SELECT p.rap_datePeriod, p.key, r.ra_key " _
        & "FROM (ags_ra_period AS p INNER JOIN ags_ra AS r ON p.key = r.ra_period) LEFT JOIN ra_ImpNewQuRa AS q ON r.ra_key = q.ra_key " _
        & "WHERE (((Year([p].[rap_datePeriod]))=" & CStr(mobjParent.year(db)) & ") AND ((q.rainRow) Is Null));"
    Set rsRaExr = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи отчётов имеющихся в БД, но отсутствующих в источнике
    If rsRaExr.RecordCount > 0 Then
        ' да, записи отчётов имеющихся в БД, но отсутствующих в источнике имеются
        rsRaExr.MoveLast: rsRaExr.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено отчётов</font> имеющихся в БД, но отсутствующих в источнике: <b>" & rsRaExr.RecordCount & "</b></P>" _
            & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи отчёта имеющего несоответствия в данных
        iii = 0
        Do Until rsRaExr.EOF 'Or iii > 400
            str = "": iii = iii + 1
            ' отображаем отчёт агента по источнику
            Set raRaExr = ClassFactory.raByKey(rsRaExr!ra_key, db)
            str = "<p>" & iii & ". <font color=""Crimson"">" & raRaExr.strRaName & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRaExr.raDelete
                str = str & ". <b>Удалён</b>"
            End If
            str = str & ".</p>"
            Set raRaExr = Nothing
            'AuditRaEdit rsRaErr, str, iii, db
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaExr.MoveNext
        Loop
    End If ' имеются ли записи отчётов имеющихся в БД, но отсутствующих в источнике
    ' закрываем набор записей отчётов имеющихся в БД, но отсутствующих в источнике
    rsRaExr.Close: Set rsRaExr = Nothing ' ----------------------------------------------------------------------------------------------------------
    ' Сверяем информацию по найденным отчётам агента с данными в БД. Окончание
    ' ===============================================================================================================================================
    
    ' ===============================================================================================================================================
    ' Сверяем информацию по найденным изменениям отчётов агента с данными в БД
    ' открываем набор записей всех изменений отчётов ' ----------------------------------------------------------------------------------------------
    Set rsRaAll = db.OpenRecordset("ra_ImpNewQuRc", dbOpenSnapshot)
    rsRaAll.MoveLast: rsRaAll.MoveFirst
    mobjParent.obgRa_aResult.value = "<P>Всего найдено изменений: <b>" & rsRaAll.RecordCount & "</b></P>" _
        & mobjParent.obgRa_aResult.value
    ' закрываем набор записей всех изменений отчётов
    rsRaAll.Close: Set rsRaAll = Nothing ' ----------------------------------------------------------------------------------------------------------
        
    ' открываем набор записей изменений отчётов отсутствующих в БД ----------------------------------------------------------------------------------
    Set rsRaNew = db.OpenRecordset("select * from ra_ImpNewQuRc where rac_key is null", dbOpenSnapshot)
    ' имеются ли изменения отсутствующие в БД?
    If rsRaNew.RecordCount > 0 Then
        ' да, изменения отсутствующие в БД имеются
        rsRaNew.MoveLast: rsRaNew.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено изменений</font> отсутствующих в БД: <b>" & rsRaNew.RecordCount & "</b></P>" _
            & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи изменения отсутствующего в БД
        iii = 0
        Do Until rsRaNew.EOF 'Or iii > 2
            str = "": iii = iii + 1
            ' создаём изменение отчёта агента по источнику
            AuditRcCreateNew rsRaNew, str, iii, db
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaNew.MoveNext
        Loop
    Else
        ' нет, изменения отсутствующие в БД отсутствуют
        mobjParent.obgRa_aResult.value = "<P><font color=""SeaGreen"">Не найдены изменения</font> <b>отсутствующие в БД</b>.</P>" _
            & mobjParent.obgRa_aResult.value
    End If ' имеются ли изменения отсутствующие в БД?
    ' закрываем набор записей изменений отчётов отсутствующих в БД ----------------------------------------------------------------------------------
    rsRaNew.Close: Set rsRaNew = Nothing
    
    ' открываем набор записей изменений отчётов имеющих несоответствия в данных ---------------------------------------------------------------------
    Set rsRaErr = db.OpenRecordset("select * from ra_ImpNewQuRc where rac_key is not null and rs = false order by rainRow", dbOpenSnapshot)
    ' имеются ли изменения имеющие несоответствия в данных?
    If rsRaErr.RecordCount > 0 Then
        ' да, изменения имеющие несоответствия в данных имеются
        rsRaErr.MoveLast: rsRaErr.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено изменений</font> имеющих несоответствия в данных: <b>" & rsRaErr.RecordCount & "</b></P>" _
            & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи изменения имеющего несоответствия в данных
        iii = 0
        Do Until rsRaErr.EOF 'Or iii > 2
            str = "": iii = iii + 1
            ' корректируем изменение отчёта агента по источнику
            AuditRcEdit rsRaErr, str, iii, db
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaErr.MoveNext
        Loop
    Else
        ' нет, изменения имеющие несоответствия в данных отсутствуют
        mobjParent.obgRa_aResult.value = "<P><font color=""SeaGreen"">Не найдены изменения</font> <b>имеющие несоответствия в данных</b>.</P>" _
            & mobjParent.obgRa_aResult.value
    End If ' имеются ли отчёты имеющие несоответствия в данных? Окончание.
    ' закрываем набор записей изменений отчётов имеющих несоответствия в данных
    rsRaErr.Close: Set rsRaErr = Nothing ' ----------------------------------------------------------------------------------------------------------
    
    ' открываем набор записей изменений отчётов имеющихся в БД, но отсутствующих в источнике --------------------------------------------------------
    strSql = "SELECT c.rac_key, q.rainRow " _
        & "FROM ags_ra_change AS c INNER JOIN ra_ImpNewQuRc AS q ON c.rac_key = q.rac_key " _
        & "WHERE (((q.rainRow) Is Null) AND ((Year([rac_datePeriod]))=" & CStr(mobjParent.year(db)) & "));"
    Set rsRaExr = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи отчётов имеющихся в БД, но отсутствующих в источнике
    If rsRaExr.RecordCount > 0 Then
        ' да, записи отчётов имеющихся в БД, но отсутствующих в источнике имеются
        rsRaExr.MoveLast: rsRaExr.MoveFirst
        mobjParent.obgRa_aResult.value = _
            "<P><font color=""Crimson"">Найдено изменений отчётов</font> имеющихся в БД, но отсутствующих в источнике: <b>" _
            & rsRaExr.RecordCount & "</b></P>" & mobjParent.obgRa_aResult.value
        ' проходим по каждой записи отчёта имеющего несоответствия в данных
        iii = 0
        Do Until rsRaExr.EOF 'Or iii > 400
            str = "": iii = iii + 1
            ' отображаем отчёт агента по источнику
            Set rcRcExr = ClassFactory.rcByKey(rsRaExr!rac_key, db)
            str = "<p>" & iii & ". <font color=""Crimson"">" & rcRcExr.strRcName & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRcExr.rcDelete
                str = str & ". <b>Удалёно</b>"
            End If
            str = str & ".</p>"
            Set rcRcExr = Nothing
            mobjParent.obgRa_aResult.value = str & mobjParent.obgRa_aResult.value
            rsRaExr.MoveNext
        Loop
    End If ' имеются ли записи отчётов имеющихся в БД, но отсутствующих в источнике
    ' закрываем набор записей изменений отчётов имеющихся в БД, но отсутствующих в источнике
    rsRaExr.Close: Set rsRaExr = Nothing ' ----------------------------------------------------------------------------------------------------------
    ' Сверяем информацию по найденным изменениям отчётов агента с данными в БД. Окончание
    ' ===============================================================================================================================================
    

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' работаем с листом Отчётов всех агентов. 05.07.2022. Окончание *************************************************************************************



' ***************************************************************************************************************************************************
' создаём изменение отчёта агента по источнику. 22.07.2022.
Private Sub AuditRcCreateNew(ByRef rsRaNew As DAO.Recordset, ByRef str As String, ByRef iii As Integer, db As DAO.Database)
    '------------------------------------------------------------------------------------------------------------------------------------------------
    Dim rcRc As rc, rcsmRcSm As rcSm
    '------------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Создаём изменение отчёта агента по источнику*"
    '------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' открываем абзац
    str = "<P>" & iii & ". " & rsRaNew!rainRow & ". <font color=""OliveDrab"">" & rsRaNew!rainRaNum & "</font>"
    
    ' нужно ли обновлять базу данных?
    If mobjParent.blnAdt_AddRA Then
        ' да, обновлять базу данных нужно
        ' имеется ли ключ отчёта, к которому изменение?
        If Not IsNull(rsRaNew!ra_key) Then
            ' да, ключ отчёта, к которому изменение имеется
            ' имеется ли ключ периода?
            If Not IsNull(rsRaNew!rcPeriod) And Not rsRaNew!rcPeriod = 0 Then
                ' да, ключ периода имеется
                ' имеется ли номер изменения?
                If Not IsNull(rsRaNew!num) And Not rsRaNew!num = 0 Then
                    ' да, номер изменения имеется
                    '  имеется ли ключ отправителя?
                    If Not IsNull(rsRaNew!exSender) And Not rsRaNew!exSender = 0 Then
                        ' да, ключ отправителя имеется
                        ' создаём объект
                        Set rcRc = ClassFactory.rcCreateNew(db, rsRaNew!ra_key, rsRaNew!num, rsRaNew!rcPeriod, rsRaNew!exSender, _
                            rsRaNew!exDate, rsRaNew!exArrv, rsRaNew!exArrvDate, rsRaNew!exArrvDateFact, _
                            rsRaNew!exRetn, rsRaNew!exRetnDate, rsRaNew!exRetnRsn, rsRaNew!exSent, rsRaNew!exSentDate, Null, Null)
                            ' объект создан?
                        If Not rcRc Is Nothing Then
                            ' да, объект удалось создать
                            str = str & ". Создано изменение отчёта, ключ: " & rcRc.lngRcKey
                            ' имется ли сумма какого либо вида?
                            If Not ( _
                                    IIf(IsNull(rsRaNew!exTtl), 0, rsRaNew!exTtl) + IIf(IsNull(rsRaNew!exWork), 0, rsRaNew!exWork) + _
                                    IIf(IsNull(rsRaNew!exEquip), 0, rsRaNew!exEquip) + IIf(IsNull(rsRaNew!exOthers), 0, rsRaNew!exOthers) _
                                    = 0) _
                                Then
                                ' создаём объект суммы
                                Set rcsmRcSm = rcRc.rcsmRcSmAdd(rsRaNew!exTtl, rsRaNew!exWork, rsRaNew!exEquip, rsRaNew!exOthers)
                                If Not rcsmRcSm Is Nothing Then
                                    str = str & ". Сумма: " _
                                        & "всего: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmTtl) & "</font>" _
                                        & ", СМР: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmWork) & "</font>" _
                                        & ", Оборудование: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmEquip) & "</font>" _
                                        & ", Прочие: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmOthers) & "</font>"
                                    ' ликвидируем объект
                                    Set rcsmRcSm = Nothing
                                Else
                                    str = str & ". <font color=""OrangeRed""><b>Сумма, хотя нужна, не создана!</b></font>"
                                End If
                            Else
                                str = str & ". Сумма не требуется."
                            End If ' имется ли сумма какого либо вида?
                            ' ликвидируем объект
                            Set rcRc = Nothing
                        Else
                            ' нет, объект создать не удалось
                            str = str & ". <font color=""OrangeRed""><b>Создать изменение отчёта не удалось!</b></font>"
                        End If ' объект создан?
                    Else
                        str = str & ". <font color=""OrangeRed""><b>Нет отправителя!</b></font>"
                    End If '  имеется ли ключ отправителя?
                Else
                    str = str & ". <font color=""OrangeRed""><b>Нет номера изменения!</b></font>"
                End If ' имеется ли номер изменения?
            Else
                str = str & ". <font color=""OrangeRed""><b>Нет периода!</b></font>"
            End If ' имеется ли ключ периода?
        Else
            str = str & ". <font color=""OrangeRed""><b>Нет ключа отчёта!</b></font>"
        End If ' имеется ли ключ отчёта, к которому изменение?
    End If ' нужно ли обновлять базу данных?

    ' закрываем абзац
    str = str & "</P>"

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' создаём изменение отчёта агента по источнику. 22.07.2022. Окончание
' ***************************************************************************************************************************************************




' ***************************************************************************************************************************************************
' корректируем изменение отчёта агента по источнику. 22.07.2022.
Private Sub AuditRcEdit(ByRef rsRaErr As DAO.Recordset, ByRef str As String, ByRef iii As Integer, db As DAO.Database)
    '------------------------------------------------------------------------------------------------------------------------------------------------
    Dim rcRc As rc, rcsmRcSm As rcSm
    '------------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Корректируем изменение отчёта агента по источнику*"
'----------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' создаём объект изменения отчёта агента агента
    Set rcRc = ClassFactory.rcByKey(rsRaErr!rac_key, db)
    ' имеется ли такое изменение?
    If Not rcRc Is Nothing Then
        ' да, такое изменение имеется
                
        ' открываем абзац
        str = "<P>" & iii & ". " & rsRaErr!rainRow & ". <font color=""OliveDrab"">" & rcRc.strRcName & "</font>"
        
        ' письмо поступления не соответствует?
        If rsRaErr!rsArrv = False Then
            ' да, письмо поступления не соответствует
            str = str & ". Письмо поступления, БД: <font color=""Crimson"">" & rcRc.strRaArrived _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrv & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.strRaArrived = rsRaErr!exArrv
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.strRaArrived & "</font>"
            End If
        End If

        ' дата письма поступления не соответствует?
        If rsRaErr!rsArrvDate = False Then
            ' да, дата письма поступления не соответствует
            str = str & ". Дата поступления, БД: <font color=""Crimson"">" & rcRc.dateRaArrivedDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrvDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.dateRaArrivedDate = rsRaErr!exArrvDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.dateRaArrivedDate & "</font>"
            End If
        End If

        ' дата письма поступления фактическая не соответствует?
        If rsRaErr!rsArrvDateFact = False Then
            ' да, дата письма поступления фактическая не соответствует
            str = str & ". Дата поступления фактическая, БД: <font color=""Crimson"">" & rcRc.dateRaArrivedDateFact _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrvDateFact & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.dateRaArrivedDateFact = rsRaErr!exArrvDateFact
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.dateRaArrivedDateFact & "</font>"
            End If
        End If

        ' письмо возвращения не соответствует?
        If rsRaErr!rsRetn = False Then
            ' да, письмо возвращения не соответствует
            str = str & ". Письмо возвращения, БД: <font color=""Crimson"">" & rcRc.strRaReturned _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetn & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.strRaReturned = rsRaErr!exRetn
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.strRaReturned & "</font>"
            End If
        End If

        ' дата письма возвращения не соответствует?
        If rsRaErr!rsRetnDate = False Then
            ' да, дата письма возвращения не соответствует
            str = str & ". Дата возвращения, БД: <font color=""Crimson"">" & rcRc.dateRaReturnedDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetnDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.dateRaReturnedDate = rsRaErr!exRetnDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.dateRaReturnedDate & "</font>"
            End If
        End If

        ' причина возвращения не соответствует?
        If rsRaErr!rsRetnRsn = False Then
            ' да, причина возвращения не соответствует
            str = str & ". Причина возвращения, БД: <font color=""Crimson"">" & rcRc.strRaReturnedReason _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetnRsn & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.strRaReturnedReason = rsRaErr!exRetnRsn
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.strRaReturnedReason & "</font>"
            End If
        End If

        ' письмо направления не соответствует?
        If rsRaErr!rsSent = False Then
            ' да, письмо направления не соответствует
            str = str & ". Письмо направления, БД: <font color=""Crimson"">" & rcRc.strRaSent _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSent & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.strRaSent = rsRaErr!exSent
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.strRaSent & "</font>"
            End If
        End If

        ' дата письма направления не соответствует?
        If rsRaErr!rsSentDate = False Then
            ' да, дата письма направления не соответствует
            str = str & ". Дата направления, БД: <font color=""Crimson"">" & rcRc.dateRaSentDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSentDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.dateRaSentDate = rsRaErr!exSentDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.dateRaSentDate & "</font>"
            End If
        End If

        ' организация отправитель не соответствует?
        If rsRaErr!rsSender = False Then
            ' да, организация отправитель не соответствует
            str = str & ". Отправитель, БД: <font color=""Crimson"">" & rcRc.lngRaSender _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSender & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.lngRaSender = rsRaErr!exSender
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.lngRaSender & "</font>"
            End If
        End If

        ' дата изменения отчёта агента не соответствует?
        If rsRaErr!rsDate = False Then
            ' да, дата изменения отчёта агента не соответствует
            str = str & ". Дата изменения, БД: <font color=""Crimson"">" & rcRc.dateRcDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                rcRc.dateRcDate = rsRaErr!exDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & rcRc.dateRcDate & "</font>"
            End If
        End If

        ' суммы изменения отчёта не соответствует?
        If rsRaErr!rsSum = False Then
            ' да, суммы изменения отчёта не соответствует
            ' имеется сумма у изменения отчёта?
            If Not IsNull(rsRaErr!raсs_key) Then
                ' да, сумма у измененияотчёта имеется
                ' создаём объект
                Set rcsmRcSm = ClassFactory.rcSmByKey(rsRaErr!raсs_key, db)
                str = str & ". Суммы изменения"
                ' *всего* не соответствует?
                If rsRaErr!rsTtl = False Then
                    str = str & ", всего, БД: <font color=""Crimson"">" & FormatCurrency(rcsmRcSm.curRcSmTtl) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exTtl) & "</font>"
                End If
                ' *СМР* не соответствует?
                If rsRaErr!rsWork = False Then
                    str = str & ", СМР, БД: <font color=""Crimson"">" & FormatCurrency(rcsmRcSm.curRcSmWork) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exWork) & "</font>"
                End If
                ' *Оборудование* не соответствует?
                If rsRaErr!rsEquip = False Then
                    str = str & ", Оборудование, БД: <font color=""Crimson"">" & FormatCurrency(rcsmRcSm.curRcSmEquip) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exEquip) & "</font>"
                End If
                ' *Прочие* не соответствует?
                If rsRaErr!rsOthers = False Then
                    str = str & ", Прочие, БД: <font color=""Crimson"">" & FormatCurrency(rcsmRcSm.curRcSmOthers) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exOthers) & "</font>"
                End If
                ' ликвидируем объект
                Set rcsmRcSm = Nothing
            Else
                ' нет, сумма у изменения отчёта отсутствует
                str = str & ". Суммы отчёта, БД: <font color=""Crimson"">нет сумм</font>, источник: " _
                    & "всего: <font color=""Peru"">" & FormatCurrency(rsRaErr!exTtl) & "</font>" _
                    & ", СМР: <font color=""Peru"">" & FormatCurrency(rsRaErr!exWork) & "</font>" _
                    & ", Оборудование: <font color=""Peru"">" & FormatCurrency(rsRaErr!exEquip) & "</font>" _
                    & ", Прочие: <font color=""Peru"">" & FormatCurrency(rsRaErr!exOthers) & "</font>"
            End If
            ' нужно ли корректировать БД?
            If mobjParent.blnAdt_AddRA Then
                ' создаём объект
                Set rcsmRcSm = ClassFactory.rcSmCreateNew(rsRaErr!rac_key, db, rsRaErr!exTtl, rsRaErr!exWork, _
                    rsRaErr!exEquip, rsRaErr!exOthers)
                str = str & ". Обновлено, БД: " _
                    & "всего: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmTtl) & "</font>" _
                    & ", СМР: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmWork) & "</font>" _
                    & ", Оборудование: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmEquip) & "</font>" _
                    & ", Прочие: <font color=""SeaGreen"">" & FormatCurrency(rcsmRcSm.curRcSmOthers) & "</font>"
                ' ликвидируем объект
                Set rasmRaSm = Nothing
            End If ' нужно ли корректировать БД?
        End If ' суммы изменения отчёта не соответствует?
        
        ' закрываем абзац
        str = str & "</P>"
        
    End If ' имеется ли такой отчёт? Окончание.
    ' ликвидируем объект отчёта агента
    Set rcRc = Nothing

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' корректируем изменение отчёта агента по источнику. 22.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' создаём отчёт агента по источнику. 21.07.2022.
Private Sub AuditRaCreateNew(ByRef rsRaNew As DAO.Recordset, ByRef str As String, ByRef iii As Integer, db As DAO.Database)
    Dim raRa As ra, rasmRaSm As raSm
    Const cstrTitle As String = "Процедура *Создаём отчёт агента по источнику*"
    '------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' открываем абзац
    str = "<P>" & iii & ". " & rsRaNew!rainRow & ". <font color=""OliveDrab"">" & rsRaNew!rainRaNum & "</font>"
    ' но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
    If Left(rsRaNew!rainRaNum, 3) = "Изм" Or Left(rsRaNew!rainRaNum, 3) = "изм" Or Left(rsRaNew!rainRaNum, 9) = "Изменение" Then
        ' да, это именно изменение
        str = str & ". <font color=""OrangeRed""><b>Но это изменение!</b></font>"
    Else
        ' нет, это простой отчёт
        ' нужно ли обновлять базу данных?
        If mobjParent.blnAdt_AddRA Then
            ' да, обновлять базу данных нужно
            If Not IsNull(rsRaNew!rainRaNum) And Not rsRaNew!rainRaNum = "" Then
                If Not IsNull(rsRaNew!periodKey) And Not rsRaNew!periodKey = 0 Then
                    If Not IsNull(rsRaNew!cstapKey) And Not rsRaNew!cstapKey = 0 Then
                        If Not IsNull(rsRaNew!cstapKey) And Not rsRaNew!ogKey = 0 Then
                            If rsRaNew!rainSign = "ОА" Or rsRaNew!rainSign = "ОА прочие" Then
                                ' создаём объект
                                Set raRa = ClassFactory.raCreateNew(db, rsRaNew!rainRaNum, rsRaNew!rainSign, rsRaNew!periodKey, rsRaNew!cstapKey, _
                                    rsRaNew!ogKey, rsRaNew!exDate, Null, rsRaNew!exArrv, rsRaNew!exArrvDate, rsRaNew!exArrvDateFact, _
                                    rsRaNew!exRetn, rsRaNew!exRetnDate, rsRaNew!exRetnRsn, rsRaNew!exSent, rsRaNew!exSentDate, Null, Null)
                                ' объект создан?
                                If Not raRa Is Nothing Then
                                    ' да, объект удалось создать
                                    str = str & ". Создан отчёт, ключ: " & raRa.lngRaKey
                                    ' имется ли сумма какого либо вида?
                                    If Not ( _
                                            IIf(IsNull(rsRaNew!exTtl), 0, rsRaNew!exTtl) + IIf(IsNull(rsRaNew!exWork), 0, rsRaNew!exWork) + _
                                            IIf(IsNull(rsRaNew!exEquip), 0, rsRaNew!exEquip) + IIf(IsNull(rsRaNew!exOthers), 0, rsRaNew!exOthers) _
                                            = 0) _
                                        Then
                                        ' создаём объект суммы
                                        Set rasmRaSm = raRa.rasmRaSmAdd(rsRaNew!exTtl, rsRaNew!exWork, rsRaNew!exEquip, rsRaNew!exOthers)
                                        If Not rasmRaSm Is Nothing Then
                                            str = str & ". Сумма: " _
                                                & "всего: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmTtl) & "</font>" _
                                                & ", СМР: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmWork) & "</font>" _
                                                & ", Оборудование: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmEquip) & "</font>" _
                                                & ", Прочие: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmOthers) & "</font>"
                                            ' ликвидируем объект
                                            Set rasmRaSm = Nothing
                                        Else
                                            str = str & ". <font color=""OrangeRed""><b>Сумма, хотя нужна, не создана!</b></font>"
                                        End If
                                    Else
                                        str = str & ". Сумма не требуется."
                                    End If ' имется ли сумма какого либо вида?
                                    ' ликвидируем объект
                                    Set raRa = Nothing
                                Else
                                    ' нет, объект создать не удалось
                                    str = str & ". <font color=""OrangeRed""><b>Создать отчёт не удалось!</b></font>"
                                End If ' объект создан?
                            Else
                                str = str & ". <font color=""OrangeRed""><b>Неверный тип: </b></font>" & rsRaNew!rainSign
                            End If
                        Else
                            str = str & ". <font color=""OrangeRed""><b>Нет отправителя!</b></font>"
                        End If
                    Else
                        str = str & ". <font color=""OrangeRed""><b>Нет стройки!</b></font>"
                    End If
                Else
                    str = str & ". <font color=""OrangeRed""><b>Нет периода!</b></font>"
                End If
            Else
                str = str & ". <font color=""OrangeRed""><b>Нет номера отчёта!</b></font>"
            End If
        End If ' нужно ли обновлять базу данных?
    End If ' но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
    ' закрываем абзац
    str = str & "</P>"

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' создаём отчёт агента по источнику. 21.07.2022. Окончание
' ***************************************************************************************************************************************************



' ***************************************************************************************************************************************************
' корректируем отчёт агента по источнику. 19.07.2022.
Private Sub AuditRaEdit(ByRef rsRaErr As DAO.Recordset, ByRef str As String, ByRef iii As Integer, db As DAO.Database)
    Dim raRa As ra, rasmRaSm As raSm
    Const cstrTitle As String = "Процедура *Корректируем отчёт агента по источнику*"
    '------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' создаём объект отчёта агента
    Set raRa = ClassFactory.raByKey(rsRaErr!ra_key, db)
    ' имеется ли такой отчёт?
    If Not raRa Is Nothing Then
        ' да, такой отчёт имеется
                
        ' открываем абзац
        str = "<P>" & iii & ". " & rsRaErr!rainRow & ". " & raRa.strRaNum
        
        ' письмо поступления не соответствует?
        If rsRaErr!rsArrv = False Then
            ' да, письмо поступления не соответствует
            str = str & ". Письмо поступления, БД: <font color=""Crimson"">" & raRa.strRaArrived _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrv & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.strRaArrived = rsRaErr!exArrv
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.strRaArrived & "</font>"
            End If
        End If
    
        ' дата письма поступления не соответствует?
        If rsRaErr!rsArrvDate = False Then
            ' да, дата письма поступления не соответствует
            str = str & ". Дата поступления, БД: <font color=""Crimson"">" & raRa.dateRaArrivedDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrvDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.dateRaArrivedDate = rsRaErr!exArrvDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.dateRaArrivedDate & "</font>"
            End If
        End If
    
        ' дата письма поступления фактическая не соответствует?
        If rsRaErr!rsArrvDateFact = False Then
            ' да, дата письма поступления фактическая не соответствует
            str = str & ". Дата поступления фактическая, БД: <font color=""Crimson"">" & raRa.dateRaArrivedDateFact _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exArrvDateFact & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.dateRaArrivedDateFact = rsRaErr!exArrvDateFact
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.dateRaArrivedDateFact & "</font>"
            End If
        End If
    
        ' письмо возвращения не соответствует?
        If rsRaErr!rsRetn = False Then
            ' да, письмо возвращения не соответствует
            str = str & ". Письмо возвращения, БД: <font color=""Crimson"">" & raRa.strRaReturned _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetn & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.strRaReturned = rsRaErr!exRetn
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.strRaReturned & "</font>"
            End If
        End If
    
        ' дата письма возвращения не соответствует?
        If rsRaErr!rsRetnDate = False Then
            ' да, дата письма возвращения не соответствует
            str = str & ". Дата возвращения, БД: <font color=""Crimson"">" & raRa.dateRaReturnedDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetnDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.dateRaReturnedDate = rsRaErr!exRetnDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.dateRaReturnedDate & "</font>"
            End If
        End If
    
        ' причина возвращения не соответствует?
        If rsRaErr!rsRetnRsn = False Then
            ' да, причина возвращения не соответствует
            str = str & ". Причина возвращения, БД: <font color=""Crimson"">" & raRa.strRaReturnedReason _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exRetnRsn & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.strRaReturnedReason = rsRaErr!exRetnRsn
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.strRaReturnedReason & "</font>"
            End If
        End If
    
        ' письмо направления не соответствует?
        If rsRaErr!rsSent = False Then
            ' да, письмо направления не соответствует
            str = str & ". Письмо направления, БД: <font color=""Crimson"">" & raRa.strRaSent _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSent & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.strRaSent = rsRaErr!exSent
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.strRaSent & "</font>"
            End If
        End If
    
        ' дата письма направления не соответствует?
        If rsRaErr!rsSentDate = False Then
            ' да, дата письма направления не соответствует
            str = str & ". Дата направления, БД: <font color=""Crimson"">" & raRa.dateRaSentDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSentDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.dateRaSentDate = rsRaErr!exSentDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.dateRaSentDate & "</font>"
            End If
        End If
    
        ' организация отправитель не соответствует?
        If rsRaErr!rsSender = False Then
            ' да, организация отправитель не соответствует
            str = str & ". Отправитель, БД: <font color=""Crimson"">" & raRa.lngRaSender _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exSender & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.lngRaSender = rsRaErr!exSender
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.lngRaSender & "</font>"
            End If
        End If
    
        ' дата отчёта агента не соответствует?
        If rsRaErr!rsDate = False Then
            ' да, дата отчёта агента не соответствует
            str = str & ". Дата отчёта, БД: <font color=""Crimson"">" & raRa.dateRaDate _
                & "</font>, источник: <font color=""Peru"">" & rsRaErr!exDate & "</font>"
            If mobjParent.blnAdt_AddRA Then
                raRa.dateRaDate = rsRaErr!exDate
                str = str & ". Обновлено, БД: <font color=""SeaGreen"">" & raRa.dateRaDate & "</font>"
            End If
        End If
    
        ' суммы отчёта не соответствует?
        If rsRaErr!rsSum = False Then
            ' да, суммы отчёта не соответствует
            ' имеется сумма у отчёта?
            If Not IsNull(rsRaErr!ras_key) Then
                ' да, сумма у отчёта имеется
                ' создаём объект
                Set rasmRaSm = ClassFactory.raSmByKey(rsRaErr!ras_key, db)
                str = str & ". Суммы отчёта"
                ' *всего* не соответствует?
                If rsRaErr!rsTtl = False Then
                    str = str & ", всего, БД: <font color=""Crimson"">" & FormatCurrency(rasmRaSm.curRaSmTtl) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exTtl) & "</font>"
                End If
                ' *СМР* не соответствует?
                If rsRaErr!rsWork = False Then
                    str = str & ", СМР, БД: <font color=""Crimson"">" & FormatCurrency(rasmRaSm.curRaSmWork) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exWork) & "</font>"
                End If
                ' *Оборудование* не соответствует?
                If rsRaErr!rsEquip = False Then
                    str = str & ", Оборудование, БД: <font color=""Crimson"">" & FormatCurrency(rasmRaSm.curRaSmEquip) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exEquip) & "</font>"
                End If
                ' *Прочие* не соответствует?
                If rsRaErr!rsOthers = False Then
                    str = str & ", Прочие, БД: <font color=""Crimson"">" & FormatCurrency(rasmRaSm.curRaSmOthers) _
                        & "</font>, источник: <font color=""Peru"">" & FormatCurrency(rsRaErr!exOthers) & "</font>"
                End If
                ' ликвидируем объект
                Set rasmRaSm = Nothing
            Else
                ' нет, сумма у отчёта отсутствует
                str = str & ". Суммы отчёта, БД: <font color=""Crimson"">нет сумм</font>, источник: " _
                    & "всего: <font color=""Peru"">" & FormatCurrency(rsRaErr!exTtl) & "</font>" _
                    & ", СМР: <font color=""Peru"">" & FormatCurrency(rsRaErr!exWork) & "</font>" _
                    & ", Оборудование: <font color=""Peru"">" & FormatCurrency(rsRaErr!exEquip) & "</font>" _
                    & ", Прочие: <font color=""Peru"">" & FormatCurrency(rsRaErr!exOthers) & "</font>"
            End If
            ' нужно ли корректировать БД?
            If mobjParent.blnAdt_AddRA Then
                ' создаём объект
                Set rasmRaSm = ClassFactory.raSmCreateNew(rsRaErr!ra_key, db, rsRaErr!exTtl, rsRaErr!exWork, _
                    rsRaErr!exEquip, rsRaErr!exOthers)
                str = str & ". Обновлено, БД: " _
                    & "всего: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmTtl) & "</font>" _
                    & ", СМР: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmWork) & "</font>" _
                    & ", Оборудование: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmEquip) & "</font>" _
                    & ", Прочие: <font color=""SeaGreen"">" & FormatCurrency(rasmRaSm.curRaSmOthers) & "</font>"
                ' ликвидируем объект
                Set rasmRaSm = Nothing
            End If ' нужно ли корректировать БД?
        End If ' суммы отчёта не соответствует?
        
        ' закрываем абзац
        str = str & "</P>"
        
    End If ' имеется ли такой отчёт? Окончание.
    ' ликвидируем объект отчёта агента
    Set raRa = Nothing

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' корректируем отчёт агента по источнику. 19.07.2022. Окончание
' ***************************************************************************************************************************************************


'' отыскиваем ячейку по содержимому. 08.07.2022 ******************************************************************************************************
'Private Function CellFind( _
'    ByRef xlS As Excel.Worksheet, ByVal findStr As String, ByVal findAtXlLookAt As XlLookAt, ByRef findTextBox As TextBox, _
'    ByRef findedCell As Range, _
'    Optional ByRef findedColumn As Integer = -1, Optional ByVal startCellColumn As Integer = -1, Optional ByRef findedOffset As Integer = 0 _
'    ) As Boolean
'    ' здесь:
'    ' xlS - лист, с которым работаем, findTextBox - объект отображающий записи о ходе ревизии
'    ' -------------------------------------------------------------------------------------------------------------------------------------
'
'    Dim c As Range
'
'    Const cstrTitle As String _
'        = "Процедура *Отыскиваем ячейку по содержимому*"
'
'    '**************************************************************************************************************************************
'
'On Error GoTo ErrHandler
'
'    ' отыскиваем колонку номеров отчётов
'    Set c = xlS.UsedRange.Find(What:=findStr, LookAt:=findAtXlLookAt)
'    If Not c Is Nothing Then
'        'присваиваем возвращаемой переменной ячейки найденную ячейку
'        Set findedCell = c:
'
'        ' присваиваем возвращаемой переменной номер колонки найденной ячейки
'        If findedColumn <> -1 Then
'            findedColumn = c.Column
'        End If
'
'        If startCellColumn <> -1 Then
'            'определяем смещение от начальной ячейки до найденой
'            findedOffset = c.Column - startCellColumn
'        End If
'
'        findTextBox.value = "<P> <font color=""MediumSeaGreen"">Найдена</font> ячейка <b>" & findStr & "</b> колонка - " & c.Column & ", строка - " & c.Row & "." _
'            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & findTextBox.value
'        CellFind = True
'    Else
'        findTextBox.value = _
'        "<P> <font color=""silver"">Ячейка</font> <b>" & findStr & "</b> <B><font color=""red"">не найдена</font></B></P>" & findTextBox.value
'        CellFind = False
'    End If
'
'NormalExit:
'    Exit Function
'
'ErrHandler:
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
'
'End Function
'' отыскиваем ячейку по содержимому. 08.07.2022. Окончание *******************************************************************************************

' считываем информацию об обнаруженном отчёте агента из Excel. 08.07.2022 ***************************************************************************
Private Sub RaReadOfExcel(ra As String, ra_date As Variant, ra_Row As Integer, Constraction As String, ConstrName As String, _
    addRa As Boolean, str As String, db As DAO.Database, _
    total As Variant, work As Variant, equipment As Variant, others As Variant, _
    arrived As String, arrivedDate As Variant, arrivedDateFact As Variant, _
    returned As String, returnedDate As Variant, sent As String, sendDate As Variant, returnedReason As String, _
    ra_org_sender As String, ra_type As String)
    
    ' 08.07.2022 убрал параметр period As Integer, он был четвёртый. Вообще процедура была ReportOfAgent
    Dim rstRa_ImpNewAdd As DAO.Recordset 'набор записей для добавления записей в промежуточную табличку
    Dim raRow As Integer ' уникальный номер строки из Excel в промежуточной табличке
    Dim paragraph As String 'для формирования строчного абзаца

    ' без пробелов в начале и окончании строки, также с однообразно замененными Null и пустой строкой
    Dim ra_ As String, ra_org_sender_ As String
    Dim arrived_ As String, returned_ As String, sent_ As String, note_ As String
    Dim Constraction_ As String, ConstrName_ As String
    ' проверяемые из таблицы отчётов
    Dim arrived_r As String, returned_r As String, sent_r As String, note_r As String
    
    Dim nnn As Integer
    Dim strErrMessage As String

    Const cstrTitle As String _
        = "Класс *Ревизия отчётов агента. Проверка файла Отчётов всех агентов* " _
        & "Процедура *считываем информацию об обнаруженном отчёте агента из Excel. 08.07.2022*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    raRow = 0
    
    'очистим от пробелов в окончании и конце, также однообразно заменим Null и пустую строку ""
    ra_ = RTrim(LTrim(ra))
    
    ' подчищаем строки
    ra_org_sender_ = StringClean(ra_org_sender)
    Constraction_ = StringClean(Constraction)
    ConstrName_ = StringClean(ConstrName)
    arrived_ = StringClean(arrived): returned_ = StringClean(returned): sent_ = StringClean(sent)
    
    paragraph = "<P>  <font color=""Silver"">Найден типа: </font>*" _
        & ra_type & "*; <font color=""Silver"">имя</font>: " & ra_ & ". <font color=""Silver"">Стр</font>. - " & Constraction & "."
        
    ' нужно ли обновлять промежуточную таблицу по источнику данных?
    If mblnAf_source Then
        ' да, обновлять промежуточную таблицу по источнику данных нужно
        ' открываем набор записей для добавления
        Set rstRa_ImpNewAdd = db.OpenRecordset("ra_ImpNew", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        With rstRa_ImpNewAdd
            .AddNew
                !rainRow = ra_Row
                !rainSender = ra_org_sender_
                !rainCstAgPnStr = Constraction_
                !rainCstName = ConstrName_
                !rainRaNum = ra_
                If ra_date <> 0 Then
                    !rainRaDate = ra_date
                End If
                !rainTtl = NumericOrNull(total): !rainWork = NumericOrNull(work):
                !rainEquip = NumericOrNull(equipment): !rainOthers = NumericOrNull(others)
                ' поступило
                !rainArrivedNum = arrived_
                If arrivedDate <> 0 And Not IsNull(arrivedDate) Then
                    !rainArrivedDate = arrivedDate
                End If
                If arrivedDateFact <> 0 And Not IsNull(arrivedDateFact) Then
                    !rainArrivedDateFact = arrivedDateFact
                End If
                ' возвращено
                !rainReturnedNum = returned_
                If returnedDate <> 0 And Not IsNull(returnedDate) Then
                    !rainReturnedDate = returnedDate
                End If
                !rainReturnedReason = returnedReason
                ' отправлено
                !rainSendNum = sent_
                If sendDate <> 0 And Not IsNull(sendDate) Then
                    !rainSendDate = sendDate
                End If
                !rainSign = ra_type
            .Update
            .Bookmark = .LastModified
            raRow = !rainRow
            paragraph = paragraph & " <font color=""orange"">ОА <b>" & ra_ & "</b> от " & ra_date & _
            "</font>. Отчёт <font color=""DarkGreen"">внесен в промеж. тбл</font>. ID - " & raRow _
                & " <font color=""silver"">(номер строки листа Excel)</font>."
        End With
        ' закрываем набор записей для добавления
        rstRa_ImpNewAdd.Close: Set rstRa_ImpNewAdd = Nothing
    Else
        ' нет, обновлять промежуточную таблицу по источнику данных не нужно
    End If
    
    str = paragraph & str
    
'    rstC_A_C.Close

NormalExit:
    Set rstC_A_C = Nothing
    Exit Sub
    
ErrHandler:
    strErrMessage = "Отчёт: " & ra_ & ", строка: " & ra_Row & "." & vbCrLf _
        & Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle
    MsgBox strErrMessage, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' считываем информацию об обнаруженном отчёте агента из Excel. 08.07.2022. Окончание ****************************************************************

' если не цифра то Null. 12.07.2022
' убираем строки из цифровых полей
Private Function NumericOrNull(ByRef value As Variant) As Variant
    If IsNumeric(value) And Not IsNull(value) Then
        NumericOrNull = value
    Else
        NumericOrNull = Null
    End If
End Function

