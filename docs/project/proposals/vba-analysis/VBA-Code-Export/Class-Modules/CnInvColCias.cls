VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CnInvColCias"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

' этот объект для работы со связью один-ко-многом объекта СФ+Д и объектами ~Факт связи тройки (СФ+Д)+СГК+ОПСД~

' родительский объект СФ+Д
Private mobjParent As cnInv

' геттер родительского объекта *СФ+Д*
Public Property Get parent() As cnInv
    ' возвращаем указатель на mobjParent, родительский объект СФ+Д
    Set parent = mobjParent
End Property

' сеттер родительского объекта *СФ+Д*
Public Property Set parent(ByVal objParent As cnInv)
    ' указатель на родительский объект *СФ+Д* отсутствует?
    If mobjParent Is Nothing Then
        ' да, указатель на родительский объект *СФ+Д* отсутствует
        ' устанавливаем указатель на objParent, родительский объект СФ+Д
        ' это можно сделать единственный раз в течении жизненного цикла объекта
        Set mobjParent = objParent
    End If
End Property

' получаем строковую информацию по наличию объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~ по ключу ОПСД. 23.03.2022 ***********************************
Public Function ReadInfCsos(ByVal csosKey As Long, db As DAO.Database) As String

    Dim rsCias As DAO.Recordset, rsCsos As DAO.Recordset, strSql As String, strStr As String, iCount As Integer
    
    Const cstrTitle As String _
        = "Функция *получаем строковую информацию по наличию объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~ по ключу ОПСД*."
        
    '************************************************************************************************************************************************
    
On Error GoTo ErrHandler

    'ReadCiasInfCsos = "что-то про наличие объектов соСчетомГКнПростой"
    
    ' проверяем сколько всего объектов соСчетомГКнПростой
'    strSql = "SELECT a.ciasKey, a.ciasCnInv, a.ciasAccnt, a.ciasCn_s_org_smpl, a.ciasNote, a.ciasTimeOfEntry " _
'        & "FROM ags_cnInvAccntSmpl AS a " _
'        & "WHERE (((a.ciasCnInv)=" & Me.Parent.ciKey & "));"
        
    strSql = "SELECT a.ciasKey, a.ciasCnInv, a.ciasAccnt, a.ciasCn_s_org_smpl, a.ciasNote, a.ciasTimeOfEntry, ac.account_num " _
        & "FROM ags_cnInvAccntSmpl AS a INNER JOIN ags_accnt AS ac ON a.ciasAccnt = ac.account_key " _
        & "WHERE (((a.ciasCnInv)=" & Me.parent.ciKey & "));"

    Set rsCias = db.OpenRecordset(strSql, dbOpenSnapshot)
    If rsCias.RecordCount > 0 Then
        rsCias.MoveLast
    End If
    iCount = rsCias.RecordCount
    
    ' отсутствуют объекты соСчетомГКнПростой?
    If iCount = 0 Then
        ' да, объекты соСчетомГКнПростой отсутствуют
        strStr = "Для ciKey = " & Me.parent.ciKey & " объекты вообще <font color=""Gray"">отсутствуют</font>"
    Else
        ' нет, объекты соСчетомГКнПростой имеются
        strStr = "Для ciKey = " & Me.parent.ciKey & " вообще имеется <font color=""BlueViolet""><b>" & iCount & "</b> объект</font>(а, ов). Счёт(а): "
        ' проходим по номерам счетов
        rsCias.MoveFirst
        iii = 1
        Do Until rsCias.EOF = True
            If iii = 1 Then
                strStr = strStr & iii & ". <font color=""BlueViolet"">" & rsCias!account_num & "</font>"
            Else
                strStr = strStr & ", " & iii & ". <font color=""BlueViolet"">" & rsCias!account_num & "</font>"
            End If
            iii = iii + 1
            rsCias.MoveNext
        Loop
        
        ' проверяем наличие объектов для определенного csosKey
        strSql = "SELECT a.ciasKey, a.ciasCnInv, a.ciasAccnt, a.ciasCn_s_org_smpl, a.ciasNote, a.ciasTimeOfEntry, ac.account_num " _
            & "FROM ags_cnInvAccntSmpl AS a INNER JOIN ags_accnt AS ac ON a.ciasAccnt = ac.account_key " _
            & "WHERE (((a.ciasCnInv)=" & Me.parent.ciKey & ") AND ((a.ciasCn_s_org_smpl)=" & csosKey & "));"
        Set rsCsos = db.OpenRecordset(strSql, dbOpenSnapshot)
        If rsCsos.RecordCount > 0 Then
            rsCsos.MoveLast
        End If
        iCount = rsCsos.RecordCount
        
        ' отсутствуют объекты для определенного csosKey?
        If iCount = 0 Then
            ' да, объекты для определенного csosKey отсутствуют
            strStr = strStr & ". Для csosKey = " & csosKey & " объекты <font color=""Gray"">отсутствуют</font>"
        Else
            ' нет, объекты для определенного csosKey имеются
            strStr = strStr & ". Для csosKey = " & csosKey & " имеется <font color=""Violet""><b>" & iCount & "</b> объект</font>(а, ов). Счёт(а): "
            ' проходим по номерам счетов
            rsCsos.MoveFirst
            iii = 1
            Do Until rsCsos.EOF = True
                If iii = 1 Then
                    strStr = strStr & iii & ". <font color=""Violet"">" & rsCsos!account_num & "</font>"
                Else
                    strStr = strStr & ", " & iii & ". <font color=""Violet"">" & rsCsos!account_num & "</font>"
                End If
                iii = iii + 1
                rsCsos.MoveNext
            Loop
        End If
        rsCsos.Close: Set rsCsos = Nothing
        
    End If

    rsCias.Close: Set rsCias = Nothing
    
    ' выводим результат
    ReadInfCsos = strStr
    
NormalExit:
    Exit Function
    
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle
    Resume NormalExit
    
End Function
' получаем строковую информацию по наличию объектов ~Факт связи тройки (СФ+Д)+СГК+ОПСД~ по ключу ОПСД. 23.03.2022. Окончание ************************


