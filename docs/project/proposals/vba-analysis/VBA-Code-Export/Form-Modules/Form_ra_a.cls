VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ra_a"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

'Private Sub adt_results_Enter()
'Dim aaa As TextBox
'aaa.sc
'End Sub

' Работа с файлами отчётов агентов

Private Sub btnAuditRun_Click()

    Const cstrTitle As String = "Функция *Проводим ревизию файлов приёмки*"
    Dim db As DAO.Database, qd As DAO.QueryDef, rst As DAO.Recordset
    Dim rstDir As DAO.Recordset, strDir As String, strFile As String
    Dim rstFiltered As DAO.Recordset, rstSheets As DAO.Recordset, rstSheetsFiltered As DAO.Recordset
    Dim rstSheetsFilteredNames As DAO.Recordset, rstSheetsFilteredPeriod As DAO.Recordset
    
    Dim xlA As Excel.Application, xlW As Excel.Workbook, xlS As Excel.Worksheet, iii As Boolean, SheetName As String
    
    Dim sqlString As String, yyyy As Integer
    
    Dim rstOafTest As DAO.Recordset, rstOaf As DAO.Recordset, strWaste As String
    
    Dim dStart As Date, dFinish As Date, dDateDiff As Long
    
    Dim objRa_aCarrent As ra_a ' объект *Текущей ревизии файлов приёмки*. 06.07.2022
    
    ' ***************************************************************************************************************************
    
On Error GoTo ErrHandler


If IsNull(Me!adt_key) = False Then

    Me!adt_results = "": Me!adt_date = DateTime.Now: dStart = Me!adt_date
    
    Me!adt_results = "<P>Начало проведения ревизии *<B><font color=""red"">" & Me!adt_name & "</font></B>*.</P>" _
    & "<P>Проводим по директории - " & Me!adt_dir & "</P>" _
    & "<P><B>" & Me!adt_date & "</B> - Время начала проведения ревизии.</P>"
    
    Set db = CurrentDb 'открываем переменную базы данных ---------------------------------------------------
    
    ' создаём объект *Текущей ревизии файлов приёмки*
    Set objRa_aCarrent = ClassFactory.Ra_aReadKey(Me!adt_key, db, Me!adt_results)
    
    ' определяем год по которому проводится ревизия
    sqlString = "SELECT ra_a.adt_key, ra_a.adt_name, First(ags_yyyy.yyyy) AS [First-yyyy] " _
        & "FROM (ra_dir INNER JOIN ra_a ON ra_dir.key = ra_a.adt_dir) INNER JOIN (ags_yyyy INNER JOIN " _
        & "(ra_dir_s_p INNER JOIN ags_ra_period ON ra_dir_s_p.rdsp_period = ags_ra_period.key) " _
        & "ON ags_yyyy.yKey = ags_ra_period.y) ON ra_dir.key = ra_dir_s_p.rdsp_dir " _
        & "GROUP BY ra_a.adt_key, ra_a.adt_name " _
        & "HAVING (((ra_a.adt_key)=" & Me!adt_key & "))"
    Set rst = db.OpenRecordset(sqlString, dbOpenSnapshot)
        ' имеется ли год?
        If rst.RecordCount > 0 Then
            ' да, год имеется
            rst.MoveFirst
            yyyy = rst![First-yyyy]
            Else
            ' нет, год отсутствует
            yyyy = 0
        End If
    rst.Close: Set rst = Nothing
    
    ' очищаем таблицу сводных значений
    strSql = "DELETE * FROM ra_aTtl"
    Set qd = db.CreateQueryDef("", strSql)
    qd.Execute dbFailOnError
    qd.Close
    Set qd = Nothing
    
    ' получаем список файлов
    Set rst = db.OpenRecordset("ra_f", dbOpenSnapshot)
    filterStr = "af_dir = " & Me!adt_dir
    rst.Filter = filterStr
    Set rstFiltered = rst.OpenRecordset

    If rstFiltered.RecordCount > 0 Then
        ' определяем директорию для поиска
        Set rstDir = db.OpenRecordset("select * from ra_dir order by key", dbOpenSnapshot)
        With rstDir
            .FindFirst "key=" & Me!adt_dir
            If .NoMatch Then
                Me!adt_results = "<P>Не обнаружена <font color=""red"">директория</font> для ревизии</P>" & Me!adt_results
                Else
                strDir = !Dir
                Me!adt_results = "<P>Имя директории *<B><font color=""green"">" & strDir & "</font></B>* для ревизии обнаружено</P>" _
                    & Me!adt_results
                Set fso = CreateObject("Scripting.FileSystemObject")
                If (fso.FolderExists(strDir)) Then
                
                    Me!adt_results = "<P>Директория с именем *<B><font color=""green"">" & strDir & "</font></B>* в файловой системе обнаружена</P>" _
                    & Me!adt_results
                    
                    ' открываем приложение
                    Set xlA = CreateObject("Excel.Application")
                    
                    Me!adt_results = "<P>" & DateTime.Now _
                    & " - *<B><font color=""green"">" & "Приложение Excel открыто" & "</font></B>*</P>" & Me!adt_results

                    ' идём по файлам
                    rstFiltered.MoveFirst
                    Do Until rstFiltered.EOF ' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                        ' является файл файлом отчётов всех агентов, аренды земли или файлом хранения и стройконтроля?
                        If rstFiltered!af_type = 3 Or rstFiltered!af_type = 2 Or rstFiltered!af_type = 5 Or rstFiltered!af_type = 6 Then
                            ' да, файл является файлом отчётов всех агентов, аренды земли или файлом хранения и стройконтроля
                            strFile = rstFiltered!af_name
                            Else
                            ' нет, файл не является отчётов всех агентов, файлом аренды земли или файлом хранения и стройконтроля
                            strFile = strDir & "\" & rstFiltered!af_name
                        End If
                        ' подлежит ли текущий файл рассмотрению?
                        If rstFiltered!af_execute Then
                            ' да, текущий файл подлежит рассмотрению
                            Set fsof = CreateObject("Scripting.FileSystemObject")
                            If (fsof.FileExists(strFile)) Then
                                'да, файл существует
                                Me!adt_results = "<P>" & DateTime.Now & " - Файл с именем *<B>" & strFile _
                                    & "</B>* в файловой системе обнаружен</P>" & Me!adt_results
                                    
                                    'открываем
                                    Set xlW = xlA.Workbooks.Open(filename:=strFile, ReadOnly:=True, UpdateLinks:=0)
                                        
                                    Me!adt_results = _
                                    "<P>" & DateTime.Now & " - Файл с именем *<B><font color=""green"">" & strFile _
                                    & "</font></B>* в приложении открыт</P>" & Me!adt_results
                                    
                                    ' ВИДИМО здесь нужно распределять файлы по процедурам, соответствующим их типам?
                                    
                                    ' является файл файлом отчётов всех агентов, аренды земли или файлом хранения и стройконтроля?
                                    If rstFiltered!af_type = 3 Or rstFiltered!af_type = 2 Or rstFiltered!af_type = 5 Then
                                        ' да, файл является файлом отчётов всех агентов, аренды земли или файлом хранения и стройконтроля
                                        
                                        ' является файл файлом аренды земли?
                                        If rstFiltered!af_type = 3 Then
                                            ' имеется ли лист "Аренда_Земли" ========================================================
                                            If WorksheetIsExist(xlW, "Аренда_Земли") Then
                                                ' да, лист "Аренда_Земли" имеется
                                                ' открываем существующий лист
                                                Set xlS = xlW.Worksheets("Аренда_Земли")
                                                ' вызываем процедуру *работаем с листом "Аренда_Земли"*
                                                RAAudit_ralp xlS, Me!adt_AddRA, Me!adt_results, db, Me!adt_key
                                                'освобождаем переменную листа
                                                Set xlS = Nothing
                                                Else
                                                ' нет, лист "Аренда_Земли" отсутствует
                                                Me!adt_results = _
                                                    "<P>" & DateTime.Now _
                                                    & " - *<B> лист <font color=""red"">Аренда_Земли не обнаружен" & "</font> в книге</B>*</P>" _
                                                    & Me!adt_results
                                            End If ' ================================================================================
                                            
                                             ' имеется ли лист "учет_аренды" ========================================================
                                            If WorksheetIsExist(xlW, "учет_аренды") Then
                                                ' да, лист "учет_аренды" имеется
                                                ' открываем существующий лист
                                                Set xlS = xlW.Worksheets("учет_аренды")
                                                ' вызываем процедуру *работаем с листом "учет_аренды"*
                                                RAAudit_ralpSum xlS, Me!adt_AddRA, Me!adt_results, db, Me!adt_key, yyyy
                                                'освобождаем переменную листа
                                                Set xlS = Nothing
                                                Else
                                                ' нет, лист "учет_аренды" отсутствует
                                                Me!adt_results = _
                                                    "<P>" & DateTime.Now _
                                                    & " - *<B> лист <font color=""red"">учет_аренды не обнаружен" & "</font> в книге</B>*</P>" _
                                                    & Me!adt_results
                                            End If ' ================================================================================
                                        End If
                                        
                                        ' является файл файлом хранения и стройконтроля?
                                        If rstFiltered!af_type = 2 Then
                                            ' имеется ли лист "ХрСтрКнтрл" ========================================================
                                            If WorksheetIsExist(xlW, "ХрСтрКнтрл") Then
                                                ' да, лист "учет_аренды" имеется
                                                ' открываем существующий лист
                                                Set xlS = xlW.Worksheets("ХрСтрКнтрл")
                                                ' вызываем процедуру *работаем с листом первичных документов к договорам, он же "ХрСтрКнтрл"*
                                                RAAudit_cn_PrDoc xlS, Me!adt_AddRA, Me!adt_results, db, Me!adt_key, yyyy, xlA, rstFiltered!af_source
                                                'освобождаем переменную листа
                                                Set xlS = Nothing
                                                Else
                                                ' нет, лист "ХрСтрКнтрл" отсутствует
                                                Me!adt_results = "<P>" & DateTime.Now _
                                                    & " - *<B> лист <font color=""red"">ХрСтрКнтрл не обнаружен" & "</font> в книге</B>*</P>" _
                                                    & Me!adt_results
                                            End If ' ================================================================================
                                        End If

                                        ' является файл файлом отчётов всех агентов?
                                        If rstFiltered!af_type = 5 Then
                                            ' имеется ли лист "Отчеты" ========================================================
                                            If WorksheetIsExist(xlW, "Отчеты") Then
                                                ' да, лист "Отчеты" имеется
                                                ' открываем существующий лист
                                                Set xlS = xlW.Worksheets("Отчеты")
                                                
                                                objRa_aCarrent.ra_aAllAgentsChildAdd rstFiltered!af_key, db
                                                
                                                objRa_aCarrent.ra_aAllAgentsChild.Audit xlS, db, xlA
                                                'MsgBox (objRa_aCarrent.ra_aAllAgentsChild.adt_AllAgentsKey)
                                                
                                                ' вызываем процедуру *Работаем с листом Отчётов всех агентов*
                                                'RAAudit_AllAgents xlS, Me!adt_AddRA, Me!adt_results, db, Me!adt_key, yyyy, xlA, rstFiltered!af_source
                                                'освобождаем переменную листа
                                                Set xlS = Nothing
                                                Else
                                                ' нет, лист "Отчеты" отсутствует
                                                Me!adt_results = "<P>" & DateTime.Now _
                                                    & " - *<B> лист <font color=""red"">Отчеты не обнаружен" & "</font> в книге</B>*</P>" _
                                                    & Me!adt_results
                                            End If ' ================================================================================
                                        End If

                                        Else
                                        ' нет, файл не является файлом отчётов всех агентов, аренды земли или файлом хранения и стройконтроля
                                        
                                        If rstFiltered!af_type = 4 Then 'Файл типа "агентское вознаграждение"
                                            ' очищаем таблицу для последующей сверки
                                            strSql = "DELETE * FROM ogAgFeePnTest"
                                            Set qd = db.CreateQueryDef("", strSql)
                                            qd.Execute dbFailOnError
                                            qd.Close
                                            Set qd = Nothing
                                            
                                            ' открываем набор записей таблицы для последующей сверки
                                            Set rstOafTest = db.OpenRecordset("ogAgFeePnTest", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                                        End If
                                        
                                        ' проходим по листам ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                        Set rstSheetsFiltered = db.OpenRecordset( _
                                            "SELECT ft_s_key, ft_s_type, ft_s_num, st_key, st_name " _
                                            & "FROM ra_ft_st INNER JOIN ra_ft_s ON ra_ft_st.st_key = ra_ft_s.ft_s_sheet_type " _
                                            & "WHERE ft_s_type = " & rstFiltered!af_type _
                                            & " ORDER BY ra_ft_s.ft_s_num" _
                                            , dbOpenSnapshot)
                                        
                                        If rstSheetsFiltered.RecordCount > 0 Then
                                            rstSheetsFiltered.MoveFirst
                                            Do Until rstSheetsFiltered.EOF
                                                'работаем с отдельным листом - начало -----------------------------------------
                                                Set rstSheetsFilteredNames = db.OpenRecordset _
                                                    ("select * from ra_ft_sn where ftsn_ft_s=" & rstSheetsFiltered!ft_s_key _
                                                        , dbOpenSnapshot)
                                                'имеются ли варианты имени листа?
                                                If rstSheetsFilteredNames.RecordCount > 0 Then
                                                    'да, варианты имени листа имеются =========================================
                                                    rstSheetsFilteredNames.MoveFirst
                                                    'очищаем имя существующего листа
                                                    SheetName = ""
                                                    
                                                    Do Until rstSheetsFilteredNames.EOF
                                                        'работаем с отдельным вариантом имени листа - начало ------------------
                                                
                                                        'присваиваем текущий вариант имени переменной имени листа
                                                        SheetName = rstSheetsFilteredNames!ftsn_name
                                                        If WorksheetIsExist(xlW, SheetName) Then
                                                            'выходим из цикла по вариантам имен поля
                                                            Exit Do
                                                        End If
                                                        
                                                        'очищаем имя существующего листа
                                                        SheetName = ""
                                                        
                                                        'переходим к следующему варианту имени
                                                        rstSheetsFilteredNames.MoveNext
                                                        'работаем с отдельным вариантом имени листа - окончание ---------------
                                                    Loop
                                                    'да, варианты имени листа имеются =========================================
                                                    Else
                                                    'нет, варианты имени листа отсутствуют ====================================
                                                    Me!adt_results = _
                                                        "<P>" & DateTime.Now _
                                                        & " - *<B><font color=""red""> лист № " _
                                                        & rstSheetsFiltered!ft_s_num & " - отсутствуют варианты имени листа" _
                                                        & "</font></B>*</P>" & Me!adt_results
                                                    'нет, варианты имени листа отсутствуют ====================================
                                                End If
                                                
                                                'после обработки всех вариантов имен переменная имени существующего листа
                                                'осталась пустой?
                                                If SheetName = "" Then
                                                    'да, она пуста. Существующий лист не удалось обнаружить
                                                    'сообщаем о неудачной попытке обнаружения листа
                                                    Me!adt_results = _
                                                        "<P>" & DateTime.Now _
                                                        & " - *<B><font color=""red""> лист № " _
                                                        & rstSheetsFiltered!ft_s_num & " - не обнаружен лист в книге" _
                                                        & "</font></B>*</P>" _
                                                        & Me!adt_results
                                                    Else
                                                    'нет, имеется имя существующего листа
                                                    'открываем существующий лист
                                                    Set xlS = xlW.Worksheets(SheetName)
                                                    'сообщаем о обнаружении листа
                                                    Me!adt_results = _
                                                        "<P><B><font color=""navy"">" & DateTime.Now _
                                                        & "</font></B> -  Лист № " & rstSheetsFiltered!ft_s_num & " *<B><font color=""green"">" _
                                                        & xlS.name & " - обнаружен в книге" _
                                                        & "</font></B>*. Тип листа: *" & rstSheetsFiltered!st_name & "*</P>" _
                                                        & Me!adt_results
                                                        
                                                    'вызываем соответствующую процедуру
                                                    If Me!adt_type = 1 Then 'Ревизия по отчётам агентов
                                                        If rstFiltered!af_type = 1 Then 'Файл типа "отчёты агента"
                                                            If rstSheetsFiltered!st_key = 2 Then 'Лист типа "лист отчётного периода"
                                                            
                                                                'отыскиваем идентификатор отчётного периода соответствующий листу
                                                                'директория - Me!adt_dir, типовой лист - rstSheetsFiltered!ft_s_key
                                                                Set rstSheetsFilteredPeriod = db.OpenRecordset( _
                                                                    "SELECT rdsp_period FROM ra_dir_s_p WHERE rdsp_dir=" & Me!adt_dir & _
                                                                    " AND rdsp_ft_s=" & rstSheetsFiltered!ft_s_key & ";", _
                                                                    dbOpenSnapshot)
                                                                'имеется ли идентификатор отчётного периода?
                                                                If rstSheetsFilteredPeriod.RecordCount > 0 Then
                                                                    'да, идентификатор отчётного периода имеется
                                                                    RAAudit_RA_RepPeriod xlS, rstSheetsFilteredPeriod!rdsp_period, Me!adt_AddRA, _
                                                                        Me!adt_results, db, rstFiltered!ra_org_sender
                                                                    Else
                                                                    'нет, идентификатор отчётного периода отсутствует
                                                                    Me!adt_results = _
                                                                        "<P>" & DateTime.Now _
                                                                        & " -  Лист № " & rstSheetsFiltered!ft_s_num & " *<B><font color=""red"">" _
                                                                        & xlS.name & " - не имеет соспоставленного отчётного периода" _
                                                                        & "</font></B>*. Тип листа: *" & rstSheetsFiltered!st_name & "*</P>" _
                                                                        & Me!adt_results
                                                                End If
                                                                rstSheetsFilteredPeriod.Close
                                                                Set rstSheetsFilteredPeriod = Nothing
                                                            End If
                                                        End If
                                                        If rstFiltered!af_type = 4 Or rstFiltered!af_type = 6 Then 'Файл типа "агентское вознаграждение"
                                                            If rstSheetsFiltered!st_key = 4 Then 'Лист типа "лист месяца"
                                                            
                                                                'отыскиваем идентификатор месяца и года соответствующие листу
                                                                'директория - Me!adt_dir, типовой лист - rstSheetsFiltered!ft_s_key
                                                                Set rstSheetsFilteredPeriod = db.OpenRecordset( _
                                                                    "SELECT rdsm_y, rdsm_m FROM ra_dir_s_m WHERE rdsm_dir=" & Me!adt_dir & _
                                                                    " AND rdsm_ft_s=" & rstSheetsFiltered!ft_s_key & ";", _
                                                                    dbOpenSnapshot)
                                                                'имеется ли идентификаторы месяца и года?
                                                                If rstSheetsFilteredPeriod.RecordCount > 0 Then
                                                                    'да, идентификаторы месяца и года имеются
                                                                    ' -------------------------------------------------------------------------------
                                                                    ' вызываем процедуру *работаем с листом агентского вознаграждения за месяц* -----
                                                                    RAAudit_AgFee_Month xlS, rstSheetsFilteredPeriod!rdsm_y, _
                                                                        rstSheetsFilteredPeriod!rdsm_m, Me!adt_AddRA, Me!adt_results, _
                                                                        db, rstOafTest, Me!adt_key
                                                                    ' -------------------------------------------------------------------------------
                                                                    Else
                                                                    'нет, идентификаторы месяца и года отсутствуют
                                                                    Me!adt_results = _
                                                                        "<P>" & DateTime.Now _
                                                                        & " -  Лист № " & rstSheetsFiltered!ft_s_num & " *<B><font color=""red"">" _
                                                                        & xlS.name & " - не имеет соспоставленного месяца и года" _
                                                                        & "</font></B>*. Тип листа: *" & rstSheetsFiltered!st_name & "*</P>" _
                                                                        & Me!adt_results
                                                                End If
                                                                rstSheetsFilteredPeriod.Close
                                                                Set rstSheetsFilteredPeriod = Nothing
                                                            End If
' !!! 28.06.2023
                                                            If rstFiltered!af_type = 6 Then 'Файл типа "агентское вознаграждение 23-0628"
                                                                ' создаём дочерний объект *Ревизия ОА. Проверка файла Актов агентского вознаграждения*
                                                                objRa_aCarrent.ra_aAgFee23_06ChildAdd rstFiltered!af_key, db
                                                                
                                                                objRa_aCarrent.ra_aAgFee23_06Child.Audit xlS, db, xlA
                                                            End If
                                                            
                                                        End If
                                                    End If
                                                    
                                                    'освобождаем переменную листа
                                                    Set xlS = Nothing
                                                End If
                                                
                                                rstSheetsFiltered.MoveNext
                                                'работаем с отдельным листом - окончание --------------------------------------
                                            Loop
                                            Else
                                            Me!adt_results = _
                                            "<P>" & DateTime.Now _
                                            & " - *<B><font color=""red"">" _
                                            & "Тип файла не содержит листов" _
                                            & "</font></B>*</P>" _
                                            & Me!adt_results
                                        End If
                                        ' проходим по листам, окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                        
                                        If rstFiltered!af_type = 4 Then 'Файл типа "агентское вознаграждение"
                                            rstOafTest.Close: Set rstOafTest = Nothing
                                            
                                            ' проверяем на предмет лишних отчётов и их пунктов
'                                            strSql = "SELECT x.oafptOafSender, o.ogaCode, af.oafNum, af.oafDate, af.oafKey, afp.oafpKey, " _
'                                                & "cst.cstapIpgPnN, afp.oafpTotalArr, afp.oafpTotal, afpt.oafptPnKey, afpt.oafptOafName, " _
'                                                & "afpt.oafptOafDate, afpt.oafptOafKey " _
'                                                & "FROM (((((SELECT t.oafptOafSender FROM ogAgFeePnTest t GROUP BY t.oafptOafSender) AS x " _
'                                                & "LEFT JOIN ags_ogAg AS o ON x.oafptOafSender = o.ogaKey) LEFT JOIN ags_ogAgFee AS af " _
'                                                & "ON x.oafptOafSender = af.cstaAg) LEFT JOIN ags_ogAgFeeP AS afp ON af.oafKey = afp.oafpOaf) " _
'                                                & "LEFT JOIN ogAgFeePnTest AS afpt ON afp.oafpKey = afpt.oafptPnKey) LEFT JOIN ags_cstAgPn AS cst " _
'                                                & "ON afp.oafpCstAgPn = cst.cstapKey WHERE (((afpt.oafptOafKey) Is Null)) ORDER BY o.ogaCode, af.oafDate;"

                                            ' 16.03.2022 исправил ошибку в запросе, он брал к удалению акты за другие годы, не соответствующие году ревизии
                                                
                                            strSql = "SELECT x.oafptOafSender, o.ogaCode, af.oafNum, af.oafDate, af.oafKey, afp.oafpKey, " _
                                                & "cst.cstapIpgPnN, afp.oafpTotalArr, afp.oafpTotal, afpt.oafptPnKey, afpt.oafptOafName, " _
                                                & "afpt.oafptOafDate, afpt.oafptOafKey " _
                                                & "FROM (((((SELECT " _
                                                & "          t.oafptOafSender , t.oafptY " _
                                                & "          FROM ogAgFeePnTest t " _
                                                & "          GROUP BY t.oafptOafSender, t.oafptY " _
                                                & "        )  AS x LEFT JOIN ags_ogAg AS o ON x.oafptOafSender = o.ogaKey) " _
                                                & "         LEFT JOIN ags_ogAgFee AS af ON (x.oafptY = af.oafY) AND (x.oafptOafSender = af.cstaAg)) " _
                                                & "         LEFT JOIN ags_ogAgFeeP AS afp ON af.oafKey = afp.oafpOaf) " _
                                                & "         LEFT JOIN ogAgFeePnTest AS afpt ON afp.oafpKey = afpt.oafptPnKey) " _
                                                & "         LEFT JOIN ags_cstAgPn AS cst ON afp.oafpCstAgPn = cst.cstapKey " _
                                                & "WHERE (((afpt.oafptOafKey) Is Null)) " _
                                                & "ORDER BY o.ogaCode, af.oafDate;"
                                                
                                            Set rstOafTest = db.OpenRecordset(strSql, dbOpenSnapshot)
                                            If rstOafTest.RecordCount > 0 Then
                                                strWaste = "<P><font color=""silver"">Имеются лишние отчёты (пункты): "
                                                rstOafTest.MoveFirst
                                                Do Until rstOafTest.EOF
                                                    ' имеется ли пункт стройки отчёта в БД?
                                                    If IsNull(rstOafTest!oafpKey) = False Then
                                                        ' да, пункт стройки отчёта в БД имеется
                                                        strWaste = strWaste & "<font color=""Crimson"">" & rstOafTest!oafNum & " от " _
                                                            & rstOafTest!oafDate & "</font>(<font color=""Salmon"">" & rstOafTest!cstapIpgPnN _
                                                            & "</font>); "
                                                        ' нужно ли корректировать БД?
                                                        If Me!adt_AddRA Then
                                                            ' да, корректировать БД нужно
                                                            ' удаляем пункт стройки отчёта
                                                            strSql = "DELETE * FROM ags_ogAgFeeP where oafpKey = " & rstOafTest!oafpKey
                                                            Set qd = db.CreateQueryDef("", strSql)
                                                            qd.Execute dbFailOnError + dbSeeChanges
                                                            qd.Close: Set qd = Nothing
                                                            strWaste = strWaste & " <b><font color=""Olive"">Пункт удален</font></b>."
                                                            ' имеются ли у отчёта пункты строек помимо удаленного?
                                                            strSql = "SELECT * FROM ags_ogAgFeeP WHERE oafpOaf = " & rstOafTest!oafKey & ";"
                                                            Set rstOaf = db.OpenRecordset(strSql, dbOpenSnapshot)
                                                            If rstOaf.RecordCount > 0 Then
                                                                ' да, у отчёта пункты строек помимо удаленного имеются
                                                                ' не делаем ни чего
                                                                Else
                                                                ' да, у отчёта пункты строек помимо удаленного отсутствуют
                                                                ' удаляем отчёт
                                                                strSql = "DELETE * FROM ags_ogAgFee where oafKey = " & rstOafTest!oafKey
                                                                Set qd = db.CreateQueryDef("", strSql)
                                                                qd.Execute dbFailOnError + dbSeeChanges
                                                                qd.Close: Set qd = Nothing
                                                                strWaste = strWaste & " <b><font color=""Olive"">Отчёт удален</font></b>."
                                                            End If
                                                            rstOaf.Close: Set rstOaf = Nothing
                                                        End If
                                                        Else
                                                        ' нет, пункт стройки отчёта в БД отсутствует
                                                        strWaste = strWaste & "<font color=""Crimson"">" & rstOafTest!oafNum & " от " _
                                                            & rstOafTest!oafDate & "</font>; "
                                                        ' нужно ли корректировать БД?
                                                        If Me!adt_AddRA Then
                                                            ' да, корректировать БД нужно
                                                            ' удаляем отчёт
                                                            strSql = "DELETE * FROM ags_ogAgFee where oafKey = " & rstOafTest!oafKey
                                                            Set qd = db.CreateQueryDef("", strSql)
                                                            qd.Execute dbFailOnError + dbSeeChanges
                                                            qd.Close: Set qd = Nothing
                                                            strWaste = strWaste & " <b><font color=""Olive"">Отчёт удален</font></b>."
                                                        End If
                                                    End If
                                                    rstOafTest.MoveNext
                                                Loop
                                                strWaste = strWaste & "</font></P>"
                                                Me!adt_results = strWaste & Me!adt_results
                                            End If
                                            rstOafTest.Close: Set rstOafTest = Nothing
                                        End If
                                        
                                        rstSheetsFiltered.Close ': rstSheets.Close
                                        Set rstSheetsFiltered = Nothing ': Set rstSheets = Nothing
                                        
                                        ' завершили работу с файлом, который не является файлом аренды земли
                                    End If
                                        
                                    'закрываем файл
                                    xlW.Close SaveChanges:=False: Set xlW = Nothing
                                    
                                    Me!adt_results = "<P>" & DateTime.Now & " - Файл с именем *<B><font color=""blue"">" & strFile _
                                    & "</font></B>* в приложении закрыт</P>" & Me!adt_results
                                    
                                Else
                                'нет, файл не существует
                                Me!adt_results = "<P>Файл с именем *<B><font color=""red"">" & strFile _
                                    & "</font></B>* в файловой системе не обнаружен</P>" & Me!adt_results
                            End If
                            Else
                            ' нет, текущий файл не подлежит рассмотрению
                            If rstFiltered!af_type = 3 Then
                                Me!adt_results = "<P><font color=""silver"">Файл с именем *</font><B><font color=""slateblue"">" & strFile _
                                    & "</font></B><font color=""silver"">* рассмотрению, в соответствии с Вашим выбором, </font>" _
                                    & "<font color=""salmon"">не подлежит</font>.</P>" & Me!adt_results
                                Else
                                Me!adt_results = _
                                    "<P><font color=""silver"">Файл с именем *</font><font color=""slategray"">" _
                                    & strDir & "\</font><B><font color=""slateblue"">" & rstFiltered!af_name _
                                    & "</font></B><font color=""silver"">* рассмотрению, в соответствии с Вашим выбором, </font>" _
                                    & "<font color=""salmon"">не подлежит</font>.</P>" & Me!adt_results
                            End If
                        End If
                        rstFiltered.MoveNext
                    Loop ' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    
                    'закрываем приложение без сохранения книг
                    xlA.Quit: Set xlA = Nothing
                    
                    Me!adt_results = _
                    "<P>" & DateTime.Now _
                    & " - *<B><font color=""blue"">" _
                    & "Приложение Excel закрыто" _
                    & "</font></B>*</P>" _
                    & Me!adt_results
                    
                    Else
                    Me!adt_results = _
                    "<P>Директория с именем *<B><font color=""red"">" _
                    & strDir _
                    & "</font></B>* в файловой системе не обнаружена</P>" _
                    & Me!adt_results
                
                End If
                Set fso = Nothing
                
            End If
        End With
        rstDir.Close: Set rstDir = Nothing
        
        Else
        Me!adt_results = "<P>Не обнаружены файлы для рассмотрения</P>" & Me!adt_results
    End If

    rstFiltered.Close  ': rst.Close
    db.Close 'закрываем переменную базы данных -------------------------------------------------------------

    dFinish = DateTime.Now: dDateDiff = DateDiff("s", dStart, dFinish)

    Me!adt_results = "<P>В " & dFinish & " - *<B><font color=""blue"">" & "ревизия завершена" _
    & "</font></B>*. C " & dStart & " в течении " & dDateDiff \ 60 & " мин. " & dDateDiff - ((dDateDiff \ 60) * 60) & " сек., (всего " _
    & dDateDiff & " сек.).</P>" & Me!adt_results
    
    Me![ra_a>Ttl_t].Requery
    
    Else
    MsgBox ("Отсутствует идентификатор ревизии")

End If

NormalExit:
    Set qd = Nothing
    Set db = Nothing
    Set objRa_aCarrent = Nothing
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' отыскиваем смещения для требуемых столбцов источника "ХрСтрКнтрл". 31.03.2022 *********************************************************************
Private Function FindOffset(ByRef xlS As Excel.Worksheet, ByVal TextFind As String, ByVal startColumn As Integer, fff As Object) As Integer

    Dim c As Range

    Const cstrTitle As String _
        = "Функция *Отыскиваем смещения для требуемых столбцов источника, он же ~ХрСтрКнтрл~*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' отыскиваем ячейку по искомому тексту
    Set c = xlS.UsedRange.Find(what:=TextFind, LookAt:=xlWhole)
    
    ' ячейка нашлась?
    If Not c Is Nothing Then
        ' да, ячейка нашлась
        FindOffset = c.Column - startColumn
    Else
        ' нет, ячейка не нашлась
        FindOffset = 0
        fff = "<P> <font color=""silver"">Не найдена ячейка</font>, <font color=""salmon"">" & TextFind & "</font>.</P>" & fff
    End If

NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number, vbExclamation, cstrTitle
    Resume NormalExit

End Function
' отыскиваем смещения для требуемых столбцов источника "ХрСтрКнтрл". 31.03.2022. Окончание **********************************************************


' работаем с листом Отчётов всех агентов. 05.07.2022 ************************************************************************************************
Private Sub RAAudit_AllAgents( _
    xlS As Excel.Worksheet, addRa As Boolean, fff As Object, db As DAO.Database, ByVal AdtKey As Long, yyyy As Integer, _
    xlA As Object, bySource As Boolean _
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
    
    Dim ra_RA As Range, ra_r_RA As Range, ra_column As Integer
    Dim ra_r_offset As Integer, ra_Sign_offset As Integer
    Dim str As String
    
    Const cstrTitle As String _
        = "Процедура *Работаем с листом Отчётов всех агентов*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

'MsgBox ("Работаем с листом Отчётов всех агентов")

    ' снимаем фильтры листа, если есть
    If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
        xlS.ShowAllData
    End If

    'отыскиваем колонку номеров отчётов
    Set c = xlS.UsedRange.Find(what:="№ ОА", LookAt:=xlWhole)
    If Not c Is Nothing Then
        'присваиваем переменной ячейки номеров отчётов
        Set ra_r_RA = c: ra_column = c.Column
        
        fff = "<P> Найдена ячейка *№ ОА* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *№ ОА* <B><font color=""red"">не найдена</font></B></P>" & fff
    End If

    'отыскиваем колонку номеров строек
    Set c = xlS.UsedRange.Find(what:="Код стройки", LookAt:=xlWhole)
    If Not c Is Nothing Then
        'определяем смещение от номера отчёта до кода стройки
        ra_r_offset = c.Column - ra_r_RA.Column
        
        fff = "<P> Найдена ячейка *Код стройки* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>. Смещение - " & ra_r_offset & ".</P>" & fff
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *Код стройки* <B><font color=""red"">не найдена</font></B></P>" & fff
        ra_r_offset = 0
    End If

    'отыскиваем колонку признака
    Set c = xlS.UsedRange.Find(what:="Признак", LookAt:=xlWhole)
    If Not c Is Nothing Then
        'определяем смещение от номера отчёта до кода стройки
        ra_Sign_offset = c.Column - ra_r_RA.Column
        
        fff = "<P> Найдена ячейка *Признак* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>. Смещение - " & ra_Sign_offset & ".</P>" & fff
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *Признак* <B><font color=""red"">не найдена</font></B></P>" & fff
        ra_Sign_offset = 0
    End If

    ' найдена ли ячейка номеров отчёта и смещения?
    If Not ra_r_RA Is Nothing And ra_r_offset <> 0 And ra_Sign_offset <> 0 Then
        ' да, ячейка номеров отчёта и смещения найдены
        ' определяем диапазон отчётов до нижней ячейки
        Set ra_RA = xlS.Range( _
            xlS.Cells(ra_r_RA.Offset(1, 0).Row, ra_r_RA.Column), _
            xlS.Cells( _
                xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                xlS.Cells(ra_r_RA.Offset(1, 0).Row, ra_r_RA.Column).Column _
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
                    Set c = .Find(what:="*-???????-*", LookAt:=xlPart)
                    ' имеется ли имя соответствующее форме имени отчёта?
                    If Not c Is Nothing Then
                        ' да имя соответствующее форме имени отчёта имеется
                        ' простой отчет нашелся в колонке имен отчётов?
                        If c.Column = ra_column Then
                            ' да, простой отчёт нашелся в колонке имен отчётов
                            adr = c.Address
                            'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                            If c.Offset(0, ra_Sign_offset).value = "ОА изм" Then
                                'да, это именно изменение
                                str = "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                ' отправляем в процедуру обработки изменений
'                                DateRA = StrToDate(c.offset(0, 1).Value)
'                                ChangeOfReportOfAgent c.Value, DateRA, c.offset(0, ra_r_offset).Value, str, db, period, AddRA, _
'                                    c.offset(0, 2).Value, c.offset(0, 3).Value, c.offset(0, 4).Value, c.offset(0, 5).Value, _
'                                    c.offset(0, 6).Value, c.offset(0, 7).Value, c.offset(0, 8).Value, c.offset(0, 9).Value, _
'                                    ra_org_sender
                                Else
                                'нет, это простой отчёт
                                str = "<P>  <font color=""silver"">Найден отчёт</font> - <font color=""DarkGreen"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                ' Отправляем обнаруженный отчёт на обработку. ++++++
'                                DateRA = StrToDate(c.offset(0, 1).Value)
'                                ReportOfAgent c.Value, DateRA, c.offset(0, ra_r_offset).Value, period, AddRA, str, db, _
'                                    c.offset(0, 2).Value, c.offset(0, 3).Value, c.offset(0, 4).Value, c.offset(0, 5).Value, _
'                                    c.offset(0, 6).Value, c.offset(0, 7).Value, c.offset(0, 8).Value, c.offset(0, 9).Value, _
'                                    ra_org_sender, "ОА"
                            End If
                            Else
                            ' нет, простой отчёт нашелся не в колонке имен отчётов
                            str = "<P>  В столбце ячейки номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. Отчёт нашелся не в колонке имен отчётов</P>"
                            'fff = str & fff
                            GoTo NotRA 'Exit Sub
                        End If
                        Else
                        ' нет имя соответствующее форме имени отчёта отсутствует
                        str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                        'fff = str & fff
                        GoTo NotRA 'Exit Sub
                    End If
                    Do
                        Set c = .FindNext(c)
                        If (Not c.Address = adr) And (c.Column = ra_column) Then
                            'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                            If c.Offset(0, ra_Sign_offset).value = "ОА изм" Then
                                'да, это именно изменение
                                str = str & "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                Else
                                'нет, это простой отчёт
                                str = str & "<P>  <font color=""silver"">Найден отчёт</font> - <font color=""DarkGreen"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                ' Отправляем обнаруженный отчёт на обработку. ++++++
'                                DateRA = StrToDate(c.offset(0, 1).Value)
'                                ReportOfAgent c.Value, DateRA, c.offset(0, ra_r_offset).Value, period, AddRA, str, db, _
'                                c.offset(0, 2).Value, c.offset(0, 3).Value, c.offset(0, 4).Value, c.offset(0, 5).Value, _
'                                c.offset(0, 6).Value, c.offset(0, 7).Value, c.offset(0, 8).Value, c.offset(0, 9).Value, _
'                                ra_org_sender, "ОА"
                            End If
                        End If
                    Loop Until c.Address = adr
                    Else
                    ' нет, количество ячеек в диапазоне не больше одной
                    ' ищем собственно отчёт
                    Set c = .Find(what:="*-???????-*", LookAt:=xlPart)
                    ' имеется ли имя соответствующее форме имени отчёта?
                    If Not c Is Nothing Then
                        ' да имя соответствующее форме имени отчёта имеется
                        ' простой отчет нашелся в колонке имен отчётов?
                        If c.Column = ra_column Then
                            ' да, простой отчёт нашелся в колонке имен отчётов
                            adr = c.Address
                            'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                            If c.Offset(0, ra_Sign_offset).value = "ОА изм" Then
                                'да, это именно изменение
                                str = "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                ' отправляем в процедуру обработки изменений
'                                DateRA = StrToDate(c.offset(0, 1).Value)
'                                ChangeOfReportOfAgent c.Value, DateRA, c.offset(0, ra_r_offset).Value, str, db, period, AddRA, _
'                                    c.offset(0, 2).Value, c.offset(0, 3).Value, c.offset(0, 4).Value, c.offset(0, 5).Value, _
'                                    c.offset(0, 6).Value, c.offset(0, 7).Value, c.offset(0, 8).Value, c.offset(0, 9).Value, _
'                                    ra_org_sender
                                Else
                                'нет, это простой отчёт
                                str = "<P>  <font color=""silver"">Найден отчёт</font> - <font color=""DarkGreen"">" & c.value & "</font>, строка - " & c.Row _
                                & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                                & ".</P>"
                                ' Отправляем обнаруженный отчёт на обработку. ++++++
'                                DateRA = StrToDate(c.offset(0, 1).Value)
'                                ReportOfAgent c.Value, DateRA, c.offset(0, ra_r_offset).Value, period, AddRA, str, db, _
'                                    c.offset(0, 2).Value, c.offset(0, 3).Value, c.offset(0, 4).Value, c.offset(0, 5).Value, _
'                                    c.offset(0, 6).Value, c.offset(0, 7).Value, c.offset(0, 8).Value, c.offset(0, 9).Value, _
'                                    ra_org_sender, "ОА"
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
                
' метка для продолжения в случае отсутствия отчётов
NotRA:
                
            End With
            fff = str & fff: str = ""
        End If ' да, диапазон отчётов имеется
    End If ' да, ячейка номеров отчёта и смещения найдены

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' работаем с листом Отчётов всех агентов. 05.07.2022. Окончание *************************************************************************************


' работаем с листом первичных документов к договорам, он же "ХрСтрКнтрл" cn_PrDoc
Private Sub RAAudit_cn_PrDoc( _
    xlS As Excel.Worksheet, addRa As Boolean, fff As Object, db As DAO.Database, ByVal AdtKey As Long, yyyy As Integer, _
    xlA As Object, bySource As Boolean _
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

    Const cstrTitle As String _
        = "Процедура *Работаем с с листом первичных документов к договорам, он же ~ХрСтрКнтрл~*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' нужно ли формировать (обновлять) таблицу исходных данных по источнику? >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    If bySource Then
        ' да, формировать (обновлять) таблицу исходных данных по источнику нужно
        ' снимаем фильтры листа, если есть
        If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
            xlS.ShowAllData
        End If
        
        ' отыскиваем ячейку "Номер первичного документа"
        Set c = xlS.UsedRange.Find(what:="Номер первичного документа", LookAt:=xlPart)
        
        ' итог поисков ячейки "Номер первичного документа"
        If Not c Is Nothing Then
            ' ячейка "Номер первичного документа" найдена
            fff = "<P> <font color=""silver"">Найдена ячейка</font> *Номер первичного документа* колонка - " & c.Column & ", строка - " & c.Row & "." _
                & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
            ' запоминаем первичную колонку для рассчёта смещений
            startColumn = c.Column
            ' отыскиваем смещения для требуемых столбцов Дата первичного документа
            ' offsetCnpdDate = FindOffset(xlS, "Дата первичного документа", c.Column, fff)
                
            ' проходим по номерам отчётов
            
            Set ra_r = xlS.Range(c.Offset(1, 0), xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, c.Column))
    
            ' открываем набор строк для поиска отчётов
            'Set rstRa = db.OpenRecordset("ags_ralpRa", dbOpenSnapshot)
            
            ' ***************************************************************************************************************************************
            ' формируем таблицу исходных данных в клиенте БД ****************************************************************************************
            
            ' очищаем таблицу для хранения перечня пунктов первичного документа из источника
            strSql = "DELETE * FROM cn_PrDocImp"
            Set qd = db.CreateQueryDef("", strSql)
            qd.Execute dbFailOnError
            qd.Close: Set qd = Nothing
            
            ' открываем набор строк для хранения перечня пунктов первичного документа из источника
            Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp", dbOpenDynaset)
            
            iii = 0: eee = 0
            For Each r In ra_r
                If IsNull(r.value) = False And IsEmpty(r.value) = False Then
                    PrDocNum = CStr(r.value)
                    If PrDocNum <> "" Then
                        iii = iii + 1
                        'PrDocDate = CDate(r.offset(0, 1)): InvNum = CStr(r.offset(0, 2)): InvDate = CDate(r.offset(0, 3)): CnNum = CStr(r.offset(0, 4))
                        
                        textAdd = "<P> <font color=""silver"">Найден документ: <font color=""CadetBlue"">" & PrDocNum & "</font>" _
                            & " от " & PrDocDate _
                            & ", с/ф № <font color=""DarkOrchid"">" & invNum & "</font> от " & invDate & _
                            ", договор <b><font color=""Olive"">" & CnNum & "</font></b>."
                            
                        With rstCn_PrDocImp
                            .AddNew
                                !NumSequential = iii
                                
                                ' работаем с типом первичного документа
                                offsetFindet = FindOffset(xlS, "ВидЗаказаНаПоставку", startColumn, fff)
                                ' найдено смещение? (было 42)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !cnpdTpOrd = r.Offset(0, offsetFindet)
                                    
                                    ' пробуем отыскать тип первичного документа
                                    Set qdFindSv = db.QueryDefs("ags_PdSdRRcList")
                                    StringFindSv = "select pdtoKey from ags.cn_PrDocT where pdtoCode = '" & r.Offset(0, offsetFindet) & "'"
                                    qdFindSv.SQL = StringFindSv
                                    Set rsFindSv = qdFindSv.OpenRecordset(dbOpenSnapshot)
                                    If rsFindSv.RecordCount = 1 Then
                                        !cnpdTpOrdKey = rsFindSv!pdtoKey
                                    End If
                                    ' закрываем всё, что было нужно для поиска типа первичного документа
                                    rsFindSv.Close: Set rsFindSv = Nothing: qdFindSv.Close: Set qdFindSv = Nothing
                                End If
                                
                                ' работаем с объектом САК
                                offsetFindet = FindOffset(xlS, "Определение проекта", startColumn, fff)
                                ' найдено смещение? (было 69)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    ' вносим код объекта САК строчный
                                    !pdpCstAgPnStr = r.Offset(0, offsetFindet)
                                    ' вносим ключ объекта САК
                                    If FindCstAP(r.Offset(0, offsetFindet), cstapKey, db) Then
                                        !pdpCstAgPnKey = cstapKey
                                    End If
                                End If
                                
                                !cnpdNum = PrDocNum
                                
                                ' работаем с датой первичного документа
                                offsetFindet = FindOffset(xlS, "Дата первичного документа", startColumn, fff)
                                ' найдено смещение? (было 1)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !cnpdDate = CDate(r.Offset(0, offsetFindet))
                                End If
                                
                                ' работаем с номером счёта-фактуры
                                offsetFindet = FindOffset(xlS, "Номер вх. Счета-фактуры", startColumn, fff)
                                ' найдено смещение? (было 2)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !cnpdCnInvNum = CStr(r.Offset(0, offsetFindet))
                                End If
                                
                                ' работаем с датой счёта-фактуры
                                offsetFindet = FindOffset(xlS, "Дата вх. Счета-фактуры", startColumn, fff)
                                ' найдено смещение? (было 3)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !cnpdCnInvDate = CDate(r.Offset(0, offsetFindet))
                                    End If
                                End If
                                
                                ' работаем с номером договора
                                offsetFindet = FindOffset(xlS, "Договор", startColumn, fff)
                                ' найдено смещение? (было 4)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !cnpdCnNum = CStr(r.Offset(0, offsetFindet))
                                End If
                                
                                ' работаем с "Статус ДИС  (текст)"
                                offsetFindet = FindOffset(xlS, "Статус ДИС  (текст)", startColumn, fff)
                                ' найдено смещение? (было 7)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !StatusOfDICtext = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Статус ОУКВ  (текст)"
                                offsetFindet = FindOffset(xlS, "Статус ОУКВ  (текст)", startColumn, fff)
                                ' найдено смещение? (было 11)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !satstusOfOUKVtext = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Сумма"
                                offsetFindet = FindOffset(xlS, "Сумма", startColumn, fff)
                                ' найдено смещение? (было 13)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !summ = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Стоимость"
                                offsetFindet = FindOffset(xlS, "Стоимость", startColumn, fff)
                                ' найдено смещение? (было 14)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !cost = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Сумма налога"
                                offsetFindet = FindOffset(xlS, "Сумма налога", startColumn, fff)
                                ' найдено смещение? (было 16)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !SumTax = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Стоимость с НДС"
                                offsetFindet = FindOffset(xlS, "Стоимость с НДС", startColumn, fff)
                                ' найдено смещение? (было 17)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !costVAT = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "СПП-элемент"
                                offsetFindet = FindOffset(xlS, "СПП-элемент", startColumn, fff)
                                ' найдено смещение? (было 19)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !SPPelement = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "№ документа счета"
                                offsetFindet = FindOffset(xlS, "№ документа счета", startColumn, fff)
                                ' найдено смещение? (было 25)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !docOfAccountNum = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Дата счета"
                                offsetFindet = FindOffset(xlS, "Дата счета", startColumn, fff)
                                ' найдено смещение? (было 26)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !AccountDate = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Дата проводки"
                                offsetFindet = FindOffset(xlS, "Дата проводки", startColumn, fff)
                                ' найдено смещение? (было 27)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !positingDate = r.Offset(0, offsetFindet)
                                End If
                                
                                ' работаем с "Бухг. документ"
                                offsetFindet = FindOffset(xlS, "Бухг. документ", startColumn, fff)
                                ' найдено смещение? (было 28)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    !accountingDoc = r.Offset(0, offsetFindet) ' Бухг. документ
                                End If
                                
                                ' работаем с "Агент"
                                offsetFindet = FindOffset(xlS, "Агент", startColumn, fff)
                                ' найдено смещение? (было 35)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" _
                                        And IsNumeric(r.Offset(0, offsetFindet)) Then
                                        !agent = CLng(r.Offset(0, offsetFindet))
                                    End If
                                End If
                                
                                ' работаем с "Текст агента"
                                offsetFindet = FindOffset(xlS, "Текст агента", startColumn, fff)
                                ' найдено смещение? (было 36)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !TextOfAgent = r.Offset(0, offsetFindet) ' Текст агента
                                    End If
                                End If
                                
                                ' работаем с "Определение проекта", по нему же и стройку искали
                                offsetFindet = FindOffset(xlS, "Определение проекта", startColumn, fff)
                                ' найдено смещение? (было 69)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !prjctDefinition = r.Offset(0, offsetFindet) ' Определение проекта
                                    End If
                                End If
                                
                                ' работаем с "Краткое описание проекта"
                                offsetFindet = FindOffset(xlS, "Краткое описание проекта", startColumn, fff)
                                ' найдено смещение? (было 70)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !prjctDefinitionSort = r.Offset(0, offsetFindet) ' Краткое описание проекта
                                    End If
                                End If
                                
                                ' работаем с "Уровень в иерархии проекта"
                                offsetFindet = FindOffset(xlS, "Уровень в иерархии проекта", startColumn, fff)
                                ' найдено смещение? (было 71)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !prjctHierarchyLevel = r.Offset(0, offsetFindet) ' Уровень в иерархии проекта
                                    End If
                                End If
                                
                                ' работаем с "Номер вышестоящего СПП-Элемента"
                                offsetFindet = FindOffset(xlS, "Номер вышестоящего СПП-Элемента", startColumn, fff)
                                ' найдено смещение? (было 72)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !ParentSppElementNum = r.Offset(0, offsetFindet) ' Номер вышестоящего СПП-Элемента
                                    End If
                                End If
                                
                                ' работаем с "Объект"
                                offsetFindet = FindOffset(xlS, "Объект", startColumn, fff)
                                ' найдено смещение? (было 73)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !Object = r.Offset(0, offsetFindet) ' Объект
                                    End If
                                End If
                                
                                ' работаем с "Стройка/ПИР"
                                offsetFindet = FindOffset(xlS, "Стройка/ПИР", startColumn, fff)
                                ' найдено смещение? (было 74)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !cstDSW = r.Offset(0, offsetFindet) ' Стройка/ПИР
                                    End If
                                End If
                                
                                ' работаем с "Номер отчета Агента"
                                offsetFindet = FindOffset(xlS, "Номер отчета Агента", startColumn, fff)
                                ' найдено смещение? (было 75)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !raNum = r.Offset(0, offsetFindet) ' Номер отчета Агента
                                    End If
                                End If
                                
                                ' работаем с "Дата отчета Агента"
                                offsetFindet = FindOffset(xlS, "Дата отчета Агента", startColumn, fff)
                                ' найдено смещение? (было 76)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !raDate = r.Offset(0, offsetFindet) ' Дата отчета Агента
                                    End If
                                End If
                                
                                ' работаем с "Номер  исправления"
                                offsetFindet = FindOffset(xlS, "Номер  исправления", startColumn, fff)
                                ' найдено смещение? (было 88)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !CorrectionNum = r.Offset(0, offsetFindet) ' Номер  исправления
                                    End If
                                End If
                                
                                ' работаем с "Дата  исправления"
                                offsetFindet = FindOffset(xlS, "Дата  исправления", startColumn, fff)
                                ' найдено смещение? (было 89)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !CorrectionDate = r.Offset(0, offsetFindet) ' Дата  исправления
                                    End If
                                End If
                                
                                ' работаем с "Название бух док-та"
                                offsetFindet = FindOffset(xlS, "Название бух док-та", startColumn, fff)
                                ' найдено смещение? (было 90)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !accountingDocName = r.Offset(0, offsetFindet) ' Название бух док-та
                                    End If
                                End If
                                
                                ' работаем с "Группа закупок"
                                offsetFindet = FindOffset(xlS, "Группа закупок", startColumn, fff)
                                ' найдено смещение? (было 91)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !purchasingGroup = r.Offset(0, offsetFindet) ' Группа закупок
                                    End If
                                End If
                                
                                ' работаем с "Название ГрЗакупок"
                                offsetFindet = FindOffset(xlS, "Название ГрЗакупок", startColumn, fff)
                                ' найдено смещение? (было 92)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !purchasingGroupName = r.Offset(0, offsetFindet) ' Название ГрЗакупок
                                    End If
                                End If
                                
                                ' Текст кредитора и ИНН+КПП поставщика позволяют идентифицировать контрагента по договору
                                
                                ' работаем с "Текст кредитора"
                                offsetFindet = FindOffset(xlS, "Текст кредитора", startColumn, fff)
                                ' найдено смещение? (было 33)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !textOfCreditor = r.Offset(0, offsetFindet) ' Текст кредитора
                                    End If
                                End If
                                
                                ' работаем с "ИНН поставщика"
                                offsetFindet = FindOffset(xlS, "ИНН поставщика", startColumn, fff)
                                ' найдено смещение? (было 34)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !supplierTIN = r.Offset(0, offsetFindet) ' ИНН поставщика
                                    End If
                                End If
                                
                                ' работаем с "КПП поставщика"
                                offsetFindet = FindOffset(xlS, "КПП поставщика", startColumn, fff)
                                ' найдено смещение? (было 41)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !supplierKPP = r.Offset(0, offsetFindet) ' 41 КПП поставщика
                                    End If
                                End If
                                
                                ' работаем с "Основной счет"
                                offsetFindet = FindOffset(xlS, "Основной счет", startColumn, fff)
                                ' найдено смещение? (было 21)
                                If Not offsetFindet = 0 Then
                                    ' да, смещение найдено
                                    If IsEmpty(r.Offset(0, offsetFindet)) = False And r.Offset(0, offsetFindet) <> "" Then
                                        !AccountMain = r.Offset(0, offsetFindet) ' Основной счет
                                    End If
                                End If
                                
                            .Update
                        End With
                            
                        textAdd = textAdd & "</font></P>"
                        ' добавляем текст к тексту хода ревизии
                        fff = textAdd & fff
                    End If
                End If
            Next
            
            ' закрываем набор строк для хранения перечня отчётов из источника
            rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
            
            fff = "<P> <font color=""silver"">Всего записей: <font color=""LightSeaGreen"">" _
                & iii & "</font></font>.</P>" & fff
                
            ' формируем таблицу исходных данных в клиенте БД, окончание *****************************************************************************
            ' ***************************************************************************************************************************************
            
            Else
            ' ячейка "№ отчета" не найдена
            fff = "<P> <font color=""silver"">Ячейка</font> *Номер первичного документа* <font color=""red"">не найдена</font></P>" & fff
        End If
        
    Else
    ' нет, формировать (обновлять) таблицу исходных данных по источнику не нужно
    fff = "<P> <font color=""silver"">Обновлять данные </font> по источнику <font color=""Goldenrod""></b>не требуется</b></font></P>" & fff
        ' проверяем, соответствует ли таблица исходных данных проверяемому году
        strSql = "select year(positingDateFirst) As yyyy FROM (SELECT First(i.positingDate) AS positingDateFirst FROM cn_PrDocImp i) as z"
        Set rstCn_PrDocImp = db.OpenRecordset(strSql, dbOpenSnapshot)
        ' имеются ли записи в таблице исходных данных?
        If rstCn_PrDocImp.RecordCount > 0 Then
            ' да, записи в таблице исходных данных имеются
            rstCn_PrDocImp.MoveFirst
            ' создаём новый объект класса ревизии по известному ключу
            Set Ra_aNew = ClassFactory.Ra_aReadKey(AdtKey, db)
            ' имеется ли объект с указанным ключём?
            If Not Ra_aNew Is Nothing Then
                ' да, объект с указанным ключём имеется
                ' соответствует ли год таблицы исходных данных году ревизии?
                If rstCn_PrDocImp!yyyy = Ra_aNew.year(db) Then
                    ' да, год таблицы исходных данных году ревизии соответствует
                    ' ни чего не делаем, идём дальше
                Else
                    ' нет, год таблицы исходных данных году ревизии не соответствует
                    fff = _
                        "<P> <font color=""silver"">Год таблицы исходных данных </font> " _
                        & "году ревизии <font color=""Salmon""><b>не соответствует</b></font></P>" _
                        & fff
                    Exit Sub
                End If
            Else
                ' нет, объект с указанным ключём отсутствует
                fff = "<P><font color=""silver"">Отсутствет " _
                    & "<font color=""Goldenrod"">объект ревизии с ключем:</font>" & ra_aKey & "</font>.</P><P></P>" & fff
                Exit Sub
            End If
        Else
            ' нет, записи в таблице исходных данных отсутствуют
            fff = "<P> <font color=""silver"">Таблица </font> исходных данных <font color=""Salmon""><b>пуста</b></font></P>" & fff
            Exit Sub
        End If
        rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
    End If
    ' нужно ли формировать (обновлять) таблицу исходных данных по источнику? Окончание. >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        
    ' *******************************************************************************************************************************************
    ' работаем с перечнем контрагентов **********************************************************************************************************
    
    ' открываем набор записей контрагентов из таблицы исходных данных в клиенте БД
    
    Set rstCn_PrDocImp = db.OpenRecordset( _
        "SELECT x.textOfCreditor, z.supplierTIN, w.supplierKPP FROM ((SELECT textOfCreditor FROM cn_PrDocImp GROUP BY textOfCreditor) AS x LEFT JOIN (SELECT textOfCreditor, supplierTIN FROM (SELECT textOfCreditor, supplierTIN FROM cn_PrDocImp WHERE supplierTIN Is Not Null)  AS y GROUP BY textOfCreditor, supplierTIN)  AS z ON x.textOfCreditor = z.textOfCreditor) left join (SELECT textOfCreditor, supplierKPP FROM cn_PrDocImp GROUP BY textOfCreditor, supplierKPP) as w on x.textOfCreditor = w.textOfCreditor", _
        dbOpenSnapshot)
        
    ' имеются ли наименования контрагентов?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, наименования контрагентов имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем с перечнем контрагентов</font>. Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
        ' проходим по каждому наименованию контрагента
        rstCn_PrDocImp.MoveFirst
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найден <font color=""CadetBlue"">" & rstCn_PrDocImp!textOfCreditor & "</font>"
            ' имеется ли ИНН у контрагента?
            If IsNull(rstCn_PrDocImp!supplierTIN) = False Then
                ' да, ИНН у контрагента имеется +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                ' но имеется ли КПП у контрагента?
                If IsNull(rstCn_PrDocImp!supplierKPP) = False Then
                    ' да, КПП у контрагента имеется
                    strFFF = strFFF & ", ИНН: <font color=""CornflowerBlue"">" & rstCn_PrDocImp!supplierTIN & "</font>" _
                        & ", КПП: <font color=""CornflowerBlue"">" & rstCn_PrDocImp!supplierKPP & "</font>"
                    ' ищем ключ идентификатора организации по ИНН и КПП =========================================================================
                    StringFindSv = "select i.org_id_key, i.org, o.ogNm from ags.org_id i left join ags.og o on i.org = o.ogKey " _
                        & "where i.org_id_value_t = '" & rstCn_PrDocImp!supplierTIN _
                        & "' and i.org_id_value_t_ext = '" & rstCn_PrDocImp!supplierKPP & "' group by i.org_id_key, i.org, o.ogNm"
                    intFind = 0: intFind2 = 0: strFind = ""
                    ' найден ли ключ идентификатора организации по ИНН и КПП?
                    If FindOneKey(db:=db, StringFindSv:=StringFindSv, KeyFieldName:="org_id_key", key:=intFind, _
                        KeyFieldName2:="org", key2:=intFind2, strValueField:="ogNm", strValue:=strFind) Then
                        ' да, ключ идентификатора организации по ИНН и КПП найден
                        strFFF = strFFF & ". По ИНН+КПП ключ OrgID: <font color=""Olive"">" & intFind & "</font>, ключ Og: " & intFind2 _
                            & ", <font color=""CornflowerBlue"">" & strFind & "</font>"
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы ..........................................
                        strSql = "UPDATE cn_PrDocImp SET cn_PrDocImp.supplierOrgId = " & intFind & " " _
                            & "WHERE (((cn_PrDocImp.supplierTIN)=""" & rstCn_PrDocImp!supplierTIN & """) " _
                            & "AND ((cn_PrDocImp.supplierKPP)=""" & rstCn_PrDocImp!supplierKPP & """));"
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError
                        qd.Close: Set qd = Nothing
                        strFFF = strFFF & ". <font color=""Olive"">Ключ исп. внесен</font>"
                        ' но ещё могут быть записи, в которых есть только наименование и КПП - - - - - - - - - - - - - - - - - - - - - - - - - -*
                        ' внесём их тоже
                        strSql = "UPDATE cn_PrDocImp SET supplierOrgId = " & intFind & " " _
                            & "WHERE (((textOfCreditor)=""" & rstCn_PrDocImp!textOfCreditor & """) " _
                            & "AND ((supplierKPP)=""" & rstCn_PrDocImp!supplierKPP & """));"
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError
                        qd.Close: Set qd = Nothing
                        strFFF = strFFF & ". КПП+имя <font color=""Olive"">Ключ исп. внесен</font>"
                        ' но ещё могут быть записи, в которых есть только наименование и КПП, окончание  - - - - - - - - - - - - - - - - - - - -*
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы, окончание ...............................
                        Else
                        ' нет, ключ идентификатора организации по ИНН и КПП не найден
                        strFFF = strFFF & ". Ключи по ИНН+КПП <font color=""Salmon"">не найдены</font>"
                        ' отыскиваем по ИНН и наименованию --------------------------------------------------------------------------------------
                        StringFindSv = "select i.org_id_key, i.org, n.ogNm from ags.org_id i left join ags.ogNmF_allVariants o on i.org = o.ogKey " _
                            & "left join ags.og n on i.org = n.ogKey where i.org_id_value_t = '" & rstCn_PrDocImp!supplierTIN & "' " _
                            & "and o.ogNm = '" & rstCn_PrDocImp!textOfCreditor & "' group by i.org_id_key, i.org, n.ogNm"
                        intFind = 0: intFind2 = 0: strFind = ""
                        ' найден ли ключ идентификатора организации по ИНН и наименованию?
                        If FindOneKey(db:=db, StringFindSv:=StringFindSv, KeyFieldName:="org_id_key", key:=intFind, _
                            KeyFieldName2:="org", key2:=intFind2, strValueField:="ogNm", strValue:=strFind) Then
                            ' да, ключ идентификатора организации по ИНН и наименованию найден
                            strFFF = strFFF & ". По ИНН+имя ключ OrgID: <font color=""Olive"">" & intFind & "</font>, ключ Og: " & intFind2 _
                                & ", <font color=""CornflowerBlue"">" & strFind & "</font>"
                            ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы ......................................
                            strSql = "UPDATE cn_PrDocImp SET supplierOrgId = " & intFind & " " _
                                & "WHERE (((textOfCreditor)=""" & rstCn_PrDocImp!textOfCreditor & """) " _
                                & "AND ((supplierTIN)=""" & rstCn_PrDocImp!supplierTIN & """));"
                            Set qd = db.CreateQueryDef("", strSql)
                            qd.Execute dbFailOnError
                            qd.Close: Set qd = Nothing
                            strFFF = strFFF & ". <font color=""Olive"">Ключ исп. внесен</font>"
                            ' но ещё могут быть записи, в которых есть только наименование и КПП - - - - - - - - - - - - - - - - - - - - - - - -*
                            ' внесём их тоже
                            strSql = "UPDATE cn_PrDocImp SET supplierOrgId = " & intFind & " " _
                                & "WHERE (((textOfCreditor)=""" & rstCn_PrDocImp!textOfCreditor & """) " _
                                & "AND ((supplierKPP)=""" & rstCn_PrDocImp!supplierKPP & """));"
                            Set qd = db.CreateQueryDef("", strSql)
                            qd.Execute dbFailOnError
                            qd.Close: Set qd = Nothing
                            strFFF = strFFF & ". КПП+имя <font color=""Olive"">Ключ исп. внесен</font>"
                            ' но ещё могут быть записи, в которых есть только наименование и КПП, окончание  - - - - - - - - - - - - - - - - - -*
                            ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы, окончание ...........................
                            Else
                            ' нет, ключ идентификатора организации по ИНН и наименованию не найден
                            strFFF = strFFF & ". Ключи по ИНН+имя <font color=""Salmon"">не найдены</font>"
                        End If ' ----------------------------------------------------------------------------------------------------------------
                    End If ' ====================================================================================================================
                    
                    Else
                    ' нет, КПП у контрагента отсутсвует
                    strFFF = strFFF & ", ИНН: <font color=""CornflowerBlue"">" & rstCn_PrDocImp!supplierTIN & "</font>" _
                        & ", КПП: <font color=""Salmon"">отсутствует</font>"
                    ' отыскиваем по ИНН и наименованию ------------------------------------------------------------------------------------------
                    StringFindSv = "select i.org_id_key, i.org, n.ogNm from ags.org_id i left join ags.ogNmF_allVariants o on i.org = o.ogKey " _
                        & "left join ags.og n on i.org = n.ogKey where i.org_id_value_t = '" & rstCn_PrDocImp!supplierTIN & "' " _
                        & "and o.ogNm = '" & rstCn_PrDocImp!textOfCreditor & "' group by i.org_id_key, i.org, n.ogNm"
                    intFind = 0: intFind2 = 0: strFind = ""
                    ' найден ли ключ идентификатора организации по ИНН и наименованию?
                    If FindOneKey(db:=db, StringFindSv:=StringFindSv, KeyFieldName:="org_id_key", key:=intFind, _
                        KeyFieldName2:="org", key2:=intFind2, strValueField:="ogNm", strValue:=strFind) Then
                        ' да, ключ идентификатора организации по ИНН и наименованию найден
                        strFFF = strFFF & ". По ИНН+имя ключ OrgID: <font color=""Olive"">" & intFind & "</font>, ключ Og: " & intFind2 _
                            & ", <font color=""CornflowerBlue"">" & strFind & "</font>"
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы ......................................
                        strSql = "UPDATE cn_PrDocImp SET supplierOrgId = " & intFind & " " _
                            & "WHERE (((textOfCreditor)=""" & rstCn_PrDocImp!textOfCreditor & """) " _
                            & "AND ((supplierTIN)=""" & rstCn_PrDocImp!supplierTIN & """));"
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError
                        qd.Close: Set qd = Nothing
                        strFFF = strFFF & ". <font color=""Olive"">Ключ исп. внесен</font>"
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы, окончание ...........................
                        Else
                        ' нет, ключ идентификатора организации по ИНН и наименованию не найден
                        strFFF = strFFF & ". Ключи по ИНН+имя <font color=""Salmon"">не найдены</font>"
                    End If ' --------------------------------------------------------------------------------------------------------------------
                End If
                ' да, ИНН у контрагента имеется, окончание ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                Else
                ' нет, ИНН у контрагента отсутствует ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                ' но имеется ли КПП у контрагента?
                If IsNull(rstCn_PrDocImp!supplierKPP) = False Then
                    ' да, КПП у контрагента имеется
                    strFFF = strFFF & ", ИНН: <font color=""Salmon"">отсутствует</font>" _
                        & ", КПП: <font color=""CornflowerBlue"">" & rstCn_PrDocImp!supplierKPP & "</font>"
                    ' отыскиваем по КПП и наименованию ------------------------------------------------------------------------------------------
                    StringFindSv = "select i.org_id_key, i.org, n.ogNm from ags.org_id i left join ags.ogNmF_allVariants o on i.org = o.ogKey " _
                        & "left join ags.og n on i.org = n.ogKey " _
                        & "where i.org_id_value_t_ext = '" & rstCn_PrDocImp!supplierKPP & "' " _
                        & "and o.ogNm = '" & rstCn_PrDocImp!textOfCreditor & "' group by i.org_id_key, i.org, n.ogNm"
                    intFind = 0: intFind2 = 0: strFind = ""
                    ' найден ли ключ идентификатора организации по КПП и наименованию?
                    If FindOneKey(db:=db, StringFindSv:=StringFindSv, KeyFieldName:="org_id_key", key:=intFind, _
                        KeyFieldName2:="org", key2:=intFind2, strValueField:="ogNm", strValue:=strFind) Then
                        ' да, ключ идентификатора организации по КПП и наименованию найден
                        strFFF = strFFF & ". По КПП+имя ключ OrgID: <font color=""Olive"">" & intFind & "</font>, ключ Og: " & intFind2 _
                            & ", <font color=""CornflowerBlue"">" & strFind & "</font>"
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы ......................................
                        strSql = "UPDATE cn_PrDocImp SET supplierOrgId = " & intFind & " " _
                            & "WHERE (((textOfCreditor)=""" & rstCn_PrDocImp!textOfCreditor & """) " _
                            & "AND ((supplierKPP)=""" & rstCn_PrDocImp!supplierKPP & """));"
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError
                        qd.Close: Set qd = Nothing
                        strFFF = strFFF & ". <font color=""Olive"">Ключ исп. внесен</font>"
                        ' вносим идентификатор исполнителя по договору в соответсвующие записи таблицы, окончание ...........................
                        Else
                        ' нет, ключ идентификатора организации по КПП и наименованию не найден
                        strFFF = strFFF & ". Ключи по КПП+имя <font color=""Salmon"">не найдены</font>"
                    End If ' --------------------------------------------------------------------------------------------------------------------
                    Else
                    ' нет, КПП у контрагента отсутсвует
                    strFFF = strFFF & ", ИНН: <font color=""Salmon"">отсутствует</font>" _
                        & ", КПП: <font color=""Salmon"">отсутствует</font>"
                End If
                ' нет, ИНН у контрагента отсутствует, окончание +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            End If
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        Else
        ' нет, наименования контрагентов отсутствуют
    End If
    
    ' закрываем набор записей контрагентов из таблицы исходных данных в клиенте БД
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
    
    ' работаем с перечнем контрагентов, окончание
    ' *******************************************************************************************************************************************
    
    ' *******************************************************************************************************************************************
    ' работаем с договорами *********************************************************************************************************************
    Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_Cn", dbOpenSnapshot)
    
    ' имеются ли договора?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, договора имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем с перечнем договоров</font>. Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
        ' проходим по каждому договору
        rstCn_PrDocImp.MoveFirst
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найден <font color=""CadetBlue"">" & rstCn_PrDocImp!cnpdCnNum & "</font>" _
                & ", <font color=""Gray"">" & rstCn_PrDocImp!textOfCreditor & "</font>"
            ' имеются ли соответствующие договор и сторона договора?
            If rstCn_PrDocImp!cn_s_org_keyCount > 0 Then
                ' да, соответствующие договор и сторона договора имеются
                ' соответствующих более одного?
                If rstCn_PrDocImp!cn_s_org_keyCount > 1 Then
                    ' да, соответствующих более одного
                    strFFF = strFFF & ". Соответствующих договоров и сторон договора <font color=""Salmon"">больше чем один...</font> Очень странно."
                    Else
                    ' нет, соответсвующий один
                    strFFF = strFFF & ". Договор <font color=""CadetBlue"">" & rstCn_PrDocImp!cn_key & "</font>" _
                        & ", сторона+орг. прост. " & rstCn_PrDocImp!csosKey
                    ' вносим в таблицу данные договоров, которые удалось обнаружить
                    strSql = "UPDATE cn_PrDocImp SET cn_PrDocImp.cn_key = " & rstCn_PrDocImp!cn_key & ", " _
                        & "cn_PrDocImp.cn_s_key = " & rstCn_PrDocImp!cn_s_key & ", " _
                        & "cn_PrDocImp.csosKey = " & rstCn_PrDocImp!csosKey & " " _
                        & "WHERE (((cn_PrDocImp.cnpdCnNum)=""" & rstCn_PrDocImp!cnpdCnNum & """) " _
                        & "AND ((cn_PrDocImp.supplierOrgId)=" & rstCn_PrDocImp!supplierOrgId & "));"
                        '& "cn_PrDocImp.cn_s_org_key = " & rstCn_PrDocImp!cn_s_org_key & " " '_
                    Set qd = db.CreateQueryDef("", strSql)
                    qd.Execute dbFailOnError
                    qd.Close: Set qd = Nothing
                    strFFF = strFFF & ". <font color=""Olive"">Внесено</font>"
                End If
                Else
                ' нет, соответствующие договор и сторона договора отсутствуют
                strFFF = strFFF & ". Соответствующие договор и сторона договора <font color=""Salmon"">не найдены</font>"
            End If
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        Else
        ' нет, договора отсутствуют
    End If
    ' закрываем набор записей договоров из таблицы исходных данных в клиенте БД
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
    

    ' работаем с договорами, окончание **********************************************************************************************************
    ' *******************************************************************************************************************************************
    
    ' проверяем наличие связи между договорами и счетами-фактурами 21.03.2022 *******************************************************************
    RAAudit_cn_PrDoc_cnInvNt db, fff, addRa
    ' если базу обновляли, то посмотрим что получилось
    If addRa Then
        RAAudit_cn_PrDoc_cnInvNt db, fff, False
    End If
    ' проверяем наличие связи между договорами и счетами-фактурами, окончание *******************************************************************

    ' работаем со счетами-фактурами не имеющими соответствующих объектов *Факт связи тройки: 1. пара *Счёт-фактура + Договор*, ******************
    ' 2. счёт главной книги, 3. организации-простой стороне договора*. 23.03.2022 ***************************************************************
    RAAudit_cn_PrDoc_cnInvExCsosNt db, fff, addRa
    If addRa Then
        RAAudit_cn_PrDoc_cnInvExCsosNt db, fff, False
    End If
    ' работаем со счетами-фактурами не имеющими соответствующих объектов *Факт связи тройки: 1. пара *Счёт-фактура + Договор*, ******************
    ' 2. счёт главной книги, 3. организации-простой стороне договора*. 23.03.2022. Окончание ****************************************************

    ' работаем со счетами-фактурами не имеющими соответствующих первичных документов. 24.03.2022 ************************************************
    RAAudit_cn_PrDoc_cnInvExCsosExPdNt db, fff, addRa
    ' если базу обновляли, то посмотрим что получилось
    If addRa Then
        RAAudit_cn_PrDoc_cnInvExCsosExPdNt db, fff, False
    End If
    ' работаем со счетами-фактурами не имеющими соответствующих первичных документов. 24.03.2022, окончание *************************************

    ' работаем со строками исходного документа не имеющими соответствующих пунктов в БД. 25.03.2022 *********************************************
    RAAudit_cn_PrDoc_cnInvExCsosExPdExPnNt db, fff, addRa
    ' если базу обновляли, то посмотрим что получилось
    If addRa Then
        RAAudit_cn_PrDoc_cnInvExCsosExPdExPnNt db, fff, False
    End If
    ' работаем со строками исходного документа не имеющими соответствующих пунктов в БД. 25.03.2022. Окончание **********************************

    ' работаем со строками исходного документа имеющими соответствующие пункты в БД. 29.03.2022 *************************************************
    RAAudit_cn_PrDoc_cnInvExCsosExPdExPnExRs db, fff, addRa
    ' если базу обновляли, то посмотрим что получилось
    If addRa Then
        RAAudit_cn_PrDoc_cnInvExCsosExPdExPnExRs db, fff, False
    End If
    ' работаем со строками исходного документа имеющими соответствующие пункты в БД. 29.03.2022. Окончание **************************************

    ' проверяем совпадение результатов по году
    RAAudit_cn_PrDoc_Compare AdtKey, db, fff, addRa

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' проверяем совпадение результатов по году. 04.04.2022 **********************************************************************************************
Private Sub RAAudit_cn_PrDoc_Compare(ByVal ra_aKey As Long, db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, Ra_aNew As ra_a, addCount As Integer, ciasN As Cias
    Dim qdef As DAO.QueryDef
    
    Const cstrTitle As String _
        = "Процедура *Проверяем совпадение результатов по году*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' создаём новый объект класса по известному ключу
    Set Ra_aNew = ClassFactory.Ra_aReadKey(ra_aKey, db)
    ' имеется ли объект с указанным ключём?
    If Not Ra_aNew Is Nothing Then
        ' да, объект с указанным ключём имеется
        ' получаем запрос со сравнением годовых значений
        Set qdef = db.QueryDefs("cn_PrDocImp_Compare")
        qdef.Parameters!yyyy = Ra_aNew.year(db)
        ' открываем набор записей
        Set rstCn_PrDocImp = qdef.OpenRecordset(dbOpenSnapshot)
        
        ' имеются ли записи?
        If rstCn_PrDocImp.RecordCount > 0 Then
            ' да, записи имеются
            rstCn_PrDocImp.MoveLast
            fff = "<P><font color=""silver"">Имеются " _
                & "<font color=""Goldenrod""><b>~строки сравнения~</b></font></font>. " _
                & "Всего их : <b><font color=""Goldenrod"">" _
                & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
            ' проходим по каждой записи
            rstCn_PrDocImp.MoveFirst ': addCount = 0
            Do Until rstCn_PrDocImp.EOF
                strFFF = "Сравниваем: Год: <font color=""Chocolate"">" & rstCn_PrDocImp!yyyy & "</font>" _
                    & ", счёт ГК: <font color=""Gray"">" & rstCn_PrDocImp!account_num & "</font>" _
                    & ", имя: <font color=""SlateBlue""><b>" & rstCn_PrDocImp!account_name & "</b></font>" _
                    & ". стройка: <font color=""SandyBrown"">" & rstCn_PrDocImp!cstapIpgPnN & "</font>"
                    ' отсутствуют ли разночтения в результатах?
                    If rstCn_PrDocImp!compareRslt Then
                        ' да, разночтения в результатах отсутствуют
                        strFFF = strFFF & ". <font color=""LightSeaGreen""><b>Всё: +</b></font>"
                    Else
                        ' нет, разночтения в результатах встречаются
                        strFFF = strFFF & ". <font color=""DeepPink""><b>Есть: -</b></font>"
                        If (Not rstCn_PrDocImp!dSummSum = 0) Or IsNull(rstCn_PrDocImp!dSummSum) Then
                            strFFF = strFFF & ". <font color=""LightSeaGreen"">dSummSum: </font> " _
                            & " бд: <font color=""MediumVioletRed"">" & FormatCurrency(rstCn_PrDocImp!summSum) & "</font>," _
                            & " ист: <font color=""DodgerBlue"">" & FormatCurrency(rstCn_PrDocImp!iSummSum) & "</font>," _
                            & " разность: <font color=""DarkOrange"">" & FormatCurrency(rstCn_PrDocImp!dSummSum) & "</font>"
                        End If
                        If (Not rstCn_PrDocImp!dCostSum = 0) Or IsNull(rstCn_PrDocImp!dCostSum) Then
                            strFFF = strFFF & ". <font color=""LightSeaGreen"">dCostSum: </font> " _
                            & " бд: <font color=""MediumVioletRed"">" & FormatCurrency(rstCn_PrDocImp!costSum) & "</font>," _
                            & " ист: <font color=""DodgerBlue"">" & FormatCurrency(rstCn_PrDocImp!iCostSum) & "</font>," _
                            & " разность: <font color=""DarkOrange"">" & FormatCurrency(rstCn_PrDocImp!dCostSum) & "</font>"
                        End If
                        If (Not rstCn_PrDocImp!dSumTaxSum = 0) Or IsNull(rstCn_PrDocImp!dSumTaxSum) Then
                            strFFF = strFFF & ". <font color=""LightSeaGreen"">dSumTaxSum: </font> " _
                            & " бд: <font color=""MediumVioletRed"">" & FormatCurrency(rstCn_PrDocImp!SumTaxSum) & "</font>," _
                            & " ист: <font color=""DodgerBlue"">" & FormatCurrency(rstCn_PrDocImp!iSumTaxSum) & "</font>," _
                            & " разность: <font color=""DarkOrange"">" & FormatCurrency(rstCn_PrDocImp!dSumTaxSum) & "</font>"
                        End If
                        If (Not rstCn_PrDocImp!dCostVATSum = 0) Or IsNull(rstCn_PrDocImp!dCostVATSum) Then
                            strFFF = strFFF & ". <font color=""LightSeaGreen"">dCostVATSum: </font> " _
                            & " бд: <font color=""MediumVioletRed"">" & FormatCurrency(rstCn_PrDocImp!costVATSum) & "</font>," _
                            & " ист: <font color=""DodgerBlue"">" & FormatCurrency(rstCn_PrDocImp!icostVATSum) & "</font>," _
                            & " разность: <font color=""DarkOrange"">" & FormatCurrency(rstCn_PrDocImp!dCostVATSum) & "</font>"
                        End If
                        
'                        strFFF = strFFF & ". Ранее не встречался"
                        ' нужно ли обновлять базу данных?
'                        If AddRA Then
'                            ' да, обновлять базу данных нужно
'                            ' создаём новый объект ~первичный документ~
'                            Set prDocNew = ClassFactory.prDocCreateNew(rstCn_PrDocImp!cnpdNumNull, rstCn_PrDocImp!cnpdDateNull, _
'                                rstCn_PrDocImp!cnpdTpOrdKey, rstCn_PrDocImp!ciasKey, db, "Для первичных документов")
'                            strFFF = strFFF & ". <font color=""OliveDrab""><b>Добавлено</b></font>, cnpdKey: <font color=""Green"">" _
'                                & prDocNew.cnpdKey & "</font>"
'                            ' ликвидируем новый объект ~первичный документ~
'                            Set prDocNew = Nothing
'                            addCount = addCount + 1
'                        End If
                    End If
                rstCn_PrDocImp.MoveNext
                fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
            Loop
'            If addCount > 0 Then
'                fff = "<P> Создано для счётов-фактур объектов ~первичный документ~: <font color=""MediumSeaGreen""><b>" _
'                    & addCount & "</b></font>.</P>" & fff
'            End If
            Else
            ' нет, счета-фактуры не связанные с соответствующими объектами отсутствуют
            fff = "<P><font color=""silver"">Отсутствуют " _
                & "<font color=""Goldenrod"">~строки сравнения~</font></font>.</P><P></P>" & fff
        End If
        ' закрываем набор записей
        rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing: Set qdef = Nothing
    Else
        ' нет, объект с указанным ключём отсутствует
        fff = "<P><font color=""silver"">Отсутствет " _
            & "<font color=""Goldenrod"">объект ревизии с ключем:</font>" & ra_aKey & "</font>.</P><P></P>" & fff
    End If

        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' проверяем совпадение результатов по году. 04.04.2022. Окончание ***********************************************************************************




' работаем со счетами-фактурами не имеющими соответствующих объектов *Факт связи тройки: 1. пара *Счёт-фактура + Договор*, **************************
' 2. счёт главной книги, 3. организации-простой стороне договора*. 23.03.2022 ***********************************************************************
Private Sub RAAudit_cn_PrDoc_cnInvExCsosNt(db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, cnInv As cnInv, addCount As Integer, ciasN As Cias
    
    Const cstrTitle As String _
        = "Процедура *Работаем со Счетами-фактурами не имеющими соответствующих объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' открываем набор записей
    Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_CnInvExCsosNt", dbOpenSnapshot)
    
    ' имеются ли счета-фактуры не связанные с соответствующими объектами?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, счета-фактуры не связанные с соответствующими объектами имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем со Счетами-фактурами не имеющими объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~</font>. " _
            & "Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
        ' проходим по каждому счёту-фактуре
        rstCn_PrDocImp.MoveFirst: addCount = 0
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найден счёт-фактура. Договор: <font color=""CadetBlue"">" & rstCn_PrDocImp!CnNum & "</font>" _
                & ", cn_key: <font color=""Gray"">" & rstCn_PrDocImp!cn_key & "</font>" _
                & ". Счёт-фактура, №: <font color=""DarkOrchid"">" & rstCn_PrDocImp!CnInvNum & "</font>" _
                & ". дата: <font color=""DarkOrchid"">" & rstCn_PrDocImp!CnInvDate & "</font>" _
                & ". ciKey: <font color=""Gray"">" & rstCn_PrDocImp!ciKey & "</font>" _
                & ". csosKey: <font color=""Gray"">" & rstCn_PrDocImp!csosKey & "</font>" _
                & ". Счёт ГК: <font color=""CadetBlue"">" & rstCn_PrDocImp!AccountMain & "</font>"
                ' отобразим информацию о других объектах ~Факт связи тройки (СФ+Д)+СГК+ОПСД~ для пары ciKey и csosKey
                Set cnInv = ClassFactory.cnInvReadKey(rstCn_PrDocImp!ciKey, db)
                If cnInv Is Nothing Then
                    strFFF = strFFF & ". Отсутствует объект *СФ+Д*"
                Else
                    strFFF = strFFF & ". " & cnInv.colCias.ReadInfCsos(rstCn_PrDocImp!csosKey, db)
                End If
                ' нужно ли обновлять базу данных?
                If addRa Then
                    ' да, обновлять базу данных нужно
                    ' создаём новый объект ~Факт связи тройки (СФ+Д)+СГК+ОПСД~
                    Set ciasN = ClassFactory.ciasCreateNew(rstCn_PrDocImp!ciKey, rstCn_PrDocImp!account_key, _
                        rstCn_PrDocImp!csosKey, db, "Для первичных документов")
                    strFFF = strFFF & ". <font color=""OliveDrab""><b>Добавлено</b></font>, ciasKey: <font color=""Green"">" _
                        & ciasN.ciasKey & "</font>"
                    addCount = addCount + 1
                    Set ciasN = Nothing
                End If
                Set cnInv = Nothing
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        If addCount > 0 Then
            fff = "<P> Создано для счётов-фактур объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~: <font color=""MediumSeaGreen""><b>" _
                & addCount & "</b></font>.</P>" & fff
        End If
        Else
        ' нет, счета-фактуры не связанные с соответствующими объектами отсутствуют
        fff = "<P><font color=""silver"">Отсутствуют Счета-фактуры не имеющие объектов " _
            & "<font color=""Goldenrod"">~Факт связи тройки (СФ+Д)+СГК+ОПСД~</font></font>.</P><P></P>" & fff
    End If
    ' закрываем набор записей
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' работаем со счетами-фактурами не имеющими соответствующих объектов *Факт связи тройки: 1. пара *Счёт-фактура + Договор*, **************************
' 2. счёт главной книги, 3. организации-простой стороне договора*. 23.03.2022. Окончание ************************************************************


' работаем со счетами-фактурами не имеющими соответствующих первичных документов. 24.03.2022 ********************************************************
Private Sub RAAudit_cn_PrDoc_cnInvExCsosExPdNt(db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, prDocNew As prDoc, addCount As Integer, ciasN As Cias
    
    Const cstrTitle As String _
        = "Процедура *Работаем со Счетами-фактурами не имеющими соответствующих ~первичных документов~*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' открываем набор записей
    Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_CnInvExCsosExPdNt", dbOpenSnapshot)
    
    ' имеются ли счета-фактуры не связанные с соответствующими объектами?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, счета-фактуры не связанные с соответствующими объектами имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем со Счетами-фактурами не имеющими объектов " _
            & "<font color=""Goldenrod""><b>~первичных документов~</b></font></font>. " _
            & "Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
        ' проходим по каждому счёту-фактуре
        rstCn_PrDocImp.MoveFirst: addCount = 0
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найден первичный. Договор: <font color=""Chocolate"">" & rstCn_PrDocImp!CnNum & "</font>" _
                & ", cn_key: <font color=""Gray"">" & rstCn_PrDocImp!cn_key & "</font>" _
                & ". Счёт-фактура: <font color=""SandyBrown""><b>" & rstCn_PrDocImp!CnInvNum & "</b></font>" _
                & ". от: <font color=""SandyBrown"">" & rstCn_PrDocImp!CnInvDate & "</font>" _
                & ". csosKey: <font color=""Gray"">" & rstCn_PrDocImp!csosKey & "</font>" _
                & ". ciKey: <font color=""Gray"">" & rstCn_PrDocImp!ciKey & "</font>" _
                & ". Счёт ГК: <font color=""CadetBlue"">" & rstCn_PrDocImp!AccountMain & "</font>" _
                & ". ciasKey: <font color=""Gray"">" & rstCn_PrDocImp!ciasKey & "</font>" _
                & ". Тип: <font color=""LightSeaGreen"">" & rstCn_PrDocImp!cnpdTpOrd & "</font>" _
                & ". Документ: <font color=""SteelBlue""><b>" & rstCn_PrDocImp!cnpdNumNull & "</b></font>" _
                & ", от: <font color=""DodgerBlue"">" & rstCn_PrDocImp!cnpdDateNull & "</font>"
                ' встречался ли документ с датой ранее?
                If rstCn_PrDocImp!NumDateCount > 0 Then
                    ' да,документ с датой ранее встречался
                    strFFF = strFFF & ". Встречался: <font color=""DeepPink""><b>" & rstCn_PrDocImp!NumDateCount & "</b></font> раз(а)"
                Else
                    ' нет,документ с датой ранее не встречался
                    strFFF = strFFF & ". Ранее не встречался"
                    ' нужно ли обновлять базу данных?
                    If addRa Then
                        ' да, обновлять базу данных нужно
                        ' создаём новый объект ~первичный документ~
                        Set prDocNew = ClassFactory.prDocCreateNew(rstCn_PrDocImp!cnpdNumNull, rstCn_PrDocImp!cnpdDateNull, _
                            rstCn_PrDocImp!cnpdTpOrdKey, rstCn_PrDocImp!ciasKey, db, "Для первичных документов")
                        strFFF = strFFF & ". <font color=""OliveDrab""><b>Добавлено</b></font>, cnpdKey: <font color=""Green"">" _
                            & prDocNew.cnpdKey & "</font>"
                        ' ликвидируем новый объект ~первичный документ~
                        Set prDocNew = Nothing
                        addCount = addCount + 1
                    End If
                End If
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        If addCount > 0 Then
            fff = "<P> Создано для счётов-фактур объектов ~первичный документ~: <font color=""MediumSeaGreen""><b>" _
                & addCount & "</b></font>.</P>" & fff
        End If
        Else
        ' нет, счета-фактуры не связанные с соответствующими объектами отсутствуют
        fff = "<P><font color=""silver"">Отсутствуют Счета-фактуры не имеющие " _
            & "<font color=""Goldenrod"">~первичных документов~</font></font>.</P><P></P>" & fff
    End If
    ' закрываем набор записей
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' работаем со счетами-фактурами не имеющими соответствующих первичных документов. 24.03.2022. Окончание *********************************************

' работаем со строками исходного документа не имеющими соответствующих пунктов в БД. 25.03.2022 *****************************************************
Private Sub RAAudit_cn_PrDoc_cnInvExCsosExPdExPnNt(db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, prDocPnNew As prDocPn, addCount As Integer
    
    Const cstrTitle As String _
        = "Процедура *Работаем со строками исходного документа не имеющими соответствующих ~пунктов~ в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' открываем набор записей
    Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_CnInvExCsosExPdExPnNtIn", dbOpenSnapshot)
    
    ' имеются ли строки не связанные с пунктами?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, строки не связанные с пунктами имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем со строками исходного документа не имеющими " _
            & "<font color=""Goldenrod""><b>~пунктов в БД~</b></font></font>. " _
            & "Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b>. <font color=""DarkOrange"">Нужно проверить существующие. " _
            & "<b>Они меняются при приёмке</b></font>.</P><P></P>" & fff
        ' проходим по каждому счёту-фактуре
        rstCn_PrDocImp.MoveFirst: addCount = 0
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найдено. Договор: <font color=""Chocolate"">" & rstCn_PrDocImp!CnNum & "</font>" _
                & ". Счёт-фактура: <font color=""SandyBrown""><b>" & rstCn_PrDocImp!CnInvNum & "</b></font>" _
                & ". от: <font color=""SandyBrown"">" & rstCn_PrDocImp!CnInvDate & "</font>" _
                & ". Счёт ГК: <font color=""CadetBlue"">" & rstCn_PrDocImp!AccountMain & "</font>" _
                & ". Тип: <font color=""LightSeaGreen"">" & rstCn_PrDocImp!cnpdTpOrd & "</font>" _
                & ". Документ: <font color=""SteelBlue""><b>" & rstCn_PrDocImp!cnpdNumNull & "</b></font>" _
                & ". от: <font color=""DodgerBlue"">" & rstCn_PrDocImp!cnpdDateNull & "</font>" _
                & ". cnpdKey: <font color=""SteelBlue"">" & rstCn_PrDocImp!cnpdKey & "</font>" _
                & ". Строк: <font color=""LightSeaGreen""><b>" & rstCn_PrDocImp!NumSequentialCount & "</b></font>" _

            ' отсутствует ли пункт в БД хотя бы в каком-то виде?
            If IsNull(rstCn_PrDocImp!pdpKey) Then
                ' да, пункт отсутствует. Значит он появился вновь
                strFFF = strFFF & ". <font color=""Chocolate"">Пункт вновь появивишийся</font>"
                ' нужно ли обновлять базу данных?
                If addRa Then
                    ' да, обновлять базу данных нужно
                    ' создаём новый объект ~пункт первичного документа~
                    Set prDocPnNew = ClassFactory.prDocPnCreateNew(pdpPrDoc:=rstCn_PrDocImp!cnpdKey, pdpCstAgPn:=rstCn_PrDocImp!pdpCstAgPnKey, _
                        StatusOfDICtext:=rstCn_PrDocImp!StatusOfDICtext, satstusOfOUKVtext:=rstCn_PrDocImp!satstusOfOUKVtext, _
                        summ:=rstCn_PrDocImp!summ, cost:=rstCn_PrDocImp!cost, SumTax:=rstCn_PrDocImp!SumTax, costVAT:=rstCn_PrDocImp!costVAT, _
                        SPPelement:=rstCn_PrDocImp!SPPelement, docOfAccountNum:=rstCn_PrDocImp!docOfAccountNum, AccountDate:=rstCn_PrDocImp!AccountDate, _
                        positingDate:=rstCn_PrDocImp!positingDate, accountingDoc:=rstCn_PrDocImp!accountingDoc, agent:=rstCn_PrDocImp!agent, _
                        TextOfAgent:=rstCn_PrDocImp!TextOfAgent, prjctDefinition:=rstCn_PrDocImp!prjctDefinition, _
                        prjctDefinitionSort:=rstCn_PrDocImp!prjctDefinitionSort, prjctHierarchyLevel:=rstCn_PrDocImp!prjctHierarchyLevel, _
                        ParentSppElementNum:=rstCn_PrDocImp!ParentSppElementNum, Object:=rstCn_PrDocImp!Object, cstDSW:=rstCn_PrDocImp!cstDSW, _
                        raNum:=rstCn_PrDocImp!raNum, raDate:=rstCn_PrDocImp!raDate, CorrectionNum:=rstCn_PrDocImp!CorrectionNum, _
                        CorrectionDate:=rstCn_PrDocImp!CorrectionDate, accountingDocName:=rstCn_PrDocImp!accountingDocName, _
                        purchasingGroup:=rstCn_PrDocImp!purchasingGroup, purchasingGroupName:=rstCn_PrDocImp!purchasingGroupName, _
                        pdpNote:="Для первичных документов", db:=db _
                        )
                    strFFF = strFFF & ". <font color=""OliveDrab""><b>Добавлено</b></font>, cnpdKey: <font color=""Green"">" _
                        & prDocPnNew.pdpKey & "</font>"
                    ' ликвидируем новый объект ~пункт первичного документа~
                    Set prDocPnNew = Nothing
                    addCount = addCount + 1
                End If
            Else
                ' нет, пункт имеется. Проверяем его свойства
                ' сверяем стройки
                If rstCn_PrDocImp!pdpCstAgPnKeyEqual Then
                    strFFF = strFFF & ". Стр.: <font color=""DarkGreen"">+</font>"
                Else
                    strFFF = strFFF & ". Стр. ист: <font color=""SandyBrown"">" & rstCn_PrDocImp!pdpCstAgPnKey & "</font>" _
                     & ". Стр. БД: <font color=""BlueViolet"">" & rstCn_PrDocImp!pdpCstAgPnKeyBd & "</font>"
                    ' нужно ли обновлять базу данных?
                    If addRa Then
                        Set prDocPnNew = ClassFactory.prDocPnByKey(rstCn_PrDocImp!pdpKey, db)
                        prDocPnNew.lngStrAgPn = rstCn_PrDocImp!pdpCstAgPnKey
                        strFFF = strFFF & ". <font color=""OliveDrab""><b>Обновлено</b></font>"
                        Set prDocPnNew = Nothing
                    End If
                End If
                ' сверяем Бухг. док.
                If rstCn_PrDocImp!accountingDocEqual Then
                    strFFF = strFFF & ". Бухг. док.: <font color=""DarkGreen"">+</font>"
                Else
                    strFFF = strFFF & ". Бухг. док. ист.: <font color=""SteelBlue"">" & rstCn_PrDocImp!accountingDoc & "</font>" _
                     & ". Бухг. док. БД: <font color=""BlueViolet"">" _
                     & IIf(IsNull(rstCn_PrDocImp!accountingDocBd), "пусто", rstCn_PrDocImp!accountingDocBd) & "</font>"
                    ' нужно ли обновлять базу данных?
                    If addRa Then
                        Set prDocPnNew = ClassFactory.prDocPnByKey(rstCn_PrDocImp!pdpKey, db)
                        prDocPnNew.strAccountingDoc = rstCn_PrDocImp!accountingDoc
                        strFFF = strFFF & ". <font color=""OliveDrab""><b>Обновлено</b></font>"
                        Set prDocPnNew = Nothing
                    End If
                End If
                ' сверяем объекты
                If rstCn_PrDocImp!objectEqual Then
                    strFFF = strFFF & ". Объект: <font color=""DarkGreen"">+</font>"
                Else
                    strFFF = strFFF & ". Объект ист.: <font color=""SandyBrown"">" & rstCn_PrDocImp!Object & "</font>" _
                     & ". Объект БД: <font color=""BlueViolet"">" _
                     & IIf(IsNull(rstCn_PrDocImp!objectBd), "пусто", rstCn_PrDocImp!objectBd) & "</font>"
                    ' нужно ли обновлять базу данных?
                    If addRa Then
                        Set prDocPnNew = ClassFactory.prDocPnByKey(rstCn_PrDocImp!pdpKey, db)
                        prDocPnNew.lngStrAgPn = rstCn_PrDocImp!Object
                        strFFF = strFFF & ". <font color=""OliveDrab""><b>Обновлено</b></font>"
                        Set prDocPnNew = Nothing
                    End If
                End If
            End If
                
                
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        If addCount > 0 Then
            fff = "<P> Создано для счётов-фактур объектов ~пункт в БД~: <font color=""MediumSeaGreen""><b>" _
                & addCount & "</b></font>.</P>" & fff
        End If
        Else
        ' нет, строки не связанные с пунктами отсутствуют
        fff = "<P><font color=""silver"">Отсутствуют строки не имеющие " _
            & "<font color=""Goldenrod"">~пунктов в БД~</font></font>.</P><P></P>" & fff
    End If
    ' закрываем набор записей
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' работаем со строками исходного документа не имеющими соответствующих пунктов в БД. 25.03.2022. Окончание ******************************************

' работаем со строками исходного документа имеющими соответствующие пункты в БД. 29.03.2022 *********************************************************
Private Sub RAAudit_cn_PrDoc_cnInvExCsosExPdExPnExRs(db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, prDocPnNew As prDocPn, addCount As Integer
    Dim rstAdd As DAO.Recordset
    
    Const cstrTitle As String _
        = "Процедура *Работаем со строками исходного документа имеющими соответствующие ~пункты~ в БД*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' открываем набор записей
    Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_CnInvExCsosExPdExPnExRs", dbOpenSnapshot)
    
    ' имеются ли строки не связанные с пунктами?
    If rstCn_PrDocImp.RecordCount > 0 Then
        ' да, строки не связанные с пунктами имеются
        rstCn_PrDocImp.MoveLast
        fff = "<P><font color=""silver"">Работаем со строками исходного документа имеющими " _
            & "<font color=""Goldenrod""><b>~пункты в БД~</b></font></font>. " _
            & "Всего их : <b><font color=""Goldenrod"">" _
            & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
        ' нужно ли обновлять базу данных?
        If addRa Then
            Set rstAdd = db.OpenRecordset("ags_cn_PrDocP", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        End If
        ' проходим по каждому счёту-фактуре
        rstCn_PrDocImp.MoveFirst: addCount = 0
        Do Until rstCn_PrDocImp.EOF
            strFFF = "Найдено. Договор: <font color=""Chocolate"">" & rstCn_PrDocImp!CnNum & "</font>" _
                & ". Счёт-фактура: <font color=""SandyBrown""><b>" & rstCn_PrDocImp!CnInvNum & "</b></font>" _
                & ". от: <font color=""SandyBrown"">" & rstCn_PrDocImp!CnInvDate & "</font>" _
                & ". Счёт ГК: <font color=""CadetBlue"">" & rstCn_PrDocImp!AccountMain & "</font>" _
                & ". Тип: <font color=""LightSeaGreen"">" & rstCn_PrDocImp!cnpdTpOrd & "</font>" _
                & ". Документ: <font color=""SteelBlue""><b>" & rstCn_PrDocImp!cnpdNumNull & "</b></font>" _
                & ". от: <font color=""DodgerBlue"">" & rstCn_PrDocImp!cnpdDateNull & "</font>" _
                & ". cnpdKey: <font color=""SteelBlue"">" & rstCn_PrDocImp!cnpdKey & "</font>" _
                & ". Строк: <font color=""LightSeaGreen""><b>" & rstCn_PrDocImp!NumSequentialCount & "</b></font>" _
                & ". Стр.: <font color=""SandyBrown"">" & rstCn_PrDocImp!pdpCstAgPnStr & "</font>" _
                & ". № док. счета: <font color=""SteelBlue"">" & rstCn_PrDocImp!docOfAccountNumNull & "</font>" _
                & ". Бухг. док.: <font color=""SteelBlue"">" & rstCn_PrDocImp!accountingDocNull & "</font>" _
                & ". Объект: <font color=""SandyBrown"">" & rstCn_PrDocImp!objectNull & "</font>"
                ' имеются ли разночтения в данных пункта?
                If rstCn_PrDocImp!rslt Then
                    ' нет, разночтения в данных пункта отсутствуют
                    strFFF = strFFF & ". <font color=""OliveDrab""><b>Всё</b></font>: <font color=""Green"">+</b></font>"
                Else
                    ' да, разночтения в данных пункта имеются
                    strFFF = strFFF & ". <font color=""Crimson""><b>Есть</b></font>: <font color=""Red"">-</b></font>"
                    If Not rstCn_PrDocImp!RsStatusOfDICtext Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">RsStatusOfDICtext</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.StatusOfDICtext") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.StatusOfDICtext") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "StatusOfDICtext", "i.StatusOfDICtext"
                    End If
                    If Not rstCn_PrDocImp!rsStatusOfOUKVtext Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">RsStatusOfDICtext</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.satstusOfOUKVtext") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.satstusOfOUKVtext") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "satstusOfOUKVtext", "i.satstusOfOUKVtext"
                    End If
                    If Not rstCn_PrDocImp!rsSumm Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsStatusOfOUKVtext</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.summ") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.summ") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "summ", "i.summ"
                    End If
                    If Not rstCn_PrDocImp!rsCost Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsCost</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.cost") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.cost") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "cost", "i.cost"
                    End If
                    If Not rstCn_PrDocImp!rsSumTax Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsSumTax</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.SumTax") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.SumTax") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "SumTax", "i.SumTax"
                    End If
                    If Not rstCn_PrDocImp!rsCostVAT Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsCostVAT</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.costVAT") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.costVAT") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "costVAT", "i.costVAT"
                    End If
                    If Not rstCn_PrDocImp!rsSPPelement Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsSPPelement</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.SPPelement") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.SPPelement") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "SPPelement", "i.SPPelement"
                    End If
                    If Not rstCn_PrDocImp!rsAccountDate Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsAccountDate</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.AccountDate") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.AccountDate") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "AccountDate", "i.AccountDate"
                    End If
                    If Not rstCn_PrDocImp!rsPositingDate Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPositingDate</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.positingDate") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.positingDate") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "positingDate", "i.positingDate"
                    End If
                    If Not rstCn_PrDocImp!rsAgent Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsAgent</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.agent") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.agent") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "agent", "i.agent"
                    End If
                    If Not rstCn_PrDocImp!rsTextOfAgent Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsTextOfAgent</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.TextOfAgent") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.TextOfAgent") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "TextOfAgent", "i.TextOfAgent"
                    End If
                    If Not rstCn_PrDocImp!rsPrjctDefinition Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPrjctDefinition</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.prjctDefinition") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.prjctDefinition") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "prjctDefinition", "i.prjctDefinition"
                    End If
                    If Not rstCn_PrDocImp!rsPrjctDefinitionSort Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPrjctDefinitionSort</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.prjctDefinitionSort") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.prjctDefinitionSort") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "prjctDefinitionSort", "i.prjctDefinitionSort"
                    End If
                    If Not rstCn_PrDocImp!rsPrjctHierarchyLevel Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPrjctHierarchyLevel</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.prjctHierarchyLevel") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.prjctHierarchyLevel") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "prjctHierarchyLevel", "i.prjctHierarchyLevel"
                    End If
                    If Not rstCn_PrDocImp!rsParentSppElementNum Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsParentSppElementNum</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.ParentSppElementNum") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.ParentSppElementNum") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "ParentSppElementNum", "i.ParentSppElementNum"
                    End If
                    If Not rstCn_PrDocImp!rsCstDSW Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsCstDSW</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.cstDSW") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.cstDSW") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "cstDSW", "i.cstDSW"
                    End If
                    If Not rstCn_PrDocImp!rsRaNum Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsRaNum</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.raNum") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.raNum") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "raNum", "i.raNum"
                    End If
                    If Not rstCn_PrDocImp!rsRaDate Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsRaDate</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.raDate") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.raDate") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "raDate", "i.raDate"
                    End If
                    If Not rstCn_PrDocImp!rsCorrectionNum Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsCorrectionNum</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.CorrectionNum") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.CorrectionNum") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "CorrectionNum", "i.CorrectionNum"
                    End If
                    If Not rstCn_PrDocImp!rsCorrectionDate Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsCorrectionDate</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.CorrectionDate") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.CorrectionDate") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "CorrectionDate", "i.CorrectionDate"
                    End If
                    If Not rstCn_PrDocImp!rsAccountingDocName Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsAccountingDocName</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.accountingDocName") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.accountingDocName") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "accountingDocName", "i.accountingDocName"
                    End If
                    If Not rstCn_PrDocImp!rsPurchasingGroup Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPurchasingGroup</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.purchasingGroup") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.purchasingGroup") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "purchasingGroup", "i.purchasingGroup"
                    End If
                    If Not rstCn_PrDocImp!rsPurchasingGroupName Then
                        strFFF = strFFF & ". <font color=""DarkMagena"">rsPurchasingGroupName</font>, БД: <font color=""Tomato"">" _
                            & rstCn_PrDocImp("b.purchasingGroupName") _
                            & "</font>, ист.: <font color=""DodgerBlue"">" & rstCn_PrDocImp("i.purchasingGroupName") & "</b></font>"
                        ' обновляем при необходимости
                        PrDocPn_Edit addRa, rstAdd, rstCn_PrDocImp, strFFF, "purchasingGroupName", "i.purchasingGroupName"
                            ' нужно ли обновлять базу данных?
'                            If AddRA Then
'                                rstAdd.FindFirst "pdpKey = " & rstCn_PrDocImp!pdpKey
'                                rstAdd.Edit
'                                    rstAdd("purchasingGroupName") = rstCn_PrDocImp("i.purchasingGroupName")
'                                rstAdd.Update
'                                strFFF = strFFF & ". <font color=""SeaGreen"">Обновлено</font>"
'                            End If
                    End If
                End If
            rstCn_PrDocImp.MoveNext
            fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
        Loop
        ' нужно ли обновлять базу данных?
        If addRa Then
            rstAdd.Close: Set rstAdd = Nothing
        End If
        If addCount > 0 Then
            fff = "<P> Создано для счётов-фактур объектов ~первичный документ~: <font color=""MediumSeaGreen""><b>" _
                & addCount & "</b></font>.</P>" & fff
        End If
        Else
        ' нет, строки не связанные с пунктами отсутствуют
        fff = "<P><font color=""silver"">Отсутствуют строки имеющие " _
            & "<font color=""Goldenrod"">~пункты в БД~</font></font>.</P><P></P>" & fff
    End If
    ' закрываем набор записей
    rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' работаем со строками исходного документа имеющими соответствующие пункты в БД. 29.03.2022. Окончание **********************************************

' обновляем значение поля. 30.03.2022 ***************************************************************************************************************
Private Sub PrDocPn_Edit(ByVal addRa As Boolean, ByRef rstAdd As DAO.Recordset, ByRef rstCn_PrDocImp As DAO.Recordset, _
    ByRef strFFF As String, ByVal bField As String, ByVal iField As String)

    Const cstrTitle As String _
        = "Процедура *Обновляем значение поля*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' нужно ли обновлять базу данных?
    If addRa Then
        rstAdd.FindFirst "pdpKey = " & rstCn_PrDocImp!pdpKey
        rstAdd.Edit
            rstAdd(bField) = rstCn_PrDocImp(iField)
        rstAdd.Update
        strFFF = strFFF & ". <font color=""SeaGreen"">Обновлено</font>"
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' обновляем значение поля. 30.03.2022. Окончание ****************************************************************************************************


' проверяем наличие связи между договорами и счетами-фактурами 21.03.2022 ***************************************************************************
Private Sub RAAudit_cn_PrDoc_cnInvNt(db As DAO.Database, fff As Object, addRa As Boolean)

    Dim rstCn_PrDocImp As DAO.Recordset, strFFF As String, cnInv As cnInv, addCount As Integer
    
    Const cstrTitle As String _
        = "Процедура *Проверяем наличие связи между договорами и счетами-фактурами*"
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

        Set rstCn_PrDocImp = db.OpenRecordset("cn_PrDocImp_CnInvNt", dbOpenSnapshot)
        
        ' имеются ли счета-фактуры не связанные с соответствующими договорами?
        If rstCn_PrDocImp.RecordCount > 0 Then
            ' да, счета-фактуры не связанные с соответствующими договорами имеются
            rstCn_PrDocImp.MoveLast
            fff = "<P><font color=""silver"">Работаем с счетами-фактурами не связанными с соответствующими договорами</font>. " _
                & "Всего их : <b><font color=""Goldenrod"">" _
                & rstCn_PrDocImp.RecordCount & "</font></b></P><P></P>" & fff
            ' проходим по каждому счёту-фактуре
            rstCn_PrDocImp.MoveFirst: addCount = 0
            Do Until rstCn_PrDocImp.EOF
                strFFF = "Найден счёт-фактура. Договор: <font color=""CadetBlue"">" & rstCn_PrDocImp!CnNum & "</font>" _
                    & ", cn_key: <font color=""Gray"">" & rstCn_PrDocImp!cn_key & "</font>" _
                    & ". Счёт-фактура, №: <font color=""DarkOrchid"">" & rstCn_PrDocImp!CnInvNum & "</font>" _
                    & ", дата: <font color=""DarkOrchid"">" & rstCn_PrDocImp!CnInvDate & "</font>"
                    If rstCn_PrDocImp!inKeyCount = 0 Then
                        strFFF = strFFF & ". Ранее не встречался"
                        If addRa Then
                            Set cnInv = ClassFactory.cnInvCreateNewInvNew(rstCn_PrDocImp!CnInvNum, rstCn_PrDocImp!CnInvDate, _
                                rstCn_PrDocImp!cn_key, db, "Для первичных документов")
                            strFFF = strFFF & ". Добавлено, ciKey: " & cnInv.ciKey
                            addCount = addCount + 1
                            Set cnInv = Nothing
                        End If
                        Else
                        strFFF = strFFF & ". Ранее встречался <font color=""DeepPink"">" & rstCn_PrDocImp!inKeyCount _
                            & "</font> раз. Возможно нет даты. Если вносить, то вручную"
                    End If
                rstCn_PrDocImp.MoveNext
                fff = "<P> <font color=""silver"">" & strFFF & "</font>.</P>" & fff
            Loop
            If addCount > 0 Then
                fff = "<P> Внесено счётов-фактур и связано с договорами: <font color=""MediumSeaGreen""><b>" & addCount & "</b></font>.</P>" & fff
            End If
            Else
            ' нет, счета-фактуры не связанные с соответствующими договорами отсутствуют
        End If
        ' закрываем набор записей договоров из таблицы исходных данных в клиенте БД
        rstCn_PrDocImp.Close: Set rstCn_PrDocImp = Nothing
        
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub
' проверяем наличие связи между договорами и счетами-фактурами 21.03.2022. Окончание ****************************************************************


' работаем с листом "учет_аренды"
Private Sub RAAudit_ralpSum(xlS As Excel.Worksheet, addRa As Boolean, fff As Object, db As DAO.Database, ByVal AdtKey As Long, yyyy As Integer)


    Dim ra_r As Range, c As Range, r As Range, valueCellReNum As String, textAdd As String, cstCodeStr As String
    Dim rstC_A_C As DAO.Recordset, cstapKey As Long, reDate As Date
    Dim rsSender As DAO.Recordset, qString As String, ogID As Long, fl As String
    Dim rstRa As DAO.Recordset, raKey As Long, RaAuKey As Long, Status As Integer
    Dim rstRaTest As DAO.Recordset, qd As DAO.QueryDef, strSql As String
    
    Dim rstWaste As DAO.Recordset
    
    Dim strAgent As String, strBranch As String

    Const cstrTitle As String _
        = "Процедура *Работаем с листом, файл - аренда земли, лист - учет_аренды*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' снимаем фильтры листа, если есть
    If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
        xlS.ShowAllData
    End If
    
    ' отыскиваем ячейку "Наименование Агента"
    Set c = xlS.UsedRange.Find(what:="Наименование Агента", LookAt:=xlWhole)
    
    ' итог поисков ячейки "Наименование Агента"
    If Not c Is Nothing Then
        ' ячейка "Наименование Агента" найдена
        fff = "<P> <font color=""silver"">Найдена ячейка</font> *Наименование Агента* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
            
        ' проходим по номерам отчётов
        Set ra_r = xlS.Range(c.Offset(1, 0), xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, c.Column))
        
        ' открываем набор строк для поиска отчётов
        'Set rstRa = db.OpenRecordset("ags_ralpRa", dbOpenSnapshot)
        
        ' очищаем таблицу для хранения перечня отчётов из источника
        strSql = "DELETE * FROM ralpRaSumTest"
        Set qd = db.CreateQueryDef("", strSql)
        qd.Execute dbFailOnError
        qd.Close
        Set qd = Nothing
        
        ' открываем набор строк для хранения перечня отчётов из источника
        Set rstRaTest = db.OpenRecordset("ralpRaSumTest", dbOpenDynaset)
        
        iii = 0: eee = 0
        For Each r In ra_r
            If IsNull(r.value) = False And IsEmpty(r.value) = False Then
                valueCellReNum = CStr(r.value): valueCellReNum = StringClean(valueCellReNum)
                If valueCellReNum <> "" And Not valueCellReNum = "ВСЕГО" And Not valueCellReNum = "их них в том числе" Then
                    ' имеется ли номер?
                    If IsEmpty(r.Offset(0, -1)) = False And IsNumeric(r.Offset(0, -1)) Then
                        ' да, номер имеется
                        strAgent = valueCellReNum
                        ' отсутствуют ли у агента филиалы?
                        If Not r.Offset(1, 0) = "их них в том числе" Then
                            ' да, филиалы у агента отсутствуют
                            iii = iii + 1
                            ' вносим информацию о суммарных показателях из источника в таблицу для их хранения
                            RaSumTestAdd rstRaTest, iii, strAgent, r.Offset(0, 1), _
                                r.Offset(0, 2), r.Offset(0, 3), r.Offset(0, 4), r.Offset(0, 5), db, strAgent, yyyy, AdtKey
                            textAdd = "<P> <font color=""silver"">Найден агент: <font color=""CadetBlue"">" & strAgent & "</font>."
                        End If
                        Else
                        ' нет, номер отсутствует
                        iii = iii + 1
                        strBranch = valueCellReNum
                        
                        ' вносим информацию о суммарных показателях из источника в таблицу для их хранения
                        RaSumTestAdd rstRaTest, iii, strAgent & ", " & valueCellReNum, _
                            r.Offset(0, 1), r.Offset(0, 2), r.Offset(0, 3), r.Offset(0, 4), r.Offset(0, 5), db, strAgent, yyyy, AdtKey, strBranch
                        textAdd = "<P> <font color=""silver"">Найден филиал: <font color=""CadetBlue"">" & strAgent & ", " & valueCellReNum & "</font>."
                    End If
                    
                    
                    ' добавляем текст к тексту хода ревизии
                    fff = textAdd & fff
                End If
            End If
        Next
        
        ' закрываем набор строк для хранения перечня отчётов из источника
        rstRaTest.Close: Set rstRaTest = Nothing
        
        ' закрываем набор строк для поиска отчётов
        'rstRa.Close: Set rstRa = Nothing
        
        fff = "<P> <font color=""silver"">Всего организаций: <font color=""LightSeaGreen"">" _
            & iii & "</font></font>.</P>" & fff
            
        Else
        ' ячейка "Наименование Агента" не найдена
        fff = "<P> <font color=""silver"">Ячейка</font> *Наименование Агента* <font color=""red"">не найдена</font></P>" & fff
        ' ra_changes_first_row = 0
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' вносим информацию о суммарных показателях из источника в таблицу для их хранения
Private Sub RaSumTestAdd(ByRef rstRaTest As DAO.Recordset, ByVal ralprsNum As Integer, ByVal ralprsSenderStr As String, _
    ByVal ralprsArrived As Variant, ByVal ralprsInProcess As Variant, ByVal ralprsSended As Variant, _
    ByVal ralprsReturned As Variant, ByVal ralprsAccepted As Variant, _
    db As DAO.Database, ByVal SenderOrgStr As String, yyyy As Integer, ByVal AdtKey As Long, Optional ByVal SenderBranchString As String _
    )
    
    Dim ogID As Long, fl As String, rsSender As DAO.Recordset, qString As String
    
    Const cstrTitle As String _
        = "Процедура *Вносим информацию о суммарных показателях из источника в таблицу для их хранения*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    With rstRaTest
        .AddNew
        
            ' добавляем номер
            !ralprsNum = ralprsNum
            
            ' добавляем отправителя
            !ralprsSenderStr = ralprsSenderStr
            
            ' добавляем представленные
            If IsEmpty(ralprsArrived) = False And IsNumeric(ralprsArrived) = True And Not CInt(ralprsArrived) = 0 Then
                !ralprsArrived = ralprsArrived
            End If
            
            ' добавляем находящиеся в работе
            If IsEmpty(ralprsInProcess) = False And IsNumeric(ralprsInProcess) = True And Not CInt(ralprsInProcess) = 0 Then
                !ralprsInProcess = ralprsInProcess
            End If

            ' добавляем направленные
            If IsEmpty(ralprsSended) = False And IsNumeric(ralprsSended) = True And Not CInt(ralprsSended) = 0 Then
                !ralprsSended = ralprsSended
            End If

            ' добавляем возвращённые
            If IsEmpty(ralprsReturned) = False And IsNumeric(ralprsReturned) = True And Not CInt(ralprsReturned) = 0 Then
                !ralprsReturned = ralprsReturned
            End If

            ' добавляем принятые суммы
            If IsEmpty(ralprsAccepted) = False And IsNumeric(ralprsAccepted) = True And Not CCur(ralprsAccepted) = 0 Then
                !ralprsAccepted = CCur(ralprsAccepted)
            End If
            
            ' отправитель
            ogID = 0
            ' имеется ли агент?
            If IsNull(SenderOrgStr) = False And IsEmpty(SenderOrgStr) = False And SenderOrgStr <> "" Then
                ' имеется ли филиал?
                If IsNull(SenderBranchString) = False And IsEmpty(SenderBranchString) = False And SenderBranchString <> "" Then
                    ' имеется что-то похожее на филиал
                    fl = StringClean(SenderBranchString)
                    qString = "SELECT onfOg, onfName, onfNameExt FROM ags_ogNmF " _
                        & "WHERE onfName = """ & StringClean(SenderOrgStr) & """ AND onfNameExt = """ & fl & """"
                    Set rsSender = db.OpenRecordset(qString, dbOpenSnapshot)
                    ' имеется одна запись филиала?
                    If rsSender.RecordCount = 1 Then
                        ' да, имеется одна запись филиала
                        rsSender.MoveFirst
                        ogID = rsSender!onfOg
'                        textAdd = textAdd & " Филиал-отправитель в БД: " & " <font color=""Goldenrod"">" & ogID & "</font>." _
'                            & " " & StringClean(r.Offset(0, -8)) & " " & fl & "."
                        Else
                        ' нет, имеется несколько запией филиала либо этих записей нет вообще
'                        textAdd = textAdd & " Филиал-отправитель в БД " & " <font color=""OrangeRed"">отсутствует, или их несколько в БД</font>." _
'                            & " " & StringClean(r.Offset(0, -8)) & " " & fl & "."
                    End If
                    rsSender.Close
                    Set rsSender = Nothing
                    Else
                    ' нет, филиала нет
                    fl = StringClean(SenderOrgStr)
                    qString = "SELECT onfOg, onfName, onfNameExt FROM ags_ogNmF " _
                        & "WHERE onfName = """ & fl & """ AND onfNameExt is Null "
                    Set rsSender = db.OpenRecordset(qString, dbOpenSnapshot)
                    ' имеется одна запись отправителя?
                    If rsSender.RecordCount = 1 Then
                        ' да, имеется одна запись отправителя
                        rsSender.MoveFirst
                        ogID = rsSender!onfOg
'                        textAdd = textAdd & " Отправитель в БД: " & " <font color=""Goldenrod"">" & ogID & "</font>." _
'                            & fl & "."
                        Else
                        ' нет, имеется несколько запией отправителя либо этих записей нет вообще
'                        textAdd = textAdd & " Отправитель в БД " & " <font color=""OrangeRed"">отсутствует, или их несколько в БД</font>." _
'                            & fl & "."
                    End If
                    rsSender.Close
                    Set rsSender = Nothing
                End If
                
                ' нашли ли мы организацию?
                If ogID > 0 Then
                    ' да, организация найдена
                    !ralprsSender = ogID
                End If
            End If
            
            ' добавляем год ralprsY
            If yyyy > 0 Then
                !ralprsY = yyyy
            End If
            
            !ralprsAdtKey = AdtKey

        .Update
        '.Bookmark = .LastModified
        'RaAuKey = !ralpraKey
        '.Close
    End With
    
NormalExit:
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' работаем с листом "Аренда_Земли"
Private Sub RAAudit_ralp(xlS As Excel.Worksheet, addRa As Boolean, fff As Object, db As DAO.Database, ByVal AdtKey As Long)

    Dim ra_r As Range, c As Range, r As Range, valueCellReNum As String, textAdd As String, cstCodeStr As String
    Dim rstC_A_C As DAO.Recordset, cstapKey As Long, reDate As Date
    Dim rsSender As DAO.Recordset, qString As String, ogID As Long, fl As String
    Dim rstRa As DAO.Recordset, raKey As Long, RaAuKey As Long, Status As Integer
    Dim rstRaTest As DAO.Recordset, qd As DAO.QueryDef, strSql As String
    
    Dim RowLastNum As Long
    
    Dim rstWaste As DAO.Recordset
    
    Dim lLastRow As Long
    'а для lLastCol можно было бы применить и тип Integer,
    'т.к. столбцов в Excel пока меньше 32767, но для однообразности назначим тоже Long
    Dim lLastCol As Long
    
    ' 23-1124
'    Dim varCostAndVat As Variant

    Const cstrTitle As String _
        = "Процедура *Работаем с листом, файл - аренда земли, лист - Аренда_Земли*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' снимаем фильтры листа, если есть
    If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
        xlS.ShowAllData
    End If
    
    ' отыскиваем ячейку "№ отчета"
    Set c = xlS.UsedRange.Find(what:="№ отчета", LookAt:=xlPart)
    
    ' итог поисков ячейки "№ отчета"
    If Not c Is Nothing Then
        ' ячейка "№ отчета" найдена
        fff = "<P> <font color=""silver"">Найдена ячейка</font> *№ отчета* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
        ' проходим по номерам отчётов
        
        
        RowLastNum = xlS.Cells.SpecialCells(xlCellTypeLastCell).Row
        lLastRow = Cells(Rows.count, c.Column).End(xlUp).Row
        
        
        Set ra_r = xlS.Range(c.Offset(1, 0), xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, c.Column))
        
        ' открываем набор строк для поиска отчётов
        Set rstRa = db.OpenRecordset("ags_ralpRa", dbOpenSnapshot)
        
        ' очищаем таблицу для хранения перечня отчётов из источника
        strSql = "DELETE * FROM ralpRaAuTest"
        Set qd = db.CreateQueryDef("", strSql)
        qd.Execute dbFailOnError
        qd.Close
        Set qd = Nothing
        
        ' открываем набор строк для хранения перечня отчётов из источника
        Set rstRaTest = db.OpenRecordset("ralpRaAuTest", dbOpenDynaset)
        
        iii = 0: eee = 0
        For Each r In ra_r
            If IsNull(r.value) = False And IsEmpty(r.value) = False Then
                valueCellReNum = CStr(r.value): valueCellReNum = StringClean(valueCellReNum)
                If valueCellReNum <> "" Then
                    iii = iii + 1
                    textAdd = "<P> <font color=""silver"">Найден номер отчёта: <font color=""CadetBlue"">" & valueCellReNum & "</font>."
                    ' представлен ли отчёт в Филиал?
                    If r.Offset(0, -5) = 1 Then
                        ' да, отчёт в филиал представлен
                        eee = eee + 1
                        ' заменяем дефис на слэшь
                        If InStr(valueCellReNum, "-") > 0 Then
                            valueCellReNum = Replace(valueCellReNum, "-", "/", 1, 1)
                            textAdd = textAdd & " <font color=""CornflowerBlue"">Представлен</font>." & " " & valueCellReNum
                            Else
                            textAdd = textAdd & " <font color=""CornflowerBlue"">Представлен</font>."
                        End If
                        ' смотрим стройку
                        ' но является ли строка строкой стройки?
                        cstCodeStr = StringClean(r.Offset(0, -15).value) ' был -14
                        If cstCodeStr Like "###-#######" Then
                            ' да, строка является строкой стройки
                            textAdd = textAdd & " Стройка: " & " <font color=""Goldenrod"">" & cstCodeStr & "</font>."
                            ' имеется ли стройка в БД?
                            If FindCstAP(cstCodeStr, cstapKey, db, rstC_A_C) Then
                                ' да, стройка в БД имеется
                                textAdd = textAdd & " В БД: " & " <font color=""MediumSeaGreen"">" & cstapKey & "</font>."
                                ' имеется ли дата отчёта?
                                If IsDate(r.Offset(0, -13).value) Then
                                    ' да, дата отчёта имеется
                                    reDate = CDate(r.Offset(0, -13).value)
                                    textAdd = textAdd & " Дата: " & " <font color=""DarkTurquoise"">" & reDate & "</font>."
                                    ' отправитель
                                    ogID = 0
                                    ' имеется ли филиал?
                                    If IsNull(r.Offset(0, -7)) = False And IsEmpty(r.Offset(0, -7)) = False _
                                        And r.Offset(0, -7) <> "" And r.Offset(0, -7) <> " " Then
                                        ' имеется что-то похожее на филиал
                                        fl = StringClean(r.Offset(0, -7))
                                        qString = "SELECT onfOg, onfName, onfNameExt FROM ags_ogNmF " _
                                            & "WHERE onfName = """ & StringClean(r.Offset(0, -8)) & """ AND onfNameExt = """ & fl & """"
                                        Set rsSender = db.OpenRecordset(qString, dbOpenSnapshot)
                                        ' имеется одна запись филиала?
                                        If rsSender.RecordCount = 1 Then
                                            ' да, имеется одна запись филиала
                                            rsSender.MoveFirst
                                            ogID = rsSender!onfOg
                                            textAdd = textAdd & " Филиал-отправитель в БД: " & " <font color=""Goldenrod"">" & ogID & "</font>." _
                                                & " " & StringClean(r.Offset(0, -8)) & " " & fl & "."
                                            Else
                                            ' нет, имеется несколько запией филиала либо этих записей нет вообще
                                            textAdd = textAdd & " Филиал-отправитель в БД " & " <font color=""OrangeRed"">отсутствует, или их несколько в БД</font>." _
                                                & " " & StringClean(r.Offset(0, -8)) & " " & fl & "."
                                        End If
                                        rsSender.Close
                                        Set rsSender = Nothing
                                        Else
                                        ' нет, филиала нет
                                        fl = StringClean(r.Offset(0, -8))
                                        qString = "SELECT onfOg, onfName, onfNameExt FROM ags_ogNmF " _
                                            & "WHERE onfName = """ & fl & """ AND onfNameExt is Null "
                                        Set rsSender = db.OpenRecordset(qString, dbOpenSnapshot)
                                        ' имеется одна запись отправителя?
                                        If rsSender.RecordCount = 1 Then
                                            ' да, имеется одна запись отправителя
                                            rsSender.MoveFirst
                                            ogID = rsSender!onfOg
                                            textAdd = textAdd & " Отправитель в БД: " & " <font color=""Goldenrod"">" & ogID & "</font>." _
                                                & fl & "."
                                            Else
                                            ' нет, имеется несколько запией отправителя либо этих записей нет вообще
                                            textAdd = textAdd & " Отправитель в БД " & " <font color=""OrangeRed"">отсутствует, или их несколько в БД</font>." _
                                                & fl & "."
                                        End If
                                        rsSender.Close
                                        Set rsSender = Nothing
                                    End If
                                    
                                    ' нашли ли мы организацию?
                                    If ogID > 0 Then
                                        ' да, организация найдена
                                        ' имеется ли соответствующий отчёт
                                        If FindRalpRa(valueCellReNum, reDate, ogID, cstapKey, raKey, rstRa, addRa, textAdd, db) Then
                                            ' да, отчёт имеется
                                            textAdd = textAdd & " Отчёт в БД: " & " <font color=""Olive"">" & raKey & "</font>."
                                            ' определяем статус
                                            ' отчёт представлен?
                                            If r.Offset(0, -5).value = 1 Then
                                                ' да, отчёт представлен
                                                ' отчёт направлен в бухгалтерию?
                                                If r.Offset(0, -3).value = 1 Then
                                                    ' да, отчёт направлен в бухгалтерию
                                                    Status = 2
                                                    Else
                                                    ' нет, отчёт не направлен в бухгалтерию
                                                    ' отчёт возвращён агенту?
                                                    If r.Offset(0, -2).value = 1 Then
                                                        ' да, отчёт возвращён агнту
                                                        Status = 3
                                                        Else
                                                        ' нет, отчёт агенту не возвращён, считаем, что он в работе
                                                        Status = 1
                                                    End If
                                                End If
                                                Else
                                                ' нет, отчёт не представлен
                                                Status = 0
                                            End If
                                            ' имеется ли факт представления отчёта
                                            ' raKey, strArrived, ByRef RaAuKey, db, raCostAndVat, raReturned, raSent, raNote, raStatus, raTestStartDate,
                                            ' textAdd, addRa
                                            
'                                            If raKey = 5593 Then
'                                                MsgBox ("5593")
'                                            End If
'                                            varCostAndVat = r.Offset(0, -1)
                                            
                                            If FindRalpRaAu(raKey, r.Offset(0, 5), RaAuKey, db, r.Offset(0, -1), r.Offset(0, 7), _
                                                r.Offset(0, 6), r.Offset(0, 4), Status, r.Offset(0, 1), textAdd, addRa) Then
                                                ' да, факт рассмотрения имеется
                                                textAdd = textAdd & " Рассмотрение: " & " <font color=""DarkCyan"">" & RaAuKey & "</font>."
                                                ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                                RaTestAdd rstRaTest, valueCellReNum, textAdd, cstapKey, reDate, ogID, raKey, RaAuKey
                                                Else
                                                ' нет, факт рассмотрения отсутствует
                                                textAdd = textAdd & " Рассмотрение в БД " & " <font color=""salmon"">отсутствует</font>."
                                                ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                                RaTestAdd rstRaTest, valueCellReNum, textAdd, cstapKey, reDate, ogID, raKey
                                            End If
                                            Else
                                            ' нет, отчёт отсутствует
                                            textAdd = textAdd & " Отчёт в БД " & " <font color=""salmon"">отсутствует</font>."
                                            ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                            RaTestAdd rstRaTest, valueCellReNum, textAdd, cstapKey, reDate, ogID
                                        End If
                                        Else
                                        ' нет, организация не найдена
                                        ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                        RaTestAdd rstRaTest, valueCellReNum, textAdd, cstapKey, reDate
                                    End If
                                    
                                    Else
                                    ' нет, дата отчёта отсутствует
                                    textAdd = textAdd & " Дата " & " <font color=""salmon"">отсутствует</font>."
                                    ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                    RaTestAdd rstRaTest, valueCellReNum, textAdd, cstapKey
                                End If
                                Else
                                ' нет, стройка в БД отсутствует
                                textAdd = textAdd & " Стройка в БД " & " <font color=""salmon"">отсутствует</font>."
                                ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                                RaTestAdd rstRaTest, valueCellReNum, textAdd
                            End If
                            Else
                            ' нет, строка строкой стройки не является
                            textAdd = textAdd & " <font color=""OrangeRed"">Стройка не найдена</font>: " & " " & cstCodeStr
                            ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                            RaTestAdd rstRaTest, valueCellReNum, textAdd
                        End If
                        Else
                        ' нет, отчёт в филиал не представлен
                        textAdd = textAdd & " <font color=""salmon"">Не представлен</font>"
                        ' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника
                        RaTestAdd rstRaTest, valueCellReNum, textAdd
                    End If
                    textAdd = textAdd & "</font></P>"
                    ' добавляем текст к тексту хода ревизии
                    fff = textAdd & fff
                End If
            End If
        Next
        
        ' закрываем набор строк для хранения перечня отчётов из источника
        rstRaTest.Close: Set rstRaTest = Nothing
        
        ' закрываем набор строк для поиска отчётов
        rstRa.Close: Set rstRa = Nothing
        
        fff = "<P> <font color=""silver"">Всего номеров отчёта: <font color=""LightSeaGreen"">" _
            & iii & "</font>, представлено: <font color=""LightSeaGreen"">" & eee & "</font></font>.</P>" & fff
            
        ' работа с отчётами имеющимися в БД, но отсутствующими в источнике ++++++++++++++++++++++++++++++++++++++++++++++++++++++
        qString = "SELECT ralprNum, ralprKey FROM ralpRaAuTestQuRa WHERE adt_key = " & AdtKey & " AND ralprtKeySQL is Null "
        Set rstWaste = db.OpenRecordset(qString, dbOpenSnapshot)
        With rstWaste
            If .RecordCount > 0 Then
                ddd = 0
                .MoveFirst
'                textAdd = "<P> <font color=""silver"">Лишние отчёты в БД: <font color=""Salmon"">" & !ralprNum _
'                    & "</font>"
                textAdd = "<P> <font color=""silver"">Лишние отчёты в БД: "
                Do Until .EOF
                    ddd = ddd + 1
                    If ddd = 1 Then
                        textAdd = textAdd & ddd & ". <font color=""Salmon"">" & !ralprNum & "</font>"
                        Else
                        textAdd = textAdd & ", " & ddd & ". <font color=""Salmon"">" & !ralprNum & "</font>"
                    End If
                    ' нужно ли корректировать БД?
                    If addRa Then
                        ' да, БД корректировать нужно
                        strSql = "DELETE * FROM ags_ralpRa where ralprKey = " & !ralprKey
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError + dbSeeChanges
                        qd.Close
                        Set qd = Nothing
                        textAdd = textAdd & ", <font color=""SeaGreen"">Удалено</font>"
                    End If
                    .MoveNext
                Loop
                textAdd = textAdd & ".<b> <font color=""RoyalBlue"">Всего</font>: <font color=""DarkOrange"">" & ddd & "</font></b>.</font></P>"
                fff = textAdd & fff
            End If
            .Close
        End With
        Set rstWaste = Nothing
        ' работа с отчётами имеющимися в БД, но отсутствующими в источнике, окончание +++++++++++++++++++++++++++++++++++++++++++

        ' работа с фактами проверки имеющимися в БД, но отсутствующими в источнике ++++++++++++++++++++++++++++++++++++++++++++++
        qString = "SELECT ralprNum, ralpraArrived, ralpraKey FROM ralpRaAuTestQuAu WHERE adt_key = " & AdtKey & " AND ralprtRaAuKey is Null "
        Set rstWaste = db.OpenRecordset(qString, dbOpenSnapshot)
        With rstWaste
            If .RecordCount > 0 Then
                ddd = 0
                .MoveFirst
                textAdd = "<P> <font color=""silver"">Лишние рассмотрения в БД: "
                Do Until .EOF
                    ddd = ddd + 1
                    If ddd = 1 Then
                        textAdd = textAdd & ddd & ". <font color=""Salmon"">" & !ralprNum _
                        & "</font> (<font color=""PaleVioletRed"">" & !ralpraArrived & "</font>)"
                        Else
                        textAdd = textAdd & ", " & ddd & ". <font color=""Salmon"">" & !ralprNum _
                        & "</font> (<font color=""PaleVioletRed"">" & !ralpraArrived & "</font>)"
                    End If
                    ' нужно ли корректировать БД?
                    If addRa Then
                        ' да, БД корректировать нужно
                        strSql = "DELETE * FROM ags_ralpRaAu where ralpraKey = " & !ralpraKey
                        Set qd = db.CreateQueryDef("", strSql)
                        qd.Execute dbFailOnError + dbSeeChanges
                        qd.Close
                        Set qd = Nothing
                        textAdd = textAdd & ", <font color=""SeaGreen"">Удалено</font>"
                    End If
                    .MoveNext
                Loop
                textAdd = textAdd & ".<b> <font color=""RoyalBlue"">Всего</font>: <font color=""DarkOrange"">" & ddd & "</font></b>.</font></P>"
                fff = textAdd & fff
            End If
            .Close
        End With
        Set rstWaste = Nothing
        ' работа с фактами проверки имеющимися в БД, но отсутствующими в источнике, окончание +++++++++++++++++++++++++++++++++++
            
        Else
        ' ячейка "№ отчета" не найдена
        fff = "<P> <font color=""silver"">Ячейка</font> *№ отчета* <font color=""red"">не найдена</font></P>" & fff
        ' ra_changes_first_row = 0
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' вносим информацию об отчёте в таблицу для хранения перечня отчётов из источника ralprtRaAuKey
Private Sub RaTestAdd(ByRef rstRaTest As DAO.Recordset, ByVal valueCellReNum As String, ByVal textAdd As String, _
    Optional ByVal cstapKey As Variant = Null, Optional ByVal reDate As Variant = Null, _
    Optional ByVal ogID As Variant = Null, Optional ByVal raKey As Variant = Null, Optional ByVal ralprtRaAuKey As Variant = Null)

    With rstRaTest
        .AddNew
        
            ' добавляем номер отчёта
            !ralprtNum = valueCellReNum
            
            ' добавляем примечание
            !ralprtNote = textAdd
            
            ' добавляем стройку
            If IsNull(cstapKey) = False Then
                !ralprtCstAgPn = cstapKey
            End If
            
            ' добавляем дату
            If IsNull(reDate) = False Then
                !ralprtDate = reDate
            End If

            ' добавляем отправителя
            If IsNull(ogID) = False Then
                !ralprtOgSender = ogID
            End If
            
            ' добавляем отчёт
            If IsNull(raKey) = False Then
                !ralprtKeySQL = raKey
            End If
            
            ' добавляем факт рассмотрения отчёта
            If IsNull(ralprtRaAuKey) = False Then
                !ralprtRaAuKey = ralprtRaAuKey
            End If
            
        .Update
        '.Bookmark = .LastModified
        'RaAuKey = !ralpraKey
        '.Close
    End With

End Sub

' проверяем наличие факта рассмотрения отчёта по аренде земли в БД
Private Function FindRalpRaAu(ByVal raKey As Long, ByVal strArrived As String, _
    ByRef RaAuKey As Long, db As DAO.Database, ByVal raCostAndVat As Variant, _
    ByVal raReturned As String, _
    ByVal raSent As String, ByVal raNote As String, ByVal raStatus As Integer, ByVal raTestStartDate As Variant, _
    ByRef textAdd As String, addRa As Boolean _
    ) As Boolean

    Dim rst As DAO.Recordset, strQ As String, raCostAndVatCur As Currency
    Dim strCmA As String, strCmB As String, DateSource As Date, DataSourceNull As Variant
    
    Dim rstAdd As DAO.Recordset
    
    Dim strArrived_ As String, raReturned_ As String, raSent_ As String, raNote_ As String

    Const cstrTitle As String _
        = "Процедура работы с сущностью *Факт рассмотрения отчёта по аренде земли в БД*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' для начала надо исключить пустоту в представлении. Оно пусто?
    If IsNull(strArrived) = True Or IsEmpty(strArrived) = True Then
        ' да, представление пусто
        RaAuKey = 0
        FindRalpRaAu = False
        textAdd = textAdd & " Представление " & " <font color=""Salmon"">пусто</font>."
        GoTo NormalExit
        Else
        ' нет, в представлении есть что-то
        ' но вдруг здесь строка нулевой длины?
        If strArrived = "" Then
            ' да, в представлении строка нулевой длины
            RaAuKey = 0
            FindRalpRaAu = False
            textAdd = textAdd & " Представление " & " <font color=""Salmon"">пусто</font>."
            GoTo NormalExit
        End If
    End If
    
    ' почистим строки
    strArrived_ = StringClean(strArrived): raReturned_ = StringClean(raReturned)
    raSent_ = StringClean(raSent): raNote_ = StringClean(raNote)
    
    ' нужно ли добавлять отсутствующие отчёты либо корректировать существующие?
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' открываем набор записей для добавления или корректировки
        Set rstAdd = db.OpenRecordset("ags_ralpRaAu", dbOpenDynaset, dbFailOnError + dbSeeChanges)
    End If
    
    strQ = "select ralpraKey, ralpraRa, ralpraCostAndVat, ralpraArrived, ralpraArrivedDate, ralpraReturned, " _
        & "ralpraReturnedDate, ralpraSent, ralpraSentDate, ralpraNote, ralpraStatus, ralpraTestStartDate from ags_ralpRaAu where ralpraRa = " _
        & raKey & " And ralpraArrived = """ & strArrived_ & """"
    Set rst = db.OpenRecordset(strQ, dbOpenSnapshot)
    
    ' имеется ли факт рассмотрения?
    If rst.RecordCount > 0 Then
        ' да, факт рассмотерния имеется
        rst.MoveFirst
        RaAuKey = rst!ralpraKey
        FindRalpRaAu = True
        
        ' проверяем атрибуты
        
        ' проверяем сумму, имеется в источнике сумма? +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        If IsNull(raCostAndVat) = False And IsEmpty(raCostAndVat) = False And IsNumeric(raCostAndVat) = True Then
            ' да, сумма в источнике имеется
            raCostAndVatCur = CCur(raCostAndVat)
            ' соответствуют ли суммы?
            If raCostAndVatCur = rst!ralpraCostAndVat Then
                ' да, суммы соответствуют
                textAdd = textAdd & " Суммы " & " <font color=""CadetBlue"">+</font>."
                Else
                ' нет, суммы не соответствуют
                textAdd = textAdd & " Суммы " & " <font color=""OrangeRed"">не соответстуют</font>. БД: <font color=""Coral"">" _
                    & FormatCurrency(rst!ralpraCostAndVat) & "</font>, ист: <font color=""OliveDrab"">" & FormatCurrency(raCostAndVatCur) & "</font>"
                ' нужно ли корректировать базу данных?
                If addRa Then
                    ' да, корректировать базу данных нужно
                    rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                    If rstAdd.NoMatch = False Then
                        rstAdd.Edit
                            rstAdd!ralpraCostAndVat = raCostAndVatCur
                        rstAdd.Update
                        textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                    End If
                    Else
                    ' нет, корректировать базу данных не нужно
                End If
            End If
            Else
            ' нет, сумма в источнике отсутствует
            ' в БД сумма отсутствует или равна 0?
            If IsNull(rst!ralpraCostAndVat) = True Or rst!ralpraCostAndVat = 0 Then
                ' да, в БД сумма отсутствует или равна 0
                textAdd = textAdd & " Суммы " & " <font color=""CadetBlue"">0 = 0</font>."
                Else
                ' нет, в БД сумма имеется и не 0
                textAdd = textAdd & " Суммы " & " <font color=""OrangeRed"">не соответстуют</font>. БД: <font color=""Coral"">" _
                    & FormatCurrency(rst!ralpraCostAndVat) & "</font>, ист: <font color=""OliveDrab"">" & FormatCurrency(raCostAndVatCur) & "</font>"
                ' нужно ли корректировать базу данных?
                If addRa Then
                    ' да, корректировать базу данных нужно
                    rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                    If rstAdd.NoMatch = False Then
                        rstAdd.Edit
                            rstAdd!ralpraCostAndVat = Null
                        rstAdd.Update
                        textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                    End If
                    Else
                    ' нет, корректировать базу данных не нужно
                End If
            End If
        End If ' проверяем сумму ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        ' проверяем направление +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        If CompareStringWithEmpty(raSent, rst!ralpraSent, strCmA, strCmB) Then
            ' да, направления соответствуют
            textAdd = textAdd & ". Напр. <font color=""cadetBlue"">+</font>"
            ' но ещё нужно проверить соответствие даты
            ' имеется ли дата в строке направления?
            DataSourceNull = ParseDate(raSent, False)
            If IsNull(DataSourceNull) = False Then
                ' да, дата в строке направления имеется
                ' определяем дату источника
                DateSource = DataSourceNull
                ' сравниваем источник с базой
                If DateSource <> rst!ralpraSentDate Then
                    textAdd = textAdd & ". Дата напр. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                        & rst!ralpraSentDate & "</font>, ист.: <font color=""goldenrod"">" & DateSource & "</font>"
                    ' нужно ли корректировать базу данных?
                    If addRa Then
                        ' да, корректировать базу данных нужно
                        rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                        If rstAdd.NoMatch = False Then
                            rstAdd.Edit
                                rstAdd!ralpraSentDate = DateSource
                            rstAdd.Update
                            textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                            Else
                            textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                        End If
                    End If
                    Else
                    textAdd = textAdd & ". Дата напр. <font color=""cadetBlue"">+</font>"
                End If
                Else
                ' нет, дата в строке направления отсутствует
                ' дата направления в БД пустая?
                If IsNull(rst!ralpraSentDate) = True Then
                    ' да, дата направления в БД пустая
                    textAdd = textAdd & ". Дата напр. <font color=""cadetBlue"">''=''</font>"
                    Else
                    ' нет, дата направления в БД не пустая
                    textAdd = textAdd & ". Дата напр. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                        & rst!ralpraSentDate & "</font>, ист.: <font color=""goldenrod"">" & DataSourceNull & "</font>"
                        ' нужно ли корректировать базу данных?
                        If addRa Then
                            ' да, корректировать базу данных нужно
                            rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                            If rstAdd.NoMatch = False Then
                                rstAdd.Edit
                                    rstAdd!ralpraSentDate = Null
                                rstAdd.Update
                                textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                                Else
                                textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                            End If
                        End If
                End If
            End If
            Else
            ' нет, направление не соответствует
            textAdd = textAdd & ". Напр. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                & strCmB & "</font>. В источнике: <font color=""goldenrod"">" & strCmA & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                If rstAdd.NoMatch = False Then
                    rstAdd.Edit
                        ' не является ли пустым направление?
                        If Not IsEmpty(raSent) And Not IsNull(raSent) And Not raSent = "" Then
                            ' да, направление пустым не является
                            rstAdd!ralpraSent = strCmA
                            ' имеется ли дата в строке направления?
                            DataSourceNull = ParseDate(raSent, False)
                            If IsNull(DataSourceNull) = False Then
                                ' да, дата в строке направления имеется
                                rstAdd!ralpraSentDate = DataSourceNull
                                Else
                                ' нет, дата в строке направления отсутствует
                                rstAdd!ralpraSentDate = Null
                            End If
                            Else
                            ' нет, направление является пустым
                            rstAdd!ralpraSent = Null
                            rstAdd!ralpraSentDate = Null
                        End If
                    rstAdd.Update
                    textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
        End If ' проверяем направление ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        ' проверяем возврат +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        If CompareStringWithEmpty(raReturned, rst!ralpraReturned, strCmA, strCmB) Then
            ' да, возвраты соответствуют
            textAdd = textAdd & ". Возвр. <font color=""cadetBlue"">+</font>"
            ' но ещё нужно проверить соответствие даты
            ' имеется ли дата в строке возврата?
            DataSourceNull = ParseDate(raReturned, False)
            If IsNull(DataSourceNull) = False Then
                ' да, дата в строке возврата имеется
                ' определяем дату источника
                DateSource = DataSourceNull
                ' сравниваем источник с базой
                If DateSource <> rst!ralpraReturnedDate Then
                    textAdd = textAdd & ". Дата возвр. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                        & rst!ralpraReturnedDate & "</font>, ист.: <font color=""goldenrod"">" & DateSource & "</font>"
                    ' нужно ли корректировать базу данных?
                    If addRa Then
                        ' да, корректировать базу данных нужно
                        rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                        If rstAdd.NoMatch = False Then
                            rstAdd.Edit
                                rstAdd!ralpraReturnedDate = DateSource
                            rstAdd.Update
                            textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                            Else
                            textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                        End If
                    End If
                    Else
                    textAdd = textAdd & ". Дата возвр. <font color=""cadetBlue"">+</font>"
                End If
                Else
                ' нет, дата в строке возврата отсутствует
                If IsNull(rst!ralpraReturnedDate) = True Then
                    '
                    textAdd = textAdd & ". Дата возвр. <font color=""cadetBlue"">''=''</font>"
                    Else
                    '
                    textAdd = textAdd & ". Дата возвр. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                        & rst!ralpraReturnedDate & "</font>, ист.: <font color=""goldenrod"">" & DataSourceNull & "</font>"
                    ' нужно ли корректировать базу данных?
                    If addRa Then
                        ' да, корректировать базу данных нужно
                        rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                        If rstAdd.NoMatch = False Then
                            rstAdd.Edit
                                rstAdd!ralpraReturnedDate = Null
                            rstAdd.Update
                            textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                            Else
                            textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                        End If
                    End If
                End If
            End If
            Else
            ' нет, возвраты не соответствуют
            textAdd = textAdd & ". Возвр. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                & strCmB & "</font>. В источнике: <font color=""goldenrod"">" & strCmA & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                If rstAdd.NoMatch = False Then
                    rstAdd.Edit
                        ' не является ли пустым возврат?
                        If Not IsEmpty(raReturned) And Not IsNull(raReturned) And Not raReturned = "" Then
                            ' да, возврат пустым не является
                            rstAdd!ralpraReturned = strCmA
                            ' имеется ли дата в строке возврата?
                            DataSourceNull = ParseDate(raSent, False)
                            If IsNull(DataSourceNull) = False Then
                                ' да, дата в строке возврата имеется
                                rstAdd!ralpraReturnedDate = DataSourceNull
                                Else
                                ' нет, дата в строке возврата отсутствует
                                rstAdd!ralpraReturnedDate = Null
                            End If
                            Else
                            ' нет, возврат является пустым
                            rstAdd!ralpraReturned = Null
                            rstAdd!ralpraReturnedDate = Null
                        End If
                    rstAdd.Update
                    textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
        End If ' проверяем возврат ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        ' проверяем примечания
        If CompareStringWithEmpty(raNote, rst!ralpraNote, strCmA, strCmB) Then
            ' да, примечания соответствуют
            textAdd = textAdd & ". Прим. <font color=""cadetBlue"">+</font>"
            Else
            ' нет, примечания не соответствуют
            textAdd = textAdd & ". Прим. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                & strCmB & "</font>. В источнике: <font color=""goldenrod"">" & strCmA & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                If rstAdd.NoMatch = False Then
                    rstAdd.Edit
                        rstAdd!ralpraNote = raNote
                    rstAdd.Update
                    textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
        End If
        
        ' проверяем статус ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        If rst!ralpraStatus = raStatus Then
            ' да, статус соответствует
            textAdd = textAdd & ". Статус <font color=""cadetBlue"">+</font>"
            Else
            ' нет, статус не соответствует
            textAdd = textAdd & ". Статус <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                & rst!ralpraStatus & "</font>. В источнике: <font color=""goldenrod"">" & raStatus & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                If rstAdd.NoMatch = False Then
                    rstAdd.Edit
                        rstAdd!ralpraStatus = raStatus
                    rstAdd.Update
                    textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                End If
                Else
                ' нет, корректировать базу данных не нужно
            End If
        End If ' проверяем статус +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        ' проверяем дату начала проверки, пришла дата? ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        If IsDate(raTestStartDate) Then
            ' да, пришла дата
            ' даты равны?
            If rst!ralpraTestStartDate = CDate(raTestStartDate) Then
                ' да, даты равны
                textAdd = textAdd & ". Дата начала <font color=""cadetBlue"">+</font>"
                Else
                ' нет, даты не равны
                textAdd = textAdd & ". Дата начала <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                    & rst!ralpraTestStartDate & "</font>. В источнике: <font color=""goldenrod"">" & raTestStartDate & "</font>"
                ' нужно ли корректировать базу данных?
                If addRa Then
                    ' да, корректировать базу данных нужно
                    rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                    If rstAdd.NoMatch = False Then
                        rstAdd.Edit
                            rstAdd!ralpraTestStartDate = CDate(raTestStartDate)
                        rstAdd.Update
                        textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                    End If
                    Else
                    ' нет, корректировать базу данных не нужно
                End If
            End If
            Else
            ' нет, пришло нечто не являющееся датой
            ' дата в БД равна null?
            If IsNull(rst!ralpraTestStartDate) Then
                ' да, дата в БД равна null
                textAdd = textAdd & ". Дата начала <font color=""cadetBlue"">''=''</font>"
                Else
                ' нет, дата в БД не равна null
                textAdd = textAdd & ". Дата начала <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
                    & rst!ralpraTestStartDate & "</font>. В источнике: <font color=""goldenrod"">" & raTestStartDate & "</font>"
                ' нужно ли корректировать базу данных?
                If addRa Then
                    ' да, корректировать базу данных нужно
                    rstAdd.FindFirst "ralpraKey = " & rst!ralpraKey
                    If rstAdd.NoMatch = False Then
                        rstAdd.Edit
                            rstAdd!ralpraTestStartDate = Null
                        rstAdd.Update
                        textAdd = textAdd & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        textAdd = textAdd & ". <font color=""salmon"">Не найден для правки</font>."
                    End If
                    Else
                    ' нет, корректировать базу данных не нужно
                End If
            End If
        End If ' проверяем дату начала проверки, пришла дата? +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        Else
        ' нет, факт рассмотрения отсутствует
        ' нужно ли корректировать БД?
        If addRa Then ' ================================================================================
            ' да, БД корректировать нужно
            ' Set rstAdd = db.OpenRecordset("ags_ralpRaAu", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            
            With rstAdd
                .AddNew
                
                    ' добавляем отчёт
                    !ralpraRa = raKey
                    
                    ' добавляем представление
                    !ralpraArrived = strArrived_
                    DataSourceNull = ParseDate(strArrived_, True)
                    If IsNull(DataSourceNull) = False Then
                        !ralpraArrivedDate = DataSourceNull
                    End If

                    ' добавляем сумму, если есть
                    If IsNull(raCostAndVat) = False And IsEmpty(raCostAndVat) = False Then
                        If IsNumeric(raCostAndVat) Then
                            !ralpraCostAndVat = CCur(raCostAndVat)
                        End If
                    End If
                    
                    ' добавляем направление, если есть
                    If IsNull(raSent_) = False And IsEmpty(raSent_) = False Then
                        If raSent_ <> "" Then
                            !ralpraSent = raSent_
                            ' ещё и дату попробуем внести
                            DataSourceNull = ParseDate(raSent_, True)
                            If IsNull(DataSourceNull) = False Then
                                !ralpraSentDate = DataSourceNull
                            End If
                        End If
                    End If
                    
                    ' добавляем возвращение, если есть
                    If IsNull(raReturned_) = False And IsEmpty(raReturned_) = False Then
                        If raReturned_ <> "" Then
                            !ralpraReturned = raReturned_
                            ' ещё и дату попробуем внести
                            DataSourceNull = ParseDate(raReturned_, True)
                            If IsNull(DataSourceNull) = False Then
                                !ralpraReturnedDate = DataSourceNull
                            End If
                        End If
                    End If
                    
                    ' добавляем комментарии, если есть
                    If IsNull(raNote_) = False And IsEmpty(raNote_) = False Then
                        If raNote_ <> "" Then
                            !ralpraNote = raNote_
                        End If
                    End If
                    
                    ' добавляем статус
                    !ralpraStatus = raStatus
                    
                    ' добавляем дату начала проверки
                    If IsDate(raTestStartDate) Then
                        !ralpraTestStartDate = CDate(raTestStartDate)
                    End If
                    
                .Update
                .Bookmark = .LastModified
                RaAuKey = !ralpraKey
                '.Close
            End With
            
            'Set rstAdd = Nothing
            textAdd = textAdd & ". Факт рассмотрения в БД <font color=""cadetBlue"">добавлен</font>"
            FindRalpRaAu = True
            Else ' -------------------------------------------------------------------------------------
            ' нет, БД корректировать не нужно
            RaAuKey = 0
            FindRalpRaAu = False
        End If ' =======================================================================================
    End If
    
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' закрываем набор записей для добавления или корректировки
        rstAdd.Close
        Set rstAdd = Nothing
    End If
    
    rst.Close: Set rst = Nothing

NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

' проверяем наличие отчёта по аренде земли в БД
Private Function FindRalpRa(ByVal raNum As String, ByVal raDate As Date, _
    ByVal OgSender As Long, ByVal cstAgPn As Long, ByRef raKey As Long, ByRef rstRa As DAO.Recordset, _
    ByVal addRa As Boolean, ByRef textAdd As String, db As DAO.Database _
    ) As Boolean
    
    Dim rstRaFilter As DAO.Recordset, strQ As String
    Dim rstAdd As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Проверяем наличие отчёта по аренде земли в БД*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    strQ = "ralprNum = """ & raNum & """ And ralprDate = " & DateConvertToQuery(raDate) _
        & " And ralprCstAgPn = " & cstAgPn & " And ralprOgSender = " & OgSender
    rstRa.Filter = strQ
    Set rstRaFilter = rstRa.OpenRecordset
    
    ' имеется ли отчёт в БД?
    If rstRaFilter.RecordCount > 0 Then
        ' да, отчёт в БД имеется
        rstRaFilter.MoveFirst
        raKey = rstRaFilter!ralprKey
        FindRalpRa = True
        Else
        ' нет, отчёт в БД отсутствует
        ' нужно ли корректировать БД?
        If addRa Then
            ' да, корректировать БД нужно
            Set rstAdd = db.OpenRecordset("ags_ralpRa", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            
            With rstAdd
                .AddNew
                    !ralprNum = raNum
                    !ralprDate = raDate
                    !ralprCstAgPn = cstAgPn
                    !ralprOgSender = OgSender
                .Update
                .Bookmark = .LastModified
                raKey = !ralprKey
                .Close
            End With
            
            Set rstAdd = Nothing
            textAdd = textAdd & ". Отчёт в БД <font color=""cadetBlue"">добавлен</font>"
            FindRalpRa = True
            Else
            ' нет, корректировать БД не нужно
            raKey = 0
            FindRalpRa = False
        End If
    End If
    
    rstRaFilter.Close: Set rstRaFilter = Nothing

NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

'работаем с листом учёта отчётов агента за период
Private Sub RAAudit_RA_RepPeriod(xlS As Excel.Worksheet, period As Long, addRa As Boolean, _
    fff As Object, db As DAO.Database, ra_org_sender As Long)

    Const cstrTitle As String _
        = "Процедура *Работаем с листом, Ревизия отчётов агента, файл - отчёты агента, лист - отчётного периода*"

    Dim c As Range, r_f As Range, str As String, adr As String
    Dim ra_num_name(1 To 2) As String
    
    'столбец имён отчётов
    Dim ra_column As Integer
    
    'для отчётов агентов простых
    Dim ra_first_col As Integer, ra_first_row As Integer, ra_last_row As Integer, _
        ra_r As Range, ra_r_first As Range, ra_r_offset As Integer
    'для изменений отчётов агентов
    Dim ra_changes_first_col As Integer, ra_changes_first_row As Integer, ra_changes_last_row As Integer, _
        ra_changes_r As Range, ra_changes_r_first As Range
    'для отчетов агентов по прочим
    Dim ra_other_first_col As Integer, ra_other_first_row As Integer, ra_other_last_row As Integer, _
        ra_other_r As Range, ra_other_r_first As Range
    'дата отчёта агента
    Dim DateRA As Date
    
    ' для поиска в одной ячейке
    Dim Match As Object, RegExp As Object, strReg As String
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    'fff = "<P> Пришли в процедуру листа отчётного периода с листом " & xlS.name & ".</P>" & fff
    
    ' снимаем фильтры листа, если есть
    If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
        xlS.ShowAllData
    End If
    
    
    ' отыскиваем строку "Изменения в отчеты агента"
    Set c = xlS.UsedRange.Find(what:="Изменения в отчеты агента", LookAt:=xlPart)
    ' посмотрим ещё краткое имя
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="ИЗМы", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="Изменения к Отчетам Агента", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="ИЗМ", LookAt:=xlWhole)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="Изменения к", LookAt:=xlPart)
    End If
    
    ' итог поисков строки изменений
    If Not c Is Nothing Then
        fff = "<P> <font color=""silver"">Найдена ячейка</font> *Изменения в отчеты агента* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
        ' номер первой строки изменений отчётов и ячейка начала раздела изменений отчётов
        ra_changes_first_row = c.Row: Set ra_changes_r_first = c
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *Изменения в отчеты агента* <font color=""red"">не найдена</font></P>" & fff
        ra_changes_first_row = 0
    End If
    
    ' отыскиваем строку "Отчеты агента по прочим"
    Set c = xlS.UsedRange.Find(what:="Отчеты агента по прочим", LookAt:=xlPart)
    ' посмотрим ещё краткое имя
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="ГИПы", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="Отеты Агента по прочим расходам", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="ГИП", LookAt:=xlWhole)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="Отчеты по прочим", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
    If c Is Nothing Then
        Set c = xlS.UsedRange.Find(what:="Отчет по прочим расходам", LookAt:=xlPart)
    End If
    ' ну и ещё вариант
'    If c Is Nothing Then
'        Set c = xlS.UsedRange.Find(What:="Прочие", LookAt:=xlWhole)
'    End If
    
    If Not c Is Nothing Then
        fff = "<P> <font color=""silver"">Найдена ячейка</font> *Отчеты агента по прочим* колонка - " & c.Column & ", строка - " & c.Row & "." _
            & " Содержание: <font color=""blue"">" & c & "</font>.</P>" & fff
        'номер первой строки прочих отчётов и ячейка начала раздела прочих отчётов
        ra_other_first_row = c.Row: Set ra_other_r_first = c
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *Отчеты агента по прочим* <font color=""red"">не найдена</font></P>" & fff
        ra_other_first_row = 0
    End If
    
    'отыскиваем колонку отчётов агента и начало раздела обычных отчётов
    ra_column = 0
    ra_first_row = xlS.Cells.SpecialCells(xlCellTypeLastCell).Row
    'задаём варианты имён столбца отчётов агентов
    ra_num_name(1) = "№ ОА"
    ra_num_name(2) = "Номер ОА"
    
    ' нужно проверить строки всех имён и взять самую высокую
    
    Dim ra_name As String
    Dim i As Integer
    'проходим по вариантам имен столбца отчётов агентов
    For i = LBound(ra_num_name) To UBound(ra_num_name)
        Set c = xlS.UsedRange.Find(what:=ra_num_name(i), LookAt:=xlPart)
        'ячейка с вариантом имени найдена
        If Not c Is Nothing Then
            'да, ячейка с вариантом имени найдена
            'сначала фиксируем столбец имен отчётов агентов, где бы мы его не нашли
            ' но потом изменяем, если он ближе к верхней части листа
            If c.Row < ra_first_row Then
                ra_column = c.Column: ra_first_row = c.Row: Set ra_r_first = c: ra_name = ra_num_name(i)
            End If
            Else
            'нет, ячейка с вариантом имени не найдена
        End If
    Next i
    
    'нашелся ли у нас столбец имен отчётов агентов?
    If Not ra_column = 0 Then
        'да, столбец имен отчётов агентов нашелся
        If Not ra_r_first Is Nothing Then
'            fff = "<P> Найдена ячейка *" & ra_name & "* колонка - " & ra_column & ", строка - " & ra_first_row & "." _
'                & " Содержание: <font color=""blue"">" & ra_r_first & "</font>.</P>" & fff
            'первая строка диапазона простых отчетов и колонка
            'ra_first_row = c.Row: Set ra_r_first = c
            
            ' отыскиваем сводные значения за лист периода
            TotalValuesFind "wsPeriod", xlS, period, addRa, fff, db, ra_org_sender, ra_column

            Else
            fff = "<P> <font color=""silver"">Ячейка</font> *Номер ОА* <B><font color=""red"">не найдена</font></B></P>" & fff
            ra_first_row = 0
        End If
        Else
        'нет, столбец имен отчётов агентов отсутствует
        fff = "<P> <font color=""silver"">Столбец</font> *Номер ОА* <B><font color=""red"">не найден</font></B></P>" & fff
        'если нет этого столбца, то здесь делать нечего
        GoTo NormalExit
    End If
    
    'отыскиваем колонку номеров строек
    Set c = xlS.UsedRange.Find(what:="Код стройки", LookAt:=xlPart)
    If Not c Is Nothing Then
        'определяем смещение от номера отчёта до кода стройки
        ra_r_offset = c.Column - ra_r_first.Column
        
'        fff = "<P> Найдена ячейка *Код стройки* колонка - " & c.Column & ", строка - " & c.Row & "." _
'            & " Содержание: <font color=""blue"">" & c & "</font>. Смещение - " & ra_r_offset & ".</P>" & fff
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *Код стройки* <B><font color=""red"">не найдена</font></B></P>" & fff
        ra_r_offset = 0
    End If
    
    'определяем диапазон обычных отчётов агентов
    '1. существует ли диапазон обычных отчётов?
    If ra_first_row > 0 Then
        '1.а. да, диапазон обычных отчётов существует
        '1.а.1. но существует ли, при этом, диапазон изменений отчётов?
        If ra_changes_first_row > 0 Then
            '1.а.1.а. да, диапазон изменений отчётов существует
            '1.а.1.а.1. существует ли диапазон прочих отчётов?
            If ra_other_first_row > 0 Then
                '1.а.1.а.1.а. да, диапазон прочих отчётов существует, имеются и диапазон прочих и диапазон изменений
                '1.а.1.а.1.а.1. начало диапазона изменений отчетов выше на странице, чем прочих отчётов?
                If ra_changes_first_row < ra_other_first_row Then
                    '1.а.1.а.1.а.1.а. да, начало диапазона изменений отчетов выше на странице, чем прочих отчётов
                    'определяем диапазон обычных отчётов
                    Set ra_r = xlS.Range(ra_r_first.Offset(1, 0), xlS.Cells(ra_changes_first_row - 1, ra_r_first.Column))
                    'определяем диапазон изменений отчётов до начала прочих
                    Set ra_changes_r = xlS.Range( _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                        xlS.Cells( _
                            ra_other_first_row - 1, _
                            xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                            ) _
                        )
                    'определяем диапазон прочих отчётов до нижней ячейки
                    Set ra_other_r = xlS.Range( _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                            ) _
                        )
                    Else
                    '1.а.1.а.1.а.1.б. нет, диапазон прочих отчётов выше на странице
                    'определяем диапазон обычных отчётов
                    Set ra_r = xlS.Range(ra_r_first.Offset(1, 0), xlS.Cells(ra_other_first_row - 1, ra_r_first.Column))
                    'определяем диапазон изменений отчётов до нижней ячейки
                    Set ra_changes_r = xlS.Range( _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                            ) _
                        )
                    'определяем диапазон прочих отчётов до начала изменений
                    Set ra_other_r = xlS.Range( _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                        xlS.Cells( _
                            ra_changes_first_row - 1, _
                            xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                            ) _
                        )
                End If
                Else
                '1.а.1.а.1.б. нет, диапазон прочих отчётов отсутствует, но имеется диапазон изменений отчётов
                'определяем диапазон обычных отчётов
                Set ra_r = xlS.Range(ra_r_first.Offset(1, 0), xlS.Cells(ra_changes_first_row - 1, ra_r_first.Column))
                'определяем диапазон изменений отчётов до нижней ячейки
                Set ra_changes_r = xlS.Range( _
                    xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                    xlS.Cells( _
                        xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                        ) _
                    )
            End If
            Else
            '1.а.1.б. нет, диапазон изменений отчётов не существует
            '1.а.1.б.1. но имеется ли диапазон прочих отчётов?
            If ra_other_first_row > 0 Then
                '1.а.1.б.1.а. да, диапазон прочих отчётов имеется
                'определяем диапазон обычных отчётов
                Set ra_r = xlS.Range(ra_r_first.Offset(1, 0), xlS.Cells(ra_other_first_row - 1, ra_r_first.Column))
                'определяем диапазон прочих отчётов до нижней ячейки
                Set ra_other_r = xlS.Range( _
                    xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column), _
                    xlS.Cells( _
                        xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_r_first.Column).Column _
                        ) _
                    )
                Else
                '1.а.1.б.1.б. нет, диапазон прочих отчётов отсутствует
                'определяем диапазон обычных отчётов
                Set ra_r = xlS.Range(ra_r_first.Offset(1, 0), xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, ra_r_first.Column))
            End If
        End If
        
        Else
        '1.б. нет, выходит, что диапазона обычных отчётов нет
        fff = "<P>  <font color=""silver"">Диапазон</font> *Отчёты обычные* <font color=""red"">не найден</font>.</P>" & fff
        '1.б.1. но существует ли, при этом, диапазон изменений отчётов?
        If ra_changes_first_row > 0 Then
            '1.б.1.а. да, диапазон изменений отчётов существует
            '1.б.1.а.1. существует ли диапазон прочих отчётов?
            If ra_other_first_row > 0 Then
                '1.б.1.а.1.а. да, диапазон прочих отчётов существует, имеются и диапазон прочих и диапазон изменений
                '1.б.1.а.1.а.1. начало диапазона изменений отчетов выше на странице, чем прочих отчётов?
                If ra_changes_first_row < ra_other_first_row Then
                    '1.б.1.а.1.а.1.а. да, начало диапазона изменений отчетов выше на странице, чем прочих отчётов
                    'определяем диапазон изменений отчётов до начала прочих
                    Set ra_changes_r = xlS.Range( _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column), _
                        xlS.Cells( _
                            ra_other_first_row - 1, _
                            xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column).Column _
                            ) _
                        )
                    'определяем диапазон прочих отчётов до нижней ячейки
                    Set ra_other_r = xlS.Range( _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column).Column _
                            ) _
                        )
                    Else
                    '1.б.1.а.1.а.1.б. нет, диапазон прочих отчётов выше на странице
                    'определяем диапазон изменений отчётов до нижней ячейки
                    Set ra_changes_r = xlS.Range( _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column), _
                        xlS.Cells( _
                            xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                            xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column).Column _
                            ) _
                        )
                    'определяем диапазон прочих отчётов до начала изменений
                    Set ra_other_r = xlS.Range( _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column), _
                        xlS.Cells( _
                            ra_changes_first_row - 1, _
                            xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column).Column _
                            ) _
                        )
                End If
                Else
                '1.б.1.а.1.б. нет, диапазон прочих отчётов отсутствует, но имеется диапазон изменений отчётов
                'определяем диапазон изменений отчётов до нижней ячейки
                Set ra_changes_r = xlS.Range( _
                    xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column), _
                    xlS.Cells( _
                        xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                        xlS.Cells(ra_changes_r_first.Offset(1, 0).Row, ra_column).Column _
                        ) _
                    )
            End If
            Else
            '1.б.1.б. нет, диапазон изменений отчётов не существует
            '1.б.1.б.1. но имеется ли диапазон прочих отчётов?
            If ra_other_first_row > 0 Then
                '1.б.1.б.1.а. да, диапазон прочих отчётов имеется
                'определяем диапазон прочих отчётов до нижней ячейки
                Set ra_other_r = xlS.Range( _
                    xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column), _
                    xlS.Cells( _
                        xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, _
                        xlS.Cells(ra_other_r_first.Offset(1, 0).Row, ra_column).Column _
                        ) _
                    )
                Else
                '1.б.1.б.1.б. нет, диапазон прочих отчётов отсутствует
            End If
        End If
    End If
    
    '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    '1.а.2. имеется ли диапазон обычных отчётов?
    If Not ra_r Is Nothing Then ' -------------------------- обычные отчёты ---------------------------------------------------------------
        '1.а.2.а. да, диапазон обычных отчётов имеется
        fff = "<P>  <font color=""gray"">Найден диапазон</font> <font color=""blue"">*Отчёты обычные*</font>, колонка - " _
            & ra_r.Column & ", первая строка - " & ra_r.Row & ", " _
            & "нижняя строка - " & ra_r.Row + ra_r.Rows.count - 1 & ". Адрес: <font color=""blue"">" & ra_r.Address & "</font>.</P>" & fff
        
        With ra_r
        
            ' количество ячеек в диапазоне больше одной?
            If .count > 1 Then
                ' да, количество ячеек в диапазоне больше одной
                ' ищем собственно отчёт
                Set c = .Find(what:="*-???????-*", LookAt:=xlWhole)
                ' имеется ли имя соответствующее форме имени отчёта?
                If Not c Is Nothing Then
                    ' да имя соответствующее форме имени отчёта имеется
                    ' простой отчет нашелся в колонке имен отчётов?
                    If c.Column = ra_column Then
                        ' да, простой отчёт нашелся в колонке имен отчётов
                        adr = c.Address
                        'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                        If Left(c.value, 3) = "Изм" Or Left(c.value, 3) = "изм" Or Left(c.value, 9) = "Изменение" Then
                            'да, это именно изменение
                            str = "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                            & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                            & ".</P>"
                            ' отправляем в процедуру обработки изменений
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ChangeOfReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, str, db, period, addRa, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender
                            Else
                            'нет, это простой отчёт
                            ' Отправляем обнаруженный отчёт на обработку. ++++++
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender, "ОА"
                        End If
                        Else
                        ' нет, простой отчёт нашелся не в колонке имен отчётов
                        str = "<P>  В столбце ячейки номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. Простой отчёт нашелся не в колонке имен отчётов</P>"
                        'fff = str & fff
                        GoTo NotRA 'Exit Sub
                    End If
                    Else
                    ' нет имя соответствующее форме имени отчёта отсутствует
                    str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров обычных отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                    'fff = str & fff
                    GoTo NotRA 'Exit Sub
                End If
                Do
                    Set c = .FindNext(c)
                    If (Not c.Address = adr) And (c.Column = ra_column) Then
                        'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                        If Left(c.value, 3) = "Изм" Or Left(c.value, 3) = "изм" Or Left(c.value, 9) = "Изменение" Then
                            'да, это именно изменение
                            str = str & "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                            & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                            & ".</P>"
                            Else
                            'нет, это простой отчёт
                            ' Отправляем обнаруженный отчёт на обработку. ++++++
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                            c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                            c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                            ra_org_sender, "ОА"
                        End If
                    End If
                Loop Until c.Address = adr
                Else
                ' нет, количество ячеек в диапазоне не больше одной
                ' ищем собственно отчёт
                Set c = .Find(what:="*-???????-*", LookAt:=xlWhole)
                ' имеется ли имя соответствующее форме имени отчёта?
                If Not c Is Nothing Then
                    ' да имя соответствующее форме имени отчёта имеется
                    ' простой отчет нашелся в колонке имен отчётов?
                    If c.Column = ra_column Then
                        ' да, простой отчёт нашелся в колонке имен отчётов
                        adr = c.Address
                        'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                        If Left(c.value, 3) = "Изм" Or Left(c.value, 3) = "изм" Or Left(c.value, 9) = "Изменение" Then
                            'да, это именно изменение
                            str = "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                            & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                            & ".</P>"
                            ' отправляем в процедуру обработки изменений
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ChangeOfReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, str, db, period, addRa, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender
                            Else
                            'нет, это простой отчёт
                            ' Отправляем обнаруженный отчёт на обработку. ++++++
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender, "ОА"
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
            
' метка для продолжения в случае отсутствия отчётов
NotRA:
            
        End With
        fff = str & fff: str = ""
        Else
        '1.а.2.б. нет, диапазон обычных отчётов отсутствует
        fff = "<P>  <font color=""silver"">Диапазон</font> *Отчёты обычные* <font color=""red"">не найден</font>.</P>" & fff
    End If ' ----------------------------------------------- обычные отчёты ---------------------------------------------------------------
    
    '1.а.3. имеется ли диапазон изменений отчётов?
    If Not ra_changes_r Is Nothing Then ' -------------------------- изменения отчётов ----------------------------------------------------
        '1.а.2.а. да, диапазон изменений отчётов имеется
        fff = "<P>  <font color=""gray"">Найден диапазон</font> <font color=""blue"">*Отчёты, изменения*</font>, колонка - " _
            & ra_changes_r.Column & ", первая строка - " & ra_changes_r.Row & ", " _
            & "нижняя строка - " & ra_changes_r.Row + ra_changes_r.Rows.count - 1 _
            & ". Адрес: <font color=""blue"">" & ra_changes_r.Address & "</font>.</P>" & fff
        
        With ra_changes_r
        
            ' количество ячеек в диапазоне более одной?
            If .count > 1 Then
                ' да, количество ячеек в диапазоне более одной
    
                Set c = .Find(what:="*-???????-*", LookAt:=xlPart)
                If Not c Is Nothing Then
                    adr = c.Address
                    str = "<P>  Найдено изменение к отчёту - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                    & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                    & ".</P>"
                    ' отправляем в процедуру обработки изменений
                    DateRA = StrToDate(c.Offset(0, 1).value)
                    ChangeOfReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, str, db, period, addRa, _
                        c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                        c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                        ra_org_sender
                    Else
                    str = "<P>  В столбце ячейки номеров изменений отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                    'fff = str & fff
                    GoTo NotRaCh 'Exit Sub
                End If
                
                Do
                    Set c = .FindNext(c)
                    If Not c.Address = adr Then
                        str = "<P>  Найдено изменение к отчёту - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                        & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                        & ".</P>" & str
                        ' отправляем в процедуру обработки изменений
                        DateRA = StrToDate(c.Offset(0, 1).value)
                        ChangeOfReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, str, db, period, addRa, _
                            c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                            c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                            ra_org_sender
                    End If
                Loop Until c.Address = adr
                
                Else
                ' нет, количество ячеек в диапазоне равно одной
                
                Set c = ra_changes_r
                If Not c Is Nothing Then
                    adr = c.Address
                    str = "<P>  <font color=""silver"">Найдено изменение к отчёту</font> - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                    & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                    & ".</P>"
                    ' отправляем в процедуру обработки изменений
                    DateRA = StrToDate(c.Offset(0, 1).value)
                    ChangeOfReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, str, db, period, addRa, _
                        c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                        c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                        ra_org_sender
                    Else
                    str = "<P>  <font color=""silver"">В столбце ячейки</font> номеров изменений отчётов <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                    'fff = str & fff
                    Exit Sub
                End If
            End If
        
' метка для продолжения в случае отсутствия измениния к отчёту
NotRaCh:
    
        End With
        fff = str & fff: str = ""
        Else
        '1.а.2.б. нет, диапазон обычных отчётов отсутствует
        fff = "<P>  <font color=""silver"">Диапазон</font> *Отчёты, изменения* <font color=""red"">не найден</font>.</P>" & fff
    End If ' ------------------------------------------------------- изменения отчётов ----------------------------------------------------

    '1.а.4. имеется ли диапазон прочих отчётов?
    If Not ra_other_r Is Nothing Then ' -------------------------- прочие отчёты ----------------------------------------------------------
        '1.а.2.а. да, диапазон изменений отчётов имеется
        fff = "<P>  <font color=""gray"">Найден диапазон</font> <font color=""blue"">*Отчёты, прочие*</font>, колонка - " _
            & ra_other_r.Column & ", первая строка - " & ra_other_r.Row & ", " _
            & "нижняя строка - " & ra_other_r.Row + ra_other_r.Rows.count - 1 _
            & ". Адрес: <font color=""blue"">" & ra_other_r.Address & "</font>.</P>" & fff
        
        With ra_other_r
        
            ' имеет здесь место неприятное явление, при количестве ячеек в диапазоне равном одной,
            ' программа ищет отчёты за рамками диапазона. Вот нашла строку с сегментом "*-Юргамыш-*"
    
            ' количество ячеек в диапазоне более одной?
            If .count > 1 Then
                ' да, количество ячеек в диапазоне более одной
                
                Set c = .Find(what:="*-???????-*", LookAt:=xlWhole)
                'Set c = .Find(What:="*-*/*", LookAt:=xlWhole)
                If Not c Is Nothing Then
                    adr = c.Address
                    ' но найден ли отчёт в столбце отчётов?
                    If c.Column = ra_column Then
                        ' да, отчёт найден в столбце отчётов
                        
                        'но не является ли найденный простой отчёт на самом деле изменением, затесавшимся в чужой раздел?
                        If Left(c.value, 3) = "Изм" Or Left(c.value, 3) = "изм" Or Left(c.value, 9) = "Изменение" Then
                            'да, это именно изменение
                            str = "<P>  Найдено изменение к отчёту - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                            & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                            & ".</P>"
                            Else
                            'нет, это простой отчёт
                            ' Отправляем обнаруженный отчёт на обработку. ++++++
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender, "ОА, прочие"
                        End If
                        Else
                        ' нет, что то похожее, странное найдено в другом столбце, не столбце отчётов
                        str = "<P>  Что то похожее, странное найдено в другом столбце, не столбце отчётов - <font color=""orange"">" _
                        & c.value & "</font>, строка - " & c.Row & ".</P>"
                    End If
                    Else
                    str = "<P>  В столбце ячейки номеров отчётов по прочим <B><font color=""mediumVioletRed"">отчёты не найдены</font></B></P>"
                    fff = str & fff
                    Exit Sub
                End If
            
                Do
                    Set c = .FindNext(c)
                    If Not c.Address = adr Then
                        'str = str & "<P>  найден ОА по прочим - <font color=""blue"">" & c.Value & "</font>, строка - " & c.Row _
                        '& ". Стройка - " & c.Offset(0, ra_r_offset).Value _
                        '& ".</P>"
                        DateRA = StrToDate(c.Offset(0, 1).value)
                        ReportOfAgent c.value, DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                        c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                        c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                        ra_org_sender, "ОА, прочие"
                    End If
                Loop Until c.Address = adr
                
                Else
                ' нет, количество ячеек в диапазоне равно одной
                
                Set c = ra_other_r
                'Set c = .Find(What:="*-*/*", LookAt:=xlWhole)
                
                If Not c Is Nothing Then
                    adr = c.Address
                    ' ищем по регулярному строковому выражению
                    Set RegExp = CreateObject("VBScript.RegExp")
                    ' определяем шаблон регулярного выражения для изменения
                    ' RealQ = Chr(34)
                    'strReg = "((Изм\.№\d|Изм\.№\d{2})( |\.|,))"
                    strReg = "(Изм|изм)"
                    RegExp.Pattern = strReg
                    ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
                    RegExp.Global = False
                    Set Match = RegExp.Execute(StringClean(c.Text))
                    ' имеются ли совпадения?
                    If Match.count > 0 Then
                        ' да, совпадения имеются, это изменение
                        str = "<P>  Найдено изменение к отчёту - <font color=""blue"">" & c.value & "</font>, строка - " & c.Row _
                            & ". Стройка - " & c.Offset(0, ra_r_offset).value _
                            & ".</P>"
                        Else
                        ' нет, совпадений нет, это не изменение
                        ' определяем шаблон регулярного выражения для отчёта
                        strReg = "(^| ).*?-\d{7}-.*( |$|\.|,)"
                        ' присваиваем шаблон регулярного выражения
                        RegExp.Pattern = strReg
                        ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
                        RegExp.Global = False
                        Set Match = RegExp.Execute(StringClean(c.Text))
                        ' имеются ли совпадения?
                        If Match.count > 0 Then
                            ' да, совпадения имеются, это отчёт
                            ' Отправляем обнаруженный отчёт на обработку. ++++++
                            DateRA = StrToDate(c.Offset(0, 1).value)
                            ReportOfAgent Trim(Match(0).value), DateRA, c.Offset(0, ra_r_offset).value, period, addRa, str, db, _
                                c.Offset(0, 2).value, c.Offset(0, 3).value, c.Offset(0, 4).value, c.Offset(0, 5).value, _
                                c.Offset(0, 6).value, c.Offset(0, 7).value, c.Offset(0, 8).value, c.Offset(0, 9).value, _
                                ra_org_sender, "ОА, прочие"
                            
                            'ChNum = CInt(Replace(Left(Match(0).Value, Len(Match(0).Value) - 1), "Изм.№", ""))
                            Else
                            ' нет, совпадения отсутствуют
                            str = "<P>  В столбце ячейки номеров отчётов по прочим <B><font color=""mediumVioletRed"">отчёты не найдены</font></B>. " & _
                                " Нет соответствий шаблону</P>"
                            fff = str & fff
                        End If
                    End If
                End If
            End If
        End With
        fff = str & fff: str = ""
        Else
        '1.а.2.б. нет, диапазон прочих отчётов отсутствует
        fff = "<P>  <font color=""silver"">Диапазон</font> *Отчёты, прочие* <font color=""red"">не найден</font>.</P>" & fff
    End If ' -------------------------------------------------- прочие отчёты -------------------------------------------------------------
    
NormalExit:
    'Set qd = Nothing
    'Set db = Nothing
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' работаем с листом агентского вознаграждения за месяц
Private Sub RAAudit_AgFee_Month(xlS As Excel.Worksheet, yearAF As Integer, monthAF As Integer, addRa As Boolean, _
    fff As Object, db As DAO.Database, ByRef rstTest As DAO.Recordset, ByVal AdtKey As Long)
    
    Dim c As Range, r_AN As Range, actNum As String, actDate As Date, actNumCst As String, actDateCst As Date
    Dim AgOrCst As String, AgOrCstCode As String
    
    Dim cObj As Range
    
    Dim qdString As String
    Dim qdf As DAO.QueryDef ' для поиска агентов
    Dim rsAg As DAO.Recordset
    Dim agKey As Long
    
    Dim qdfAct As DAO.QueryDef ' для поиска актов
    Dim rsAct As DAO.Recordset, rsActCst As DAO.Recordset
    Dim actKey As Long, actKeyCst As Long
    
    Dim r_Act As Range, a As Range ' диапазон для поиска актов того же заказчика
    Dim cstCodeStr As String, sumStr As String, sumCurr As Currency, sumCurrSent As Currency
    
    Dim rstC_A_C As DAO.Recordset, rsActP As DAO.Recordset
    Dim strFFF As String, cstNote As String, oafpNote_ As String, cstNum As Integer, cstapKey As Long, oafpKey As Long
    
    Dim actKeyNew As Long
    
    ' для сверки общей суммы агента за месяц
    Dim MonthAgSum As Currency, MonthAgSumRslt As Currency
    Dim rsSum As DAO.Recordset
    
    ' для последующей сверки
    Dim qd As DAO.QueryDef, strSql As String

    Const cstrTitle As String _
        = "Процедура *Работаем с листом, Ревизия отчётов агента, файл - агентского вознаграждения, лист - месяца*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' fff = "<P> Пришли в процедуру листа месяца с листом " & xlS.name & ".</P>" & fff
    
    ' снимаем фильтры листа, если есть
    If (xlS.AutoFilterMode And xlS.FilterMode) Or xlS.FilterMode Then
        xlS.ShowAllData
    End If
    
    ' № и дата Акта
    ' отыскиваем строку "№ и дата Акта"
    Set c = xlS.UsedRange.Find(what:="№ и дата Акта", LookAt:=xlPart)
    ' посмотрим ещё краткое имя
    'If c Is Nothing Then
    '    Set c = xlS.UsedRange.Find(What:="ИЗМы", LookAt:=xlPart)
    'End If
    
    ' итог поисков строки изменений
    If Not c Is Nothing Then
        fff = "<P> <font color=""silver"">Найдена ячейка</font> *№ и дата Акта* " _
            & "<font color=""silver"">колонка - " & c.Column & ", строка - " & c.Row & "</font>." _
            & " Содержание: <font color=""cadetblue"">" & c & "</font>.</P>" & fff
            
        ' номер первой строки изменений отчётов и ячейка начала раздела изменений отчётов
        ' определяем диапазон имён актов
        Set r_AN = xlS.Range _
            ( _
                xlS.Cells(c.Row + 1, c.Column), _
                xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, c.Column) _
            )
        ' проходим по диапазону имен актов
        For Each c In r_AN
            If IsEmpty(c) = False And IsNumeric(c) = False Then
                fff = "<P> <font color=""silver""><font color=""gray"">Найден акт</font>, колонка - " & c.Column & ", строка - " & c.Row & "</font>." _
                    & " Содержание: <font color=""SteelBlue"">" & c & "</font>.</P>" & fff
                    
                actNum = ""
                actDate = "01.01.1900"
                
                ' имеется ли номер и дата акта?
                If FindActAgFeeNumDate(c, actNum, actDate) Then
                    ' да, номер и дата акта имеется
                    ' ищем организацию-агента
                    AgOrCst = StringClean(c.Offset(0, -2).value): AgOrCstCode = StringClean(c.Offset(1, -2).value)
                    If IsEmpty(AgOrCstCode) = False And IsNull(AgOrCstCode) = False And Len(AgOrCstCode) > 2 Then
                        AgOrCstCode = Left(AgOrCstCode, 3)
                    End If
                    ' ячейка агента или стройки пуста?
                    If IsEmpty(AgOrCst) Or IsNull(AgOrCst) Then
                        ' да, ячейка агента или стройки пуста
                        fff = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNum _
                            & "</font>, дата - <font color=""Olive"">" & actDate _
                            & "</font>, <font color=""salmon"">ячейка агента или стройки пуста</font></font>.</P>" & fff
                        Else
                        ' нет, в ячейке агента или стройки что-то есть
                        ' в ячейке агента или стройки стройка?
                        If AgOrCst Like "###-#######" Then
                            ' да, в ячейке агента или стройки стройка.
                            ' Это значит что здесь акт для отдельной стройки. Будет рассмотрен в составе общего акта заказчика.
                            fff = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNum _
                                & "</font>, дата - <font color=""Olive"">" & actDate & "</font>, стройка - <B><font color=""Olive"">" _
                                & AgOrCst & "</B></font>. Будет рассмотрен в составе общего акта заказчика</font>.</P>" & fff
                            Else
                            ' нет, в ячейке агента или стройки не стройка, что-то другое...
                            ' это значит что здесь мы скорее всего имеем дело с основным актом заказчика за месяц
                            ' пробуем отыскать агента
                            Set qdf = db.QueryDefs("ags_PdSdRRcList")
                            qdString = "select * from ags.ogNmF_allVariantsAg where ogNm like '" & AgOrCst & "' and ogaCode = '" & AgOrCstCode & "'"
                            qdf.SQL = qdString
                            Set rsAg = qdf.OpenRecordset()
                                ' имеется ли хотя бы одна запись агента?
                                If rsAg.RecordCount > 0 Then
                                    ' да, хотя бы одна запись агента имеется
                                    rsAg.MoveFirst
                                    agKey = rsAg!ogaKey
                                    ' фиксируем суммы агента за месяц для последующей проверки
                                    If IsNull(c.Offset(0, -1).value) = False And IsEmpty(c.Offset(0, -1).value) = False _
                                        And c.Offset(0, -1).value <> "" And IsNumeric(c.Offset(0, -1).value) = True Then
                                        MonthAgSum = CCur(c.Offset(0, -1).value)
                                        Else
                                        MonthAgSum = 0
                                    End If
                                    If IsNull(c.Offset(0, 5).value) = False And IsEmpty(c.Offset(0, 5).value) = False _
                                        And c.Offset(0, 5).value <> "" And IsNumeric(c.Offset(0, 5).value) = True Then
                                        MonthAgSumRslt = CCur(c.Offset(0, 5).value)
                                        Else
                                        MonthAgSumRslt = 0
                                    End If
                                    ' отыскиваем основной акт заказчика за месяц в БД. Акт имеется? +++++++++++++++++++++++++++++++++++++++++++++
                                    If FindAct(actNum, actDate, agKey, yearAF, monthAF, db, rsAct, actKey) Then
                                        ' да, акт в БД имеется. Здесь мы нашли основной акт заказчика за месяц
                                        strFFF = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNum _
                                            & "</font>, дата - <font color=""Olive"">" & actDate & "</font>, агент - <font color=""SteelBlue"">" _
                                            & AgOrCst & "</font>, в БД ключ -  <font color=""Olive"">" & agKey _
                                            & "</font>, акт <font color=""green"">найден</font> в БД, ключ - <font color=""Olive"">" _
                                            & actKey & "</font>"
                                            
                                        ' вызываем процедуру *проверяем атрибуты акта агентского вознаграждения*
                                        TestAct c, strFFF, rsAct, addRa, db
                                        
                                        fff = strFFF & "</font>.</P>" & fff
                                        
                                        'Set cObj = c
                                        
                                        ' Работаем с основным актом Агента за месяц по агентскому вознаграждению
                                        RAAudit_AgFee_Month_Act xlS, c, AgOrCst, agKey, actNum, actDate, actKey, MonthAgSum, MonthAgSumRslt, _
                                            AdtKey, yearAF, monthAF, fff, db, addRa, rstTest
                                        Else
                                        ' нет, в БД запись основного акта заказчика за месяц отсутствует ----------------------------------------
                                        fff = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNum _
                                            & "</font>, дата - <font color=""Olive"">" & actDate & "</font>, агент - <font color=""SteelBlue"">" _
                                            & AgOrCst & "</font>, в БД ключ -  <font color=""Olive"">" & agKey _
                                            & "</font>, <font color=""salmon"">акт в БД не найден</font></font>.</P>" & fff
                                        ' нужно ли корректировать базу данных?
                                        If addRa Then
                                            ' да, корректировать базу данных нужно
                                            ' добавляем основной акт заказчика за месяц. Акт добавлен?
                                            If AddActAgFee(actNum, actDate, agKey, c.Offset(0, 1).value, _
                                                c.Offset(0, 3).value, c.Offset(0, 2).value, yearAF, monthAF, db, actKeyNew) Then
                                                ' да, основной акт заказчика за месяц добавлен
                                                fff = "<P> <font color=""silver"">Добавлен акт, ключ - <font color=""Olive"">" & actKeyNew _
                                                    & "</font></font>.</P>" & fff
                                                    
                                                ' добавляем пункты строек для основного акта заказчика за месяц ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                ' Работаем с основным актом Агента за месяц по агентскому вознаграждению
                                                RAAudit_AgFee_Month_Act xlS, c, AgOrCst, agKey, actNum, actDate, actKeyNew, MonthAgSum, MonthAgSumRslt, _
                                                    AdtKey, yearAF, monthAF, fff, db, addRa, rstTest
                                                ' добавляем пункты строек для основного акта заказчика за месяц, окончание ~~~~~~~~~~~~~~~~~~~~~~
                                                    
                                                Else
                                                ' нет, основной акт заказчика за месяц не добавлен
                                                fff = "<P> <font color=""silver"">Акт <font color=""salmon"">не добавлен</font></font>.</P>" & fff
                                            End If
                                            Else
                                            ' нет, корректировать базу данных не нужно. Ни чего не делаем
                                        End If
                                        ' нет, в БД запись основного акта заказчика за месяц отсутствует, окончание -----------------------------
                                    End If ' отыскиваем основной акт заказчика за месяц в БД. Акт имеется? Окончание ++++++++++++++++++++++++++++
                                    rsAct.Close: Set rsAct = Nothing
                                    Else
                                    ' нет, записи агента отсутствуют
                                    fff = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNum _
                                        & "</font>, дата - <font color=""Olive"">" & actDate & "</font>, агент (стройка) - <font color=""SteelBlue"">" _
                                        & AgOrCst & "</font>, в БД агент <font color=""salmon"">не найден</font></font>.</P>" & fff
                                End If
                            ' закрываем всё, что было нужно для поиска агента
                            rsAg.Close: Set rsAg = Nothing: qdf.Close: Set qdf = Nothing
                        End If
                    End If
                    Else
                    ' нет, номер и дата акта не обнаружены
                    fff = "<P> <font color=""silver"">Номер и дата акта <font color=""salmon"">не найдены</font></font>.</P>" & fff
                End If
                
            End If
        Next
        
        Else
        fff = "<P> <font color=""silver"">Ячейка</font> *№ и дата Акта* <font color=""red"">не найдена</font></P>" & fff
        ra_changes_first_row = 0
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' Работаем с основным актом Агента за месяц по агентскому вознаграждению
Private Sub RAAudit_AgFee_Month_Act( _
    ByRef xlS As Excel.Worksheet, ByVal c As Range, ByVal AgOrCst As String, _
    ByVal agKey As Long, ByVal actNum As String, ByVal actDate As Date, ByVal actKey As Long, _
    ByVal MonthAgSum As Currency, ByVal MonthAgSumRslt As Currency, _
    ByVal AdtKey As Long, ByVal yearAF As Integer, ByVal monthAF As Integer, _
    ByRef fff As Object, ByRef db As DAO.Database, addRa As Boolean, ByRef rstTest As DAO.Recordset _
    )
    ' лист: xlS, c, AgOrCst
    ' про рассматриваемый основной акт Агента за месяц: agKey, actNum, actDate, actKey, MonthAgSum, MonthAgSumRslt
    ' про ревизию: AdtKey, yearAF, monthAF
    ' технические: fff, db, AddRA, rstTest
    ' Пояснения:
    ' MonthAgSum и MonthAgSumRslt это суммы поступившие и принятые зафиксированные для последующей проверки
    
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    
    Dim r_Act As Range, a As Range, iii As Integer, cstCodeStr As String, actNumCst As String, actDateCst As Date
    Dim rsActCst As DAO.Recordset, actKeyCst As Long
    Dim sumStr As String, sumCurr As Currency, sumCurrSent As Currency
    Dim strFFF As String, cstapKey As Long
    Dim rstC_A_C As DAO.Recordset, oafpKey As Long, rsActP As DAO.Recordset
    Dim actKeyNew As Long
    Dim rsSum As DAO.Recordset ' Для проверки сумм
    
    ' для пакетного отображения пунктов строек акта 16.03.2022
    Dim strCount As Integer     ' текущее количество записей в пакете
    Dim strSum As String        ' суммарная строка пакета

    Const cstrTitle As String _
        = "Процедура *Работаем с основным актом Агента за месяц по агентскому вознаграждению*"

    '************************************************************************************************************************************************
    
    ' определяем диапазон от ячейки текущего основного акта Агента за месяц до окончания листа
    Set r_Act = xlS.Range _
        ( _
            xlS.Cells(c.Row + 1, c.Column), _
            xlS.Cells(xlS.Cells.SpecialCells(xlCellTypeLastCell).Row, c.Column) _
        )
    ' посчитаем найденные стройки акта
    iii = 0
    
    ' ***********************************************************************************************************************************************
    ' запускаем цикл, ищущий стройки и акты специфичные для отдельнох строек, по текущему основному акту Агента за месяц ****************************
    strCount = 0: strSum = "" ' обнуляем текущее количество записей в пакете, очищаем суммарную строку пакета
    For Each a In r_Act
        ' имеется ли что-либо в ячейке акта
        If IsEmpty(a) = False And IsNull(a) = False Then
            ' да, в ячейке акта что-то имеется. Возможно это акт специфичный для отдельной стройки
            ' но является ли эта строка строкой стройки?
            cstCodeStr = StringClean(a.Offset(0, -2).value)
            If cstCodeStr Like "###-#######" Then
                ' да, в ячейке кода стройки стройка имеется
                strSum = "<P> <font color=""silver"">Найдена стройка <font color=""BlueViolet"">" & cstCodeStr & "</font> для " _
                & a & "</font>.</P>" & strSum
                strCount = strCount + 1
                ' имеются ли строчные номер и дата акта? Здесь не ищем акт в базе данных.
                    If FindActAgFeeNumDate(a, actNumCst, actDateCst) Then
                        ' да, номер и дата акта имеется. Здесь мы отыскали номер и дату акта специфичного для отдельной стройки
                        
                        ' отыскиваем акт специфичный для отдельной стройки в БД. Акт имеется? +++++++++++++++++++++++++++++++++++++++++++++++++++++++
                        ' набор записей с актом *rsActCst* и первичный ключ акта *actKeyCst* получаем
                        If FindAct(actNumCst, actDateCst, agKey, yearAF, monthAF, db, rsActCst, actKeyCst) Then
                        
                            ' да, акт специфичный для отдельной стройки имеется =====================================================================
                            ' здесь имеется акт для отдельной стройки (на фоне основного акта заказчика за месяц)
                            strFFF = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNumCst _
                                & "</font>, дата - <font color=""Olive"">" & actDateCst & "</font>, агент - <font color=""SteelBlue"">" _
                                & AgOrCst & "</font>, в БД ключ -  <font color=""Olive"">" & agKey _
                                & "</font>, <font color=""green"">акт найден</font> в БД, ключ - <font color=""Olive"">" _
                                & actKeyCst & "</font>"
                            ' проверяем атрибуты акта
                            TestAct a, strFFF, rsActCst, addRa, db
                            ' имеется ли стройка в БД?
                            ' первичный ключ объекта стройка-агент-код *cstapKey*, сумму *sumCurr* и набор записей,
                            ' содержащий объект стройка-агент-код *rstC_A_C* получаем
                            If TestSumAnDCst(a.Offset(0, -1).value, cstCodeStr, cstapKey, sumCurr, db, rstC_A_C) Then
                                ' да, стройка в БД имеются
                                strFFF = strFFF & ". Ключ САК: <font color=""cadetBlue"">" & cstapKey & "</font>, сумма <font color=""cadetBlue"">" _
                                    & FormatCurrency(sumCurr) & "</font>"
                                    
                                ' имеется ли пункт акта?
                                ' первичный ключ пункта стройки акта по агентскому вознаграждению *oafpKey*
                                ' и набор записей, содержащий этот пункт *rsActP* получаем
                                If FindActPn(actKeyCst, cstapKey, oafpKey, db, rsActP) Then
                                
                                    ' да, пункт акта имеется -----------------------------------------------------------------------------------
                                    strFFF = strFFF & ". Пункт акта в БД: <font color=""cadetBlue"">" & oafpKey & "</font>"
                                    ' определяем принятую сумму
                                    sumStr = a.Offset(0, 5).value
                                    If IsNull(sumStr) = False And IsEmpty(sumStr) = False And sumStr <> "" _
                                        And IsNumeric(sumStr) = True Then
                                        sumCurrSent = CCur(sumStr)
                                        Else
                                        sumCurrSent = 0
                                    End If
                                    ' проверяем атрибуты стройки
                                    testCst sumCurr, sumCurrSent, a, strFFF, rsActP, addRa, db
                                    
                                    ' вносим пункт в таблицу для последующей сверки
                                    OafTestAdd rstTest, actNumCst, actDateCst, actKeyCst, agKey, oafpKey, cstapKey, strFFF & "</font>.</P>", AdtKey, yearAF
                                    
                                    ' закрываем набор записей
                                    rsActP.Close: Set rsActP = Nothing
                                    ' да, пункт акта имеется, окончание ------------------------------------------------------------------------
                                    
                                    Else
                                    
                                    ' нет, пункт акта отсутствует ------------------------------------------------------------------------------
                                    strFFF = strFFF & ". Пункт акта в БД: <font color=""salmon"">отсутствует</font>"
                                    ' нужно ли корректировать базу данных?
                                    If addRa Then
                                        ' да, корректировать базу данных нужно
                                        ' добавлен ли пункт стройки в базу данных?
                                        If AddActAgFeeP(cstapKey, actKeyCst, sumCurr, sumCurrSent, a.Offset(0, 4).value, _
                                            a.Offset(0, -3).value, db, oafpKey) Then
                                            ' да, пункт стройки в базу данных добавлен
                                            strFFF = strFFF _
                                                & ". В БД <font color=""DarkSeeGreen"">добавлен</font>, ключ: <font color=""olive"">" & oafpKey & "</font>"
                                            ' вносим пункт в таблицу для последующей сверки
                                            OafTestAdd rstTest, actNumCst, actDateCst, actKeyCst, agKey, oafpKey, cstapKey, _
                                                strFFF & "</font>.</P>", AdtKey, yearAF
                                            Else
                                            ' нет, пункт стройки в базу данных не добавлен
                                            strFFF = strFFF & ". В БД <font color=""salmon"">не добавлен</font>"
                                        End If
                                        Else
                                        ' нет, корректировать базу данных не нужно. Ни чего не делаем
                                    End If
                                    ' нет, пункт акта отсутствует, окончание -------------------------------------------------------------------
                                    
                                End If
                                rstC_A_C.Close: Set rstC_A_C = Nothing
                                
                                Else
                                ' нет, стройка в БД отсутствуют
                                strFFF = strFFF & ". Стройка в БД: <font color=""salmon"">отсутствует</font>"
                            End If
                            ' добавляем строки в пакет
                            strSum = strFFF & "</font>.</P>" & strSum
                            strCount = strCount + 1
                            ' да, акт специфичный для отдельной стройки имеется, окончание ==========================================================
                            
                            Else
                            
                            ' нет, акт специфичный для отдельной стройки отсутствует ================================================================
                            strFFF = "<P> <font color=""silver"">Найдены номер и дата акта, номер - <font color=""Olive"">" & actNumCst _
                                & "</font>, дата - <font color=""Olive"">" & actDateCst & "</font>, агент - <font color=""SteelBlue"">" _
                                & AgOrCst & "</font>, в БД ключ -  <font color=""Olive"">" & agKey _
                                & "</font>, <font color=""salmon"">акт в БД не найден</font>"
                            ' нужно ли корректировать базу данных?
                            If addRa Then
                                ' да, корректировать базу данных нужно
                                ' добавляем акт специфичный для отдельной стройки. Акт добавлен? ....................................................
                                If AddActAgFee(actNumCst, actDateCst, agKey, a.Offset(0, 1).value, _
                                    a.Offset(0, 3).value, a.Offset(0, 2).value, yearAF, monthAF, db, actKeyNew) Then
                                    ' да, акт специфичный для отдельной стройки добавлен
                                    strFFF = strFFF & " Добавлен акт, ключ - <font color=""Olive"">" & actKeyNew _
                                        & "</font>"
                                        
                                    ' добавляем пункт стройки к добавленному акту -------------------------------------------------------------------
                                    ' имеется ли стройка в БД?
                                    If TestSumAnDCst(a.Offset(0, -1).value, cstCodeStr, cstapKey, sumCurr, db, rstC_A_C) Then
                                        ' да, стройка в БД имеются
                                        strFFF = strFFF & ". Ключ САК: <font color=""cadetBlue"">" & cstapKey & "</font>, сумма <font color=""cadetBlue"">" _
                                            & FormatCurrency(sumCurr) & "</font>"
                                    
                                        ' определяем принятую сумму
                                        sumStr = a.Offset(0, 5).value
                                        If IsNull(sumStr) = False And IsEmpty(sumStr) = False And sumStr <> "" _
                                            And IsNumeric(sumStr) = True Then
                                            sumCurrSent = CCur(sumStr)
                                            Else
                                            sumCurrSent = 0
                                        End If
                                    
                                        ' Собственно добавляем пункт стройки к добавленному акту. Добавлен ли пункт стройки в базу данных? ~~~~~~~~~~
                                        If AddActAgFeeP(cstapKey, actKeyNew, sumCurr, sumCurrSent, a.Offset(0, 4).value, a.Offset(0, -3).value, db, oafpKey) Then
                                            ' да, пункт стройки в базу данных добавлен
                                            strFFF = strFFF _
                                                & ". В БД пункт <font color=""DarkSeeGreen"">добавлен</font>, ключ: <font color=""olive"">" & oafpKey & "</font>"
                                                
                                            ' вносим пункт в таблицу для последующей сверки
                                            OafTestAdd rstTest, actNumCst, actDateCst, actKeyNew, agKey, oafpKey, cstapKey, _
                                                strFFF & "</font>.</P>", AdtKey, yearAF
                                            Else
                                            ' нет, пункт стройки в базу данных не добавлен
                                            strFFF = strFFF & ". В БД пункт <font color=""salmon"">не добавлен</font>"
                                        End If
                                        ' Собственно добавляем пункт стройки к добавленному акту. Окончание. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                        
                                        Else
                                        ' нет, стройка в БД отсутствуют
                                        strFFF = strFFF & ". Стройка в БД: <font color=""salmon"">отсутствует</font>"
                                    End If
                                    ' добавляем пункт стройки к добавленному акту, окончание --------------------------------------------------------
                                    Else
                                    ' нет, акт специфичный для отдельной стройки не добавлен
                                    strFFF = strFFF & " Акт <font color=""salmon"">не добавлен</font>"
                                End If ' добавляем акт специфичный для отдельной стройки, окончание .................................................
                                Else
                                ' нет, корректировать базу данных не нужно. Ни чего не делаем
                            End If
                            ' добавляем строки в пакет
                            strSum = strFFF & "</font>.</P>" & strSum
                            strCount = strCount + 1
                            ' нет, акт специфичный для отдельной стройки отсутствует, окончание =====================================================
                            
                        End If ' отыскиваем акт специфичный для отдельной стройки в БД. Окончание. ++++++++++++++++++++++++++++++++++++++++++++++++++
                        
                        Else
                        ' нет, строчные номер и дата акта отсутствуют
                        ' добавляем строки в пакет
                        strSum = "<P> <font color=""silver"">Номер и дата акта строчные в ячейке <font color=""salmon"">не найдены</font></font>.</P>" & strSum
                        strCount = strCount + 1
                    End If
                Else
                ' нет, в ячейке кода стройки стройка отсутствует. Значит это следующий основной акта заказчика за месяц.
                ' Чтобы он нашелся в вышестоящей процедуре Нам надлежит выйти из цикла, ищущего стройки и акты специфичные для отдельнох строек,
                ' по текущему основному акту заказчика за месяц.
                Exit For
            End If
            
            Else ' разница между наличием и отсутствием чего-либо в ячейке акта
            
            ' нет, в ячейке акта ни чего нет, возможно это строка пункта стройки ====================================================================
            ' но имеется ли стройка в ячейке кода стройки
            cstCodeStr = StringClean(a.Offset(0, -2).value)
            If cstCodeStr Like "###-#######" Then
            
                ' да, в ячейке кода стройки стройка имеется. Следовательно это стройка рассматриваемого вышестоящего основного акта заказчика за месяц.
                ' имеется ли сумма у стройки?
                sumStr = a.Offset(0, -1).value
                If IsNull(sumStr) = False And IsEmpty(sumStr) = False And sumStr <> "" _
                    And IsNumeric(sumStr) = True Then
                    sumCurr = CCur(sumStr)
                    If sumCurr <> 0 Then
                        ' да, сумма у стройки имеется
                        ' определяем принятую сумму
                        sumStr = a.Offset(0, 5).value
                        If IsNull(sumStr) = False And IsEmpty(sumStr) = False And sumStr <> "" _
                            And IsNumeric(sumStr) = True Then
                            sumCurrSent = CCur(sumStr)
                            Else
                            sumCurrSent = 0
                        End If
                        ' отыскиваем стройку (объект САК) в базе данных. Имеется ли стройка в базе данных?
                        If FindCstAP(cstCodeStr, cstapKey, db, rstC_A_C) Then
                            ' да, стройка в базе данных имеется
                            iii = iii + 1
                            ' отыскиваем пункт акта ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            If FindActPn(actKey, cstapKey, oafpKey, db, rsActP) Then
                            
                                ' да, пункт акта в базе данных имеется --------------------------------------------------------------------
                                strFFF = "<P> <font color=""silver"">Для акта найдена стройка <font color=""cadetBlue"">" _
                                    & cstCodeStr & "</font>, в БД: <font color=""gray"">" & rstC_A_C!cstapKey _
                                    & "</font>, сумма - <font color=""cadetBlue"">" & FormatCurrency(sumCurr) & _
                                    "</font>, пункт в БД: <font color=""gray"">" & rsActP!oafpKey & "</font>"
                                ' проверяем атрибуты стройки
                                testCst sumCurr, sumCurrSent, a, strFFF, rsActP, addRa, db
                                
                                ' вносим пункт в таблицу для последующей сверки
                                OafTestAdd rstTest, actNum, actDate, actKey, agKey, oafpKey, cstapKey, strFFF & "</font>.</P>", AdtKey, yearAF
                                
                                ' вносим запись в поле "ход ревизии"
'                                fff = strFFF & "</font>.</P>" & fff
                                
                                ' добавляем строки в пакет
                                strSum = strFFF & "</font>.</P>" & strSum
                                strCount = strCount + 1
                                ' да, пункт акта в базе данных имеется, окончание ---------------------------------------------------------
                                
                                Else
                                
                                ' нет, пункт акта в базе данных отсутствует ---------------------------------------------------------------
                                strFFF = "<P> <font color=""silver"">Для акта найдена стройка <font color=""cadetBlue"">" _
                                    & cstCodeStr & "</font>, в БД: <font color=""gray"">" & rstC_A_C!cstapKey _
                                    & "</font>, сумма - <font color=""cadetBlue"">" & FormatCurrency(sumCurr) & _
                                    "</font>, пункт в БД <font color=""salmon"">не найден</font>"
                                ' нужно ли корректировать базу данных?
                                If addRa Then
                                    ' да, корректировать базу данных нужно
                                    ' добавлен ли пункт стройки в базу данных?
                                    If AddActAgFeeP(cstapKey, actKey, sumCurr, sumCurrSent, a.Offset(0, 4).value, a.Offset(0, -3).value, db, oafpKey) Then
                                        ' да, пункт стройки в базу данных добавлен
                                        strFFF = strFFF & ". В БД <font color=""DarkSeeGreen"">добавлен</font>, ключ: <font color=""olive"">" _
                                            & oafpKey & "</font>"
                                        ' вносим пункт в таблицу для последующей сверки
                                        OafTestAdd rstTest, actNum, actDate, actKey, agKey, oafpKey, cstapKey, _
                                            strFFF & "</font>.</P>", AdtKey, yearAF
                                        Else
                                        ' нет, пункт стройки в базу данных не добавлен
                                        strFFF = strFFF & ". В БД <font color=""salmon"">не добавлен</font>"
                                    End If
                                    Else
                                    ' нет, корректировать базу данных не нужно. Ни чего не делаем
                                End If
'                                fff = strFFF & "</font>.</P>" & fff
                                
                                ' добавляем строки в пакет
                                strSum = strFFF & "</font>.</P>" & strSum
                                strCount = strCount + 1
                                ' нет, пункт акта в базе данных отсутствует, окончание ----------------------------------------------------
                                
                            End If ' отыскиваем пункт акта, окончание ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            
                            rsActP.Close: Set rsActP = Nothing
                            
                            Else
                            ' нет, стройка в базе данных отсутствует
'                            fff = "<P> <font color=""silver"">Для акта найдена стройка <font color=""cadetBlue"">" _
'                                & cstCodeStr & "</font>, стройка в БД <font color=""olive"">отсутствует</font>, сумма - <font color=""cadetBlue"">" _
'                                & sumCurr & "</font></font>.</P>" & fff
                                
                            ' добавляем строки в пакет
                            strSum = "<P> <font color=""silver"">Для акта найдена стройка <font color=""cadetBlue"">" _
                                & cstCodeStr & "</font>, стройка в БД <font color=""olive"">отсутствует</font>, сумма - <font color=""cadetBlue"">" _
                                & sumCurr & "</font></font>.</P>" & strSum
                            strCount = strCount + 1
                        End If
                        rstC_A_C.Close: Set rstC_A_C = Nothing
                    End If
                    Else
                    ' нет, сумма у стройки отсутствует. Ни делаем ни чего
                End If
                
                Else
                
                ' нет, в ячейке кода стройки стройка отсутствует.
                ' Нет ни акта ни стройки, это похоже на окончание диапазона текущему основному акту Агента за месяц.
                ' Выходим из цикла.
                Exit For
                
            End If
            ' нет, в ячейке акта ни чего нет, возможно это строка пункта стройки, окончание =========================================================
        End If ' завершение проверки ячейки акта (диапазона от начала основного акта до окончания страницы) на пустоту
        
        ' количество строк в пакете больше определенного количества?
        If strCount > 20 Then
            ' да, количество строк в пакете больше определенного количества
            ' добавляем пакет строк к тексту лога работы, очищаем суммарную строку пакета, обнуляем текущее количество записей в пакете
            fff = strSum & fff: strSum = "": strCount = 0
            Else
            ' нет, количество строк в пакете не больше определенного количества
            ' ни делаем ни чего
        End If
    Next
    
    ' имеются ли строки пакета не добавленные внутри цикла?
    If strCount > 0 Then
        ' да, строки пакета не добавленные внутри цикла имеются
        ' добавляем пакет строк к тексту лога работы, очищаем суммарную строку пакета, обнуляем текущее количество записей в пакете
        fff = strSum & fff: strSum = "": strCount = 0
    End If
    
    ' завершаем цикл, ищущий стройки и акты специфичные для отдельнох строек, по текущему основному акту Агента за месяц ****************************
    ' ***********************************************************************************************************************************************
    
    ' получаем из БД итоги для заказчика за месяц
    qdString = "SELECT yKey, ogaKey, mKey, oafKey, Total FROM ags_ogAgFeeGrA WHERE yKey = " & yearAF & " AND ogaKey = " & agKey _
        & " AND mKey = " & monthAF & " AND oafKey Is Null;"
    Set rsSum = db.OpenRecordset(qdString, dbOpenSnapshot)
        If rsSum.RecordCount > 0 Then
            ' да, пункт итогов заказчика в базе данных имеется
            rsSum.MoveFirst
            ' соответствует ли итог из БД результату агента из источника?
            If WorksheetFunction.Round(rsSum!total, 2) = WorksheetFunction.Round(MonthAgSumRslt, 2) Then
                ' да, итог из БД результату агента из источника соответсвует
                fff = "<P> <font color=""silver"">Для акта найдено строек - " _
                    & iii & ". Всего: " & FormatCurrency(MonthAgSum) & ". Всего для учёта: " & FormatCurrency(MonthAgSumRslt) _
                    & ". <b>БД: <font color=""OliveDrab""> соответствует: " & FormatCurrency(rsSum!total) & "</font></b></font>.</P>" & fff
                Else
                ' нет, итог из БД результату агента из источника не соответсвует
                fff = "<P> <font color=""silver"">Для акта найдено строек - " _
                    & iii & ". Всего: " & FormatCurrency(MonthAgSum) & ". Всего для учёта: " & FormatCurrency(MonthAgSumRslt) _
                    & ". <b>БД: <font color=""Salmon""> не соответствует: " & FormatCurrency(rsSum!total) & "</font></b></font>.</P>" & fff
            End If
            Else
            ' нет, пункт итогов заказчика в базе данных отсутствует
            ' соответствует ли нолю результат агента из источника?
            If 0 = MonthAgSumRslt Then
                ' да, результат агента из источника соответсвует нолю
                fff = "<P> <font color=""silver"">Для акта найдено строек - " _
                    & iii & ". Всего: " & FormatCurrency(MonthAgSum) & ". Всего для учёта: " & FormatCurrency(MonthAgSumRslt) _
                    & ". <b>БД: <font color=""OliveDrab""> соответствует: " & FormatCurrency(0) & "</font></b></font>.</P>" & fff
                Else
                ' нет, результат агента из источника не соответсвует нолю
                fff = "<P> <font color=""silver"">Для акта найдено строек - " _
                    & iii & ". Всего: " & FormatCurrency(MonthAgSum) & ". Всего для учёта: " & FormatCurrency(MonthAgSumRslt) _
                    & ". <b>БД: <font color=""Salmon""> не соответствует: " & FormatCurrency(0) & "</font></b></font>.</P>" & fff
            End If
        End If
    rsSum.Close: Set rsSum = Nothing

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' вносим данные в таблицу для последующей сверки актов агентского вознаграждения
Private Sub OafTestAdd(ByRef rstTest As DAO.Recordset, ByVal oafptOafName As String, ByVal oafptOafDate As Date _
    , ByVal oafptOafKey As Long, ByVal oafptOafSender As Long, ByVal oafptPnKey As Long _
    , ByVal oafptPnCstAgPn As Long, ByVal oafptPnNote As String, ByVal oafptAdtKey As Long, ByVal oafptY As Integer _
    )
    
    With rstTest
        .AddNew
            !oafptOafName = oafptOafName
            !oafptOafDate = oafptOafDate
            !oafptOafKey = oafptOafKey
            !oafptOafSender = oafptOafSender
            !oafptPnKey = oafptPnKey
            !oafptPnCstAgPn = oafptPnCstAgPn
            !oafptPnNote = oafptPnNote
            !oafptAdtKey = oafptAdtKey
            !oafptY = oafptY
        .Update
    End With

End Sub

' добавляем пункт акта агентского вознаграждения
Private Function AddActAgFeeP(ByVal cstapKey As Long, ByVal actKey As Long, ByVal sumCurr As Currency, ByVal sumCurrSent As Currency, _
    ByVal oafpNote As String, ByVal oafpNum As Integer, _
    ByRef db As DAO.Database, ByRef oafpKey As Long) As Boolean

    Dim rsActP As DAO.Recordset, parsedDate As Variant
    
    Const cstrTitle As String _
        = "Процедура *Добавляем пункт акта агентского вознаграждения*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    oafpKey = 0
    
    Set rsActP = db.OpenRecordset("ags_ogAgFeeP", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        With rsActP
            .AddNew
                ' акт
                !oafpOaf = actKey
            
                ' номер
                If Not IsEmpty(oafpNum) And Not IsNull(oafpNum) And Not oafpNum = 0 Then
                    !oafpNum = oafpNum
                End If
                
                ' сумма
                !oafpTotalArr = sumCurr
                
                ' сумма
                !oafpTotal = sumCurrSent
                
                ' стройка
                !oafpCstAgPn = cstapKey
                
                ' примечания
                If Not IsEmpty(oafpNote) And Not IsNull(oafpNote) And Not oafpNote = "" Then
                    !oafpNote = StringClean(oafpNote)
                End If
            .Update
            .Bookmark = .LastModified
            oafpKey = !oafpKey
            .Close
        End With
    Set rsActP = Nothing

    AddActAgFeeP = True

NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    AddActAgFeeP = False
    Resume NormalExit

End Function

' добавляем акт агентского вознаграждения
Private Function AddActAgFee(ByVal actNum As String, ByVal actDate As Variant, ByVal agKey As Long, _
    ByVal oafArrived As String, ByVal oafReturned As String, ByVal oafSent As String, _
    ByVal yearAF As Integer, ByVal monthAF As Integer, _
    ByRef db As DAO.Database, ByRef actKey As Long) As Boolean

    Dim rsAct As DAO.Recordset, parsedDate As Variant

    Const cstrTitle As String _
        = "Процедура *Добавляем акт агентского вознаграждения*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    actKey = 0

    Set rsAct = db.OpenRecordset("ags_ogAgFee", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        With rsAct
            .AddNew
                ' номер
                !oafNum = actNum
                
                ' дата
                If Not IsEmpty(actDate) And Not IsNull(actDate) And IsDate(actDate) Then
                    !oafDate = actDate
                    Else
                    !oafDate = Null
                End If
                
                ' агент
                !cstaAg = agKey
                
                ' поступление
                If Not IsEmpty(oafArrived) And Not IsNull(oafArrived) And Not oafArrived = "" Then
                    !oafArrived = StringClean(oafArrived)
                    'отыскиваем дату
                    If oafArrived Like "*##.##.####*" Then
                        parsedDate = ParseDate(oafArrived, False)
                        If IsNull(parsedDate) = False Then
                            !oafArrivedDate = parsedDate
                        End If
                    End If
                    Else
                    !oafArrived = Null
                End If
                 ' возвращение
                If Not IsEmpty(oafReturned) And Not IsNull(oafReturned) And Not oafReturned = "" Then
                    !oafReturned = StringClean(oafReturned)
                    'отыскиваем дату
                    If oafReturned Like "*##.##.####*" Then
                        parsedDate = ParseDate(oafReturned, False)
                        If IsNull(parsedDate) = False Then
                            !oafReturnedDate = parsedDate
                        End If
                    End If
                    Else
                    !oafReturned = Null
                End If
                ' направление
                If Not IsEmpty(oafSent) And Not IsNull(oafSent) And Not oafSent = "" Then
                    !oafSent = StringClean(oafSent)
                    'отыскиваем дату
                    If oafSent Like "*##.##.####*" Then
                        parsedDate = ParseDate(oafSent, False)
                        If IsNull(parsedDate) = False Then
                            !oafSentDate = parsedDate
                        End If
                    End If
                    Else
                    !oafSent = Null
                End If
                
                ' год
                !oafY = yearAF
                
                ' месяц
                !oafM = monthAF
            .Update
            .Bookmark = .LastModified
            actKey = !oafKey
            .Close
        End With
    Set rsAct = Nothing

    AddActAgFee = True

NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    AddActAgFee = False
    Resume NormalExit

End Function

' проверяем атрибуты пункта стройки акта агентского вознаграждения
Private Sub testCst(ByVal sumCurr As Currency, ByVal sumCurrSent As Currency, ByRef a As Range, ByRef strFFF As String, ByRef rsActP As DAO.Recordset, _
    addRa As Boolean, ByRef db As DAO.Database)

    Dim cstNote As String, oafpNote_ As String, cstNum As Integer, cstNumDB As Integer
    Dim rstAct_add As DAO.Recordset
        
    Const cstrTitle As String _
        = "Процедура *Проверяем атрибуты пункта стройки акта агентского вознаграждения*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' нужно ли добавлять отсутствующие отчёты либо корректировать существующие?
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' открываем набор записей для добавления или корректировки
        Set rstAct_add = db.OpenRecordset("ags_ogAgFeeP", dbOpenDynaset, dbFailOnError + dbSeeChanges)
    End If
    
    ' соответствует ли сумма представленная?
    If Round(rsActP!oafpTotalArr, 2) = Round(sumCurr, 2) Then
        ' да, сумма соответствует
        strFFF = strFFF & ". Сумма представленная <font color=""cadetBlue"">+</font>"
        Else
        ' нет, сумма не соответствует
        strFFF = strFFF & ". Сумма представленная <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & FormatCurrency(rsActP!oafpTotalArr) & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafpKey = " & rsActP!oafpKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    rstAct_add!oafpTotalArr = sumCurr
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If

    ' соответствует ли сумма направленная?
    If Round(rsActP!oafpTotal, 2) = Round(sumCurrSent, 2) Then
        ' да, сумма соответствует
        strFFF = strFFF & ". Сумма направленная <font color=""cadetBlue"">+</font>"
        Else
        ' нет, сумма не соответствует
        strFFF = strFFF & ". Сумма направленная <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & FormatCurrency(rsActP!oafpTotal) & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafpKey = " & rsActP!oafpKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    rstAct_add!oafpTotal = sumCurrSent
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    ' соотвутсевует ли примечание?
    If CompareStringWithEmpty(a.Offset(0, 4).value, rsActP!oafpNote, cstNote, oafpNote_) Then
        ' да, примечания соответствуют
        strFFF = strFFF & ". Прим. <font color=""cadetBlue"">+</font>"
        Else
        ' нет, примечания не соответствует
        strFFF = strFFF & ". Прим. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & oafpNote_ & "</font>. В источнике: <font color=""goldenrod"">" & cstNote & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafpKey = " & rsActP!oafpKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    rstAct_add!oafpNote = StringClean(a.Offset(0, 4).value)
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    ' соответствует ли порядковый номер?
    cstNote = a.Offset(0, -3).value
    If IsNull(cstNote) = False And IsEmpty(cstNote) = False And cstNote <> "" And IsNumeric(cstNote) Then
        cstNum = CInt(cstNote)
        Else
        cstNum = 0
    End If
    If IsNull(rsActP!oafpNum) = False And IsEmpty(rsActP!oafpNum) = False Then
        cstNumDB = rsActP!oafpNum
        Else
        cstNumDB = 0
    End If
    If cstNumDB = cstNum Then
        ' да, номера соответствуют
        strFFF = strFFF & ". № пп <font color=""cadetBlue"">+</font>"
        Else
        ' нет, номера не соответствует
        strFFF = strFFF & ". № пп <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & cstNumDB & "</font>. В источнике: <font color=""goldenrod"">" & cstNum & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafpKey = " & rsActP!oafpKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    If cstNum = 0 Then
                        rstAct_add!oafpNum = Null
                        Else
                        rstAct_add!oafpNum = cstNum
                    End If
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' закрываем набор записей для добавления или корректировки
        rstAct_add.Close
        Set rstAct_add = Nothing
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' отыскиваем пункт стройки акта по агентскому вознаграждению
Private Function FindActPn(ByVal actKey As Long, ByVal cstapKey As Long, ByRef oafpKey As Long, _
    ByRef db As DAO.Database, ByRef rsActP As DAO.Recordset) As Boolean
    ' первичный ключ пункта стройки акта по агентскому вознаграждению *oafpKey*
    ' и набор записей, содержащий этот пункт *rsActP* ВОЗВРАЩАЕМ

    oafpKey = 0

    ' отыскиваем пункт акта rsActP
    qdString = "SELECT * FROM ags_ogAgFeeP WHERE oafpOaf = " & actKey & " AND oafpCstAgPn = " & cstapKey & ";"
    Set rsActP = db.OpenRecordset(qdString, dbOpenSnapshot)
        If rsActP.RecordCount > 0 Then
            ' да, пункт акта в базе данных имеется
            rsActP.MoveFirst
            oafpKey = rsActP!oafpKey
            FindActPn = True
            Else
            ' нет, пункт акта в базе данных отсутствует
            FindActPn = False
        End If
End Function

' проверяем наличие суммы и стройки
Private Function TestSumAnDCst(ByVal sumStr As Variant, ByVal cstCodeStr As String, ByRef cstapKey As Long, _
    ByRef sumCurr As Currency, ByRef db As DAO.Database, ByRef rstC_A_C As DAO.Recordset) As Boolean
    ' первичный ключ объекта стройка-агент-код *cstapKey*, сумму sumCurr и набор записей,
    ' содержащий объект стройка-агент-код *rstC_A_C* ВОЗВРАЩАЕМ

        Dim qdString As String

        cstapKey = 0: sumCurr = 0
        
        ' является ли значение суммы не пустым и цифровым?
        If IsNull(sumStr) = False And IsEmpty(sumStr) = False And sumStr <> "" _
            And IsNumeric(sumStr) = True Then
            ' да, значение суммы является не пустым и цифровым
            sumCurr = CCur(sumStr)
        End If
        
        ' первичный ключ объекта стройка-агент-пункт *cstapKey* и набор записей, содержащий стройку *rstC_A_C* получаем
        If FindCstAP(cstCodeStr, cstapKey, db, rstC_A_C) Then
            ' да, стройка в базе данных имеется
            TestSumAnDCst = True
            Else
            ' нет, стройка в базе данных отсутствует
            TestSumAnDCst = False
        End If
        

End Function

'' отыскиваем стройку (объект САК) в базе данных. Имеется ли стройка в базе данных?
'Private Function FindCstAP(ByVal cstCodeStr As String, ByRef cstapKey as long, _
'    ByRef db As DAO.Database, Optional ByRef rstC_A_C As Variant) As Boolean
'    ' первичный ключ объекта стройка-агент-пункт *cstapKey* и набор записей, содержащий стройку *rstC_A_C* ВОЗВРАЩАЕМ
'    ' ByRef rstC_A_C As DAO.Recordset
'
'    Dim qdString As String, rsCstAgPn As DAO.Recordset
'    Dim qdFindSv As DAO.QueryDef, StringFindSv As String, rsFindSv As DAO.Recordset ' для поиска в SQL сервере
'
'    Const cstrTitle As String _
'        = "Процедура *Отыскиваем стройку (объект САК) в базе данных*"
'
'    '**************************************************************************************************************************************
'
'On Error GoTo ErrHandler
'
'        cstapKey = 0
'
'        ' пробуем отыскать стройку
'        Set qdFindSv = db.QueryDefs("ags_PdSdRRcList")
'        StringFindSv = "select * from ags.cstAgPn where  cstapIpgPnN = '" & cstCodeStr & "'"
'        qdFindSv.SQL = StringFindSv
'        Set rsFindSv = qdFindSv.OpenRecordset()
'        ' имеется ли хотя бы одна запись стройки?
'        If rsFindSv.RecordCount > 0 Then
'            ' да, хотя бы одна запись агента стройки
'            rsFindSv.MoveFirst
'            cstapKey = rsFindSv!cstapKey
'            FindCstAP = True
'            Else
'            ' нет, стройка в базе данных отсутствует
'            FindCstAP = False
'        End If
'
'        ' нужен ли вызывающему функцию коду рекордсет со стройкой?
'        If IsMissing(rstC_A_C) = False Then
'            ' да, вызывающему функцию коду рекордсет со стройкой нужен
'            Set rstC_A_C = rsFindSv
'            Else
'            ' нет, вызывающему функцию коду рекордсет со стройкой не нужен
'            rsFindSv.Close: Set rsFindSv = Nothing
'        End If
'
'        ' закрываем всё, что было нужно для поиска стройку
'        qdFindSv.Close: Set qdFindSv = Nothing
'
'NormalExit:
'    Exit Function
'
'ErrHandler:
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
'
'End Function

' проверяем атрибуты акта агентского вознаграждения
Private Sub TestAct(ByRef c As Range, ByRef strFFF As String, ByRef rsAct As DAO.Recordset, _
    addRa As Boolean, ByRef db As DAO.Database)

    Dim cstNote As String, oafpNote_ As String
    Dim DateSource As Variant, DateDB As Variant
    Dim rstAct_add As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Проверяем атрибуты акта агентского вознаграждения*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' нужно ли добавлять отсутствующие отчёты либо корректировать существующие?
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' открываем набор записей для добавления или корректировки
        Set rstAct_add = db.OpenRecordset("ags_ogAgFee", dbOpenDynaset, dbFailOnError + dbSeeChanges)
    End If

    ' проверяем поступление
    If CompareStringWithEmpty(c.Offset(0, 1).value, rsAct!oafArrived, cstNote, oafpNote_) Then
        ' да, поступление соответствуют
        strFFF = strFFF & ". Поступ. <font color=""cadetBlue"">+</font>"
        ' но ещё нужно проверить соответствие даты
        ' определяем дату источника
        DateSource = ParseDate(c.Offset(0, 1).value, False)
        ' сравниваем источник с базой
        If DateSource <> rsAct!oafArrivedDate Then
            strFFF = strFFF & ". Дата поступ. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                & rsAct!oafArrivedDate & "</font>, ист.: <font color=""goldenrod"">" & DateSource & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
                If rstAct_add.NoMatch = False Then
                    rstAct_add.Edit
                        If Not IsEmpty(c.Offset(0, 1).value) And Not IsNull(c.Offset(0, 1).value) And Not c.Offset(0, 1).value = "" Then
                            'отыскиваем дату
                            rstAct_add!oafArrivedDate = ParseDate(c.Offset(0, 1).value, False)
                            Else
                            rstAct_add!oafArrivedDate = Null
                        End If
                    rstAct_add.Update
                    strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
            Else
            strFFF = strFFF & ". Дата поступ. <font color=""cadetBlue"">+</font>"
        End If
        Else
        ' нет, поступление не соответствует
        strFFF = strFFF & ". Поступ. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & oafpNote_ & "</font>. В источнике: <font color=""goldenrod"">" & cstNote & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    If Not IsEmpty(c.Offset(0, 1).value) And Not IsNull(c.Offset(0, 1).value) And Not c.Offset(0, 1).value = "" Then
                        rstAct_add!oafArrived = StringClean(c.Offset(0, 1).value)
                        'отыскиваем дату
                        rstAct_add!oafArrivedDate = ParseDate(c.Offset(0, 1).value, False)
                        Else
                        rstAct_add!oafArrived = Null
                        rstAct_add!oafArrivedDate = Null
                    End If
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    ' проверяем направление
    If CompareStringWithEmpty(c.Offset(0, 2).value, rsAct!oafSent, cstNote, oafpNote_) Then
        ' да, направление соответствуют
        strFFF = strFFF & ". Напр. <font color=""cadetBlue"">+</font>"
        ' но ещё нужно проверить соответствие даты
        ' определяем дату источника
        DateSource = ParseDate(c.Offset(0, 2).value, False)
        ' сравниваем источник с базой
        If DateSource <> rsAct!oafSentDate Then
            strFFF = strFFF & ". Дата напр. <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                & rsAct!oafSentDate & "</font>, ист.: <font color=""goldenrod"">" & DateSource & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
                If rstAct_add.NoMatch = False Then
                    rstAct_add.Edit
                        If Not IsEmpty(c.Offset(0, 2).value) And Not IsNull(c.Offset(0, 2).value) And Not c.Offset(0, 2).value = "" Then
                            'отыскиваем дату
                            rstAct_add!oafSentDate = ParseDate(c.Offset(0, 2).value, False)
                            Else
                            rstAct_add!oafSentDate = Null
                        End If
                    rstAct_add.Update
                    strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
            Else
            strFFF = strFFF & ". Дата напр. <font color=""cadetBlue"">+</font>"
        End If
        Else
        ' нет, направление не соответствует
        strFFF = strFFF & ". Напр. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & oafpNote_ & "</font>. В источнике: <font color=""goldenrod"">" & cstNote & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    If Not IsEmpty(c.Offset(0, 2).value) And Not IsNull(c.Offset(0, 2).value) And Not c.Offset(0, 2).value = "" Then
                        rstAct_add!oafSent = StringClean(c.Offset(0, 2).value)
                        'отыскиваем дату
                        rstAct_add!oafSentDate = ParseDate(c.Offset(0, 2).value, False)
                        Else
                        rstAct_add!oafSent = Null
                        rstAct_add!oafSentDate = Null
                    End If
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    ' проверяем возврат
    If CompareStringWithEmpty(c.Offset(0, 3).value, rsAct!oafReturned, cstNote, oafpNote_) Then
        ' да, возврат соответствуют
        strFFF = strFFF & ". Возврат <font color=""cadetBlue"">+</font>"
        ' но ещё нужно проверить соответствие даты
        ' определяем дату источника
        DateSource = ParseDate(c.Offset(0, 3).value, False)
        ' сравниваем источник с базой
        If DateSource <> rsAct!oafReturnedDate Then
            strFFF = strFFF & ". Дата возврата <font color=""cadetBlue"">не соответствует</font> БД: <font color=""purple"">" _
                & rsAct!oafReturnedDate & "</font>, ист.: <font color=""goldenrod"">" & DateSource & "</font>"
            ' нужно ли корректировать базу данных?
            If addRa Then
                ' да, корректировать базу данных нужно
                rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
                If rstAct_add.NoMatch = False Then
                    rstAct_add.Edit
                        If Not IsEmpty(c.Offset(0, 3).value) And Not IsNull(c.Offset(0, 3).value) And Not c.Offset(0, 3).value = "" Then
                            'отыскиваем дату
                            rstAct_add!oafReturnedDate = ParseDate(c.Offset(0, 3).value, False)
                            Else
                            rstAct_add!oafReturnedDate = Null
                        End If
                    rstAct_add.Update
                    strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                    Else
                    strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
                End If
            End If
            Else
            strFFF = strFFF & ". Дата возврата <font color=""cadetBlue"">+</font>"
        End If
        Else
        ' нет, возврат не соответствует
        strFFF = strFFF & ". Возврат <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & oafpNote_ & "</font>. В источнике: <font color=""goldenrod"">" & cstNote & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    If Not IsEmpty(c.Offset(0, 3).value) And Not IsNull(c.Offset(0, 3).value) And Not c.Offset(0, 3).value = "" Then
                        rstAct_add!oafReturned = StringClean(c.Offset(0, 3).value)
                        'отыскиваем дату
                        rstAct_add!oafReturnedDate = ParseDate(c.Offset(0, 3).value, False)
                        Else
                        rstAct_add!oafReturned = Null
                        rstAct_add!oafReturnedDate = Null
                    End If
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    ' проверяем примечания
    If CompareStringWithEmpty(c.Offset(0, 4).value, rsAct!oafNote, cstNote, oafpNote_) Then
        ' да, примечания соответствуют
        strFFF = strFFF & ". Прим. <font color=""cadetBlue"">+</font>"
        Else
        ' нет, примечания не соответствует
        strFFF = strFFF & ". Прим. <font color=""salmon"">не соответстует</font>. В БД: <font color=""purple"">" _
            & oafpNote_ & "</font>. В источнике: <font color=""goldenrod"">" & cstNote & "</font>"
        ' нужно ли корректировать базу данных?
        If addRa Then
            ' да, корректировать базу данных нужно
            rstAct_add.FindFirst "oafKey = " & rsAct!oafKey
            If rstAct_add.NoMatch = False Then
                rstAct_add.Edit
                    If Not IsEmpty(c.Offset(0, 4).value) And Not IsNull(c.Offset(0, 4).value) And Not c.Offset(0, 4).value = "" Then
                        rstAct_add!oafNote = StringClean(c.Offset(0, 4).value)
                        Else
                        rstAct_add!oafNote = Null
                    End If
                rstAct_add.Update
                strFFF = strFFF & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                Else
                strFFF = strFFF & ". <font color=""salmon"">Не найден для правки</font>."
            End If
        End If
    End If
    
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' закрываем набор записей для добавления или корректировки
        rstAct_add.Close: Set rstAct_add = Nothing
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' отыскиваем акт
Private Function FindAct(ByVal actNum As String, ByVal actDate As Date, ByVal agKey As Long, _
    ByVal yearAF As Integer, ByVal monthAF As Integer, _
    ByRef db As DAO.Database, ByRef rsAct As DAO.Recordset, ByRef actKey As Long) As Boolean
    ' набор записей с актом *rsAct* и первичный ключ акта *actKey* ВОЗВРАЩАЕМ

    Dim qdfAct As DAO.QueryDef ' для поиска актов

    Set qdfAct = db.QueryDefs("ags_PdSdRRcList")
    qdString = "select * from ags.ogAgFee where oafNum = '" & actNum _
        & "' and oafDate = '" & DateConvertToQuery(actDate, "sql") & "' and cstaAg = " & agKey & " and oafY = " _
        & yearAF & " and oafM = " & monthAF & ";"
    qdfAct.SQL = qdString
    Set rsAct = qdfAct.OpenRecordset()
        ' имеется ли хотя бы одна запись акта?
        If rsAct.RecordCount > 0 Then
            ' да, хотя бы одна запись акта имеется
            rsAct.MoveFirst
            actKey = rsAct!oafKey
            FindAct = True
            Else
            ' нет, нет не одной записи акта
            FindAct = False
        End If
    qdfAct.Close
    Set qdfAct = Nothing

End Function

' проверяем соответствие строк
Private Function CompareStringWithEmpty(strA As Variant, strB As Variant, _
    Optional ByRef ReturnA As String, Optional ByRef ReturnB As String) As Boolean
    
    ReturnA = EmptyOrString(strA)
    ReturnB = EmptyOrString(strB)
    
    ' равны ли значения строк, если они даже и пусты?
    If ReturnA = ReturnB Then
        ' да, значения строк, если они даже и пусты, равны
        CompareStringWithEmpty = True
        Else
        ' нет, значения строк, если они даже и пусты, не равны
        CompareStringWithEmpty = False
    End If

End Function

' проверяем строку на пустоту
Private Function EmptyOrString(StartValue As Variant) As String

    Dim strTemp As String
    
    ' начальная строка не является пустой?
    If IsNull(StartValue) = False And IsEmpty(StartValue) = False And StartValue <> "" Then
        ' да, начальная строка не является пустой
        strTemp = StringClean(CStr(StartValue))
        ' очищенная строка не является пустой?
        If IsNull(strTemp) = False And IsEmpty(strTemp) = False And strTemp <> "" Then
            ' да, очищенная строка не является пустой
            EmptyOrString = StringClean(CStr(StartValue))
            Else
            ' нет, очищенная строка является пустой
            EmptyOrString = "пусто"
        End If
        Else
        ' нет, начальная строка является пустой
        EmptyOrString = "пусто"
    End If
End Function


'' конвертируем дату в строку для вставки в строку запроса Target = 'sql'
'Private Function DateConvertToQuery(DateToConv As Date, Optional ByVal Target As String = "access") As String
'
'    Select Case Target
'        Case "sql"
'            DateConvertToQuery = year(DateToConv) & "-" & month(DateToConv) & "-" & Day(DateToConv)
'        Case Else
'            DateConvertToQuery = "#" & month(DateToConv) & "/" & Day(DateToConv) & "/" & year(DateToConv) & "#"
'    End Select
'
'End Function


' Ищем номер и дату акта
Private Function FindActAgFeeNumDate(ByVal StringValue As String, ByRef actNum As String, ByRef actDate As Date) As Boolean

    Dim Match As Object, RegExp As Object, strReg As String, StringValueCl As String, CountDates As Integer
    Dim ParseDateResult As Variant

    Const cstrTitle As String _
        = "Процедура *Ищем номер и дату акта*"

    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    FindActAgFeeNumDate = False
    StringValueCl = StringClean(StringValue)

    Set RegExp = CreateObject("VBScript.RegExp")
    ' определяем шаблон регулярного выражения
    ' RealQ = Chr(34) Акт №  39 ДС  от 31.07.2021
    'strReg = "((Изм\.№\d|Изм\.№\d{2}|Изм\.\d|Изм\.\d{2}|Изм\d|Изм\d{2})( |\.|,))"
    'strReg = "((Акт № )((\d|d{2})( ДС|ДС))( от )(\d{2}\.\d{2}\.(\d{2}(\D|$)|\d{4})))"
    'strReg = "((Акт № )((\d|\d{2})( ДС|ДС))( от )(\d{2}\.\d{2}\.d{4}))"
    strReg = "((^)|(^Акт № )|(^Акт )|(^№ ))(((\d|\d{2})( ДС|ДС))|(\d|\d{2}))( от \d{2}\.\d{2}\.\d{4})$"
    ' присваиваем шаблон регулярного выражения
    RegExp.Pattern = strReg
    ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
    RegExp.Global = False
    Set Match = RegExp.Execute(StringValueCl)
    If Match.count > 0 Then
        If IsDate(Right(StringValueCl, 10)) Then
            actDate = CDate(Right(StringValueCl, 10))
            If Left(StringValueCl, 6) = "Акт № " Then
                actNum = Mid(StringValueCl, 6, Len(StringValueCl) - 19)
                Else
                If Left(StringValueCl, 4) = "Акт " Then
                    actNum = Mid(StringValueCl, 4, Len(StringValueCl) - 17)
                    Else
                    If Left(StringValueCl, 2) = "№ " Then
                        actNum = Mid(StringValueCl, 2, Len(StringValueCl) - 15)
                        Else
                        actNum = Left(StringValueCl, Len(StringValueCl) - 13)
                    End If
                End If
            End If
            actNum = Trim(actNum)
            FindActAgFeeNumDate = True
        End If
        Else
        ' вторая попытка
        ' имеются ли даты в строке?
        ParseDateResult = ParseDate(Text:=StringValueCl, Start:=False, CountDates:=CountDates)
        If IsNull(ParseDateResult) = False Then
            ' да, даты в строке имеются
            ' одна ли дата в строке?
            If CountDates = 1 Then
                ' да, в строке одна дата
                strReg = " от \d{2}\.\d{2}\.(\d{2}|\d{4})$"
                ' присваиваем шаблон регулярного выражения
                RegExp.Pattern = strReg
                ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
                RegExp.Global = False
                Set Match = RegExp.Execute(StringValueCl)
                If Match.count > 0 Then
                    If IsDate(Right(StringValueCl, 10)) Then
                        actNum = _
                            Replace(Replace(Replace(Replace(Left(StringValueCl, Len(StringValueCl) - 14), "Акты № ", ""), "Акт № ", ""), "№ ", ""), "№", "")
                        actNum = Trim(actNum)
                        actDate = CDate(Right(StringValueCl, 10))
                        FindActAgFeeNumDate = True
                    End If
                    If IsDate(Right(StringValueCl, 8)) Then
                        actNum = _
                            Replace(Replace(Replace(Replace(Left(StringValueCl, Len(StringValueCl) - 12), "Акты № ", ""), "Акт № ", ""), "№ ", ""), "№", "")
                        actNum = Trim(actNum)
                        actDate = CDate(Right(StringValueCl, 8))
                        FindActAgFeeNumDate = True
                    End If
                End If
                Else
                ' нет, в строке более чем одна дата
                ' видимо здесь нужно всю строку признать номером акта а самую позднюю дату признать датой акта
                actNum = StringValueCl
                actDate = ParseDateResult
                FindActAgFeeNumDate = True
            End If
        End If
    End If

NormalExit:
    Exit Function
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

'' Пребразование строки к дате
'Private Function StrToDate(str_date As String) As Date
'    Dim str_date_10 As String
'
'    Const cstrTitle As String = "Функция *Пребразование строки к дате*"
'
'On Error GoTo ErrHandler
'
'    If IsDate(str_date) Then
'            StrToDate = CDate(str_date)
'        Else
'            If Len(str_date) > 10 Then
'                str_date_10 = Left(str_date, 10)
'                If IsDate(str_date_10) Then
'                    StrToDate = CDate(str_date_10)
'                    Else
'                    StrToDate = 0
'                End If
'                Else
'                StrToDate = 0
'            End If
'    End If
'
'NormalExit:
'    Exit Function
'
'ErrHandler:
'
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
'
'End Function

' Обрабатываем найденный отчёт агента.
Private Sub ReportOfAgent(ra As String, ra_date As Variant, Constraction As String, period As Integer, _
    addRa As Boolean, str As String, db As DAO.Database, _
    total As Variant, work As Variant, equipment As Variant, others As Variant, _
    arrived As String, returned As String, sent As String, note As String, ra_org_sender As Long, _
    ra_type As String)

    Dim rstC_A_C As DAO.Recordset 'набор записей для поиска сущности стройка-агент-код
    Dim rst_ra As DAO.Recordset 'набор записей для поиска сущности отчёта
    Dim rst_ra_add As DAO.Recordset 'набор записей для добавления сущности отчёта
    Dim rst_ra_add_sum As DAO.Recordset 'набор записей для добавления сумм по отчёту
    Dim rst_ra_upd_sum As DAO.Recordset 'набор записей для корректировки сумм по отчёту
    Dim qdString As String
    Dim raNewKey As Long, ra_summ_NewKey As Long
    Dim parsedDate As Variant 'для приёма даты, извлечённой из строки
    Dim paragraph As String 'для формирования строчного абзаца
    
    ' без пробелов в начале и окончании строки, также с однообразно замененными Null и пустой строкой
    Dim ra_ As String
    Dim arrived_ As String, returned_ As String, sent_ As String, note_ As String
    Dim Constraction_ As String
    ' проверяемые из таблицы отчётов
    Dim arrived_r As String, returned_r As String, sent_r As String, note_r As String
    
    Dim nnn As Integer
    Dim ar

    Const cstrTitle As String _
        = "Процедура *Обрабатываем найденный отчёт агента, Ревизия отчётов агента, файл - отчёты агента, лист - отчётного периода*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    'очистим от пробелов в окончании и конце, также однообразно заменим Null и пустую строку ""
    ra_ = RTrim(LTrim(ra))
    
    'для представления
    If arrived = "" Or IsNull(arrived) Then
        arrived_ = "Пустое значение строки"
        Else
        arrived_ = RTrim(LTrim(arrived))
    End If
    
    'для возвращения
    If returned = "" Or IsNull(returned) Then
        returned_ = "Пустое значение строки"
        Else
        returned_ = RTrim(LTrim(returned))
    End If
    
    'для отправки в бухгалтерию
    If sent = "" Or IsNull(sent) Then
        sent_ = "Пустое значение строки"
        Else
        sent_ = RTrim(LTrim(sent))
    End If
    
    ' для примечаний
    If note = "" Or IsNull(note) Then
        note_ = "Пустое значение строки"
        Else
        note_ = StringClean(note)
    End If
    
    Constraction_ = StringClean(Constraction)
    
    paragraph = "<P>  <font color=""Silver"">Найден типа: </font>*" _
        & ra_type & "*; <font color=""Silver"">имя</font>: " & ra_ & ". <font color=""Silver"">Стр</font>. - " & Constraction & "."
    
    ' нужно ли добавлять отсутствующие отчёты либо корректировать существующие?
    If addRa Then
        ' да, отсутствующие отчёты нужно добавлять либо корректировать существующие
        ' открываем набор записей для добавления или корректировки
        Set rst_ra_add = db.OpenRecordset("ags_ra", dbOpenDynaset, dbFailOnError + dbSeeChanges)
    End If
    
    'имеется ли стройка в базе данных?
    qdString = "select * from ags_cstAgPn where cstapIpgPnN = """ & Constraction_ & """;"
    Set rstC_A_C = db.OpenRecordset(qdString, dbOpenSnapshot)
    
    If rstC_A_C.RecordCount > 0 Then
        'да, стройка в базе данных имеется
        rstC_A_C.MoveFirst
        paragraph = paragraph & " <font color=""Silver"">Найден САК в бд, ID - " & rstC_A_C!cstapKey & ". Об. СА, ID - " & rstC_A_C!cstapCsta & "</font>."
        'имеется ли отчёт?
        'дата отчёта отлична от ноля?
        'If ra_date <> 0 Then
            'да, дата отчёта отлична от ноля
        '    Dim dddS As String
        '    dddS = "#" & Month(ra_date) & "/" & Day(ra_date) & "/" & Year(ra_date) & "#"
            
        '    qdString = "SELECT * FROM ags_ra WHERE ra_num = """ & ra_ & _
        '        """ AND ra_date = " & dddS & _
        '        " AND ra_cac = " & rstC_A_C!cstapKey & _
        '        " AND ra_period = " & period & ";"
        '    Else
            
            qdString = "SELECT * FROM ags_ra WHERE ra_num = """ & ra_ & _
                """ AND ra_cac = " & rstC_A_C!cstapKey & _
                " AND ra_period = " & period & ";"
        'End If
        'имеется ли такой отчёт в этом отчётном периоде?
        Set rst_ra = db.OpenRecordset(qdString, dbOpenSnapshot)
        If rst_ra.RecordCount > 0 Then
            'да, такой отчёт имеется ----------------------------------------------------------------------------------------------------------------
            If ra_type = "ОА" Then
                paragraph = paragraph & " <font color=""DarkGray"">Найден ОА:</font> <font color=""green"">" & ra_ & " от " & ra_date & _
                    " в БД</font>. <font color=""Silver"">ID - " & rst_ra!ra_key & "</font>."
                Else
                paragraph = paragraph & " <font color=""DarkGray"">Найден ОП:</font> <font color=""olive"">" & ra_ & " от " & ra_date & _
                    " в БД</font>. <font color=""Silver"">ID - " & rst_ra!ra_key & "</font>."
            End If
            'проверяем соответствие значение атрибутов в файле
            
            ' для типа отчёта
            If ra_type <> rst_ra!ra_type Then
                paragraph = paragraph & " <font color=""silver""><font color=""salmon"">Не соответствует тип</font>." _
                    & " БД: <font color=""Crimson"">" & rst_ra!ra_type & "</font>. источник: <font color=""CadetBlue"">" & ra_type & "</font></font>."
                ' нужно ли корректировать существующие отчёты?
                If addRa Then
                    ' да, нужно корректировать существующие отчёты?
                    rst_ra_add.FindFirst "ra_key = " & rst_ra!ra_key
                    If rst_ra_add.NoMatch = False Then
                        rst_ra_add.Edit
                            rst_ra_add!ra_type = ra_type
                        rst_ra_add.Update
                        paragraph = paragraph & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        paragraph = paragraph & ". <font color=""red"">Не найден для правки</font>."
                    End If
                End If
            End If
            
            ' для поступления
            If rst_ra!ra_arrived = "" Or IsNull(rst_ra!ra_arrived) Then
                arrived_r = "Пустое значение строки"
                Else
                arrived_r = RTrim(LTrim(rst_ra!ra_arrived))
            End If
            
            If arrived_r <> arrived_ Then
                paragraph = paragraph & " <font color=""red"">Не соответствует поступление</font>." & " Старое: " & arrived_r & ". Новое: " & arrived_
                ' нужно ли корректировать существующие отчёты?
                If addRa Then
                    ' да, нужно корректировать существующие отчёты
                    rst_ra_add.FindFirst "ra_key = " & rst_ra!ra_key
                    If rst_ra_add.NoMatch = False Then
                        rst_ra_add.Edit
                            rst_ra_add!ra_arrived = RTrim(LTrim(arrived))
                            'отыскиваем дату
                            If arrived_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(arrived_, False)
                                If IsNull(parsedDate) = False Then
                                    rst_ra_add!ra_arrived_date = parsedDate
                                End If
                            End If
                        rst_ra_add.Update
                        paragraph = paragraph & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        paragraph = paragraph & ". <font color=""red"">Не найден для правки</font>."
                    End If
                End If
            End If
                        
            'для возвращения
            If rst_ra!ra_returned = "" Or IsNull(rst_ra!ra_returned) Then
                returned_r = "Пустое значение строки"
                Else
                returned_r = RTrim(LTrim(rst_ra!ra_returned))
            End If
                        
            If returned_r <> returned_ Then
                paragraph = paragraph & " <font color=""red"">Не соответствует возвращение</font>." & " Старое: " & returned_r & ". Новое: " & returned_
                ' нужно ли корректировать существующие отчёты?
                If addRa Then
                    ' да, нужно корректировать существующие отчёты
                    rst_ra_add.FindFirst "ra_key = " & rst_ra!ra_key
                    If rst_ra_add.NoMatch = False Then
                        rst_ra_add.Edit
                            rst_ra_add!ra_returned = RTrim(LTrim(returned))
                            'отыскиваем дату
                            If returned_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(returned_, False)
                                If IsNull(parsedDate) = False Then
                                    rst_ra_add!ra_returned_date = parsedDate
                                End If
                            End If
                        rst_ra_add.Update
                        paragraph = paragraph & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        paragraph = paragraph & ". <font color=""red"">Не найден для правки</font>."
                    End If
                End If
            End If
            
            'для отправки в бухгалтерию
            If rst_ra!ra_sent = "" Or IsNull(rst_ra!ra_sent) Then
                sent_r = "Пустое значение строки"
                Else
                sent_r = RTrim(LTrim(rst_ra!ra_sent))
            End If
            
            If sent_r <> sent_ Then
                paragraph = paragraph & " <font color=""red"">Не соответствует направление в ДБУ</font>." & " Старое: " & sent_r & ". Новое: " & sent_
                ' нужно ли корректировать существующие отчёты?
                If addRa Then
                    ' да, нужно корректировать существующие отчёты
                    rst_ra_add.FindFirst "ra_key = " & rst_ra!ra_key
                    If rst_ra_add.NoMatch = False Then
                        rst_ra_add.Edit
                            rst_ra_add!ra_sent = RTrim(LTrim(sent))
                            'отыскиваем дату
                            If sent_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(sent_, False)
                                If IsNull(parsedDate) = False Then
                                    rst_ra_add!ra_sent_date = parsedDate
                                End If
                            End If
                        rst_ra_add.Update
                        paragraph = paragraph & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        paragraph = paragraph & ". <font color=""red"">Не найден для правки</font>."
                    End If
                End If
            End If
            
            ' для примечаний
            If rst_ra!ra_note = "" Or IsNull(rst_ra!ra_note) Then
                note_r = "Пустое значение строки"
                Else
                note_r = StringClean(rst_ra!ra_note)
            End If
            
            ' If note_ <> "Пустое значение строки" And (note_r Like "*" & note_ & "*") = False Then
            If note_r <> note_ Then
                paragraph = paragraph & " <font color=""red"">Не соответствует примечание</font>." & " Старое: " & note_r & ". Новое: " & note_
                ' нужно ли корректировать существующие отчёты?
                If addRa Then
                    ' да, нужно корректировать существующие отчёты
                    rst_ra_add.FindFirst "ra_key = " & rst_ra!ra_key
                    If rst_ra_add.NoMatch = False Then
                        rst_ra_add.Edit
                            rst_ra_add!ra_note = StringClean(note)
                        rst_ra_add.Update
                        paragraph = paragraph & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                        Else
                        paragraph = paragraph & ". <font color=""red"">Не найден для правки</font>."
                    End If
                End If
            End If
            
            ' Проверяем наличие и значения сумм. По самой поздней сумме
            qdString = "SELECT ras_key, ras_ra, ras_total, ras_work, ras_equip, ras_others, ras_date FROM ags_raSmLt where ras_ra = " & rst_ra!ra_key
                
            Set rst_ra_add_sum = db.OpenRecordset(qdString, dbOpenSnapshot)
                With rst_ra_add_sum
                    ' имеются ли в БД суммы для текущего отчёта?
                    If .RecordCount > 0 Then
                        ' да, в БД суммы для текущего отчёта имеются
                        .MoveFirst
                        bbb = True ' по умолчанию считаем что все суммы соответствуют
                        bbc = True ' заготавливаем переменную для получения информации о соответствии сумм из процедуры
                        ' прверяем всю сумму
                        bbb = SummCompare(!ras_total, total, paragraph, "Всего")
                        
                        ' проверяем СМР
                        bbc = SummCompare(!ras_work, work, paragraph, "СМР")
                        If bbb Then
                            bbb = bbc
                        End If
                        ' проверяем оборудование
                        bbc = SummCompare(!ras_equip, equipment, paragraph, "Оборудование")
                        If bbb Then
                            bbb = bbc
                        End If
                        ' проверяем прочие затраты
                        bbc = SummCompare(!ras_others, others, paragraph, "Прочее")
                        If bbb Then
                            bbb = bbc
                        End If
                        
                        ' ну и делаем вывод. Соответствуют ли суммы?
                        If bbb Then
                            ' да, все суммы соответствуют
                            paragraph = paragraph & " <font color=""darkblue"">Все суммы соответствуют</font>."
                            Else
                            ' нет, есть суммы, которые не соответствуют
                            ' нужно ли корректировать существующие отчёты?
                            If addRa Then
                                ' да, нужно корректировать существующие отчёты
                                'добавляем запись сумм
                                Set rst_ra_upd_sum = db.OpenRecordset("ags_ra_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                                    With rst_ra_upd_sum
                                        .AddNew
                                            !ras_ra = rst_ra!ra_key
                                            !ras_date = Now
                                            If Not IsEmpty(total) And IsNumeric(total) Then
                                                !ras_total = total
                                                Else
                                                !ras_total = Null
                                            End If
                                            If Not IsEmpty(work) And IsNumeric(work) Then
                                                !ras_work = work
                                                Else
                                                !ras_work = Null
                                            End If
                                            If Not IsEmpty(equipment) And IsNumeric(equipment) Then
                                                !ras_equip = equipment
                                                Else
                                                !ras_equip = Null
                                            End If
                                            If Not IsEmpty(others) And IsNumeric(others) Then
                                                !ras_others = others
                                                Else
                                                !ras_others = Null
                                            End If
                                        .Update
                                        .Bookmark = .LastModified
                                        ra_summ_NewKey = !ras_key
                                        .Close
                                    End With
                                Set rst_ra_upd_sum = Nothing
                                paragraph = paragraph & " <font color=""blueviolet"">Добавлены обновлённые суммы к отчёту</font>. " _
                                    & "<font color=""silver"">ID - " & ra_summ_NewKey & _
                                    "</font>."
                            End If
                        End If
                        Else
                        ' нет, в БД суммы для текущего отчёта отсутствуют
                        ' но имеются ли суммы для данного отчёта в источнике данных?
                        If (IsEmpty(total) = False Or IsEmpty(work) = False Or IsEmpty(equipment) = False Or IsEmpty(others) = False) _
                            And ((total + work + equipment + others) <> 0) Then
                            ' да, в суммах есть что-то кроме пустоты и нулей
                            paragraph = paragraph & _
                                " <font color=""crimson"">В БД суммы для текущего отчёта <B>отсутствуют</B>, однако в источнике они <B>есть</B></font>! "
                            Else
                            ' нет, в суммах ничего кроме пустоты или нулей нет
                            paragraph = paragraph & _
                                " <font color=""lightSeaGreen"">В БД и в источнике суммы для текущего отчёта <B>отсутствуют</B></font>. "
                        End If
                    End If
                    .Close
                End With
            Set rst_ra_add_sum = Nothing
            paragraph = paragraph & "</P>"
            'да, такой отчёт имеется ----------------------------------------------------------------------------------------------------------------
            Else
            'нет, такой отчёт отсутствует -----------------------------------------------------------------------------------------------------------
            'нужно ли добавлять отсутствующие отчёты
            If addRa Then
                'да, отсутствующие отчёты нужно добавлять
                'Set rst_ra_add = db.OpenRecordset("ags_ra", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                With rst_ra_add
                    .AddNew
                        !ra_num = ra_
                        If ra_date <> 0 Then
                            !ra_date = ra_date
                        End If
                        !ra_type = ra_type
                        !ra_cac = rstC_A_C!cstapKey
                        !ra_period = period
                        !ra_note_t = "<P>Создан простой отчёт - " & ra_ & ". Дата - " & Now & ". При помощи ревизии</P>"
                        
                        'заполняем графы поступление и время поступления
                        If arrived <> "" Then
                            !ra_arrived = arrived_
                            'отыскиваем дату
                            If arrived_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(arrived_, False)
                                If IsNull(parsedDate) = False Then
                                    !ra_arrived_date = parsedDate
                                End If
                            End If
                        End If
                        
                        'заполняем графы возвращение и время возвращения
                        If returned <> "" Then
                            !ra_returned = returned_
                            'отыскиваем дату
                            If returned_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(returned_, False)
                                If IsNull(parsedDate) = False Then
                                    !ra_returned_date = parsedDate
                                End If
                            End If
                        End If
                        
                        'заполняем графы отправлен и время отправления
                        If sent <> "" Then
                            !ra_sent = sent_
                            'отыскиваем дату
                            If sent_ Like "*##.##.####*" Then
                                parsedDate = ParseDate(sent_, False)
                                If IsNull(parsedDate) = False Then
                                    !ra_sent_date = parsedDate
                                End If
                            End If
                        End If
                        
                        'заполняем графу примечаний
                        If note <> "" Then
                            !ra_note = !ra_note & "<p>" & note_ & ".</p>"
                        End If
                        
                        !ra_created = Now
                        !ra_org_sender = ra_org_sender
                    .Update
                    .Bookmark = .LastModified
                    raNewKey = !ra_key
                    paragraph = paragraph & " <font color=""orange"">Не найден ОА " & ra_ & " от " & ra_date & _
                    " в бд</font>. Отчёт <font color=""DarkGreen"">добавлен</font>. ID - " & raNewKey & "."
                    .Close
                End With
                Set rst_ra_add = Nothing
                'добавляем суммы
                'есть ли в суммах что-то кроме пустоты?
                If IsEmpty(total) = False Or IsEmpty(work) = False Or IsEmpty(equipment) = False Or IsEmpty(others) = False Then
                    'да, в суммах есть что-то кроме пустоты
                    'добавляем запись сумм
                    Set rst_ra_add_sum = db.OpenRecordset("ags_ra_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                        With rst_ra_add_sum
                            .AddNew
                                !ras_ra = raNewKey
                                !ras_date = Now
                                If Not IsEmpty(total) And IsNumeric(total) Then
                                    !ras_total = total
                                End If
                                If Not IsEmpty(work) And IsNumeric(work) Then
                                    !ras_work = work
                                End If
                                If Not IsEmpty(equipment) And IsNumeric(equipment) Then
                                    !ras_equip = equipment
                                End If
                                If Not IsEmpty(others) And IsNumeric(others) Then
                                    !ras_others = others
                                End If
                            .Update
                            .Bookmark = .LastModified
                            ra_summ_NewKey = !ras_key
                            .Close
                        End With
                    Set rst_ra_add_sum = Nothing
                    paragraph = paragraph & " <font color=""blue"">Добавлены суммы к отчёту. ID - " & ra_summ_NewKey & _
                    "</font>.</P>"
                    Else
                    'нет, суммы все пусты
                    paragraph = paragraph & " <font color=""blue"">Суммы не добавлены, так как пусты</font>.</P>"
                End If
                Else
                'нет, отсутствующие отчёты добавлять не нужно
                paragraph = paragraph & " <font color=""red"">Не найден ОА " & ra_ & " от " & ra_date & " в бд</font>.</P>"
            'нет, такой отчёт отсутствует -----------------------------------------------------------------------------------------------------------
            End If
        End If
        rst_ra.Close: Set rst_ra = Nothing
        Else
        'нет, стройка в базе данных отсутствует
        paragraph = paragraph & " <font color=""DarkOrange"">Не найден объект <b>САК</b> в бд.</font></P>"
    End If
    
    str = paragraph & str
    
    rstC_A_C.Close

NormalExit:
    Set rstC_A_C = Nothing
    Exit Sub
    
ErrHandler:
    
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' проверяем совпадение сумм
Function SummCompare(DataBaseSumm As Variant, SourceSumm As Variant, ByRef Paragraf As String, SummType As String) As Boolean

    Dim dsSt As String, dsCr As Currency, sSt As String, sCr As Currency
    
        Const cstrTitle As String _
        = "Процедура *Проверяем совпадение сумм*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    ' делаем строку суммы из БД
    If IsNull(DataBaseSumm) Then
        dsSt = "Null": dsCr = CCur(0)
        Else
        If IsEmpty(DataBaseSumm) Then
            dsSt = "Empty": dsCr = CCur(0)
            Else
            dsSt = Format(DataBaseSumm, "Currency"): dsCr = CCur(DataBaseSumm)
        End If
    End If
    
    ' делаем строку суммы из источника
    If IsNull(SourceSumm) Then
        sSt = "Null": sCr = CCur(0)
        Else
        If IsEmpty(SourceSumm) Then
            sSt = "Empty": sCr = CCur(0)
            Else
            sSt = Format(SourceSumm, "Currency"): sCr = CCur(SourceSumm)
        End If
    End If
    
    ' заготавливаем результат функции
    SummCompare = True
    
    ' определяем результат функции
    If Not dsCr = sCr Then
        Paragraf = Paragraf & " <font color=""red"">Не соответствует *" & _
            SummType & "*</font>. <font color=""darkred"">БД: <b>" & _
            dsSt & "</b></font>, <font color=""IndianRed"">источник: <b>" & sSt & "</b></font>."
        SummCompare = False
    End If
    
NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

' обрабатываем найденное изменение отчёта
Private Sub ChangeOfReportOfAgent( _
    ChRpStr As String, ChRpDate As Date, cst As String, fff As String, db As DAO.Database, period As Integer, addRa As Boolean, _
    total As Variant, work As Variant, equipment As Variant, others As Variant, _
    arrived As String, returned As String, sent As String, note As String, ra_org_sender As Long _
    )

    Dim StrArray() As String ' массив для найденных слов
    Dim li As Integer, ssss As String, iii As Integer, stSm As String
    Dim Rddd As Date, RdddV As Variant, RdddS As String, Rnum As String, isChange As Boolean, ChNum As Integer, stst As String
    
    Dim rstC_A_C As DAO.Recordset 'набор записей для поиска сущности стройка-агент-код
    Dim rst_ra As DAO.Recordset 'набор записей для поиска сущности отчёта
    Dim rst_raCh As DAO.Recordset 'набор записей для поиска сущности изменения к отчёту
    Dim rst_raChSm As DAO.Recordset 'набор записей для поиска сущности суммы к изменению к отчёту
    Dim rst_raCh_add As DAO.Recordset 'открываем набор записей для добавления или корректировки изменения к отчёту
    Dim rst_raCh_add_sum As DAO.Recordset 'набор записей для добавления сумм по изменению
    Dim qdString As String, raChNewKey As Long, raCh_summ_NewKey As Long
    Dim Match As Object, RegExp As Object, strReg As String
    Dim MatchD As Object, RegExpD As Object, strRegD As String
    Dim rst_ra_upd_sum As DAO.Recordset, ra_summ_NewKey As Long
    
    ' без пробелов в начале и окончании строки, также с однообразно замененными Null и пустой строкой
    Dim arrived_ As String, returned_ As String, sent_ As String, note_ As String
        ' проверяемые из таблицы отчётов
    Dim arrived_r As String, returned_r As String, sent_r As String, note_r As String, nummStr As String

    Const cstrTitle As String _
        = "Процедура *Обрабатываем найденное изменение отчёта агента, Ревизия отчётов агента, файл - отчёты агента, лист - отчётного периода*"
        
    '**************************************************************************************************************************************
    
On Error GoTo ErrHandler

    ' для начала пометим, что это не изменение, что номер его 0, номера отчёта нет, даты отчёта нет
    isChange = False: ChNum = 0: Rnum = "Нет номера отчёта" ': Rddd = Null
    
    ' попробуем найти номер изменения сразу
    Set RegExp = CreateObject("VBScript.RegExp")
    ' определяем шаблон регулярного выражения
    ' RealQ = Chr(34)... (Изм|изм)(\.)*(№| №)*( )*([0-9]{1,3})
    'strReg = "((Изм\.№\d|Изм\.№\d{2}|Изм\.\d|Изм\.\d{2}|Изм\d|Изм\d{2})( |\.|,))"
    strReg = "(Изм|изм|Изменение|изменение)(\.| \.)*(№| №)*( )*([0-9]{1,3})"
    ' присваиваем шаблон регулярного выражения
    RegExp.Pattern = strReg
    ' устанавливаем вместо поиска всех совпадений в строке поиск первого совпадения
    RegExp.Global = False
    Set Match = RegExp.Execute(StringClean(ChRpStr))
    If Match.count > 0 Then
        ' ищем номер
        nummStr = StringClean(Match(0).value)
        
        Set RegExpD = CreateObject("VBScript.RegExp")
        strRegD = "([0-9]{1,3})"
        RegExpD.Pattern = strRegD
        RegExpD.Global = False
        Set MatchD = RegExpD.Execute(nummStr)
        If MatchD.count > 0 Then
            If IsNumeric(MatchD(0).value) = True Then
                ChNum = CInt(MatchD(0).value)
            End If
        End If
        
'        ' убираем справа точку или запятую. Правый знак это точка или запятая?
'        If Right(nummStr, 1) = "." Or Right(nummStr, 1) = "," Then
'            ' да, правый знак это точка или запятая
'            nummStr = Left(nummStr, Len(nummStr) - 1)
'            Else
'            ' нет, правый знак это не точка и не запятая
'        End If
        
'        ' префикс - 7 знаков?
'        If Left(nummStr, 7) = "Изм. № " Then
'            ' да, префикс - 7 знаков
'            nummStr = Trim(Right(nummStr, Len(nummStr) - 7))
'            If IsNumeric(nummStr) = True Then
'                ChNum = CInt(nummStr)
'            End If
'            Else
'            ' нет, префикс не 7 знаков
'            ' префикс - 6 знаков?
'            If Left(nummStr, 6) = "Изм. №" Or Left(nummStr, 6) = "Изм.№ " Or Left(nummStr, 6) = "Изм № " Then
'                ' да, префикс - 6 знаков
'                nummStr = Trim(Right(nummStr, Len(nummStr) - 6))
'                If IsNumeric(nummStr) = True Then
'                    ChNum = CInt(nummStr)
'                End If
'                Else
'                ' нет, префикс не 6 знаков
'                ' префикс - 5 знаков?
'                If Left(nummStr, 5) = "Изм.№" Or Left(nummStr, 5) = "Изм №" Or Left(nummStr, 5) = "Изм. " Then
'                    ' да, префикс - 5 знаков
'                    nummStr = Trim(Right(nummStr, Len(nummStr) - 5))
'                    If IsNumeric(nummStr) = True Then
'                        ChNum = CInt(nummStr)
'                    End If
'                    Else
'                    ' нет, префикс не 5 знаков
'                    If Left(nummStr, 4) = "Изм." Then
'                        nummStr = Trim(Right(nummStr, Len(nummStr) - 4))
'                        If IsNumeric(nummStr) = True Then
'                            ChNum = CInt(nummStr)
'                        End If
'                        Else
'                            If Left(nummStr, 3) = "Изм" Then
'                                nummStr = Trim(Right(nummStr, Len(nummStr) - 3))
'                                If IsNumeric(nummStr) = True Then
'                                    ChNum = CInt(nummStr)
'                                End If
'                            End If
'                    End If
'                End If
'            End If
'        End If
        
'        Select Case nummStr
'            Case Left(Match(0).value, Len(Match(0).value) - 1) = "Изм.№"
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 1), "Изм.№", ""))
'            Case Left(Match(0).value, Len(Match(0).value) - 2) = "Изм.№"
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 2), "Изм.№", ""))
'            Case Left(Match(0).value, Len(Match(0).value) - 1) = "Изм."
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 1), "Изм.", ""))
'            Case Left(Match(0).value, Len(Match(0).value) - 2) = "Изм."
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 2), "Изм.", ""))
'            Case Left(Match(0).value, Len(Match(0).value) - 1) = "Изм"
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 1), "Изм", ""))
'            Case Left(Match(0).value, Len(Match(0).value) - 2) = "Изм"
'                ChNum = CInt(Replace(Left(Match(0).value, Len(Match(0).value) - 2), "Изм", ""))
'        End Select
    End If
    
    ' разобьём строку на отдельные слова, сначала почистив
    StrArray() = Split(StringClean(ChRpStr))
    
    ' пройдём по всем словам
    ssss = "": iii = 1
    For li = LBound(StrArray) To UBound(StrArray)
        If iii = 1 Then
            ssss = iii & ". " & StrArray(li)
            Else
            ssss = ssss & ", " & iii & ". " & StrArray(li)
        End If
        
        ' проверяем, что это изменение
        If StrArray(li) Like "*Изм*" Then
            isChange = True
            ssss = ssss & ", это действительно изм."
        End If

        ' пробуем перевести в номер изменения
        If Left(StrArray(li), 1) = "№" And Len(StrArray(li)) > 1 Then
            stst = Right(StrArray(li), Len(StrArray(li)) - 1)
            Else
            stst = StrArray(li)
        End If
        
        If IsNumeric(stst) Then
            If ChNum = 0 Then
                ChNum = CInt(stst)
                ssss = ssss & ", это номер изм."
                Else
                ssss = ssss & ", это ВТОРОЙ номер изм.? Плохо. Оставим номером первый."
            End If
        End If
        
        ' отыскиваем номер отчёта
        If StrArray(li) Like "*-???????-*" Then
            If Left(StrArray(li), 1) = "№" Then
                Rnum = Right(StrArray(li), Len(StrArray(li)) - 1)
                Else
                Rnum = StrArray(li)
            End If
            ssss = ssss & ", № отч."
        End If
        
        iii = iii + 1
    Next li
    
    ' отыскиваем самую раннюю дату как дату отчёта
    RdddV = ParseDate(RTrim(LTrim(ChRpStr)), True, RdddS)
    If IsNull(RdddV) = False Then
        Rddd = RdddV
        ssss = ssss & ", " & Rddd & " - дата отч."
        Else
        ssss = ssss & ", <font color=""DarkRed"">дата отч. не найдена, " & RdddS & "</font>"
    End If
    
    ' посмотрим, что у нас вышло после анализа отдельных слов
    ' вообще это изменение?
    If isChange Then
        ' да, это изменение
        ' имеется ли номер изменения?
        If ChNum > 0 Then
            ' да, номер изменеия имеется
            ' имеется ли дата изменения?
            If IsNull(ChRpDate) = False Then
                ' да, дата изменения имеется
                ' найден номер отчёта?
                If Rnum <> "Нет номера отчёта" Then
                    ' имеется ли стройка в базе данных?
                    qdString = "select * from ags_cstAgPn where cstapIpgPnN = """ & cst & """;"
                    Set rstC_A_C = db.OpenRecordset(qdString, dbOpenSnapshot)
                    
                    If rstC_A_C.RecordCount > 0 Then
                        ' да, стройка в базе данных имеется
                        rstC_A_C.MoveFirst
                        ssss = ssss & ". Найден САК в бд, ID - " & rstC_A_C!cstapKey '& ". Объект СА, ID - " & rstC_A_C!cstapCsta & "."
                        ' имеется ли отчёт?
                        ' дата отчёта отлична от ноля?
                        If Rddd <> 0 Then
                            ' да, дата отчёта отлична от ноля
                            Dim dddS As String
                            dddS = "#" & Month(Rddd) & "/" & Day(Rddd) & "/" & year(Rddd) & "#"
                            
                            qdString = "SELECT * FROM ags_ra WHERE ra_num = """ & Rnum & _
                                """ AND ra_date = " & dddS '& _
                                '" AND ra_cac = " & rstC_A_C!cstapKey '& _
                                '" AND ra_period = " & period & ";"
                            Else
                            
                            qdString = "SELECT * FROM ags_ra WHERE ra_num = """ & Rnum & _
                                """ AND ra_date Is Null AND ra_cac = " & rstC_A_C!cstapKey '& _
                                '" AND ra_period = " & period & ";"
                        End If
                        Set rst_ra = db.OpenRecordset(qdString, dbOpenSnapshot)
                        ' имеется ли такой отчёт?
                        If rst_ra.RecordCount > 0 Then
                            ' да, такой отчёт имеется
                            rst_ra.MoveFirst
                            ssss = ssss & " <font color=""green"">найден ОА " & rst_ra!ra_num & _
                                " от " & rst_ra!ra_date & " в бд</font>. ID - " & rst_ra!ra_key & "."
                                
                            ' проверяем прибытие, возврат, отправку и примечания
                            ' очистим от пробелов в окончании и конце, также однообразно заменим Null и пустую строку ""
    
                            ' для представления
                            If arrived = "" Or IsNull(arrived) Then
                                arrived_ = "Пустое значение строки"
                                Else
                                arrived_ = RTrim(LTrim(arrived))
                            End If
                            
                            ' для возвращения
                            If returned = "" Or IsNull(returned) Then
                                returned_ = "Пустое значение строки"
                                Else
                                returned_ = RTrim(LTrim(returned))
                            End If
                            
                            ' для отправки в бухгалтерию
                            If sent = "" Or IsNull(sent) Then
                                sent_ = "Пустое значение строки"
                                Else
                                sent_ = RTrim(LTrim(sent))
                            End If
                            
                            ' для примечаний
                            If note = "" Or IsNull(note) Then
                                note_ = "Пустое значение строки"
                                Else
                                note_ = StringClean(note)
                            End If
                                
                            ' нужно ли добавлять отсутствующие изменения отчётов либо корректировать существующие?
                            If addRa Then
                                ' да, отсутствующие изменения отчётов нужно добавлять либо корректировать существующие
                                ' открываем набор записей для добавления или корректировки
                                Set rst_raCh_add = db.OpenRecordset("ags_ra_change", dbOpenDynaset, dbFailOnError + dbSeeChanges)
                            End If

                                
                            ' отыскиваем собственно изменение
                            dddS = "#" & Month(ChRpDate) & "/" & Day(ChRpDate) & "/" & year(ChRpDate) & "#"
                                
                            qdString = "SELECT * FROM ags_ra_change WHERE (((ags_ra_change.raс_ra)= " & rst_ra!ra_key & ") " & _
                                "AND ((ags_ra_change.raс_date) = " & dddS & ") AND ((ags_ra_change.raс_num) = """ & ChNum & """))"
                                
                            Set rst_raCh = db.OpenRecordset(qdString, dbOpenSnapshot)
                                ' имеется ли изменение?
                                If rst_raCh.RecordCount > 0 Then
                                    ' да, изменение имеется -----------------------------------------------------------------------------------------
                                    rst_raCh.MoveFirst
                                    ssss = ssss & " <font color=""green"">Найдено изм. " & rst_raCh!raс_num & _
                                        " от " & rst_raCh!raс_date & " в бд</font>. ID - " & rst_raCh!rac_key & "."
                                    
                                    stSm = "Про движение:"
                                    
                                    ' для поступления
                                    If rst_raCh!ra_arrived = "" Or IsNull(rst_raCh!ra_arrived) Then
                                        arrived_r = "Пустое значение строки"
                                        Else
                                        arrived_r = RTrim(LTrim(rst_raCh!ra_arrived))
                                    End If
                                    
                                    If arrived_r <> arrived_ Then
                                        stSm = stSm & " <font color=""red"">Не соответствует поступление</font>." & _
                                            " Старое: " & arrived_r & ". Новое: " & arrived_
                                        ' нужно ли корректировать существующие отчёты?
                                        If addRa Then
                                            ' да, нужно корректировать существующие отчёты
                                            rst_raCh_add.FindFirst "rac_key = " & rst_raCh!rac_key
                                            If rst_raCh_add.NoMatch = False Then
                                                rst_raCh_add.Edit
                                                    rst_raCh_add!ra_arrived = RTrim(LTrim(arrived))
                                                    'отыскиваем дату
                                                    If arrived_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(arrived_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            rst_raCh_add!ra_arrived_date = parsedDate
                                                        End If
                                                    End If
                                                rst_raCh_add.Update
                                                stSm = stSm & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                                                Else
                                                stSm = stSm & ". <font color=""red"">Не найден для правки</font>."
                                            End If
                                        End If
                                    End If
                                    
                                    'для возвращения
                                    If rst_raCh!ra_returned = "" Or IsNull(rst_raCh!ra_returned) Then
                                        returned_r = "Пустое значение строки"
                                        Else
                                        returned_r = RTrim(LTrim(rst_raCh!ra_returned))
                                    End If
                                                
                                    If returned_r <> returned_ Then
                                        stSm = stSm & " <font color=""red"">Не соответствует возвращение</font>." & _
                                            " Старое: " & returned_r & ". Новое: " & returned_
                                        ' нужно ли корректировать существующие отчёты?
                                        If addRa Then
                                            ' да, нужно корректировать существующие отчёты
                                            rst_raCh_add.FindFirst "rac_key = " & rst_raCh!rac_key
                                            If rst_raCh_add.NoMatch = False Then
                                                rst_raCh_add.Edit
                                                    rst_raCh_add!ra_returned = RTrim(LTrim(returned))
                                                    'отыскиваем дату
                                                    If returned_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(returned_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            rst_raCh_add!ra_returned_date = parsedDate
                                                        End If
                                                    End If
                                                rst_raCh_add.Update
                                                stSm = stSm & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                                                Else
                                                stSm = stSm & ". <font color=""red"">Не найден для правки</font>."
                                            End If
                                        End If
                                    End If
                                    
                                    'для отправки в бухгалтерию
                                    If rst_raCh!ra_sent = "" Or IsNull(rst_raCh!ra_sent) Then
                                        sent_r = "Пустое значение строки"
                                        Else
                                        sent_r = RTrim(LTrim(rst_raCh!ra_sent))
                                    End If
                                    
                                    If sent_r <> sent_ Then
                                        stSm = stSm & " <font color=""red"">Не соответствует направление в ДБУ</font>." & _
                                            " Старое: " & sent_r & ". Новое: " & sent_
                                        ' нужно ли корректировать существующие отчёты?
                                        If addRa Then
                                            ' да, нужно корректировать существующие отчёты
                                            rst_raCh_add.FindFirst "rac_key = " & rst_raCh!rac_key
                                            If rst_raCh_add.NoMatch = False Then
                                                rst_raCh_add.Edit
                                                    rst_raCh_add!ra_sent = RTrim(LTrim(sent))
                                                    'отыскиваем дату
                                                    If sent_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(sent_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            rst_raCh_add!ra_sent_date = parsedDate
                                                        End If
                                                    End If
                                                rst_raCh_add.Update
                                                stSm = stSm & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                                                Else
                                                stSm = stSm & ". <font color=""red"">Не найден для правки</font>."
                                            End If
                                        End If
                                    End If
                                    
                                    ' для примечаний
                                    If rst_raCh!ra_note = "" Or IsNull(rst_raCh!ra_note) Then
                                        note_r = "Пустое значение строки"
                                        Else
                                        note_r = StringClean(rst_raCh!ra_note)
                                    End If
                                    
                                    ' If note_ <> "Пустое значение строки" And (note_r Like "*" & note_ & "*") = False Then
                                    If note_r <> note_ Then
                                        stSm = stSm & " <font color=""red"">Не соответствует примечание</font>." & _
                                            " Старое: " & note_r & ". Новое: " & note_
                                        ' нужно ли корректировать существующие отчёты?
                                        If addRa Then
                                            ' да, нужно корректировать существующие отчёты
                                            rst_raCh_add.FindFirst "rac_key = " & rst_raCh!rac_key
                                            If rst_raCh_add.NoMatch = False Then
                                                rst_raCh_add.Edit
                                                    rst_raCh_add!ra_note = StringClean(note)
                                                rst_raCh_add.Update
                                                stSm = stSm & ". <B><font color=""SeaGreen"">Обновлено</font></B>."
                                                Else
                                                stSm = stSm & ". <font color=""red"">Не найден для правки</font>."
                                            End If
                                        End If
                                    End If
                                    
                                    If stSm = "Про движение:" Then
                                        stSm = stSm & " <font color=""Blue"">Всё соответствует</font>.</P><P>     "
                                        Else
                                        stSm = stSm & "</P><P>     "
                                    End If
                                    ssss = stSm & ssss
                                        
                                    ' имеются ли суммы в БД?
                                    qdString = "SELECT raсs_raс, raсs_total, raсs_work, raсs_equip, raсs_others, raсs_date " & _
                                        "FROM ags_ra_chSmLt " & _
                                        "WHERE raсs_raс = " & rst_raCh!rac_key & ";"
                                      
                                    stSm = "Про суммы:"
                                    ' имеются ли суммы у изменения в БД?
                                    Set rst_raChSm = db.OpenRecordset(qdString, dbOpenSnapshot)
                                        With rst_raChSm
                                            If .RecordCount > 0 Then
                                                ' да, суммы в БД имеются
                                                .MoveFirst
                                                
                                                bbb = True: bbc = True

                                                ' смотрим всего
                                                bbb = SummCompare(!raсs_total, total, stSm, "Всего")
                                                
                                                ' смотрим СМР
                                                bbc = SummCompare(!raсs_work, work, stSm, "СМР")
                                                If bbb Then
                                                    bbb = bbc
                                                End If
                                                ' смотрим оборудование
                                                bbc = SummCompare(!raсs_equip, equipment, stSm, "Оборудование")
                                                If bbb Then
                                                    bbb = bbc
                                                End If
                                                ' смотрим прочее
                                                bbc = SummCompare(!raсs_others, others, stSm, "Прочее")
                                                If bbb Then
                                                    bbb = bbc
                                                End If
                                                
                                                ' подводим итог по всем суммам, все ли суммы совпадают?
                                                If bbb Then
                                                    ' да, все суммы совпадают
                                                    stSm = stSm & " <font color=""blue"">Все суммы соответствуют</font>."
                                                    Else
                                                    ' нет, не все суммы совпадают
                                                    ' нужно ли корректировать существующие изменения?
                                                    If addRa Then
                                                        ' да, нужно корректировать существующие изменения
                                                        ' добавляем запись сумм
                                                        If AddRaChSum(db, rst_raCh!rac_key, total, work, equipment, others, raCh_summ_NewKey) Then
                                                            ' да, суммы добавились
                                                            stSm = stSm & " <font color=""blue"">Добавлены обновлённые суммы к изм. ID - " & raCh_summ_NewKey & _
                                                            "</font>."
                                                            Else
                                                            ' нет, суммы не добавились
                                                            stSm = stSm & " <font color=""Salmon"">Обновлённые суммы к изм. не добавлены</font>."
                                                        End If
                                                        
'                                                        Set rst_ra_upd_sum = db.OpenRecordset("ags_ra_change_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
'                                                            With rst_ra_upd_sum
'                                                                .AddNew
'                                                                    !raсs_raс = rst_raCh!rac_key
'                                                                    !raсs_date = Now
'                                                                    If Not IsEmpty(total) And IsNumeric(total) Then
'                                                                        !raсs_total = total
'                                                                        Else
'                                                                        !raсs_total = Null
'                                                                    End If
'                                                                    If Not IsEmpty(work) And IsNumeric(work) Then
'                                                                        !raсs_work = work
'                                                                        Else
'                                                                        !raсs_work = Null
'                                                                    End If
'                                                                    If Not IsEmpty(equipment) And IsNumeric(equipment) Then
'                                                                        !raсs_equip = equipment
'                                                                        Else
'                                                                        !raсs_equip = Null
'                                                                    End If
'                                                                    If Not IsEmpty(others) And IsNumeric(others) Then
'                                                                        !raсs_others = others
'                                                                        Else
'                                                                        !raсs_others = Null
'                                                                    End If
'                                                                .Update
'                                                                .Bookmark = .LastModified
'                                                                ra_summ_NewKey = !racs_key
'                                                                .Close
'                                                            End With
'                                                        Set rst_ra_upd_sum = Nothing
'                                                        stSm = stSm & " <font color=""blueviolet"">Добавлены обновлённые суммы к отчёту</font>. " _
'                                                            & "<font color=""silver"">ID - " & ra_summ_NewKey & _
'                                                            "</font>."
                                                    End If
                                                End If
                                                
                                                Else
                                                ' нет, суммы в БД отсутствуют
                                                ' имеются ли суммы в исходном файле?
                                                If Not ( _
                                                    (IsEmpty(total) Or total = 0) _
                                                    And (IsEmpty(work) Or work = 0) _
                                                    And (IsEmpty(equipment) Or equipment = 0) _
                                                    And (IsEmpty(others) Or others = 0) _
                                                    ) Then
                                                    ' да, суммы в исходном файле имеются
                                                    stSm = stSm & _
                                                        " <font color=""DarkRed"">В исходном файле есть суммы, однако в БД суммы отсутствуют!</font>."
                                                    ' нужно ли добавлять суммы?
                                                    If addRa Then
                                                        ' да, суммы добавлять нужно
                                                        If AddRaChSum(db, rst_raCh!rac_key, total, work, equipment, others, raCh_summ_NewKey) Then
                                                            ' да, суммы добавились
                                                            stSm = stSm & " <font color=""blue"">Добавлены суммы к изм. ID - " & raCh_summ_NewKey & _
                                                            "</font>."
                                                            Else
                                                            ' нет, суммы не добавились
                                                            stSm = stSm & " <font color=""Salmon"">Суммы к изм. не добавлены</font>."
                                                        End If
                                                    End If
                                                    Else
                                                    ' нет, суммы в исходном файле отсутствуют
                                                    stSm = stSm & _
                                                        " <font color=""DarkGreen"">В исходном файле нет сумм, и в БД суммы отсутствуют. Это хорошо.</font>."
                                                End If
                                            End If
                                            .Close
                                        End With
                                    Set rst_raChSm = Nothing
                                    
                                    stSm = stSm & "</P><P>     "
                                    ssss = stSm & ssss
                                    ' да, изменение имеется -----------------------------------------------------------------------------------------
                                    Else
                                    ' нет изменение отсутствует -------------------------------------------------------------------------------------
                                    ssss = ssss & ", <font color=""darkred""> Но изменение № " & ChNum & _
                                        " от " & dddS & " к отчёту с ключём " & rst_ra!ra_key & " в БД обнаружить не удалось</font>..."
                                    ' нужно ли добавлять изменение при его отсутствии?
                                    If addRa Then
                                        'да, отсутствующие изменения нужно добавлять
                                        With rst_raCh_add
                                            .AddNew
                                                !raс_ra = rst_ra!ra_key
                                                !raс_num = ChNum
                                                If ChRpDate <> 0 Then
                                                    !raс_date = ChRpDate
                                                End If
                                                !ra_period = period
                                                !ra_note_t = "<P>Создано изм. отчёта - " & ChNum & ". Дата - " & Now & ". При помощи ревизии</P>"
                                                
                                                'заполняем графы поступление и время поступления
                                                If arrived <> "" Then
                                                    !ra_arrived = arrived_
                                                    'отыскиваем дату
                                                    If arrived_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(arrived_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            !ra_arrived_date = parsedDate
                                                        End If
                                                    End If
                                                End If
                                                
                                                'заполняем графы возвращение и время возвращения
                                                If returned <> "" Then
                                                    !ra_returned = returned_
                                                    'отыскиваем дату
                                                    If returned_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(returned_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            !ra_returned_date = parsedDate
                                                        End If
                                                    End If
                                                End If
                                                
                                                'заполняем графы отправлен и время отправления
                                                If sent <> "" Then
                                                    !ra_sent = sent_
                                                    'отыскиваем дату
                                                    If sent_ Like "*##.##.####*" Then
                                                        parsedDate = ParseDate(sent_, False)
                                                        If IsNull(parsedDate) = False Then
                                                            !ra_sent_date = parsedDate
                                                        End If
                                                    End If
                                                End If
                                                
                                                'заполняем графу примечаний
                                                If note <> "" Then
                                                    !ra_note = !ra_note & "<p>" & note_ & ".</p>"
                                                End If
                                                
                                                !ra_created = Now
                                                !ra_org_sender = ra_org_sender
                                            .Update
                                            .Bookmark = .LastModified
                                            raChNewKey = !rac_key
                                            ssss = ssss & " <font color=""orange"">Не найдено изменение " & ChNum & " от " & ChRpDate & _
                                            " в бд</font>. Изм. <font color=""DarkGreen"">добавлено</font>. ID - " & raChNewKey & "."
                                            '.Close
                                        End With
                                        'добавляем суммы
                                        'есть ли в суммах что-то кроме пустоты?
                                        If IsEmpty(total) = False Or IsEmpty(work) = False Or IsEmpty(equipment) = False Or IsEmpty(others) = False Then
                                            'да, в суммах есть что-то кроме пустоты
                                            'добавляем запись суммю Суммы добавились?
                                            If AddRaChSum(db, raChNewKey, total, work, equipment, others, raCh_summ_NewKey) Then
                                                ' да, суммы добавились
                                                ssss = ssss & " <font color=""blue"">Добавлены суммы к изм. ID - " & raCh_summ_NewKey & _
                                                "</font>."
                                                Else
                                                ' нет, суммы не добавились
                                                ssss = ssss & " <font color=""Salmon"">Суммы к изм. не добавлены</font>."
                                            End If
                                            
'                                            Set rst_raCh_add_sum = db.OpenRecordset("ags_ra_change_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
'                                                With rst_raCh_add_sum
'                                                    .AddNew
'                                                        !raсs_raс = raChNewKey
'                                                        !raсs_date = Now
'                                                        If Not IsEmpty(total) And IsNumeric(total) Then
'                                                            !raсs_total = total
'                                                        End If
'                                                        If Not IsEmpty(work) And IsNumeric(work) Then
'                                                            !raсs_work = work
'                                                        End If
'                                                        If Not IsEmpty(equipment) And IsNumeric(equipment) Then
'                                                            !raсs_equip = equipment
'                                                        End If
'                                                        If Not IsEmpty(others) And IsNumeric(others) Then
'                                                            !raсs_others = others
'                                                        End If
'                                                    .Update
'                                                    .Bookmark = .LastModified
'                                                    raCh_summ_NewKey = !raсs_key
'                                                    .Close
'                                                End With
'                                            Set rst_raCh_add_sum = Nothing
'                                            ssss = ssss & " <font color=""blue"">Добавлены суммы к изм. ID - " & raCh_summ_NewKey & _
'                                            "</font>."
                                            Else
                                            'нет, суммы все пусты
                                            ssss = ssss & " <font color=""blue"">Суммы не добавлены, так как пусты</font>."
                                        End If
                                    End If
                                    ' нет изменение отсутствует -------------------------------------------------------------------------------------
                                End If
                               
                                ' закрываем набор для добавления или корректировки изменений к отчётам
                                If Not (rst_raCh_add Is Nothing) Then
                                    rst_raCh_add.Close: Set rst_raCh_add = Nothing
                                End If
                                ' закрываем набор для поиска изменений отчётов
                                rst_raCh.Close: Set rst_raCh = Nothing
                                
                            Else
                            ' нет, такой отчёт отсутствует
                            ssss = ssss & ", <font color=""darkred""> Но отчёт " & Rnum & " в БД обнаружить не удалось</font>..."
                        End If
                        rst_ra.Close: Set rst_ra = Nothing
                        
                        Else
                        ' нет, стройка (САК) в базе данных отсутствует
                        ssss = ssss & ", <font color=""darkred""> Но стройку (САК) в БД обнаружить не удалось</font>..."
                    End If
                    
                    rstC_A_C.Close
                    
                    Else
                    ' нет, номер отчёта не найден
                    ssss = ssss & ", <font color=""darkred""> Но номер отчёта обнаружить не удалось</font>..."
                End If
                Else
                ' нет, дата изменения отсутствует
                ssss = ssss & ", <font color=""darkred""> Но дату изменения обнаружить не удалось</font>..."
            End If
            Else
            ' нет, номер изменения отсутствует
            ssss = ssss & ", <font color=""darkred""> Но номер изменения обнаружить не удалось</font>..."
        End If
        Else
        ' нет, это не изменение
        ssss = ssss & ", <font color=""darkred""> Но это совсем не изменение</font>..."
    End If
    
    fff = "<P>     <font color=""orange"">" & ssss & "</font>.</P>" & fff

NormalExit:
    Set rstC_A_C = Nothing
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

' добавляем суммы к изменениям отчётов агента
Private Function AddRaChSum(ByRef db As DAO.Database, ByVal raChKey As Long, _
    ByVal total As Variant, ByVal work As Variant, ByVal equipment As Variant, ByVal others As Variant, ByRef raChSummNewKey As Long) As Boolean

    Dim rst_raCh_add_sum As DAO.Recordset
    
    Const cstrTitle As String _
        = "Процедура *Добавляем суммы к изменениям отчётов агента*"
    '**************************************************************************************************************************************
On Error GoTo ErrHandler

    AddRaChSum = False

    Set rst_raCh_add_sum = db.OpenRecordset("ags_ra_change_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        With rst_raCh_add_sum
            .AddNew
                !raсs_raс = raChKey
                !raсs_date = Now
                If Not IsEmpty(total) And IsNumeric(total) Then
                    !raсs_total = total
                End If
                If Not IsEmpty(work) And IsNumeric(work) Then
                    !raсs_work = work
                End If
                If Not IsEmpty(equipment) And IsNumeric(equipment) Then
                    !raсs_equip = equipment
                End If
                If Not IsEmpty(others) And IsNumeric(others) Then
                    !raсs_others = others
                End If
            .Update
            .Bookmark = .LastModified
            raChSummNewKey = !raсs_key
            .Close
        End With
    Set rst_raCh_add_sum = Nothing
    
    AddRaChSum = True
    
NormalExit:
    Set rstC_A_C = Nothing
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Function

'Public Function WorksheetIsExist(xlW As Excel.Workbook, WorkSheetName As String) As Boolean
'On Error Resume Next
'    WorksheetIsExist = (TypeOf xlW.Worksheets(WorkSheetName) Is Worksheet)
'End Function

' получаем дату из строки, Start - давать самую раннюю дату, иначе - самую позднюю
' CountDates - показывает сколько дат в строке
Function ParseDate(ByVal Text As String, Start As Boolean, _
    Optional ByRef ErrDescr As String, Optional ByRef CountDates As Integer) As Variant

    ' для разных дат
    Dim Match As Object, RegExp As Object, d As Date, di As Date, strReg As String, strTemp As String
    
    Const cstrTitle As String _
        = "Процедура *Получаем дату из строки*"
    '**************************************************************************************************************************************
On Error GoTo ErrHandler

    ' для начала установим возвращаемую величину в Null
    ParseDate = Null: ErrDescr = "": CountDates = 0
    
    ' очистим строку
    strTemp = StringClean(Text)
    
    ' ищем разные даты
    Set RegExp = CreateObject("VBScript.RegExp")
    ' определяем шаблон регулярного выражения
    RealQ = Chr(34)
    strReg = "((\d{2}\.\d{2}\.(\d{2}(\D|$)|\d{4}))" & _
        "|(\d{2}|" & RealQ & "\d{2}" & RealQ & ") " & _
        "((я|Я)нваря|(ф|Ф)евраля|(м|М)арта|(а|А)преля|(м|М)ая|(и|И)юня|(и|И)юля|(а|А)вгуста|(с|С)ентября|(о|О)ктября|(н|Н)оября|(д|Д)екабря) \d{4})"
    ' присваиваем шаблон регулярного выражения
    RegExp.Pattern = strReg
    ' устанавливаем поиск всех совпадений в строке вместо поиска первого совпадения
    RegExp.Global = True
    Set Match = RegExp.Execute(strTemp)
    If Match.count > 0 Then
        CountDates = Match.count
        If Start Then
            ' самая ранняя
            For i = 0 To Match.count - 1
                ' убираем кавычки, если они есть
                strTemp = Replace(Match(i).value, RealQ, "")
                ' дата вида 02.02.20 будет иметь на хвосте лишний знак. Ну пробел, конец строки, запятую или ещё чего. Нужно убрать
                If Len(strTemp) = 9 Then
                    strTemp = Left(strTemp, 8)
                End If
                di = CDate(strTemp)
                If di < d Or d = 0 Then
                    d = di
                End If
            Next
            Else
            'самая поздняя
            For i = 0 To Match.count - 1
                ' убираем кавычки, если они есть
                strTemp = Replace(Match(i).value, RealQ, "")
                ' дата вида 02.02.20 будет иметь на хвосте лишний знак. Ну пробел, конец строки, запятую или ещё чего. Нужно убрать
                If Len(strTemp) = 9 Then
                    strTemp = Left(strTemp, 8)
                End If
                di = CDate(strTemp)
                If di > d Then
                    d = di
                End If
            Next
        End If
    End If
    
    'ну и возвращаем величину
    If d > 0 Then
        ParseDate = d
    End If
        
NormalExit:
    Exit Function
    
ErrHandler:
    ErrDescr = strTemp & ", " & "№ ошибки: " & Err.Number & ", " & Err.Description
    'MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Function

'' очищаем строку
'Function StringClean(ByVal Text As String) As String
'
'    Dim strTemp As String
'
'    If Text = "" Then
'        StringClean = ""
'        Else
'        ' очистим строку
'        strTemp = Replace(Text, vbCr, " ")
'        strTemp = Replace(strTemp, vbLf, " ")
'        strTemp = Replace(strTemp, vbTab, " ")
'        strTemp = Replace(strTemp, vbVerticalTab, " ")
'        strTemp = Replace(strTemp, vbBack, " ")
'        strTemp = Replace(strTemp, vbNullChar, " ")
'        While InStr(strTemp, "  ") > 0
'            strTemp = Replace(strTemp, "  ", " ")
'        Wend
'        strTemp = Trim(strTemp)
'        If strTemp = " " Then
'            strTemp = ""
'        End If
'        StringClean = strTemp
'    End If
'
'End Function

' отыскиваем сводные значения на листе
Private Sub TotalValuesFind(WSheetType As String, xlS As Excel.Worksheet, period As Integer, addRa As Boolean, _
    fff As Object, db As DAO.Database, ra_org_sender As Long, raColumn As Integer)
    
    Dim c As Range
    Dim raArrived As Integer, raSended As Integer, raReturned As Integer, raInProcess As Integer, raWithWork As Integer
    Dim rst_Ttl As DAO.Recordset
    Dim rowTtl As String, rowSwod As String, rg As Excel.Range
    ' для ВСЕГО
    Dim mTtl As Currency, mWork As Currency, mEquip As Currency, mOthers As Currency
    ' для Учёта затрат
    Dim aTtl As Currency, aWork As Currency, aEquip As Currency, aOthers As Currency
    ' для разницы учёта и ВСЕГО
    Dim dTtl As Currency, dWork As Currency, dEquip As Currency, dOthers As Currency
    
    Dim qdf As DAO.QueryDef, sqlStr As String, iii As Integer
    Dim rs As DAO.Recordset

    Const cstrTitle As String _
        = "Процедура *Отыскиваем сводные значения на листе*"
    '**************************************************************************************************************************************
On Error GoTo ErrHandler

    ' обрабатываем лист периода -----------------------------------------------------------------------------------------------------------
    If WSheetType = "wsPeriod" Then
    
        ' отыскиваем строку "Всего отчетов"
        Set c = xlS.UsedRange.Find(what:="Всего отчетов", LookAt:=xlPart)
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Представлено отчетов агента", LookAt:=xlPart)
        End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            raArrived = c.Offset(0, 1).value
            'fff = "<P> Найдена ячейка *Поступило* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>, всего их " & raArrived & ".</P>" & fff
            Else
            fff = "<P> Ячейка *Поступило* <font color=""red"">не найдена</font></P>" & fff
            ra_changes_first_row = 0
        End If

        ' отыскиваем строку "направлено в СБУ"
        Set c = xlS.UsedRange.Find(what:="направлено в СБУ", LookAt:=xlPart)
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="направленно в СБУ", LookAt:=xlPart)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="направлено в CБУ", LookAt:=xlPart)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="направленно в CБУ", LookAt:=xlPart)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="направленно в ДБУ", LookAt:=xlPart)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="направлено в ДБУ", LookAt:=xlPart)
        End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            raSended = c.Offset(0, 1).value
            'fff = "<P> Найдена ячейка *Направлено* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>, всего их " & raSended & ".</P>" & fff
            Else
            fff = "<P> Ячейка *Направлено* <font color=""red"">не найдена</font></P>" & fff
            ra_changes_first_row = 0
        End If

        ' отыскиваем строку "вернули на доработку"
        Set c = xlS.UsedRange.Find(what:="вернули на доработку", LookAt:=xlPart)
        ' посмотрим ещё
        'If c Is Nothing Then
        '    Set c = xlS.UsedRange.Find(What:="Представлено отчетов агента", LookAt:=xlPart)
        'End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            raReturned = c.Offset(0, 1).value
            'fff = "<P> Найдена ячейка *Возвращено* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>, всего их " & raReturned & ".</P>" & fff
            Else
            fff = "<P> Ячейка *Возвращено* <font color=""red"">не найдена</font></P>" & fff
            ra_changes_first_row = 0
        End If

        ' отыскиваем строку "на проверке"
        Set c = xlS.UsedRange.Find(what:="на проверке", LookAt:=xlPart)
        ' посмотрим ещё
        'If c Is Nothing Then
        '    Set c = xlS.UsedRange.Find(What:="Представлено отчетов агента", LookAt:=xlPart)
        'End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            raInProcess = c.Offset(0, 1).value
            'fff = "<P> Найдена ячейка *На проверке* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>, всего их " & raInProcess & ".</P>" & fff
            Else
            fff = "<P> Ячейка *На проверке* <font color=""red"">не найдена</font></P>" & fff
        End If
        
        ' отыскиваем строку "Отчеты с СМР"
        Set c = xlS.UsedRange.Find(what:="ОА с СМР", LookAt:=xlPart)
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="отчетов с СМР", LookAt:=xlPart)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Отчеты с СМР", LookAt:=xlPart)
        End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            raWithWork = c.Offset(0, 1).value
            'fff = "<P> Найдена ячейка *ОА с СМР* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>, всего их " & raWithWork & ".</P>" & fff
            Else
            fff = "<P> Ячейка *ОА с СМР* <font color=""red"">не найдена</font></P>" & fff
        End If
        
        ' отыскиваем строку "ВСЕГО"Всего:

        Set c = xlS.UsedRange.Find(what:="ВСЕГО", LookAt:=xlWhole)
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Всего:", LookAt:=xlWhole)
        End If
        ' посмотрим ещё
        If c Is Nothing Then
            Set c = xlS.UsedRange.Find(what:="Всего:", LookAt:=xlWhole)
        End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            rowTtl = c.Row
            Set rg = xlS.Cells(rowTtl, raColumn)
            'fff = "<P> Найдена ячейка *ВСЕГО* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>.</P>" & fff
            ' копируем значения сумм ВСЕГО
            If IsNumeric(rg.Offset(0, 2)) Then
                mTtl = rg.Offset(0, 2)
            End If
            If IsNumeric(rg.Offset(0, 3)) Then
                mWork = rg.Offset(0, 3)
            End If
            If IsNumeric(rg.Offset(0, 4)) Then
                mEquip = rg.Offset(0, 4)
            End If
            If IsNumeric(rg.Offset(0, 5)) Then
                mOthers = rg.Offset(0, 5)
            End If
            Else
            fff = "<P> Ячейка *ВСЕГО* <font color=""red"">не найдена</font></P>" & fff
        End If
        
        
        ' отыскиваем строку "Учет затрат для свода"
        Set c = xlS.UsedRange.Find(what:="Учет затрат для свода", LookAt:=xlPart)
        ' посмотрим ещё
        'If c Is Nothing Then
        '    Set c = xlS.UsedRange.Find(What:="Представлено отчетов агента", LookAt:=xlPart)
        'End If
        
        ' итог поисков строки
        If Not c Is Nothing Then
            rowSwod = c.Row
            Set rg = xlS.Cells(rowSwod + 1, raColumn)
            'fff = "<P> Найдена ячейка *Учет затрат для свода* колонка - " & c.Column & ", строка - " & c.Row & "." _
            '    & " Содержание: <font color=""Teal"">" & c & "</font>.</P>" & fff
            If IsNumeric(rg.Offset(0, 2)) Then
                aTtl = rg.Offset(0, 2)
            End If
            If IsNumeric(rg.Offset(0, 3)) Then
                aWork = rg.Offset(0, 3)
            End If
            If IsNumeric(rg.Offset(0, 4)) Then
                aEquip = rg.Offset(0, 4)
            End If
            If IsNumeric(rg.Offset(0, 5)) Then
                aOthers = rg.Offset(0, 5)
            End If
            ' ну и строчку выше
            Set rg = xlS.Cells(rowSwod, raColumn)
            If IsNumeric(rg.Offset(0, 2)) Then
                dTtl = rg.Offset(0, 2)
            End If
            If IsNumeric(rg.Offset(0, 3)) Then
                dWork = rg.Offset(0, 3)
            End If
            If IsNumeric(rg.Offset(0, 4)) Then
                dEquip = rg.Offset(0, 4)
            End If
            If IsNumeric(rg.Offset(0, 5)) Then
                dOthers = rg.Offset(0, 5)
            End If
            Else
            fff = "<P> Ячейка *Учет затрат для свода* <font color=""red"">не найдена</font></P>" & fff
        End If
        
        ' определим теперь данные из БД
        Set qdf = db.QueryDefs("ags_PdSdRRcList")
                
            sqlStr = "select " & _
                    "x.ra_period, x.ra_org_sender, x.arrived arrivedCount, x.returned returnedCount, x.[sent] sentCount, x.arrived - x.returned - x.[sent] inProcessCount " & _
                    ", y.workCount " & _
                    ", y.mTotalSum, y.mWorkSum, y.mEquipSum, y.mOthersSum " & _
                    ", z.aTotalSum, z.aWorkSum, z.aEquipSum, z.aOthersSum " & _
                    ", c.cTotalSum, c.cWorkSum, c.cEquipSum, c.cOthersSum " & _
                    ", isnull(z.aTotalSum, 0) - isnull(y.mTotalSum, 0) - isnull(c.cTotalSum, 0) dTotalSum " & _
                    ", isnull(z.aWorkSum, 0) - isnull(y.mWorkSum, 0) - isnull(c.cWorkSum, 0) dWorkSum " & _
                    ", isnull(z.aEquipSum, 0) - isnull(y.mEquipSum, 0) - isnull(c.cEquipSum, 0) dEquipSum " & _
                    ", isnull(z.aOthersSum, 0) - isnull(y.mOthersSum, 0) - isnull(c.cOthersSum, 0) dOthersSum " & _
                "from " & _
                    "( " & _
                        "SELECT " & _
                            "l.ra_period , l.ra_org_sender " & _
                            ", count(l.ra_arrived) arrived, count(l.ra_returned) returned, count(l.ra_sent) sent " & _
                        "from " & _
                            "ags.RRcList l " & _
                        "where " & _
                            "l.ra_period = " & period & " And l.ra_org_sender = " & ra_org_sender & " " & _
                        "Group by " & _
                            "l.ra_period , l.ra_org_sender " & _
                    ") x "
                    
            'sqlStr = sqlStr & "Left Join " & _
            '            "( " & _
            '                "select " & _
            '                    "t.ra_period, t.ra_org_sender, count(t.ras_work) workCount " & _
            '                "from " & _
            '                    "ags.RRcList t " & _
            '                "where " & _
            '                    "t.ra_period = " & period & " and t.ra_org_sender = " & ra_org_sender & " " & _
            '                "Group by " & _
            '                    "t.ra_period , t.ra_org_sender " & _
            '            ") u " & _
            '            "on x.ra_org_sender = u.ra_org_sender and x.ra_period = u.ra_period "
            
            ' здесь добавляем количество простых отчётов агента, имеющих СМР, и суммы по ним
            sqlStr = sqlStr & "Left Join " & _
                        "( " & _
                            "select " & _
                                "t.ra_period, t.ra_org_sender, count(t.ras_work) workCount " & _
                                ", sum(t.ras_total) mTotalSum, sum(t.ras_work) mWorkSum, sum(t.ras_equip) mEquipSum, sum(t.ras_others) mOthersSum " & _
                            "from " & _
                                "ags.RRcList t " & _
                            "where " & _
                                "t.[type] = 'отчёт' and t.ra_type = 'ОА' and t.ra_period = " & period & " and t.ra_org_sender = " & ra_org_sender & " " & _
                            "Group by " & _
                                "t.ra_period , t.ra_org_sender " & _
                        ") y " & _
                        "on x.ra_org_sender = y.ra_org_sender and x.ra_period = y.ra_period "
                        
            ' здесь добавляем общие суммы по принятым ОА и Изм.
            sqlStr = sqlStr & "Left Join " & _
                        "( " & _
                            "select " & _
                                "t.ra_period , t.ra_org_sender " & _
                                ", sum(t.ras_total) aTotalSum, sum(t.ras_work) aWorkSum, sum(t.ras_equip) aEquipSum, sum(t.ras_others) aOthersSum " & _
                            "from " & _
                                "ags.RRcList t " & _
                            "where " & _
                                "((t.[type] = 'отчёт' and t.ra_type = 'ОА') or (t.[type] = 'изм.')) and not t.ra_sent is null and t.ra_period = " & period & " and t.ra_org_sender = " & ra_org_sender & " " & _
                            "Group by " & _
                                "t.ra_period , t.ra_org_sender " & _
                        ") z " & _
                        "on x.ra_org_sender = z.ra_org_sender and x.ra_period = z.ra_period "
            
            sqlStr = sqlStr & "Left Join " & _
                        "( " & _
                            "select " & _
                                "t.ra_period , t.ra_org_sender " & _
                                ", sum(t.ras_total) cTotalSum, sum(t.ras_work) cWorkSum, sum(t.ras_equip) cEquipSum, sum(t.ras_others) cOthersSum " & _
                            "from " & _
                                "ags.RRcList t " & _
                            "where " & _
                                "t.[type] = 'изм.' and t.ra_period = " & period & " and t.ra_org_sender = " & ra_org_sender & " " & _
                            "Group by " & _
                                "t.ra_period , t.ra_org_sender " & _
                        ") c " & _
                        "on x.ra_org_sender = c.ra_org_sender and x.ra_period = c.ra_period"

            qdf.SQL = sqlStr
                
        iii = 0
        
        Set rs = qdf.OpenRecordset()
        If rs.EOF = False Then
            rs.MoveLast
            iii = rs.RecordCount
            rs.MoveFirst
        End If
            
        ' добавляем данные в таблицу
        Set rst_Ttl = db.OpenRecordset("ra_aTtl", dbOpenDynaset, dbFailOnError + dbSeeChanges)
            With rst_Ttl
                .AddNew
                
                    !ratSender = ra_org_sender: !ratPeriod = period
                    
                    ' добавляем количества отчётов
                    If Not IsEmpty(raArrived) And IsNumeric(raArrived) Then
                        !ratArrived = raArrived
                    End If
                    If Not IsEmpty(raReturned) And IsNumeric(raReturned) Then
                        !ratReturned = raReturned
                    End If
                    If Not IsEmpty(raSended) And IsNumeric(raSended) Then
                        !ratSended = raSended
                    End If
                    If Not IsEmpty(raInProcess) And IsNumeric(raInProcess) Then
                        !ratInProcess = raInProcess
                    End If
                    If Not IsEmpty(raWithWork) And IsNumeric(raWithWork) Then
                        !ratWithWork = raWithWork
                    End If
                    
                    ' добавляем суммы ВСЕГО
                    If Not IsEmpty(mTtl) And IsNumeric(mTtl) Then
                        !mTtl = mTtl
                    End If
                    If Not IsEmpty(mWork) And IsNumeric(mWork) Then
                        !mWork = mWork
                    End If
                    If Not IsEmpty(mEquip) And IsNumeric(mEquip) Then
                        !mEquip = mEquip
                    End If
                    If Not IsEmpty(mOthers) And IsNumeric(mOthers) Then
                        !mOthers = mOthers
                    End If
                    
                    ' добавляем суммы учёта
                    If Not IsEmpty(aTtl) And IsNumeric(aTtl) Then
                        !aTtl = aTtl
                    End If
                    If Not IsEmpty(aWork) And IsNumeric(aWork) Then
                        !aWork = aWork
                    End If
                    If Not IsEmpty(aEquip) And IsNumeric(aEquip) Then
                        !aEquip = aEquip
                    End If
                    If Not IsEmpty(aOthers) And IsNumeric(aOthers) Then
                        !aOthers = aOthers
                    End If
                    
                    ' добавляем суммы разницы ВСЕГО и учёта
                    If Not IsEmpty(dTtl) And IsNumeric(dTtl) Then
                        !dTtl = dTtl
                    End If
                    If Not IsEmpty(dWork) And IsNumeric(dWork) Then
                        !dWork = dWork
                    End If
                    If Not IsEmpty(dEquip) And IsNumeric(dEquip) Then
                        !dEquip = dEquip
                    End If
                    If Not IsEmpty(dOthers) And IsNumeric(dOthers) Then
                        !dOthers = dOthers
                    End If
                    
                    If iii > 0 Then
                        ' добавляем количества отчётов
                        If Not IsEmpty(rs!arrivedCount) And IsNumeric(rs!arrivedCount) Then
                            !ratArrivedDB = rs!arrivedCount
                        End If
                        If Not IsEmpty(rs!returnedCount) And IsNumeric(rs!returnedCount) Then
                            !ratReturnedDB = rs!returnedCount
                        End If
                        If Not IsEmpty(rs!sentCount) And IsNumeric(rs!sentCount) Then
                            !ratSendedDB = rs!sentCount
                        End If
                        If Not IsEmpty(rs!inProcessCount) And IsNumeric(rs!inProcessCount) Then
                            !ratInProcessDB = rs!inProcessCount
                        End If
                        If Not IsEmpty(rs!workCount) And IsNumeric(rs!workCount) Then
                            !ratWithWorkDB = rs!workCount
                        End If
                        
                        ' добавляем суммы ВСЕГО
                        If Not IsEmpty(rs!mTotalSum) And IsNumeric(rs!mTotalSum) Then
                            !mTtlDB = rs!mTotalSum
                        End If
                        If Not IsEmpty(rs!mWorkSum) And IsNumeric(rs!mWorkSum) Then
                            !mWorkDB = rs!mWorkSum
                        End If
                        If Not IsEmpty(rs!mEquipSum) And IsNumeric(rs!mEquipSum) Then
                            !mEquipDB = rs!mEquipSum
                        End If
                        If Not IsEmpty(rs!mOthersSum) And IsNumeric(rs!mOthersSum) Then
                            !mOthersDB = rs!mOthersSum
                        End If
                        
                        ' добавляем суммы учёта
                        If Not IsEmpty(rs!aTotalSum) And IsNumeric(rs!aTotalSum) Then
                            !aTtlDB = rs!aTotalSum
                        End If
                        If Not IsEmpty(rs!aWorkSum) And IsNumeric(rs!aWorkSum) Then
                            !aWorkDB = rs!aWorkSum
                        End If
                        If Not IsEmpty(rs!aEquipSum) And IsNumeric(rs!aEquipSum) Then
                            !aEquipDB = rs!aEquipSum
                        End If
                        If Not IsEmpty(rs!aOthersSum) And IsNumeric(rs!aOthersSum) Then
                            !aOthersDB = rs!aOthersSum
                        End If
                        
                        ' добавляем суммы разницы ВСЕГО и учёта
                        If Not IsEmpty(rs!dTotalSum) And IsNumeric(rs!dTotalSum) Then
                            !dTtlDB = rs!dTotalSum
                        End If
                        If Not IsEmpty(rs!dWorkSum) And IsNumeric(rs!dWorkSum) Then
                            !dWorkDB = rs!dWorkSum
                        End If
                        If Not IsEmpty(rs!dEquipSum) And IsNumeric(rs!dEquipSum) Then
                            !dEquipDB = rs!dEquipSum
                        End If
                        If Not IsEmpty(rs!dOthersSum) And IsNumeric(rs!dOthersSum) Then
                            !dOthersDB = rs!dOthersSum
                        End If
                    End If
                    
                .Update
                .Bookmark = .LastModified
                'raCh_summ_NewKey = !raсs_key
                .Close
            End With
        Set rst_Ttl = Nothing
        
        rs.Close
        qdf.Close
        Set qdf = Nothing
        
    ' обрабатываем лист периода -----------------------------------------------------------------------------------------------------------
    End If

NormalExit:
    Exit Sub
    
ErrHandler:
    'ErrDescr = strTemp & ", " & "№ ошибки: " & Err.Number & ", " & Err.Description
    MsgBox Err.Description & vbCrLf & "№ ошибки: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit

End Sub

