program rtdealer;
//
//  Custom routing Router to Dealer
//

{$APPTYPE CONSOLE}

uses
    Classes
  , SysUtils
  , windows
  , zmqapi;

//  We have two workers, here we copy the code, normally these would
//  run on different boxes…
//
var
  cs: TRTLCriticalSection;

procedure Note( str: String );
begin
  EnterCriticalSection( cs );
  Writeln( str );
  LeaveCriticalSection( cs );
end;

procedure worker_task_a( args: Pointer );
var
  context: TZMQContext;
  worker: TZMQSocket;
  total: Integer;
  finished: Boolean;
  request: String;
begin
  context := TZMQContext.create;
  worker := context.Socket( stDealer );
  worker.Identity := 'A';
  worker.connect( 'tcp://127.0.0.1:5555' );

  total := 0;
  finished := false;
  while not finished do
  begin
    //  We receive one part, with the workload
    worker.recv( request );
    finished := request = 'END';
    if not finished then
      inc( total );
  end;
  Note( Format('A received: %d',[total] ) );
  worker.Free;
  context.Free;
end;

procedure worker_task_b( args: Pointer );
var
  context: TZMQContext;
  worker: TZMQSocket;
  total: Integer;
  finished: Boolean;
  request: String;
begin
  context := TZMQContext.create;
  worker := context.Socket( stDealer );
  worker.Identity := 'B';
  worker.connect( 'tcp://127.0.0.1:5555' );

  total := 0;
  finished := false;
  while not finished do
  begin
    //  We receive one part, with the workload
    worker.recv( request );
    finished := request = 'END';
    if not finished then
      inc( total );
  end;
  Note( Format('B received: %d',[total] ) );
  worker.Free;
  context.Free;
end;

//  After we've defined the two worker tasks, we have the main task.
//  Recall that these three tasks could be in separate processes, even
//  running on different boxes. It's just easier to start by writing
//  these in a single program. The main task starts the two workers,
//  then scatters tasks to the workers. It sends an END message to each
//  worker to tell them to exit:

var
  context: TZMQContext;
  client: TZMQSocket;
  tid1,tid2: Cardinal;
  i: Integer;
begin
  InitializeCriticalSection( cs );

  context := TZMQContext.create;
  client := context.Socket( stRouter );
  client.bind( 'tcp://127.0.0.1:5555' );

  BeginThread( nil, 0, @worker_task_a, nil, 0, tid1 );
  BeginThread( nil, 0, @worker_task_b, nil, 0, tid2 );

  //  Wait for threads to connect, since otherwise the messages
  //  we send won't be routable.
  sleep(100);

  //  Send 10 tasks scattered to A twice as often as B
  Randomize;

  for i := 0 to 9 do
  begin
    //  Send two message parts, first the address...
    if Random > 0.33 then
      client.send('A', [sfSndMore] )
//      client.send( ['A', 'This is the workload'] )
    else
      client.send('B', [sfSndMore] );
//      client.send( ['B', 'This is the workload'] )

    //  And then the workload
    client.send( 'This is the workload' );
  end;
  client.send( ['A','END'] );
  client.send( ['B','END'] );

  client.Free;
  context.Free;
  sleep(1000);
  DeleteCriticalSection( cs );
end.

