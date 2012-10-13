program local_lat;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  bindto: String;
  msgsize: Integer;
  roundtripcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;
  i: Integer;
begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: local_lat <bind-to> <message-size> <roundtrip-count>' );
    exit;
  end;

  bindto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  roundtripcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stRep );
  socket.bind( bindto );

  msg := TZMQMessage.create( msgsize );
  for i := 0 to roundtripcount -1 do
  begin
    if socket.recv( msg ) <> msgsize then
      raise Exception.Create( 'message of incorrect size received' );
    socket.send( msg );
  end;

  msg.Free;
  socket.Free;
  context.Free;
end.
