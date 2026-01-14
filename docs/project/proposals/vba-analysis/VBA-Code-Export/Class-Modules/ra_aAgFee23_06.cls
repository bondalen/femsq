VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ra_aAgFee23_06"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' класс *Ревизия ОА. Проверка файла Актов агентского вознаграждения* (образца от 27.06.2023). 28.06.2023

' ###################################################################################################################################################
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' !!! не нужно их писать в других местах, это приведет к ошибке. 07.07.2022
' Ключ объекта *Ревизия ОА. Проверка файла Актов агентского вознаграждения*
Private mlngRa_aAgFee23_06Key As Long
' база данных
Private mdbDb As DAO.Database
' вышестоящий класс *Ревизия отчётов агента*
Private mobjParent As ra_a
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' область определения закрытых пременных, содержащих значения свойств
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
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' ---------------------------------------------------------------------------------------------------------------------------------------------------
Const cstrTable As String = "ra_f", cstrTableKeyField As String = "af_key"
Const cstrTableTypeField As String = "af_type" ' поле определяющее тип объекта, чтобы понять, что объект соответствует классу настоящего файла
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' ###################################################################################################################################################

' ###################################################################################################################################################
' геттеры и сеттеры (леттеры) свойств
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' свойство ~Ключ объекта *Ревизия ОА. Проверка файла Актов агентского вознаграждения*~. 29.06.2023
' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства ~Ключ объекта *Ревизия ОА. Проверка файла Актов агентского вознаграждения*~
Public Property Get Ra_aAgFee23_06Key() As Long
    Ra_aAgFee23_06Key = mlngRa_aAgFee23_06Key
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' свойство ~Ключ объекта *Ревизия ОА. Проверка файла Актов агентского вознаграждения*~. 29.06.2023. Окончание
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' свойство *Ревизия отчётов агента*. 29.06.2023
' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' сеттер свойства вышестоящий класс *Ревизия отчётов агента*
Public Property Set parent(ByRef objParent As ra_a)
    If mobjParent Is Nothing Then
        Set mobjParent = objParent
    End If
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' свойство *Ревизия отчётов агента*. 29.06.2023. Окончание
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' геттеры и сеттеры (леттеры) свойств. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' инициализации и реинициализации
' ***************************************************************************************************************************************************
' обработка встроенного события инициализации
Private Sub Class_Initialize()
    ' инициализируем объект с нулевым ключём. В таком виде он не имеет смысла.
    ' Требуется реинициализация.
    mlngRa_aAgFee23_06Key = -1
End Sub
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' реинициализируем объект *Ревизия ОА. Проверка файла Актов агентского вознаграждения* по известному ключу такого объекта. 29.06.2023
' ...................................................................................................................................................
Public Sub riByKey(ByVal Ra_aAgFee23_06Key As Long, ByRef boResult As Boolean, ByRef db As DAO.Database)
    ' ...............................................................................................................................................
    Dim rs As DAO.Recordset, strSql As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект *Ревизия ОА. Проверка файла Актов агентского вознаграждения* по известному ключу такого объекта*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' ключ объекта равен -1? То есть реинициализация ранее не проводилась
    If mlngRa_aAgFee23_06Key = -1 Then
        ' да,ключ объекта равен -1
        ' отыскиваем объект по известному ключу
        strSql = "SELECT * FROM " & cstrTable & " WHERE " & cstrTableKeyField & " = " & Ra_aAgFee23_06Key & ";"
        Set rs = db.OpenRecordset(strSql, dbOpenSnapshot)
        
        ' имеются ли записи с указанным ключём?
        If rs.RecordCount = 1 Then
            ' да, записи с указанным ключём имеются
            ' соответствует ли запись в таблице классу настоящего файла
            If rs.Fields(cstrTableTypeField) = 6 Then
                ' да, запись в таблице соответствует классу настоящего файла
                mlngRa_aAgFee23_06Key = Ra_aAgFee23_06Key
                Set mdbDb = db ' устанавливаем ссылку на базу данных
                rs.MoveFirst
                    mlngAf_num = rs!af_num
                    mstrAf_name = rs!af_name
                    mlngAf_dir = rs!af_dir
                    mlngAf_type = rs!af_type
                    mlngRa_org_sender = rs!ra_org_sender
                    mblnAf_execute = rs!af_execute
                    mblnAf_source = rs!af_source

                boResult = True ' результат положительный
            Else
                ' нет, запись в таблице не соответствует классу настоящего файла
                mlngRa_aAgFee23_06Key = 0
                boResult = False ' результат отрицательный
            End If
        Else
            ' нет, записи с указанным ключём отсутствуют
            mlngRa_aAgFee23_06Key = 0
            boResult = False
        End If
    Else
        ' да,ключ объекта не равен -1
        ' ключ объекта равен 0?
        If mlngRa_aAgFee23_06Key = 0 Then
            ' да, ключ объекта равен 0. Ранее он безуспешно реинициализировался
            boResult = False
        Else
            ' нет, ключ объекта не равен 0. Ранее он успешно реинициализировался
            boResult = True
        End If
    End If
    
    ' закрываем набор записей
    rs.Close: Set rs = Nothing
    
NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' ...................................................................................................................................................
' реинициализируем объект *Ревизия ОА. Проверка файла Актов агентского вознаграждения* по известному ключу такого объекта. 29.06.2023. Окончание
' ***************************************************************************************************************************************************
' инициализации и реинициализации. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' чтение полей и запись в них

' чтение полей и запись в них. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' методы
' ***************************************************************************************************************************************************
' работаем с листом Актов по агентскому вознаграждению всех агентов. 28.06.2023
Public Sub Audit( _
    xlS As Excel.Worksheet, db As DAO.Database, xlA As Object _
    )
    ' здесь:
    ' xlS - лист, с которым работаем, AddRA - потребность в корректировке БД, fff - объект отображающий записи о ходе ревизии
    ' db - база данных, открытая,
    ' AdtKey - идентификатор текущей ревизии, yyyy - год текущей ревизии, xlA - приложение эксель
    ' ...............................................................................................................................................
    Dim rsAgentNo As DAO.Recordset, qdf As DAO.QueryDef, strTest As String, ogAgFeeCurrent As ogAgFee, ogAgFeePnCurrent As ogAgFeePn
    Dim cellResault As Range
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Работаем с листом Актов по агентскому вознаграждению всех агентов*. ClassModule: ra_aAgFee23_06, Sub: Audit"
' ---------------------------------------------------------------------------------------------------------------------------------------------------
    
On Error GoTo ErrHandler

'MsgBox ("Работаем с листом Отчётов всех агентов")

    ' нужно ли обновлять промежуточную таблицу по источнику данных?
    If mblnAf_source Then
        ' да, обновлять промежуточную таблицу по источнику данных нужно
        AuditFillFromSource xlS, db, xlA
    Else
        ' нет, обновлять промежуточную таблицу по источнику данных не нужно
    End If
    
    ' проверяем, что каждому отправителю соответствует только один ключ
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestAgentNo"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "Отсутствуют отправители: "
        Do Until rsAgentNo.EOF
            strTest = strTest & " <font color=""Crimson"">" & rsAgentNo!oafptOafSender & "</font>;"
            rsAgentNo.MoveNext
        Loop
    Else
        strTest = "Все отправители идентифицированы."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    
    ' вносим ключ отправителя в промежуточную таблицу
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "exec ags.ogAgFeePnTestAgentKey"
    qdf.ReturnsRecords = False  ''avoid 3065 error
    qdf.Execute dbFailOnError
    mobjParent.obgRa_aResult = "<P>Ключ отправителя внесен в промежуточную таблицу.</P>" & mobjParent.obgRa_aResult
    qdf.Close: Set qdf = Nothing

    ' работаем с Актами по агентскому вознаграждению отсутствующими в источнике
    ' проверяем наличие актов в БД отсутствующих в источнике
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.fnOgAgFeePnTestActDbOnly(" & mobjParent.year(mdbDb) & ") f"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "Акты отсутствующие в источнике: "
        Do Until rsAgentNo.EOF
            strTest = strTest & " <font color=""Crimson"">" & rsAgentNo!oafNum & " от " & rsAgentNo!oafDate & "</font>;"
            rsAgentNo.MoveNext
        Loop
        ' нужно ли обновлять базу данных
        If mobjParent.blnAdt_AddRA Then
            ' да, обновлять базу данных нужно
            ' удаляем Акты по агентскому вознаграждению отсутствующие в источнике
            qdf.Close: Set qdf = Nothing
            Set qdf = db.CreateQueryDef("")
            qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
            qdf.SQL = "exec ags.ogAgFeePnTestActDbOnlyDel " & mobjParent.year(mdbDb)
            qdf.ReturnsRecords = False  ''avoid 3065 error
            qdf.Execute dbFailOnError
            strTest = strTest & "<P>Акты по агентскому вознаграждению отсутствующие в источнике удалены.</P>"
            qdf.Close: Set qdf = Nothing
        End If
    Else
        strTest = "Актов, отсутствующих в источнике, нет."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    ' работаем с Актами по агентскому вознаграждению отсутствующими в источнике. Окончание
    
    ' работаем с Актами по агентскому вознаграждению отсутствующими в базе данных
    ' проверяем наличие Актов в отсутствующих в базе данных
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestActNew order by ogaNm, oafptOafDate, oafptOafName"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "<P>Акты отсутствующие в базе данных: </P>"
        Do Until rsAgentNo.EOF
            strTest = strTest & "<P> " & " <font color=""Crimson"">" & rsAgentNo!oafptOafName & " от " & rsAgentNo!oafptOafDate _
                & "</font> " & rsAgentNo!ogaNm & ";" & "</P>"
            rsAgentNo.MoveNext
        Loop
        ' нужно ли обновлять базу данных
        If mobjParent.blnAdt_AddRA Then
            ' да, обновлять базу данных нужно
            ' добавляем Акты по агентскому вознаграждению отсутствующие в базе данных
            qdf.Close: Set qdf = Nothing
            Set qdf = db.CreateQueryDef("")
            qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
            qdf.SQL = "exec ags.ogAgFeePnTestActAdd"
            qdf.ReturnsRecords = False  ''avoid 3065 error
            qdf.Execute dbFailOnError
            strTest = strTest & "<P>Акты по агентскому вознаграждению отсутствующие в базе данных добавлены.</P>"
            qdf.Close: Set qdf = Nothing
        End If
    Else
        strTest = "Актов, отсутствующих в базе данных, нет."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    ' работаем с Актами по агентскому вознаграждению отсутствующими в базе данных. Окончание
    
    ' проверяем отсутствие задвоения атрибутов у Актов по агентскому вознаграждениюв источнике
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestActAttr"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "Имеются разночтения в значениях атрибутов у Актов в источнике:"
        Do Until rsAgentNo.EOF
            strTest = strTest & " <font color=""Crimson"">" & rsAgentNo!oafNum & " от " _
                & rsAgentNo!oafDate & "</font> " & rsAgentNo!ogaNm & ";"
            rsAgentNo.MoveNext
        Loop
    Else
        strTest = "Разночтений в атрибутах у актов в источнике не обнаружено."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    
    ' проверяем отсутствие задвоения атрибутов у Актов по агентскому вознаграждениюв источнике. Окончание

    ' работаем с Актами по агентскому вознаграждению на предмет соответствия атрибутов в БД и источнике
    ' проверяем соответствие атрибутов в БД и источнике
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestActAttrTrue order by ogaNm, oafNum"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "<P>Акты имеющие несоответствия в атрибутах: </P>"
        i = 1
        ' проходим по каждому Акту имеющему несоответствия в атрибутах
        Do Until rsAgentNo.EOF ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            strTest = strTest & "<P> " & i & ". <b><font color=""Chocolate"">" & rsAgentNo!oafNum & " от " & rsAgentNo!oafDate _
                & "</font></b> " & rsAgentNo!ogaNm & ";" & "</P>"
            ' нужно ли обновлять базу данных?
            If mobjParent.blnAdt_AddRA Then
                ' да, базу обновлять нужно. Создаём объект для обновления ***************
                Set ogAgFeeCurrent = ClassFactory.ogAgFeeByKey(rsAgentNo!oafKey, mdbDb)
                ' ***********************************************************************
            End If
            ' Поступило
            If rsAgentNo!ArrivedNumTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strArrived = rsAgentNo!ArrivedNumExc
                    strTest = strTest & "<P>     Поступило: БД: <font color=""Crimson"">" & rsAgentNo!ArrivedNumBd & "</font>, ист: <font color=""DarkGreen"">" _
                        & rsAgentNo!ArrivedNumExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Поступило: БД: <font color=""Crimson"">" & rsAgentNo!ArrivedNumBd & "</font>, ист: <font color=""DarkGreen"">" _
                        & rsAgentNo!ArrivedNumExc & "</font>;</P>"
                End If
            End If
            ' Поступило (Дата письма)
            If rsAgentNo!ArrivedDateTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.dateArrivedDate = rsAgentNo!ArrivedDateExc
                    strTest = strTest & "<P>     Поступило (Дата письма): БД: <font color=""Crimson"">" & rsAgentNo!ArrivedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ArrivedDateExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Поступило (Дата письма): БД: <font color=""Crimson"">" & rsAgentNo!ArrivedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ArrivedDateExc & "</font>;</P>"
                End If
            End If
            ' Направлен в Бухгалтерию (№ СЗ)
            If rsAgentNo!SendedNumTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strSent = rsAgentNo!SendedNumExc
                    strTest = strTest & "<P>     Направлен в Бухгалтерию (№ СЗ): БД: <font color=""Crimson"">" & rsAgentNo!SendedNumBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!SendedNumExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Направлен в Бухгалтерию (№ СЗ): БД: <font color=""Crimson"">" & rsAgentNo!SendedNumBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!SendedNumExc & "</font>;</P>"
                End If
            End If
            ' Направлен в Бухгалтерию (дата СЗ)
            If rsAgentNo!SendedDateTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.dateSentDate = rsAgentNo!SendedDateExc
                    strTest = strTest & "<P>     Направлен в Бухгалтерию (дата СЗ): БД: <font color=""Crimson"">" & rsAgentNo!SendedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!SendedDateExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Направлен в Бухгалтерию (дата СЗ): БД: <font color=""Crimson"">" & rsAgentNo!SendedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!SendedDateExc & "</font>;</P>"
                End If
            End If
            ' Возвращен на доработку (№ письма)
            If rsAgentNo!ReturnedNumTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strReturned = rsAgentNo!ReturnedNumExc
                    strTest = strTest & "<P>     Возвращен на доработку (№ письма): БД: <font color=""Crimson"">" & rsAgentNo!ReturnedNumBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedNumExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Возвращен на доработку (№ письма): БД: <font color=""Crimson"">" & rsAgentNo!ReturnedNumBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedNumExc & "</font>;</P>"
                End If
            End If
            ' Возвращен на доработку (дата письма)
            If rsAgentNo!ReturnedDateTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.dateReturnedDate = rsAgentNo!ReturnedDateExc
                    strTest = strTest & "<P>     Возвращен на доработку (дата письма): БД: <font color=""Crimson"">" & rsAgentNo!ReturnedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedDateExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Возвращен на доработку (дата письма): БД: <font color=""Crimson"">" & rsAgentNo!ReturnedDateBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedDateExc & "</font>;</P>"
                End If
            End If
            ' Причина возврата
            If rsAgentNo!ReturnedReasonTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strReturnedReason = rsAgentNo!ReturnedReasonExc
                    strTest = strTest & "<P>     Причина возврата: БД: <font color=""Crimson"">" & rsAgentNo!ReturnedReasonBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedReasonExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Причина возврата: БД: <font color=""Crimson"">" & rsAgentNo!ReturnedReasonBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!ReturnedReasonExc & "</font>;</P>"
                End If
            End If
            ' CAPEX
            If rsAgentNo!CapexTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strCapex = rsAgentNo!CapexExc
                    strTest = strTest & "<P>     CAPEX: БД: <font color=""Crimson"">" & rsAgentNo!CapexBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!CapexExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     CAPEX: БД: <font color=""Crimson"">" & rsAgentNo!CapexBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!CapexExc & "</font>;</P>"
                End If
            End If
            ' год
            If rsAgentNo!yTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.lngY = rsAgentNo!yExc
                    strTest = strTest & "<P>     год: БД: <font color=""Crimson"">" & rsAgentNo!yyyyBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!yyyyExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     год: БД: <font color=""Crimson"">" & rsAgentNo!yyyyBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!yyyyExc & "</font>;</P>"
                End If
            End If
            ' месяц
            If rsAgentNo!mTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.lngM = rsAgentNo!mExc
                    strTest = strTest & "<P>     месяц: БД: <font color=""Crimson"">" & rsAgentNo!mBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!mExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     месяц: БД: <font color=""Crimson"">" & rsAgentNo!mBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!mExc & "</font>;</P>"
                End If
            End If
            ' Отдел Управления
            If rsAgentNo!unitTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeeCurrent.strUnit = rsAgentNo!unitExc
                    strTest = strTest & "<P>     Отдел Управления: БД: <font color=""Crimson"">" & rsAgentNo!unitBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!unitExc & "</font>; <b><font color=""Green"">Обновлено</font></b>;</P>"
                Else
                    strTest = strTest & "<P>     Отдел Управления: БД: <font color=""Crimson"">" & rsAgentNo!unitBd _
                        & "</font>, ист: <font color=""DarkGreen"">" & rsAgentNo!unitExc & "</font>;</P>"
                End If
            End If
            
            rsAgentNo.MoveNext: i = i + 1
            ' если был создан объект, то удаляем его
            If Not ogAgFeeCurrent Is Nothing Then
                Set ogAgFeeCurrent = Nothing
            End If
        Loop ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ' проходим по каждому Акту имеющему несоответствия в атрибутах. Окончание
    Else
        strTest = "Актов, имеющих несоответствия в атрибутах, нет."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    ' работаем с Актами по агентскому вознаграждению на предмет соответствия атрибутов в БД и источнике. Окончание
    
    ' проверяем факт наличия в источнике строект отсутствующих в БД
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestCstNo"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "В источнике имеются стройки отсутствующие в БД:"
        i = 1
        Do Until rsAgentNo.EOF
            strTest = strTest & " <b>" & i & "</b>. <font color=""Crimson"">" & rsAgentNo!oafptOafName & " от " _
                & rsAgentNo!oafptOafDate & "</font> " & rsAgentNo!ogaNm & " - <b><font color=""Red"">" & rsAgentNo!oafptPnCstAgPn & "</font></b>;"
            i = i + 1: rsAgentNo.MoveNext
        Loop
    Else
        strTest = "В источнике отсутствуют стройки отсутствующие в БД."
    End If
    rsAgentNo.Close: Set rsAgentNo = Nothing
    qdf.Close: Set qdf = Nothing
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
   
    ' вносим ключ стройки в промежуточную таблицу
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "exec ags.ogAgFeePnTestCstKey"
    qdf.ReturnsRecords = False  ''avoid 3065 error
    qdf.Execute dbFailOnError
    mobjParent.obgRa_aResult = "<P>Ключ стройки внесен в промежуточную таблицу.</P>" & mobjParent.obgRa_aResult
    qdf.Close: Set qdf = Nothing
    
    ' проверяем факт наличия в базе данных пунктов Актов агентского вознаграждения, отсутствующих в источнике
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.fnOgAgFeePnTestExcNo(" & mobjParent.year(mdbDb) & ") order by oafpOaf, cstapIpgPnN"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
        rsAgentNo.MoveFirst: strTest = "В базе данных имеются пункты Актов агентского вознаграждения, отсутствующие в источнике:"
        nnn = rsAgentNo!oafpOaf
        i = 1: ii = 1
        strTest = strTest & " <b>" & ii & "</b>. <font color=""Crimson"">" & rsAgentNo!oafNum & " от " _
            & rsAgentNo!oafDate & "</font>:"
        Do Until rsAgentNo.EOF
            If nnn = rsAgentNo!oafpOaf Then
                strTest = strTest & " <font color=""CadetBlue"">" & i & "</font>. " & rsAgentNo!cstapIpgPnN & ";"
            Else
                nnn = rsAgentNo!oafpOaf: ii = ii + 1
                strTest = strTest & " <b>" & ii & "</b>. <font color=""Crimson"">" & rsAgentNo!oafNum & " от " _
                    & rsAgentNo!oafDate & "</font>:" & " <font color=""CadetBlue"">" & i & "</font>. " & rsAgentNo!cstapIpgPnN & ";"
            End If
            i = i + 1
            rsAgentNo.MoveNext
        Loop
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
        ' нужно ли обновлять базу данных
        If mobjParent.blnAdt_AddRA Then
            ' да, обновлять базу данных нужно
            ' удаляем пункты Актов агентского вознаграждения отсутствующие в источнике
'            qdf.Close: Set qdf = Nothing
            Set qdf = db.CreateQueryDef("")
            qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
            qdf.SQL = "exec ags.ogAgFeePnTestExcNoDel " & mobjParent.year(mdbDb)
            qdf.ReturnsRecords = False  ''avoid 3065 error
            qdf.Execute dbFailOnError
            strTest = strTest & "<P>Пункты Актов агентского вознаграждения отсутствующие в источнике удалены.</P>"
            qdf.Close: Set qdf = Nothing
        End If
    Else
        strTest = "В базе данных отсутствуют пункты Актов агентского вознаграждения, отсутствующие в источнике."
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
    End If
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    
    ' работаем с пунктами Актов по агентскому вознаграждению, имеющимися в источнике но отсутствующими в БД. 10.07.2023
    ' проверяем наличие пунктов Актов отсутствующих в базе данных
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestDbNo order by oafptOafSender, oafptOafDate, oafptOafName, oafKey"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
    
        rsAgentNo.MoveFirst: strTest = "<P>Пункты Актов, имеющиеся в источнике, отсутствующие в базе данных: </P>": i = 1
        
        nnn = rsAgentNo!oafKey
        i = 1: ii = 1
        strTest = strTest & " <b>" & ii & "</b>. <font color=""CadetBlue"">" & rsAgentNo!oafptOafName & " от " _
            & rsAgentNo!oafptOafDate & "</font> " & rsAgentNo!oafptOafSender & ":"
        Do Until rsAgentNo.EOF
            If nnn = rsAgentNo!oafKey Then
                strTest = strTest & " <font color=""Chocolate"">" & i & "</font>. " & rsAgentNo!oafptPnCstAgPn & ";"
            Else
                nnn = rsAgentNo!oafKey: ii = ii + 1
                strTest = strTest & "</p><p><b>" & ii & "</b>. <font color=""CadetBlue"">" & rsAgentNo!oafptOafName & " от " _
                    & rsAgentNo!oafptOafDate & "</font> " & rsAgentNo!oafptOafSender & ":" & " <font color=""Chocolate"">" _
                    & i & "</font>. " & rsAgentNo!oafptPnCstAgPn & ";"
            End If
            i = i + 1
            rsAgentNo.MoveNext
        Loop
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
        
        ' нужно ли обновлять базу данных
        If mobjParent.blnAdt_AddRA Then
            ' да, обновлять базу данных нужно
            ' добавляем пункты Актов по агентскому вознаграждению отсутствующие в базе данных
            Set qdf = db.CreateQueryDef("")
            qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
            qdf.SQL = "exec ags.ogAgFeePnTestActPnAdd" ' 24-0619 здесь была ошибка двоящей пары "отчёт-стройка"
            qdf.ReturnsRecords = False  ''avoid 3065 error
            qdf.Execute dbFailOnError
            strTest = strTest & "<P>Пункты Актов по агентскому вознаграждению отсутствующие в базе данных добавлены.</P>"
            qdf.Close: Set qdf = Nothing
        End If
    Else
        strTest = "Пунктов Актов, имеющихся в источнике, отсутствующих в базе данных, нет."
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
    End If
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    ' работаем с пунктами Актов по агентскому вознаграждению, имеющимися в источнике но отсутствующими в БД. 10.07.2023. Окончание
    
    ' работаем с пунктами Актов по агентскому вознаграждению, имеющими разночтения с источником. 10.07.2023
    Set qdf = db.CreateQueryDef("")
    qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
    qdf.SQL = "SELECT * FROM ags.ogAgFeePnTestActPnNoEq order by oafptOafSender, oafptOafDate, oafptOafName, oafKey, oafptPnCstAgPn"
    qdf.ReturnsRecords = True
    Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
    If rsAgentNo.RecordCount > 0 Then
    
        rsAgentNo.MoveFirst: strTest = "<P>Пункты Актов, имеющие разночтения с источником: </P>": i = 1
        
        nnn = rsAgentNo!oafKey
        i = 1: ii = 1
        strTest = strTest & " <b>" & ii & "</b>. <font color=""CadetBlue"">" & rsAgentNo!oafptOafName & " от " _
            & rsAgentNo!oafptOafDate & "</font> " & rsAgentNo!oafptOafSender & ":"
        Do Until rsAgentNo.EOF
            If nnn = rsAgentNo!oafKey Then
                strTest = strTest & " <font color=""Chocolate"">" & i & "</font>. <b>" & rsAgentNo!oafptPnCstAgPn & "</b>;"
            Else
                nnn = rsAgentNo!oafKey: ii = ii + 1
                strTest = strTest & "</p><p><b>" & ii & "</b>. <font color=""CadetBlue"">" & rsAgentNo!oafptOafName & " от " _
                    & rsAgentNo!oafptOafDate & "</font> " & rsAgentNo!oafptOafSender & ":" & " <font color=""Chocolate"">" _
                    & i & "</font>. <b>" & rsAgentNo!oafptPnCstAgPn & "</b>;"
            End If
            
            ' нужно ли обновлять базу данных?
            If mobjParent.blnAdt_AddRA Then
                ' да, базу обновлять нужно. Создаём объект для обновления ***************
                Set ogAgFeePnCurrent = ClassFactory.ogAgFeePnByKey(rsAgentNo!oafpKey, mdbDb)
                ' ***********************************************************************
            End If
            
            ' Сумма
            If rsAgentNo!ttlTest = 0 Then
                ' нужно ли обновлять базу данных?
                If mobjParent.blnAdt_AddRA Then
                    ogAgFeePnCurrent.curTotal = rsAgentNo!oafptTtl
                    strTest = strTest & " Сумма: БД: <font color=""Crimson"">" & rsAgentNo!oafpTotal & "</font>, ист: <font color=""DarkGreen"">" _
                        & rsAgentNo!oafptTtl & "</font>; <b><font color=""Green"">Обновлено</font></b>;"
                Else
                    strTest = strTest & " Сумма: БД: <font color=""Crimson"">" & rsAgentNo!oafpTotal & "</font>, ист: <font color=""DarkGreen"">" _
                        & rsAgentNo!oafptTtl & "</font>;"
                End If
            End If
            
            ' если был создан объект, то удаляем его
            If Not ogAgFeePnCurrent Is Nothing Then
                Set ogAgFeePnCurrent = Nothing
            End If
            
            i = i + 1
            rsAgentNo.MoveNext
        Loop
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
        
    Else
        strTest = "Пунктов Актов, имеющих разночтения с источником, нет."
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing
    End If
    
    mobjParent.obgRa_aResult = "<P>" & strTest & "</P>" & mobjParent.obgRa_aResult
    ' работаем с пунктами Актов по агентскому вознаграждению, имеющими разночтения с источником. 10.07.2023. Окончание
    
    ' проверяем соответствие общей суммы =ПРОМЕЖУТОЧНЫЕ.ИТОГИ(109;[Сумма])
    Set cellResault = xlS.UsedRange.Find(what:="=ПРОМЕЖУТОЧНЫЕ.ИТОГИ(109;[Сумма])", LookIn:=xlFormulas, LookAt:=xlWhole)
'    Dim c As Range
'    Set c = cellResault.Find("=ПРОМЕЖУТОЧНЫЕ.ИТОГИ(109;[Сумма])", xlFormulas)
    If Not cellResault Is Nothing Then
        Dim rSource As Currency, rDb As Currency
        rSource = cellResault.value: strTest = "<b>Сумма Актов за год</b>. Итого, источник: <b><font color=""DarkGreen"">" _
            & Format(rSource, "Currency") & "</font></b>;"
        
        Set qdf = db.CreateQueryDef("")
        qdf.Connect = "ODBC;DSN=FishEye;Trusted_Connection=Yes;APP=Microsoft Office 2013;DATABASE=FishEye;"
        qdf.SQL = "select sum(p.oafpTotal) as smm from ags.ogAgFee a join ags.ogAgFeeP p on a.oafKey = p.oafpOaf " _
            & "where year(a.oafDate) = " & mobjParent.year(mdbDb)
        qdf.ReturnsRecords = True
        Set rsAgentNo = qdf.OpenRecordset(dbOpenSnapshot)
        If rsAgentNo.RecordCount > 0 Then
            rsAgentNo.MoveFirst ': strTest = "В источнике имеются стройки отсутствующие в БД:"
            rDb = rsAgentNo!smm
            strTest = strTest & " Итого, БД: <b><font color=""Chocolate"">" & Format(rDb, "Currency") _
                & "</font></b>; Разница: <font color=""Crimson"">" & Format(rSource - rDb, "Currency") & "</font>;"
        Else
            strTest = strTest & " В БД отсутствуют записи Актов. <font color=""Crimson"">Проверить невозможно</font>."
        End If
        rsAgentNo.Close: Set rsAgentNo = Nothing
        qdf.Close: Set qdf = Nothing

    Else
        strTest = "В источнике отсутствует ячейка с итоговой суммой. <font color=""Crimson"">Проверить невозможно</font>."
    End If
        
    mobjParent.obgRa_aResult = "<P>" & strTest & ".</P>" & mobjParent.obgRa_aResult
    
NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' работаем с листом Актов по агентскому вознаграждению всех агентов. 28.06.2023. Окончание
' ***************************************************************************************************************************************************
' методы. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' внутренние процедуры и функции
' ***************************************************************************************************************************************************
' заполняем промежуточную таблицу из источника данных. 29.06.2023
Private Sub AuditFillFromSource(xlS As Excel.Worksheet, db As DAO.Database, xlA As Object)
    ' -------------------------------------------------------------------------------------------------------------------------------------
    Dim dbObj As dbAccess
    Dim myArray(1 To 17, 1 To 2) As Variant
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Заполняем промежуточную таблицу из источника данных*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' 1 - откуда, 2 - куда
    myArray(1, 1) = "№ Акта": myArray(1, 2) = "oafptOafName"
    myArray(2, 1) = "Дата Акта": myArray(2, 2) = "oafptOafDate"
    myArray(3, 1) = "Код стройки": myArray(3, 2) = "oafptPnCstAgPn"
    myArray(4, 1) = "Сумма": myArray(4, 2) = "oafptTtl"
    myArray(5, 1) = "Поступило " & vbLf & "(№ письма)": myArray(5, 2) = "oafptArrivedNum"
    myArray(6, 1) = "Поступило (Дата письма)": myArray(6, 2) = "oafptArrivedDate"
    myArray(7, 1) = "Направлен в Бухгалтерию (№ СЗ)": myArray(7, 2) = "oafptSendedNum"
    myArray(8, 1) = "Направлен в Бухгалтерию (дата СЗ)": myArray(8, 2) = "oafptSendedDate"
    myArray(9, 1) = "Возвращен на доработку (№ письма) ": myArray(9, 2) = "oafptReturnedNum"
    myArray(10, 1) = "Возвращен на доработку (дата письма)": myArray(10, 2) = "oafptReturnedDate"
    myArray(11, 1) = "Причина возврата": myArray(11, 2) = "oafptReturnedReason"
    myArray(12, 1) = "Отдел Управления": myArray(12, 2) = "oafptUnit"
    myArray(13, 1) = "Кол-во листов Акта и С/Ф": myArray(13, 2) = "oafptPagesCount"
    myArray(14, 1) = "Кол-во Актов": myArray(14, 2) = "oafptActCount"
    myArray(15, 1) = "Агент": myArray(15, 2) = "oafptOafSender"
    myArray(16, 1) = "CAPEX": myArray(16, 2) = "oafptCapex"
    myArray(17, 1) = "Cумма возвращенных АВ": myArray(17, 2) = "oafptReturnedSum"
        
    Set dbObj = ClassFactory.dbAccessByDB(db)
        
    If dbObj.ExcelToTable(xlS, "ags_ogAgFeePnTest", myArray(), "№ Акта", "*", "oafptKey", mobjParent.obgRa_aResult) Then
        mobjParent.obgRa_aResult = "<P>Промежуточная таблица из источника данных заполнена.</P>" & mobjParent.obgRa_aResult
    Else
        mobjParent.obgRa_aResult = "<P>Промежуточную таблицу из источника данных заполненить не удалось.</P>" & mobjParent.obgRa_aResult
    End If

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' заполняем промежуточную таблицу из источника данных. 29.06.2023. Окончание
' ***************************************************************************************************************************************************
' внутренние процедуры и функции. Окончание
' ###################################################################################################################################################

