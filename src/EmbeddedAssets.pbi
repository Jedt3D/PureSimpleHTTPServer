; EmbeddedAssets.pbi — in-memory asset serving via IncludeBinary + CatchPack
; Include with: XIncludeFile "EmbeddedAssets.pbi"
; Provides: OpenEmbeddedPack(), ServeEmbeddedFile(), CloseEmbeddedPack()
;
; Usage:
;   1. Build time: scripts/pack_assets.sh  dist/  webapp.zip
;   2. In main.pb: UseZipPacker()
;                  DataSection
;                    webapp: IncludeBinary "webapp.zip"  webappEnd:
;                  EndDataSection
;   3. In Main(): OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, MimeTypes.pbi, HttpResponse.pbi

; g_EmbeddedPack — CatchPack handle; 0 = no pack open
Global g_EmbeddedPack.i

; OpenEmbeddedPack(*packData, packSize) — open the in-memory asset pack
; *packData:  address of embedded data (e.g. ?webapp)
; packSize:   size in bytes (e.g. ?webappEnd - ?webapp)
; Default args (0, 0) → returns #False (no pack available — used in unit tests)
; Returns #True if pack opened successfully, #False otherwise.
Procedure.i OpenEmbeddedPack(*packData = 0, packSize.i = 0)
  If g_EmbeddedPack > 0
    ProcedureReturn #True  ; already open
  EndIf

  If *packData = 0 Or packSize <= 0
    ProcedureReturn #False  ; no embedded pack data
  EndIf

  UseZipPacker()
  g_EmbeddedPack = CatchPack(#PB_Any, *packData, packSize)
  ProcedureReturn Bool(g_EmbeddedPack > 0)
EndProcedure

; ServeEmbeddedFile(connection.i, urlPath.s) — serve a file from the embedded pack
; urlPath: normalized URL path (e.g. "/index.html" → looks for "index.html" in pack)
; Returns #True if file was found and served (200), #False if not in pack.
Procedure.i ServeEmbeddedFile(connection.i, urlPath.s)
  If g_EmbeddedPack = 0
    ProcedureReturn #False
  EndIf

  ; Strip leading "/" to get pack-relative path ("index.html", "css/app.css", etc.)
  Protected packPath.s = Mid(urlPath, 2)
  If packPath = ""
    packPath = "index.html"
  EndIf

  ; Allocate a working buffer (Phase D: 4 MB ceiling for embedded assets)
  Protected maxSize.i = 4 * 1024 * 1024
  Protected *buffer = AllocateMemory(maxSize)
  If *buffer = 0
    ProcedureReturn #False
  EndIf

  ; Decompress directly by filename; returns -1 if not found
  Protected uncompressedSize.i = UncompressPackMemory(g_EmbeddedPack, *buffer, maxSize, packPath)
  If uncompressedSize < 0
    FreeMemory(*buffer)
    ProcedureReturn #False
  EndIf

  Protected ext.s          = LCase(GetExtensionPart(packPath))
  Protected mimeType.s     = GetMimeType(ext)
  Protected extraHeaders.s = "Content-Type: " + mimeType + #CRLF$

  SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, extraHeaders, uncompressedSize), #PB_Ascii)
  If uncompressedSize > 0
    SendNetworkData(connection, *buffer, uncompressedSize)
  EndIf

  FreeMemory(*buffer)
  ProcedureReturn #True
EndProcedure

; CloseEmbeddedPack() — release the in-memory pack handle
Procedure CloseEmbeddedPack()
  If g_EmbeddedPack > 0
    ClosePack(g_EmbeddedPack)
    g_EmbeddedPack = 0
  EndIf
EndProcedure
