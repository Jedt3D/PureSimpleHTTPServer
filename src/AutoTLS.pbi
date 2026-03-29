; AutoTLS.pbi — automatic TLS certificate management via acme.sh
; Include with: XIncludeFile "AutoTLS.pbi"
; Provides: GetCertPath(), GetKeyPath(), CertificateExists(),
;           IssueCertificate(), RenewCertificate(),
;           StartCertRenewal(), StopCertRenewal(),
;           HttpRedirectHandler(), StartHttpRedirect(), StopHttpRedirect()
;
; Phase 5: Automatic HTTPS via acme.sh (HTTP-01 challenge, webroot mode).
;   - Certificate issuance/renewal via acme.sh subprocess
;   - Background renewal thread (checks every 12 hours)
;   - HTTP redirect server on port 80 (ACME challenges + HTTPS redirect)
;
; Prerequisites:
;   - acme.sh installed at ~/.acme.sh/acme.sh
;   - Port 80 accessible from the internet
;   - Domain DNS points to this server's public IP
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, Types.pbi, HttpParser.pbi, HttpResponse.pbi, Config.pbi, TcpServer.pbi

; Global state for auto-TLS
Global g_AutoTlsDomain.s     = ""   ; domain name (set from --auto-tls)
Global g_AcmeChallengeDir.s  = ""   ; path to .well-known/acme-challenge/
Global g_RenewalRunning.i    = #False
Global g_RenewalThread.i     = 0
Global g_HttpRedirectRunning.i = #False
Global g_HttpRedirectThread.i  = 0
Global g_HttpRedirectPort.i    = 80

; ── Certificate paths ──────────────────────────────────────────────────────

; GetCertPath(domain) — return the path acme.sh stores the fullchain certificate
Procedure.s GetCertPath(domain.s)
  ProcedureReturn GetHomeDirectory() + ".acme.sh" + #SEP + domain + "_ecc" + #SEP + "fullchain.cer"
EndProcedure

; GetKeyPath(domain) — return the path acme.sh stores the private key
Procedure.s GetKeyPath(domain.s)
  ProcedureReturn GetHomeDirectory() + ".acme.sh" + #SEP + domain + "_ecc" + #SEP + domain + ".key"
EndProcedure

; CertificateExists(domain) — check if both cert and key files exist on disk
Procedure.i CertificateExists(domain.s)
  ProcedureReturn Bool(FileSize(GetCertPath(domain)) >= 0 And FileSize(GetKeyPath(domain)) >= 0)
EndProcedure

; ── Certificate management via acme.sh ─────────────────────────────────────

; RunAcmeSh(args) — run acme.sh with the given arguments, return exit code
; Returns 0 on success, nonzero on failure, -1 if acme.sh not found.
Procedure.i RunAcmeSh(args.s)
  Protected acmePath.s = GetHomeDirectory() + ".acme.sh" + #SEP + "acme.sh"
  If FileSize(acmePath) < 0
    ProcedureReturn -1
  EndIf
  Protected prog.i = RunProgram(acmePath, args, "", #PB_Program_Open | #PB_Program_Hide)
  If prog = 0
    ProcedureReturn -1
  EndIf
  While ProgramRunning(prog) : Delay(100) : Wend
  Protected exitCode.i = ProgramExitCode(prog)
  CloseProgram(prog)
  ProcedureReturn exitCode
EndProcedure

; IssueCertificate(domain, webroot) — request a new certificate via HTTP-01 challenge
; Returns #True on success.
Procedure.i IssueCertificate(domain.s, webroot.s)
  Protected args.s = "--issue -d " + domain + " -w " + webroot + " --keylength ec-256"
  ProcedureReturn Bool(RunAcmeSh(args) = 0)
EndProcedure

; RenewCertificate(domain) — attempt to renew (acme.sh only renews if within 30 days)
; Returns #True if renewal succeeded (or was skipped because cert is still valid).
Procedure.i RenewCertificate(domain.s)
  Protected args.s = "--renew -d " + domain + " --ecc"
  Protected result.i = RunAcmeSh(args)
  ; acme.sh returns 0 on success, 2 if cert is not yet due for renewal (not an error)
  ProcedureReturn Bool(result = 0 Or result = 2)
EndProcedure

; ── Renewal thread ─────────────────────────────────────────────────────────

; CertRenewalLoop — background thread: checks for renewal every 12 hours
Procedure CertRenewalLoop(*unused)
  Protected elapsed.i
  Protected checkInterval.i = 12 * 60 * 60 * 1000  ; 12 hours

  While g_RenewalRunning
    ; Sleep in 1-second increments to allow clean shutdown
    elapsed = 0
    While elapsed < checkInterval And g_RenewalRunning
      Delay(1000)
      elapsed + 1000
    Wend

    If g_RenewalRunning
      If RenewCertificate(g_AutoTlsDomain)
        ; Reload certificates into TLS globals and restart server
        Protected newKey.s  = ReadPEMFile(GetKeyPath(g_AutoTlsDomain))
        Protected newCert.s = ReadPEMFile(GetCertPath(g_AutoTlsDomain))
        If newKey <> "" And newCert <> ""
          g_TlsKey  = newKey
          g_TlsCert = newCert
          RestartServer()
        EndIf
      EndIf
    EndIf
  Wend
EndProcedure

; StartCertRenewal() — launch the background renewal thread
Procedure StartCertRenewal()
  g_RenewalRunning = #True
  g_RenewalThread  = CreateThread(@CertRenewalLoop(), 0)
EndProcedure

; StopCertRenewal() — signal the renewal thread to exit and wait for it
Procedure StopCertRenewal()
  If g_RenewalThread
    g_RenewalRunning = #False
    WaitThread(g_RenewalThread)
    g_RenewalThread = 0
  EndIf
EndProcedure

; ── HTTP redirect server (port 80: ACME challenges + HTTPS redirect) ──────

; HttpRedirectHandler — handle one HTTP request: serve ACME challenge or redirect
Procedure.i HttpRedirectHandler(connection.i, raw.s)
  Protected req.HttpRequest
  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  ; Serve ACME challenge tokens from /.well-known/acme-challenge/
  Protected prefix.s = "/.well-known/acme-challenge/"
  If Left(req\Path, Len(prefix)) = prefix
    Protected token.s = Mid(req\Path, Len(prefix) + 1)
    If token <> "" And FindString(token, "/") = 0 And FindString(token, "..") = 0
      Protected tokenPath.s = g_AcmeChallengeDir + #SEP + token
      Protected tokenSize.i = FileSize(tokenPath)
      If tokenSize >= 0
        Protected *buf = AllocateMemory(tokenSize + 1)
        If *buf
          Protected f.i = ReadFile(#PB_Any, tokenPath)
          If f
            If tokenSize > 0 : ReadData(f, *buf, tokenSize) : EndIf
            CloseFile(f)
            Protected hdr.s = "Content-Type: text/plain" + #CRLF$
            SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, hdr, tokenSize), #PB_Ascii)
            If tokenSize > 0 : SendNetworkData(connection, *buf, tokenSize) : EndIf
            FreeMemory(*buf)
            ProcedureReturn #True
          EndIf
          FreeMemory(*buf)
        EndIf
      EndIf
    EndIf
  EndIf

  ; Redirect everything else to HTTPS
  Protected redirUrl.s = "https://" + g_AutoTlsDomain + req\Path
  If req\QueryString <> ""
    redirUrl + "?" + req\QueryString
  EndIf
  Protected redirHeaders.s = "Location: " + redirUrl + #CRLF$
  SendNetworkString(connection, BuildResponseHeaders(#HTTP_301, redirHeaders, 0), #PB_Ascii)
  ProcedureReturn #True
EndProcedure

; HttpRedirectLoop — background thread: run a simple HTTP server on port 80
Procedure HttpRedirectLoop(*unused)
  Protected httpServerID.i = CreateNetworkServer(#PB_Any, g_HttpRedirectPort, #PB_Network_TCP)
  If httpServerID = 0
    Debug "HttpRedirectLoop: failed to start HTTP server on port " + Str(g_HttpRedirectPort)
    ProcedureReturn
  EndIf

  Protected event.i, client.i, clientKey.s, received.i
  NewMap accum.s()
  Protected *recvBuf = AllocateMemory(#RECV_BUFFER_SIZE)
  If *recvBuf = 0
    CloseNetworkServer(httpServerID)
    ProcedureReturn
  EndIf

  While g_HttpRedirectRunning
    event = NetworkServerEvent(httpServerID)
    Select event
      Case 0
        Delay(1)
      Case #PB_NetworkEvent_Connect
        accum(Str(EventClient())) = ""
      Case #PB_NetworkEvent_Data
        client    = EventClient()
        clientKey = Str(client)
        received  = ReceiveNetworkData(client, *recvBuf, #RECV_BUFFER_SIZE)
        If received > 0
          accum(clientKey) + PeekS(*recvBuf, received, #PB_Ascii)
          If FindString(accum(clientKey), #CRLF$ + #CRLF$) > 0
            HttpRedirectHandler(client, accum(clientKey))
            DeleteMapElement(accum(), clientKey)
            CloseNetworkConnection(client)
          EndIf
        EndIf
      Case #PB_NetworkEvent_Disconnect
        clientKey = Str(EventClient())
        If FindMapElement(accum(), clientKey)
          DeleteMapElement(accum(), clientKey)
        EndIf
    EndSelect
  Wend

  FreeMemory(*recvBuf)
  CloseNetworkServer(httpServerID)
EndProcedure

; StartHttpRedirect(port) — launch the HTTP redirect server in a background thread
Procedure StartHttpRedirect(port.i = 80)
  g_HttpRedirectPort    = port
  g_HttpRedirectRunning = #True
  g_HttpRedirectThread  = CreateThread(@HttpRedirectLoop(), 0)
EndProcedure

; StopHttpRedirect() — signal the HTTP redirect server to stop and wait
Procedure StopHttpRedirect()
  If g_HttpRedirectThread
    g_HttpRedirectRunning = #False
    WaitThread(g_HttpRedirectThread)
    g_HttpRedirectThread = 0
  EndIf
EndProcedure
