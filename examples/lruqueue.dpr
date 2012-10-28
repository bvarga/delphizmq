program lruqueue;
//
//  Least-recently used (LRU) queue device
//  Clients and workers are shown here in-process
//

{$APPTYPE CONSOLE}

uses
    Windows
  , SysUtils
  , zmqapi
  ;

const
  NBR_CLIENTS = 10;
  NBR_WORKERS = 3;

var
  cs: TRTLCriticalSection;

procedure Note( str: String );
begin
  EnterCriticalSection( cs );
  Writeln( str );
  LeaveCriticalSection( cs );
end;

//  Basic request-reply client using REQ socket
//  Since s_send and s_recv can't handle 0MQ binary identities we
//  set a printable text identity to allow routing.
//
procedure client_task( args: Pointer );
var
  context: TZMQContext;
  client: TZMQSocket;
  reply: String;
begin
  context := TZMQContext.create;
  client := context.Socket( stReq );
  //  Set a printable identity
  client.Identity := IntToHex( Integer(client),8 );
  client.connect( 'tcp://127.0.0.1:5555' );

  //  Send request, get reply
  client.send( 'HELLO' );
  client.recv( reply );
  Note( Format('Client: %s',[reply]) );

  client.Free;
  context.Free;
end;

//  While this example runs in a single process, that is just to make
//  it easier to start and stop the example. Each thread has its own
//  context and conceptually acts as a separate process.
//  This is the worker task, using a REQ socket to do LRU routing.
//  Since s_send and s_recv can't handle 0MQ binary identities we
//  set a printable text identity to allow routing.

procedure worker_task( args: Pointer );
var
    context: TZMQContext;
    worker: TZMQSocket;
    address
  , empty
  , request: String;
begin
  context := TZMQContext.create;
  worker := context.Socket( stReq );
  //  Set a printable identity
  worker.Identity := IntToHex( Integer(worker),8 );
  worker.connect( 'tcp://127.0.0.1:5556' );

  //  Tell broker we're ready for work
  worker.send( 'READY' );

  while true do
  begin
    //  Read and save all frames until we get an empty frame
    //  In this example there is only 1 but it could be more
    worker.recv( address );
    worker.recv( empty );
    Assert( empty = '' );

    //  Get request, send reply
    worker.recv( request );
    Note( Format('Worker: %s',[request]) );

    worker.send([
      address,
      '',
      'OK'
    ]);
  end;
  worker.Free;
  context.Free;
end;

//  This is the main task. It starts the clients and workers, and then
//  routes requests between the two layers. Workers signal READY when
//  they start; after that we treat them as ready when they reply with
//  a response back to a client. The LRU data structure is just a queue
//  of next available workers.

var
    context: TZMQContext;
    frontend
  , backend: TZMQSocket;
    i,j
  , client_nbr: Integer;
    tid: Cardinal;

    poller: TZMQPoller;
    prc: Integer;
    pr: TZMQPollResult;

    //  Queue of available workers
    available_workers: Integer = 0;
    worker_queue: Array[0..9] of String;
    worker_addr
  , empty
  , client_addr
  , reply
  , request: String;

begin
  InitializeCriticalSection( cs );

  //  Prepare our context and sockets
  context := TZMQContext.create;
  frontend := context.Socket( stRouter );
  backend := context.Socket( stRouter );
  frontend.bind( 'tcp://127.0.0.1:5555' );
  backend.bind( 'tcp://127.0.0.1:5556' );

  sleep(100);
  
  for i := 0 to NBR_CLIENTS - 1 do
    BeginThread( nil, 0, @client_task, nil, 0, tid );
  client_nbr := NBR_CLIENTS;

  for i := 0 to NBR_WORKERS - 1 do
    BeginThread( nil, 0, @worker_task, nil, 0, tid );

  //  Here is the main loop for the least-recently-used queue. It has two
  //  sockets; a frontend for clients and a backend for workers. It polls
  //  the backend in all cases, and polls the frontend only when there are
  //  one or more workers ready. This is a neat way to use 0MQ's own queues
  //  to hold messages we're not ready to process yet. When we get a client
  //  reply, we pop the next available worker, and send the request to it,
  //  including the originating client address. When a worker replies, we
  //  re-queue that worker, and we forward the reply to the original client,
  //  using the address envelope.

  poller := TZMQPoller.Create;
  poller.regist( backend, [pePollIn] );
  poller.regist( frontend, [pePollIn] );
  while client_nbr > 0 do
  begin

     //  Poll frontend only if we have available workers
    if available_workers > 0 then
      prc := poller.poll
    else
      prc := poller.poll( -1, 1 );

    for i := 0 to prc - 1 do
    begin
      pr := poller.pollResult[i];

      //  Handle worker activity on backend
      if ( pePollIn in pr.revents ) and ( pr.socket = backend ) then
      begin
        //  Queue worker address for LRU routing
        backend.recv( worker_addr );
        Assert( available_workers < NBR_WORKERS );
        worker_queue[available_workers] := worker_addr;
        inc( available_workers );

        //  Second frame is empty
        backend.recv( empty );
        Assert( empty = '' );

        //  Third frame is READY or else a client reply address
        backend.recv( client_addr );

        //  If client reply, send rest back to frontend
        if client_addr <> 'READY' then
        begin
          backend.recv( empty );
          Assert( empty = '' );

          backend.recv( reply );
          frontend.send([
            client_addr,
            '',
            reply
          ]);
          dec( client_nbr );
        end;
      end else
      //  Here is how we handle a client request:
      if ( pePollIn in pr.revents ) and ( pr.socket = frontend ) then
      begin
        //  Now get next client request, route to LRU worker
        //  Client request is [address][empty][request]
        frontend.recv( client_addr );
        frontend.recv( empty );
        Assert( empty = '' );
        frontend.recv( request );

        backend.send([
          worker_queue[0],
          '',
          client_addr,
          '',
          request
        ]);

        //  Dequeue and drop the next worker address
        dec( available_workers );
        for j := 0 to available_workers - 1 do
          worker_queue[j] := worker_queue[j+1];
      end;
    end;
  end;
  poller.Free;
  frontend.Free;
  backend.Free;
  context.Free;
  DeleteCriticalSection( cs );
end.

