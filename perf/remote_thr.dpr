program remote_thr;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  ;

var
  connectto: String;
  msgsize,
  msgcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;
  i: Integer;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: remote_thr <connect-to> <message-size> <message-count>' );
    exit;
  end;

  connectto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  msgcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stPush );
  socket.connect( connectto );

  for i := 0 to msgcount - 1 do
  begin
    msg := TZMQMessage.create( msgsize );
    FillMemory( msg.data, msgsize, 0 );
    socket.send( msg );
    msg.Free;
  end;

  socket.Free;
  context.Free;


end.
