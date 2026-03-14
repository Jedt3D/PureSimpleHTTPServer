; TestCommon.pbi — shared includes for all test files
; Include with: XIncludeFile "TestCommon.pbi"  (from the tests/ directory)
;
; All paths use "../src/" so PureUnit's parser resolves them from tests/ correctly.
; XIncludeFile is idempotent — safe to include modules that include each other.
EnableExplicit

XIncludeFile "../src/Global.pbi"
XIncludeFile "../src/Types.pbi"
XIncludeFile "../src/DateHelper.pbi"
XIncludeFile "../src/UrlHelper.pbi"
XIncludeFile "../src/HttpParser.pbi"
XIncludeFile "../src/HttpResponse.pbi"
XIncludeFile "../src/TcpServer.pbi"
XIncludeFile "../src/MimeTypes.pbi"
XIncludeFile "../src/Logger.pbi"
XIncludeFile "../src/FileServer.pbi"
XIncludeFile "../src/DirectoryListing.pbi"
XIncludeFile "../src/RangeParser.pbi"
XIncludeFile "../src/Config.pbi"
XIncludeFile "../src/EmbeddedAssets.pbi"
