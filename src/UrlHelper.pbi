; UrlHelper.pbi — URL decoding and path normalization
; Include with: XIncludeFile "UrlHelper.pbi"
; Provides: URLDecodePath(s.s), NormalizePath(s.s)
EnableExplicit

; URLDecodePath(s.s) — percent-decode a URL path string
; Uses PureBasic's built-in URLDecoder() from the HTTP library.
Procedure.s URLDecodePath(s.s)
  ProcedureReturn URLDecoder(s)
EndProcedure

; NormalizePath(s.s) — resolve . and .. path segments
;
; - Ensures result starts with /
; - Removes empty segments (double slashes) and . segments
; - Resolves .. by popping the last segment
; - Traversal above root is silently ignored (safe against path traversal)
; - Preserves trailing slash if original path had one
;
; Examples:
;   NormalizePath("/foo/./bar")   => "/foo/bar"
;   NormalizePath("/foo/../bar")  => "/bar"
;   NormalizePath("/../etc")      => "/etc"   (traversal above root ignored)
;   NormalizePath("")             => "/"
Procedure.s NormalizePath(s.s)
  Protected trailingSlash.i = #False
  Protected i.i, segment.s, count.i, result.s

  If Left(s, 1) <> "/"
    s = "/" + s
  EndIf

  If Len(s) > 1 And Right(s, 1) = "/"
    trailingSlash = #True
  EndIf

  NewList segments.s()

  count = CountString(s, "/") + 1
  For i = 1 To count
    segment = StringField(s, i, "/")
    Select segment
      Case "", "."
        ; skip empty (double-slash) and current-dir segments
      Case ".."
        If ListSize(segments()) > 0
          LastElement(segments())
          DeleteElement(segments())
        EndIf
        ; If list is empty, silently ignore (can't go above root)
      Default
        AddElement(segments())
        segments() = segment
    EndSelect
  Next i

  result = ""
  ForEach segments()
    result + "/" + segments()
  Next

  If result = ""
    result = "/"
  ElseIf trailingSlash
    result + "/"
  EndIf

  ProcedureReturn result
EndProcedure
