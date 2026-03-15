// 
// PureBasic 6.30 - C Backend (MacOS X - arm64) generated code
// 
// (c) 2025 Fantaisie Software
// 
// The header must remain intact for Re-Assembly
// 
// Process
// Cipher
// Thread
// RegularExpression
// Http
// PackerZip
// PackerArchive
// Packer
// Internal
// Requester
// Network
// Date
// Cocoa
// Menu
// Window
// Event
// Gadget
// FileSystem
// System
// DragDrop
// Image
// ImagePluginBMP
// ImagePlugin
// VectorDrawing
// String
// 2DDrawing
// Font
// Desktop
// 2DDrawingBase
// Array
// File
// Sort
// Math
// LinkedList
// Memory
// Map
// Object
// SimpleList
// :System
// 
#pragma warning(disable: 4024)
// 
typedef long long quad;
typedef quad integer;
#define PB_INFINITY (1.0 / 0.0)
#define PB_NEG_INFINITY (-1.0 / 0.0)
typedef struct pb_array { void *a; } pb_array;
typedef struct pb_array2 { void *a; integer b[2]; } pb_array2;
typedef struct pb_array3 { void *a; integer b[3]; } pb_array3;
typedef struct pb_array4 { void *a; integer b[4]; } pb_array4;
typedef struct pb_array5 { void *a; integer b[5]; } pb_array5;
typedef struct pb_array6 { void *a; integer b[6]; } pb_array6;
typedef struct pb_array7 { void *a; integer b[7]; } pb_array7;
typedef struct pb_array8 { void *a; integer b[8]; } pb_array8;
typedef struct pb_array9 { void *a; integer b[9]; } pb_array9;
typedef struct pb_listitem { void *a; void *b; void *c;} pb_listitem;
typedef struct pb_list { void *a; pb_listitem *b; } pb_list;
typedef struct pb_mapitem { void *a; void *b; void *c;} pb_mapitem;
typedef struct pb_pbmap { pb_mapitem *a; } pb_pbmap;
typedef struct pb_map { pb_pbmap *a; } pb_map;
static integer s_s[]={0, -1};
#define M_SYSFUNCTION(a) a
#define M_PBFUNCTION(a) a
#define M_CDECL
typedef void TCHAR;
#include <math.h>
#define SYS_BankerRound(x) llrint(x)
#define SYS_BankerRoundQuad(x) llrint(x)
// 
integer PB_AddElement(void*);
integer PB_AllocateMemory(integer);
integer PB_AllocateStructure(integer,void*);
integer PB_CatchPack(integer,integer,integer);
integer PB_ClearList(void*);
integer PB_CloseFile(integer);
integer PB_CloseNetworkConnection(integer);
integer PB_CloseNetworkServer(integer);
integer PB_ClosePack(integer);
quad PB_ConvertDate(quad,integer);
integer PB_CountProgramParameters();
integer PB_CountString(void*,void*);
integer PB_CreateDirectory(void*);
integer PB_CreateFile(integer,void*);
integer PB_CreateMutex();
integer PB_CreateNetworkServer2(integer,integer,integer);
integer PB_CreateRegularExpression(integer,void*);
integer PB_CreateThread(integer,integer);
quad PB_Date();
integer PB_DayOfWeek(quad);
integer PB_Delay(integer);
integer PB_DeleteElement(void*);
integer PB_DeleteFile(void*);
integer PB_DeleteMapElement2(void*,void*);
void* PB_DirectoryEntryName(integer,integer);
integer PB_DirectoryEntryType(integer);
integer PB_EndDate();
integer PB_EndThread();
integer PB_EndVectorDrawing();
integer PB_Eof(integer);
integer PB_Event_Free();
integer PB_Event_Init();
integer PB_EventClient();
integer PB_ExamineDirectory(integer,void*,void*);
integer PB_ExamineRegularExpression(integer,void*);
integer PB_FileSeek(integer,quad);
quad PB_FileSize(void*);
integer PB_FindMapElement(void*,void*);
integer PB_FindString(void*,void*);
integer PB_FinishDirectory(integer);
integer PB_FirstElement(void*);
integer PB_FlushFileBuffers(integer);
void* PB_FormatDate(void*,quad,integer);
integer PB_FreeCocoa();
integer PB_FreeDesktops();
integer PB_FreeFiles();
integer PB_FreeFileSystem();
integer PB_FreeFonts();
integer PB_FreeImages();
integer PB_FreeList(void*);
integer PB_FreeMap(void*);
integer PB_FreeMemory(integer);
integer PB_FreeMemorys();
integer PB_FreeMutex(integer);
integer PB_FreeNetworks();
integer PB_FreeObjects();
integer PB_FreePackers();
integer PB_FreeRegularExpression(integer);
integer PB_FreeRegularExpressions();
integer PB_FreeStructure(integer);
integer PB_FreeWindows();
void* PB_GetExtensionPart(void*,integer);
quad PB_GetFileDate(void*,integer);
void* PB_GetFilePart(void*,integer);
void* PB_GetPathPart(void*,integer);
void* PB_GetTemporaryDirectory(integer);
void* PB_Hex(quad,integer);
integer PB_Init2DDrawing();
integer PB_InitArray();
integer PB_InitBMPImagePlugin();
integer PB_InitDate();
integer PB_InitDesktop();
integer PB_InitFile();
integer PB_InitFont();
integer PB_InitGadget();
integer PB_InitHTTP();
integer PB_InitImage();
integer PB_InitImageDecoder();
integer PB_InitList();
integer PB_InitMap();
integer PB_InitMemory();
integer PB_InitMenu();
integer PB_InitNetworkInternal();
integer PB_InitPacker();
integer PB_InitProcess();
integer PB_InitRegularExpression();
integer PB_InitRequester();
integer PB_InitThread();
integer PB_InitVectorDrawing();
integer PB_InitWindow();
integer PB_InternalProcessToFront();
integer PB_LastElement(void*);
void* PB_LCase(void*,integer);
void* PB_Left(void*,integer,integer);
integer PB_Len(void*);
integer PB_ListSize(void*);
integer PB_LockMutex(integer);
quad PB_Lof(integer);
integer PB_MessageRequester(void*,void*);
void* PB_Mid(void*,integer,integer);
void* PB_Mid2(void*,integer,integer,integer);
integer PB_Month(quad);
integer PB_NetworkServerEvent2(integer);
integer PB_NextDirectoryEntry(integer);
integer PB_NextElement(void*);
integer PB_NextRegularExpressionMatch(integer);
integer PB_OpenFile(integer,void*);
quad PB_PeekI(quad);
void* PB_PeekS3(integer,integer,integer,integer);
integer PB_PokeI(quad,quad);
void* PB_ProgramFilename(integer);
void* PB_ProgramParameter2(integer,integer);
integer PB_ReadData(integer,integer,integer);
integer PB_ReadFile(integer,void*);
void* PB_ReadString(integer,integer);
integer PB_ReceiveNetworkData(integer,integer,integer);
void* PB_RegularExpressionGroup(integer,integer,integer);
integer PB_RenameFile(void*,void*);
void* PB_ReplaceString(void*,void*,void*,integer);
integer PB_ResetList(void*);
void* PB_Right(void*,integer,integer);
void* PB_RSet2(void*,integer,void*,integer);
integer PB_SendNetworkData(integer,integer,integer);
integer PB_SendNetworkString2(integer,void*,integer);
integer PB_SetBundleCurrentDirectory();
integer PB_SortList(void*,integer);
void* PB_Str(quad,integer);
void* PB_StrF2(float,integer,integer);
integer PB_StringByteLength2(void*,integer);
void* PB_StringField(void*,integer,void*,integer);
void* PB_Trim(void*,integer);
integer PB_UncompressPackMemory2(integer,integer,integer,void*);
integer PB_UnlockMutex(integer);
void* PB_URLDecoder(void*,integer);
void* PB_URLEncoder(void*,integer);
integer PB_UseZipPacker();
quad PB_Val(void*);
integer PB_WaitThread(integer);
integer PB_WriteString2(integer,void*,integer);
integer PB_WriteStringN2(integer,void*,integer);
static char *tls;
int PB_ExitCode=0;
integer PB_MemoryBase=0;
integer PB_Instance=0;
int PB_ArgC;
char **PB_ArgV;
static unsigned char *pb_datapointer;
// 
// 
// 
// 
void SYS_Quit();
M_SYSFUNCTION(void) SYS_InitPureBasic();
void exit(int status);
M_PBFUNCTION(void) PB_InitCocoa();
M_SYSFUNCTION(void) SYS_CopyString(const void *String);
M_SYSFUNCTION(void) SYS_FreeStructureStrings(void *Buffer, integer *StructureMap);
int M_CDECL SYS_StringEqual(TCHAR *String1, TCHAR *String2);
M_SYSFUNCTION(void) SYS_AllocateString4(TCHAR **String, integer PreviousPosition);
M_SYSFUNCTION(void) SYS_FastAllocateString4(TCHAR **Address, const TCHAR *String);
M_SYSFUNCTION(integer) SYS_FastAllocateStringFree4(TCHAR **Address, const TCHAR *String);
M_SYSFUNCTION(void) SYS_FreeString(TCHAR *String);
M_PBFUNCTION(void *) PB_NewList(integer ElementSize, void *Object, integer *StructureMap, int ElementType);
M_SYSFUNCTION(void *) SYS_AllocateArray(integer ElementSize, integer NbElements, int Type, integer *StructureMap, pb_array *Address);
M_PBFUNCTION(void *) PB_NewMap(integer ElementSize, int ElementType, integer *StructureMap, void *Address, int HashSize);
M_PBFUNCTION(void *) PB_GetMapElement(void *Map, void *Key);
extern void *PB_StringBase;
extern integer PB_StringBasePosition;
M_SYSFUNCTION(void) SYS_InitString(void);
M_SYSFUNCTION(void) SYS_FreeStrings(void);
// 
M_SYSFUNCTION(void) SYS_PushStringBasePosition(void);
M_SYSFUNCTION(integer) SYS_PopStringBasePosition(void);
M_SYSFUNCTION(integer) SYS_PopStringBasePositionUpdate(void);
M_SYSFUNCTION(void *) SYS_PopStringBasePositionValue(void);
M_SYSFUNCTION(void *) SYS_PopStringBasePositionValueNoUpdate(void);
M_SYSFUNCTION(integer) SYS_GetStringBasePosition(void);
M_SYSFUNCTION(void) SYS_SetStringBasePosition(integer Position);
M_SYSFUNCTION(integer) SYS_StringBasePositionNoPop(void);
M_SYSFUNCTION(char *) SYS_GetStringBase(void);
volatile int PB_DEBUGGER_LineNumber=-1;
volatile int PB_DEBUGGER_IncludedFiles=0;
char *PB_DEBUGGER_FileName=0;
typedef struct s_rangespec s_rangespec;
typedef struct s_serverconfig s_serverconfig;
typedef struct s_rewriterule s_rewriterule;
typedef struct s_rewriteresult s_rewriteresult;
typedef struct s_threaddata s_threaddata;
typedef struct s_httprequest s_httprequest;
// 
static void* f_httpdate(quad v_ts,int sbp);
static void* f_urldecodepath(void* v_s,int sbp);
static void* f_normalizepath(void* v_s,int sbp);
static void* f_getheader(void* v_rawheaders,void* v_name,int sbp);
static integer f_parsehttprequest(void* v_raw,s_httprequest* p_req);
static void* f_statustext(integer v_code,int sbp);
static void* f_buildresponseheaders(integer v_statuscode,void* v_extraheaders,integer v_bodylen,int sbp);
static integer f_sendtextresponse(integer v_connection,integer v_statuscode,void* v_contenttype,void* v_body);
typedef integer (*pf_connectionhandlerproto)(integer v_connection,void* v_raw);
static integer f_connectionthread(s_threaddata* p_data);
static integer f_startserver(integer v_port);
static integer f_stopserver();
static void* f_getmimetype(void* v_extension,int sbp);
static integer f_ensureloginit();
static integer f_openorappend(void* v_path);
static void* f_rotationstamp(int sbp);
static integer f_prunearchives(void* v_logpath);
static integer f_rotatelog(integer p_fh,void* v_logpath);
static integer f_reopenlogs();
static integer f_logrotationthread(integer p_unused);
static void* f_apachedate(quad v_ts,int sbp);
static integer f_openlogfile(void* v_path);
static integer f_closelogfile();
static integer f_openerrorlog(void* v_path);
static integer f_closeerrorlog();
static integer f_logaccess(void* v_ip,void* v_method,void* v_path,void* v_protocol,integer v_status,integer v_bytes,void* v_referer,void* v_useragent);
static integer f_startdailyrotation();
static integer f_stopdailyrotation();
static integer f_logerror(void* v_level,void* v_message);
static void* f_resolveindexfile(void* v_dirpath,void* v_indexlist,int sbp);
static void* f_buildetag(void* v_filepath,int sbp);
static integer f_ishiddenpath(void* v_urlpath,void* v_hiddenpatterns);
static integer f_servefile(integer v_connection,s_serverconfig* p_cfg,s_httprequest* p_req,integer p_bytesout,integer p_statusout);
static void* f_builddirectorylisting(void* v_dirpath,void* v_urlpath,int sbp);
static integer f_parserangeheader(void* v_header,integer v_filesize,s_rangespec* p_range);
static integer f_sendpartialresponse(integer v_connection,void* v_fspath,s_rangespec* p_range,void* v_mimetype,integer v_filesize);
static integer f_loaddefaults(s_serverconfig* p_cfg);
static integer f_parseloglevel(void* v_s);
static integer f_parsecli(s_serverconfig* p_cfg);
static integer f_urllastslash_(void* v_path);
static void* f_urlbasename_(void* v_path,int sbp);
static void* f_urldirname_(void* v_path,int sbp);
static void* f_substplaceholders_(void* v_tmpl,void* v_captured,void* v_g1,void* v_g2,void* v_g3,void* v_g4,void* v_g5,void* v_g6,void* v_g7,void* v_g8,void* v_g9,int sbp);
static integer f_parserule_(void* v_line,s_rewriterule* p_rule);
static integer f_loaddirrulesifneeded_(void* v_dirpath,void* v_docroot);
static integer f_initrewriteengine();
static integer f_cleanuprewriteengine();
static integer f_loadglobalrules(void* v_path);
static integer f_globalrulecount();
static integer f_applyrewrites(void* v_path,void* v_docroot,s_rewriteresult* p_result);
static integer f_openembeddedpack(integer p_packdata,integer v_packsize);
static integer f_serveembeddedfile(integer v_connection,void* v_urlpath);
static integer f_closeembeddedpack();
static integer f_sighuphandler(integer v_signum);
static integer f_installsignalhandlers();
static integer f_removesignalhandlers();
static integer f_writerulefile_(void* v_path,void* v_content);
static integer f_rw_setup();
static integer f_rw_teardown();
static integer f_rewriteengine_init_mutexcreated();
static integer f_rewriteengine_globalrulecount_zeroafterinit();
static integer f_rewriteengine_exactrewrite_match();
static integer f_rewriteengine_exactrewrite_nomatch();
static integer f_rewriteengine_globrewrite_pathplaceholder();
static integer f_rewriteengine_globrewrite_fileplaceholder();
static integer f_rewriteengine_globrewrite_dirplaceholder();
static integer f_rewriteengine_regexrewrite_capturegroup();
static integer f_rewriteengine_regexrewrite_multiplegroups();
static integer f_rewriteengine_exactredir_301();
static integer f_rewriteengine_exactredir_defaultcode302();
static integer f_rewriteengine_globredir_pathsubstitution();
static integer f_rewriteengine_regexredir_capturegroup();
static integer f_rewriteengine_firstrulewins();
static integer f_rewriteengine_comments_ignored();
static integer f_rewriteengine_blanklines_ignored();
static integer f_rewriteengine_invalidverb_ignored();
static integer f_rewriteengine_nomatch_returnsfalse();
static integer f_rewriteengine_loadfromfile_countscorrectly();
static integer f_rewriteengine_perdir_loadsfromdocroot();
static integer f_rewriteengine_globalfirst_perdirsecond();
static integer f_rewriteengine_cleanup_safe();

#pragma pack(1)
typedef struct s_rangespec {
integer f_start;
integer f_end;
integer f_isvalid;
} s_rangespec;
#pragma pack()

#pragma pack(1)
typedef struct s_serverconfig {
integer f_port;
void* f_rootdirectory;
void* f_indexfiles;
integer f_browseenabled;
integer f_spafallback;
void* f_hiddenpatterns;
void* f_logfile;
integer f_maxconnections;
void* f_errorlogfile;
integer f_loglevel;
integer f_logsizemb;
integer f_logkeepcount;
integer f_logdaily;
void* f_pidfile;
integer f_cleanurls;
void* f_rewritefile;
} s_serverconfig;
#pragma pack()

#pragma pack(1)
typedef struct s_rewriterule {
integer f_ruletype;
integer f_matchtype;
void* f_pattern;
void* f_destination;
integer f_code;
integer f_regexhandle;
} s_rewriterule;
#pragma pack()

#pragma pack(1)
typedef struct s_rewriteresult {
integer f_action;
void* f_newpath;
void* f_redirurl;
integer f_redircode;
} s_rewriteresult;
#pragma pack()

#pragma pack(1)
typedef struct s_threaddata {
integer f_client;
void* f_raw;
} s_threaddata;
#pragma pack()

#pragma pack(1)
typedef struct s_httprequest {
void* f_method;
void* f_path;
void* f_querystring;
void* f_version;
void* f_rawheaders;
integer f_contentlength;
void* f_body;
integer f_isvalid;
integer f_errorcode;
} s_httprequest;
#pragma pack()
integer f_exit_(integer) asm("_exit");
integer f_signal(integer,integer) asm("_signal");
static unsigned short _S10[]={0};
static unsigned short _S7[]={37,121,121,121,121,32,37,104,104,58,37,105,105,58,37,115,115,0};
static unsigned short _S63[]={97,112,112,99,97,99,104,101,0};
static unsigned short _S130[]={32,34,0};
static unsigned short _S90[]={102,111,110,116,47,116,116,102,0};
static unsigned short _S291[]={47,120,0};
static unsigned short _S226[]={9,0};
static unsigned short _S176[]={60,47,104,50,62,10,0};
static unsigned short _S8[]={32,71,77,84,0};
static unsigned short _S142[]={52,48,51,32,70,111,114,98,105,100,100,101,110,0};
static unsigned short _S187[]={60,116,100,62,0};
static unsigned short _S80[]={97,118,105,102,0};
static unsigned short _S30[]={72,84,84,80,47,49,46,49,32,0};
static unsigned short _S159[]={86,97,114,121,58,32,65,99,99,101,112,116,45,69,110,99,111,100,105,110,103,13,10,0};
static unsigned short _S205[]={45,45,101,114,114,111,114,45,108,111,103,0};
static unsigned short _S6[]={32,0};
static unsigned short _S298[]={102,111,114,119,97,114,100,32,47,97,32,47,98,10,114,101,119,114,105,116,101,32,47,120,32,47,121,10,0};
static unsigned short _S39[]={116,101,120,116,47,99,115,115,0};
static unsigned short _S133[]={34,0};
static unsigned short _S225[]={35,0};
static unsigned short _S177[]={60,116,97,98,108,101,62,60,116,114,62,60,116,104,62,78,97,109,101,60,47,116,104,62,60,116,104,62,83,105,122,101,60,47,116,104,62,60,116,104,62,77,111,100,105,102,105,101,100,60,47,116,104,62,60,47,116,114,62,10,0};
static unsigned short _S45[]={116,101,120,116,47,99,115,118,0};
static unsigned short _S62[]={97,112,112,108,105,99,97,116,105,111,110,47,109,97,110,105,102,101,115,116,43,106,115,111,110,0};
static unsigned short _S121[]={42,0};
static unsigned short _S29[]={85,110,107,110,111,119,110,0};
static unsigned short _S160[]={13,10,67,97,99,104,101,45,67,111,110,116,114,111,108,58,32,109,97,120,45,97,103,101,61,48,13,10,0};
static unsigned short _S116[]={43,0};
static unsigned short _S3[]={44,0};
static unsigned short _S117[]={45,0};
static unsigned short _S11[]={46,0};
static unsigned short _S9[]={47,0};
static unsigned short _S118[]={48,0};
static unsigned short _S263[]={47,112,114,111,102,105,108,101,47,52,50,0};
static unsigned short _S14[]={58,0};
static unsigned short _S137[]={32,91,0};
static unsigned short _S287[]={47,114,115,115,47,97,116,111,109,0};
static unsigned short _S146[]={66,117,105,108,100,68,105,114,101,99,116,111,114,121,76,105,115,116,105,110,103,32,102,97,105,108,101,100,58,32,0};
static unsigned short _S17[]={63,0};
static unsigned short _S200[]={45,45,112,111,114,116,0};
static unsigned short _S183[]={32,66,0};
static unsigned short _S77[]={105,109,97,103,101,47,120,45,105,99,111,110,0};
static unsigned short _S60[]={97,112,112,108,105,99,97,116,105,111,110,47,119,97,115,109,0};
static unsigned short _S259[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,100,105,114,125,47,123,102,105,108,101,125,32,115,104,111,117,108,100,32,114,101,99,111,110,115,116,114,117,99,116,32,99,97,112,116,117,114,101,32,112,97,116,104,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,119,114,105,116,101,95,68,105,114,80,108,97,99,101,104,111,108,100,101,114,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S202[]={45,45,98,114,111,119,115,101,0};
static unsigned short _S269[]={114,101,100,105,114,32,47,111,108,100,45,112,97,103,101,32,47,110,101,119,45,112,97,103,101,32,51,48,49,10,0};
static unsigned short _S208[]={45,45,108,111,103,45,107,101,101,112,0};
static unsigned short _S239[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,78,111,32,103,108,111,98,97,108,32,114,117,108,101,115,32,108,111,97,100,101,100,32,121,101,116,32,226,128,148,32,99,111,117,110,116,32,115,104,111,117,108,100,32,98,101,32,48,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,97,108,82,117,108,101,67,111,117,110,116,95,90,101,114,111,65,102,116,101,114,73,110,105,116,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S124[]={91,0};
static unsigned short _S140[]={92,0};
static unsigned short _S128[]={93,0};
static unsigned short _S96[]={97,117,100,105,111,47,109,112,101,103,0};
static unsigned short _S290[]={114,101,119,114,105,116,101,32,47,120,32,47,102,105,114,115,116,10,114,101,119,114,105,116,101,32,47,120,32,47,115,101,99,111,110,100,10,0};
static unsigned short _S72[]={115,118,103,0};
static unsigned short _S242[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,69,120,97,99,116,32,114,101,119,114,105,116,101,32,115,104,111,117,108,100,32,109,97,116,99,104,32,47,97,98,111,117,116,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,119,114,105,116,101,95,77,97,116,99,104,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S248[]={114,101,119,114,105,116,101,32,47,98,108,111,103,47,42,32,47,112,111,115,116,115,47,123,112,97,116,104,125,10,0};
static unsigned short _S297[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,66,108,97,110,107,32,108,105,110,101,115,32,115,104,111,117,108,100,32,110,111,116,32,99,114,101,97,116,101,32,114,117,108,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,66,108,97,110,107,76,105,110,101,115,95,73,103,110,111,114,101,100,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S40[]={116,120,116,0};
static unsigned short _S234[]={47,98,108,111,103,0};
static unsigned short _S261[]={47,117,115,101,114,47,52,50,0};
static unsigned short _S53[]={109,106,115,0};
static unsigned short _S282[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,112,97,116,104,125,32,115,104,111,117,108,100,32,115,117,98,115,116,105,116,117,116,101,32,105,110,32,114,101,100,105,114,101,99,116,32,85,82,76,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,100,105,114,95,80,97,116,104,83,117,98,115,116,105,116,117,116,105,111,110,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S229[]={126,0};
static unsigned short _S210[]={45,45,112,105,100,45,102,105,108,101,0};
static unsigned short _S131[]={34,32,0};
static unsigned short _S255[]={47,97,115,115,101,116,115,47,108,111,103,111,46,112,110,103,0};
static unsigned short _S147[]={53,48,48,32,73,110,116,101,114,110,97,108,32,83,101,114,118,101,114,32,69,114,114,111,114,0};
static unsigned short _S273[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,82,101,100,105,114,85,82,76,32,115,104,111,117,108,100,32,98,101,32,47,110,101,119,45,112,97,103,101,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,100,105,114,95,51,48,49,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S84[]={105,109,97,103,101,47,116,105,102,102,0};
static unsigned short _S215[]={123,100,105,114,125,0};
static unsigned short _S122[]={74,97,110,32,70,101,98,32,77,97,114,32,65,112,114,32,77,97,121,32,74,117,110,32,74,117,108,32,65,117,103,32,83,101,112,32,79,99,116,32,78,111,118,32,68,101,99,0};
static unsigned short _S304[]={114,101,119,114,105,116,101,32,47,97,32,47,98,10,114,101,100,105,114,32,47,99,32,47,100,32,51,48,49,10,35,32,115,107,105,112,10,114,101,119,114,105,116,101,32,47,101,32,47,102,10,0};
static unsigned short _S250[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,49,32,40,114,101,119,114,105,116,101,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,119,114,105,116,101,95,80,97,116,104,80,108,97,99,101,104,111,108,100,101,114,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S155[]={67,111,110,116,101,110,116,45,69,110,99,111,100,105,110,103,58,32,103,122,105,112,13,10,0};
static unsigned short _S81[]={105,109,97,103,101,47,97,118,105,102,0};
static unsigned short _S56[]={97,112,112,108,105,99,97,116,105,111,110,47,106,115,111,110,0};
static unsigned short _S299[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,85,110,107,110,111,119,110,32,118,101,114,98,115,32,115,104,111,117,108,100,32,98,101,32,115,107,105,112,112,101,100,59,32,111,110,108,121,32,118,97,108,105,100,32,114,117,108,101,115,32,99,111,117,110,116,101,100,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,73,110,118,97,108,105,100,86,101,114,98,95,73,103,110,111,114,101,100,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S303[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,114,101,115,117,108,116,46,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,48,32,119,104,101,110,32,110,111,32,114,117,108,101,32,109,97,116,99,104,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,78,111,77,97,116,99,104,95,82,101,116,117,114,110,115,70,97,108,115,101,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S271[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,50,32,40,114,101,100,105,114,101,99,116,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,100,105,114,95,51,48,49,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S82[]={116,105,102,0};
static unsigned short _S33[]={67,111,110,110,101,99,116,105,111,110,58,32,99,108,111,115,101,13,10,0};
static unsigned short _S76[]={105,99,111,0};
static unsigned short _S144[]={65,99,99,101,112,116,45,69,110,99,111,100,105,110,103,0};
static unsigned short _S48[]={105,99,115,0};
static unsigned short _S182[]={60,116,100,62,45,60,47,116,100,62,60,116,100,62,45,60,47,116,100,62,60,47,116,114,62,10,0};
static unsigned short _S57[]={106,115,111,110,108,100,0};
static unsigned short _S230[]={114,101,119,114,105,116,101,46,99,111,110,102,0};
static unsigned short _S257[]={114,101,119,114,105,116,101,32,47,115,116,97,116,105,99,47,42,32,47,97,115,115,101,116,115,47,123,100,105,114,125,47,123,102,105,108,101,125,10,0};
static unsigned short _S68[]={106,112,101,103,0};
static unsigned short _S216[]={123,114,101,46,49,125,0};
static unsigned short _S262[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,49,32,40,114,101,119,114,105,116,101,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,119,114,105,116,101,95,67,97,112,116,117,114,101,71,114,111,117,112,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S21[]={77,111,118,101,100,32,80,101,114,109,97,110,101,110,116,108,121,0};
static unsigned short _S170[]={116,97,98,108,101,123,98,111,114,100,101,114,45,99,111,108,108,97,112,115,101,58,99,111,108,108,97,112,115,101,59,119,105,100,116,104,58,49,48,48,37,125,0};
static unsigned short _S123[]={37,109,109,0};
static unsigned short _S20[]={80,97,114,116,105,97,108,32,67,111,110,116,101,110,116,0};
static unsigned short _S236[]={80,117,114,101,85,110,105,116,0};
static unsigned short _S201[]={45,45,114,111,111,116,0};
static unsigned short _S129[]={32,45,32,45,32,0};
static unsigned short _S247[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,69,120,97,99,116,32,114,101,119,114,105,116,101,32,115,104,111,117,108,100,32,78,79,84,32,109,97,116,99,104,32,47,99,111,110,116,97,99,116,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,119,114,105,116,101,95,78,111,77,97,116,99,104,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S217[]={123,114,101,46,50,125,0};
static unsigned short _S186[]={60,47,97,62,60,47,116,100,62,0};
static unsigned short _S79[]={105,109,97,103,101,47,98,109,112,0};
static unsigned short _S268[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,114,101,46,49,125,32,97,110,100,32,123,114,101,46,50,125,32,115,104,111,117,108,100,32,115,119,97,112,32,99,111,114,114,101,99,116,108,121,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,119,114,105,116,101,95,77,117,108,116,105,112,108,101,71,114,111,117,112,115,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S135[]={119,97,114,110,0};
static unsigned short _S16[]={72,84,84,80,47,0};
static unsigned short _S245[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,78,101,119,80,97,116,104,32,115,104,111,117,108,100,32,98,101,32,47,97,98,111,117,116,46,104,116,109,108,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,119,114,105,116,101,95,77,97,116,99,104,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S312[]={114,101,119,114,105,116,101,32,47,98,108,111,103,47,104,101,108,108,111,32,47,112,101,114,100,105,114,45,116,97,114,103,101,116,10,0};
static unsigned short _S295[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,67,111,109,109,101,110,116,32,108,105,110,101,115,32,115,104,111,117,108,100,32,110,111,116,32,99,114,101,97,116,101,32,114,117,108,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,67,111,109,109,101,110,116,115,95,73,103,110,111,114,101,100,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S241[]={47,97,98,111,117,116,0};
static unsigned short _S314[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,71,108,111,98,97,108,32,114,117,108,101,115,32,115,104,111,117,108,100,32,116,97,107,101,32,112,114,105,111,114,105,116,121,32,111,118,101,114,32,112,101,114,45,100,105,114,32,114,117,108,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,97,108,70,105,114,115,116,95,80,101,114,68,105,114,83,101,99,111,110,100,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S209[]={45,45,110,111,45,108,111,103,45,100,97,105,108,121,0};
static unsigned short _S218[]={123,114,101,46,51,125,0};
static unsigned short _S47[]={116,101,120,116,47,109,97,114,107,100,111,119,110,59,32,99,104,97,114,115,101,116,61,117,116,102,45,56,0};
static unsigned short _S99[]={119,97,118,0};
static unsigned short _S151[]={52,48,52,32,78,111,116,32,70,111,117,110,100,0};
static unsigned short _S136[]={105,110,102,111,0};
static unsigned short _S1[]={83,117,110,44,77,111,110,44,84,117,101,44,87,101,100,44,84,104,117,44,70,114,105,44,83,97,116,0};
static unsigned short _S258[]={47,97,115,115,101,116,115,47,105,109,103,47,108,111,103,111,46,112,110,103,0};
static unsigned short _S148[]={68,105,114,101,99,116,111,114,121,32,108,105,115,116,105,110,103,32,100,105,115,97,98,108,101,100,58,32,0};
static unsigned short _S163[]={67,97,110,110,111,116,32,111,112,101,110,32,102,105,108,101,58,32,0};
static unsigned short _S69[]={105,109,97,103,101,47,106,112,101,103,0};
static unsigned short _S141[]={70,111,114,98,105,100,100,101,110,58,32,0};
static unsigned short _S36[]={104,116,109,0};
static unsigned short _S293[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,70,105,114,115,116,32,109,97,116,99,104,105,110,103,32,114,117,108,101,32,115,104,111,117,108,100,32,119,105,110,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,70,105,114,115,116,82,117,108,101,87,105,110,115,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S59[]={119,97,115,109,0};
static unsigned short _S31[]={83,101,114,118,101,114,58,32,80,117,114,101,83,105,109,112,108,101,72,84,84,80,83,101,114,118,101,114,47,49,46,53,46,48,13,10,0};
static unsigned short _S207[]={45,45,108,111,103,45,115,105,122,101,0};
static unsigned short _S158[]={67,97,99,104,101,45,67,111,110,116,114,111,108,58,32,109,97,120,45,97,103,101,61,48,13,10,0};
static unsigned short _S113[]={112,100,102,0};
static unsigned short _S196[]={119,119,119,114,111,111,116,0};
static unsigned short _S166[]={60,116,105,116,108,101,62,73,110,100,101,120,32,111,102,32,0};
static unsigned short _S149[]={46,104,116,109,108,0};
static unsigned short _S110[]={97,112,112,108,105,99,97,116,105,111,110,47,103,122,105,112,0};
static unsigned short _S175[]={60,104,50,62,73,110,100,101,120,32,111,102,32,0};
static unsigned short _S219[]={123,114,101,46,52,125,0};
static unsigned short _S164[]={60,33,68,79,67,84,89,80,69,32,104,116,109,108,62,10,0};
static unsigned short _S71[]={105,109,97,103,101,47,103,105,102,0};
static unsigned short _S173[]={97,123,116,101,120,116,45,100,101,99,111,114,97,116,105,111,110,58,110,111,110,101,125,97,58,104,111,118,101,114,123,116,101,120,116,45,100,101,99,111,114,97,116,105,111,110,58,117,110,100,101,114,108,105,110,101,125,0};
static unsigned short _S252[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,112,97,116,104,125,32,115,104,111,117,108,100,32,98,101,32,116,104,101,32,103,108,111,98,32,99,97,112,116,117,114,101,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,119,114,105,116,101,95,80,97,116,104,80,108,97,99,101,104,111,108,100,101,114,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S174[]={60,47,115,116,121,108,101,62,60,47,104,101,97,100,62,60,98,111,100,121,62,10,0};
static unsigned short _S119[]={37,121,121,121,121,37,109,109,37,100,100,0};
static unsigned short _S162[]={79,117,116,32,111,102,32,109,101,109,111,114,121,32,115,101,114,118,105,110,103,58,32,0};
static unsigned short _S93[]={101,111,116,0};
static unsigned short _S104[]={118,105,100,101,111,47,119,101,98,109,0};
static unsigned short _S95[]={109,112,51,0};
static unsigned short _S112[]={97,112,112,108,105,99,97,116,105,111,110,47,120,45,116,97,114,0};
static unsigned short _S101[]={109,112,52,0};
static unsigned short _S100[]={97,117,100,105,111,47,119,97,118,0};
static unsigned short _S18[]={99,111,110,116,101,110,116,45,108,101,110,103,116,104,0};
static unsigned short _S244[]={47,97,98,111,117,116,46,104,116,109,108,0};
static unsigned short _S27[]={82,97,110,103,101,32,78,111,116,32,83,97,116,105,115,102,105,97,98,108,101,0};
static unsigned short _S311[]={114,101,119,114,105,116,101,32,47,98,108,111,103,47,104,101,108,108,111,32,47,103,108,111,98,97,108,45,116,97,114,103,101,116,10,0};
static unsigned short _S107[]={122,105,112,0};
static unsigned short _S308[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,80,101,114,45,100,105,114,32,114,101,119,114,105,116,101,46,99,111,110,102,32,115,104,111,117,108,100,32,98,101,32,102,111,117,110,100,32,97,110,100,32,97,112,112,108,105,101,100,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,80,101,114,68,105,114,95,76,111,97,100,115,70,114,111,109,68,111,99,82,111,111,116,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S214[]={123,102,105,108,101,125,0};
static unsigned short _S190[]={60,47,116,97,98,108,101,62,10,0};
static unsigned short _S220[]={123,114,101,46,53,125,0};
static unsigned short _S55[]={106,115,111,110,0};
static unsigned short _S167[]={60,47,116,105,116,108,101,62,10,0};
static unsigned short _S109[]={103,122,0};
static unsigned short _S41[]={116,101,120,116,47,112,108,97,105,110,59,32,99,104,97,114,115,101,116,61,117,116,102,45,56,0};
static unsigned short _S192[]={60,47,98,111,100,121,62,60,47,104,116,109,108,62,0};
static unsigned short _S180[]={39,62,0};
static unsigned short _S280[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,50,32,40,114,101,100,105,114,101,99,116,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,100,105,114,95,80,97,116,104,83,117,98,115,116,105,116,117,116,105,111,110,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S91[]={111,116,102,0};
static unsigned short _S289[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,82,101,100,105,114,67,111,100,101,32,115,104,111,117,108,100,32,98,101,32,51,48,49,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,100,105,114,95,67,97,112,116,117,114,101,71,114,111,117,112,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S277[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,79,109,105,116,116,101,100,32,114,101,100,105,114,101,99,116,32,99,111,100,101,32,115,104,111,117,108,100,32,100,101,102,97,117,108,116,32,116,111,32,51,48,50,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,100,105,114,95,68,101,102,97,117,108,116,67,111,100,101,51,48,50,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S246[]={47,99,111,110,116,97,99,116,0};
static unsigned short _S152[]={70,105,108,101,32,110,111,116,32,102,111,117,110,100,58,32,0};
static unsigned short _S156[]={69,84,97,103,58,32,0};
static unsigned short _S305[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,70,105,108,101,32,119,105,116,104,32,51,32,118,97,108,105,100,32,114,117,108,101,115,32,40,49,32,99,111,109,109,101,110,116,41,32,115,104,111,117,108,100,32,108,111,97,100,32,51,32,114,117,108,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,76,111,97,100,70,114,111,109,70,105,108,101,95,67,111,117,110,116,115,67,111,114,114,101,99,116,108,121,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S143[]={82,97,110,103,101,0};
static unsigned short _S221[]={123,114,101,46,54,125,0};
static unsigned short _S51[]={116,101,120,116,47,118,99,97,114,100,0};
static unsigned short _S24[]={66,97,100,32,82,101,113,117,101,115,116,0};
static unsigned short _S50[]={118,99,102,0};
static unsigned short _S102[]={118,105,100,101,111,47,109,112,52,0};
static unsigned short _S267[]={47,57,57,47,112,111,115,116,0};
static unsigned short _S283[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,82,101,100,105,114,67,111,100,101,32,115,104,111,117,108,100,32,98,101,32,51,48,49,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,100,105,114,95,80,97,116,104,83,117,98,115,116,105,116,117,116,105,111,110,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S222[]={123,114,101,46,55,125,0};
static unsigned short _S138[]={93,32,91,112,105,100,32,0};
static unsigned short _S238[]={13,70,105,108,101,58,32,47,85,115,101,114,115,47,119,111,114,97,106,101,100,116,47,80,117,114,101,66,97,115,105,99,95,80,114,111,106,101,99,116,115,47,80,117,114,101,83,105,109,112,108,101,72,84,84,80,83,101,114,118,101,114,47,116,101,115,116,115,47,116,101,115,116,95,114,101,119,114,105,116,101,46,112,98,0};
static unsigned short _S66[]={105,109,97,103,101,47,112,110,103,0};
static unsigned short _S58[]={97,112,112,108,105,99,97,116,105,111,110,47,108,100,43,106,115,111,110,0};
static unsigned short _S165[]={60,104,116,109,108,62,60,104,101,97,100,62,60,109,101,116,97,32,99,104,97,114,115,101,116,61,39,117,116,102,45,56,39,62,10,0};
static unsigned short _S120[]={37,104,104,37,105,105,37,115,115,0};
static unsigned short _S157[]={76,97,115,116,45,77,111,100,105,102,105,101,100,58,32,0};
static unsigned short _S313[]={47,103,108,111,98,97,108,45,116,97,114,103,101,116,0};
static unsigned short _S28[]={73,110,116,101,114,110,97,108,32,83,101,114,118,101,114,32,69,114,114,111,114,0};
static unsigned short _S194[]={98,121,116,101,115,32,0};
static unsigned short _S275[]={114,101,100,105,114,32,47,111,108,100,32,47,110,101,119,10,0};
static unsigned short _S199[]={110,111,110,101,0};
static unsigned short _S228[]={114,101,100,105,114,0};
static unsigned short _S64[]={116,101,120,116,47,99,97,99,104,101,45,109,97,110,105,102,101,115,116,0};
static unsigned short _S92[]={102,111,110,116,47,111,116,102,0};
static unsigned short _S223[]={123,114,101,46,56,125,0};
static unsigned short _S52[]={106,115,0};
static unsigned short _S193[]={98,121,116,101,115,61,0};
static unsigned short _S86[]={102,111,110,116,47,119,111,102,102,0};
static unsigned short _S153[]={103,122,105,112,0};
static unsigned short _S188[]={60,47,116,100,62,0};
static unsigned short _S181[]={47,60,47,97,62,60,47,116,100,62,0};
static unsigned short _S73[]={105,109,97,103,101,47,115,118,103,43,120,109,108,0};
static unsigned short _S213[]={123,112,97,116,104,125,0};
static unsigned short _S284[]={114,101,100,105,114,32,126,47,102,101,101,100,40,46,42,41,32,47,114,115,115,123,114,101,46,49,125,32,51,48,49,10,0};
static unsigned short _S22[]={70,111,117,110,100,0};
static unsigned short _S61[]={119,101,98,109,97,110,105,102,101,115,116,0};
static unsigned short _S306[]={114,101,119,114,105,116,101,32,47,98,108,111,103,47,104,101,108,108,111,32,47,98,108,111,103,47,104,101,108,108,111,46,104,116,109,108,10,0};
static unsigned short _S125[]={37,100,100,0};
static unsigned short _S78[]={98,109,112,0};
static unsigned short _S253[]={114,101,119,114,105,116,101,32,47,115,116,97,116,105,99,47,42,32,47,97,115,115,101,116,115,47,123,102,105,108,101,125,10,0};
static unsigned short _S227[]={114,101,119,114,105,116,101,0};
static unsigned short _S296[]={10,32,32,10,114,101,119,114,105,116,101,32,47,97,32,47,98,10,10,0};
static unsigned short _S97[]={111,103,103,0};
static unsigned short _S307[]={47,98,108,111,103,47,104,101,108,108,111,0};
static unsigned short _S232[]={112,115,104,115,95,114,119,95,116,101,115,116,0};
static unsigned short _S5[]={37,100,100,32,0};
static unsigned short _S105[]={111,103,118,0};
static unsigned short _S171[]={116,104,44,116,100,123,116,101,120,116,45,97,108,105,103,110,58,108,101,102,116,59,112,97,100,100,105,110,103,58,52,112,120,32,49,50,112,120,59,98,111,114,100,101,114,45,98,111,116,116,111,109,58,49,112,120,32,115,111,108,105,100,32,35,100,100,100,125,0};
static unsigned short _S145[]={73,102,45,78,111,110,101,45,77,97,116,99,104,0};
static unsigned short _S235[]={47,98,108,111,103,47,114,101,119,114,105,116,101,46,99,111,110,102,0};
static unsigned short _S224[]={123,114,101,46,57,125,0};
static unsigned short _S178[]={60,116,114,62,60,116,100,62,60,97,32,104,114,101,102,61,39,46,46,47,39,62,46,46,47,60,47,97,62,60,47,116,100,62,60,116,100,62,45,60,47,116,100,62,60,116,100,62,45,60,47,116,100,62,60,47,116,114,62,10,0};
static unsigned short _S111[]={116,97,114,0};
static unsigned short _S231[]={105,110,100,101,120,46,104,116,109,108,0};
static unsigned short _S114[]={97,112,112,108,105,99,97,116,105,111,110,47,112,100,102,0};
static unsigned short _S301[]={47,110,111,109,97,116,99,104,0};
static unsigned short _S184[]={32,75,66,0};
static unsigned short _S243[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,49,32,40,114,101,119,114,105,116,101,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,119,114,105,116,101,95,77,97,116,99,104,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S204[]={45,45,108,111,103,0};
static unsigned short _S279[]={47,100,111,119,110,108,111,97,100,115,47,114,101,112,111,114,116,46,112,100,102,0};
static unsigned short _S191[]={60,104,114,62,60,115,109,97,108,108,62,80,117,114,101,83,105,109,112,108,101,72,84,84,80,83,101,114,118,101,114,32,118,49,46,53,46,48,60,47,115,109,97,108,108,62,10,0};
static unsigned short _S310[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,80,101,114,45,100,105,114,32,114,117,108,101,32,115,104,111,117,108,100,32,114,101,119,114,105,116,101,32,112,97,116,104,32,99,111,114,114,101,99,116,108,121,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,80,101,114,68,105,114,95,76,111,97,100,115,70,114,111,109,68,111,99,82,111,111,116,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S37[]={116,101,120,116,47,104,116,109,108,59,32,99,104,97,114,115,101,116,61,117,116,102,45,56,0};
static unsigned short _S4[]={44,32,0};
static unsigned short _S276[]={47,111,108,100,0};
static unsigned short _S87[]={119,111,102,102,50,0};
static unsigned short _S197[]={105,110,100,101,120,46,104,116,109,108,44,105,110,100,101,120,46,104,116,109,0};
static unsigned short _S154[]={46,103,122,0};
static unsigned short _S139[]={93,32,0};
static unsigned short _S43[]={116,101,120,116,47,120,109,108,59,32,99,104,97,114,115,101,116,61,117,116,102,45,56,0};
static unsigned short _S2[]={74,97,110,44,70,101,98,44,77,97,114,44,65,112,114,44,77,97,121,44,74,117,110,44,74,117,108,44,65,117,103,44,83,101,112,44,79,99,116,44,78,111,118,44,68,101,99,0};
static unsigned short _S195[]={67,111,110,116,101,110,116,45,82,97,110,103,101,58,32,0};
static unsigned short _S274[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,82,101,100,105,114,67,111,100,101,32,115,104,111,117,108,100,32,98,101,32,51,48,49,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,69,120,97,99,116,82,101,100,105,114,95,51,48,49,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S288[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,114,101,46,49,125,32,115,104,111,117,108,100,32,99,97,112,116,117,114,101,32,47,97,116,111,109,32,97,102,116,101,114,32,47,102,101,101,100,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,100,105,114,95,67,97,112,116,117,114,101,71,114,111,117,112,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S98[]={97,117,100,105,111,47,111,103,103,0};
static unsigned short _S32[]={67,111,110,116,101,110,116,45,76,101,110,103,116,104,58,32,0};
static unsigned short _S108[]={97,112,112,108,105,99,97,116,105,111,110,47,122,105,112,0};
static unsigned short _S132[]={34,32,34,0};
static unsigned short _S70[]={103,105,102,0};
static unsigned short _S265[]={114,101,119,114,105,116,101,32,126,47,40,91,97,45,122,93,43,41,47,40,91,48,45,57,93,43,41,32,47,123,114,101,46,50,125,47,123,114,101,46,49,125,10,0};
static unsigned short _S233[]={112,115,104,115,95,114,119,95,103,108,111,98,97,108,46,99,111,110,102,0};
static unsigned short _S237[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,103,95,82,101,119,114,105,116,101,77,117,116,101,120,32,115,104,111,117,108,100,32,98,101,32,110,111,110,45,122,101,114,111,32,97,102,116,101,114,32,73,110,105,116,82,101,119,114,105,116,101,69,110,103,105,110,101,40,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,73,110,105,116,95,77,117,116,101,120,67,114,101,97,116,101,100,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S278[]={114,101,100,105,114,32,47,100,111,119,110,108,111,97,100,115,47,42,32,47,102,105,108,101,115,47,123,112,97,116,104,125,32,51,48,49,10,0};
static unsigned short _S26[]={78,111,116,32,70,111,117,110,100,0};
static unsigned short _S23[]={78,111,116,32,77,111,100,105,102,105,101,100,0};
static unsigned short _S46[]={109,100,0};
static unsigned short _S85[]={119,111,102,102,0};
static unsigned short _S103[]={119,101,98,109,0};
static unsigned short _S198[]={46,103,105,116,44,46,101,110,118,44,46,68,83,95,83,116,111,114,101,0};
static unsigned short _S106[]={118,105,100,101,111,47,111,103,103,0};
static unsigned short _S74[]={119,101,98,112,0};
static unsigned short _S13[]={13,10,0};
static unsigned short _S254[]={47,115,116,97,116,105,99,47,105,109,103,47,108,111,103,111,46,112,110,103,0};
static unsigned short _S211[]={45,45,99,108,101,97,110,45,117,114,108,115,0};
static unsigned short _S35[]={104,116,109,108,0};
static unsigned short _S315[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,67,108,101,97,110,117,112,82,101,119,114,105,116,101,69,110,103,105,110,101,32,111,110,32,97,108,114,101,97,100,121,45,99,108,101,97,110,32,115,116,97,116,101,32,115,104,111,117,108,100,32,110,111,116,32,99,114,97,115,104,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,67,108,101,97,110,117,112,95,83,97,102,101,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S185[]={32,77,66,0};
static unsigned short _S172[]={116,104,123,98,97,99,107,103,114,111,117,110,100,58,35,102,52,102,52,102,52,125,0};
static unsigned short _S302[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,112,112,108,121,82,101,119,114,105,116,101,115,32,115,104,111,117,108,100,32,114,101,116,117,114,110,32,35,70,97,108,115,101,32,119,104,101,110,32,110,111,32,114,117,108,101,32,109,97,116,99,104,101,115,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,78,111,77,97,116,99,104,95,82,101,116,117,114,110,115,70,97,108,115,101,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S189[]={60,47,116,100,62,60,47,116,114,62,10,0};
static unsigned short _S300[]={114,101,119,114,105,116,101,32,47,115,112,101,99,105,102,105,99,32,47,116,97,114,103,101,116,10,0};
static unsigned short _S67[]={106,112,103,0};
static unsigned short _S270[]={47,111,108,100,45,112,97,103,101,0};
static unsigned short _S89[]={116,116,102,0};
static unsigned short _S212[]={45,45,114,101,119,114,105,116,101,0};
static unsigned short _S54[]={97,112,112,108,105,99,97,116,105,111,110,47,106,97,118,97,115,99,114,105,112,116,0};
static unsigned short _S249[]={47,98,108,111,103,47,104,101,108,108,111,45,119,111,114,108,100,0};
static unsigned short _S25[]={70,111,114,98,105,100,100,101,110,0};
static unsigned short _S206[]={45,45,108,111,103,45,108,101,118,101,108,0};
static unsigned short _S127[]={37,104,104,58,37,105,105,58,37,115,115,0};
static unsigned short _S49[]={116,101,120,116,47,99,97,108,101,110,100,97,114,0};
static unsigned short _S12[]={46,46,0};
static unsigned short _S292[]={47,102,105,114,115,116,0};
static unsigned short _S161[]={67,111,110,116,101,110,116,45,82,97,110,103,101,58,32,98,121,116,101,115,32,42,47,0};
static unsigned short _S285[]={47,102,101,101,100,47,97,116,111,109,0};
static unsigned short _S94[]={97,112,112,108,105,99,97,116,105,111,110,47,118,110,100,46,109,115,45,102,111,110,116,111,98,106,101,99,116,0};
static unsigned short _S179[]={60,116,114,62,60,116,100,62,60,97,32,104,114,101,102,61,39,0};
static unsigned short _S88[]={102,111,110,116,47,119,111,102,102,50,0};
static unsigned short _S38[]={99,115,115,0};
static unsigned short _S203[]={45,45,115,112,97,0};
static unsigned short _S126[]={37,121,121,121,121,0};
static unsigned short _S44[]={99,115,118,0};
static unsigned short _S134[]={101,114,114,111,114,0};
static unsigned short _S264[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,114,101,46,49,125,32,115,104,111,117,108,100,32,98,101,32,116,104,101,32,102,105,114,115,116,32,99,97,112,116,117,114,101,32,103,114,111,117,112,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,119,114,105,116,101,95,67,97,112,116,117,114,101,71,114,111,117,112,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S34[]={67,111,110,116,101,110,116,45,84,121,112,101,58,32,0};
static unsigned short _S42[]={120,109,108,0};
static unsigned short _S294[]={35,32,84,104,105,115,32,105,115,32,97,32,99,111,109,109,101,110,116,10,114,101,119,114,105,116,101,32,47,97,32,47,98,10,0};
static unsigned short _S19[]={79,75,0};
static unsigned short _S115[]={97,112,112,108,105,99,97,116,105,111,110,47,111,99,116,101,116,45,115,116,114,101,97,109,0};
static unsigned short _S266[]={47,112,111,115,116,47,57,57,0};
static unsigned short _S309[]={47,98,108,111,103,47,104,101,108,108,111,46,104,116,109,108,0};
static unsigned short _S286[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,65,99,116,105,111,110,32,115,104,111,117,108,100,32,98,101,32,50,32,40,114,101,100,105,114,101,99,116,41,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,82,101,103,101,120,82,101,100,105,114,95,67,97,112,116,117,114,101,71,114,111,117,112,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S168[]={60,115,116,121,108,101,62,0};
static unsigned short _S272[]={47,110,101,119,45,112,97,103,101,0};
static unsigned short _S251[]={47,112,111,115,116,115,47,104,101,108,108,111,45,119,111,114,108,100,0};
static unsigned short _S256[]={65,115,115,101,114,116,40,41,32,102,97,105,108,101,100,33,13,13,77,101,115,115,97,103,101,58,32,123,102,105,108,101,125,32,115,104,111,117,108,100,32,98,101,32,98,97,115,101,110,97,109,101,32,111,102,32,99,97,112,116,117,114,101,13,80,114,111,99,101,100,117,114,101,58,32,82,101,119,114,105,116,101,69,110,103,105,110,101,95,71,108,111,98,82,101,119,114,105,116,101,95,70,105,108,101,80,108,97,99,101,104,111,108,100,101,114,40,41,13,76,105,110,101,58,32,0};
static unsigned short _S75[]={105,109,97,103,101,47,119,101,98,112,0};
static unsigned short _S169[]={98,111,100,121,123,102,111,110,116,45,102,97,109,105,108,121,58,109,111,110,111,115,112,97,99,101,59,112,97,100,100,105,110,103,58,49,101,109,125,0};
static unsigned short _S260[]={114,101,119,114,105,116,101,32,126,47,117,115,101,114,47,40,91,48,45,57,93,43,41,32,47,112,114,111,102,105,108,101,47,123,114,101,46,49,125,10,0};
static unsigned short _S281[]={47,102,105,108,101,115,47,114,101,112,111,114,116,46,112,100,102,0};
static unsigned short _S150[]={78,111,116,32,102,111,117,110,100,32,40,83,80,65,58,32,110,111,32,114,111,111,116,32,105,110,100,101,120,41,58,32,0};
static unsigned short _S65[]={112,110,103,0};
static unsigned short _S83[]={116,105,102,102,0};
static unsigned short _S15[]={13,10,13,10,0};
static unsigned short _S240[]={114,101,119,114,105,116,101,32,47,97,98,111,117,116,32,47,97,98,111,117,116,46,104,116,109,108,10,0};

static integer ms_s[]={0,-1};
static integer ms_serverconfig[];
static integer ms_rewriterule[];
static integer ms_rewriteresult[];
static integer ms_threaddata[];
static integer ms_httprequest[];
static integer ms_serverconfig[]={
8,
16,
40,
48,
64,
104,
120,
-1};
static integer ms_rewriterule[]={
16,
24,
-1};
static integer ms_rewriteresult[]={
8,
16,
-1};
static integer ms_threaddata[]={
8,
-1};
static integer ms_httprequest[]={
0,
8,
16,
24,
32,
48,
-1};
static pb_array a_g_gr_ruletype={0};
static pb_array a_g_gr_matchtype={0};
static pb_array a_g_gr_pattern={0};
static pb_array a_g_gr_destination={0};
static pb_array a_g_gr_code={0};
static pb_array a_g_gr_regexhandle={0};
static pb_array a_g_dc_dirpath={0};
static pb_array a_g_dc_filemtime={0};
static pb_array a_g_dc_rulecount={0};
static pb_array a_g_dr_ruletype={0};
static pb_array a_g_dr_matchtype={0};
static pb_array a_g_dr_pattern={0};
static pb_array a_g_dr_destination={0};
static pb_array a_g_dr_code={0};
static pb_array a_g_dr_regexhandle={0};
static pb_list t_g_closelist={0};
static void* g_g_tmpconf=0;
static volatile integer g_g_logfile=0;
static integer g_g_reopenlogs=0;
static void* g_g_errorlogpath=0;
static integer g_g_closemutex=0;
static pf_connectionhandlerproto g_g_handler=0;
static integer g_g_rotationthread=0;
static integer g_g_logmaxbytes=0;
static void* g_g_logpath=0;
static void* g_g_tzoffset=0;
static integer g_g_gr_count=0;
static integer g_g_logmutex=0;
static integer g_g_loglevel=0;
static integer g_g_serverpid=0;
static integer g_g_running=0;
static integer g_g_rewritemutex=0;
static integer g_g_stoprotation=0;
static integer g_g_embeddedpack=0;
static volatile integer g_g_errorlogfile=0;
static integer g_g_dc_count=0;
static integer g_g_logkeepcount=0;
static void* g_g_tmprwdir=0;
static integer g_g_rotationseq=0;
// 
// 
// Procedure.i ParseRule_(line.s, *rule.RewriteRule)
static integer f_parserule_(void* v_line,s_rewriterule* p_rule) {
integer r=0;
SYS_FastAllocateString4(&v_line,v_line);
integer v_tcount=0;
integer v_ruletype=0;
integer v_regexhandle=0;
void* v_tok=0;
integer v_matchtype=0;
void* v_verb=0;
void* v_t0=0;
void* v_t1=0;
void* v_t2=0;
void* v_t3=0;
integer v_ti=0;
integer v_tn=0;
void* v_cleanpat=0;
integer v_code=0;
// line = Trim(line)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Trim(v_line,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_line,SYS_PopStringBasePosition());
// If Len(line) = 0 Or Left(line, 1) = "#" : ProcedureReturn #False : EndIf
integer r0=PB_Len(v_line);
integer c3=0;
if ((r0==0)) { goto ok3; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_line,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S225;
if (SYS_StringEqual(p1,p0)) { goto ok3; }
goto no3;
ok3:
c3=1;
no3:;
if (!(c3)) { goto no2; }
r=0LL;
goto end;
no2:;
// 
// 
// line = ReplaceString(line, Chr(9), " ")
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_line,_S226,_S6,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_line,SYS_PopStringBasePosition());
// Protected t0.s = "", t1.s = "", t2.s = "", t3.s = ""
SYS_FastAllocateStringFree4(&v_t0,_S10);
SYS_FastAllocateStringFree4(&v_t1,_S10);
SYS_FastAllocateStringFree4(&v_t2,_S10);
SYS_FastAllocateStringFree4(&v_t3,_S10);
// Protected tcount.i = 0
v_tcount=0;
// Protected ti.i, tn.i = CountString(line, " ") + 1;
integer r1=PB_CountString(v_line,_S6);
v_tn=(r1+1);
// Protected tok.s;
// For ti = 1 To tn
v_ti=1;
while(1) {
if (!(((integer)v_tn>=v_ti))) { break; }
// tok = Trim(StringField(line, ti, " "))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_line,v_ti,_S6,SYS_PopStringBasePosition());
void* p2=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_Trim(p2,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_tok,SYS_PopStringBasePosition());
// If Len(tok) > 0
integer r2=PB_Len(v_tok);
if (!((r2>0))) { goto no7; }
// Select tcount
quad pb_select7=v_tcount;
// Case 0 : t0 = tok
if (pb_select7==0LL) {
SYS_PushStringBasePosition();
SYS_CopyString(v_tok);
SYS_AllocateString4(&v_t0,SYS_PopStringBasePosition());
// Case 1 : t1 = tok
goto endselect7;}
if (pb_select7==1LL) {
SYS_PushStringBasePosition();
SYS_CopyString(v_tok);
SYS_AllocateString4(&v_t1,SYS_PopStringBasePosition());
// Case 2 : t2 = tok
goto endselect7;}
if (pb_select7==2LL) {
SYS_PushStringBasePosition();
SYS_CopyString(v_tok);
SYS_AllocateString4(&v_t2,SYS_PopStringBasePosition());
// Case 3 : t3 = tok
goto endselect7;}
if (pb_select7==3LL) {
SYS_PushStringBasePosition();
SYS_CopyString(v_tok);
SYS_AllocateString4(&v_t3,SYS_PopStringBasePosition());
// EndSelect
}
endselect7:;
// tcount + 1
v_tcount=(v_tcount+1);
// If tcount >= 4 : Break : EndIf
if (!((v_tcount>=4LL))) { goto no9; }
goto il_next5;
no9:;
// EndIf
no7:;
// Next
next4:
v_ti+=1;
}
il_next5:;
// If tcount < 3 : ProcedureReturn #False : EndIf
if (!((v_tcount<3LL))) { goto no11; }
r=0LL;
goto end;
no11:;
// 
// Protected verb.s = LCase(t0)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_LCase(v_t0,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_verb,SYS_PopStringBasePosition());
// Protected ruleType.i;
// Select verb
void *pb_select8=0;
SYS_FastAllocateString4(&pb_select8,v_verb);
// Case "rewrite" : ruleType = #RULE_REWRITE
if (SYS_StringEqual(pb_select8,_S227)) {
v_ruletype=0;
// Case "redir"   : ruleType = #RULE_REDIR
goto endselect8;}
if (SYS_StringEqual(pb_select8,_S228)) {
v_ruletype=1;
// Default        : ProcedureReturn #False
goto endselect8;}
SYS_FreeString(pb_select8);
r=0LL;
goto end;
// EndSelect
endselect8:;
SYS_FreeString(pb_select8);
// 
// Protected code.i = 0
v_code=0;
// If ruleType = #RULE_REDIR
if (!((v_ruletype==1LL))) { goto no13; }
// code = Val(t3)
quad r3=PB_Val(v_t3);
v_code=r3;
// If code = 0 : code = 302 : EndIf
if (!((v_code==0LL))) { goto no15; }
v_code=302;
no15:;
// EndIf
no13:;
// 
// Protected matchType.i;
// Protected cleanPat.s;
// If Left(t1, 1) = "~"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_t1,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p3=SYS_PopStringBasePositionValue();
void* p4=_S229;
if (!(SYS_StringEqual(p4,p3))) { goto no17; }
// matchType = #MATCH_REGEX
v_matchtype=2;
// cleanPat  = Mid(t1, 2)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Mid(v_t1,2LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_cleanpat,SYS_PopStringBasePosition());
// ElseIf Right(t1, 1) = "*"
goto endif16;
no17:;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_t1,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p5=SYS_PopStringBasePositionValue();
void* p6=_S121;
if (!(SYS_StringEqual(p6,p5))) { goto no18; }
ok18:;
// matchType = #MATCH_GLOB
v_matchtype=1;
// cleanPat  = Left(t1, Len(t1) - 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r4=PB_Len(v_t1);
integer p7=(integer)(r4+-1);
PB_Left(v_t1,p7,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_cleanpat,SYS_PopStringBasePosition());
// Else
goto endif16;
no18:;
// matchType = #MATCH_EXACT
v_matchtype=0;
// cleanPat  = t1
SYS_PushStringBasePosition();
SYS_CopyString(v_t1);
SYS_AllocateString4(&v_cleanpat,SYS_PopStringBasePosition());
// EndIf
endif16:;
// 
// Protected regexHandle.i = 0
v_regexhandle=0;
// If matchType = #MATCH_REGEX
if (!((v_matchtype==2LL))) { goto no21; }
// regexHandle = CreateRegularExpression(#PB_Any, cleanPat)
integer r5=PB_CreateRegularExpression(-1LL,v_cleanpat);
v_regexhandle=r5;
// If regexHandle = 0 : ProcedureReturn #False : EndIf
if (!((v_regexhandle==0LL))) { goto no23; }
r=0LL;
goto end;
no23:;
// EndIf
no21:;
// 
// *rule\RuleType    = ruleType
p_rule->f_ruletype=v_ruletype;
// *rule\MatchType   = matchType
p_rule->f_matchtype=v_matchtype;
// *rule\Pattern     = cleanPat
SYS_PushStringBasePosition();
SYS_CopyString(v_cleanpat);
SYS_AllocateString4(&p_rule->f_pattern,SYS_PopStringBasePosition());
// *rule\Destination = t2
SYS_PushStringBasePosition();
SYS_CopyString(v_t2);
SYS_AllocateString4(&p_rule->f_destination,SYS_PopStringBasePosition());
// *rule\Code        = code
p_rule->f_code=v_code;
// *rule\RegexHandle = regexHandle
p_rule->f_regexhandle=v_regexhandle;
// ProcedureReturn #True
r=1LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_line);
SYS_FreeString(v_tok);
SYS_FreeString(v_verb);
SYS_FreeString(v_t0);
SYS_FreeString(v_t1);
SYS_FreeString(v_t2);
SYS_FreeString(v_t3);
SYS_FreeString(v_cleanpat);
return r;
}
// Procedure EnsureLogInit()
static integer f_ensureloginit() {
integer r=0;
quad v_delta=0;
integer v_h=0;
integer v_m=0;
void* v_sign=0;
// If g_LogMutex = 0
if (!((g_g_logmutex==0LL))) { goto no2; }
// g_LogMutex = CreateMutex()
integer r0=PB_CreateMutex();
g_g_logmutex=r0;
// 
// 
// Protected delta.q = Date() - ConvertDate(Date(), #PB_Date_UTC)
quad r1=PB_Date();
quad r2=PB_Date();
quad r3=PB_ConvertDate(r2,1LL);
v_delta=((quad)r1-(quad)r3);
// Protected sign.s = "+"
SYS_FastAllocateStringFree4(&v_sign,_S116);
// If delta < 0 : sign = "-" : delta = -delta : EndIf
if (!((v_delta<0LL))) { goto no4; }
SYS_FastAllocateStringFree4(&v_sign,_S117);
v_delta=(-(v_delta));
no4:;
// Protected h.i = delta / 3600
v_h=(v_delta/3600LL);
// Protected m.i = (delta % 3600) / 60
v_m=((((quad)(v_delta)%3600LL))/60LL);
// g_TZOffset = sign + RSet(Str(h), 2, "0") + RSet(Str(m), 2, "0")
SYS_PushStringBasePosition();
SYS_CopyString(v_sign);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_h,SYS_PopStringBasePosition());
void* p0=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_RSet2(p0,2LL,_S118,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_m,SYS_PopStringBasePosition());
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_RSet2(p1,2LL,_S118,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_AllocateString4(&g_g_tzoffset,SYS_PopStringBasePosition());
// EndIf
no2:;
// EndProcedure
r=0;
end:
SYS_FreeString(v_sign);
return r;
}
// Procedure SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)
static integer f_sendtextresponse(integer v_connection,integer v_statuscode,void* v_contenttype,void* v_body) {
integer r=0;
SYS_FastAllocateString4(&v_contenttype,v_contenttype);
SYS_FastAllocateString4(&v_body,v_body);
integer v_bytelen=0;
void* v_headerblock=0;
void* v_extraheaders=0;
// Protected byteLen.i      = StringByteLength(body, #PB_UTF8)
integer r0=PB_StringByteLength2(v_body,2LL);
v_bytelen=r0;
// Protected extraHeaders.s = "Content-Type: " + contentType + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(_S34);
SYS_CopyString(v_contenttype);
SYS_CopyString(_S13);
SYS_AllocateString4(&v_extraheaders,SYS_PopStringBasePosition());
// Protected headerBlock.s  = BuildResponseHeaders(statusCode, extraHeaders, byteLen)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r1=f_buildresponseheaders(v_statuscode,v_extraheaders,v_bytelen,SYS_PopStringBasePosition());
r1;
SYS_AllocateString4(&v_headerblock,SYS_PopStringBasePosition());
// SendNetworkString(connection, headerBlock, #PB_Ascii)
integer r2=PB_SendNetworkString2(v_connection,v_headerblock,24LL);
// If byteLen > 0
if (!((v_bytelen>0LL))) { goto no2; }
// SendNetworkString(connection, body, #PB_UTF8)
integer r3=PB_SendNetworkString2(v_connection,v_body,2LL);
// EndIf
no2:;
// EndProcedure
r=0;
end:
SYS_FreeString(v_contenttype);
SYS_FreeString(v_headerblock);
SYS_FreeString(v_extraheaders);
SYS_FreeString(v_body);
return r;
}
// Procedure.s StatusText(code.i)
static void* f_statustext(integer v_code,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
// Select code
quad pb_select2=v_code;
// Case 200 : ProcedureReturn "OK"
if (pb_select2==200LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S19);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 206 : ProcedureReturn "Partial Content"
goto endselect2;}
if (pb_select2==206LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S20);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 301 : ProcedureReturn "Moved Permanently"
goto endselect2;}
if (pb_select2==301LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S21);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 302 : ProcedureReturn "Found"
goto endselect2;}
if (pb_select2==302LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S22);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 304 : ProcedureReturn "Not Modified"
goto endselect2;}
if (pb_select2==304LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S23);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 400 : ProcedureReturn "Bad Request"
goto endselect2;}
if (pb_select2==400LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S24);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 403 : ProcedureReturn "Forbidden"
goto endselect2;}
if (pb_select2==403LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S25);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 404 : ProcedureReturn "Not Found"
goto endselect2;}
if (pb_select2==404LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S26);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 416 : ProcedureReturn "Range Not Satisfiable"
goto endselect2;}
if (pb_select2==416LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S27);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case 500 : ProcedureReturn "Internal Server Error"
goto endselect2;}
if (pb_select2==500LL) {
SYS_PushStringBasePosition();
SYS_CopyString(_S28);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Default  : ProcedureReturn "Unknown"
goto endselect2;}
SYS_PushStringBasePosition();
SYS_CopyString(_S29);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndSelect
endselect2:;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
return r;
}
// Procedure ReopenLogs()
static integer f_reopenlogs() {
integer r=0;
// If g_LogFile > 0
if (!((g_g_logfile>0LL))) { goto no2; }
// FlushFileBuffers(g_LogFile)
integer p0=(integer)g_g_logfile;
integer r0=PB_FlushFileBuffers(p0);
// CloseFile(g_LogFile)
integer p1=(integer)g_g_logfile;
integer r1=PB_CloseFile(p1);
// g_LogFile = OpenOrAppend(g_LogPath)
void* p2=(void*)g_g_logpath;
integer r2=f_openorappend(p2);
g_g_logfile=r2;
// EndIf
no2:;
// If g_ErrorLogFile > 0
if (!((g_g_errorlogfile>0LL))) { goto no4; }
// FlushFileBuffers(g_ErrorLogFile)
integer p3=(integer)g_g_errorlogfile;
integer r3=PB_FlushFileBuffers(p3);
// CloseFile(g_ErrorLogFile)
integer p4=(integer)g_g_errorlogfile;
integer r4=PB_CloseFile(p4);
// g_ErrorLogFile = OpenOrAppend(g_ErrorLogPath)
void* p5=(void*)g_g_errorlogpath;
integer r5=f_openorappend(p5);
g_g_errorlogfile=r5;
// EndIf
no4:;
// g_ReopenLogs = 0
g_g_reopenlogs=0;
// EndProcedure
r=0;
end:
return r;
}
// Procedure.i ParseLogLevel(s.s)
static integer f_parseloglevel(void* v_s) {
integer r=0;
SYS_FastAllocateString4(&v_s,v_s);
// Select LCase(s)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_LCase(v_s,SYS_PopStringBasePosition());
void *pb_select6=0;
SYS_AllocateString4(&pb_select6,SYS_PopStringBasePosition());
// Case "none"  : ProcedureReturn 0
if (SYS_StringEqual(pb_select6,_S199)) {
SYS_FreeString(pb_select6);
r=0LL;
goto end;
// Case "error" : ProcedureReturn 1
goto endselect6;}
if (SYS_StringEqual(pb_select6,_S134)) {
SYS_FreeString(pb_select6);
r=1LL;
goto end;
// Case "warn"  : ProcedureReturn 2
goto endselect6;}
if (SYS_StringEqual(pb_select6,_S135)) {
SYS_FreeString(pb_select6);
r=2LL;
goto end;
// Case "info"  : ProcedureReturn 3
goto endselect6;}
if (SYS_StringEqual(pb_select6,_S136)) {
SYS_FreeString(pb_select6);
r=3LL;
goto end;
// Default      : ProcedureReturn -1  
goto endselect6;}
SYS_FreeString(pb_select6);
r=-1LL;
goto end;
// EndSelect
endselect6:;
SYS_FreeString(pb_select6);
// EndProcedure
r=0;
end:
SYS_FreeString(v_s);
return r;
}
// Procedure SIGHUPHandler(signum.i)
static integer f_sighuphandler(integer v_signum) {
integer r=0;
// g_ReopenLogs = 1
g_g_reopenlogs=1;
// EndProcedure
r=0;
end:
return r;
}
// Procedure.s HTTPDate(ts.q)
static void* f_httpdate(quad v_ts,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
void* v_days=0;
void* v_months=0;
// Protected days.s   = "Sun,Mon,Tue,Wed,Thu,Fri,Sat"
SYS_FastAllocateStringFree4(&v_days,_S1);
// Protected months.s = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"
SYS_FastAllocateStringFree4(&v_months,_S2);
// 
// 
// ProcedureReturn StringField(days, DayOfWeek(ts) + 1, ",") + ", " +                   FormatDate("%dd ", ts) +                   StringField(months, Month(ts), ",") + " " +                   FormatDate("%yyyy %hh:%ii:%ss", ts) + " GMT"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r0=PB_DayOfWeek(v_ts);
integer p0=(integer)(r0+1);
PB_StringField(v_days,p0,_S3,SYS_PopStringBasePosition());
SYS_CopyString(_S4);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S5,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r1=PB_Month(v_ts);
PB_StringField(v_months,r1,_S3,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S6);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S7,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S8);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_days);
SYS_FreeString(v_months);
return r;
}
// Procedure.s BuildETag(filePath.s)
static void* f_buildetag(void* v_filepath,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_filepath,v_filepath);
integer v_size=0;
quad v_mtime=0;
// Protected size.i = FileSize(filePath)
quad r0=PB_FileSize(v_filepath);
v_size=r0;
// If size < 0
if (!((v_size<0LL))) { goto no2; }
// ProcedureReturn ""
SYS_PushStringBasePosition();
SYS_CopyString(_S10);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndIf
no2:;
// Protected mtime.q = GetFileDate(filePath, #PB_Date_Modified)
quad r1=PB_GetFileDate(v_filepath,2LL);
v_mtime=r1;
// ProcedureReturn Chr(34) + Hex(size) + "-" + Hex(mtime) + Chr(34)
SYS_PushStringBasePosition();
SYS_CopyString(_S133);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Hex(v_size,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S117);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Hex(v_mtime,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S133);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_filepath);
return r;
}
// Procedure LoadGlobalRules(path.s)
static integer f_loadglobalrules(void* v_path) {
integer r=0;
SYS_FastAllocateString4(&v_path,v_path);
volatile s_rewriterule v_tmp={0};
integer v_f=0;
integer v_i=0;
// LockMutex(g_RewriteMutex)
integer p0=(integer)g_g_rewritemutex;
integer r0=PB_LockMutex(p0);
// Protected i.i;
// For i = 0 To g_GR_Count - 1
v_i=0;
while(1) {
if (!(((integer)(g_g_gr_count+-1)>=v_i))) { break; }
// If g_GR_RegexHandle(i) > 0
if (!((((integer*)a_g_gr_regexhandle.a)[(integer)v_i]>0LL))) { goto no4; }
// FreeRegularExpression(g_GR_RegexHandle(i))
integer p1=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
integer r1=PB_FreeRegularExpression(p1);
// g_GR_RegexHandle(i) = 0
((integer*)a_g_gr_regexhandle.a)[(integer)v_i]=0;
// EndIf
no4:;
// g_GR_Pattern(i)     = ""
SYS_FastAllocateStringFree4(&((void**)a_g_gr_pattern.a)[(integer)v_i],_S10);
// g_GR_Destination(i) = ""
SYS_FastAllocateStringFree4(&((void**)a_g_gr_destination.a)[(integer)v_i],_S10);
// Next
next1:
v_i+=1;
}
il_next2:;
// g_GR_Count = 0
g_g_gr_count=0;
// Protected f.i = ReadFile(#PB_Any, path)
integer r2=PB_ReadFile(-1LL,v_path);
v_f=r2;
// If f
if (!(v_f)) { goto no6; }
// Protected tmp.RewriteRule;
// While Not Eof(f) And g_GR_Count <= #MAX_GLOBAL_RULES
while (1) {
integer r3=PB_Eof(v_f);
integer c8=0;
if (!(!(r3))) { goto no8; }
if (!((g_g_gr_count<=63LL))) { goto no8; }
ok8:
c8=1;
no8:;
if (!(c8)) { break; }
// If ParseRule_(ReadString(f), @tmp)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReadString(v_f,SYS_PopStringBasePosition());
void* p2=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer p3=(integer)((integer)(&v_tmp));
integer r4=f_parserule_(p2,p3);
SYS_PopStringBasePositionUpdate();
if (!(r4)) { goto no10; }
// g_GR_RuleType(g_GR_Count)    = tmp\RuleType
((integer*)a_g_gr_ruletype.a)[(integer)g_g_gr_count]=v_tmp.f_ruletype;
// g_GR_MatchType(g_GR_Count)   = tmp\MatchType
((integer*)a_g_gr_matchtype.a)[(integer)g_g_gr_count]=v_tmp.f_matchtype;
// g_GR_Pattern(g_GR_Count)     = tmp\Pattern
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp.f_pattern);
SYS_AllocateString4(&((void**)a_g_gr_pattern.a)[(integer)g_g_gr_count],SYS_PopStringBasePosition());
// g_GR_Destination(g_GR_Count) = tmp\Destination
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp.f_destination);
SYS_AllocateString4(&((void**)a_g_gr_destination.a)[(integer)g_g_gr_count],SYS_PopStringBasePosition());
// g_GR_Code(g_GR_Count)        = tmp\Code
((integer*)a_g_gr_code.a)[(integer)g_g_gr_count]=v_tmp.f_code;
// g_GR_RegexHandle(g_GR_Count) = tmp\RegexHandle
((integer*)a_g_gr_regexhandle.a)[(integer)g_g_gr_count]=v_tmp.f_regexhandle;
// g_GR_Count + 1
g_g_gr_count=(g_g_gr_count+1);
// EndIf
no10:;
// Wend
}
il_wend7:;
// CloseFile(f)
integer r5=PB_CloseFile(v_f);
// EndIf
no6:;
// UnlockMutex(g_RewriteMutex)
integer p4=(integer)g_g_rewritemutex;
integer r6=PB_UnlockMutex(p4);
// EndProcedure
r=0;
end:
SYS_FreeString(v_path);
SYS_FreeStructureStrings(&v_tmp,ms_rewriterule);
return r;
}
// Procedure.s URLBasename_(path.s)
static void* f_urlbasename_(void* v_path,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_path,v_path);
integer v_pos=0;
// Protected pos.i = URLLastSlash_(path)
integer r0=f_urllastslash_(v_path);
v_pos=r0;
// If pos > 0 : ProcedureReturn Mid(path, pos + 1) : EndIf
if (!((v_pos>0LL))) { goto no2; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p0=(integer)(v_pos+1);
PB_Mid(v_path,p0,SYS_PopStringBasePosition());
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
no2:;
// ProcedureReturn path
SYS_PushStringBasePosition();
SYS_CopyString(v_path);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_path);
return r;
}
// Procedure ConnectionThread(*data.ThreadData)
static integer f_connectionthread(s_threaddata* p_data) {
integer r=0;
integer v_client=0;
void* v_raw=0;
// Protected client.i = *data\client
v_client=p_data->f_client;
// Protected raw.s    = *data\raw
SYS_PushStringBasePosition();
SYS_CopyString(p_data->f_raw);
SYS_AllocateString4(&v_raw,SYS_PopStringBasePosition());
// FreeStructure(*data)
integer p0=(integer)p_data;
integer r0=PB_FreeStructure(p0);
// g_Handler(client, raw)
integer r1=g_g_handler(v_client,v_raw);
// 
// 
// LockMutex(g_CloseMutex)
integer p1=(integer)g_g_closemutex;
integer r2=PB_LockMutex(p1);
// AddElement(g_CloseList())
void* p2=(void*)(t_g_closelist.a);
integer r3=PB_AddElement(p2);
// g_CloseList() = client
(*(integer*)&t_g_closelist.b->c)=v_client;
// UnlockMutex(g_CloseMutex)
integer p3=(integer)g_g_closemutex;
integer r4=PB_UnlockMutex(p3);
// EndProcedure
r=0;
end:
SYS_FreeString(v_raw);
return r;
}
// Procedure.s GetMimeType(extension.s)
static void* f_getmimetype(void* v_extension,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_extension,v_extension);
// Select extension
void *pb_select4=0;
SYS_FastAllocateString4(&pb_select4,v_extension);
// 
// Case "html", "htm"   : ProcedureReturn "text/html; charset=utf-8"
if (SYS_StringEqual(pb_select4,_S35) || SYS_StringEqual(pb_select4,_S36)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S37);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "css"           : ProcedureReturn "text/css"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S38)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S39);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "txt"           : ProcedureReturn "text/plain; charset=utf-8"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S40)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S41);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "xml"           : ProcedureReturn "text/xml; charset=utf-8"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S42)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S43);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "csv"           : ProcedureReturn "text/csv"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S44)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S45);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "md"            : ProcedureReturn "text/markdown; charset=utf-8"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S46)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S47);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "ics"           : ProcedureReturn "text/calendar"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S48)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S49);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "vcf"           : ProcedureReturn "text/vcard"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S50)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S51);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// 
// Case "js", "mjs"     : ProcedureReturn "application/javascript"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S52) || SYS_StringEqual(pb_select4,_S53)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S54);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "json"          : ProcedureReturn "application/json"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S55)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S56);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "jsonld"        : ProcedureReturn "application/ld+json"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S57)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S58);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "wasm"          : ProcedureReturn "application/wasm"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S59)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S60);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "webmanifest"   : ProcedureReturn "application/manifest+json"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S61)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S62);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "appcache"      : ProcedureReturn "text/cache-manifest"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S63)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S64);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// 
// Case "png"           : ProcedureReturn "image/png"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S65)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S66);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "jpg", "jpeg"   : ProcedureReturn "image/jpeg"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S67) || SYS_StringEqual(pb_select4,_S68)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S69);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "gif"           : ProcedureReturn "image/gif"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S70)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S71);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "svg"           : ProcedureReturn "image/svg+xml"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S72)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S73);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "webp"          : ProcedureReturn "image/webp"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S74)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S75);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "ico"           : ProcedureReturn "image/x-icon"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S76)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S77);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "bmp"           : ProcedureReturn "image/bmp"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S78)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S79);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "avif"          : ProcedureReturn "image/avif"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S80)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S81);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "tif", "tiff"   : ProcedureReturn "image/tiff"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S82) || SYS_StringEqual(pb_select4,_S83)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S84);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// 
// Case "woff"          : ProcedureReturn "font/woff"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S85)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S86);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "woff2"         : ProcedureReturn "font/woff2"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S87)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S88);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "ttf"           : ProcedureReturn "font/ttf"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S89)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S90);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "otf"           : ProcedureReturn "font/otf"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S91)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S92);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "eot"           : ProcedureReturn "application/vnd.ms-fontobject"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S93)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S94);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// 
// Case "mp3"           : ProcedureReturn "audio/mpeg"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S95)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S96);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "ogg"           : ProcedureReturn "audio/ogg"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S97)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S98);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "wav"           : ProcedureReturn "audio/wav"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S99)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S100);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "mp4"           : ProcedureReturn "video/mp4"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S101)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S102);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "webm"          : ProcedureReturn "video/webm"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S103)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S104);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "ogv"           : ProcedureReturn "video/ogg"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S105)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S106);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// 
// Case "zip"           : ProcedureReturn "application/zip"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S107)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S108);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "gz"            : ProcedureReturn "application/gzip"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S109)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S110);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "tar"           : ProcedureReturn "application/x-tar"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S111)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S112);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Case "pdf"           : ProcedureReturn "application/pdf"
goto endselect4;}
if (SYS_StringEqual(pb_select4,_S113)) {
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S114);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// Default              : ProcedureReturn "application/octet-stream"
goto endselect4;}
SYS_FreeString(pb_select4);
SYS_PushStringBasePosition();
SYS_CopyString(_S115);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndSelect
endselect4:;
SYS_FreeString(pb_select4);
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_extension);
return r;
}
// Procedure.s NormalizePath(s.s)
static void* f_normalizepath(void* v_s,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_s,v_s);
void* v_segment=0;
integer v_i=0;
integer v_trailingslash=0;
void* v_result=0;
integer v_count=0;
pb_list t_segments={0};
// Protected trailingSlash.i = #False
v_trailingslash=0;
// Protected i.i, segment.s, count.i, result.s;;;;
// 
// If Left(s, 1) <> "/"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_s,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S9;
if (!((!SYS_StringEqual(p1,p0)))) { goto no2; }
// s = "/" + s
SYS_PushStringBasePosition();
SYS_CopyString(_S9);
SYS_CopyString(v_s);
SYS_AllocateString4(&v_s,SYS_PopStringBasePosition());
// EndIf
no2:;
// 
// If Len(s) > 1 And Right(s, 1) = "/"
integer r0=PB_Len(v_s);
integer c5=0;
if (!((r0>1))) { goto no5; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_s,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p2=SYS_PopStringBasePositionValue();
void* p3=_S9;
if (!(SYS_StringEqual(p3,p2))) { goto no5; }
ok5:
c5=1;
no5:;
if (!(c5)) { goto no4; }
// trailingSlash = #True
v_trailingslash=1;
// EndIf
no4:;
// 
// NewList segments.s()
PB_NewList(8,&t_segments,ms_s,8);
// 
// count = CountString(s, "/") + 1
integer r1=PB_CountString(v_s,_S9);
v_count=(r1+1);
// For i = 1 To count
v_i=1;
while(1) {
if (!(((integer)v_count>=v_i))) { break; }
// segment = StringField(s, i, "/")
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_s,v_i,_S9,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_segment,SYS_PopStringBasePosition());
// Select segment
void *pb_select1=0;
SYS_FastAllocateString4(&pb_select1,v_segment);
// Case "", "."
if (SYS_StringEqual(pb_select1,_S10) || SYS_StringEqual(pb_select1,_S11)) {
// 
// Case ".."
goto endselect1;}
if (SYS_StringEqual(pb_select1,_S12)) {
// If ListSize(segments()) > 0
void* p4=(void*)(t_segments.a);
integer r2=PB_ListSize(p4);
if (!((r2>0))) { goto no9; }
// LastElement(segments())
void* p5=(void*)(t_segments.a);
integer r3=PB_LastElement(p5);
// DeleteElement(segments())
void* p6=(void*)(t_segments.a);
integer r4=PB_DeleteElement(p6);
// EndIf
no9:;
// 
// Default
goto endselect1;}
// AddElement(segments())
void* p7=(void*)(t_segments.a);
integer r5=PB_AddElement(p7);
// segments() = segment
SYS_PushStringBasePosition();
SYS_CopyString(v_segment);
SYS_AllocateString4(&(*(void**)&t_segments.b->c),SYS_PopStringBasePosition());
// EndSelect
endselect1:;
SYS_FreeString(pb_select1);
// Next i
next6:
v_i+=1;
}
il_next7:;
// 
// result = ""
SYS_FastAllocateStringFree4(&v_result,_S10);
// ForEach segments()
PB_ResetList(t_segments.a);
while (PB_NextElement(t_segments.a)) {
// result + "/" + segments()
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S9);
SYS_CopyString((*(void**)&t_segments.b->c));
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// Next
}
il_next10:;
// 
// If result = ""
void* p8=v_result;
void* p9=_S10;
if (!(SYS_StringEqual(p9,p8))) { goto no12; }
// result = "/"
SYS_FastAllocateStringFree4(&v_result,_S9);
// ElseIf trailingSlash
goto endif11;
no12:;
if (!(v_trailingslash)) { goto no13; }
ok13:;
// result + "/"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S9);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// EndIf
endif11:;
no13:;
// 
// ProcedureReturn result
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_segment);
SYS_FreeString(v_s);
SYS_FreeString(v_result);
PB_FreeList(t_segments.a);
return r;
}
// Procedure CleanupRewriteEngine()
static integer f_cleanuprewriteengine() {
integer r=0;
integer v_i=0;
integer v_j=0;
integer v_ri=0;
// Protected i.i, j.i, ri.i;;;
// For i = 0 To g_GR_Count - 1
v_i=0;
while(1) {
if (!(((integer)(g_g_gr_count+-1)>=v_i))) { break; }
// If g_GR_RegexHandle(i) > 0
if (!((((integer*)a_g_gr_regexhandle.a)[(integer)v_i]>0LL))) { goto no4; }
// FreeRegularExpression(g_GR_RegexHandle(i))
integer p0=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
integer r0=PB_FreeRegularExpression(p0);
// g_GR_RegexHandle(i) = 0
((integer*)a_g_gr_regexhandle.a)[(integer)v_i]=0;
// EndIf
no4:;
// Next
next1:
v_i+=1;
}
il_next2:;
// g_GR_Count = 0
g_g_gr_count=0;
// For i = 0 To g_DC_Count - 1
v_i=0;
while(1) {
if (!(((integer)(g_g_dc_count+-1)>=v_i))) { break; }
// For j = 0 To g_DC_RuleCount(i) - 1
v_j=0;
while(1) {
if (!(((integer)(((integer*)a_g_dc_rulecount.a)[(integer)v_i]+-1)>=v_j))) { break; }
// ri = i * #DR_STRIDE + j
v_ri=((quad)((quad)v_i*(quad)16LL)+(quad)v_j);
// If g_DR_RegexHandle(ri) > 0
if (!((((integer*)a_g_dr_regexhandle.a)[(integer)v_ri]>0LL))) { goto no10; }
// FreeRegularExpression(g_DR_RegexHandle(ri))
integer p1=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
integer r1=PB_FreeRegularExpression(p1);
// g_DR_RegexHandle(ri) = 0
((integer*)a_g_dr_regexhandle.a)[(integer)v_ri]=0;
// EndIf
no10:;
// Next
next7:
v_j+=1;
}
il_next8:;
// g_DC_RuleCount(i) = 0
((integer*)a_g_dc_rulecount.a)[(integer)v_i]=0;
// g_DC_DirPath(i)   = ""
SYS_FastAllocateStringFree4(&((void**)a_g_dc_dirpath.a)[(integer)v_i],_S10);
// g_DC_FileMtime(i) = 0
((quad*)a_g_dc_filemtime.a)[(integer)v_i]=0;
// Next
next5:
v_i+=1;
}
il_next6:;
// g_DC_Count = 0
g_g_dc_count=0;
// If g_RewriteMutex
if (!(g_g_rewritemutex)) { goto no12; }
// FreeMutex(g_RewriteMutex)
integer p2=(integer)g_g_rewritemutex;
integer r2=PB_FreeMutex(p2);
// g_RewriteMutex = 0
g_g_rewritemutex=0;
// EndIf
no12:;
// EndProcedure
r=0;
end:
return r;
}
// Procedure.s RotationStamp()
static void* f_rotationstamp(int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
quad v_ts=0;
// Protected ts.q = Date()
quad r0=PB_Date();
v_ts=r0;
// g_RotationSeq + 1
g_g_rotationseq=(g_g_rotationseq+1);
// ProcedureReturn FormatDate("%yyyy%mm%dd", ts) + "-" + FormatDate("%hh%ii%ss", ts) +                   "-" + RSet(Str(g_RotationSeq), 3, "0")
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S119,v_ts,SYS_PopStringBasePosition());
SYS_CopyString(_S117);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S120,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S117);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p0=(quad)g_g_rotationseq;
PB_Str(p0,SYS_PopStringBasePosition());
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_RSet2(p1,3LL,_S118,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
return r;
}
// Procedure.s ResolveIndexFile(dirPath.s, indexList.s)
static void* f_resolveindexfile(void* v_dirpath,void* v_indexlist,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_dirpath,v_dirpath);
SYS_FastAllocateString4(&v_indexlist,v_indexlist);
integer v_i=0;
void* v_fullpath=0;
integer v_count=0;
void* v_candidate=0;
// Protected i.i, candidate.s, fullPath.s;;;
// Protected count.i = CountString(indexList, ",") + 1
integer r0=PB_CountString(v_indexlist,_S3);
v_count=(r0+1);
// 
// If Right(dirPath, 1) <> "/" And Right(dirPath, 1) <> "\"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_dirpath,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S9;
integer c3=0;
if (!((!SYS_StringEqual(p1,p0)))) { goto no3; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_dirpath,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p2=SYS_PopStringBasePositionValue();
void* p3=_S140;
if (!((!SYS_StringEqual(p3,p2)))) { goto no3; }
ok3:
c3=1;
no3:;
if (!(c3)) { goto no2; }
// dirPath + "/"
SYS_PushStringBasePosition();
SYS_CopyString(v_dirpath);
SYS_CopyString(_S9);
SYS_AllocateString4(&v_dirpath,SYS_PopStringBasePosition());
// EndIf
no2:;
// 
// For i = 1 To count
v_i=1;
while(1) {
if (!(((integer)v_count>=v_i))) { break; }
// candidate = Trim(StringField(indexList, i, ","))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_indexlist,v_i,_S3,SYS_PopStringBasePosition());
void* p4=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_Trim(p4,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_candidate,SYS_PopStringBasePosition());
// If candidate <> ""
void* p5=v_candidate;
void* p6=_S10;
if (!((!SYS_StringEqual(p6,p5)))) { goto no7; }
// fullPath = dirPath + candidate
SYS_PushStringBasePosition();
SYS_CopyString(v_dirpath);
SYS_CopyString(v_candidate);
SYS_AllocateString4(&v_fullpath,SYS_PopStringBasePosition());
// If FileSize(fullPath) >= 0
quad r1=PB_FileSize(v_fullpath);
if (!((r1>=0))) { goto no9; }
// ProcedureReturn fullPath
SYS_PushStringBasePosition();
SYS_CopyString(v_fullpath);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndIf
no9:;
// EndIf
no7:;
// Next i
next4:
v_i+=1;
}
il_next5:;
// 
// ProcedureReturn ""
SYS_PushStringBasePosition();
SYS_CopyString(_S10);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_indexlist);
SYS_FreeString(v_fullpath);
SYS_FreeString(v_dirpath);
SYS_FreeString(v_candidate);
return r;
}
// Procedure.s URLDirname_(path.s)
static void* f_urldirname_(void* v_path,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_path,v_path);
integer v_pos=0;
// Protected pos.i = URLLastSlash_(path)
integer r0=f_urllastslash_(v_path);
v_pos=r0;
// If pos > 1 : ProcedureReturn Left(path, pos - 1) : EndIf
if (!((v_pos>1LL))) { goto no2; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p0=(integer)(v_pos+-1);
PB_Left(v_path,p0,SYS_PopStringBasePosition());
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
no2:;
// ProcedureReturn "/"
SYS_PushStringBasePosition();
SYS_CopyString(_S9);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_path);
return r;
}
// Procedure.i OpenOrAppend(path.s)
static integer f_openorappend(void* v_path) {
integer r=0;
SYS_FastAllocateString4(&v_path,v_path);
integer v_fh=0;
// Protected fh.i = 0
v_fh=0;
// If FileSize(path) >= 0
quad r0=PB_FileSize(v_path);
if (!((r0>=0))) { goto no2; }
// fh = OpenFile(#PB_Any, path)
integer r1=PB_OpenFile(-1LL,v_path);
v_fh=r1;
// If fh > 0
if (!((v_fh>0LL))) { goto no4; }
// FileSeek(fh, Lof(fh))
quad r2=PB_Lof(v_fh);
integer r3=PB_FileSeek(v_fh,r2);
// EndIf
no4:;
// EndIf
no2:;
// If fh = 0
if (!((v_fh==0LL))) { goto no6; }
// fh = CreateFile(#PB_Any, path)
integer r4=PB_CreateFile(-1LL,v_path);
v_fh=r4;
// EndIf
no6:;
// ProcedureReturn fh
r=v_fh;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_path);
return r;
}
// Procedure.i URLLastSlash_(path.s)
static integer f_urllastslash_(void* v_path) {
integer r=0;
SYS_FastAllocateString4(&v_path,v_path);
integer v_i=0;
// Protected i.i;
// For i = Len(path) To 1 Step -1
integer r0=PB_Len(v_path);
v_i=r0;
while(1) {
if (!(((integer)1LL<=v_i))) { break; }
// If Mid(path, i, 1) = "/"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Mid2(v_path,v_i,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S9;
if (!(SYS_StringEqual(p1,p0))) { goto no4; }
// ProcedureReturn i
r=v_i;
goto end;
// EndIf
no4:;
// Next
next1:
v_i+=-1;
}
il_next2:;
// ProcedureReturn 0
r=0LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_path);
return r;
}
// Procedure.i GlobalRuleCount()
static integer f_globalrulecount() {
integer r=0;
integer v_n=0;
// LockMutex(g_RewriteMutex)
integer p0=(integer)g_g_rewritemutex;
integer r0=PB_LockMutex(p0);
// Protected n.i = g_GR_Count
v_n=g_g_gr_count;
// UnlockMutex(g_RewriteMutex)
integer p1=(integer)g_g_rewritemutex;
integer r1=PB_UnlockMutex(p1);
// ProcedureReturn n
r=v_n;
goto end;
// EndProcedure
r=0;
end:
return r;
}
// Procedure.s GetHeader(rawHeaders.s, name.s)
static void* f_getheader(void* v_rawheaders,void* v_name,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_rawheaders,v_rawheaders);
SYS_FastAllocateString4(&v_name,v_name);
void* v_line=0;
integer v_colonpos=0;
integer v_i=0;
integer v_count=0;
// Protected i.i, line.s, colonPos.i, count.i;;;;
// name = LCase(name)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_LCase(v_name,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_name,SYS_PopStringBasePosition());
// count = CountString(rawHeaders, #CRLF$) + 1
integer r0=PB_CountString(v_rawheaders,_S13);
v_count=(r0+1);
// For i = 1 To count
v_i=1;
while(1) {
if (!(((integer)v_count>=v_i))) { break; }
// line = StringField(rawHeaders, i, #CRLF$)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_rawheaders,v_i,_S13,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_line,SYS_PopStringBasePosition());
// colonPos = FindString(line, ":")
integer r1=PB_FindString(v_line,_S14);
v_colonpos=r1;
// If colonPos > 0
if (!((v_colonpos>0LL))) { goto no4; }
// If LCase(Left(line, colonPos - 1)) = name
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p0=(integer)(v_colonpos+-1);
PB_Left(v_line,p0,SYS_PopStringBasePosition());
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_LCase(p1,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p2=SYS_PopStringBasePositionValue();
void* p3=v_name;
if (!(SYS_StringEqual(p3,p2))) { goto no6; }
// ProcedureReturn Trim(Mid(line, colonPos + 1))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p4=(integer)(v_colonpos+1);
PB_Mid(v_line,p4,SYS_PopStringBasePosition());
void* p5=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_Trim(p5,SYS_PopStringBasePosition());
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndIf
no6:;
// EndIf
no4:;
// Next i
next1:
v_i+=1;
}
il_next2:;
// ProcedureReturn ""
SYS_PushStringBasePosition();
SYS_CopyString(_S10);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_line);
SYS_FreeString(v_name);
SYS_FreeString(v_rawheaders);
return r;
}
// Procedure LogRotationThread(*unused)
static integer f_logrotationthread(integer p_unused) {
integer r=0;
quad v_elapsed=0;
quad v_secsleft=0;
quad v_utcnow=0;
// Protected secsLeft.q, elapsed.q, utcNow.q;;;
// While g_StopRotation = 0
while (1) {
if (!((g_g_stoprotation==0LL))) { break; }
// 
// utcNow   = ConvertDate(Date(), #PB_Date_UTC)
quad r0=PB_Date();
quad r1=PB_ConvertDate(r0,1LL);
v_utcnow=r1;
// secsLeft = 86400 - (utcNow % 86400)
v_secsleft=((-((((quad)(v_utcnow)%86400LL))))+86400);
// 
// 
// elapsed = 0
v_elapsed=0;
// While elapsed < secsLeft And g_StopRotation = 0
while (1) {
integer c3=0;
if (!((v_elapsed<v_secsleft))) { goto no3; }
if (!((g_g_stoprotation==0LL))) { goto no3; }
ok3:
c3=1;
no3:;
if (!(c3)) { break; }
// Delay(1000)
integer r2=PB_Delay(1000LL);
// elapsed + 1
v_elapsed=(v_elapsed+1);
// Wend
}
il_wend2:;
// 
// 
// If g_StopRotation = 0
if (!((g_g_stoprotation==0LL))) { goto no5; }
// LockMutex(g_LogMutex)
integer p0=(integer)g_g_logmutex;
integer r3=PB_LockMutex(p0);
// If g_LogFile > 0 And g_LogPath <> ""
integer c8=0;
if (!((g_g_logfile>0LL))) { goto no8; }
void* p1=g_g_logpath;
void* p2=_S10;
if (!((!SYS_StringEqual(p2,p1)))) { goto no8; }
ok8:
c8=1;
no8:;
if (!(c8)) { goto no7; }
// RotateLog(@g_LogFile, g_LogPath)
integer p3=(integer)((integer)(&g_g_logfile));
void* p4=(void*)g_g_logpath;
integer r4=f_rotatelog(p3,p4);
// EndIf
no7:;
// If g_ErrorLogFile > 0 And g_ErrorLogPath <> ""
integer c11=0;
if (!((g_g_errorlogfile>0LL))) { goto no11; }
void* p5=g_g_errorlogpath;
void* p6=_S10;
if (!((!SYS_StringEqual(p6,p5)))) { goto no11; }
ok11:
c11=1;
no11:;
if (!(c11)) { goto no10; }
// RotateLog(@g_ErrorLogFile, g_ErrorLogPath)
integer p7=(integer)((integer)(&g_g_errorlogfile));
void* p8=(void*)g_g_errorlogpath;
integer r5=f_rotatelog(p7,p8);
// EndIf
no10:;
// UnlockMutex(g_LogMutex)
integer p9=(integer)g_g_logmutex;
integer r6=PB_UnlockMutex(p9);
// EndIf
no5:;
// Wend
}
il_wend1:;
// EndProcedure
r=0;
end:
return r;
}
// Procedure LogError(level.s, message.s)
static integer f_logerror(void* v_level,void* v_message) {
integer r=0;
SYS_FastAllocateString4(&v_level,v_level);
SYS_FastAllocateString4(&v_message,v_message);
void* v_line=0;
integer v_levelint=0;
// If g_ErrorLogFile = 0
if (!((g_g_errorlogfile==0LL))) { goto no2; }
// ProcedureReturn
r=0;
goto end;
// EndIf
no2:;
// 
// Protected levelInt.i;
// Select LCase(level)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_LCase(v_level,SYS_PopStringBasePosition());
void *pb_select5=0;
SYS_AllocateString4(&pb_select5,SYS_PopStringBasePosition());
// Case "error" : levelInt = 1
if (SYS_StringEqual(pb_select5,_S134)) {
v_levelint=1;
// Case "warn"  : levelInt = 2
goto endselect5;}
if (SYS_StringEqual(pb_select5,_S135)) {
v_levelint=2;
// Case "info"  : levelInt = 3
goto endselect5;}
if (SYS_StringEqual(pb_select5,_S136)) {
v_levelint=3;
// Default      : levelInt = 1  
goto endselect5;}
v_levelint=1;
// EndSelect
endselect5:;
SYS_FreeString(pb_select5);
// 
// If levelInt > g_LogLevel
if (!((v_levelint>g_g_loglevel))) { goto no4; }
// ProcedureReturn  
r=0;
goto end;
// EndIf
no4:;
// 
// Protected line.s = ApacheDate(Date()) + " [" + level + "] [pid " +                      Str(g_ServerPID) + "] " + message
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad r0=PB_Date();
void* r1=f_apachedate(r0,SYS_PopStringBasePosition());
SYS_CopyString(_S137);
SYS_CopyString(v_level);
SYS_CopyString(_S138);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p0=(quad)g_g_serverpid;
PB_Str(p0,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S139);
SYS_CopyString(v_message);
SYS_AllocateString4(&v_line,SYS_PopStringBasePosition());
// 
// LockMutex(g_LogMutex)
integer p1=(integer)g_g_logmutex;
integer r2=PB_LockMutex(p1);
// If g_ReopenLogs : ReopenLogs() : EndIf
if (!(g_g_reopenlogs)) { goto no6; }
integer r3=f_reopenlogs();
no6:;
// If g_LogMaxBytes > 0 And g_ErrorLogFile > 0
integer c9=0;
if (!((g_g_logmaxbytes>0LL))) { goto no9; }
if (!((g_g_errorlogfile>0LL))) { goto no9; }
ok9:
c9=1;
no9:;
if (!(c9)) { goto no8; }
// FlushFileBuffers(g_ErrorLogFile)
integer p2=(integer)g_g_errorlogfile;
integer r4=PB_FlushFileBuffers(p2);
// If Lof(g_ErrorLogFile) >= g_LogMaxBytes
integer p3=(integer)g_g_errorlogfile;
quad r5=PB_Lof(p3);
if (!((r5>=g_g_logmaxbytes))) { goto no11; }
// RotateLog(@g_ErrorLogFile, g_ErrorLogPath)
integer p4=(integer)((integer)(&g_g_errorlogfile));
void* p5=(void*)g_g_errorlogpath;
integer r6=f_rotatelog(p4,p5);
// EndIf
no11:;
// EndIf
no8:;
// If g_ErrorLogFile > 0
if (!((g_g_errorlogfile>0LL))) { goto no13; }
// WriteStringN(g_ErrorLogFile, line, #PB_Ascii)
integer p6=(integer)g_g_errorlogfile;
integer r7=PB_WriteStringN2(p6,v_line,24LL);
// EndIf
no13:;
// UnlockMutex(g_LogMutex)
integer p7=(integer)g_g_logmutex;
integer r8=PB_UnlockMutex(p7);
// EndProcedure
r=0;
end:
SYS_FreeString(v_line);
SYS_FreeString(v_message);
SYS_FreeString(v_level);
return r;
}
// Procedure PruneArchives(logPath.s)
static integer f_prunearchives(void* v_logpath) {
integer r=0;
SYS_FastAllocateString4(&v_logpath,v_logpath);
void* v_suffix=0;
integer v_excess=0;
integer v_prefixlen=0;
void* v_name=0;
integer v_i=0;
void* v_stem=0;
void* v_base=0;
void* v_ext=0;
integer v_suffixlen=0;
void* v_mid=0;
void* v_prefix=0;
void* v_dir=0;
integer v_stemlen=0;
pb_list t_archives={0};
// If g_LogKeepCount <= 0 : ProcedureReturn : EndIf
if (!((g_g_logkeepcount<=0LL))) { goto no2; }
r=0;
goto end;
no2:;
// 
// Protected dir.s       = GetPathPart(logPath)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetPathPart(v_logpath,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
SYS_AllocateString4(&v_dir,SYS_PopStringBasePosition());
// Protected base.s      = GetFilePart(logPath)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetFilePart(v_logpath,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_base,SYS_PopStringBasePosition());
// Protected ext.s       = LCase(GetExtensionPart(base))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetExtensionPart(v_base,SYS_PopStringBasePosition());
void* p0=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_LCase(p0,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_ext,SYS_PopStringBasePosition());
// Protected stemLen.i   = Len(base) - Bool(ext <> "") * (Len(ext) + 1)
integer r0=PB_Len(v_base);
void* p1=v_ext;
void* p2=_S10;
int r1=(((!SYS_StringEqual(p2,p1)))?1:0);
integer r2=PB_Len(v_ext);
v_stemlen=((quad)r0-(quad)((quad)r1*(quad)((r2+1))));
// Protected stem.s      = Left(base, stemLen)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_base,v_stemlen,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_stem,SYS_PopStringBasePosition());
// Protected prefix.s    = stem + "."
SYS_PushStringBasePosition();
SYS_CopyString(v_stem);
SYS_CopyString(_S11);
SYS_AllocateString4(&v_prefix,SYS_PopStringBasePosition());
// Protected suffix.s    = ""
SYS_FastAllocateStringFree4(&v_suffix,_S10);
// If ext <> "" : suffix = "." + ext : EndIf
void* p3=v_ext;
void* p4=_S10;
if (!((!SYS_StringEqual(p4,p3)))) { goto no4; }
SYS_PushStringBasePosition();
SYS_CopyString(_S11);
SYS_CopyString(v_ext);
SYS_AllocateString4(&v_suffix,SYS_PopStringBasePosition());
no4:;
// Protected prefixLen.i = Len(prefix)
integer r3=PB_Len(v_prefix);
v_prefixlen=r3;
// Protected suffixLen.i = Len(suffix)
integer r4=PB_Len(v_suffix);
v_suffixlen=r4;
// 
// Protected NewList archives.s()
PB_NewList(8,&t_archives,ms_s,8);;
// Protected name.s, mid.s;;
// 
// If ExamineDirectory(1, dir, "*")
integer r5=PB_ExamineDirectory(1LL,v_dir,_S121);
if (!(r5)) { goto no6; }
// While NextDirectoryEntry(1)
while (1) {
integer r6=PB_NextDirectoryEntry(1LL);
if (!(r6)) { break; }
// If DirectoryEntryType(1) = #PB_DirectoryEntry_File
integer r7=PB_DirectoryEntryType(1LL);
if (!((r7==1))) { goto no9; }
// name = DirectoryEntryName(1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_DirectoryEntryName(1LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_name,SYS_PopStringBasePosition());
// 
// If Len(name) > prefixLen + 14 + suffixLen
integer r8=PB_Len(v_name);
if (!((r8>((v_prefixlen+v_suffixlen)+14)))) { goto no11; }
// If Left(name, prefixLen) = prefix
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_name,v_prefixlen,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p5=SYS_PopStringBasePositionValue();
void* p6=v_prefix;
if (!(SYS_StringEqual(p6,p5))) { goto no13; }
// If suffix = "" Or Right(name, suffixLen) = suffix
void* p7=v_suffix;
void* p8=_S10;
integer c16=0;
if (SYS_StringEqual(p8,p7)) { goto ok16; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_name,v_suffixlen,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p9=SYS_PopStringBasePositionValue();
void* p10=v_suffix;
if (SYS_StringEqual(p10,p9)) { goto ok16; }
goto no16;
ok16:
c16=1;
no16:;
if (!(c16)) { goto no15; }
// mid = Mid(name, prefixLen + 1, Len(name) - prefixLen - suffixLen)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r9=PB_Len(v_name);
integer p11=(integer)(v_prefixlen+1);
integer p12=(integer)((r9-v_prefixlen)-v_suffixlen);
PB_Mid2(v_name,p11,p12,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_mid,SYS_PopStringBasePosition());
// 
// If Len(mid) >= 15 And Mid(mid, 9, 1) = "-"
integer r10=PB_Len(v_mid);
integer c19=0;
if (!((r10>=15))) { goto no19; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Mid2(v_mid,9LL,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p13=SYS_PopStringBasePositionValue();
void* p14=_S117;
if (!(SYS_StringEqual(p14,p13))) { goto no19; }
ok19:
c19=1;
no19:;
if (!(c19)) { goto no18; }
// AddElement(archives())
void* p15=(void*)(t_archives.a);
integer r11=PB_AddElement(p15);
// archives() = dir + name
SYS_PushStringBasePosition();
SYS_CopyString(v_dir);
SYS_CopyString(v_name);
SYS_AllocateString4(&(*(void**)&t_archives.b->c),SYS_PopStringBasePosition());
// EndIf
no18:;
// EndIf
no15:;
// EndIf
no13:;
// EndIf
no11:;
// EndIf
no9:;
// Wend
}
il_wend7:;
// FinishDirectory(1)
integer r12=PB_FinishDirectory(1LL);
// EndIf
no6:;
// 
// SortList(archives(), #PB_Sort_Ascending)
void* p16=(void*)(t_archives.a);
integer r13=PB_SortList(p16,0LL);
// 
// Protected excess.i = ListSize(archives()) - g_LogKeepCount
void* p17=(void*)(t_archives.a);
integer r14=PB_ListSize(p17);
v_excess=((quad)r14-(quad)g_g_logkeepcount);
// If excess > 0
if (!((v_excess>0LL))) { goto no21; }
// FirstElement(archives())
void* p18=(void*)(t_archives.a);
integer r15=PB_FirstElement(p18);
// Protected i.i;
// For i = 1 To excess
v_i=1;
while(1) {
if (!(((integer)v_excess>=v_i))) { break; }
// DeleteFile(archives())
void* p19=(void*)(*(void**)&t_archives.b->c);
integer r16=PB_DeleteFile(p19);
// NextElement(archives())
void* p20=(void*)(t_archives.a);
integer r17=PB_NextElement(p20);
// Next i
next22:
v_i+=1;
}
il_next23:;
// EndIf
no21:;
// 
// FreeList(archives())
void* p21=(void*)(t_archives.a);
integer r18=PB_FreeList(p21);
// EndProcedure
r=0;
end:
SYS_FreeString(v_suffix);
SYS_FreeString(v_name);
SYS_FreeString(v_logpath);
SYS_FreeString(v_stem);
SYS_FreeString(v_base);
SYS_FreeString(v_ext);
SYS_FreeString(v_mid);
SYS_FreeString(v_prefix);
SYS_FreeString(v_dir);
PB_FreeList(t_archives.a);
return r;
}
// Procedure.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
static integer f_parserangeheader(void* v_header,integer v_filesize,s_rangespec* p_range) {
integer r=0;
SYS_FastAllocateString4(&v_header,v_header);
void* v_endstr=0;
void* v_startstr=0;
void* v_rangespec=0;
integer v_dashpos=0;
integer v_endval=0;
integer v_suffixlen=0;
integer v_startval=0;
// Protected rangeSpec.s, dashPos.i, startStr.s, endStr.s;;;;
// Protected startVal.i, endVal.i, suffixLen.i;;;
// 
// *range\IsValid = #False
p_range->f_isvalid=0;
// *range\Start   = 0
p_range->f_start=0;
// *range\End     = fileSize - 1
p_range->f_end=(v_filesize+-1);
// 
// If fileSize <= 0
if (!((v_filesize<=0LL))) { goto no2; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no2:;
// 
// 
// If LCase(Left(header, 6)) <> "bytes="
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Left(v_header,6LL,SYS_PopStringBasePosition());
void* p0=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_LCase(p0,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p1=SYS_PopStringBasePositionValue();
void* p2=_S193;
if (!((!SYS_StringEqual(p2,p1)))) { goto no4; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no4:;
// 
// rangeSpec = Mid(header, 7)  
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Mid(v_header,7LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_rangespec,SYS_PopStringBasePosition());
// dashPos   = FindString(rangeSpec, "-")
integer r0=PB_FindString(v_rangespec,_S117);
v_dashpos=r0;
// If dashPos = 0
if (!((v_dashpos==0LL))) { goto no6; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no6:;
// 
// startStr = Left(rangeSpec, dashPos - 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p3=(integer)(v_dashpos+-1);
PB_Left(v_rangespec,p3,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_startstr,SYS_PopStringBasePosition());
// endStr   = Mid(rangeSpec, dashPos + 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p4=(integer)(v_dashpos+1);
PB_Mid(v_rangespec,p4,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_endstr,SYS_PopStringBasePosition());
// 
// If startStr = "" And endStr <> ""
void* p5=v_startstr;
void* p6=_S10;
integer c9=0;
if (!(SYS_StringEqual(p6,p5))) { goto no9; }
void* p7=v_endstr;
void* p8=_S10;
if (!((!SYS_StringEqual(p8,p7)))) { goto no9; }
ok9:
c9=1;
no9:;
if (!(c9)) { goto no8; }
// 
// suffixLen = Val(endStr)
quad r1=PB_Val(v_endstr);
v_suffixlen=r1;
// If suffixLen <= 0
if (!((v_suffixlen<=0LL))) { goto no11; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no11:;
// *range\Start = fileSize - suffixLen
p_range->f_start=((quad)v_filesize-(quad)v_suffixlen);
// If *range\Start < 0
if (!((p_range->f_start<0LL))) { goto no13; }
// *range\Start = 0
p_range->f_start=0;
// EndIf
no13:;
// *range\End = fileSize - 1
p_range->f_end=(v_filesize+-1);
// 
// ElseIf startStr <> "" And endStr = ""
goto endif7;
no8:;
void* p9=v_startstr;
void* p10=_S10;
integer c15=0;
if (!((!SYS_StringEqual(p10,p9)))) { goto no15; }
void* p11=v_endstr;
void* p12=_S10;
if (!(SYS_StringEqual(p12,p11))) { goto no15; }
ok15:
c15=1;
no15:;
if (!(c15)) { goto no14; }
ok14:;
// 
// startVal = Val(startStr)
quad r2=PB_Val(v_startstr);
v_startval=r2;
// If startVal < 0 Or startVal >= fileSize
integer c18=0;
if ((v_startval<0LL)) { goto ok18; }
if ((v_startval>=v_filesize)) { goto ok18; }
goto no18;
ok18:
c18=1;
no18:;
if (!(c18)) { goto no17; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no17:;
// *range\Start = startVal
p_range->f_start=v_startval;
// *range\End   = fileSize - 1
p_range->f_end=(v_filesize+-1);
// 
// ElseIf startStr <> "" And endStr <> ""
goto endif7;
no14:;
void* p13=v_startstr;
void* p14=_S10;
integer c20=0;
if (!((!SYS_StringEqual(p14,p13)))) { goto no20; }
void* p15=v_endstr;
void* p16=_S10;
if (!((!SYS_StringEqual(p16,p15)))) { goto no20; }
ok20:
c20=1;
no20:;
if (!(c20)) { goto no19; }
ok19:;
// 
// startVal = Val(startStr)
quad r3=PB_Val(v_startstr);
v_startval=r3;
// endVal   = Val(endStr)
quad r4=PB_Val(v_endstr);
v_endval=r4;
// If startVal < 0 Or endVal < startVal Or startVal >= fileSize
integer c23=0;
if ((v_startval<0LL)) { goto ok23; }
if ((v_endval<v_startval)) { goto ok23; }
goto no23;
ok23:
c23=1;
no23:;
integer c24=0;
if (c23) { goto ok24; }
if ((v_startval>=v_filesize)) { goto ok24; }
goto no24;
ok24:
c24=1;
no24:;
if (!(c24)) { goto no22; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no22:;
// If endVal >= fileSize
if (!((v_endval>=v_filesize))) { goto no26; }
// endVal = fileSize - 1
v_endval=(v_filesize+-1);
// EndIf
no26:;
// *range\Start = startVal
p_range->f_start=v_startval;
// *range\End   = endVal
p_range->f_end=v_endval;
// 
// Else
goto endif7;
no19:;
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
endif7:;
// 
// *range\IsValid = #True
p_range->f_isvalid=1;
// ProcedureReturn #True
r=1LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_endstr);
SYS_FreeString(v_startstr);
SYS_FreeString(v_rangespec);
SYS_FreeString(v_header);
return r;
}
// Procedure.i IsHiddenPath(urlPath.s, hiddenPatterns.s)
static integer f_ishiddenpath(void* v_urlpath,void* v_hiddenpatterns) {
integer r=0;
SYS_FastAllocateString4(&v_urlpath,v_urlpath);
SYS_FastAllocateString4(&v_hiddenpatterns,v_hiddenpatterns);
integer v_patcount=0;
integer v_i=0;
integer v_j=0;
void* v_pattern=0;
void* v_pathpart=0;
integer v_segcount=0;
// Protected i.i, j.i, pathPart.s, pattern.s;;;;
// Protected segCount.i = CountString(urlPath, "/") + 1
integer r0=PB_CountString(v_urlpath,_S9);
v_segcount=(r0+1);
// Protected patCount.i = CountString(hiddenPatterns, ",") + 1
integer r1=PB_CountString(v_hiddenpatterns,_S3);
v_patcount=(r1+1);
// 
// For i = 1 To segCount
v_i=1;
while(1) {
if (!(((integer)v_segcount>=v_i))) { break; }
// pathPart = StringField(urlPath, i, "/")
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_urlpath,v_i,_S9,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_pathpart,SYS_PopStringBasePosition());
// If pathPart = "" : Continue : EndIf
void* p0=v_pathpart;
void* p1=_S10;
if (!(SYS_StringEqual(p1,p0))) { goto no4; }
goto next1;
no4:;
// For j = 1 To patCount
v_j=1;
while(1) {
if (!(((integer)v_patcount>=v_j))) { break; }
// pattern = Trim(StringField(hiddenPatterns, j, ","))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_hiddenpatterns,v_j,_S3,SYS_PopStringBasePosition());
void* p2=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_Trim(p2,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_pattern,SYS_PopStringBasePosition());
// If pattern <> "" And pathPart = pattern
void* p3=v_pattern;
void* p4=_S10;
integer c9=0;
if (!((!SYS_StringEqual(p4,p3)))) { goto no9; }
void* p5=v_pathpart;
void* p6=v_pattern;
if (!(SYS_StringEqual(p6,p5))) { goto no9; }
ok9:
c9=1;
no9:;
if (!(c9)) { goto no8; }
// ProcedureReturn #True
r=1LL;
goto end;
// EndIf
no8:;
// Next j
next5:
v_j+=1;
}
il_next6:;
// Next i
next1:
v_i+=1;
}
il_next2:;
// 
// ProcedureReturn #False
r=0LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_pattern);
SYS_FreeString(v_urlpath);
SYS_FreeString(v_hiddenpatterns);
SYS_FreeString(v_pathpart);
return r;
}
// Procedure InitRewriteEngine()
static integer f_initrewriteengine() {
integer r=0;
integer v_i=0;
void* v_empty=0;
// 
// 
// 
// 
// 
// 
// 
// 
// Protected i.i;
// Protected empty.s = ""    
SYS_FastAllocateStringFree4(&v_empty,_S10);
// For i = 0 To #MAX_GLOBAL_RULES
v_i=0;
while(1) {
if (!(((integer)63LL>=v_i))) { break; }
// g_GR_Pattern(i)     = empty
SYS_PushStringBasePosition();
SYS_CopyString(v_empty);
SYS_AllocateString4(&((void**)a_g_gr_pattern.a)[(integer)v_i],SYS_PopStringBasePosition());
// g_GR_Destination(i) = empty
SYS_PushStringBasePosition();
SYS_CopyString(v_empty);
SYS_AllocateString4(&((void**)a_g_gr_destination.a)[(integer)v_i],SYS_PopStringBasePosition());
// Next
next1:
v_i+=1;
}
il_next2:;
// For i = 0 To #MAX_DIR_CACHE
v_i=0;
while(1) {
if (!(((integer)7LL>=v_i))) { break; }
// g_DC_DirPath(i) = empty
SYS_PushStringBasePosition();
SYS_CopyString(v_empty);
SYS_AllocateString4(&((void**)a_g_dc_dirpath.a)[(integer)v_i],SYS_PopStringBasePosition());
// Next
next3:
v_i+=1;
}
il_next4:;
// For i = 0 To 127
v_i=0;
while(1) {
if (!(((integer)127LL>=v_i))) { break; }
// g_DR_Pattern(i)     = empty
SYS_PushStringBasePosition();
SYS_CopyString(v_empty);
SYS_AllocateString4(&((void**)a_g_dr_pattern.a)[(integer)v_i],SYS_PopStringBasePosition());
// g_DR_Destination(i) = empty
SYS_PushStringBasePosition();
SYS_CopyString(v_empty);
SYS_AllocateString4(&((void**)a_g_dr_destination.a)[(integer)v_i],SYS_PopStringBasePosition());
// Next
next5:
v_i+=1;
}
il_next6:;
// g_RewriteMutex = CreateMutex()
integer r0=PB_CreateMutex();
g_g_rewritemutex=r0;
// EndProcedure
r=0;
end:
SYS_FreeString(v_empty);
return r;
}
// Procedure.s URLDecodePath(s.s)
static void* f_urldecodepath(void* v_s,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_s,v_s);
// ProcedureReturn URLDecoder(s)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_URLDecoder(v_s,SYS_PopStringBasePosition());
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_s);
return r;
}
// Procedure.i ApplyRewrites(path.s, docRoot.s, *result.RewriteResult)
static integer f_applyrewrites(void* v_path,void* v_docroot,s_rewriteresult* p_result) {
integer r=0;
SYS_FastAllocateString4(&v_path,v_path);
SYS_FastAllocateString4(&v_docroot,v_docroot);
integer v_slot=0;
void* v_pfx=0;
integer v_i=0;
void* v_dest=0;
integer v_k=0;
integer v_hit=0;
integer v_ri=0;
void* v_dirpath=0;
void* v_g1=0;
void* v_g2=0;
void* v_g3=0;
void* v_g4=0;
void* v_g5=0;
void* v_g6=0;
void* v_g7=0;
void* v_g8=0;
void* v_g9=0;
void* v_captured=0;
// *result\Action = 0
p_result->f_action=0;
// LockMutex(g_RewriteMutex)
integer p0=(integer)g_g_rewritemutex;
integer r0=PB_LockMutex(p0);
// 
// Protected i.i, k.i;;
// Protected captured.s, pfx.s, dest.s;;;
// Protected hit.i;
// Protected g1.s, g2.s, g3.s, g4.s, g5.s, g6.s, g7.s, g8.s, g9.s;;;;;;;;;
// 
// 
// For i = 0 To g_GR_Count - 1
v_i=0;
while(1) {
if (!(((integer)(g_g_gr_count+-1)>=v_i))) { break; }
// captured = ""
SYS_FastAllocateStringFree4(&v_captured,_S10);
// g1 = "" : g2 = "" : g3 = "" : g4 = "" : g5 = ""
SYS_FastAllocateStringFree4(&v_g1,_S10);
SYS_FastAllocateStringFree4(&v_g2,_S10);
SYS_FastAllocateStringFree4(&v_g3,_S10);
SYS_FastAllocateStringFree4(&v_g4,_S10);
SYS_FastAllocateStringFree4(&v_g5,_S10);
// g6 = "" : g7 = "" : g8 = "" : g9 = ""
SYS_FastAllocateStringFree4(&v_g6,_S10);
SYS_FastAllocateStringFree4(&v_g7,_S10);
SYS_FastAllocateStringFree4(&v_g8,_S10);
SYS_FastAllocateStringFree4(&v_g9,_S10);
// hit = #False
v_hit=0;
// 
// Select g_GR_MatchType(i)
quad pb_select9=((integer*)a_g_gr_matchtype.a)[(integer)v_i];
// Case #MATCH_EXACT
if (pb_select9==0LL) {
// If path = g_GR_Pattern(i)
void* p1=v_path;
void* p2=((void**)a_g_gr_pattern.a)[(integer)v_i];
if (!(SYS_StringEqual(p2,p1))) { goto no4; }
// hit = #True
v_hit=1;
// EndIf
no4:;
// Case #MATCH_GLOB
goto endselect9;}
if (pb_select9==1LL) {
// pfx = g_GR_Pattern(i)
SYS_PushStringBasePosition();
SYS_CopyString(((void**)a_g_gr_pattern.a)[(integer)v_i]);
SYS_AllocateString4(&v_pfx,SYS_PopStringBasePosition());
// If Left(path, Len(pfx)) = pfx
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r1=PB_Len(v_pfx);
PB_Left(v_path,r1,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p3=SYS_PopStringBasePositionValue();
void* p4=v_pfx;
if (!(SYS_StringEqual(p4,p3))) { goto no6; }
// captured = Mid(path, Len(pfx) + 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r2=PB_Len(v_pfx);
integer p5=(integer)(r2+1);
PB_Mid(v_path,p5,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_captured,SYS_PopStringBasePosition());
// hit = #True
v_hit=1;
// EndIf
no6:;
// Case #MATCH_REGEX
goto endselect9;}
if (pb_select9==2LL) {
// If g_GR_RegexHandle(i) > 0
if (!((((integer*)a_g_gr_regexhandle.a)[(integer)v_i]>0LL))) { goto no8; }
// If ExamineRegularExpression(g_GR_RegexHandle(i), path)
integer p6=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
integer r3=PB_ExamineRegularExpression(p6,v_path);
if (!(r3)) { goto no10; }
// If NextRegularExpressionMatch(g_GR_RegexHandle(i))
integer p7=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
integer r4=PB_NextRegularExpressionMatch(p7);
if (!(r4)) { goto no12; }
// g1 = RegularExpressionGroup(g_GR_RegexHandle(i), 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p8=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p8,1LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g1,SYS_PopStringBasePosition());
// g2 = RegularExpressionGroup(g_GR_RegexHandle(i), 2)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p9=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p9,2LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g2,SYS_PopStringBasePosition());
// g3 = RegularExpressionGroup(g_GR_RegexHandle(i), 3)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p10=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p10,3LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g3,SYS_PopStringBasePosition());
// g4 = RegularExpressionGroup(g_GR_RegexHandle(i), 4)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p11=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p11,4LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g4,SYS_PopStringBasePosition());
// g5 = RegularExpressionGroup(g_GR_RegexHandle(i), 5)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p12=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p12,5LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g5,SYS_PopStringBasePosition());
// g6 = RegularExpressionGroup(g_GR_RegexHandle(i), 6)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p13=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p13,6LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g6,SYS_PopStringBasePosition());
// g7 = RegularExpressionGroup(g_GR_RegexHandle(i), 7)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p14=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p14,7LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g7,SYS_PopStringBasePosition());
// g8 = RegularExpressionGroup(g_GR_RegexHandle(i), 8)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p15=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p15,8LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g8,SYS_PopStringBasePosition());
// g9 = RegularExpressionGroup(g_GR_RegexHandle(i), 9)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p16=(integer)((integer*)a_g_gr_regexhandle.a)[(integer)v_i];
PB_RegularExpressionGroup(p16,9LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g9,SYS_PopStringBasePosition());
// hit = #True
v_hit=1;
// EndIf
no12:;
// EndIf
no10:;
// EndIf
no8:;
// EndSelect
}
endselect9:;
// 
// If hit
if (!(v_hit)) { goto no14; }
// dest = SubstPlaceholders_(g_GR_Destination(i), captured,                                  g1, g2, g3, g4, g5, g6, g7, g8, g9)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* p17=(void*)((void**)a_g_gr_destination.a)[(integer)v_i];
void* r5=f_substplaceholders_(p17,v_captured,v_g1,v_g2,v_g3,v_g4,v_g5,v_g6,v_g7,v_g8,v_g9,SYS_PopStringBasePosition());
r5;
SYS_AllocateString4(&v_dest,SYS_PopStringBasePosition());
// If g_GR_RuleType(i) = #RULE_REWRITE
if (!((((integer*)a_g_gr_ruletype.a)[(integer)v_i]==0LL))) { goto no16; }
// *result\Action  = 1
p_result->f_action=1;
// *result\NewPath = dest
SYS_PushStringBasePosition();
SYS_CopyString(v_dest);
SYS_AllocateString4(&p_result->f_newpath,SYS_PopStringBasePosition());
// Else
goto endif15;
no16:;
// *result\Action    = 2
p_result->f_action=2;
// *result\RedirURL  = dest
SYS_PushStringBasePosition();
SYS_CopyString(v_dest);
SYS_AllocateString4(&p_result->f_redirurl,SYS_PopStringBasePosition());
// *result\RedirCode = g_GR_Code(i)
p_result->f_redircode=((integer*)a_g_gr_code.a)[(integer)v_i];
// EndIf
endif15:;
// UnlockMutex(g_RewriteMutex)
integer p18=(integer)g_g_rewritemutex;
integer r6=PB_UnlockMutex(p18);
// ProcedureReturn #True
r=1LL;
goto end;
// EndIf
no14:;
// Next
next1:
v_i+=1;
}
il_next2:;
// 
// 
// Protected dirPath.s = URLDirname_(path)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r7=f_urldirname_(v_path,SYS_PopStringBasePosition());
r7;
SYS_AllocateString4(&v_dirpath,SYS_PopStringBasePosition());
// Protected slot.i = LoadDirRulesIfNeeded_(dirPath, docRoot)
integer r8=f_loaddirrulesifneeded_(v_dirpath,v_docroot);
v_slot=r8;
// If slot >= 0
if (!((v_slot>=0LL))) { goto no19; }
// Protected ri.i;
// For k = 0 To g_DC_RuleCount(slot) - 1
v_k=0;
while(1) {
if (!(((integer)(((integer*)a_g_dc_rulecount.a)[(integer)v_slot]+-1)>=v_k))) { break; }
// ri = slot * #DR_STRIDE + k
v_ri=((quad)((quad)v_slot*(quad)16LL)+(quad)v_k);
// captured = ""
SYS_FastAllocateStringFree4(&v_captured,_S10);
// g1 = "" : g2 = "" : g3 = "" : g4 = "" : g5 = ""
SYS_FastAllocateStringFree4(&v_g1,_S10);
SYS_FastAllocateStringFree4(&v_g2,_S10);
SYS_FastAllocateStringFree4(&v_g3,_S10);
SYS_FastAllocateStringFree4(&v_g4,_S10);
SYS_FastAllocateStringFree4(&v_g5,_S10);
// g6 = "" : g7 = "" : g8 = "" : g9 = ""
SYS_FastAllocateStringFree4(&v_g6,_S10);
SYS_FastAllocateStringFree4(&v_g7,_S10);
SYS_FastAllocateStringFree4(&v_g8,_S10);
SYS_FastAllocateStringFree4(&v_g9,_S10);
// hit = #False
v_hit=0;
// 
// Select g_DR_MatchType(ri)
quad pb_select10=((integer*)a_g_dr_matchtype.a)[(integer)v_ri];
// Case #MATCH_EXACT
if (pb_select10==0LL) {
// If path = g_DR_Pattern(ri)
void* p19=v_path;
void* p20=((void**)a_g_dr_pattern.a)[(integer)v_ri];
if (!(SYS_StringEqual(p20,p19))) { goto no23; }
// hit = #True
v_hit=1;
// EndIf
no23:;
// Case #MATCH_GLOB
goto endselect10;}
if (pb_select10==1LL) {
// pfx = g_DR_Pattern(ri)
SYS_PushStringBasePosition();
SYS_CopyString(((void**)a_g_dr_pattern.a)[(integer)v_ri]);
SYS_AllocateString4(&v_pfx,SYS_PopStringBasePosition());
// If Left(path, Len(pfx)) = pfx
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r9=PB_Len(v_pfx);
PB_Left(v_path,r9,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p21=SYS_PopStringBasePositionValue();
void* p22=v_pfx;
if (!(SYS_StringEqual(p22,p21))) { goto no25; }
// captured = Mid(path, Len(pfx) + 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r10=PB_Len(v_pfx);
integer p23=(integer)(r10+1);
PB_Mid(v_path,p23,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_captured,SYS_PopStringBasePosition());
// hit = #True
v_hit=1;
// EndIf
no25:;
// Case #MATCH_REGEX
goto endselect10;}
if (pb_select10==2LL) {
// If g_DR_RegexHandle(ri) > 0
if (!((((integer*)a_g_dr_regexhandle.a)[(integer)v_ri]>0LL))) { goto no27; }
// If ExamineRegularExpression(g_DR_RegexHandle(ri), path)
integer p24=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
integer r11=PB_ExamineRegularExpression(p24,v_path);
if (!(r11)) { goto no29; }
// If NextRegularExpressionMatch(g_DR_RegexHandle(ri))
integer p25=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
integer r12=PB_NextRegularExpressionMatch(p25);
if (!(r12)) { goto no31; }
// g1 = RegularExpressionGroup(g_DR_RegexHandle(ri), 1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p26=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p26,1LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g1,SYS_PopStringBasePosition());
// g2 = RegularExpressionGroup(g_DR_RegexHandle(ri), 2)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p27=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p27,2LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g2,SYS_PopStringBasePosition());
// g3 = RegularExpressionGroup(g_DR_RegexHandle(ri), 3)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p28=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p28,3LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g3,SYS_PopStringBasePosition());
// g4 = RegularExpressionGroup(g_DR_RegexHandle(ri), 4)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p29=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p29,4LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g4,SYS_PopStringBasePosition());
// g5 = RegularExpressionGroup(g_DR_RegexHandle(ri), 5)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p30=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p30,5LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g5,SYS_PopStringBasePosition());
// g6 = RegularExpressionGroup(g_DR_RegexHandle(ri), 6)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p31=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p31,6LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g6,SYS_PopStringBasePosition());
// g7 = RegularExpressionGroup(g_DR_RegexHandle(ri), 7)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p32=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p32,7LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g7,SYS_PopStringBasePosition());
// g8 = RegularExpressionGroup(g_DR_RegexHandle(ri), 8)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p33=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p33,8LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g8,SYS_PopStringBasePosition());
// g9 = RegularExpressionGroup(g_DR_RegexHandle(ri), 9)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer p34=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
PB_RegularExpressionGroup(p34,9LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_g9,SYS_PopStringBasePosition());
// hit = #True
v_hit=1;
// EndIf
no31:;
// EndIf
no29:;
// EndIf
no27:;
// EndSelect
}
endselect10:;
// 
// If hit
if (!(v_hit)) { goto no33; }
// dest = SubstPlaceholders_(g_DR_Destination(ri), captured,                                    g1, g2, g3, g4, g5, g6, g7, g8, g9)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* p35=(void*)((void**)a_g_dr_destination.a)[(integer)v_ri];
void* r13=f_substplaceholders_(p35,v_captured,v_g1,v_g2,v_g3,v_g4,v_g5,v_g6,v_g7,v_g8,v_g9,SYS_PopStringBasePosition());
r13;
SYS_AllocateString4(&v_dest,SYS_PopStringBasePosition());
// If g_DR_RuleType(ri) = #RULE_REWRITE
if (!((((integer*)a_g_dr_ruletype.a)[(integer)v_ri]==0LL))) { goto no35; }
// *result\Action  = 1
p_result->f_action=1;
// *result\NewPath = dest
SYS_PushStringBasePosition();
SYS_CopyString(v_dest);
SYS_AllocateString4(&p_result->f_newpath,SYS_PopStringBasePosition());
// Else
goto endif34;
no35:;
// *result\Action    = 2
p_result->f_action=2;
// *result\RedirURL  = dest
SYS_PushStringBasePosition();
SYS_CopyString(v_dest);
SYS_AllocateString4(&p_result->f_redirurl,SYS_PopStringBasePosition());
// *result\RedirCode = g_DR_Code(ri)
p_result->f_redircode=((integer*)a_g_dr_code.a)[(integer)v_ri];
// EndIf
endif34:;
// UnlockMutex(g_RewriteMutex)
integer p36=(integer)g_g_rewritemutex;
integer r14=PB_UnlockMutex(p36);
// ProcedureReturn #True
r=1LL;
goto end;
// EndIf
no33:;
// Next
next20:
v_k+=1;
}
il_next21:;
// EndIf
no19:;
// 
// UnlockMutex(g_RewriteMutex)
integer p37=(integer)g_g_rewritemutex;
integer r15=PB_UnlockMutex(p37);
// ProcedureReturn #False
r=0LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_path);
SYS_FreeString(v_pfx);
SYS_FreeString(v_dest);
SYS_FreeString(v_docroot);
SYS_FreeString(v_dirpath);
SYS_FreeString(v_g1);
SYS_FreeString(v_g2);
SYS_FreeString(v_g3);
SYS_FreeString(v_g4);
SYS_FreeString(v_g5);
SYS_FreeString(v_g6);
SYS_FreeString(v_g7);
SYS_FreeString(v_g8);
SYS_FreeString(v_g9);
SYS_FreeString(v_captured);
return r;
}
// Procedure.s BuildDirectoryListing(dirPath.s, urlPath.s)
static void* f_builddirectorylisting(void* v_dirpath,void* v_urlpath,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_dirpath,v_dirpath);
SYS_FastAllocateString4(&v_urlpath,v_urlpath);
quad v_entdate=0;
void* v_name=0;
integer v_entsize=0;
void* v_entpath=0;
void* v_result=0;
void* v_href=0;
void* v_sizestr=0;
pb_list t_dirs={0};
pb_list t_files={0};
// Protected result.s, name.s, href.s, sizeStr.s;;;;
// Protected entPath.s, entSize.i, entDate.q;;;
// 
// 
// If Right(dirPath, 1) <> "/" And Right(dirPath, 1) <> "\"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_dirpath,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S9;
integer c3=0;
if (!((!SYS_StringEqual(p1,p0)))) { goto no3; }
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_dirpath,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p2=SYS_PopStringBasePositionValue();
void* p3=_S140;
if (!((!SYS_StringEqual(p3,p2)))) { goto no3; }
ok3:
c3=1;
no3:;
if (!(c3)) { goto no2; }
// dirPath + "/"
SYS_PushStringBasePosition();
SYS_CopyString(v_dirpath);
SYS_CopyString(_S9);
SYS_AllocateString4(&v_dirpath,SYS_PopStringBasePosition());
// EndIf
no2:;
// If Right(urlPath, 1) <> "/"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_urlpath,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p4=SYS_PopStringBasePositionValue();
void* p5=_S9;
if (!((!SYS_StringEqual(p5,p4)))) { goto no5; }
// urlPath + "/"
SYS_PushStringBasePosition();
SYS_CopyString(v_urlpath);
SYS_CopyString(_S9);
SYS_AllocateString4(&v_urlpath,SYS_PopStringBasePosition());
// EndIf
no5:;
// 
// 
// Protected NewList dirs.s()
PB_NewList(8,&t_dirs,ms_s,8);;
// Protected NewList files.s()
PB_NewList(8,&t_files,ms_s,8);;
// 
// If Not ExamineDirectory(0, dirPath, "*")
integer r0=PB_ExamineDirectory(0LL,v_dirpath,_S121);
if (!(!(r0))) { goto no7; }
// ProcedureReturn ""
SYS_PushStringBasePosition();
SYS_CopyString(_S10);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndIf
no7:;
// 
// While NextDirectoryEntry(0)
while (1) {
integer r1=PB_NextDirectoryEntry(0LL);
if (!(r1)) { break; }
// name = DirectoryEntryName(0)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_DirectoryEntryName(0LL,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_name,SYS_PopStringBasePosition());
// If name = "." Or name = ".."
void* p6=v_name;
void* p7=_S11;
integer c11=0;
if (SYS_StringEqual(p7,p6)) { goto ok11; }
void* p8=v_name;
void* p9=_S12;
if (SYS_StringEqual(p9,p8)) { goto ok11; }
goto no11;
ok11:
c11=1;
no11:;
if (!(c11)) { goto no10; }
// Continue
continue;
// EndIf
no10:;
// If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
integer r2=PB_DirectoryEntryType(0LL);
if (!((r2==2))) { goto no13; }
// AddElement(dirs())  : dirs()  = name
void* p10=(void*)(t_dirs.a);
integer r3=PB_AddElement(p10);
SYS_PushStringBasePosition();
SYS_CopyString(v_name);
SYS_AllocateString4(&(*(void**)&t_dirs.b->c),SYS_PopStringBasePosition());
// Else
goto endif12;
no13:;
// AddElement(files()) : files() = name
void* p11=(void*)(t_files.a);
integer r4=PB_AddElement(p11);
SYS_PushStringBasePosition();
SYS_CopyString(v_name);
SYS_AllocateString4(&(*(void**)&t_files.b->c),SYS_PopStringBasePosition());
// EndIf
endif12:;
// Wend
}
il_wend8:;
// FinishDirectory(0)
integer r5=PB_FinishDirectory(0LL);
// 
// SortList(dirs(),  #PB_Sort_Ascending | #PB_Sort_NoCase)
void* p12=(void*)(t_dirs.a);
integer r6=PB_SortList(p12,2LL);
// SortList(files(), #PB_Sort_Ascending | #PB_Sort_NoCase)
void* p13=(void*)(t_files.a);
integer r7=PB_SortList(p13,2LL);
// 
// 
// result  = "<!DOCTYPE html>" + #LF$
SYS_FastAllocateStringFree4(&v_result,_S164);
// result + "<html><head><meta charset='utf-8'>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S165);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<title>Index of " + urlPath + "</title>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S166);
SYS_CopyString(v_urlpath);
SYS_CopyString(_S167);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<style>"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S168);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "body{font-family:monospace;padding:1em}"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S169);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "table{border-collapse:collapse;width:100%}"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S170);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "th,td{text-align:left;padding:4px 12px;border-bottom:1px solid #ddd}"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S171);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "th{background:#f4f4f4}"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S172);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "a{text-decoration:none}a:hover{text-decoration:underline}"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S173);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "</style></head><body>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S174);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<h2>Index of " + urlPath + "</h2>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S175);
SYS_CopyString(v_urlpath);
SYS_CopyString(_S176);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<table><tr><th>Name</th><th>Size</th><th>Modified</th></tr>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S177);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// 
// 
// If urlPath <> "/"
void* p14=v_urlpath;
void* p15=_S9;
if (!((!SYS_StringEqual(p15,p14)))) { goto no16; }
// result + "<tr><td><a href='../'>../</a></td><td>-</td><td>-</td></tr>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S178);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// EndIf
no16:;
// 
// 
// ForEach dirs()
PB_ResetList(t_dirs.a);
while (PB_NextElement(t_dirs.a)) {
// href    = urlPath + URLEncoder(dirs()) + "/"
SYS_PushStringBasePosition();
SYS_CopyString(v_urlpath);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* p16=(void*)(*(void**)&t_dirs.b->c);
PB_URLEncoder(p16,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S9);
SYS_AllocateString4(&v_href,SYS_PopStringBasePosition());
// result + "<tr><td><a href='" + href + "'>" + dirs() + "/</a></td>"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S179);
SYS_CopyString(v_href);
SYS_CopyString(_S180);
SYS_CopyString((*(void**)&t_dirs.b->c));
SYS_CopyString(_S181);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<td>-</td><td>-</td></tr>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S182);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// Next
}
il_next17:;
// 
// 
// ForEach files()
PB_ResetList(t_files.a);
while (PB_NextElement(t_files.a)) {
// href    = urlPath + URLEncoder(files())
SYS_PushStringBasePosition();
SYS_CopyString(v_urlpath);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* p17=(void*)(*(void**)&t_files.b->c);
PB_URLEncoder(p17,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_AllocateString4(&v_href,SYS_PopStringBasePosition());
// entPath = dirPath + files()
SYS_PushStringBasePosition();
SYS_CopyString(v_dirpath);
SYS_CopyString((*(void**)&t_files.b->c));
SYS_AllocateString4(&v_entpath,SYS_PopStringBasePosition());
// entSize = FileSize(entPath)
quad r8=PB_FileSize(v_entpath);
v_entsize=r8;
// entDate = GetFileDate(entPath, #PB_Date_Modified)
quad r9=PB_GetFileDate(v_entpath,2LL);
v_entdate=r9;
// 
// If entSize < 1024
if (!((v_entsize<1024LL))) { goto no20; }
// sizeStr = Str(entSize) + " B"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_entsize,SYS_PopStringBasePosition());
SYS_CopyString(_S183);
SYS_AllocateString4(&v_sizestr,SYS_PopStringBasePosition());
// ElseIf entSize < 1048576
goto endif19;
no20:;
if (!((v_entsize<1048576LL))) { goto no21; }
ok21:;
// sizeStr = StrF(entSize / 1024.0, 1) + " KB"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
float p18=(float)((double)v_entsize/1024.0);
PB_StrF2(p18,1LL,SYS_PopStringBasePosition());
SYS_CopyString(_S184);
SYS_AllocateString4(&v_sizestr,SYS_PopStringBasePosition());
// Else
goto endif19;
no21:;
// sizeStr = StrF(entSize / 1048576.0, 1) + " MB"
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
float p19=(float)((double)v_entsize/1048576.0);
PB_StrF2(p19,1LL,SYS_PopStringBasePosition());
SYS_CopyString(_S185);
SYS_AllocateString4(&v_sizestr,SYS_PopStringBasePosition());
// EndIf
endif19:;
// 
// result + "<tr><td><a href='" + href + "'>" + files() + "</a></td>"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S179);
SYS_CopyString(v_href);
SYS_CopyString(_S180);
SYS_CopyString((*(void**)&t_files.b->c));
SYS_CopyString(_S186);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<td>" + sizeStr + "</td>"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S187);
SYS_CopyString(v_sizestr);
SYS_CopyString(_S188);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<td>" + HTTPDate(entDate) + "</td></tr>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S187);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r10=f_httpdate(v_entdate,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S189);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// Next
}
il_next18:;
// 
// result + "</table>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S190);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "<hr><small>" + #APP_NAME + " v" + #APP_VERSION + "</small>" + #LF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S191);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "</body></html>"
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S192);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// 
// FreeList(dirs())
void* p20=(void*)(t_dirs.a);
integer r11=PB_FreeList(p20);
// FreeList(files())
void* p21=(void*)(t_files.a);
integer r12=PB_FreeList(p21);
// 
// ProcedureReturn result
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_name);
SYS_FreeString(v_entpath);
SYS_FreeString(v_result);
SYS_FreeString(v_href);
SYS_FreeString(v_urlpath);
SYS_FreeString(v_dirpath);
SYS_FreeString(v_sizestr);
PB_FreeList(t_dirs.a);
PB_FreeList(t_files.a);
return r;
}
// Procedure RotateLog(*fh, logPath.s)
static integer f_rotatelog(integer p_fh,void* v_logpath) {
integer r=0;
SYS_FastAllocateString4(&v_logpath,v_logpath);
void* v_archive=0;
void* v_stem=0;
void* v_base=0;
void* v_ext=0;
integer v_fh=0;
void* v_dir=0;
// Protected fh.i = PeekI(*fh)
quad p0=(quad)p_fh;
quad r0=PB_PeekI(p0);
v_fh=r0;
// If fh > 0
if (!((v_fh>0LL))) { goto no2; }
// FlushFileBuffers(fh)
integer r1=PB_FlushFileBuffers(v_fh);
// CloseFile(fh)
integer r2=PB_CloseFile(v_fh);
// PokeI(*fh, 0)
quad p1=(quad)p_fh;
integer r3=PB_PokeI(p1,0LL);
// EndIf
no2:;
// 
// Protected dir.s  = GetPathPart(logPath)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetPathPart(v_logpath,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_dir,SYS_PopStringBasePosition());
// Protected base.s = GetFilePart(logPath)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetFilePart(v_logpath,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_base,SYS_PopStringBasePosition());
// Protected ext.s  = LCase(GetExtensionPart(base))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_GetExtensionPart(v_base,SYS_PopStringBasePosition());
void* p2=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_LCase(p2,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_ext,SYS_PopStringBasePosition());
// Protected stem.s = Left(base, Len(base) - Bool(ext <> "") * (Len(ext) + 1))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
integer r4=PB_Len(v_base);
void* p7=v_ext;
void* p8=_S10;
int r5=(((!SYS_StringEqual(p8,p7)))?1:0);
integer r6=PB_Len(v_ext);
integer p9=(integer)(r4-((integer)r5*(integer)((r6+1))));
PB_Left(v_base,p9,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_stem,SYS_PopStringBasePosition());
// Protected archive.s;
// If ext <> ""
void* p10=v_ext;
void* p11=_S10;
if (!((!SYS_StringEqual(p11,p10)))) { goto no4; }
// archive = dir + stem + "." + RotationStamp() + "." + ext
SYS_PushStringBasePosition();
SYS_CopyString(v_dir);
SYS_CopyString(v_stem);
SYS_CopyString(_S11);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r7=f_rotationstamp(SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S11);
SYS_CopyString(v_ext);
SYS_AllocateString4(&v_archive,SYS_PopStringBasePosition());
// Else
goto endif3;
no4:;
// archive = dir + stem + "." + RotationStamp()
SYS_PushStringBasePosition();
SYS_CopyString(v_dir);
SYS_CopyString(v_stem);
SYS_CopyString(_S11);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r8=f_rotationstamp(SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_AllocateString4(&v_archive,SYS_PopStringBasePosition());
// EndIf
endif3:;
// 
// RenameFile(logPath, archive)
integer r9=PB_RenameFile(v_logpath,v_archive);
// PokeI(*fh, CreateFile(#PB_Any, logPath))
integer r10=PB_CreateFile(-1LL,v_logpath);
quad p12=(quad)p_fh;
integer r11=PB_PokeI(p12,r10);
// PruneArchives(logPath)
integer r12=f_prunearchives(v_logpath);
// EndProcedure
r=0;
end:
SYS_FreeString(v_archive);
SYS_FreeString(v_logpath);
SYS_FreeString(v_stem);
SYS_FreeString(v_base);
SYS_FreeString(v_ext);
SYS_FreeString(v_dir);
return r;
}
// Procedure.s BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i)
static void* f_buildresponseheaders(integer v_statuscode,void* v_extraheaders,integer v_bodylen,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_extraheaders,v_extraheaders);
void* v_result=0;
// Protected result.s;
// result = "HTTP/1.1 " + Str(statusCode) + " " + StatusText(statusCode) + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(_S30);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_statuscode,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S6);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r0=f_statustext(v_statuscode,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S13);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "Server: " + #APP_NAME + "/" + #APP_VERSION + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S31);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "Content-Length: " + Str(bodyLen) + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S32);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_bodylen,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S13);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// result + "Connection: close" + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S33);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// If extraHeaders <> ""
void* p0=v_extraheaders;
void* p1=_S10;
if (!((!SYS_StringEqual(p1,p0)))) { goto no2; }
// result + extraHeaders
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(v_extraheaders);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// EndIf
no2:;
// result + #CRLF$  
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
SYS_CopyString(_S13);
SYS_AllocateString4(&v_result,SYS_PopStringBasePosition());
// ProcedureReturn result
SYS_PushStringBasePosition();
SYS_CopyString(v_result);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_result);
SYS_FreeString(v_extraheaders);
return r;
}
// Procedure WriteRuleFile_(path.s, content.s)
static integer f_writerulefile_(void* v_path,void* v_content) {
integer r=0;
SYS_FastAllocateString4(&v_path,v_path);
SYS_FastAllocateString4(&v_content,v_content);
integer v_f=0;
// Protected f.i = CreateFile(#PB_Any, path)
integer r0=PB_CreateFile(-1LL,v_path);
v_f=r0;
// If f
if (!(v_f)) { goto no2; }
// WriteString(f, content, #PB_Ascii)
integer r1=PB_WriteString2(v_f,v_content,24LL);
// CloseFile(f)
integer r2=PB_CloseFile(v_f);
// EndIf
no2:;
// EndProcedure
r=0;
end:
SYS_FreeString(v_path);
SYS_FreeString(v_content);
return r;
}
// Procedure.i LoadDirRulesIfNeeded_(dirPath.s, docRoot.s)
static integer f_loaddirrulesifneeded_(void* v_dirpath,void* v_docroot) {
integer r=0;
SYS_FastAllocateString4(&v_dirpath,v_dirpath);
SYS_FastAllocateString4(&v_docroot,v_docroot);
volatile s_rewriterule v_tmp2={0};
volatile s_rewriterule v_tmp={0};
void* v_dirfs=0;
integer v_f=0;
integer v_i=0;
integer v_j=0;
quad v_mtime=0;
integer v_ri=0;
void* v_confpath=0;
// Protected dirFS.s = docRoot + dirPath
SYS_PushStringBasePosition();
SYS_CopyString(v_docroot);
SYS_CopyString(v_dirpath);
SYS_AllocateString4(&v_dirfs,SYS_PopStringBasePosition());
// If Right(dirFS, 1) <> "/" : dirFS + "/" : EndIf
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Right(v_dirfs,1LL,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=SYS_PopStringBasePositionValue();
void* p1=_S9;
if (!((!SYS_StringEqual(p1,p0)))) { goto no2; }
SYS_PushStringBasePosition();
SYS_CopyString(v_dirfs);
SYS_CopyString(_S9);
SYS_AllocateString4(&v_dirfs,SYS_PopStringBasePosition());
no2:;
// Protected confPath.s = dirFS + "rewrite.conf"
SYS_PushStringBasePosition();
SYS_CopyString(v_dirfs);
SYS_CopyString(_S230);
PB_StringBasePosition+=2;
SYS_AllocateString4(&v_confpath,SYS_PopStringBasePosition());
// 
// Protected mtime.q = GetFileDate(confPath, #PB_Date_Modified)
quad r0=PB_GetFileDate(v_confpath,2LL);
v_mtime=r0;
// If mtime <= 0 : ProcedureReturn -1 : EndIf
if (!((v_mtime<=0LL))) { goto no4; }
r=-1LL;
goto end;
no4:;
// 
// Protected i.i, j.i, ri.i, f.i;;;;
// Protected tmp.RewriteRule;
// 
// 
// For i = 0 To g_DC_Count - 1
v_i=0;
while(1) {
if (!(((integer)(g_g_dc_count+-1)>=v_i))) { break; }
// If g_DC_DirPath(i) = dirPath
void* p2=((void**)a_g_dc_dirpath.a)[(integer)v_i];
void* p3=v_dirpath;
if (!(SYS_StringEqual(p3,p2))) { goto no8; }
// If g_DC_FileMtime(i) <> mtime
if (!((((quad*)a_g_dc_filemtime.a)[(integer)v_i]!=v_mtime))) { goto no10; }
// 
// For j = 0 To g_DC_RuleCount(i) - 1
v_j=0;
while(1) {
if (!(((integer)(((integer*)a_g_dc_rulecount.a)[(integer)v_i]+-1)>=v_j))) { break; }
// ri = i * #DR_STRIDE + j
v_ri=((quad)((quad)v_i*(quad)16LL)+(quad)v_j);
// If g_DR_RegexHandle(ri) > 0
if (!((((integer*)a_g_dr_regexhandle.a)[(integer)v_ri]>0LL))) { goto no14; }
// FreeRegularExpression(g_DR_RegexHandle(ri))
integer p4=(integer)((integer*)a_g_dr_regexhandle.a)[(integer)v_ri];
integer r1=PB_FreeRegularExpression(p4);
// g_DR_RegexHandle(ri) = 0
((integer*)a_g_dr_regexhandle.a)[(integer)v_ri]=0;
// EndIf
no14:;
// Next
next11:
v_j+=1;
}
il_next12:;
// g_DC_RuleCount(i) = 0
((integer*)a_g_dc_rulecount.a)[(integer)v_i]=0;
// 
// f = ReadFile(#PB_Any, confPath)
integer r2=PB_ReadFile(-1LL,v_confpath);
v_f=r2;
// If f
if (!(v_f)) { goto no16; }
// While Not Eof(f) And g_DC_RuleCount(i) < #DR_STRIDE
while (1) {
integer r3=PB_Eof(v_f);
integer c18=0;
if (!(!(r3))) { goto no18; }
if (!((((integer*)a_g_dc_rulecount.a)[(integer)v_i]<16LL))) { goto no18; }
ok18:
c18=1;
no18:;
if (!(c18)) { break; }
// If ParseRule_(ReadString(f), @tmp)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReadString(v_f,SYS_PopStringBasePosition());
void* p5=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer p6=(integer)((integer)(&v_tmp));
integer r4=f_parserule_(p5,p6);
SYS_PopStringBasePositionUpdate();
if (!(r4)) { goto no20; }
// j = i * #DR_STRIDE + g_DC_RuleCount(i)
v_j=((quad)((quad)v_i*(quad)16LL)+(quad)((integer*)a_g_dc_rulecount.a)[(integer)v_i]);
// g_DR_RuleType(j)    = tmp\RuleType
((integer*)a_g_dr_ruletype.a)[(integer)v_j]=v_tmp.f_ruletype;
// g_DR_MatchType(j)   = tmp\MatchType
((integer*)a_g_dr_matchtype.a)[(integer)v_j]=v_tmp.f_matchtype;
// g_DR_Pattern(j)     = tmp\Pattern
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp.f_pattern);
SYS_AllocateString4(&((void**)a_g_dr_pattern.a)[(integer)v_j],SYS_PopStringBasePosition());
// g_DR_Destination(j) = tmp\Destination
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp.f_destination);
SYS_AllocateString4(&((void**)a_g_dr_destination.a)[(integer)v_j],SYS_PopStringBasePosition());
// g_DR_Code(j)        = tmp\Code
((integer*)a_g_dr_code.a)[(integer)v_j]=v_tmp.f_code;
// g_DR_RegexHandle(j) = tmp\RegexHandle
((integer*)a_g_dr_regexhandle.a)[(integer)v_j]=v_tmp.f_regexhandle;
// g_DC_RuleCount(i) + 1
((integer*)a_g_dc_rulecount.a)[(integer)v_i]=(((integer*)a_g_dc_rulecount.a)[(integer)v_i]+1);
// EndIf
no20:;
// Wend
}
il_wend17:;
// CloseFile(f)
integer r5=PB_CloseFile(v_f);
// EndIf
no16:;
// g_DC_FileMtime(i) = mtime
((quad*)a_g_dc_filemtime.a)[(integer)v_i]=v_mtime;
// EndIf
no10:;
// ProcedureReturn i
r=v_i;
goto end;
// EndIf
no8:;
// Next
next5:
v_i+=1;
}
il_next6:;
// 
// 
// If g_DC_Count > #MAX_DIR_CACHE : ProcedureReturn -1 : EndIf
if (!((g_g_dc_count>7LL))) { goto no22; }
r=-1LL;
goto end;
no22:;
// i = g_DC_Count
v_i=g_g_dc_count;
// g_DC_DirPath(i)   = dirPath
SYS_PushStringBasePosition();
SYS_CopyString(v_dirpath);
SYS_AllocateString4(&((void**)a_g_dc_dirpath.a)[(integer)v_i],SYS_PopStringBasePosition());
// g_DC_FileMtime(i) = mtime
((quad*)a_g_dc_filemtime.a)[(integer)v_i]=v_mtime;
// g_DC_RuleCount(i) = 0
((integer*)a_g_dc_rulecount.a)[(integer)v_i]=0;
// f = ReadFile(#PB_Any, confPath)
integer r6=PB_ReadFile(-1LL,v_confpath);
v_f=r6;
// If f
if (!(v_f)) { goto no24; }
// Protected tmp2.RewriteRule;
// While Not Eof(f) And g_DC_RuleCount(i) < #DR_STRIDE
while (1) {
integer r7=PB_Eof(v_f);
integer c26=0;
if (!(!(r7))) { goto no26; }
if (!((((integer*)a_g_dc_rulecount.a)[(integer)v_i]<16LL))) { goto no26; }
ok26:
c26=1;
no26:;
if (!(c26)) { break; }
// If ParseRule_(ReadString(f), @tmp2)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReadString(v_f,SYS_PopStringBasePosition());
void* p7=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer p8=(integer)((integer)(&v_tmp2));
integer r8=f_parserule_(p7,p8);
SYS_PopStringBasePositionUpdate();
if (!(r8)) { goto no28; }
// j = i * #DR_STRIDE + g_DC_RuleCount(i)
v_j=((quad)((quad)v_i*(quad)16LL)+(quad)((integer*)a_g_dc_rulecount.a)[(integer)v_i]);
// g_DR_RuleType(j)    = tmp2\RuleType
((integer*)a_g_dr_ruletype.a)[(integer)v_j]=v_tmp2.f_ruletype;
// g_DR_MatchType(j)   = tmp2\MatchType
((integer*)a_g_dr_matchtype.a)[(integer)v_j]=v_tmp2.f_matchtype;
// g_DR_Pattern(j)     = tmp2\Pattern
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp2.f_pattern);
SYS_AllocateString4(&((void**)a_g_dr_pattern.a)[(integer)v_j],SYS_PopStringBasePosition());
// g_DR_Destination(j) = tmp2\Destination
SYS_PushStringBasePosition();
SYS_CopyString(v_tmp2.f_destination);
SYS_AllocateString4(&((void**)a_g_dr_destination.a)[(integer)v_j],SYS_PopStringBasePosition());
// g_DR_Code(j)        = tmp2\Code
((integer*)a_g_dr_code.a)[(integer)v_j]=v_tmp2.f_code;
// g_DR_RegexHandle(j) = tmp2\RegexHandle
((integer*)a_g_dr_regexhandle.a)[(integer)v_j]=v_tmp2.f_regexhandle;
// g_DC_RuleCount(i) + 1
((integer*)a_g_dc_rulecount.a)[(integer)v_i]=(((integer*)a_g_dc_rulecount.a)[(integer)v_i]+1);
// EndIf
no28:;
// Wend
}
il_wend25:;
// CloseFile(f)
integer r9=PB_CloseFile(v_f);
// EndIf
no24:;
// g_DC_Count + 1
g_g_dc_count=(g_g_dc_count+1);
// ProcedureReturn i
r=v_i;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeStructureStrings(&v_tmp2,ms_rewriterule);
SYS_FreeStructureStrings(&v_tmp,ms_rewriterule);
SYS_FreeString(v_dirfs);
SYS_FreeString(v_confpath);
SYS_FreeString(v_docroot);
SYS_FreeString(v_dirpath);
return r;
}
// Procedure.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
static integer f_sendpartialresponse(integer v_connection,void* v_fspath,s_rangespec* p_range,void* v_mimetype,integer v_filesize) {
integer r=0;
SYS_FastAllocateString4(&v_fspath,v_fspath);
SYS_FastAllocateString4(&v_mimetype,v_mimetype);
void* v_contentrange=0;
void* v_extraheaders=0;
integer v_file=0;
integer v_rangelen=0;
integer p_buffer=0;
// Protected rangeLen.i   = *range\End - *range\Start + 1
v_rangelen=(((quad)p_range->f_end-(quad)p_range->f_start)+1);
// Protected contentRange.s, extraHeaders.s;;
// Protected *buffer, file.i;;
// 
// If rangeLen <= 0
if (!((v_rangelen<=0LL))) { goto no2; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no2:;
// 
// *buffer = AllocateMemory(rangeLen + 1)
integer p0=(integer)(v_rangelen+1);
integer r0=PB_AllocateMemory(p0);
p_buffer=(void*)r0;
// If *buffer = 0
if (!(((integer)p_buffer==0))) { goto no4; }
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no4:;
// 
// file = ReadFile(#PB_Any, fsPath)
integer r1=PB_ReadFile(-1LL,v_fspath);
v_file=r1;
// If file = 0
if (!((v_file==0LL))) { goto no6; }
// FreeMemory(*buffer)
integer p1=(integer)p_buffer;
integer r2=PB_FreeMemory(p1);
// ProcedureReturn #False
r=0LL;
goto end;
// EndIf
no6:;
// 
// FileSeek(file, *range\Start)
quad p2=(quad)p_range->f_start;
integer r3=PB_FileSeek(v_file,p2);
// ReadData(file, *buffer, rangeLen)
integer p3=(integer)p_buffer;
integer r4=PB_ReadData(v_file,p3,v_rangelen);
// CloseFile(file)
integer r5=PB_CloseFile(v_file);
// 
// contentRange  = "bytes " + Str(*range\Start) + "-" + Str(*range\End) + "/" + Str(fileSize)
SYS_PushStringBasePosition();
SYS_CopyString(_S194);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p4=(quad)p_range->f_start;
PB_Str(p4,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S117);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p5=(quad)p_range->f_end;
PB_Str(p5,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S9);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Str(v_filesize,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_AllocateString4(&v_contentrange,SYS_PopStringBasePosition());
// extraHeaders  = "Content-Type: "  + mimeType       + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(_S34);
SYS_CopyString(v_mimetype);
SYS_CopyString(_S13);
SYS_AllocateString4(&v_extraheaders,SYS_PopStringBasePosition());
// extraHeaders + "Content-Range: "  + contentRange   + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(v_extraheaders);
SYS_CopyString(_S195);
SYS_CopyString(v_contentrange);
SYS_CopyString(_S13);
SYS_AllocateString4(&v_extraheaders,SYS_PopStringBasePosition());
// extraHeaders + "Cache-Control: "  + "max-age=0"    + #CRLF$
SYS_PushStringBasePosition();
SYS_CopyString(v_extraheaders);
SYS_CopyString(_S158);
SYS_AllocateString4(&v_extraheaders,SYS_PopStringBasePosition());
// 
// SendNetworkString(connection, BuildResponseHeaders(#HTTP_206, extraHeaders, rangeLen), #PB_Ascii)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r6=f_buildresponseheaders(206LL,v_extraheaders,v_rangelen,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p6=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r7=PB_SendNetworkString2(v_connection,p6,24LL);
SYS_PopStringBasePositionUpdate();
// SendNetworkData(connection, *buffer, rangeLen)
integer p7=(integer)p_buffer;
integer r8=PB_SendNetworkData(v_connection,p7,v_rangelen);
// 
// FreeMemory(*buffer)
integer p8=(integer)p_buffer;
integer r9=PB_FreeMemory(p8);
// ProcedureReturn #True
r=1LL;
goto end;
// EndProcedure
r=0;
end:
SYS_FreeString(v_contentrange);
SYS_FreeString(v_extraheaders);
SYS_FreeString(v_mimetype);
SYS_FreeString(v_fspath);
return r;
}
// Procedure.s ApacheDate(ts.q)
static void* f_apachedate(quad v_ts,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
integer v_mon=0;
void* v_monstr=0;
void* v_months=0;
// Protected months.s = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
SYS_FastAllocateStringFree4(&v_months,_S122);
// Protected mon.i    = Val(FormatDate("%mm", ts))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S123,v_ts,SYS_PopStringBasePosition());
void* p0=(void*)SYS_PopStringBasePositionValueNoUpdate();
quad r0=PB_Val(p0);
SYS_PopStringBasePositionUpdate();
v_mon=r0;
// Protected monStr.s = StringField(months, mon, " ")
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_StringField(v_months,v_mon,_S6,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_monstr,SYS_PopStringBasePosition());
// ProcedureReturn "[" + FormatDate("%dd", ts) + "/" + monStr + "/" +                   FormatDate("%yyyy", ts) + ":" + FormatDate("%hh:%ii:%ss", ts) +                   " " + g_TZOffset + "]"
SYS_PushStringBasePosition();
SYS_CopyString(_S124);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S125,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S9);
SYS_CopyString(v_monstr);
SYS_CopyString(_S9);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S126,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S14);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_FormatDate(_S127,v_ts,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
SYS_CopyString(_S6);
SYS_CopyString(g_g_tzoffset);
SYS_CopyString(_S128);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_monstr);
SYS_FreeString(v_months);
return r;
}
// Procedure.s SubstPlaceholders_(tmpl.s, captured.s,                                 g1.s, g2.s, g3.s, g4.s, g5.s,                                 g6.s, g7.s, g8.s, g9.s)
static void* f_substplaceholders_(void* v_tmpl,void* v_captured,void* v_g1,void* v_g2,void* v_g3,void* v_g4,void* v_g5,void* v_g6,void* v_g7,void* v_g8,void* v_g9,int sbp) {
void* r=0;
PB_StringBasePosition=sbp;
SYS_FastAllocateString4(&v_tmpl,v_tmpl);
SYS_FastAllocateString4(&v_captured,v_captured);
SYS_FastAllocateString4(&v_g1,v_g1);
SYS_FastAllocateString4(&v_g2,v_g2);
SYS_FastAllocateString4(&v_g3,v_g3);
SYS_FastAllocateString4(&v_g4,v_g4);
SYS_FastAllocateString4(&v_g5,v_g5);
SYS_FastAllocateString4(&v_g6,v_g6);
SYS_FastAllocateString4(&v_g7,v_g7);
SYS_FastAllocateString4(&v_g8,v_g8);
SYS_FastAllocateString4(&v_g9,v_g9);
void* v_r=0;
// Protected r.s = tmpl
SYS_PushStringBasePosition();
SYS_CopyString(v_tmpl);
PB_StringBasePosition+=2;
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{path}", captured)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S213,v_captured,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{file}", URLBasename_(captured))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r0=f_urlbasename_(v_captured,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p0=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_ReplaceString(v_r,_S214,p0,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{dir}",  URLDirname_(captured))
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
void* r1=f_urldirname_(v_captured,SYS_PopStringBasePosition());
PB_StringBasePosition+=2;
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
PB_ReplaceString(v_r,_S215,p1,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.1}", g1)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S216,v_g1,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.2}", g2)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S217,v_g2,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.3}", g3)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S218,v_g3,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.4}", g4)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S219,v_g4,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.5}", g5)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S220,v_g5,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.6}", g6)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S221,v_g6,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.7}", g7)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S222,v_g7,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.8}", g8)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S223,v_g8,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// r = ReplaceString(r, "{re.9}", g9)
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_ReplaceString(v_r,_S224,v_g9,SYS_PopStringBasePosition());
SYS_AllocateString4(&v_r,SYS_PopStringBasePosition());
// ProcedureReturn r
SYS_PushStringBasePosition();
SYS_CopyString(v_r);
r=SYS_PopStringBasePositionValueNoUpdate();
goto end;
// EndProcedure
SYS_PushStringBasePosition();
SYS_CopyString("\0");
r=SYS_PopStringBasePositionValueNoUpdate();
end:
SYS_FreeString(v_tmpl);
SYS_FreeString(v_r);
SYS_FreeString(v_g1);
SYS_FreeString(v_g2);
SYS_FreeString(v_g3);
SYS_FreeString(v_g4);
SYS_FreeString(v_g5);
SYS_FreeString(v_g6);
SYS_FreeString(v_g7);
SYS_FreeString(v_g8);
SYS_FreeString(v_g9);
SYS_FreeString(v_captured);
return r;
}
// 
char PB_OpenGLSubsystem=1;
int PB_Compiler_Unicode=1;
int PB_Compiler_Thread=0;
int PB_Compiler_Purifier=0;
int PB_Compiler_Debugger=0;
int PB_Compiler_DPIAware=0;
int PB_ExecutableType=1;
// 
void PB_EndFunctions() {
PB_EndThread();
PB_FreeRegularExpressions();
PB_FreePackers();
PB_FreeNetworks();
PB_EndDate();
PB_FreeCocoa();
PB_FreeWindows();
PB_Event_Free();
PB_FreeFileSystem();
PB_FreeImages();
PB_EndVectorDrawing();
PB_FreeFonts();
PB_FreeDesktops();
PB_FreeFiles();
PB_FreeObjects();
PB_FreeMemorys();
}
// 
int main(int argc, char* argv[]) {
PB_ArgC = argc;
PB_ArgV = argv;
PB_InternalProcessToFront();
PB_InitCocoa();
SYS_InitPureBasic();
SYS_InitString();
PB_InitMap();
PB_InitMemory();
PB_InitList();
PB_InitFile();
PB_InitArray();
PB_InitDesktop();
PB_InitFont();
PB_Init2DDrawing();
PB_InitVectorDrawing();
PB_InitImageDecoder();
PB_InitBMPImagePlugin();
PB_InitImage();
PB_InitGadget();
PB_Event_Init();
PB_InitWindow();
PB_InitMenu();
PB_InitDate();
PB_InitNetworkInternal();
PB_InitRequester();
PB_InitPacker();
PB_InitHTTP();
PB_InitRegularExpression();
PB_InitThread();
PB_InitProcess();
// 
// 
// EnableExplicit
// XIncludeFile "TestCommon.pbi"
// 
// 
// 
// 
// 
// EnableExplicit
// 
// XIncludeFile "../src/Global.pbi"
// 
// 
// EnableExplicit
// 
// 
// #APP_NAME    = "PureSimpleHTTPServer"
// #APP_VERSION = "1.5.0"
// 
// 
// #HTTP_200 = 200   
// #HTTP_206 = 206   
// #HTTP_301 = 301   
// #HTTP_302 = 302   
// #HTTP_304 = 304   
// #HTTP_400 = 400   
// #HTTP_403 = 403   
// #HTTP_404 = 404   
// #HTTP_416 = 416   
// #HTTP_500 = 500   
// 
// 
// #RECV_BUFFER_SIZE = 65536  
// #SEND_CHUNK_SIZE  = 65536  
// #MAX_HEADER_SIZE  = 8192   
// 
// 
// #DEFAULT_PORT  = 8080
// #DEFAULT_INDEX = "index.html"
// 
// XIncludeFile "../src/Types.pbi"
// 
// 
// 
// 
// 
// Structure HttpRequest
// Method.s           
// Path.s             
// QueryString.s      
// Version.s          
// RawHeaders.s       
// ContentLength.i    
// Body.s             
// IsValid.i          
// ErrorCode.i        
// EndStructure
// 
// 
// Structure HttpResponse
// StatusCode.i       
// StatusText.s       
// ExtraHeaders.s     
// Body.s             
// BodyBuffer.i       
// BodyBufferSize.i   
// EndStructure
// 
// 
// Structure RangeSpec
// Start.i    
// End.i      
// IsValid.i  
// EndStructure
// 
// 
// Structure ServerConfig
// Port.i             
// RootDirectory.s    
// IndexFiles.s       
// BrowseEnabled.i    
// SpaFallback.i      
// HiddenPatterns.s   
// LogFile.s          
// MaxConnections.i   
// 
// ErrorLogFile.s     
// LogLevel.i         
// LogSizeMB.i        
// LogKeepCount.i     
// LogDaily.i         
// PidFile.s          
// 
// CleanUrls.i        
// RewriteFile.s      
// EndStructure
// 
// XIncludeFile "../src/DateHelper.pbi"
// 
// 
// 
// EnableExplicit
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/UrlHelper.pbi"
// 
// 
// 
// EnableExplicit
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/HttpParser.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/HttpResponse.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/TcpServer.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// Prototype.i ConnectionHandlerProto(connection.i, raw.s)
// 
// 
// Global g_Handler.ConnectionHandlerProto;
// 
// 
// Global g_Running.i;
// 
// 
// 
// 
// Global g_CloseMutex.i;
// Global NewList g_CloseList.i()
PB_NewList(8,&t_g_closelist,0,21);;
// 
// 
// Structure ThreadData
// client.i
// raw.s
// EndStructure
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/MimeTypes.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/Logger.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// Global g_LogFile.i       = 0   
g_g_logfile=0;
// Global g_ErrorLogFile.i  = 0   
g_g_errorlogfile=0;
// Global g_LogMutex.i      = 0   
g_g_logmutex=0;
// Global g_LogLevel.i      = 2   
g_g_loglevel=2;
// Global g_ServerPID.i     = 0   
g_g_serverpid=0;
// Global g_TZOffset.s              ;
// Global g_LogPath.s       = ""  
SYS_FastAllocateStringFree4(&g_g_logpath,_S10);
// Global g_ErrorLogPath.s  = ""  
SYS_FastAllocateStringFree4(&g_g_errorlogpath,_S10);
// Global g_LogMaxBytes.i   = 0   
g_g_logmaxbytes=0;
// Global g_LogKeepCount.i  = 30  
g_g_logkeepcount=30;
// Global g_RotationSeq.i   = 0   
g_g_rotationseq=0;
// Global g_RotationThread.i = 0  
g_g_rotationthread=0;
// Global g_StopRotation.i   = 0  
g_g_stoprotation=0;
// Global g_ReopenLogs.i     = 0  
g_g_reopenlogs=0;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/FileServer.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// Declare.s BuildDirectoryListing(dirPath.s, urlPath.s)
// Declare.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
// Declare.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/DirectoryListing.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/RangeParser.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/Config.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/RewriteEngine.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// EnableExplicit
// 
// 
// #RULE_REWRITE = 0   
// #RULE_REDIR   = 1   
// 
// 
// #MATCH_EXACT = 0    
// #MATCH_GLOB  = 1    
// #MATCH_REGEX = 2    
// 
// 
// #MAX_GLOBAL_RULES = 63    
// #MAX_DIR_CACHE    = 7     
// #MAX_DIR_RULES    = 15    
// #DR_STRIDE        = 16    
// 
// 
// 
// Structure RewriteResult
// Action.i          
// NewPath.s         
// RedirURL.s        
// RedirCode.i       
// EndStructure
// 
// 
// Structure RewriteRule
// RuleType.i     
// MatchType.i    
// Pattern.s
// Destination.s
// Code.i
// RegexHandle.i
// EndStructure
// 
// 
// 
// Global Dim g_GR_RuleType.i(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,21,0,&a_g_gr_ruletype);;
// Global Dim g_GR_MatchType.i(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,21,0,&a_g_gr_matchtype);;
// Global Dim g_GR_Pattern.s(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,8,s_s,&a_g_gr_pattern);;
// Global Dim g_GR_Destination.s(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,8,s_s,&a_g_gr_destination);;
// Global Dim g_GR_Code.i(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,21,0,&a_g_gr_code);;
// Global Dim g_GR_RegexHandle.i(#MAX_GLOBAL_RULES)
SYS_AllocateArray(8,64,21,0,&a_g_gr_regexhandle);;
// Global g_GR_Count.i = 0
g_g_gr_count=0;
// 
// 
// Global Dim g_DC_DirPath.s(#MAX_DIR_CACHE)
SYS_AllocateArray(8,8,8,s_s,&a_g_dc_dirpath);;
// Global Dim g_DC_FileMtime.q(#MAX_DIR_CACHE)
SYS_AllocateArray(8,8,13,0,&a_g_dc_filemtime);;
// Global Dim g_DC_RuleCount.i(#MAX_DIR_CACHE)
SYS_AllocateArray(8,8,21,0,&a_g_dc_rulecount);;
// Global g_DC_Count.i = 0
g_g_dc_count=0;
// 
// 
// Global Dim g_DR_RuleType.i(127)
SYS_AllocateArray(8,128,21,0,&a_g_dr_ruletype);;
// Global Dim g_DR_MatchType.i(127)
SYS_AllocateArray(8,128,21,0,&a_g_dr_matchtype);;
// Global Dim g_DR_Pattern.s(127)
SYS_AllocateArray(8,128,8,s_s,&a_g_dr_pattern);;
// Global Dim g_DR_Destination.s(127)
SYS_AllocateArray(8,128,8,s_s,&a_g_dr_destination);;
// Global Dim g_DR_Code.i(127)
SYS_AllocateArray(8,128,21,0,&a_g_dr_code);;
// Global Dim g_DR_RegexHandle.i(127)
SYS_AllocateArray(8,128,21,0,&a_g_dr_regexhandle);;
// 
// Global g_RewriteMutex.i;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/EmbeddedAssets.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// Global g_EmbeddedPack.i;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "../src/SignalHandler.pbi"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS
// 
// #SIGHUP  = 1   
// #SIG_DFL = 0   
// 
// ImportC ""
// signal.i(signum.i, *handler)
// EndImport
// 
// 
// 
// 
// 
// 
// 
// 
// 
// CompilerElse
// 
// 
// 
// Global g_TmpRwDir.s   ;
// Global g_TmpConf.s    ;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
SYS_Quit();
}

void SYS_Quit() {
PB_EndFunctions();
exit(PB_ExitCode);
}
