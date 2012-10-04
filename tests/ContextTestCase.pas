unit ContextTestCase;

interface

{$I zmq.inc}

uses

    TestFramework
  , Classes
  , Windows
  , zmqapi
  ;

type

  TContextTestCase = class(TTestCase)
  strict private
    context: TZMQContext;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ContextDefaults;
    procedure SetIOThreads;
    procedure SetMaxSockets;
  end;

implementation

uses
  zmq;

{ TContextTestCase }

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

initialization
  RegisterTest(TContextTestCase.Suite);

end.
