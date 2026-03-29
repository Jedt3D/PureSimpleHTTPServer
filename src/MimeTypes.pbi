; MimeTypes.pbi — MIME type lookup table
; Include with: XIncludeFile "MimeTypes.pbi"
; Provides: GetMimeType(extension.s) -> String
; Dependencies (managed by main.pb and tests/TestCommon.pbi): (none)

; GetMimeType(extension.s) — return MIME type for a file extension
; extension: lowercase, without leading dot (e.g. "html", "css", "js", "png")
; Returns "application/octet-stream" for unknown extensions.
Procedure.s GetMimeType(extension.s)
  Select extension
    ; Text
    Case "html", "htm"   : ProcedureReturn "text/html; charset=utf-8"
    Case "css"           : ProcedureReturn "text/css"
    Case "txt"           : ProcedureReturn "text/plain; charset=utf-8"
    Case "xml"           : ProcedureReturn "text/xml; charset=utf-8"
    Case "csv"           : ProcedureReturn "text/csv"
    Case "md"            : ProcedureReturn "text/markdown; charset=utf-8"
    Case "ics"           : ProcedureReturn "text/calendar"
    Case "vcf"           : ProcedureReturn "text/vcard"
    ; Scripts
    Case "js", "mjs"     : ProcedureReturn "application/javascript"
    Case "json"          : ProcedureReturn "application/json"
    Case "jsonld"        : ProcedureReturn "application/ld+json"
    Case "wasm"          : ProcedureReturn "application/wasm"
    Case "webmanifest"   : ProcedureReturn "application/manifest+json"
    Case "appcache"      : ProcedureReturn "text/cache-manifest"
    ; Images
    Case "png"           : ProcedureReturn "image/png"
    Case "jpg", "jpeg"   : ProcedureReturn "image/jpeg"
    Case "gif"           : ProcedureReturn "image/gif"
    Case "svg"           : ProcedureReturn "image/svg+xml"
    Case "webp"          : ProcedureReturn "image/webp"
    Case "ico"           : ProcedureReturn "image/x-icon"
    Case "bmp"           : ProcedureReturn "image/bmp"
    Case "avif"          : ProcedureReturn "image/avif"
    Case "tif", "tiff"   : ProcedureReturn "image/tiff"
    ; Fonts
    Case "woff"          : ProcedureReturn "font/woff"
    Case "woff2"         : ProcedureReturn "font/woff2"
    Case "ttf"           : ProcedureReturn "font/ttf"
    Case "otf"           : ProcedureReturn "font/otf"
    Case "eot"           : ProcedureReturn "application/vnd.ms-fontobject"
    ; Audio / Video
    Case "mp3"           : ProcedureReturn "audio/mpeg"
    Case "ogg"           : ProcedureReturn "audio/ogg"
    Case "wav"           : ProcedureReturn "audio/wav"
    Case "mp4"           : ProcedureReturn "video/mp4"
    Case "webm"          : ProcedureReturn "video/webm"
    Case "ogv"           : ProcedureReturn "video/ogg"
    ; Archives / Binary
    Case "zip"           : ProcedureReturn "application/zip"
    Case "gz"            : ProcedureReturn "application/gzip"
    Case "tar"           : ProcedureReturn "application/x-tar"
    Case "pdf"           : ProcedureReturn "application/pdf"
    Default              : ProcedureReturn "application/octet-stream"
  EndSelect
EndProcedure
