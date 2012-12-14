program asyncsrv;
//
//  Asynchronous client-to-server (DEALER to ROUTER)
//
//  While this example runs in a single process, that is just to make
//  it easier to start and stop the example. Each task has its own
//  context and conceptually acts as a separate process.

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Classes
  , zmqapi
  ;

//  ---------------------------------------------------------------------
//  This is our client task
//  It connects to the server, and then sends a request once per second
//  It collects responses as they arrive, and it prints them out. We will
//  run several client tasks in parallel, each with a different random ID.

procedure client_task( args: Pointer );
var
  ctx: TZMQContext;
  client: TZMQSocket;
  poller: TZMQPoller;
  pr: TZMQPollItem;
  i, pc, request_nbr: Integer;
  tsl: TStringList;
begin
  ctx := TZMQContext.create;
  client := ctx.Socket( stDealer );

  //  Set random identity to make tracing easier
  client.Identity := IntToHex( Integer(client),8 );
  client.connect( 'tcp://localhost:5570' );

  poller := TZMQPoller.Create( true );
  poller.register( client, [pePollIn] );

  tsl := TStringList.Create;

  request_nbr := 0;
  while true do
  begin
    //  Tick once per second, pulling in arriving messages
    for i := 0 to 100 - 1 do
    begin
      pc := poller.poll( 10 );
      if ( pc > 0 ) then
      begin
        pr := poller.pollResult[0];
        tsl.Clear;
        pr.socket.recv( tsl );
        ZMQNote( tsl[0] + ' ' + client.Identity );
      end;
    end;
    request_nbr := request_nbr + 1;
    client.send( Format('request #%d',[request_nbr]) )
  end;
  tsl.Free;
  ctx.Free;
end;

//  This is our server task.
//  It uses the multithreaded server model to deal requests out to a pool
//  of workers and route replies back to clients. One worker can handle
//  one request at a time but one client can talk to multiple workers at
//  once.

procedure server_worker( args: Pointer ); forward;

procedure server_task( args: Pointer );
var
  ctx: TZMQContext;
  frontend,
  backend: TZMQSocket;
  i: Integer;
  tid: Cardinal;
begin
  ctx := TZMQContext.create;

  //  Frontend socket talks to clients over TCP
  frontend := ctx.Socket( stRouter );
  frontend.bind( 'tcp://*:5570' );

  //  Backend socket talks to workers over inproc
  backend := ctx.Socket( stDealer );
  backend.bind( 'inproc://backend' );

  //  Launch pool of worker threads, precise number is not critical
  for i := 0 to 4 do
    BeginThread( nil, 0, @server_worker, ctx, 0, tid );

  //  Connect backend to frontend via a proxy
  ZMQProxy( frontend, backend, nil );

  ctx.Free;
end;

//  Each worker task works on one request at a time and sends a random number
//  of replies back, with random delays between replies:

procedure server_worker( args: Pointer );
var
  ctx: TZMQContext;
  worker: TZMQSocket;
  tsl: TStringList;
  i,replies: Integer;
begin
  ctx := args;
  worker := ctx.Socket( stDealer );
  worker.connect( 'inproc://backend' );
  tsl := TStringList.Create;
  while true do
  begin
    //  The DEALER socket gives us the reply envelope and message
    worker.recv( tsl );

    //  Send 0..4 replies back
    replies := Random( 5 );
    for i := 0 to replies - 1 do
    begin
      //  Sleep for some fraction of a second
      sleep( Random(1000) + 1 );
      worker.send( [ tsl[0], tsl[1] ] );
    end;
    tsl.Clear;

  end;
  tsl.Free;
end;

var
  tid: Cardinal;
  ctx: TZMQContext;
begin
  //  The main thread simply starts several clients, and a server, and then
  //  waits for the server to finish.
  Randomize;

  ctx := TZMQContext.create;
  BeginThread( nil, 0, @client_task, nil, 0, tid );
  BeginThread( nil, 0, @client_task, nil, 0, tid );
  BeginThread( nil, 0, @client_task, nil, 0, tid );

  BeginThread( nil, 0, @server_task, nil, 0, tid );

  sleep( 5 * 1000 );
  ctx.Free;

end.
