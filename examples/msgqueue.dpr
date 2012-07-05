program msgqueue;
//
//  Simple message queuing broker
//  Same as request-reply broker but using QUEUE device
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

begin
  context := TZMQContext.Create( 1 );

  //  Socket facing clients
  frontend := TZMQSocket.Create( context, stRouter );
  frontend.bind( 'tcp://*:5559' );

  //  Socket facing services
  backend := TZMQSocket.Create( context, stDealer );
  backend.bind( 'tcp://*:5560' );

  //  Start built-in device
  ZMQDevice( dQueue, frontend, backend );

  //  We never get here
  frontend.Free;
  backend.Free;
  context.Free;
end.
