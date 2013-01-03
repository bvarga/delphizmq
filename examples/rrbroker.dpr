program rrbroker;
//
//  Simple request-reply broker
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
  poller: TZMQPoller;
  frame: TZMQFrame;
  more: Boolean;
  i,pc: Integer;
  pollResult: TZMQPollItem;
  otherSocket: TZMQSocket;

begin
  //  Prepare our context and sockets
  context := TZMQContext.Create;
  frontend := Context.Socket( stRouter );
  backend := Context.Socket( stDealer );
  frontend.bind( 'tcp://*:5559' );
  backend.bind( 'tcp://*:5560' );

  //  Initialize poll set
  poller := TZMQPoller.Create( true );
  poller.register( frontend, [pePollIn] );
  poller.register( backend, [pePollIn] );

  //  Switch messages between sockets
  while True do
  begin
    pc := poller.poll;
    for i := 0 to pc - 1 do
    begin
      pollResult := poller.pollResult[i];
      more := True;
      if pollResult.socket = frontend then
        otherSocket := backend
      else
        otherSocket := frontend;

      if pePollIn in pollResult.events then
      while more do
      begin
        //  Process all parts of the message
        frame := TZMQFrame.Create;
        pollResult.socket.recv( frame );
        more := pollResult.socket.rcvMore;
        if more then
          otherSocket.send( frame, [sfSndMore] )
        else
          otherSocket.send( frame, [] );
      end;

    end;
  end;
  //  We never get here but clean up anyhow
  poller.Free;
  frontend.Free;
  backend.Free;
  context.Free;
end.
