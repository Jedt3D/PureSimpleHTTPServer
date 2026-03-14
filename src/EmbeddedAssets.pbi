; EmbeddedAssets.pbi — in-memory asset serving via IncludeBinary + CatchPack
; Include with: XIncludeFile "EmbeddedAssets.pbi"
; Provides: OpenEmbeddedPack(), ServeEmbeddedFile(), CloseEmbeddedPack()
;
; Phase D: implement CatchPack() + UncompressPackMemory() serving
; Phase A: placeholder (always returns #False — no embedded pack)
;
; Usage:
;   1. At build time: pack assets into a zip with scripts/pack_assets.sh
;   2. Embed the zip: DataSection / webapp: / IncludeBinary "webapp.zip" / webappEnd: / EndDataSection
;   3. At runtime:    OpenEmbeddedPack()  -> serve files -> CloseEmbeddedPack()
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; OpenEmbeddedPack() — initialize the in-memory asset pack
; Returns #True if embedded pack is available, #False if none compiled in
Procedure.i OpenEmbeddedPack()
  ; Phase D: implement CatchPack(#PB_Any, ?webapp, ?webappEnd - ?webapp)
  ProcedureReturn #False
EndProcedure

; ServeEmbeddedFile(connection.i, urlPath.s) — serve a file from the embedded pack
; Returns #True if file was found and served, #False if not in pack
Procedure.i ServeEmbeddedFile(connection.i, urlPath.s)
  ; Phase D: implement UncompressPackMemory() + SendNetworkData()
  ProcedureReturn #False
EndProcedure

; CloseEmbeddedPack() — release the in-memory pack resources
Procedure CloseEmbeddedPack()
  ; Phase D: implement ClosePack()
EndProcedure
