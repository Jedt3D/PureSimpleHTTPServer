; test_range_parser.pb — Unit tests for RangeParser.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit Range_FullRange()
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=0-1023", 2048, @r)
  Assert(ok = #True,     "should be valid")
  Assert(r\Start = 0,    "start = 0")
  Assert(r\End   = 1023, "end = 1023")
  Assert(r\IsValid = #True, "IsValid flag")
EndProcedureUnit

ProcedureUnit Range_OpenEnded()
  ; bytes=500- means from 500 to end of 1024-byte file
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=500-", 1024, @r)
  Assert(ok = #True,     "should be valid")
  Assert(r\Start = 500,  "start = 500")
  Assert(r\End   = 1023, "end = fileSize-1")
EndProcedureUnit

ProcedureUnit Range_SuffixRange()
  ; bytes=-200 means last 200 bytes of a 1024-byte file
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=-200", 1024, @r)
  Assert(ok = #True,      "should be valid")
  Assert(r\Start = 824,   "start = 1024-200 = 824")
  Assert(r\End   = 1023,  "end = 1023")
EndProcedureUnit

ProcedureUnit Range_SuffixLargerThanFile()
  ; bytes=-5000 on a 1024-byte file → clamp start to 0
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=-5000", 1024, @r)
  Assert(ok = #True,    "should be valid (clamped)")
  Assert(r\Start = 0,   "start clamped to 0")
  Assert(r\End = 1023,  "end = 1023")
EndProcedureUnit

ProcedureUnit Range_EndClampedToFileSize()
  ; bytes=0-9999 on a 1024-byte file → end clamped to 1023
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=0-9999", 1024, @r)
  Assert(ok = #True,     "should be valid")
  Assert(r\End = 1023,   "end clamped to fileSize-1")
EndProcedureUnit

ProcedureUnit Range_StartBeyondFile()
  ; bytes=2000- on a 1024-byte file → 416 unsatisfiable
  Protected r.RangeSpec
  Protected ok.i = ParseRangeHeader("bytes=2000-", 1024, @r)
  Assert(ok = #False, "start beyond EOF should be unsatisfiable")
EndProcedureUnit

ProcedureUnit Range_InvalidFormat()
  Protected r.RangeSpec
  Assert(ParseRangeHeader("invalid",       1024, @r) = #False, "no 'bytes=' prefix")
  Assert(ParseRangeHeader("bytes=100-50",  1024, @r) = #False, "end < start invalid")
  Assert(ParseRangeHeader("bytes=",        1024, @r) = #False, "empty range spec")
EndProcedureUnit

ProcedureUnit Range_EmptyHeader()
  Protected r.RangeSpec
  Assert(ParseRangeHeader("", 1024, @r) = #False, "empty header invalid")
EndProcedureUnit

ProcedureUnit Range_ZeroFileSize()
  Protected r.RangeSpec
  Assert(ParseRangeHeader("bytes=0-", 0, @r) = #False, "zero-size file invalid")
EndProcedureUnit
