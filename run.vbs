' Script writter by Tran Trong Hoa

' Execute command to cmd
Function ExecuteCommand(cmd)
    On Error Resume Next
    Dim objShell, objExec, strOutput
    Set objShell = CreateObject("WScript.Shell")
    Set objExec = objShell.Exec("cmd /c " & cmd)
    
    Do While Not objExec.StdOut.AtEndOfStream
        strOutput = strOutput & objExec.StdOut.ReadLine() & vbCrLf
    Loop

    Set objExec = Nothing
    Set objShell = Nothing
    ExecuteCommand = Trim(strOutput)
    On Error GoTo 0
End Function

' Fetch content from URL
Function FetchContentFromUrl(url)
    On Error Resume Next 
    Dim objXMLHTTP, strOutput
    Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
    
    objXMLHTTP.open "GET", url, False
    objXMLHTTP.send
    
    If Err.Number <> 0 Then
        strOutput = "Error fetching content from URL!"
    Else
        strOutput = objXMLHTTP.responseText
    End If
    
    Set objXMLHTTP = Nothing
    FetchContentFromUrl = strOutput
    On Error GoTo 0 
End Function

' Auto start localdb
Function AutoStartLOCALDB(name)
    AutoStartLOCALDB = ExecuteCommand("sqllocaldb start " & name)
End Function

' Get info localdb
Function GetInfoLocalDB(name)
    GetInfoLocalDB = ExecuteCommand("sqllocaldb i " & name)
End Function

' Author info
Dim Author, BaseGithubUrl
Author = "Tran Trong Hoa"
BaseGithubUrl = "https://raw.githubusercontent.com/hectran12/archive_sql_task/refs/heads/main/data/"

Dim WelcomeMsg
WelcomeMsg = FetchContentFromUrl(BaseGithubUrl & "welcome.txt")

Dim FullWelcome
FullWelcome = "Author: " & Author & vbCrLf & WelcomeMsg

MsgBox FullWelcome, vbInformation, "Welcome"

' Check SQL LOCALDB installed
Dim checkInstallSQLLOCALDB
checkInstallSQLLOCALDB = ExecuteCommand("sqllocaldb 2>&1")

If checkInstallSQLLOCALDB = "" Or InStr(LCase(checkInstallSQLLOCALDB), "not recognized") > 0 Then
    MsgBox "SQL Server LocalDB is NOT installed on this computer.", vbExclamation, "Error"
    WScript.Quit
End If

' List LocalDB instances
Dim ListLocalDB
ListLocalDB = ExecuteCommand("sqllocaldb i")

' Choice LocalDB instance
Dim LocalDBInstance
LocalDBInstance = InputBox("List of LocalDB instances:" & vbCrLf & ListLocalDB & vbCrLf & "Enter LocalDB instance name:", "LocalDB instance")

' Check exist LocalDB instance
If InStr(ListLocalDB, LocalDBInstance) = 0 Then
    MsgBox "LocalDB instance '" & LocalDBInstance & "' does NOT exist.", vbExclamation, "Error"
    WScript.Quit
End If

' Input code to initialize database
Dim CodeInitDB
CodeInitDB = InputBox("Enter code to initialize database (EX: ql1): ", "Code to initialize database")

' Fetch SQL script to initialize database
Dim SqlInitDB
SqlInitDB = BaseGithubUrl & CodeInitDB & ".txt"

Dim SqlInitDBContent
SqlInitDBContent = FetchContentFromUrl(SqlInitDB)

If SqlInitDBContent = "" Or SqlInitDBContent = "Error fetching content from URL!" Then
    MsgBox "SQL script to initialize database is NOT found.", vbExclamation, "Error"
    WScript.Quit
End If

' Auto start LocalDB instance
AutoStartLOCALDB(LocalDBInstance)

' Save to file
Dim SqlInitDBFile
SqlInitDBFile = "init.sql"

Dim objFSO, objFile
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.CreateTextFile(SqlInitDBFile, True)
objFile.Write SqlInitDBContent
objFile.Close

' Execute SQL script to initialize database
Dim ExecuteSqlInitDB
ExecuteSqlInitDB = ExecuteCommand("sqlcmd -S (localdb)\" & LocalDBInstance & " -i " & SqlInitDBFile)

' Get info LocalDB instance
Dim InfoLocalDB
InfoLocalDB = GetInfoLocalDB(LocalDBInstance)

' Save info to file info_db.txt
Dim InfoDBFile
InfoDBFile = "info_db.txt"

Set objFile = objFSO.CreateTextFile(InfoDBFile, True)
objFile.Write InfoLocalDB
objFile.Close

' Show info LocalDB instance
MsgBox InfoLocalDB, vbInformation, "Info LocalDB instance"
