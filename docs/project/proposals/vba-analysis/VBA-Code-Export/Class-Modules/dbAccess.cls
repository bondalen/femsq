VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "dbAccess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' объект *Работа с базой данных Access* 15.09.2022

' ###################################################################################################################################################
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' !!! не нужно их писать в других местах, это приведет к ошибке. 07.07.2022
' тип для поиска колонок Excel
Private Type findCell
    cellFinded As Boolean
    cellNum As Range
    cellNumColumn As Integer
    destination As String
End Type
' ссылка на объект #база данных Access#
Private mdbDb As DAO.Database
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' Const cstrTable As String = "ags_ipg", cstrTableKeyField As String = "ipgKey"
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' ###################################################################################################################################################



' ###################################################################################################################################################
' инициализации и реинициализации
' ***************************************************************************************************************************************************
'' обработка встроенного события инициализации
'Private Sub Class_Initialize()
'    ' инициализируем объект с нулевым ключём. В таком виде он не имеет смысла.
'    ' Требуется реинициализация.
'    ' -1 означает, что проверки наличия свойства не было. Если позже будет установлено значение свойства,
'    ' то оно будет приведено к 0 при отсутствии и к значению при наличии.
'    ' Это чтобы избежать необходимости каждый раз вычислять свойство заново
'    mlngIpgKey = -1
'End Sub
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' реинициализируем объект *Работа с базой данных Access*. 15.09.2022
' ...................................................................................................................................................
Public Sub Reinitialise(ByRef db As DAO.Database)
    ' ...............................................................................................................................................
    Dim rs As DAO.Recordset, strSql As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Реинициализируем объект #Работа с базой данных Access# по базе данных*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' инициализирована ли база данных объекта?
    If mdbDb Is Nothing Then
        ' нет, база данных объекта не инициализирована
        Set mdbDb = db ' устанавливаем ссылку на базу данных
    End If
    
NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' реинициализируем объект *Работа с базой данных Access*. 15.09.2022. Окончание
' ***************************************************************************************************************************************************
' инициализации и реинициализации. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' методы
' ***************************************************************************************************************************************************
' редактируем строковое поле. 09.08.2022
'Private Sub editFieldStr(ByVal strFieldName As String, ByVal strNew As Variant)
'
'    ClassFunc.varEditFieldStr strFieldName, strNew, cstrTable, mlngIpgKey, cstrTableKeyField, mdbDb
'
'End Sub
' редактируем строковое поле. 09.08.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' переносим набор записей из таблицы Excel в таблицу базы данных. 30.06.2022
Public Function ExcelToTable(xlS As Excel.Worksheet, ByVal strTableName As String, ByRef arrayFields() As Variant, _
    ByVal strKeyCell As String, ByVal strFindPattern As String, ByVal strKeyField As String, ByRef findTextBox As TextBox) As Boolean
    ' ...............................................................................................................................................
    Dim boRslt As Boolean
    Dim cellRaNumFinded As Boolean, cellRaNum As Range, cellRaNumColumn As Integer, arrLenght As Integer
    Dim arrayCellFind() As findCell, boolCellFinded As Boolean
    Dim rngKeyCell As Range, ra_RA As Range, str As String, fff As String
    Dim c As Range, intCountRow As Integer
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Функция *Переносим набор записей из таблицы Excel в таблицу базы данных*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
    ' заранее поставим отрицательный результат
    boRslt = False: intCountRow = 0

    ' таблица назначения успешно очищена?
    If Me.TableRecordsClear(strTableName) Then
        ' да, таблица назначения успешно очищена
        arrLenght = UBound(arrayFields)
        ReDim arrayCellFind(arrLenght - 1)
        ' проходим по массиву соответствия полей и присваиваем значения. 1 - откуда, 2 - куда
        ii = 0
        For i = LBound(arrayFields) To UBound(arrayFields)
            cellRaNumFinded = CellFind(xlS:=xlS, findStr:=arrayFields(i, 1), findAtXlLookAt:=xlWhole, findTextBox:=findTextBox, _
            findedCell:=cellRaNum, findedColumn:=cellRaNumColumn)
            
            arrayCellFind(ii).cellFinded = cellRaNumFinded
            Set arrayCellFind(ii).cellNum = cellRaNum
            arrayCellFind(ii).cellNumColumn = cellRaNumColumn
            arrayCellFind(ii).destination = arrayFields(i, 2)
            
            If cellRaNum.value = strKeyCell Then
                Set rngKeyCell = cellRaNum
            End If
            
            ii = ii + 1
        Next i
        
        ' проверяем нахождение всех колонок
        boolCellFinded = True
        For i = LBound(arrayCellFind) To UBound(arrayCellFind)
            If Not arrayCellFind(i).cellFinded Then
                boolCellFinded = False
            End If
        Next i
        
        ' все ли колонки найдены?
        If boolCellFinded Then
            ' да, все колонки найдены
            ' определяем диапазон отчётов до нижней ячейки
            Set ra_RA = xlS.Range( _
                xlS.Cells(rngKeyCell.Offset(1, 0).Row, rngKeyCell.Column), _
                xlS.Cells( _
                    xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                    xlS.Cells(rngKeyCell.Offset(1, 0).Row, rngKeyCell.Column).Column _
                    ) _
                )
            
            ' имеется ли диапазон отчётов?
            If Not ra_RA Is Nothing Then
                ' да, диапазон отчётов имеется
                ' проходим по отчётам
                fff = "<P>  <font color=""gray"">Найден диапазон</font> <font color=""blue"">*Отчёты обычные*</font>, колонка - " _
                    & ra_RA.Column & ", первая строка - " & ra_RA.Row & ", " _
                    & "нижняя строка - " & ra_RA.Row + ra_RA.Rows.count - 1 & ". Адрес: <font color=""blue"">" & ra_RA.Address & "</font>.</P>" & fff

                With ra_RA

                    ' количество ячеек в диапазоне больше одной?
                    If .count > 1 Then
                        ' да, количество ячеек в диапазоне больше одной
                        ' ищем собственно отчёт
                        Set c = .Find(what:=strFindPattern, LookAt:=xlPart)
                        ' имеется ли имя соответствующее форме имени отчёта?
                        If Not c Is Nothing Then
                            ' да имя соответствующее форме имени отчёта имеется
                            ' простой отчет нашелся в колонке имен отчётов?
                            If c.Column = rngKeyCell.Column Then
                                ' да, простой отчёт нашелся в колонке имен отчётов
                                adr = c.Address
                                
                                If (Not IsEmpty(c.value)) And (Not Left(c.Formula, 1) = "=") Then
                                    If ExcelRowToDataBaseTable(arrayCellFind, c, rngKeyCell, strTableName, strKeyField) Then
                                        intCountRow = intCountRow + 1
                                    End If
                                End If
                            Else
                                ' нет, простой отчёт нашелся не в колонке имен отчётов
                                str = "<P>  В столбце ячейки номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. Отчёт нашелся не в колонке имен отчётов</P>"
                                GoTo NotRA 'Exit Sub
                            End If
                        Else
                            ' нет имя соответствующее форме имени отчёта отсутствует
                            str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                            GoTo NotRA 'Exit Sub
                        End If
                        Do
                            Set c = .FindNext(c)
                            If (Not c.Address = adr) And (c.Column = rngKeyCell.Column) Then
                                If (Not IsEmpty(c.value)) And (Not Left(c.Formula, 1) = "=") Then
                                    If ExcelRowToDataBaseTable(arrayCellFind, c, rngKeyCell, strTableName, strKeyField) Then
                                        intCountRow = intCountRow + 1
                                    End If
                                End If
                            End If
                        Loop Until c.Address = adr
                        Else
                        ' нет, количество ячеек в диапазоне не больше одной
                        ' ищем собственно отчёт
                        Set c = .Find(what:=strFindPattern, LookAt:=xlPart)
                        ' имеется ли имя соответствующее форме имени отчёта?
                        If Not c Is Nothing Then
                            ' да имя соответствующее форме имени отчёта имеется
                            ' простой отчет нашелся в колонке имен отчётов?
                            If c.Column = rngKeyCell.Column Then
                            ' да, простой отчёт нашелся в колонке имен отчётов
                                adr = c.Address
                                If (Not IsEmpty(c.value)) And (Not Left(c.Formula, 1) = "=") Then
                                    If ExcelRowToDataBaseTable(arrayCellFind, c, rngKeyCell, strTableName, strKeyField) Then
                                        intCountRow = intCountRow + 1
                                    End If
                                End If
                            Else
                                ' нет, простой отчёт нашелся не в колонке имен отчётов
                                str = "<P>  <font color=""silver"">В столбце ячейки номеров</font> обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. Простой отчёт нашелся не в колонке имен отчётов</P>"
                            End If
                            Else
                            ' нет имя соответствующее форме имени отчёта отсутствует
                            str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                        End If
                    End If ' здесь проверка на количество ячеек в диапазоне
                    boRslt = True
    ' метка для продолжения в случае отсутствия отчётов
NotRA:

                End With
                fff = str & fff & findTextBox.value: str = ""
                findTextBox.value = fff
                findTextBox.value = "<P><font color=""green"">Перенесено</font> строк: " & intCountRow & ".</P>" & findTextBox.value
            End If ' да, диапазон отчётов имеется
            
        Else
            ' нет, не все колонки найдены
        End If
        
        
    End If ' да, таблица назначения успешно очищена. Окончание
    
    ExcelToTable = boRslt
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Function
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Function
' переносим набор записей из таблицы Excel в таблицу базы данных. 30.06.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' внутренняя функция *Переносим строку из таблицы Excel в таблицу базы данных*. 03.07.2023
Private Function ExcelRowToDataBaseTable(ByRef arrayCellFind() As findCell, ByRef c As Range, ByRef rngKeyCell As Range, _
    ByVal strTableName As String, ByVal strKeyField As String) As Boolean
    ' ...............................................................................................................................................
    Dim boRslt As Boolean, findCellCurrent As findCell, intOffset As Integer, findedCell As Range, rs As DAO.Recordset
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Функция *Переносим строку из таблицы Excel в таблицу базы данных*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
    ' заранее поставим отрицательный результат
    boRslt = False
    
    Set rs = mdbDb.OpenRecordset(strTableName, dbOpenDynaset, dbSeeChanges)
    ' заготавливаем создаваемую строку
    rs.AddNew
        ' oafptKey oafptOafName oafptOafDate oafptPnCstAgPn oafptTtl oafptArrivedNum oafptArrivedDate oafptUnit
        rs.Fields(strKeyField).value = c.Row
        ' проходим по массиву полей и присваиваем значения. 1 - откуда, 2 - куда
        For i = LBound(arrayCellFind) To UBound(arrayCellFind)
            findCellCurrent = arrayCellFind(i)
            ' опеределяем смещение
            intOffset = findCellCurrent.cellNumColumn - rngKeyCell.Column
            ' получаем искомую ячейку
            Set findedCell = c.Offset(0, intOffset)
            ' записываем значение искомой ячейки в поле создаваемой строки oafptOafSender
            rs.Fields(findCellCurrent.destination).value = findedCell.value
        Next i
    ' вносим создаваемую строку в базу данных
    rs.Update
    rs.Bookmark = rs.LastModified
    boRslt = True
    rs.Close: Set rs = Nothing

    ExcelRowToDataBaseTable = boRslt
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Function
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle _
    & vbCrLf & "Где строка " & c.Row & ", колонка " & findCellCurrent.cellNumColumn & ", для *" & findCellCurrent.cellNum & "*" _
    , vbExclamation, cstrTitle:
    Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Function
' внутренняя функция *Переносим строку из таблицы Excel в таблицу базы данных*. 03.07.2023. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' переносим набор записей от сервера в таблицу. 15.09.2022
Public Function SqlSrvRecordsetToTable(ByVal strSqlToSrv As String, ByVal strTableName As String, ByRef arrayFields() As Variant) As Boolean
    
    Dim rsTable As DAO.Recordset, rsSqlServer As DAO.Recordset
    Dim boRslt As Boolean
    
    ' заранее поставим отрицательный результат
    boRslt = False
    
    ' таблица назначения успешно очищена?
    If Me.TableRecordsClear(strTableName) Then
        ' да, таблица назначения успешно очищена
        ' получаем набор записей от сервера по строке SQL. Имеются записи в полученном наборе?
        If Me.SqlSrvRecordsetBySqlString(strSqlToSrv, rsSqlServer) > 0 Then
            ' да, записи в полученном наборе имеются
            ' открываем на редактирование рекордсет формируемой таблицы
            Set rsTable = mdbDb.OpenRecordset(strTableName, dbOpenDynaset)
            
            With rsSqlServer
                Do Until .EOF = True
                
                    'собственно присваиваем
                    rsTable.AddNew
                        
                        ' проходим по массиву соответствия полей и присваиваем значения. 1 - откуда, 2 - куда
                        For i = LBound(arrayFields) To UBound(arrayFields)
                            rsTable.Fields(arrayFields(i, 2)).value = .Fields(arrayFields(i, 1)).value
                        Next i
                        
                    ' обновляем набор записей
                    rsTable.Update
                    rsTable.Bookmark = rsTable.LastModified
                    'идем к следующей записи
                    .MoveNext
                Loop
            End With
            rsTable.Close: Set rsTable = Nothing
            
            ' поставим положительный результат
            boRslt = True
            
        End If ' да, записи в полученном наборе имеются. Окончание
        ' если имеется набор данных от сервера, то закрываем его
        If Not rsSqlServer Is Nothing Then
            rsSqlServer.Close: Set rsSqlServer = Nothing
        End If
        
    End If ' да, таблица назначения успешно очищена. Окончание
    
    SqlSrvRecordsetToTable = boRslt

End Function
' переносим набор записей от сервера в таблицу. 15.09.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' переносим набор записей от сервера в таблицу через *набор записей ADODB*. 01.11.2024
Public Function SqlSrvRecordsetADODB_toTable(ByRef adoRst As ADODB.Recordset, ByVal strTableName As String, _
    ByRef arrayFields() As Variant) As Boolean
    
    Dim rsTable As DAO.Recordset ', rsSqlServer As DAO.Recordset
    Dim boRslt As Boolean
    
    ' заранее поставим отрицательный результат
    boRslt = False
    
    ' таблица назначения успешно очищена?
    If Me.TableRecordsClear(strTableName) Then
        ' да, таблица назначения успешно очищена
        ' Имеются записи в полученном наборе записей?
        If adoRst.RecordCount <> 0 Then
            ' да, записи в полученном наборе имеются
            ' открываем на редактирование рекордсет формируемой таблицы
            Set rsTable = mdbDb.OpenRecordset(strTableName, dbOpenDynaset)
            
            With adoRst
                Do Until .EOF = True
                
                    'собственно присваиваем
                    rsTable.AddNew
                        
                        ' проходим по массиву соответствия полей и присваиваем значения. 1 - откуда, 2 - куда
                        For i = LBound(arrayFields) To UBound(arrayFields)
'                            Debug.Print "2 -> " & arrayFields(i, 2) & ": 1 -> " & arrayFields(i, 1) & ";"
                            rsTable.Fields(arrayFields(i, 2)).value = .Fields(arrayFields(i, 1)).value
                        Next i
                        
                    ' обновляем набор записей
                    rsTable.Update
                    rsTable.Bookmark = rsTable.LastModified
                    'идем к следующей записи
                    .MoveNext
                Loop
            End With
            rsTable.Close: Set rsTable = Nothing
            
            ' поставим положительный результат
            boRslt = True

        End If ' да, записи в полученном наборе имеются. Окончание

    End If ' да, таблица назначения успешно очищена. Окончание
    
    SqlSrvRecordsetADODB_toTable = boRslt

End Function
' переносим набор записей от сервера в таблицу через *набор записей ADODB*. 01.11.2024. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' получаем набор записей от сервера по строке SQL. 15.09.2022
' даём в эту функцию свой рекордсет, она нам его открывает, получая данные c SQL сервера, и возвращает количество строк в нём
Public Function SqlSrvRecordsetBySqlString(ByVal strSql As String, ByRef rstSqlSrv As DAO.Recordset) As Long
    
    Dim lgRslt As Long
    Dim qd As DAO.QueryDef

    'получаем набор записей от сервера путём создания временного запроса
    Set qd = mdbDb.CreateQueryDef("")
    qd.Connect = mdbDb.TableDefs("ags_yyyy").Connect
    qd.SQL = strSql
    qd.ReturnsRecords = True
    qd.ODBCTimeout = 600
    
    Set rstSqlSrv = qd.OpenRecordset(dbOpenSnapshot)
    rstSqlSrv.MoveLast
    lgRslt = rstSqlSrv.RecordCount
    rstSqlSrv.MoveFirst
    
    SqlSrvRecordsetBySqlString = lgRslt
    
End Function
' получаем набор записей от сервера по строке SQL. 15.09.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' очищаем таблицу от данных. 15.09.2022
Public Function TableRecordsClear(ByVal tableName As String) As Boolean
    
    Dim boRslt As Boolean
    Dim qd As DAO.QueryDef, strSql As String

    ' заранее установим неудачный результат очистки
    boRslt = False
    
    ' имеется ли таблица в базе данных?
    If DCount("[Name]", "MSysObjects", "[Name] = '" & tableName & "'") = 1 Then
        ' да, таблица в базе данных имеется
        'очищаем таблицу
        strSql = "DELETE * FROM [" & tableName & "]"
        Set qd = mdbDb.CreateQueryDef("", strSql)
        qd.Execute dbFailOnError
        qd.Close
        Set qd = Nothing
        ' установим удачный результат очистки
        boRslt = True
    End If
    
    TableRecordsClear = boRslt
    
End Function
' очищаем таблицу от данных. 15.09.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' получаем новое подключение ADODB. 01.11.2024
Public Function GetNewADODBConnection() As ADODB.Connection
    Dim oCn As New ADODB.Connection
    Dim sCnStr As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Функция *Получаем новое подключение ADODB*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
  
    sCnStr = "Provider='SQLOLEDB';Data Source='SPB-05-NV-SQL1';" & _
            "Integrated Security='SSPI';Initial Catalog='FishEye';"
    oCn.Open sCnStr
  
    If oCn.State = adStateOpen Then
        Set GetNewADODBConnection = oCn
    End If
  
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Function
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Function
' получаем новое подключение ADODB. 01.11.2024. Окончание
' ***************************************************************************************************************************************************

' методы. Окончание
' ###################################################################################################################################################

