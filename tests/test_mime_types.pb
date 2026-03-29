; test_mime_types.pb — Unit tests for MimeTypes.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit MimeTypes_TextTypes()
  Assert(GetMimeType("html") = "text/html; charset=utf-8",  "html")
  Assert(GetMimeType("htm")  = "text/html; charset=utf-8",  "htm")
  Assert(GetMimeType("css")  = "text/css",                  "css")
  Assert(GetMimeType("txt")  = "text/plain; charset=utf-8", "txt")
  Assert(GetMimeType("xml")  = "text/xml; charset=utf-8",   "xml")
  Assert(GetMimeType("csv")  = "text/csv",                  "csv")
EndProcedureUnit

ProcedureUnit MimeTypes_ScriptTypes()
  Assert(GetMimeType("js")   = "application/javascript", "js")
  Assert(GetMimeType("mjs")  = "application/javascript", "mjs")
  Assert(GetMimeType("json") = "application/json",       "json")
  Assert(GetMimeType("wasm") = "application/wasm",       "wasm")
EndProcedureUnit

ProcedureUnit MimeTypes_ImageTypes()
  Assert(GetMimeType("png")  = "image/png",     "png")
  Assert(GetMimeType("jpg")  = "image/jpeg",    "jpg")
  Assert(GetMimeType("jpeg") = "image/jpeg",    "jpeg")
  Assert(GetMimeType("gif")  = "image/gif",     "gif")
  Assert(GetMimeType("svg")  = "image/svg+xml", "svg")
  Assert(GetMimeType("webp") = "image/webp",    "webp")
  Assert(GetMimeType("ico")  = "image/x-icon",  "ico")
EndProcedureUnit

ProcedureUnit MimeTypes_FontTypes()
  Assert(GetMimeType("woff")  = "font/woff",  "woff")
  Assert(GetMimeType("woff2") = "font/woff2", "woff2")
  Assert(GetMimeType("ttf")   = "font/ttf",   "ttf")
  Assert(GetMimeType("otf")   = "font/otf",   "otf")
EndProcedureUnit

ProcedureUnit MimeTypes_ArchiveTypes()
  Assert(GetMimeType("zip") = "application/zip",  "zip")
  Assert(GetMimeType("gz")  = "application/gzip", "gz")
  Assert(GetMimeType("pdf") = "application/pdf",  "pdf")
EndProcedureUnit

ProcedureUnit MimeTypes_UnknownExtension()
  Assert(GetMimeType("xyz")        = "application/octet-stream", "unknown xyz")
  Assert(GetMimeType("")           = "application/octet-stream", "empty extension")
  Assert(GetMimeType("purebasic")  = "application/octet-stream", "unknown purebasic")
EndProcedureUnit
