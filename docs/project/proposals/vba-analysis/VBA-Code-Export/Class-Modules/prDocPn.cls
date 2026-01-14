VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "prDocPn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' объект пункта первичного документа. 25.03.2022

' ###################################################################################################################################################
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' !!! не нужно их писать в других местах, это приведет к ошибке. 07.07.2022
' ключ пункта первичного документа
Private mlngPdpKey As Long
' база данных
Private mdbDb As DAO.Database
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' ---------------------------------------------------------------------------------------------------------------------------------------------------
Const cstrTable As String = "ags_cn_PrDocP", cstrTableKeyField As String = "pdpKey"
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' ###################################################################################################################################################


' ###################################################################################################################################################
' геттеры и сеттеры (леттеры) свойств
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' геттер свойства ключ пункта первичного документа
Public Property Get pdpKey() As Long
    pdpKey = mlngPdpKey
End Property
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' свойство *Стройка-Агент-Код*. 06.06.2023
' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *Стройка-Агент-Код*
Public Property Get lngStrAgPn() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *Стройка-Агент-Код*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    lngStrAgPn = readFieldVar("pdpCstAgPn")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *Стройка-Агент-Код*
Public Property Let lngStrAgPn(ByVal lngStrAgPnNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *Стройка-Агент-Код*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldNum "pdpCstAgPn", lngStrAgPnNew

NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' ссвойство *Стройка-Агент-Код*. 06.06.2023. Окончание
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' свойство *Бухгалтерский документ*. 05.06.2023
' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *Бухгалтерский документ*
Public Property Get strAccountingDoc() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *Бухгалтерский документ*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    strAccountingDoc = readFieldVar("accountingDoc")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *Бухгалтерский документ*
Public Property Let strAccountingDoc(ByVal strAccountingDocNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *Бухгалтерский документ*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldStr "accountingDoc", strAccountingDocNew

NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' ссвойство *Бухгалтерский документ*. 05.06.2023. Окончание
' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' свойство *Объект*. 06.06.2023
' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *Объект*
Public Property Get strObject() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *Объект*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    strObject = readFieldVar("object")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *Объект*
Public Property Let strObject(ByVal strObjectNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *Объект*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldStr "object", strObjectNew

NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' ссвойство *Объект*. 06.06.2023. Окончание
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
    mlngPdpKey = -1
End Sub
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' реинициализируем объект ~пункт первичного документа~ через создание нового такого объекта по N параметрам. 25.03.2022
' ...................................................................................................................................................
Public Sub riPrDocPnCreateNew(ByVal pdpPrDoc As Long, ByVal pdpCstAgPn As Long, ByVal StatusOfDICtext As String _
    , ByVal satstusOfOUKVtext As String, ByVal summ As Currency, ByVal cost As Currency, ByVal SumTax As Currency, ByVal costVAT As Currency _
    , ByVal SPPelement As String, ByVal docOfAccountNum As String _
    , ByVal AccountDate As Variant, ByVal positingDate As Variant _
    , ByVal accountingDoc As String, ByVal agent As Variant, ByVal TextOfAgent As Variant _
    , ByVal prjctDefinition As String, ByVal prjctDefinitionSort As String, ByVal prjctHierarchyLevel As Long _
    , ByVal ParentSppElementNum As Variant, ByVal Object As Variant _
    , ByVal cstDSW As Variant, ByVal raNum As Variant, ByVal raDate As Variant, ByVal CorrectionNum As Variant _
    , ByVal CorrectionDate As Variant _
    , ByVal accountingDocName As Variant _
    , ByVal purchasingGroup As Variant, ByVal purchasingGroupName As Variant, ByVal pdpNote As String, db As DAO.Database)

    Dim rsPrDocP As DAO.Recordset
    
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект ~пункт первичного документа~ через создание нового такого объекта по N параметрам*."
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    ' создаём объект
    ' открываем таблицу для создания
    Set rsPrDocP = db.OpenRecordset("ags_cn_PrDocP", dbOpenDynaset, dbSeeChanges)

    ' добавляем объект
    With rsPrDocP
        .AddNew
            !pdpPrDoc = pdpPrDoc
            !pdpCstAgPn = pdpCstAgPn
            ClassFactory.fieldInsertString !StatusOfDICtext, StatusOfDICtext
            ClassFactory.fieldInsertString !satstusOfOUKVtext, satstusOfOUKVtext
            !summ = summ
            !cost = cost
            !SumTax = SumTax
            !costVAT = costVAT
            ClassFactory.fieldInsertString !SPPelement, SPPelement
            ClassFactory.fieldInsertString !docOfAccountNum, docOfAccountNum
            !AccountDate = AccountDate
            !positingDate = positingDate
            ClassFactory.fieldInsertString !accountingDoc, accountingDoc
            ClassFactory.fieldInsertString !agent, agent
            ClassFactory.fieldInsertString !TextOfAgent, TextOfAgent
            ClassFactory.fieldInsertString !prjctDefinition, prjctDefinition
            ClassFactory.fieldInsertString !prjctDefinitionSort, prjctDefinitionSort
            !prjctHierarchyLevel = prjctHierarchyLevel
            ClassFactory.fieldInsertString !ParentSppElementNum, ParentSppElementNum
            ClassFactory.fieldInsertString !Object, Object
            ClassFactory.fieldInsertString !cstDSW, cstDSW
            ClassFactory.fieldInsertString !raNum, raNum
            !raDate = raDate
            ClassFactory.fieldInsertString !CorrectionNum, CorrectionNum
            !CorrectionDate = CorrectionDate
            ClassFactory.fieldInsertString !accountingDocName, accountingDocName
            ClassFactory.fieldInsertString !purchasingGroup, purchasingGroup
            ClassFactory.fieldInsertString !purchasingGroupName, purchasingGroupName
            ClassFactory.fieldInsertString !pdpNote, pdpNote
            !pdpTimeOfEntry = Now()
        .Update
        .Bookmark = .LastModified
        mlngPdpKey = !pdpKey
    End With

    ' закрываем таблицу
    rsPrDocP.Close: Set rsPrDocP = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Sub
' ...................................................................................................................................................
' реинициализируем объект ~пункт первичного документа~ через создание нового такого объекта по N параметрам. 25.03.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' реинициализируем объект *Пункт первичного документа* по известному ключу такого объекта. 02.06.2023
' ...................................................................................................................................................
Public Sub riByKey(ByVal prDocPnKey As Long, ByRef boResult As Boolean, ByRef db As DAO.Database)
    ' ...............................................................................................................................................
    Dim rs As DAO.Recordset, strSql As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Реинициализируем объект *Пункт первичного документа* по известному ключу такого объекта*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' ключ объекта равен -1? То есть реинициализация ранее не проводилась
    If mlngPdpKey = -1 Then
        ' да,ключ объекта равен -1
        ' отыскиваем объект по известному ключу
        strSql = "SELECT * FROM " & cstrTable & " WHERE " & cstrTableKeyField & " = " & prDocPnKey & ";"
        Set rs = db.OpenRecordset(strSql, dbOpenSnapshot)
        
        ' имеются ли записи с указанным ключём?
        If rs.RecordCount = 1 Then
            ' да, записи с указанным ключём имеются
            mlngPdpKey = rs!pdpKey
            Set mdbDb = db ' устанавливаем ссылку на базу данных
            boResult = True ' результат положительный
        Else
            ' нет, записи с указанным ключём отсутствуют
            mlngPdpKey = 0
            boResult = False ' результат отрицательный
        End If
    Else
        ' да,ключ объекта не равен -1
        ' ключ объекта равен 0?
        If mlngPdpKey = 0 Then
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
' реинициализируем объект *Пункт первичного документа* по известному ключу такого объекта. 02.06.2023. Окончание
' ***************************************************************************************************************************************************
' инициализации и реинициализации. Окончание
' ###################################################################################################################################################

' ###################################################################################################################################################
' чтение полей и запись в них
' ***************************************************************************************************************************************************
' редактируем строковое поле. 09.08.2022
Private Sub editFieldStr(ByVal strFieldName As String, ByVal strNew As Variant)

    ClassFunc.varEditFieldStr strFieldName, strNew, cstrTable, mlngPdpKey, cstrTableKeyField, mdbDb
    
End Sub
' редактируем строковое поле. 09.08.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' читаем значение поля в переменную типа Variant. 09.08.2022
Private Function readFieldVar(ByVal dateFieldName As String) As Variant
    
    readFieldVar = ClassFunc.varReadField(dateFieldName, cstrTable, mlngPdpKey, cstrTableKeyField, mdbDb)
    
End Function
' читаем значение поля в переменную типа Variant. 09.08.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем поле даты. 09.08.2022
Private Sub editFieldDate(ByVal dateFieldName As String, ByVal dateNew As Variant)
    
    ClassFunc.varEditFieldDate dateFieldName, dateNew, cstrTable, mlngPdpKey, cstrTableKeyField, mdbDb
    
End Sub
' редактируем поле даты. 09.08.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем числовое поле. 09.08.2022
Private Sub editFieldNum(ByVal numFieldName As String, ByVal numNew As Variant)
    
    ClassFunc.varEditFieldNum numFieldName, numNew, cstrTable, mlngPdpKey, cstrTableKeyField, mdbDb
    
End Sub
' редактируем числовое поле. 09.08.2022. Окончание
' ***************************************************************************************************************************************************
' чтение полей и запись в них. Окончание
' ###################################################################################################################################################

