; test_embedded_assets.pb — Unit tests for EmbeddedAssets.pbi
; Phase D: tests the graceful no-pack fallback.
; Full pack tests require an embedded zip (tested via the binary build).
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit EmbeddedPack_NoPackReturnsFalse()
  ; OpenEmbeddedPack() with no arguments (default 0,0) should return #False
  Assert(OpenEmbeddedPack() = #False, "no embedded pack → should return #False")
EndProcedureUnit

ProcedureUnit EmbeddedPack_ServeWithoutOpenReturnsFalse()
  ; g_EmbeddedPack is 0 (no pack open) → ServeEmbeddedFile should bail immediately
  Assert(ServeEmbeddedFile(0, "/index.html") = #False, "serve without open pack → #False")
EndProcedureUnit

ProcedureUnit EmbeddedPack_CloseWithoutOpenIsHarmless()
  ; CloseEmbeddedPack() on an unopened pack must not crash
  CloseEmbeddedPack()
  Assert(#True, "CloseEmbeddedPack() on closed pack is harmless")
EndProcedureUnit

ProcedureUnit EmbeddedPack_InvalidPointerReturnsFalse()
  ; Explicitly pass zero pointer and zero size → #False (guards against accidental calls)
  Assert(OpenEmbeddedPack(0, 1024) = #False, "null pointer → #False")
  Assert(OpenEmbeddedPack(1, 0)    = #False, "zero size → #False")
EndProcedureUnit
