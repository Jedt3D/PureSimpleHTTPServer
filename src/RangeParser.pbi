; RangeParser.pbi — HTTP Range header parser and partial-content sender
; Include with: XIncludeFile "RangeParser.pbi"
; Provides: ParseRangeHeader(), SendPartialResponse()
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, Types.pbi (RangeSpec), HttpResponse.pbi

; Structure RangeSpec is defined in Types.pbi (included before this file)

; ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec) — parse a Range: header value
; header:   the header value only, e.g. "bytes=0-1023" (not "Range: bytes=0-1023")
; fileSize: total size of the file in bytes (needed for suffix and open-ended ranges)
; *range:   filled with Start/End/IsValid on success
; Returns #True if range is satisfiable, #False if unsatisfiable (caller should send 416)
Procedure.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
  Protected rangeSpec.s, dashPos.i, startStr.s, endStr.s
  Protected startVal.i, endVal.i, suffixLen.i

  *range\IsValid = #False
  *range\Start   = 0
  *range\End     = fileSize - 1

  If fileSize <= 0
    ProcedureReturn #False
  EndIf

  ; Must start with "bytes="
  If LCase(Left(header, 6)) <> "bytes="
    ProcedureReturn #False
  EndIf

  rangeSpec = Mid(header, 7)  ; "start-end" portion
  dashPos   = FindString(rangeSpec, "-")
  If dashPos = 0
    ProcedureReturn #False
  EndIf

  startStr = Left(rangeSpec, dashPos - 1)
  endStr   = Mid(rangeSpec, dashPos + 1)

  If startStr = "" And endStr <> ""
    ; Suffix range: bytes=-200 → last 200 bytes
    suffixLen = Val(endStr)
    If suffixLen <= 0
      ProcedureReturn #False
    EndIf
    *range\Start = fileSize - suffixLen
    If *range\Start < 0
      *range\Start = 0
    EndIf
    *range\End = fileSize - 1

  ElseIf startStr <> "" And endStr = ""
    ; Open-ended range: bytes=500- → from 500 to EOF
    startVal = Val(startStr)
    If startVal < 0 Or startVal >= fileSize
      ProcedureReturn #False
    EndIf
    *range\Start = startVal
    *range\End   = fileSize - 1

  ElseIf startStr <> "" And endStr <> ""
    ; Full range: bytes=0-1023
    startVal = Val(startStr)
    endVal   = Val(endStr)
    If startVal < 0 Or endVal < startVal Or startVal >= fileSize
      ProcedureReturn #False
    EndIf
    If endVal >= fileSize
      endVal = fileSize - 1
    EndIf
    *range\Start = startVal
    *range\End   = endVal

  Else
    ProcedureReturn #False
  EndIf

  *range\IsValid = #True
  ProcedureReturn #True
EndProcedure

; SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
; Sends a 206 Partial Content response for the given byte range.
; mimeType:  content type string (caller computes this from extension)
; fileSize:  total file size (for Content-Range header)
; Returns #True on success, #False on I/O error.
Procedure.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
  Protected rangeLen.i   = *range\End - *range\Start + 1
  Protected contentRange.s, extraHeaders.s
  Protected *buffer, file.i

  If rangeLen <= 0
    ProcedureReturn #False
  EndIf

  *buffer = AllocateMemory(rangeLen + 1)
  If *buffer = 0
    ProcedureReturn #False
  EndIf

  file = ReadFile(#PB_Any, fsPath)
  If file = 0
    FreeMemory(*buffer)
    ProcedureReturn #False
  EndIf

  FileSeek(file, *range\Start)
  ReadData(file, *buffer, rangeLen)
  CloseFile(file)

  contentRange  = "bytes " + Str(*range\Start) + "-" + Str(*range\End) + "/" + Str(fileSize)
  extraHeaders  = "Content-Type: "  + mimeType       + #CRLF$
  extraHeaders + "Content-Range: "  + contentRange   + #CRLF$
  extraHeaders + "Cache-Control: "  + "max-age=0"    + #CRLF$

  SendNetworkString(connection, BuildResponseHeaders(#HTTP_206, extraHeaders, rangeLen), #PB_Ascii)
  SendNetworkData(connection, *buffer, rangeLen)

  FreeMemory(*buffer)
  ProcedureReturn #True
EndProcedure
