VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "raSm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' объект *Сумма отчёта агента*

' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' !!! не нужно их писать в других местах, это приведет к ошибке. 07.07.2022
' ключ объекта *Сумма отчёта агента*
Private mlngRaSmKey As Long
' база данных
Private mdbDb As DAO.Database
' область определения закрытых пременных, содержащих значения свойств ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

' ###################################################################################################################################################
' геттеры и сеттеры (леттеры) свойств

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *всего*. 20.07.2022
Public Property Get curRaSmTtl() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *всего*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    curRaSmTtl = readFieldVar("ras_total")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *всего*. 20.07.2022
Public Property Let curRaSmTtl(ByVal curRaSmTtlNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *всего*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldNum "ras_total", curRaSmTtlNew
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *СМР*. 20.07.2022
Public Property Get curRaSmWork() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *СМР*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    curRaSmWork = readFieldVar("ras_work")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *СМР*. 20.07.2022
Public Property Let curRaSmWork(ByVal curRaSmWorkNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *СМР*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldNum "ras_work", curRaSmWorkNew
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *Оборудование*. 20.07.2022
Public Property Get curRaSmEquip() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *Оборудование*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    curRaSmEquip = readFieldVar("ras_equip")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *Оборудование*. 20.07.2022
Public Property Let curRaSmEquip(ByVal curRaSmEquipNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *Оборудование*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldNum "ras_equip", curRaSmEquipNew
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' геттер свойства *Прочие*. 20.07.2022
Public Property Get curRaSmOthers() As Variant
    Const cstrTitle As String = "Процедура *Геттер свойства *Прочие*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    curRaSmOthers = readFieldVar("ras_others")
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' леттер свойства *Прочие*. 20.07.2022
Public Property Let curRaSmOthers(ByVal curRaSmOthersNew As Variant)
    Const cstrTitle As String = "Процедура *Леттер свойства *Прочие*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    editFieldNum "ras_others", curRaSmOthersNew
    
NormalExit:
    Exit Property
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Property ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' геттеры и сеттеры (леттеры) свойств. Окончание
' ###################################################################################################################################################

' обработка встроенного события инициализации
Private Sub Class_Initialize()
    ' инициализируем объект с нулевым ключём. В таком виде он не имеет смысла.
    ' Требуется реинициализация.
    ' -1 означает, что проверки наличия свойства не было. Если позже будет установлено значение свойства,
    ' то оно будет приведено к 0 при отсутствии и к значению при наличии.
    ' Это чтобы избежать необходимости каждый раз вычислять свойство заново
    mlngRaSmKey = -1
End Sub

' ***************************************************************************************************************************************************
' реинициализируем объект *Сумма отчёта агента* по известному ключу такого объекта. 20.07.2022
Public Sub Class_ReinitialiseByKey(ByVal raSmKey As Long, ByRef boResult As Boolean, db As DAO.Database)

    Dim rs As DAO.Recordset, strSql As String
    
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект *Сумма отчёта агента* по известному ключу такого объекта*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    ' ключ объекта равен -1? То есть реинициализация ранее не проводилась
    If mlngRaSmKey = -1 Then
        ' да,ключ объекта равен -1
        ' отыскиваем объект по известному ключу
        strSql = "SELECT * FROM ags_ra_summ WHERE ras_key = " & raSmKey & ";"
        Set rs = db.OpenRecordset(strSql, dbOpenSnapshot)
        
        ' имеются ли записи с указанным ключём?
        If rs.RecordCount = 1 Then
            ' да, записи с указанным ключём имеются
            mlngRaSmKey = raSmKey
            ' устанавливаем ссылку на базу данных
            Set mdbDb = db
            ' результат положительный
            boResult = True
        Else
            ' нет, записи с указанным ключём отсутствуют
            mlngRaSmKey = 0
            ' результат отрицательный
            boResult = False
        End If
    Else
        ' да,ключ объекта не равен -1
        ' ключ объекта равен 0?
        If mlngRaSmKey = 0 Then
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
' реинициализируем объект *Сумма отчёта агента* по известному ключу такого объекта. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' реинициализируем объект *Сумма отчёта агента* путём создания такого объекта. 20.07.2022
Public Sub Class_ReinitialiseCreateNew(ByVal raKey As Long, ByRef boResult As Boolean, db As DAO.Database, _
    ByVal varTtl As Variant, ByVal varWork As Variant, ByVal varEquip As Variant, ByVal varOthers As Variant)

    Dim rs As DAO.Recordset, strSql As String, raSmKeyNew As Long
    
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект *Сумма отчёта агента* путём создания такого объекта*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler

    raSmKey = 0

    ' ключ объекта равен -1? То есть реинициализация ранее не проводилась
    If mlngRaSmKey = -1 Then
        ' да,ключ объекта равен -1
        ' создаём новый объект
        Set rs = db.OpenRecordset("ags_ra_summ", dbOpenDynaset, dbFailOnError + dbSeeChanges)
        With rs
            .AddNew
                !ras_ra = raKey
            .Update
            .Bookmark = .LastModified
            raSmKeyNew = !ras_key
        End With
        ' имеется ли новый ключ?
        If raSmKeyNew > 0 Then
            ' да, новый ключ имеется
            mlngRaSmKey = raSmKeyNew
            
            ' устанавливаем ссылку на базу данных
            Set mdbDb = db
            
            ' записываем суммы
            If IsNull(varTtl) Or IsNumeric(varTtl) Then
                curRaSmTtl = varTtl
            End If
            If IsNull(varWork) Or IsNumeric(varWork) Then
                curRaSmWork = varWork
            End If
            If IsNull(varEquip) Or IsNumeric(varEquip) Then
                curRaSmEquip = varEquip
            End If
            If IsNull(varOthers) Or IsNumeric(varOthers) Then
                curRaSmOthers = varOthers
            End If
            
            ' результат положительный
            boResult = True
        Else
            ' нет, записи с указанным ключём отсутствуют
            mlngRaSmKey = 0
            ' результат отрицательный
            boResult = False
        End If
    Else
        ' да,ключ объекта не равен -1
        ' ключ объекта равен 0?
        If mlngRaSmKey = 0 Then
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
' реинициализируем объект *Сумма отчёта агента* путём создания такого объекта. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' читаем значение поля в переменную типа Variant. 20.07.2022
Private Function readFieldVar(ByVal dateFieldName As String) As Variant
'    Const cstrTitle As String = "Процедура *Читаем значение поля в переменную типа Variant."
'    '************************************************************************************************************************************************
'On Error GoTo ErrHandler
    
    readFieldVar = ClassFunc.varReadField(dateFieldName, "ags_ra_summ", mlngRaSmKey, "ras_key", mdbDb)
    
'NormalExit:
'    Exit Function
'ErrHandler:
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
End Function
' читаем значение поля в переменную типа Variant. 20.07.2022. Окончание
' ***************************************************************************************************************************************************

' ***************************************************************************************************************************************************
' редактируем числовое поле. 20.07.2022
Private Sub editFieldNum(ByVal numFieldName As String, ByVal numNew As Variant)
'    Const cstrTitle As String = "Процедура *Редактируем числовое поле."
'    '************************************************************************************************************************************************
'On Error GoTo ErrHandler
    
    ClassFunc.varEditFieldNum numFieldName, numNew, "ags_ra_summ", mlngRaSmKey, "ras_key", mdbDb
    
'NormalExit:
'    Exit Sub
'ErrHandler:
'    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
'    Resume NormalExit
End Sub
' редактируем числовое поле. 20.07.2022. Окончание
' ***************************************************************************************************************************************************


