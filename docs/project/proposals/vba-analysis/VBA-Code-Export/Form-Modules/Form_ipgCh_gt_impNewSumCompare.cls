VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Form_ipgCh>impNewSumCompare"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database

' ***************************************************************************************************************************************************
' смена текущей записи формы расхождений с импортом отчётов. 19.09.2022
' ---------------------------------------------------------------------------------------------------------------------------------------------------
Private Sub Form_Current()
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Dim ipgChIpgLate As Integer, cstAgPnC As cstAgPn, db As DAO.Database, ipgChYyyy As Integer
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Процедура *Геттер свойства *Смена текущей записи формы расхождений с импортом отчётов*."
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
    
    ' загружена ли форма ipgCh?
    If CurrentProject.AllForms("ipgCh").IsLoaded Then
        ' да, форма ipgCh загружена
        
        Set db = CurrentDb: Set cstAgPnC = ClassFactory.cstAgPnByCode(Me!cstAgPnCode, db)
        
        ' доступно ли свойство *форма* у контроля *ipgCh>ipgPn_t* без ошибок?
        If Test.controlFormNoError(Me.parent![ipgCh>ipgPn_t]) Then
            ' да, свойство *форма* у контроля *ipgCh>ipgPn_t* доступно без ошибок
            ipgChIpgLate = Me.parent![ipgcIpgLate]
            ' фильтруем *ipgCh>ipgPn_t*
            If ipgChIpgLate <> 0 And cstAgPnC.lngCstAgPnKey <> 0 Then
                Me.parent![ipgCh>ipgPn_t].Form.Form.Filter _
                    = "ipgpIpg = " & ipgChIpgLate & " And ipgpCstAgPn = " & cstAgPnC.lngCstAgPnKey
                Me.parent![ipgCh>ipgPn_t].Form.Form.FilterOn = True
            End If
            
            ' да, свойство *форма* у контроля *ipgCh>ipgPn_t* доступно без ошибок. Окончание
        End If ' доступно ли свойство *форма* у контроля *ipgCh>ipgPn_t* без ошибок?
        
        ' доступно ли свойство *форма* у контроля *ipgCh>ra_chSmLt_t* без ошибок?
        If Test.controlFormNoError(Me.parent![ipgCh>ra_chSmLt_t]) Then
            ' да, свойство *форма* у контроля *ipgCh>ra_chSmLt_t* доступно без ошибок
            ipgChYyyy = Me.parent![ipgcYyyy]
            ' фильтруем *ipgCh>ra_chSmLt_t*
            If ipgChYyyy <> 0 And cstAgPnC.lngCstAgPnKey <> 0 Then
                Me.parent![ipgCh>ra_chSmLt_t].Form.Form.Filter _
                    = "rc_yyyy = " & ipgChYyyy & " And ra_cac = " & cstAgPnC.lngCstAgPnKey
                Me.parent![ipgCh>ra_chSmLt_t].Form.Form.FilterOn = True
            End If
            ' да, свойство *форма* у контроля *ipgCh>ra_chSmLt_t* доступно без ошибок. Окончание
        End If ' доступно ли свойство *форма* у контроля *ipgCh>ra_chSmLt_t* без ошибок?
        
'        ' доступно ли свойство *форма* у контроля *ipgCh>ra_chSmLt_s* без ошибок?
'        If Test.controlFormNoError(Me.Parent![ipgCh>ra_chSmLt_s]) Then
'            ' да, свойство *форма* у контроля *ipgCh>ra_chSmLt_s* доступно без ошибок
'            ipgChYyyy = Me.Parent![ipgcYyyy]
'            ' фильтруем *ipgCh>ra_chSmLt_s*
'            If ipgChYyyy <> 0 And cstAgPnC.lngCstAgPnKey <> 0 Then
'                Me.Parent![ipgCh>ra_chSmLt_s].Form.Form.Filter _
'                    = "rc_yyyy = " & ipgChYyyy & " And ra_cac = " & cstAgPnC.lngCstAgPnKey
'                Me.Parent![ipgCh>ra_chSmLt_s].Form.Form.FilterOn = True
'            End If
'            ' да, свойство *форма* у контроля *ipgCh>ra_chSmLt_s* доступно без ошибок. Окончание
'        End If ' доступно ли свойство *форма* у контроля *ipgCh>ra_chSmLt_s* без ошибок?
        
        Set cstAgPnC = Nothing: Set db = Nothing
        ' да, форма ipgCh загружена. Окончание
    End If ' загружена ли форма ipgCh?

NormalExit:
    Exit Sub
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
End Sub
' ---------------------------------------------------------------------------------------------------------------------------------------------------
' смена текущей записи формы расхождений с импортом. 19.09.2022. Окончание
' ***************************************************************************************************************************************************
