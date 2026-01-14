VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipg>LdM_t"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

' по нажатию кнопки просматриваем или загружаем файлы уточнённых планов
Private Sub btnLoad_Click()

    Dim dStart As Date, dFinish As Date
    Dim db As DAO.Database, rsF As DAO.Recordset, strSql As String, strFFF As String
    Dim xlA As Excel.Application, xlW As Excel.Workbook, xlS As Excel.Worksheet
    Dim rsFindCst As DAO.Recordset ' таблица найденных строек для добавления

    Const cstrTitle As String _
        = "Процедура *По нажатию кнопки просматриваем или загружаем файлы уточнённых планов"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

'  ли идентификатор загрузки?
If IsNull(Me!ldmKey) = False Then
    ' да, идентификатор загрузки имеется
    Me!ldmText = "": dStart = DateTime.Now
    
    Me!ldmText = "<P>Начало проведения загрузки *<B><font color=""DarkGoldenrod"">" & Me!ldmName & "</font></B>*.</P>" _
    & "<P><B>" & dStart & "</B> - Время начала проведения загрузки.</P>"
    
    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------
    
    ' пройдём по файлам загрузки
    strSql = "SELECT * FROM ipgLdM_f WHERE ldmfLdM = " & Me!ldmKey & ";"
    ' открываем набор данных файлов загрузки
    Set rsF = db.OpenRecordset(strSql, dbOpenSnapshot)
    ' имеются ли записи файлов загрузки?
    If rsF.RecordCount > 0 Then
        ' да, записи файлов загрузки имеются
        ' открываем приложение
        Set xlA = CreateObject("Excel.Application")
        
        Me!ldmText = "<P>" & DateTime.Now & " - *<b><font color=""green"">" & "Приложение Excel открыто" & "</font>*</b></P>" & Me!ldmText
        
        ' очищаем таблицу найденных строек
        strSql = "DELETE * FROM ipgLdm_fShCst": Set qd = db.CreateQueryDef("", strSql): qd.Execute dbFailOnError
        qd.Close: Set qd = Nothing
        
        ' открываем таблицу найденных строек для добавления
        Set rsFindCst = db.OpenRecordset("ipgLdm_fShCst", dbOpenDynaset)

        ' проходим по каждой записи файла
        rsF.MoveFirst
        Do Until rsF.EOF = True
            Me!ldmText = "<p><font color=""silver"">Рассматриваем файл <font color=""Brown""><b>" & rsF!ldmfFile & "</b></font>.</font></p>" & Me!ldmText
            
            ' подлежит ли текущий файл рассмотрению?
            If rsF!ldmfSee Then
                ' да, текущий файл подлежит рассмотрению
                Set fsof = CreateObject("Scripting.FileSystemObject")
                If (fsof.FileExists(rsF!ldmfFile)) Then
                    'да, файл существует
                    Me!ldmText = "<P>" & DateTime.Now & " - Файл с именем *" & rsF!ldmfFile _
                        & "* в файловой системе обнаружен</P>" & Me!ldmText
                        
                        'открываем файл
                        Set xlW = xlA.Workbooks.Open(filename:=rsF!ldmfFile, ReadOnly:=True, UpdateLinks:=0)
                            
                        Me!ldmText = "<P>" & DateTime.Now & " - Файл с именем *<font color=""green"">" & rsF!ldmfFile _
                        & "</font>* в приложении открыт</P>" & Me!ldmText
                        
                        ' вызываем процедуру работы с листом
                        LoadWorkbook db, xlW, rsF!ldmfSheet, rsF!ldmfKey, rsFindCst, rsF!ldmfUtPlKey, _
                            rsF!ldmfLimColumn, rsF!ldmfQuarter, rsF!ldmfSumFirst, Me!ldmText, Me!ldmUpdate
                        
                        'закрываем файл
                        xlW.Close SaveChanges:=False: Set xlW = Nothing
                        
                        Me!ldmText = "<P>" & DateTime.Now & " - Файл с именем *<font color=""blue"">" & rsF!ldmfFile _
                        & "</font>* в приложении закрыт</P>" & Me!ldmText
                                    
                    Else
                    'нет, файл не существует
                    Me!ldmText = "<P>Файл с именем *<B><font color=""red"">" & rsF!ldmfFile _
                        & "</font></B>* в файловой системе не обнаружен</P>" & Me!ldmText
                End If
                Else
                ' нет, текущий файл не подлежит рассмотрению
                Me!ldmText = "<P><font color=""silver"">Файл с именем *</font><B><font color=""slateblue"">" & rsF!ldmfFile _
                    & "</font></B><font color=""silver"">* рассмотрению, в соответствии с Вашим выбором, </font>" _
                    & "<font color=""salmon"">не подлежит</font>.</P>" & Me!ldmText
            End If
            
            'Me!ldmText = strFFF & Me!ldmText
            rsF.MoveNext
        Loop
        
        ' закрываем таблицу найденных строек для добавления
        rsFindCst.Close: Set rsFindCst = Nothing
        
        'закрываем приложение без сохранения книг
        xlA.Quit: Set xlA = Nothing
        
        Me!ldmText = "<P>" & DateTime.Now & " - *<B><font color=""blue"">" & "Приложение Excel закрыто" & "</font></B>*</P>" _
        & Me!ldmText
        
        Else
        ' нет, записи файлов загрузки отсутствуют
        Me!ldmText = "<p>В БД <font color=""Salmon"">записи файлов загрузки отсутствуют</font></p>" & Me!ldmText
    End If
    
    ' закрываем набор данных файлов загрузки
    rsF.Close: Set rsF = Nothing
    
    db.Close 'закрываем переменную базы данных -------------------------------------------------------------

    dFinish = DateTime.Now: dDateDiff = DateDiff("s", dStart, dFinish)

    Me!ldmText = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "загрузка завершена" _
    & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
    & dDateDiff & " сек.).</P>" & Me!ldmText
    
    'Me![ra_a>Ttl_t].Requery
    
    Else
    ' нет, идентификатор загрузки отсутствует
    MsgBox ("Отсутствует идентификатор загрузки")

End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' загружаем файл (рабочую книгу) уточненного плана
Private Sub LoadWorkbook(ByRef db As DAO.Database, ByRef xlW As Excel.Workbook, ByVal WorkSheetName As String, _
    ByVal WorkSheetKey As Integer, ByRef rsFindCst As DAO.Recordset, ByVal ldmfUtPlKey As Integer, _
    ByVal ldmfLimColumn As String, ByVal ldmfQuarter As Boolean, ByVal ldmfSumFirst As Integer, ByRef TextFieldObj As Object, ByVal Update As Boolean)
    ' ldmfQuarter - наличие квартальных сумм
    ' ldmfSumFirst - смещение первой суммы от колонки общего лимита
    ' ldmfUtPlKey - ключ уточнённого плана

    Dim xlS As Excel.Worksheet
    Dim c As Range, loadRange As Range, adr As String, dd As Range, ddOffset As Integer
    Dim cCst As Range, iii As Integer, eee As String
    Dim rsShRange As DAO.Recordset, strSql As String, SchemeKey As Integer, CostIts As Integer
    Dim rsCstStart As DAO.Recordset, startNext As Integer, cstapKey As Long, strFFF As String
    Dim rsIuplpEdit As DAO.Recordset
    
    Const cstrTitle As String _
        = "Процедура *~Загружаем файл (рабочую книгу) уточненного плана~*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    TextFieldObj = "<p> <font color=""silver"">Отыскиваем лист: <font color=""CadetBlue"">" & WorkSheetName & "</font>.</font></p>" & TextFieldObj
    
    ' имеется ли требуемый лист? ====================================================================================================================
    If WorksheetIsExist(xlW, WorkSheetName) Then
        ' да, требуемый лист имеется
        ' открываем существующий лист
        Set xlS = xlW.Worksheets(WorkSheetName)
        
        TextFieldObj = "<P> <font color=""silver"">Лист <font color=""Teal"">" & WorkSheetName & " <b>обнаружен</b>" & "</font> в книге</font></P>" & TextFieldObj
        
        ' снимаем фильтры листа, если есть
        If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
            xlS.ShowAllData
        End If
        
        ' отыскиваем ячейку "Код стройки" Код объекта/стройки Код объекта (ИУС)
        Set c = xlS.UsedRange.Find(what:="Код стройки", LookAt:=xlPart)
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Код", LookAt:=xlWhole)
        End If
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Код ИП", LookAt:=xlWhole)
        End If
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Код объекта/стройки", LookAt:=xlPart)
        End If
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Код объекта (ИУС)", LookAt:=xlPart)
        End If

        
        ' отыскиваем ячейку "основной лимит"
        Set dd = xlS.UsedRange.Find(what:=ldmfLimColumn, LookAt:=xlPart)
        
        ' итог поисков ячейки "Код стройки"
        If Not c Is Nothing And Not dd Is Nothing Then
            ' ячейка "Код стройки" найдена
            TextFieldObj = "<P> <font color=""silver"">Найдена ячейка <b>*Код стройки (код)*</b> колонка - " & c.Column & ", строка - " & c.Row & "." _
                & " Содержание: <font color=""blue"">" & c & "</font>. И лимит тоже найден.</font></P>" & TextFieldObj
                
            ddOffset = dd.Column - c.Column
                
            ' проходим по диапазонам соответствующим схемам реализации инвестпроектов
            strSql = "SELECT * FROM ipgLdm_fSh INNER JOIN ags_ipgSh ON ipgLdm_fSh.ldmfsScheme = ags_ipgSh.ipgsKey " _
                & "WHERE ipgLdm_fSh.ldmfsFile=" & WorkSheetKey
            Set rsShRange = db.OpenRecordset(strSql, dbOpenSnapshot)
            ' имеются ли диапазоны соответствующим схемам реализации инвестпроектов?
            If rsShRange.RecordCount > 0 Then
                ' да, диапазоны соответствующим схемам реализации инвестпроектов имеются
                ' проходим по найденным диапазонам --------------------------------------------------------------------------------------------------
                rsShRange.MoveFirst
                Do Until rsShRange.EOF
                    SchemeKey = rsShRange!ldmfsScheme
                    TextFieldObj = "<P> <font color=""silver"">Диапазон № <font color=""CadetBlue""><b>" & rsShRange!ldmfsNum _
                        & "</b>" & "</font>, схема: <font color=""DarkGoldenrod""><b>" & rsShRange!ipgsNm & "</b></font></font></P>" & TextFieldObj
                    
                    ' определяем диапазон файла загрузки в виде колонки для поиска номеров строек
                    Set loadRange = xlS.Range _
                        ( _
                            xlS.Cells(rsShRange!ldmfsStart, c.Column), _
                            xlS.Cells( _
                                rsShRange!ldmfsEnd, _
                                c.Column _
                                ) _
                        )
                        
                    ' проходим по колонке для поиска номеров строек +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    ' имется ли диапазон файла загрузки в виде колонки для поиска номеров строек?
                    If Not loadRange Is Nothing Then
                        ' да, диапазон файла загрузки в виде колонки для поиска номеров строек имеется
                        With loadRange
                            ' количество ячеек в диапазоне больше одной?
                            If .count > 1 Then
                                ' да, количество ячеек в диапазоне больше одной
                                ' ищем собственно стройку
                                Set cCst = .Find(what:="???-???????", LookAt:=xlWhole) ' Find ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                ' имеется ли имя соответствующее форме имя стройки?
                                If Not cCst Is Nothing Then
                                    ' фиксируем адрес первой найденной ячейки со стройкой
                                    adr = cCst.Address: iii = 1: eee = Left(cCst.Offset(0, 1), 20)
                                    
                                    LoadCst db, xlS, cCst, ddOffset, iii, eee, rsFindCst, SchemeKey, rsShRange!ldmfsKey, _
                                        ldmfUtPlKey, ldmfQuarter, ldmfSumFirst, strFFF
                                        
                                    TextFieldObj = strFFF & TextFieldObj: strFFF = ""
                                    Do ' повторно :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                        Set cCst = .FindNext(cCst)
                                        ' адрес вновь найденной стройки не равен ли зафиксированному адресу первой стройки?
                                        If (Not cCst.Address = adr) Then
                                            ' да, адрес вновь найденной стройки не равен зафиксированному адресу первой стройки
                                            iii = iii + 1: eee = Left(cCst.Offset(0, 1), 20)
                                            
                                            LoadCst db, xlS, cCst, ddOffset, iii, eee, rsFindCst, SchemeKey, rsShRange!ldmfsKey, _
                                                ldmfUtPlKey, ldmfQuarter, ldmfSumFirst, strFFF
                                                
                                            TextFieldObj = strFFF & TextFieldObj: strFFF = ""
                                        End If
                                    Loop Until cCst.Address = adr ' повторно, окончание :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                                    Else
                                    TextFieldObj = "<P>  <font color=""silver"">В диапазоне</font> *коды строек* " _
                                        & "<font color=""Salmon""><b>не найдены</b></font>.</P>" & TextFieldObj
                                End If  ' Find, окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                Else
                                ' нет, количество ячеек в диапазоне не больше одной
                            End If ' здесь проверка на количество ячеек в диапазоне
                        End With
                        Else
                        ' нет, диапазон файла загрузки в виде колонки для поиска номеров строек отсутствует
                        TextFieldObj = "<P>  <font color=""silver"">Диапазон</font> *колонка для поиска номеров строек* <font color=""red"">не найден</font>.</P>" _
                            & TextFieldObj
                    End If ' проходим по колонке для поиска номеров строек, окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    
                    ' определяем номера строк окончания диапазонов строек +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    ' проходим по перечню найденных строек, отсортированному по возрастанию начала диапазона
                    strSql = "SELECT idmfscCst, ldmfscScheme, ldmfscStart,ldmfscEnd, ldmfsc_fSh, ldmfscCstAgPn FROM ipgLdm_fShCst " _
                        & "WHERE ldmfsc_fSh = " & rsShRange!ldmfsKey & " ORDER BY ldmfscStart"
                    Set rsCstStart = db.OpenRecordset(strSql, dbOpenDynaset)
                    ' имеются ли стройки в табличке найденных строек для этого диапазона?
                    If rsCstStart.RecordCount > 0 Then
                        ' да, стройки в табличке найденных строек для этого диапазона имеются
                        rsCstStart.MoveLast
                        TextFieldObj = "<P>  <font color=""silver"">Строек</font> в табличке найденных строек: <font color=""CadetBlue"">" _
                            & rsCstStart.RecordCount & "</font>.</P>" _
                            & TextFieldObj
                        ' проходим по перечню найденных строек
                        rsCstStart.MoveFirst
                        Do Until rsCstStart.EOF
                            ' отыскиваем начало следующего диапазона стройки
                            strSql = "SELECT Min(z.ldmfscStart) AS rowMin FROM (SELECT idmfscCst, ldmfscScheme, ldmfscStart, ldmfscEnd, ldmfsc_fSh " _
                                & "FROM ipgLdm_fShCst " _
                                & "WHERE ldmfscStart > " & rsCstStart!ldmfscStart & " And ldmfsc_fSh = " & rsShRange!ldmfsKey & " " _
                                & "ORDER BY ldmfscStart) AS z;"
                            ' имеется ли номмер строки начала следующего диапазона стройки?
                            If FindOneKey(db:=db, StringFindSv:=strSql, KeyFieldName:="rowMin", key:=startNext, dbKind:="Access") Then
                                ' да, номмер строки начала следующего диапазона стройки имеется
                                startNext = startNext - 1
                                Else
                                ' нет, номмер строки начала следующего диапазона стройки отсутствует
                                startNext = rsShRange!ldmfsEnd
                            End If
                            ' обновляем номер строки окончания диапазона текущей стройки и ключ стройки
                            rsCstStart.Edit
                                ' обновляем номер строки окончания диапазона текущей стройки
                                rsCstStart!ldmfscEnd = startNext
                                ' обновляем ключ стройки
                                If FindCstAP(rsCstStart!idmfscCst, cstapKey, db) Then
                                    rsCstStart!ldmfscCstAgPn = cstapKey
                                End If
                            rsCstStart.Update
                            ' переходим к следующей стройке
                            rsCstStart.MoveNext
                        Loop
                        Else
                        ' нет, стройки в табличке найденных строек для этого диапазона отсутствуют
                        TextFieldObj = "<P>  <font color=""silver"">Стройки</font> в <font color=""IndianRed""><b>табличке</b></font> найденных строек " _
                            & "<font color=""red"">не найдены</font>.</P>" & TextFieldObj
                    End If
                    rsCstStart.Close: Set rsCstStart = Nothing
                    ' определяем номера строк окончания диапазонов строек, окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    
                    ' проходим по стройкам текущего диапазона в запросе найденных строек и делаем выводы по их соответствию БД ++++++++++++++++++++++
                    
                    strSql = "SELECT z.ldmfsc_fSh, z.ldmfscScheme, z.ldmfscStart, z.ldmfscEnd, z.idmfscCst, z.ldmfscCstAgPn, " _
                        & "z.ldmIpg, z.ldmfUtPlKey, z.ipgpKeyCount, z.ipgpKey, y.iuplpKey, " _
                        & "z.ldmfscLim AS limYeDoc, y.iuplpLim AS limYeDB, " _
                        & "IIf(IsNull(limYeDoc) And IsNull(limYeDB),Null,IIf(IsNull(limYeDoc),0,limYeDoc)-IIf(IsNull(limYeDB),0,limYeDB)) AS limYeDiff, " _
                        & "z.ldmfscLimQu1 AS limQu1doc, y.iuplpQ1 AS limQu1db, " _
                        & "IIf(IsNull(limQu1doc) And IsNull(limQu1db),Null,IIf(IsNull(limQu1doc),0,limQu1doc)-IIf(IsNull(limQu1db),0,limQu1db)) AS limQu1Diff, "
                        
                     strSql = strSql _
                        & "z.ldmfscLimMn1 AS limMn1Doc, y.iuplpM01 AS limMn1DB, " _
                        & "IIf(IsNull(limMn1Doc) And IsNull(limMn1DB),Null,IIf(IsNull(limMn1Doc),0,limMn1Doc)-IIf(IsNull(limMn1DB),0,limMn1DB)) AS limMn1Diff, " _
                        & "z.ldmfscLimMn2 AS limMn2Doc, y.iuplpM02 AS limMn2DB, " _
                        & "IIf(IsNull(limMn2Doc) And IsNull(limMn2DB),Null,IIf(IsNull(limMn2Doc),0,limMn2Doc)-IIf(IsNull(limMn2DB),0,limMn2DB)) AS limMn2Diff, " _
                        & "z.ldmfscLimMn3 AS limMn3Doc, y.iuplpM03 AS limMn3DB, " _
                        & "IIf(IsNull(limMn3Doc) And IsNull(limMn3DB),Null,IIf(IsNull(limMn3Doc),0,limMn3Doc)-IIf(IsNull(limMn3DB),0,limMn3DB)) AS limMn3Diff, "

                    strSql = strSql _
                        & "z.ldmfscLimQu2 AS limQu2doc, y.iuplpQ2 AS limQu2db, " _
                        & "IIf(IsNull(limQu2doc) And IsNull(limQu2db),Null,IIf(IsNull(limQu2doc),0,limQu2doc)-IIf(IsNull(limQu2db),0,limQu2db)) AS limQu2Diff, " _
                        & "z.ldmfscLimMn4 AS limMn4Doc, y.iuplpM04 AS limMn4DB, " _
                        & "IIf(IsNull(limMn4Doc) And IsNull(limMn4DB),Null,IIf(IsNull(limMn4Doc),0,limMn4Doc)-IIf(IsNull(limMn4DB),0,limMn4DB)) AS limMn4Diff, " _
                        & "z.ldmfscLimMn5 AS limMn5Doc, y.iuplpM05 AS limMn5DB, " _
                        & "IIf(IsNull(limMn5Doc) And IsNull(limMn5DB),Null,IIf(IsNull(limMn5Doc),0,limMn5Doc)-IIf(IsNull(limMn5DB),0,limMn5DB)) AS limMn5Diff, " _
                        & "z.ldmfscLimMn6 AS limMn6Doc, y.iuplpM06 AS limMn6DB, " _
                        & "IIf(IsNull(limMn6Doc) And IsNull(limMn6DB),Null,IIf(IsNull(limMn6Doc),0,limMn6Doc)-IIf(IsNull(limMn6DB),0,limMn6DB)) AS limMn6Diff, "

                    strSql = strSql _
                        & "z.ldmfscLimQu3 AS limQu3doc, y.iuplpQ3 AS limQu3db, " _
                        & "IIf(IsNull(limQu3doc) And IsNull(limQu3db),Null,IIf(IsNull(limQu3doc),0,limQu3doc)-IIf(IsNull(limQu3db),0,limQu3db)) AS limQu3Diff, " _
                        & "z.ldmfscLimMn7 AS limMn7Doc, y.iuplpM07 AS limMn7DB, " _
                        & "IIf(IsNull(limMn7Doc) And IsNull(limMn7DB),Null,IIf(IsNull(limMn7Doc),0,limMn7Doc)-IIf(IsNull(limMn7DB),0,limMn7DB)) AS limMn7Diff, " _
                        & "z.ldmfscLimMn8 AS limMn8Doc, y.iuplpM08 AS limMn8DB, " _
                        & "IIf(IsNull(limMn8Doc) And IsNull(limMn8DB),Null,IIf(IsNull(limMn8Doc),0,limMn8Doc)-IIf(IsNull(limMn8DB),0,limMn8DB)) AS limMn8Diff, " _
                        & "z.ldmfscLimMn9 AS limMn9Doc, y.iuplpM09 AS limMn9DB, " _
                        & "IIf(IsNull(limMn9Doc) And IsNull(limMn9DB),Null,IIf(IsNull(limMn9Doc),0,limMn9Doc)-IIf(IsNull(limMn9DB),0,limMn9DB)) AS limMn9Diff, "

                    strSql = strSql _
                        & "z.ldmfscLimQu4 AS limQu4doc, y.iuplpQ4 AS limQu4db, " _
                        & "IIf(IsNull(limQu4doc) And IsNull(limQu4db),Null,IIf(IsNull(limQu4doc),0,limQu4doc)-IIf(IsNull(limQu4db),0,limQu4db)) AS limQu4Diff, " _
                        & "z.ldmfscLimMn10 AS limMn10Doc, y.iuplpM10 AS limMn10DB, " _
                        & "IIf(IsNull(limMn10Doc) And IsNull(limMn10DB),Null,IIf(IsNull(limMn10Doc),0,limMn10Doc)-IIf(IsNull(limMn10DB),0,limMn10DB)) AS limMn10Diff, " _
                        & "z.ldmfscLimMn11 AS limMn11Doc, y.iuplpM11 AS limMn11DB, " _
                        & "IIf(IsNull(limMn11Doc) And IsNull(limMn11DB),Null,IIf(IsNull(limMn11Doc),0,limMn11Doc)-IIf(IsNull(limMn11DB),0,limMn11DB)) AS limMn11Diff, " _
                        & "z.ldmfscLimMn12 AS limMn12Doc, y.iuplpM12 AS limMn12DB, " _
                        & "IIf(IsNull(limMn12Doc) And IsNull(limMn12DB),Null,IIf(IsNull(limMn12Doc),0,limMn12Doc)-IIf(IsNull(limMn12DB),0,limMn12DB)) AS limMn12Diff, p.ipgpSh " _

                    strSql = strSql _
                        & "FROM ((SELECT a.ldmfsc_fSh, a.ldmfscScheme, a.ldmfscStart, a.ldmfscEnd, a.idmfscCst, a.ldmfscCstAgPn, a.ldmIpg, a.ldmfscLim, a.ldmfscLimQu1, a.ldmfscLimMn1, a.ldmfscLimMn2, a.ldmfscLimMn3, a.ldmfscLimQu2, a.ldmfscLimMn4, a.ldmfscLimMn5, a.ldmfscLimMn6, a.ldmfscLimQu3, a.ldmfscLimMn7, a.ldmfscLimMn8, a.ldmfscLimMn9, a.ldmfscLimQu4, a.ldmfscLimMn10, a.ldmfscLimMn11, a.ldmfscLimMn12, a.ipgpKeyCount, b.ipgpKey, ipgLdM_f.ldmfUtPlKey " _
                        & "FROM ((SELECT z.ldmfsc_fSh, z.ldmfscScheme, z.ldmfscStart, z.ldmfscEnd, z.idmfscCst, z.ldmfscCstAgPn, z.ldmIpg, z.ldmfscLim, z.ldmfscLimQu1, z.ldmfscLimMn1, z.ldmfscLimMn2, z.ldmfscLimMn3, z.ldmfscLimQu2, z.ldmfscLimMn4, z.ldmfscLimMn5, z.ldmfscLimMn6, z.ldmfscLimQu3, z.ldmfscLimMn7, z.ldmfscLimMn8, z.ldmfscLimMn9, z.ldmfscLimQu4, z.ldmfscLimMn10, z.ldmfscLimMn11, z.ldmfscLimMn12, Count(ags_ipgPn.ipgpKey) AS ipgpKeyCount " _
                        & "FROM (SELECT Cst.ldmfsc_fSh, Cst.ldmfscScheme, Cst.ldmfscStart, Cst.ldmfscEnd, Cst.idmfscCst, Cst.ldmfscCstAgPn, LdM.ldmIpg, Cst.ldmfscLim, Cst.ldmfscLimQu1, Cst.ldmfscLimMn1 , Cst.ldmfscLimMn2, Cst.ldmfscLimMn3, Cst.ldmfscLimQu2, Cst.ldmfscLimMn4, Cst.ldmfscLimMn5, Cst.ldmfscLimMn6, Cst.ldmfscLimQu3, Cst.ldmfscLimMn7, Cst.ldmfscLimMn8, Cst.ldmfscLimMn9, Cst.ldmfscLimQu4, Cst.ldmfscLimMn10, Cst.ldmfscLimMn11, Cst.ldmfscLimMn12 " _
                        & "FROM ipgLdM AS LdM RIGHT JOIN (ipgLdM_f AS f RIGHT JOIN (ipgLdm_fShCst AS Cst LEFT JOIN ipgLdm_fSh AS Sh ON Cst.ldmfsc_fSh = Sh.ldmfsKey) ON f.ldmfKey = Sh.ldmfsFile) ON LdM.ldmKey = f.ldmfLdM) AS z " _
                        & "LEFT JOIN ags_ipgPn ON (z.ldmIpg = ags_ipgPn.ipgpIpg) AND (z.ldmfscLim = ags_ipgPn.ipgpSmTtl) AND (z.ldmfscCstAgPn = ags_ipgPn.ipgpCstAgPn) GROUP BY z.ldmfsc_fSh, z.ldmfscScheme, z.ldmfscStart, z.ldmfscEnd, z.idmfscCst, z.ldmfscCstAgPn, z.ldmIpg, z.ldmfscLim, z.ldmfscLimQu1, z.ldmfscLimMn1, z.ldmfscLimMn2, z.ldmfscLimMn3, z.ldmfscLimQu2, z.ldmfscLimMn4, z.ldmfscLimMn5, z.ldmfscLimMn6, z.ldmfscLimQu3, z.ldmfscLimMn7, z.ldmfscLimMn8, z.ldmfscLimMn9, z.ldmfscLimQu4, z.ldmfscLimMn10, z.ldmfscLimMn11, z.ldmfscLimMn12) AS a " _
                        & "LEFT JOIN (SELECT y.ldmfscCstAgPn, y.ldmIpg, y.ldmfscLim, p.ipgpKey FROM (SELECT z.ldmfsc_fSh, z.ldmfscScheme, z.ldmfscStart, z.ldmfscEnd, z.idmfscCst, z.ldmfscCstAgPn, z.ldmIpg, z.ldmfscLim, Count(p.ipgpKey) AS [Count-ipgpKey] " _
                        & "FROM (SELECT Cst.ldmfsc_fSh, Cst.ldmfscScheme, Cst.ldmfscStart, Cst.ldmfscEnd, Cst.idmfscCst, Cst.ldmfscCstAgPn, LdM.ldmIpg, Cst.ldmfscLim FROM ipgLdM AS LdM RIGHT JOIN (ipgLdM_f AS f RIGHT JOIN (ipgLdm_fShCst AS Cst LEFT JOIN ipgLdm_fSh AS Sh ON Cst.ldmfsc_fSh = Sh.ldmfsKey) ON f.ldmfKey = Sh.ldmfsFile) ON LdM.ldmKey = f.ldmfLdM)  AS z LEFT JOIN ags_ipgPn AS p ON (z.ldmfscCstAgPn = p.ipgpCstAgPn) AND (z.ldmfscLim = p.ipgpSmTtl) AND (z.ldmIpg = p.ipgpIpg) " _
                        & "GROUP BY z.ldmfsc_fSh, z.ldmfscScheme, z.ldmfscStart, z.ldmfscEnd, z.idmfscCst, z.ldmfscCstAgPn, z.ldmIpg, z.ldmfscLim HAVING (((Count(p.ipgpKey))=1))) AS y " _
                        & "INNER JOIN ags_ipgPn AS p ON (y.ldmfscLim = p.ipgpSmTtl) AND (y.ldmIpg = p.ipgpIpg) AND (y.ldmfscCstAgPn = p.ipgpCstAgPn))  AS b ON (a.ldmIpg = b.ldmIpg) AND (a.ldmfscCstAgPn = b.ldmfscCstAgPn) " _
                        & "AND (a.ldmfscLim = b.ldmfscLim)) LEFT JOIN (ipgLdM_f RIGHT JOIN ipgLdm_fSh ON ipgLdM_f.ldmfKey = ipgLdm_fSh.ldmfsFile) ON a.ldmfsc_fSh = ipgLdm_fSh.ldmfsKey)  AS z LEFT JOIN ags_ipgUtPlP AS y ON (z.ldmfUtPlKey = y.iuplpPl) AND (z.ipgpKey = y.iuplpIpgPn)) LEFT JOIN ags_ipgPn AS p ON z.ipgpKey = p.ipgpKey " _
                        & "WHERE (((z.ldmfsc_fSh)=" & rsShRange!ldmfsKey & "));"

                    Set rsCstStart = db.OpenRecordset(strSql, dbOpenDynaset)
                    ' имеются ли стройки в запросе найденных строек для этого диапазона?
                    If rsCstStart.RecordCount > 0 Then
                        ' да, стройки в запросе найденных строек для этого диапазона имеются
                        rsCstStart.MoveLast
                        TextFieldObj = "<P>  <font color=""silver"">Строек</font> в запросе найденных строек: <font color=""DarkGoldenrod"">" _
                            & rsCstStart.RecordCount & "</font>.</P>" & TextFieldObj
                        ' проходим по каждой стройке запроса ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                        rsCstStart.MoveFirst
                        ' обновляем ли БД?
                        If Update Then
                            ' да, БД обновляем
                            Set rsIuplpEdit = db.OpenRecordset("ags_ipgUtPlP", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                            Do Until rsCstStart.EOF
                                testCst db, rsCstStart, strFFF, Update, rsIuplpEdit
                                TextFieldObj = strFFF & TextFieldObj: strFFF = ""
                                ' переходим к следующей стройке
                                rsCstStart.MoveNext
                            Loop
                            rsIuplpEdit.Close: Set rsIuplpEdit = Nothing
                            Else
                            ' нет, БД не обновляем
                            Do Until rsCstStart.EOF
                                testCst db, rsCstStart, strFFF, Update
                                TextFieldObj = strFFF & TextFieldObj: strFFF = ""
                                ' переходим к следующей стройке
                                rsCstStart.MoveNext
                            Loop
                        End If
                        ' проходим по каждой стройке запроса, окончание::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                        Else
                        ' нет, стройки в запросе найденных строек для этого диапазона отсутствуют
                        TextFieldObj = "<P>  <font color=""silver"">Стройки</font> в <font color=""DarkViolet"">" _
                            & "<b>запросе</b></font> найденных строек <font color=""red"">не найдены</font>.</P>" & TextFieldObj
                    End If
                    rsCstStart.Close: Set rsCstStart = Nothing
                    ' проходим по стройкам текущего диапазона в запросе найденных строек и делаем выводы по их соответствию БД, окончание +++++++++++
                    
                    rsShRange.MoveNext
                Loop
                ' проходим по найденным диапазонам, окончание ---------------------------------------------------------------------------------------
                rsShRange.Close: Set rsShRange = Nothing
                
                Else
                ' нет, диапазоны соответствующим схемам реализации инвестпроектов отсутствуют
                TextFieldObj = "<P> Диапазоны по схемам <font color=""Salmon""><b>не определены</b>" & "</font> в БД</P>" & TextFieldObj
            End If
            Else
            ' ячейка "Код стройки" не найдена
            TextFieldObj = "<P> <font color=""silver"">Ячейка <b>*Код стройки (код)*</b> <font color=""red"">не найдена</font>. Или лимит.</font></P>" & TextFieldObj
        End If
        
        ' освобождаем переменную листа
        Set xlS = Nothing
        Else
        ' нет, требуемый лист отсутствует
        TextFieldObj = "<P> Лист <font color=""Salmon"">" & WorkSheetName & " <b>не обнаружен</b>" & "</font> в книге*</P>" & TextFieldObj
    End If ' имеется ли требуемый лист, окончание ===================================================================================================


NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' работаем со стройкой в запросе найденных строек и делаем выводы по её соответствию БД
Private Sub testCst(ByRef db As DAO.Database, ByRef rsFindCst As DAO.Recordset, ByRef strFFF As String, _
    ByVal Update As Boolean, Optional ByRef rsIuplpEdit As Variant)

    Dim in1 As Integer, in2 As Integer
    Dim qd As DAO.QueryDef, strS As String

    Const cstrTitle As String _
        = "Процедура *Работаем со стройкой в запросе найденных строек и делаем выводы по её соответствию БД*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    strFFF = "<p style=""padding-left:100px""><font color=""silver"">"
    strFFF = strFFF & " - <font color=""Teal"">" & rsFindCst!idmfscCst & "</font>"
    ' имеются ли пункты инвестпрограммы соответствующие текущему пункту уточненного плана?
    If rsFindCst!ipgpKeyCount > 0 Then
        ' да, пункты инвестпрограммы соответствующие текущему пункту уточненного плана имеются
        ' пунктов инвестпрограмм соответствующих текущему пункту уточненного плана больше одного?
        If rsFindCst!ipgpKeyCount > 1 Then
            ' да, пунктов инвестпрограмм соответствующих текущему пункту уточненного плана больше одного
            strFFF = strFFF & ", <font color=""Salmon"">пунктов инвестпрограмм соответствующих текущему пункту уточненного плана больше одного!</font>"
            Else
            ' нет, пункт инвестпрограммы соответствующий текущему пункту уточненного плана имеется ровно один. Хорошо
            strFFF = strFFF & ", ид. пункта ИП: <font color=""Gray"">" & rsFindCst!ipgpKey & "</font>"
            ' проверяем соответствие схемы реализации
            If IsNull(rsFindCst!ipgpSh) Then
                in1 = 0
                Else
                in1 = rsFindCst!ipgpSh
            End If
            If IsNull(rsFindCst!ldmfscScheme) Then
                in2 = 0
                Else
                in2 = rsFindCst!ldmfscScheme
            End If
            strFFF = strFFF & TestLim(LimDB:=rsFindCst!ipgpSh, limDoc:=rsFindCst!ldmfscScheme, _
                diff:=in1 - in2, Title:="Схема", Update:=False, Mln:=False, isCurr:=False)
            ' обновляем ли БД?
            If Update Then
                ' да, БД обновляем
                ' есть ли разница?
                If Not in1 - in2 = 0 Then
                    ' да, разница есть
                    ' обновляем таблицу в БД
                    strSql = "update ags.ipgPn set ipgpSh = " & rsFindCst!ldmfscScheme & " where ipgpKey = " & rsFindCst!ipgpKey & ";"
                    
                    PassThroughQuery db, strSql
                    
                    strFFF = strFFF & ". <font color=""DarkGreen""><b>Обновлено.</b></font>"
                    Else
                    ' нет, разницы нет
                End If
                Else
                ' нет, БД не обновляем
            End If
            ' имеется ли пункт детализации пункта инвестпрограммы по текущему пункту уточненного плана?
            If IsNull(rsFindCst!iuplpKey) = False Then
                ' да, пункт детализации пункта инвестпрограммы по текущему пункту уточненного плана имеется
                strFFF = strFFF & ", ид. пункта ИП по УП: <font color=""Gray"">" & rsFindCst!iuplpKey & "</font>"
                ' проверяем общий лимит
                strFFF = strFFF & TestLim(rsFindCst!limYeDB, rsFindCst!limYeDoc, rsFindCst!limYeDiff, "Лимит год", Update, rsIuplpEdit, "iuplpLim", rsFindCst!iuplpKey)
                
                ' проверяем лимит 1-го квартала
                strFFF = strFFF & TestLim(rsFindCst!limQu1db, rsFindCst!limQu1doc, rsFindCst!limQu1Diff, "Лимит кв. I", Update, rsIuplpEdit, "iuplpQ1", rsFindCst!iuplpKey)
                ' проверяем лимит января
                strFFF = strFFF & TestLim(rsFindCst!limMn1DB, rsFindCst!limMn1Doc, rsFindCst!limMn1Diff, "Лимит января", Update, rsIuplpEdit, "iuplpM01", rsFindCst!iuplpKey)
                ' проверяем лимит февраля
                strFFF = strFFF & TestLim(rsFindCst!limMn2DB, rsFindCst!limMn2Doc, rsFindCst!limMn2Diff, "Лимит февраля", Update, rsIuplpEdit, "iuplpM02", rsFindCst!iuplpKey)
                ' проверяем лимит марта
                strFFF = strFFF & TestLim(rsFindCst!limMn3DB, rsFindCst!limMn3Doc, rsFindCst!limMn3Diff, "Лимит марта", Update, rsIuplpEdit, "iuplpM03", rsFindCst!iuplpKey)
                
                ' проверяем лимит 2-го квартала
                strFFF = strFFF & TestLim(rsFindCst!limQu2db, rsFindCst!limQu2doc, rsFindCst!limQu2Diff, "Лимит кв. II", Update, rsIuplpEdit, "iuplpQ2", rsFindCst!iuplpKey)
                ' проверяем лимит апреля
                strFFF = strFFF & TestLim(rsFindCst!limMn4DB, rsFindCst!limMn4Doc, rsFindCst!limMn4Diff, "Лимит апреля", Update, rsIuplpEdit, "iuplpM04", rsFindCst!iuplpKey)
                ' проверяем лимит мая
                strFFF = strFFF & TestLim(rsFindCst!limMn5DB, rsFindCst!limMn5Doc, rsFindCst!limMn5Diff, "Лимит мая", Update, rsIuplpEdit, "iuplpM05", rsFindCst!iuplpKey)
                ' проверяем лимит июня
                strFFF = strFFF & TestLim(rsFindCst!limMn6DB, rsFindCst!limMn6Doc, rsFindCst!limMn6Diff, "Лимит июня", Update, rsIuplpEdit, "iuplpM06", rsFindCst!iuplpKey)
                
                ' проверяем лимит 3-го квартала
                strFFF = strFFF & TestLim(rsFindCst!limQu3db, rsFindCst!limQu3doc, rsFindCst!limQu3Diff, "Лимит кв. III", Update, rsIuplpEdit, "iuplpQ3", rsFindCst!iuplpKey)
                ' проверяем лимит июля
                strFFF = strFFF & TestLim(rsFindCst!limMn7DB, rsFindCst!limMn7Doc, rsFindCst!limMn7Diff, "Лимит июля", Update, rsIuplpEdit, "iuplpM07", rsFindCst!iuplpKey)
                ' проверяем лимит августа
                strFFF = strFFF & TestLim(rsFindCst!limMn8DB, rsFindCst!limMn8Doc, rsFindCst!limMn8Diff, "Лимит августа", Update, rsIuplpEdit, "iuplpM08", rsFindCst!iuplpKey)
                ' проверяем лимит сентября
                strFFF = strFFF & TestLim(rsFindCst!limMn9DB, rsFindCst!limMn9Doc, rsFindCst!limMn9Diff, "Лимит сентября", Update, rsIuplpEdit, "iuplpM09", rsFindCst!iuplpKey)
                
                ' проверяем лимит 4-го квартала
                strFFF = strFFF & TestLim(rsFindCst!limQu4db, rsFindCst!limQu4doc, rsFindCst!limQu4Diff, "Лимит кв. IV", Update, rsIuplpEdit, "iuplpQ4", rsFindCst!iuplpKey)
                ' проверяем лимит октября
                strFFF = strFFF & TestLim(rsFindCst!limMn10DB, rsFindCst!limMn10Doc, rsFindCst!limMn10Diff, "Лимит октября", Update, rsIuplpEdit, "iuplpM10", rsFindCst!iuplpKey)
                ' проверяем лимит ноября
                strFFF = strFFF & TestLim(rsFindCst!limMn11DB, rsFindCst!limMn11Doc, rsFindCst!limMn11Diff, "Лимит ноября", Update, rsIuplpEdit, "iuplpM11", rsFindCst!iuplpKey)
                ' проверяем лимит декабря
                strFFF = strFFF & TestLim(rsFindCst!limMn12DB, rsFindCst!limMn12Doc, rsFindCst!limMn12Diff, "Лимит декабря", Update, rsIuplpEdit, "iuplpM12", rsFindCst!iuplpKey)
                Else
                ' нет, пункт детализации пункта инвестпрограммы по текущему пункту уточненного плана отсутствует
                strFFF = strFFF & ", <font color=""Salmon"">пункт детализации пункта инвестпрограммы по текущему пункту уточненного плана отсутствует!</font>"
                ' обновляем ли БД?
                If Update Then
                    ' да, БД обновляем
                    ' добавляем запись
                    With rsIuplpEdit
                        .AddNew
                            !iuplpPl = rsFindCst!ldmfUtPlKey
                            !iuplpIpgPn = rsFindCst!ipgpKey
                            !iuplpLim = rsFindCst!limYeDoc
                            FieldInsertIuplpPlPn !iuplpQ1, rsFindCst!limQu1doc
                            FieldInsertIuplpPlPn !iuplpM01, rsFindCst!limMn1Doc
                            FieldInsertIuplpPlPn !iuplpM02, rsFindCst!limMn2Doc
                            FieldInsertIuplpPlPn !iuplpM03, rsFindCst!limMn3Doc
                            FieldInsertIuplpPlPn !iuplpQ2, rsFindCst!limQu2doc
                            FieldInsertIuplpPlPn !iuplpM04, rsFindCst!limMn4Doc
                            FieldInsertIuplpPlPn !iuplpM05, rsFindCst!limMn5Doc
                            FieldInsertIuplpPlPn !iuplpM06, rsFindCst!limMn6Doc
                            FieldInsertIuplpPlPn !iuplpQ3, rsFindCst!limQu3doc
                            FieldInsertIuplpPlPn !iuplpM07, rsFindCst!limMn7Doc
                            FieldInsertIuplpPlPn !iuplpM08, rsFindCst!limMn8Doc
                            FieldInsertIuplpPlPn !iuplpM09, rsFindCst!limMn9Doc
                            FieldInsertIuplpPlPn !iuplpQ4, rsFindCst!limQu4doc
                            FieldInsertIuplpPlPn !iuplpM10, rsFindCst!limMn10Doc
                            FieldInsertIuplpPlPn !iuplpM11, rsFindCst!limMn11Doc
                            FieldInsertIuplpPlPn !iuplpM12, rsFindCst!limMn12Doc
                        .Update
                        .Bookmark = .LastModified
                        'RaAuKey = !ralpraKey
                        strFFF = strFFF & ". <font color=""DarkGreen""><b>Добавлено.</b></font>"
                        strFFF = strFFF & ", ид. пункта ИП по УП: <font color=""Gray"">" & rsIuplpEdit!iuplpKey & "</font>"
                    End With
                    Else
                    ' нет, БД не обновляем
                End If
            End If
        End If
        Else
        ' нет, пункты инвестпрограммы соответствующие текущему пункту уточненного плана отсутствуют
        strFFF = strFFF & ", <font color=""Salmon"">пункты инвестпрограммы соответствующие текущему пункту уточненного плана отсутствуют!</font>"
    End If
    strFFF = strFFF & "</font></p>"

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' вносим значение лимита в поле пункта уточнённого плана
Private Sub FieldInsertIuplpPlPn(ByRef FieldIns As DAO.Field, ByRef FieldOut As DAO.Field)

    Dim ddLimTtl As Variant
    
    Const cstrTitle As String _
        = "Процедура *Вносим значение лимита в поле пункта уточнённого плана*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    If IsNull(FieldOut) = False And IsEmpty(FieldOut) = False _
        And IsNumeric(FieldOut) Then
        If Not FieldOut = 0 Then
            ddLimTtl = CDec(WorksheetFunction.Round(FieldOut, 8))
            FieldIns = ddLimTtl
        End If
    End If
                            
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
                            
End Sub


' проверяем соответствие лимитов
Private Function TestLim(ByVal LimDB As Variant, ByVal limDoc As Variant, _
    ByVal diff As Variant, ByVal Title As String, _
    ByVal Update As Boolean, Optional ByRef rsIuplpEdit As Variant, Optional ByVal FieldEditName As String = "", Optional ByVal iuplpKey As Integer = 0, _
    Optional Mln As Boolean = True, Optional isCurr As Boolean = True) As String

    Dim strUp As String, strText As String

    Const cstrTitle As String _
        = "Процедура *Проверяем соответствие лимитов*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' разница величин равна 0?
    If diff = 0 Or IIf(IsNull(LimDB), 0, LimDB) - IIf(IsNull(limDoc), 0, limDoc) = 0 Then
        ' да, разница величин равна 0
        TestLim = ", " & Title & "<font color=""Teal""><b>+</b></font>"
        Else
        ' нет, разница величин не равна 0 -------------------------------------------------------------------------------------------------
        strUp = ""
        If Update Then
            ' да, БД обновляем
            rsIuplpEdit.FindFirst "iuplpKey = " & iuplpKey
            rsIuplpEdit.Edit
                rsIuplpEdit(FieldEditName) = limDoc
            rsIuplpEdit.Update
            strUp = ". <font color=""DarkGreen""><b>Обновлено.</b></font>"
            Else
            ' нет, БД не обновляем
        End If
        
        ' умножаем на миллион?
        If Mln Then
            ' да, на миллион умножаем
            ' это деньги?
            If isCurr Then
                ' да, это деньги
                strText = ", " & Title & ": <font color=""Salmon""><b>не равен</b></font>. БД: <font color=""GoldenRod"">" _
                    & FormatCurrency(IIf(IsNull(LimDB), 0, LimDB * 1000000)) & "</font>, источник: <font color=""CadetBlue"">" _
                    & FormatCurrency(IIf(IsNull(limDoc), 0, limDoc * 1000000)) _
                    & "</font>, разница: <font color=""Salmon"">" & FormatCurrency(IIf(IsNull(diff), 0, diff * 1000000)) & "</font>"
                Else
                ' нет, это не деньги
                strText = ", " & Title & ": <font color=""Salmon""><b>не равен</b></font>. БД: <font color=""GoldenRod"">" _
                    & IIf(IsNull(LimDB), 0, LimDB * 1000000) & "</font>, источник: <font color=""CadetBlue"">" _
                    & IIf(IsNull(limDoc), 0, limDoc * 1000000) _
                    & "</font>, разница: <font color=""Salmon"">" & IIf(IsNull(diff), 0, diff * 1000000) & "</font>"
            End If
            Else
            ' нет, на миллион не умножаем
            ' это деньги?
            If isCurr Then
                ' да, это деньги
                strText = ", " & Title & ": <font color=""Salmon""><b>не равен</b></font>. БД: <font color=""GoldenRod"">" _
                    & FormatCurrency(IIf(IsNull(LimDB), 0, LimDB)) & "</font>, источник: <font color=""CadetBlue"">" _
                    & FormatCurrency(IIf(IsNull(limDoc), 0, limDoc)) _
                    & "</font>, разница: <font color=""Salmon"">" & FormatCurrency(IIf(IsNull(diff), 0, diff)) & "</font>"
                Else
                ' нет, это не деньги
                strText = ", " & Title & ": <font color=""Salmon""><b>не равен</b></font>. БД: <font color=""GoldenRod"">" _
                    & IIf(IsNull(LimDB), 0, LimDB) & "</font>, источник: <font color=""CadetBlue"">" & IIf(IsNull(limDoc), 0, limDoc) _
                    & "</font>, разница: <font color=""Salmon"">" & IIf(IsNull(diff), 0, diff) & "</font>"
            End If
        End If
        TestLim = strText & strUp
        ' нет, разница величин не равна 0, окончание --------------------------------------------------------------------------------------
    End If


NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

' загружаем стройку из файла
Private Sub LoadCst(ByRef db As DAO.Database, ByRef xlS As Excel.Worksheet, ByRef cCst As Range, _
    ByVal ddOffset As Integer, ByVal iii As Integer, ByVal eee As String, ByRef rsFindCst As DAO.Recordset, _
    ByVal ldmfscScheme As Integer, ByVal ldmfsc_fSh As Integer, ByVal ldmfUtPlKey As Integer, _
    ByVal ldmfQuarter As Boolean, ByVal ldmfSumFirst As Integer, ByRef strFFF As String)
    ' ldmfQuarter - наличие квартальных сумм
    ' ldmfSumFirst - смещение первой суммы от колонки общего лимита
    ' ddOffset - смещение общего лимита относительно столбца кодов стройки
    ' ldmfUtPlKey - ключ уточнённого плана
    
    Dim strSql As String, CostIts As Integer, ddLimTtl As Variant, OffsetInt As Integer

    Const cstrTitle As String _
        = "Процедура *Загружаем стройку из файла*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    strFFF = ""
    
    ' имеется ли общая сумма?
    If IsNull(cCst.Offset(0, ddOffset)) = False And IsEmpty(cCst.Offset(0, ddOffset)) = False _
        And IsNumeric(cCst.Offset(0, ddOffset)) Then
        ' да, общая сумма имеется
        ' общая сумма не равна 0?
        If Not cCst.Offset(0, ddOffset) = 0 Then
            ' да, общая сумма не равна 0
            ddLimTtl = CDec(cCst.Offset(0, ddOffset))
            ' проверяем на предмет направления затрат
            ' имеется ли ключ направления затрат?
            strSql = "select iciKey, iciName from ags.ipgCostItsNmAll where iciName = '" & cCst.Offset(0, 1) & "'"
            If FindOneKey(db, strSql, "iciKey", CostIts) Then
                ' да, ключ направления затрат имеется
                ' выходит это пункт направления затрат а не стройка
                strFFF = "<p><font color=""silver"">  <b>" & iii & "</b>. " & cCst.Row & ". <font color=""CadetBlue"">" _
                    & cCst & "</font>, " & eee & " " & ddLimTtl & ", затраты: <b>" & cCst.Offset(0, 1) & "</b> ключ " _
                    & CostIts & "</font></p>" & strFFF
                    
                ' Здесь ещё бы на подрядчика проверить +++++++++++++++++++++
                    
                Else
                ' нет, ключ направления затрат отсутствует
                    
                ' добавляем в таблицу найденных строек
                With rsFindCst
                    .AddNew
                        !idmfscCst = cCst
                        !ldmfscScheme = ldmfscScheme
                        !ldmfscStart = cCst.Row
                        !ldmfsc_fSh = ldmfsc_fSh
                        !ldmfscLim = ddLimTtl
                        !ldmfscUtPl = ldmfUtPlKey
                        
                        OffsetInt = ddOffset + ldmfSumFirst
                        ' имеются ли суммы кварталов в рассматриваемом файле
                        If ldmfQuarter Then
                            ' да, суммы кварталов в рассматриваемом файле имеются
                            ' вносим сумму первого квартала
                            FieldInsert !ldmfscLimQu1, OffsetInt, cCst
                            ' вносим сумму января
                            FieldInsert !ldmfscLimMn1, OffsetInt + 1, cCst
                            ' вносим сумму февраля
                            FieldInsert !ldmfscLimMn2, OffsetInt + 2, cCst
                            ' вносим сумму марта
                            FieldInsert !ldmfscLimMn3, OffsetInt + 3, cCst
                            ' вносим сумму второго квартала
                            FieldInsert !ldmfscLimQu2, OffsetInt + 4, cCst
                            ' вносим сумму апреля
                            FieldInsert !ldmfscLimMn4, OffsetInt + 5, cCst
                            ' вносим сумму мая
                            FieldInsert !ldmfscLimMn5, OffsetInt + 6, cCst
                            ' вносим сумму июня
                            FieldInsert !ldmfscLimMn6, OffsetInt + 7, cCst
                            ' вносим сумму третьего квартала
                            FieldInsert !ldmfscLimQu3, OffsetInt + 8, cCst
                            ' вносим сумму июля
                            FieldInsert !ldmfscLimMn7, OffsetInt + 9, cCst
                            ' вносим сумму августа
                            FieldInsert !ldmfscLimMn8, OffsetInt + 10, cCst
                            ' вносим сумму сентября
                            FieldInsert !ldmfscLimMn9, OffsetInt + 11, cCst
                            ' вносим сумму четвертого квартала
                            FieldInsert !ldmfscLimQu4, OffsetInt + 12, cCst
                            ' вносим сумму октября
                            FieldInsert !ldmfscLimMn10, OffsetInt + 13, cCst
                            ' вносим сумму ноября
                            FieldInsert !ldmfscLimMn11, OffsetInt + 14, cCst
                            ' вносим сумму декабря
                            FieldInsert !ldmfscLimMn12, OffsetInt + 15, cCst
                            Else
                            ' нет, суммы кварталов в рассматриваемом файле отсутствуют
                            ' вносим сумму января
                            FieldInsert !ldmfscLimMn1, OffsetInt, cCst
                            ' вносим сумму февраля
                            FieldInsert !ldmfscLimMn2, OffsetInt + 1, cCst
                            ' вносим сумму марта
                            FieldInsert !ldmfscLimMn3, OffsetInt + 2, cCst
                            ' вносим сумму апреля
                            FieldInsert !ldmfscLimMn4, OffsetInt + 3, cCst
                            ' вносим сумму мая
                            FieldInsert !ldmfscLimMn5, OffsetInt + 4, cCst
                            ' вносим сумму июня
                            FieldInsert !ldmfscLimMn6, OffsetInt + 5, cCst
                            ' вносим сумму июля
                            FieldInsert !ldmfscLimMn7, OffsetInt + 6, cCst
                            ' вносим сумму августа
                            FieldInsert !ldmfscLimMn8, OffsetInt + 7, cCst
                            ' вносим сумму сентября
                            FieldInsert !ldmfscLimMn9, OffsetInt + 8, cCst
                            ' вносим сумму октября
                            FieldInsert !ldmfscLimMn10, OffsetInt + 9, cCst
                            ' вносим сумму ноября
                            FieldInsert !ldmfscLimMn11, OffsetInt + 10, cCst
                            ' вносим сумму декабря
                            FieldInsert !ldmfscLimMn12, OffsetInt + 11, cCst
                        End If
                    .Update
                End With
                ' ну значит это действительно стройка
                strFFF = "<p><font color=""silver"">  <b>" & iii & "</b>. " & cCst.Row & ". <font color=""CadetBlue"">" _
                    & cCst & "</font>, " & eee & " " & ddLimTtl & " <font color=""CadetBlue""><b>стройка</b></font></font></p>" _
                    & strFFF
            End If
            Else
            ' нет, общая сумма равна 0
            strFFF = "<p><font color=""silver"">  <b>" & iii & "</b>. " & cCst.Row & ". <font color=""CadetBlue"">" _
                & cCst & "</font>, " & eee & ", <font color=""Salmon""><b>нет лимита</b></font> </font></p>" & strFFF
        End If
        Else
        ' нет, общая сумма отсутствует
        strFFF = "<p><font color=""silver"">  <b>" & iii & "</b>. " & cCst.Row & ". <font color=""CadetBlue"">" _
            & cCst & "</font>, " & eee & ", <font color=""Salmon""><b>нет лимита</b></font> </font></p>" & strFFF
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    ' ошибка про то что невозможно добавить строку из-за повторяющегося индекса?
    If Err.Number = 3022 Then
        ' да, ошибка про то что невозможно добавить строку из-за повторяющегося индекса
        strFFF = "<p><font color=""silver"">  <b>" & iii & "</b>. " & cCst.Row & ". <font color=""CadetBlue"">" _
            & cCst & "</font>, " & eee & " " & ddLimTtl & " <font color=""DarkOrange""><b>Ошибка: попытка повторно добавить стройку</b></font></font></p>" _
            & strFFF
        Else
        ' нет, ошибка не про то что невозможно добавить строку из-за повторяющегося индекса
        MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    End If
    Resume NormalExit

End Sub

' вносим значение лимита в поле
Private Sub FieldInsert(ByRef FieldIns As DAO.Field, ByVal OffsetInt As Integer, ByRef cCst As Range)

    Dim ddLimTtl As Variant
    
    Const cstrTitle As String _
        = "Процедура *Вносим значение лимита в поле*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    If IsNull(cCst.Offset(0, OffsetInt)) = False And IsEmpty(cCst.Offset(0, OffsetInt)) = False _
        And IsNumeric(cCst.Offset(0, OffsetInt)) Then
        If Not cCst.Offset(0, OffsetInt) = 0 Then
            ddLimTtl = CDec(WorksheetFunction.Round(cCst.Offset(0, OffsetInt), 8))
            FieldIns = ddLimTtl
        End If
    End If
                            
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
                            
End Sub
