; DateHelper.pbi — RFC 7231 HTTP date formatting
; Include with: XIncludeFile "DateHelper.pbi"
; Provides: HTTPDate(ts.q) -> String
EnableExplicit

; HTTPDate(ts.q) — format a UTC timestamp as an RFC 7231 HTTP date string
;
; Format: "Day, DD Mon YYYY HH:MM:SS GMT"
; Example: HTTPDate(Date(2026, 3, 14, 0, 0, 0)) => "Sat, 14 Mar 2026 00:00:00 GMT"
;
; NOTE: PureBasic's FormatDate() has no day-name or month-name tokens,
; so we build those with lookup strings and StringField().
Procedure.s HTTPDate(ts.q)
  Protected days.s   = "Sun,Mon,Tue,Wed,Thu,Fri,Sat"
  Protected months.s = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"
  ; DayOfWeek: 0=Sun, 1=Mon, ..., 6=Sat  -> StringField index = DayOfWeek+1
  ; Month:     1=Jan, 2=Feb, ..., 12=Dec -> StringField index = Month directly
  ProcedureReturn StringField(days, DayOfWeek(ts) + 1, ",") + ", " +
                  FormatDate("%dd ", ts) +
                  StringField(months, Month(ts), ",") + " " +
                  FormatDate("%yyyy %hh:%ii:%ss", ts) + " GMT"
EndProcedure
