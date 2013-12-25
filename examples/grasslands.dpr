program grasslands;
//  The Grasslands Pattern
//
//  The Classic ZeroMQ model, plain text with no protection at all.
//  @author Varga Balázs <bb.varga@gmail.com>

{$APPTYPE CONSOLE}

{$R *.res}

uses
    System.SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  server,
  client: TZMQSocket;
  msg: Utf8String;
begin
  //  Create context
  context := TZMQContext.Create;

  //  Create and bind server socket
  server := Context.Socket( stPush );
  server.bind('tcp://127.0.0.1:9000');

  //  Create and connect client socket
  client := Context.Socket( stPull );
  client.connect('tcp://127.0.0.1:9000');

  //  Send a single message from server to client
  server.send( 'Hello' );
  client.recv( msg );

  Assert( msg = 'Hello' );
  Writeln( 'Grasslands test OK' );

  context.Free;
end.

