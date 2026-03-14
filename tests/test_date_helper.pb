; test_date_helper.pb — Unit tests for DateHelper.pbi
; Tests: HTTPDate() RFC 7231 formatting
EnableExplicit
XIncludeFile "TestCommon.pbi"

; -----------------------------------------------------------------------
; Test: full RFC 7231 string for a known timestamp
; 2026-03-14 00:00:00 is a Saturday (verified: Jan 1 2026 = Thu + 72 days = Sat)
; -----------------------------------------------------------------------
ProcedureUnit Test_HTTPDate_FullFormat()
  Protected ts.q     = Date(2026, 3, 14, 0, 0, 0)
  Protected result.s = HTTPDate(ts)
  Assert(result = "Sat, 14 Mar 2026 00:00:00 GMT",
         "Full RFC 7231 string — got: '" + result + "'")
EndProcedureUnit

; -----------------------------------------------------------------------
; Test: zero-padding on single-digit day, hour, minute, second
; 2026-03-01 09:05:03 is a Sunday (14 Mar is Sat; Sat - 13 days = Sun)
; -----------------------------------------------------------------------
ProcedureUnit Test_HTTPDate_ZeroPadding()
  Protected ts.q     = Date(2026, 3, 1, 9, 5, 3)
  Protected result.s = HTTPDate(ts)
  Assert(result = "Sun, 01 Mar 2026 09:05:03 GMT",
         "Zero-padded fields — got: '" + result + "'")
EndProcedureUnit

; -----------------------------------------------------------------------
; Test: all seven day names
; Week: Sun=2026-03-15, Mon=16, Tue=17, Wed=18, Thu=19, Fri=20, Sat=21
; -----------------------------------------------------------------------
ProcedureUnit Test_HTTPDate_AllDayNames()
  Protected i.i, ts.q, result.s
  Dim expected.s(6)
  expected(0) = "Sun" : expected(1) = "Mon" : expected(2) = "Tue"
  expected(3) = "Wed" : expected(4) = "Thu" : expected(5) = "Fri"
  expected(6) = "Sat"

  For i = 0 To 6
    ts     = Date(2026, 3, 15 + i, 12, 0, 0)
    result = HTTPDate(ts)
    Assert(Left(result, 3) = expected(i),
           "Day " + Str(i) + ": expected '" + expected(i) + "' got '" + Left(result, 3) + "'")
  Next i
EndProcedureUnit

; -----------------------------------------------------------------------
; Test: all twelve month names
; Uses the 1st of each month in 2026 — day in the formatted string is "01"
; Month abbreviation is at position 9 (after "Day, 01 ")
; -----------------------------------------------------------------------
ProcedureUnit Test_HTTPDate_AllMonthNames()
  Protected i.i, ts.q, result.s, monthPart.s
  Dim expected.s(11)
  expected(0)  = "Jan" : expected(1)  = "Feb" : expected(2)  = "Mar"
  expected(3)  = "Apr" : expected(4)  = "May" : expected(5)  = "Jun"
  expected(6)  = "Jul" : expected(7)  = "Aug" : expected(8)  = "Sep"
  expected(9)  = "Oct" : expected(10) = "Nov" : expected(11) = "Dec"

  For i = 0 To 11
    ts        = Date(2026, i + 1, 1, 0, 0, 0)
    result    = HTTPDate(ts)
    ; Format: "Day, 01 Mon YYYY HH:MM:SS GMT"
    ;          123456789
    monthPart = Mid(result, 9, 3)
    Assert(monthPart = expected(i),
           "Month " + Str(i + 1) + ": expected '" + expected(i) + "' got '" + monthPart + "'")
  Next i
EndProcedureUnit
