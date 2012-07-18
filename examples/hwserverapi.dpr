program hwserverapi;
//
//  Hello World server in Delphi
//  Binds REP socket to tcp://*:5555
//  Expects "Hello" from client, replies with "World"
//
{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  socket: TZMQSocket;
  sMsg: AnsiString;

begin
  //  Prepare our context and socket
  context := TZMQContext.Create( 1 );
  socket := TZMQSocket.Create( context, stRep );
  socket.bind( 'tcp://*:5555' );

  while true do
  begin
    //  Wait for next request from client
    socket.recv( sMsg );
    Writeln( 'Received Hello' );

    //  Do some 'work'
    sleep( 1 );

    //  Send reply back to client
    socket.send( 'World' );
  end;
  socket.Free;
  context.Free;
end.
