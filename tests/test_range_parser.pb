; test_range_parser.pb — Unit tests for RangeParser.pbi
; Phase C — placeholder (full tests written when RangeParser is implemented)
;
; Phase C tests will cover:
;   ParseRangeHeader("bytes=0-1023",  1024, *r) -> start=0, end=1023, valid
;   ParseRangeHeader("bytes=500-",    1024, *r) -> start=500, end=1023, valid
;   ParseRangeHeader("bytes=-200",    1024, *r) -> start=824, end=1023, valid
;   ParseRangeHeader("bytes=2000-",   1024, *r) -> invalid (416)
;   ParseRangeHeader("invalid",       1024, *r) -> invalid (416)
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit Placeholder_RangeParser()
  Assert(#True, "Phase C placeholder")
EndProcedureUnit
