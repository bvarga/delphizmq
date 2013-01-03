program mspoller;
//
//  Reading from multiple sockets
//  This version uses zmq_poll()
//
{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  receiver,
  subscriber: TZMQSocket;
  i,pc: Integer;
  task: TZMQFrame;
  poller: TZMQPoller;
  pollResult: TZMQPollItem;
begin
  //  Prepare our context and sockets
  context := TZMQContext.Create;

  //  Connect to task ventilator
  receiver := Context.Socket( stPull );
  receiver.connect( 'tcp://localhost:5557' );

  //  Connect to weather server
  subscriber := Context.Socket( stSub );
  subscriber.connect( 'tcp://localhost:5556' );
  subscriber.subscribe( '10001' );

  //  Initialize poll set
  poller := TZMQPoller.Create( true );
  poller.Register( receiver, [pePollIn] );
  poller.Register( subscriber, [pePollIn] );

  task := nil;

  //  Process messages from both sockets
  while True do
  begin
    pc := poller.poll;
    for i := 0 to pc - 1 do
    begin
      pollResult := poller.pollResult[i];
      if pePollIn in pollResult.events then
        pollResult.socket.recv( task );
    end;
    FreeAndNil( task );
  end;
  //  We never get here
  poller.Free;
  receiver.Free;
  subscriber.Free;
  context.Free;
end.
