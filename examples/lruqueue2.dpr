program lruqueue2;
//
//  Least-recently used (LRU) queue device
//  Demonstrates use of the Higher level API
//

{$APPTYPE CONSOLE}

uses
    Windows
  , SysUtils
  , Classes
  , zmqapi
  ;

const
  NBR_CLIENTS = 10;
  NBR_WORKERS = 3;
  LRU_READY = '\001'; //  Signals worker is ready

//  Basic request-reply client using REQ socket
procedure client_task( args: Pointer );
var
  context: TZMQContext;
  client: TZMQSocket;
  reply: String;
begin
  context := TZMQContext.create;
  client := context.Socket( stReq );
  client.connect( 'tcp://127.0.0.1:5555' );

  //  Send request, get reply
  while not context.Terminated do
  begin
    client.send( 'HELLO' );
    client.recv( reply );
    ZMQNote( Format('Client: %s',[reply]) );
    sleep(1);
  end;
  context.Free;
end;

//  Worker using REQ socket to do LRU routing
//
procedure worker_task( args: Pointer );
var
    context: TZMQContext;
    worker: TZMQSocket;
    msg: TStringList;
begin
  context := TZMQContext.create;
  worker := context.Socket( stReq );
  //  Set a printable identity
  worker.Identity := IntToHex( Integer(worker),8 );

  worker.connect( 'tcp://127.0.0.1:5556' );
  msg := TStringList.Create;
  //  Tell broker we're ready for work
  worker.send( LRU_READY );

  //  Process messages as they arrive
  while not context.Terminated do
  begin
    msg.Clear;
    worker.recv( msg );
    //ZMQNote( Format('Worker: %s',[msg[2]]) );
    msg[2] := 'OK';
    worker.send( msg );
  end;
  msg.Free;
  context.Free;
end;

//  Now we come to the main task. This has the identical functionality to
//  the previous lruqueue example but uses the Higher level API to start child
//  threads, to hold the list of workers, and to read and send messages:

var
    context: TZMQContext;
    frontend
  , backend: TZMQSocket;
    i,j: Integer;
    tid: Cardinal;

    poller: TZMQPoller;
    prc: Integer;
    pr: TZMQPollItem;

    //  Queue of available workers
    worker_queue: TStringList;
    msg: TStringList;

begin

  //  Prepare our context and sockets
  context := TZMQContext.create;
  frontend := context.Socket( stRouter );
  backend := context.Socket( stRouter );
  frontend.bind( 'tcp://127.0.0.1:5555' );
  backend.bind( 'tcp://127.0.0.1:5556' );

  sleep(100);

  for i := 0 to NBR_CLIENTS - 1 do
    BeginThread( nil, 0, @client_task, nil, 0, tid );

  for i := 0 to NBR_WORKERS - 1 do
    BeginThread( nil, 0, @worker_task, nil, 0, tid );

  msg := TStringList.create;
  worker_queue := TStringList.Create;
  poller := TZMQPoller.Create( true );
  poller.register( backend, [pePollIn] );
  poller.register( frontend, [pePollIn] );

  while not context.Terminated do
  begin

     //  Poll frontend only if we have available workers
    if worker_queue.Count > 0 then
      prc := poller.poll
    else
      prc := poller.poll( -1, 1 );

    for i := 0 to prc - 1 do
    begin
      pr := poller.pollResult[i];
      msg.clear;
      //  Handle worker activity on backend
      if ( pePollIn in pr.events ) and ( pr.socket = backend ) then
      begin
        backend.recv( msg );
        Assert( worker_queue.Count < NBR_WORKERS );
        worker_queue.Add( msg[0] );
        Assert( msg[1] = '' );

        //  If client reply, send rest back to frontend
        if msg[2] <> LRU_READY then
        begin
          Assert( msg[3] = '' );
          msg.Delete(0);
          msg.Delete(0);
          frontend.send( msg );
        end;
      end else
      //  Here is how we handle a client request:
      if ( pePollIn in pr.events ) and ( pr.socket = frontend ) then
      begin
        //  Now get next client request, route to LRU worker
        //  Client request is [address][empty][request]
        frontend.recv( msg );
        Assert( msg[1] = '' );
        msg.Insert(0,'');
        msg.Insert(0,worker_queue[0]);

        backend.send(msg);

        //  Dequeue and drop the next worker address
        worker_queue.Delete( 0 );
      end;
    end;
  end;
  msg.Free;
  worker_queue.Free;
  poller.Free;
  context.Free;
end.

