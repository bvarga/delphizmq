program remote_lat;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  , zmq
  ;

var
  connectto: String;
  msgsize: Integer;
  roundtripcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;
  i: Integer;
  //watch: Pointer;
  elapsed: Word;
  latency: Real;

  fFrequency,
  fstart,
  fStop : Int64;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: remote_lat <connect-to> <message-size> <roundtrip-count>' );
    exit;
  end;

  connectto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  roundtripcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stReq );
  socket.connect( connectto );

  msg := TZMQMessage.create( msgsize );

  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );
  //watch := zmq_stopwatch_start;

  for i := 0 to roundtripcount - 1 do
  begin
    socket.send( msg );
    if socket.recv( msg ) <> msgsize then
      raise Exception.Create( 'message of incorrect size received' );
  end;
  QueryPerformanceCounter( fStop );
  elapsed := (fStop - fStart) div fFrequency;

  //elapsed := zmq_stopwatch_stop( watch );
  msg.Free;

  latency := elapsed / (roundtripcount * 2);

  Writeln( Format('message size: %d [B]',[ msgsize ] ) );
  Writeln( Format('roundtrip count: %d', [roundtripcount] ) );
  Writeln( Format('average latency: %.3f [us]', [ latency ] ) );
  
  socket.Free;
  context.Free;
end.
