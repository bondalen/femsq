VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_cnAddNewInv"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database


' *****************************************************************************************************************************************
' добавляем новый счёт-фактуру. 07.04.2023
Private Sub btnSave_Click()
    Dim cnInvNew As cnInv, cnKey As Long
    Const cstrTitle As String = "Процедура кнопки *Добавляем новый счёт-фактуру*."
    '************************************************************************************************************************************************
On Error GoTo ErrHandler

' проверяем данные
cnKey = CLng(Me!txtCn_key.Caption)

If cnKey > 0 Then
    ' отсутствуют ли №?
    If IsNull(Me!invNum) Then
        ' да, № отсутствует
        ' отсутствует ли дата, либо она имеет неверный формат?
        If IsDate(Me!invDate) = False Then
            ' да, дата отсутствует, либо она имеет неверный формат
            If MsgBox("Отсутствуют № и дата (либо неверный её формат)! Создать такой счёт-фактуру?", _
                vbOKCancel + vbExclamation) = vbOK Then
                ' дата отсутствует?
                If IsNull(Me!invDate) Then
                    ' да, дата отсутствует
                    Set cnInvNew = ClassFactory.cnInvCreateNewInvNew _
                        (Null, Null, cnKey, CurrentDb, Trim("по кнопке, без № и даты. " & Me!invNote))
                    DoCmd.Close acForm, Me.name, acSaveNo
                    Set cnInvNew = Nothing
                Else
                    ' нет, дата имеет неверный формат
                    MsgBox ("Неверный формат даты. Счёт-фактура не создан")
                End If
            End If
        Else
            ' нет, дата имеется
            If MsgBox("Отсутствует №! Создать такой счёт-фактуру?", vbOKCancel + vbExclamation) = vbOK Then
                Set cnInvNew = ClassFactory.cnInvCreateNewInvNew _
                    (Null, Me!invDate, cnKey, CurrentDb, Trim("по кнопке, без №. " & Me!invNote))
                DoCmd.Close acForm, Me.name, acSaveNo
                Set cnInvNew = Nothing
            End If
        End If
    Else
        ' нет, № имеется
        ' отстутствует ли дата?
        If IsDate(Me!invDate) = False Then
            ' да, дата отсутствует
            If MsgBox("Отсутствует дата (либо неверный её формат)! Создать такой счёт-фактуру?", _
                vbOKCancel + vbExclamation) = vbOK Then
                ' дата отсутствует?
                If IsNull(Me!invDate) Then
                    ' да, дата отсутствует
                    Set cnInvNew = ClassFactory.cnInvCreateNewInvNew _
                        (Me!invNum, Null, cnKey, CurrentDb, Trim("по кнопке, без даты. " & Me!invNote))
                    DoCmd.Close acForm, Me.name, acSaveNo
                    Set cnInvNew = Nothing
                Else
                    ' нет, дата имеет неверный формат
                    MsgBox ("Неверный формат даты. Счёт-фактура не создан")
                End If
            End If
        Else
            ' нет, дата имеется
            Set cnInvNew = ClassFactory.cnInvCreateNewInvNew _
                (Me!invNum, Me!invDate, cnKey, CurrentDb, Trim("по кнопке. " & Me!invNote))
            DoCmd.Close acForm, Me.name, acSaveNo
            Set cnInvNew = Nothing
        End If
    End If
End If

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
End Sub
' *****************************************************************************************************************************************

Private Sub Form_Open(Cancel As Integer)
    If Len(Me.OpenArgs) > 0 Then
        Me!txtCn_key.Caption = Me.OpenArgs
    End If
End Sub
