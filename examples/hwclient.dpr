program hwclient;
//
//  Hello World client
//  Connects REQ socket to tcp://localhost:5555
//  Sends "Hello" to server, expects "World" back
//
{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  requester: TZMQSocket;
  i: Integer;
  sMsg: String;
begin
  context := TZMQContext.Create( 1 );

  //  Socket to talk to server
  Writeln('Connecting to hello world server...');
  requester := TZMQSocket.Create( context, stReq );
  requester.connect( 'tcp://localhost:5555' );

  for i := 0 to 9 do
  begin
    Writeln( Format( 'Sending Hello %d',[ i ] ));
    requester.send( 'Hello' );
    requester.recv( sMsg );
    Writeln( Format( 'Received World %d', [ i ] ) );
  end;

  requester.Free;
  context.Free;
end.
