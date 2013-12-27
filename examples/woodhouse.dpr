program woodhouse;
//  The Woodhouse Pattern
//
//  It may keep some malicious people out but all it takes is a bit
//  of network sniffing, and they'll be able to fake their way in.
//  @author Varga Balázs <bb.varga@gmail.com>

{$APPTYPE CONSOLE}

uses
    System.SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  auth: TZMQAuth;
  server,
  client: TZMQSocket;
  msg: Utf8String;
begin
  //  Create context and start authentication engine
  context := TZMQContext.Create;
  auth :=  TZMQauth.Create( context );
  auth.verbose := true;
  auth.allow( '127.0.0.1' );

  //  Tell the authenticator how to handle PLAIN requests
  auth.configurePlain('*','passwords');

  //  Create and bind server socket
  server := Context.Socket( stPush );
  server.Security := ssPlain;
  //zsocket_set_plain_server (server, 1);
  server.bind('tcp://*:9000');

  //  Create and connect client socket
  client := Context.Socket( stPull );
  client.PlainUserName := 'admin';
  client.PlainPassword := 'secret';
  client.connect('tcp://127.0.0.1:9000');

  //  Send a single message from server to client
  server.send( 'Hello' );
  client.recv( msg );

  Assert( msg = 'Hello' );
  Writeln( 'Woodhouse test OK' );

  auth.Free;
  context.Free;
end.



