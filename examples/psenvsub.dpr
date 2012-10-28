program psenvsub;
//
//  Pubsub envelope subscriber
//

{$APPTYPE CONSOLE}

uses
    Classes
  , SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  subscriber: TZMQSocket;
  msg: TStringList;
begin
  //  Prepare our context and subscriber
  context := TZMQContext.create;
  subscriber := context.Socket( stSub );
  subscriber.connect( 'tcp://localhost:5563' );
  subscriber.Subscribe( 'B' );
  msg := TStringList.Create;
  while true do
  begin
    msg.Clear;
    subscriber.recv( msg );
    Writeln( Format( '[%s] %s', [msg[0], msg[1]] ) );
  end;
  msg.Free;
  subscriber.Free;
  context.Free;
end.
