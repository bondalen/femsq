# Предложения по изменению VBA кода — устранение TCP port exhaustion

**Дата:** 2026-06-01  
**Проблема:** Исчерпание TCP-портов (Event ID 4227, Tcpip) на RDS-хосте `NV-SK-TSW112.adm.gazprom.ru`  
**Корень проблемы:** ADODB-соединения к SQL Server открываются и закрываются при каждом вызове, порты не успевают выходить из состояния TIME_WAIT (240 сек по умолчанию)

---

## Изменение 1 — `dbAccess.cls`

### 1.1 Добавить приватную переменную для кэширования соединения

**Место:** секция приватных переменных, после строки `Private mdbDb As DAO.Database`

**Было:**
```vba
' ссылка на объект #база данных Access#
Private mdbDb As DAO.Database
```

**Стало:**
```vba
' ссылка на объект #база данных Access#
Private mdbDb As DAO.Database
' кэшированное ADODB-соединение к SQL Server (открывается один раз, переиспользуется)
Private moCn As ADODB.Connection
```

---

### 1.2 Переписать `GetNewADODBConnection()` — возвращать кэшированное соединение

**Место:** функция `GetNewADODBConnection`, строки ~465–488

**Было:**
```vba
' получаем новое подключение ADODB. 01.11.2024
Public Function GetNewADODBConnection() As ADODB.Connection
    Dim oCn As New ADODB.Connection
    Dim sCnStr As String
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Функция *Получаем новое подключение ADODB*."
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------
  
    sCnStr = "Provider='SQLOLEDB';Data Source='SPB-05-NV-SQL1';" & _
            "Integrated Security='SSPI';Initial Catalog='FishEye';"
    oCn.Open sCnStr
  
    If oCn.State = adStateOpen Then
        Set GetNewADODBConnection = oCn
    End If
  
' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Function
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Function
' получаем новое подключение ADODB. 01.11.2024. Окончание
```

**Стало:**
```vba
' получаем подключение ADODB. 01.11.2024. Ред. 2026-06-01: кэширование + retry
Public Function GetNewADODBConnection() As ADODB.Connection
    Dim sCnStr As String
    Dim intAttempt As Integer
    ' -----------------------------------------------------------------------------------------------------------------------------------------------
    Const cstrTitle As String = "Функция *Получаем подключение ADODB*."
    Const cintMaxAttempts As Integer = 3
    Const cintRetryDelaySec As Integer = 3
' ---------------------------------------------------------------------------------------------------------------------------------------------------
On Error GoTo ErrHandler
' ---------------------------------------------------------------------------------------------------------------------------------------------------

    ' соединение уже открыто — возвращаем без создания нового TCP-сокета
    If Not moCn Is Nothing Then
        If moCn.State = adStateOpen Then
            Set GetNewADODBConnection = moCn
            Exit Function
        End If
    End If

    ' соединения нет или оно закрыто — создаём новое с повторными попытками
    sCnStr = "Provider='SQLOLEDB';Data Source='SPB-05-NV-SQL1';" & _
             "Integrated Security='SSPI';Initial Catalog='FishEye';"

    For intAttempt = 1 To cintMaxAttempts
        On Error Resume Next
        Set moCn = New ADODB.Connection
        moCn.Open sCnStr
        On Error GoTo ErrHandler
        If moCn.State = adStateOpen Then
            Set GetNewADODBConnection = moCn
            Exit Function
        End If
        ' соединение не установлено — ждём перед следующей попыткой
        If intAttempt < cintMaxAttempts Then
            Application.Wait Now + TimeSerial(0, 0, cintRetryDelaySec)
        End If
    Next intAttempt

    ' все попытки исчерпаны
    MsgBox "Не удалось подключиться к SQL Server за " & cintMaxAttempts & " попытки." & vbCrLf & _
           "Попробуйте отключиться от удалённого рабочего стола и подключиться снова." & vbCrLf & _
           cstrTitle, vbExclamation, cstrTitle

' ---------------------------------------------------------------------------------------------------------------------------------------------------
NormalExit:
    Exit Function
ErrHandler:
    MsgBox Err.Description & vbCrLf & "Error number: " & Err.Number & vbCrLf & cstrTitle, vbExclamation, cstrTitle: Resume NormalExit
' ---------------------------------------------------------------------------------------------------------------------------------------------------
End Function
' получаем подключение ADODB. 01.11.2024. Ред. 2026-06-01: кэширование + retry. Окончание
```

---

### 1.3 Добавить `Class_Terminate()` — гарантированное закрытие соединения

**Место:** добавить **перед** строкой `' методы. Окончание` (в конце секции методов, после `GetNewADODBConnection`)

**Было:** *(процедура отсутствует)*

**Стало:**
```vba
' ***************************************************************************************************************************************************
' закрываем кэшированное ADODB-соединение при уничтожении объекта. 2026-06-01
Private Sub Class_Terminate()
    If Not moCn Is Nothing Then
        If moCn.State = adStateOpen Then moCn.Close
        Set moCn = Nothing
    End If
End Sub
' закрываем кэшированное ADODB-соединение при уничтожении объекта. 2026-06-01. Окончание
' ***************************************************************************************************************************************************
```

---

### 1.4 Исправить `SqlSrvRecordsetBySqlString()` — закрыть QueryDef явно

**Место:** функция `SqlSrvRecordsetBySqlString`, строки ~411–430

**Было:**
```vba
' получаем набор записей от сервера по строке SQL. 15.09.2022
' даём в эту функцию свой рекордсет, она нам его открывает, получая данные c SQL сервера, и возвращает количество строк в нём
Public Function SqlSrvRecordsetBySqlString(ByVal strSql As String, ByRef rstSqlSrv As DAO.Recordset) As Long
    
    Dim lgRslt As Long
    Dim qd As DAO.QueryDef

    'получаем набор записей от сервера путём создания временного запроса
    Set qd = mdbDb.CreateQueryDef("")
    qd.Connect = mdbDb.TableDefs("ags_yyyy").Connect
    qd.SQL = strSql
    qd.ReturnsRecords = True
    qd.ODBCTimeout = 600
    
    Set rstSqlSrv = qd.OpenRecordset(dbOpenSnapshot)
    rstSqlSrv.MoveLast
    lgRslt = rstSqlSrv.RecordCount
    rstSqlSrv.MoveFirst
    
    SqlSrvRecordsetBySqlString = lgRslt
    
End Function
' получаем набор записей от сервера по строке SQL. 15.09.2022. Окончание
```

**Стало:**
```vba
' получаем набор записей от сервера по строке SQL. 15.09.2022. Ред. 2026-06-01: закрытие qd
' даём в эту функцию свой рекордсет, она нам его открывает, получая данные c SQL сервера, и возвращает количество строк в нём
Public Function SqlSrvRecordsetBySqlString(ByVal strSql As String, ByRef rstSqlSrv As DAO.Recordset) As Long
    
    Dim lgRslt As Long
    Dim qd As DAO.QueryDef

    'получаем набор записей от сервера путём создания временного запроса
    Set qd = mdbDb.CreateQueryDef("")
    qd.Connect = mdbDb.TableDefs("ags_yyyy").Connect
    qd.SQL = strSql
    qd.ReturnsRecords = True
    qd.ODBCTimeout = 600
    
    Set rstSqlSrv = qd.OpenRecordset(dbOpenSnapshot)
    qd.Close: Set qd = Nothing  ' рекордсет держит свою ссылку на соединение — QueryDef можно закрыть немедленно
    
    rstSqlSrv.MoveLast
    lgRslt = rstSqlSrv.RecordCount
    rstSqlSrv.MoveFirst
    
    SqlSrvRecordsetBySqlString = lgRslt
    
End Function
' получаем набор записей от сервера по строке SQL. 15.09.2022. Ред. 2026-06-01: закрытие qd. Окончание
```

---

## Изменение 2 — `Form_ipgChMin.cls`

### 2.1 Убрать `objConn.Close` в `btnMasteringPercent_2408_Click()`

**Место:** строка ~352, в блоке завершения процедуры `btnMasteringPercent_2408_Click`

**Было:**
```vba
    ' Закрываем и очищаем всё, что нужно
    objConn.Close: Set rstCompound = Nothing: Set objConn = Nothing: Set dbAccessTest = Nothing: Set db = Nothing
```

**Стало:**
```vba
    ' Закрываем и очищаем всё, что нужно
    ' objConn.Close — не вызывать: соединение кэшировано в dbAccess, закроется в Class_Terminate при Set dbAccessTest = Nothing
    Set rstCompound = Nothing: Set objConn = Nothing: Set dbAccessTest = Nothing: Set db = Nothing
```

---

## Сводка изменений

| Файл | Процедура / место | Суть изменения | Ожидаемый эффект |
|------|-------------------|----------------|------------------|
| `dbAccess.cls` | Секция переменных | Добавить `Private moCn As ADODB.Connection` | Инфраструктура кэша |
| `dbAccess.cls` | `GetNewADODBConnection()` | Возвращать кэшированное соединение; retry 3×3 сек | 1 TCP-сокет на объект вместо N; переживает кратковременный порт-exhaustion |
| `dbAccess.cls` | Добавить `Class_Terminate()` | Закрывать `moCn` при уничтожении объекта | Порт освобождается немедленно, не ждёт GC |
| `dbAccess.cls` | `SqlSrvRecordsetBySqlString()` | `qd.Close: Set qd = Nothing` после `OpenRecordset` | QueryDef не удерживает ODBC-ресурс лишнее время |
| `Form_ipgChMin.cls` | `btnMasteringPercent_2408_Click()`, строка ~352 | Убрать `objConn.Close` | Не закрывает кэшированное соединение раньше `Class_Terminate` |

## Важные замечания

1. **Область кэширования** — соединение кэшируется на время жизни объекта `dbAccess`. Каждая процедура создаёт свой `dbAccess` через `ClassFactory.dbAccessByDB(db)` и уничтожает его в конце. Это значит, что одна кнопка = одно соединение на всю свою работу. Между разными нажатиями кнопок соединение пересоздаётся — что допустимо.

2. **Изменения 1.2 и 1.3 образуют пару** — применять вместе. Если применить 1.2 без 1.3, соединение может не закрыться своевременно при выходе `dbAccess` за область видимости.

3. **Изменение 2.1 применять только после 1.2+1.3** — иначе соединение останется незакрытым до вызова GC.

4. **Изменения 1.4 и 1.5 независимы** — можно применять отдельно и в любом порядке.

5. **Retry в 1.4** адресует симптом (пользователь видит понятное сообщение вместо технической ошибки), но не устраняет причину (исчерпание портов). Полное устранение — только через административные меры (`TcpTimedWaitDelay`, расширение диапазона портов, ODBC pooling).
