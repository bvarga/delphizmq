unit PushPullTestCase;

interface

{$I zmq.inc}

uses

    TestFramework
  , Classes
  , Windows
  , zmqapi
  ;

const
  cBind = 'tcp://*:5555';
  cConnect = 'tcp://127.0.0.1:5555';
  
type

  TPushPullTestCase = class(TTestCase)
  strict private
    context: TZMQContext;

  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure SendString;
    procedure SendStringThread;
    procedure SendStringThreadFirstConnect;
  end;

implementation

uses
  Sysutils
  ;

var
  ehandle: THandle;

{ TPushPullTestCase }

procedure TPushPullTestCase.SetUp;
begin
  inherited;
  context := TZMQContext.Create;
end;

procedure TPushPullTestCase.TearDown;
begin
  inherited;
  if context <> nil then
    context.Free;
end;

procedure TPushPullTestCase.SendString;
var
  sPush,sPull: TZMQSocket;
  s: Utf8String;
  rc: Integer;
begin
  sPush := context.Socket( stPush );
  try
    sPush.bind( cBind );
    sPull := context.Socket( stPull );
    try
      sPull.connect( cConnect );
      sPush.send( 'Hello' );
      rc := sPull.recv( s );
      CheckEquals( 5, rc, 'checking result' );
      CheckEquals( 'Hello', s, 'checking value' );
    finally
      sPull.Free;
    end;
  finally
    sPush.Free;
  end;
end;

procedure PushProc( lcontext: TZMQContext );
var
  sPush: TZMQSocket;
begin
  WaitForSingleObject( ehandle, INFINITE );
  sPush := lcontext.Socket( stPush );
  try
    sPush.bind( cBind );
    sPush.send( 'Hello' );
  finally
    sPush.Free;
  end;
end;

procedure TPushPullTestCase.SendStringThread;
var
  sPull: TZMQSocket;
  s: Utf8String;
  rc: Integer;
  tid: Cardinal;
begin
  SetEvent( ehandle );
  BeginThread( nil, 0, @pushProc, context, 0, tid );

  sPull := context.Socket( stPull );
  try
    sPull.connect( cConnect );
    rc := sPull.recv( s );
    CheckEquals( 5, rc, 'checking result' );
    CheckEquals( 'Hello', s, 'checking value' );

  finally
    sPull.Free;
  end;

end;

// should work, because push blocks until a downstream node
// become available.
procedure TPushPullTestCase.SendStringThreadFirstConnect;
var
  sPull: TZMQSocket;
  s: Utf8String;
  rc: Integer;
  tid: Cardinal;
begin
  ResetEvent( ehandle );
  BeginThread( nil, 0, @pushProc, context, 0, tid );

  sPull := context.Socket( stPull );
  try
    sPull.connect( cConnect );
    SetEvent( ehandle );
    rc := sPull.recv( s );
    CheckEquals( 5, rc, 'checking result' );
    CheckEquals( 'Hello', s, 'checking value' );

  finally
    sPull.Free;
  end;
end;

{
  try
    SetEvent( ehandle );
    WaitForSingleObject( ehandle, INFINITE );
  finally
  end;
}
initialization
  RegisterTest(TPushPullTestCase.Suite);
  ehandle := CreateEvent( nil, true, true, nil );

finalization
  CloseHandle( ehandle );

end.
