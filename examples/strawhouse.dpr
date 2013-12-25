program strawhouse;
//  The Strawhouse Pattern
//
//  We allow or deny clients according to their IP address. It may keep
//  spammers and idiots away, but won't stop a real attacker for more
//  than a heartbeat.
//  @author Varga Balázs <bb.varga@gmail.com>

{$APPTYPE CONSOLE}

{$R *.res}

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
  //  Create context
  context := TZMQContext.Create;

  //  Start an authentication engine for this context. This engine
  //  allows or denies incoming connections (talking to the libzmq
  //  core over a protocol called ZAP).
  auth :=  TZMQauth.Create( context );

  //  Get some indication of what the authenticator is deciding
  auth.verbose := true;

  //  Whitelist our address; any other address will be rejected
  auth.allow( '127.0.0.1' );

  //  Create and bind server socket
  server := Context.Socket( stPush );
  server.ZAPDomain := 'global';
  server.bind('tcp://127.0.0.1:9000');

  //  Create and connect client socket
  client := Context.Socket( stPull );
  client.connect('tcp://127.0.0.1:9000');

  //  Send a single message from server to client
  server.send( 'Hello' );
  client.recv( msg );

  Assert( msg = 'Hello' );
  Writeln( 'Strawhouse test OK' );

  auth.Free;
  context.Free;
end.


