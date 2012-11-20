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
      context := TZMQContext.Create;

      //FZMQsocket.Free;
    end;
  end;
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
