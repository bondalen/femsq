VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "prDoc"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' объект первичного документа. 25.03.2022

' ключ первичного документа
Private mlngCnpdKey As Long

' геттер свойства ключ первичного документа
Public Property Get cnpdKey() As Long
    cnpdKey = mlngCnpdKey
End Property

' обработка встроенного события инициализации
Private Sub Class_Initialize()
    ' инициализируем объект с нулевым ключём. В таком виде он не имеет смысла.
    ' Требуется реинициализация.
    mlngCnpdKey = 0
End Sub

' реинициализируем объект ~первичный документ~ через создание нового такого объекта по четырём параметрам. 25.03.2022 *******************************
Public Sub riPrDocCreateNew(ByVal cnpdNum As String, ByVal cnpdDate As Date, ByVal cnpdTpOrd As Long, _
    ByVal cnpdCnInvAccntSmpl As Long, db As DAO.Database, strNote As String)

    Dim rsCnpd As DAO.Recordset
    
    Const cstrTitle As String _
        = "Процедура *Реинициализируем объект ~первичный документ~ через создание нового такого объекта по четырём параметрам*."
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    ' создаём объект
    ' открываем таблицу для создания
    Set rsCnpd = db.OpenRecordset("ags_cn_PrDoc", dbOpenDynaset, dbSeeChanges)
    
    ' добавляем объект
    With rsCnpd
        .AddNew
            !cnpdNum = cnpdNum
            !cnpdDate = cnpdDate
            !cnpdTpOrd = cnpdTpOrd
            !cnpdCnInvAccntSmpl = cnpdCnInvAccntSmpl
            !cnpdNote = strNote
            !cnpdTimeofEntry = Now()
        .Update
        .Bookmark = .LastModified
        mlngCnpdKey = !cnpdKey
    End With
    
    ' закрываем таблицу
    rsCnpd.Close: Set rsCnpd = Nothing
    
NormalExit:
    Exit Sub
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Sub
' реинициализируем объект ~первичный документ~ через создание нового такого объекта по четырём параметрам. 25.03.2022. Окончание ********************

