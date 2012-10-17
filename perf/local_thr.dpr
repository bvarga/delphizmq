program local_thr;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  ;

var
  bindto: String;
  msgsize,
  msgcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;

  fFrequency,
  fstart,
  fStop : Int64;

  i: Integer;
  elapsed,
  throughput,
  megabits: Real;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: local_thr <bind-to> <message-size> <message-count>' );
    exit;
  end;

  bindto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  msgcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stPull );
  socket.bind( bindto );

  msg := TZMQMessage.create;
  if socket.recv( msg ) <> msgsize then
    raise Exception.Create('message of incorrect size received');

  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to msgcount - 2 do
  if socket.recv( msg ) <> msgsize then
    raise Exception.Create( 'message of incorrect size received' );

  QueryPerformanceCounter( fStop );
  elapsed := 1000*1000*(fStop - fStart) / fFrequency;
  if elapsed = 0 then
    elapsed := 1;

  msg.Free;
  throughput := msgcount / elapsed * 1000000;
  megabits := throughput * msgsize * 8 / 1000000;

  Writeln( Format('message size: %d [B]',[ msgsize ] ) );
  Writeln( Format('message count: %d', [ msgcount ] ) );
  Writeln( Format('mean throughput: %f [msg/s]', [ throughput ] ) );
  Writeln( Format('mean throughput: %.3f [Mb/s]', [ megabits ] ) );

  socket.Free;
  context.Free;
end.
