; DirectoryListing.pbi — HTML directory browse page generator
; Include with: XIncludeFile "DirectoryListing.pbi"
; Provides: BuildDirectoryListing(dirPath.s, urlPath.s) -> String
;
; Phase C: implement HTML directory listing
; Phase A: placeholder
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; BuildDirectoryListing(dirPath.s, urlPath.s) — generate HTML directory listing
; dirPath: absolute filesystem path to the directory
; urlPath: URL path for generating links (e.g. "/docs/")
; Returns: HTML string for the directory listing page, "" on error
Procedure.s BuildDirectoryListing(dirPath.s, urlPath.s)
  ; Phase C: implement
  ProcedureReturn ""
EndProcedure
