

Sub BatchConvertDocxToPDF()
    Dim objDoc As Document
    Dim strFile As String, strFolder As String

    'Initialization
    strFolder = ActiveDocument.Path & "\"
    strFile = Dir(strFolder & "*.docx", vbNormal)

    Set fs = CreateObject("Scripting.FileSystemObject")
    If Not fs.folderExists(strFolder & "pdf") Then
        fs.createFolder (strFolder & "pdf")
    End If

    'Precess each file in the file folder and convert them to pdf.
    While strFile <> ""
        Application.ScreenUpdating = False
            Set objDoc = Documents.Open(FileName:=strFolder & strFile)
            pdfName = strFolder & "pdf\" & strFile


            objDoc.ExportAsFixedFormat _
                OutputFileName:=Replace(pdfName, ".docx", ".pdf"), _
                ExportFormat:=wdExportFormatPDF, OpenAfterExport:=False, OptimizeFor:=wdExportOptimizeForPrint, _
                Range:=wdExportAllDocument, Item:=wdExportDocumentContent

            objDoc.Close SaveChanges:=wdDoNotSaveChanges
        Application.ScreenUpdating = True
        strFile = Dir()
        DoEvents
    Wend
End Sub


