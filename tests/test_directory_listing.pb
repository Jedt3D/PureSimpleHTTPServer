; test_directory_listing.pb — Unit tests for DirectoryListing.pbi
; Phase C — placeholder (full tests written when DirectoryListing is implemented)
;
; Phase C tests will:
;   - Create a temp directory with known files via ProcedureUnitStartup
;   - Assert BuildDirectoryListing() HTML contains each filename
;   - Assert filenames are URL-encoded in hrefs
;   - Assert ".." parent link present for subdirectory
;   - Clean up via ProcedureUnitShutdown
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit Placeholder_DirectoryListing()
  Assert(#True, "Phase C placeholder")
EndProcedureUnit
