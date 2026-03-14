; TcpServer.pbi — TCP server wrapper for HTTP connections
; Include with: XIncludeFile "TcpServer.pbi"
; Provides: StartServer(), StopServer(), g_Handler
;
; Phase E: thread-per-connection model
;   Data accumulation runs in the main event loop (single-threaded, safe).
;   Each complete HTTP request is handed off to a new thread via ConnectionThread,
;   allowing the event loop to continue accepting connections while requests are
;   being handled. Requires the -t (thread-safe) compiler flag.
;   Shared read-only state (g_Handler, g_Config, g_EmbeddedPack) needs no mutex.
;   Logger uses its own mutex for safe concurrent log writes.
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; ConnectionHandlerProto — callback signature for HTTP request handlers
; connection: client connection ID (from EventClient())
; raw:        complete raw HTTP request string (accumulated until \r\n\r\n found)
Prototype.i ConnectionHandlerProto(connection.i, raw.s)

; g_Handler — set this to @YourHandler() before calling StartServer()
Global g_Handler.ConnectionHandlerProto

; g_Running — internal flag; set to #False by StopServer() to break event loop
Global g_Running.i

; Per-connection data passed to the handler thread
Structure ThreadData
  client.i
  raw.s
EndStructure

; ConnectionThread — handler thread: calls g_Handler then closes the connection
Procedure ConnectionThread(*data.ThreadData)
  Protected client.i = *data\client
  Protected raw.s    = *data\raw
  FreeStructure(*data)
  g_Handler(client, raw)
  CloseNetworkConnection(client)
EndProcedure

; StartServer(port.i) — create a TCP server and enter a blocking event loop
;
; Dispatches each complete HTTP request to g_Handler in a new thread.
; Returns #True on clean shutdown (StopServer() called), #False on startup failure.
;
; NOTE: g_Handler must be assigned before calling StartServer().
Procedure.i StartServer(port.i)
  Protected event.i, client.i, clientKey.s, received.i
  Protected *recvBuf, *td.ThreadData
  NewMap accum.s()

  If g_Handler = 0
    Debug "StartServer: g_Handler is not set"
    ProcedureReturn #False
  EndIf

  Protected serverID.i = CreateNetworkServer(#PB_Any, port, #PB_Network_TCP)
  If serverID = 0
    Debug "StartServer: CreateNetworkServer() failed on port " + Str(port)
    ProcedureReturn #False
  EndIf

  g_Running = #True

  *recvBuf = AllocateMemory(#RECV_BUFFER_SIZE)
  If Not *recvBuf
    CloseNetworkServer(serverID)
    ProcedureReturn #False
  EndIf

  Repeat
    event = NetworkServerEvent(serverID)
    Select event
      Case 0
        Delay(1)  ; no event — avoid busy-wait

      Case #PB_NetworkEvent_Connect
        clientKey = Str(EventClient())
        accum(clientKey) = ""

      Case #PB_NetworkEvent_Data
        client    = EventClient()
        clientKey = Str(client)
        received  = ReceiveNetworkData(client, *recvBuf, #RECV_BUFFER_SIZE)
        If received > 0
          accum(clientKey) = accum(clientKey) + PeekS(*recvBuf, received, #PB_Ascii)
          ; Dispatch to a handler thread when the complete request header block arrives
          If FindString(accum(clientKey), #CRLF$ + #CRLF$) > 0
            *td = AllocateStructure(ThreadData)
            *td\client = client
            *td\raw    = accum(clientKey)
            DeleteMapElement(accum(), clientKey)
            If CreateThread(@ConnectionThread(), *td) = 0
              ; Thread creation failed — handle synchronously as fallback
              g_Handler(*td\client, *td\raw)
              CloseNetworkConnection(*td\client)
              FreeStructure(*td)
            EndIf
          EndIf
        EndIf

      Case #PB_NetworkEvent_Disconnect
        clientKey = Str(EventClient())
        If FindMapElement(accum(), clientKey)
          DeleteMapElement(accum(), clientKey)
        EndIf

    EndSelect
  Until g_Running = #False

  FreeMemory(*recvBuf)
  CloseNetworkServer(serverID)
  ProcedureReturn #True
EndProcedure

; StopServer() — signal the event loop to terminate on the next iteration
Procedure StopServer()
  g_Running = #False
EndProcedure
