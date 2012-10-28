program psenvpub;
//
//  Pubsub envelope publisher
//  Note that the zhelpers.h file also provides s_sendmore
//

{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  publisher: TZMQSocket;
begin
  //  Prepare our context and publisher
  context := TZMQContext.Create;
  publisher := context.Socket( stPub );
  publisher.bind( 'tcp://*:5563' );

  while true do
  begin
    //  Write two messages, each with an envelope and content
    publisher.send( ['A', 'We don''t want to see this'] );
    publisher.send( ['B', 'We would like to see this'] );
    sleep(1);
  end;

  publisher.Free;
  context.Free;
end.
