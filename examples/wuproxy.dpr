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
  frame: TZMQFrame;
  more: Boolean;
begin
  context := TZMQContext.Create;

  //  This is where the weather server sits
  frontend := Context.Socket( stSub );
  frontend.connect( 'tcp://192.168.55.210:5556' );

  //  This is our public endpoint for subscribers
  backend := Context.Socket( stPub );
  backend.bind( 'tcp://10.1.1.0:8100' );

  //  Subscribe on everything
  frontend.subscribe('');

  //  Shunt messages out to our own subscribers
  while True do
  begin
    while True do
    begin
      frame := TZMQFrame.Create;

      //  Process all parts of the message
      frontend.recv( frame );
      more := frontend.rcvMore;
      if more then
        backend.send( frame, [sfSndMore] )
      else
        backend.send( frame, [] );
      if not more then
        break;      //  Last message part
    end;
  end;
  //  We don't actually get here but if we did, we'd shut down neatly
  frontend.Free;
  backend.Free;
  context.Free;
end.
