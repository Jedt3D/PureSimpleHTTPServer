; FileServer.pbi — static file serving from disk
; Include with: XIncludeFile "FileServer.pbi"
; Provides: ServeFile(), ResolveIndexFile(), BuildETag()
;
; Phase B: implement file reading, ETag, Last-Modified, 404/403/500 responses
; Phase A: placeholder
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Types.pbi, MimeTypes.pbi

; ServeFile(connection.i, docRoot.s, urlPath.s) — serve a file from disk
; Returns #True if file was found and served, #False if not found (404)
Procedure.i ServeFile(connection.i, docRoot.s, urlPath.s)
  ; Phase B: implement
  ProcedureReturn #False
EndProcedure

; ResolveIndexFile(dirPath.s, indexList.s) — find an index file in a directory
; indexList: comma-separated list e.g. "index.html,index.htm"
; Returns full file path if found, "" if none exists
Procedure.s ResolveIndexFile(dirPath.s, indexList.s)
  ; Phase B: implement
  ProcedureReturn ""
EndProcedure

; BuildETag(filePath.s) — generate an ETag for a file (CRC32 of size+mtime)
; Returns ETag string suitable for use in ETag: header
Procedure.s BuildETag(filePath.s)
  ; Phase B: implement
  ProcedureReturn ""
EndProcedure
