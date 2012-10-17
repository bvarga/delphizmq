program inproc_lat;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  //, zmq
  ;

var
  msgsize: Integer;
  roundtripcount: Integer;

procedure worker( cntx: TZMQContext );
var
  socket: TZMQSocket;
  msg: TZMQMessage;
  i: Integer;
begin
  socket := cntx.Socket( stRep );
  socket.connect( 'inproc://lat_test' );

  msg := TZMQMessage.create;
  for i := 0 to roundtripcount - 1 do
  begin
    socket.recv( msg );
    socket.send( msg );
  end;
  msg.Free;
  socket.Free;

end;

var

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;
  tid: Cardinal;
  i: Integer;

  elapsed,
  latency: Real;

  fFrequency,
  fstart,
  fStop : Int64;

  localThread: THandle;
  rc2: Cardinal;
  rc3: LongBool;
begin
  if ParamCount <> 2 then
  begin
    Writeln('usage: remote_lat <message-size> <roundtrip-count>' );
    exit;
  end;

  msgsize := StrToInt( ParamStr( 1 ) );
  roundtripcount := StrToInt( ParamStr( 2 ) );

  context := TZMQContext.Create;

  socket := context.Socket( stReq );
  socket.bind( 'inproc://lat_test' );

  localThread := BeginThread( nil, 0, @worker, context, 0, tid );
  if localThread = 0 then
    raise Exception.Create( 'error in BeginThread' );

  msg := TZMQMessage.create( msgsize );
  FillMemory( msg.data, msgsize, 0 );

  Writeln( Format('message size: %d [B]', [msgsize] ) );
  Writeln( Format('roundtrip count: %d', [roundtripcount] ) );

  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to roundtripcount - 1 do
  begin
    socket.send( msg );
    if socket.recv( msg ) <> msgsize then
      raise Exception.Create( 'message of incorrect size received' );
  end;

  QueryPerformanceCounter( fStop );
  msg.Free;

  elapsed := 1000*1000*(fStop - fStart) / fFrequency;

  latency := elapsed / (roundtripcount * 2);

  rc2 := WaitForSingleObject( localThread, INFINITE );
  if rc2 = WAIT_FAILED then
    raise Exception.Create( 'error in WaitForSingleObject' );

  rc3 := CloseHandle( localThread );
  if not rc3 then
    raise Exception.Create( 'error in CloseHandle' );

  Writeln( Format('average latency: %.3f [us]',[latency] ) );
  socket.Free;
  context.Free;

end.
