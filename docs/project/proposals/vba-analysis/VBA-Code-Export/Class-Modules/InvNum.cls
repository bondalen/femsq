VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "InvNum"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' ключ номера счёта-фактуры
Private lngCnInvNumKey As Long

' получаем ключ номера счёта-фактуры
Public Property Get cnnKey() As String
    cnnKey = lngCnInvNumKey
End Property

' обработка встроенного события инициализации
Private Sub Class_Initialize()
    lngCnInvNumKey = 0
End Sub

' реинициализируем объект номера счёта-фактуры через создание нового по номеру. 22.03.2022 **********************************************************
Public Sub riInvNumCreateNewNum(invNum As Variant, InvKey As Long, db As DAO.Database, strNote As String)
    Dim rsInvNum As DAO.Recordset
    Const cstrTitle As String = "Процедура *Реинициализируем объект номера счёта-фактуры через создание нового по номеру*."
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler
    
    ' открываем таблицу для добавления
    Set rsInvNum = db.OpenRecordset("ags_invNum", dbOpenDynaset, dbSeeChanges)
    
    ' добавляем номер счёта-фактуры
    With rsInvNum
        .AddNew
            If IsNull(invNum) Then
                !inNote = "Счёт-фактура без номера. " & strNote
            Else
                !inNote = strNote
            End If
            !inNum = invNum
            !inInv = InvKey
            !inTimeOfEntry = Now()
        .Update
        .Bookmark = .LastModified
        lngCnInvNumKey = !inKey
    End With
    
    ' закрываем набор данных таблицы для добавления
    rsInvNum.Close: Set rsInvNum = Nothing
    
NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Sub
' реинициализируем объект номера счёта-фактуры через создание нового по номеру. 22.03.2022. Окончание ***********************************************

