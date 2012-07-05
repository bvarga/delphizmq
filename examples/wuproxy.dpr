program wuproxy;
//
//  Weather proxy device
//
{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  frontend,
  backend: TZMQSocket;
  msg: TZMQMessage;
  more: Boolean;
begin
  context := TZMQContext.Create( 1 );

  //  This is where the weather server sits
  frontend := TZMQSocket.Create( context, stSub );
  frontend.connect( 'tcp://192.168.55.210:5556' );

  //  This is our public endpoint for subscribers
  backend := TZMQSocket.Create( context, stPub );
  backend.bind( 'tcp://10.1.1.0:8100' );

  //  Subscribe on everything
  frontend.subscribe('');

  //  Shunt messages out to our own subscribers
  while True do
  begin
    while True do
    begin
      msg := TZMQMessage.Create;

      //  Process all parts of the message
      frontend.recv( msg );
      more := frontend.rcvMore;
      if more then
        backend.send( msg, [rsfSndMore] )
      else
        backend.send( msg, [] );
      msg.free;
      if not more then
        break;      //  Last message part
    end;
  end;
  //  We don't actually get here but if we did, we'd shut down neatly
  frontend.Free;
  backend.Free;
  context.Free;
end.
