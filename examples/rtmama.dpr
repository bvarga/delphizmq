program rtmama;
//
//  Custom routing Router to Mama (ROUTER to REQ)
//

{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

const
  NBR_WORKERS = 10;

var
  cs: TRTLCriticalSection;

procedure Note( str: String );
begin
  EnterCriticalSection( cs );
  Writeln( str );
  LeaveCriticalSection( cs );
end;

procedure worker_task( args: Pointer );
var
  context: TZMQContext;
  worker: TZMQSocket;
  total: Integer;
  finished: Boolean;
  workload: String;
begin
  context := TZMQContext.create;
  worker := context.Socket( stReq );
  //  We use a string identity for ease here
  worker.Identity := IntToHex( Integer(context),8 );
  worker.connect( 'tcp://127.0.0.1:5555' );

  total := 0;
  finished := false;
  while not finished do
  begin
    //  Tell the router we're ready for work
    worker.send( 'ready' );

    //  Get workload from router, until finished
    worker.recv( workload );
    finished := workload = 'END';
    if not finished then
    begin
      inc( total );
      //  Do some random work
      sleep( random(1000) + 1 );
    end;
  end;
  Note( Format('Processed: %d tasks',[total] ) );
  worker.Free;
  context.Free;
end;

//  While this example runs in a single process, that is just to make
//  it easier to start and stop the example. Each thread has its own
//  context and conceptually acts as a separate process.

var
  context: TZMQContext;
  client: TZMQSocket;
  i: Integer;
  tid :Cardinal;
    address
  , empty
  , ready: String;

begin
  InitializeCriticalSection( cs );

  context := TZMQContext.create;
  client := context.Socket( stRouter );
  client.bind( 'tcp://127.0.0.1:5555' );
  Randomize;
  for i := 0 to NBR_WORKERS - 1 do
    BeginThread( nil, 0, @worker_task, nil, 0, tid );

  for i := 0 to NBR_WORKERS * 10 - 1 do
  begin
    //  LRU worker is next waiting in queue
    client.recv( address );
    client.recv( empty );
    client.recv( ready );

    client.send( [address, '', 'This is the workload'] );
  end;

  //  Now ask mamas to shut down and report their results
  for i := 0 to NBR_WORKERS - 1 do
  begin
    client.recv( address );
    client.recv( empty );
    client.recv( ready );

    client.send( [address, '', 'END'] );
  end;

  client.Free;
  context.Free;
  DeleteCriticalSection( cs );

end.


