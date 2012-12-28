unit ContextTestCase;

interface

{$I zmq.inc}

uses

  {$ifdef fpc}
  fpcunit, testutils, testregistry
  {$else}
  TestFramework
  {$endif}
  , Classes
  {$ifndef UNIX}
  , Windows
  {$endif}
  , zmqapi
  , zmq
  ;

type

  TContextTestCase = class(TTestCase)
  strict private
    context: TZMQContext;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ContextTerminate;
    {$ifdef zmq3}
    procedure ContextDefaults;
    procedure SetIOThreads;
    procedure SetMaxSockets;
    {$endif}

    procedure CreateReqSocket;
    procedure lazyPirateBugTest;
  end;

implementation

uses
  SysUtils;

{ TContextTestCase }

procedure TContextTestCase.ContextTerminate;
var
  st: TZMQSocketType;
  FZMQsocket: TZMQSocket;
  s: String;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      FZMQSocket.bind('tcp://127.0.0.1:5555');
      context.Linger := 10;
      context.Free;
      //CheckEquals( True, FZMQSocket.Terminated, 'Socket has not terminated! socket type: ' + IntToStr( Ord( st ) ) );

    finally
      context := nil;

      //FZMQsocket.Free;
    end;
  end;
end;

procedure TContextTestCase.CreateReqSocket;
var
  s: TZMQSocket;
  p: TZMQPoller;
begin
  s := context.Socket( streq );
  p := TZMQPoller.Create( true );
  s.connect( 'tcp://127.0.0.1:5555' );
  s.send('hhhh');
  p.Register( s , [pepollin] );
  p.poll(1000);
  p.Free;

  s.linger := 0;
  s.Free;

  context.Free;
  context := nil;
end;

procedure TContextTestCase.lazyPirateBugTest;
var
  sclient,
  sserver: TZMQSocket;
begin
  sserver := context.Socket( stRep );
  sserver.bind( 'tcp://*:5555' );

  sclient := context.Socket( stReq );
  sclient.connect( 'tcp://localhost:5555' );
  sclient.send('request1');

  sleep(500);
  sclient.Free;

  sclient := context.Socket( stReq );
  sclient.connect( 'tcp://localhost:5555' );
  sclient.send('request1');


  sclient.Free;
  sleep(500);

  sserver.Free;
  sleep(500);

  context.Free;
  context := nil;

end;

procedure TContextTestCase.SetUp;
begin
  inherited;
  context := TZMQContext.Create;
end;

procedure TContextTestCase.TearDown;
begin
  inherited;
  if context <> nil then
    context.Free;
end;

{$ifdef zmq3}
procedure TContextTestCase.ContextDefaults;
begin
  CheckEquals( ZMQ_IO_THREADS_DFLT, context.IOThreads );
  CheckEquals( ZMQ_MAX_SOCKETS_DFLT, context.MaxSockets );
end;

procedure TContextTestCase.SetIOThreads;
begin
  CheckEquals( ZMQ_IO_THREADS_DFLT, context.IOThreads );
  context.IOThreads := 0;
  CheckEquals( 0, context.IOThreads );
  context.IOThreads := 2;
  CheckEquals( 2, context.IOThreads );
end;

procedure TContextTestCase.SetMaxSockets;
begin
  CheckEquals( ZMQ_MAX_SOCKETS_DFLT, context.MaxSockets );
  context.MaxSockets := 16;
  CheckEquals( 16, context.MaxSockets );
end;


{$endif}


initialization
  {$ifdef fpc}
  RegisterTest(TContextTestCase);
  {$else}
  RegisterTest(TContextTestCase.Suite);
  {$endif}

end.
