Main(Wscript.Arguments(0))

Public Sub Main(targetPath)
    Const targetFilename = "sae_report.csv"
    Dim tempFile
    Dim targetFile
    Dim replaceText
    Dim newFile
    Set fso = CreateObject("Scripting.FileSystemObject")
    For Each tempFile In fso.GetFolder(targetPath).files
        If tempFile.Name = targetFilename Then
            Set targetFile = fso.OpenTextFile(tempFile.Path)
            replaceText = replaceCrlf(targetFile.readAll)
            targetFile.Close
            tempFile.Delete
            Set newFile = fso.createtextfile(targetPath + "\" + targetFilename)
            With newFile
                .write replaceText
                .Close
            End With
        End If
    Next
    Set newFile = Nothing
    Set targetFile = Nothing
    Set fso = Nothing
End Sub

Private Function replaceCrlf(targetText)
    Dim replaceText
    Dim constPattern
    constPattern = Chr(34) + vbCrLf
    Set regEx = CreateObject("VBScript.RegExp")
    With regEx
        .Pattern = constPattern
        .Global = True
    End With
    replaceText = regEx.Replace(targetText, "Åö")
    replaceText = Replace(replaceText, vbCrLf, "")
    replaceText = Replace(replaceText, "Åö", constPattern)
    replaceCrlf = replaceText
    Set regEx = Nothing
End Function
