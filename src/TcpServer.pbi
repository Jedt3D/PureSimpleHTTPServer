; TcpServer.pbi — TCP server wrapper for HTTP connections
; Include with: XIncludeFile "TcpServer.pbi"
; Provides: StartServer(), StopServer(), g_Handler
;
; Phase A: single-threaded, one request per connection (Connection: close model)
; Phase E: will replace with thread-per-connection model
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

; StartServer(port.i) — create a TCP server and enter a blocking event loop
;
; Dispatches each complete HTTP request to g_Handler.
; Returns #True on clean shutdown (StopServer() called), #False on startup failure.
;
; NOTE: g_Handler must be assigned before calling StartServer().
Procedure.i StartServer(port.i)
  Protected event.i, client.i, clientKey.s, received.i
  Protected *recvBuf
  NewMap accum.s()

  If g_Handler = 0
    Debug "StartServer: g_Handler is not set"
    ProcedureReturn #False
  EndIf

  ; Note: PureBasic Network library requires no initialization call
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
          ; Dispatch when complete header block received
          If FindString(accum(clientKey), #CRLF$ + #CRLF$) > 0
            g_Handler(client, accum(clientKey))
            CloseNetworkConnection(client)
            DeleteMapElement(accum(), clientKey)
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
