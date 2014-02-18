program stonehouse;
//  The Stonehouse Pattern
//
//  Where we allow any clients to connect, but we promise clients
//  that we are who we claim to be, and our conversations won't be
//  tampered with or modified, or spied on.
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
  client_cert,
  server_cert: TZMQCert;
  server_key: TCurveKey;
  msg: Utf8String;
begin

  //  Create context and start authentication engine
  context := TZMQContext.Create;
  auth :=  TZMQauth.Create( context );
  auth.verbose := true;
  auth.allow( '127.0.0.1' );

  //  Tell the authenticator how to handle CURVE requests
  auth.ConfigureCurve ('*', ZMQ_CURVE_ALLOW_ANY);

  //  We need two certificates, one for the client and one for
  //  the server. The client must know the server's public key
  //  to make a CURVE connection.
  client_cert := TZMQCert.Create();
  client_cert.publicKey.txt := 'g#=r=P%xlhehg8UMS--Fj2r/r][}>}s@ED=T#WCd';
  client_cert.secretKey.txt := 'xi#9aSD5+)YDXBL+)d83R{pZ#Ox&d#FBRLJf@o0$';

  //client_cert.random;
  server_cert := TZMQCert.Create();
  server_cert.publicKey.txt := 'm7rX=kp/&HZ.O50ReKaz9H(L:S86I5y$E>j/nPCp';
  server_cert.secretKey.txt := ']V46.D$P@D&GN9nv^uaZ5.kOb^3+&vh#BR1!anlk';

  //server_cert.random;

  server_key := server_cert.publicKey;

  //  Create and bind server socket
  server := Context.Socket( stPush );

  server_cert.Apply( server );
  server.Security := ssCurve;
  server.bind('tcp://*:9000');

  //  Create and connect client socket
  client := Context.Socket( stPull );
  client_cert.Apply( client );
  client.CurveServerKey := server_key;
  client.connect('tcp://127.0.0.1:9000');


  //  Send a single message from server to client
  server.send( 'Hello' );
  client.recv( msg );

  Assert( msg = 'Hello' );
  Writeln( 'Stonehouse test OK' );

  client_cert.Free;
  server_cert.Free;
  auth.Free;
  context.Free;
end.



