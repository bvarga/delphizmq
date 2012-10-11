unit SocketTestCase;

interface

{$I zmq.inc}

uses

    TestFramework
  , Classes
  , Windows
  , zmqapi
  ;

type

  TSocketTestCase = class(TTestCase)
  strict private
    context: TZMQContext;
    FZMQSocket: TZMQSocket;

  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSocketType;
    procedure TestrcvMore;
    procedure TestHWM;
    {$ifdef zmq3}
    procedure TestSndHWM;
    procedure TestRcvHWM;
    procedure TestLastEndpoint;
    procedure TestAcceptFilter;
    {$else}
    procedure TestSwap;
    procedure TestRecoveryIvlMSec;
    procedure TestMCastLoop;
    {$endif}
    procedure TestRcvTimeout;
    procedure TestSndTimeout;
    procedure TestAffinity;
    procedure TestIdentity;
    procedure TestRate;
    procedure TestRecoveryIvl;
    procedure TestSndBuf;
    procedure TestRcvBuf;
    procedure TestLinger;
    procedure TestReconnectIvl;
    procedure TestReconnectIvlMax;
    procedure TestBacklog;
    procedure TestFD;
    procedure TestEvents;
    procedure TestSubscribe;
    procedure TestunSubscribe;

    procedure SocketPair;




  end;

implementation

uses
  Sysutils
  ;

{ TSimpleTestCase }

procedure TSocketTestCase.SetUp;
begin
  inherited;
  context := TZMQContext.Create;
end;

procedure TSocketTestCase.TearDown;
begin
  inherited;
  if context <> nil then
    context.Free;
end;

procedure TSocketTestCase.TestSocketType;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      Check( FZMQSocket.SocketType = st, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestrcvMore;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( False, FZMQSocket.rcvMore, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestHWM;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( {$ifdef zmq3}1000{$else}0{$endif}, FZMQSocket.HWM, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.HWM := 42;
      CheckEquals( 42, FZMQSocket.HWM );
    finally
      FZMQSocket.Free;
    end;
  end;
end;


{$ifdef zmq3}
procedure TSocketTestCase.TestSndHWM;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 1000, FZMQSocket.SndHWM, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.SndHWM := 42;
      CheckEquals( 42, FZMQSocket.SndHWM );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestRcvHWM;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 1000, FZMQSocket.RcvHWM, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.RcvHWM := 42;
      CheckEquals( 42, FZMQSocket.RcvHWM );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestLastEndpoint;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( '', FZMQSocket.LastEndpoint, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.bind('tcp://127.0.0.1:5555');
      Sleep(10);
      CheckEquals( 'tcp://127.0.0.1:5555', FZMQSocket.LastEndpoint, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
    finally
      FZMQSocket.unbind('tcp://127.0.0.1:5555');
      Sleep(10);
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestAcceptFilter;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      FZMQSocket.bind('tcp://*:5555');
      Sleep(10);
      FZMQSocket.AddAcceptFilter('192.168.1.1');
      CheckEquals( '192.168.1.1', FZMQSocket.AcceptFilter[0], 'Add Accept Filter 1' );
      FZMQSocket.AddAcceptFilter('192.168.1.2');
      CheckEquals( '192.168.1.2', FZMQSocket.AcceptFilter[1], 'Add Accept Filter 2' );
      FZMQSocket.AcceptFilter[0] := '192.168.1.3';
      CheckEquals( '192.168.1.3', FZMQSocket.AcceptFilter[0], 'Change Accept Filter 1' );
      try
        // trying to set wrong value
        FZMQSocket.AcceptFilter[0] := 'xraxsda';
        CheckEquals( '192.168.1.3', FZMQSocket.AcceptFilter[0], 'Change Accept Filter 2' );
      except
        on e: Exception do
        begin
          if e is EZMQException then
          begin
            CheckEquals( '192.168.1.3', FZMQSocket.AcceptFilter[0], 'set Invalid check 1' );
            CheckEquals( '192.168.1.2', FZMQSocket.AcceptFilter[1], 'set Invalid check 2' );
          end else
            raise;
        end;
      end;
    finally
      FZMQSocket.unbind('tcp://*:5555');
      Sleep(10);
      FZMQSocket.Free;
    end;
  end;
end;

{$else}

procedure TSocketTestCase.TestSwap;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 0, FZMQSocket.Swap, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Swap := 1024;
      CheckEquals( 1024, FZMQSocket.Swap );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestRecoveryIvlMSec;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( -1, FZMQSocket.RecoveryIvlMSec, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.RecoveryIvlMSec := 1024;
      CheckEquals( 1024, FZMQSocket.RecoveryIvlMSec );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestMCastLoop;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 1, FZMQSocket.MCastLoop, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.MCastLoop := 0;
      CheckEquals( 0, FZMQSocket.MCastLoop );
    finally
      FZMQSocket.Free;
    end;
  end;
end;
{$endif}

procedure TSocketTestCase.TestRcvTimeout;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( -1, FZMQSocket.RcvTimeout, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.RcvTimeout := 42;
      CheckEquals( 42, FZMQSocket.RcvTimeout );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestSndTimeout;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( -1, FZMQSocket.SndTimeout, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.SndTimeout := 42;
      CheckEquals( 42, FZMQSocket.SndTimeout );
    finally
      FZMQSocket.Free;
    end;
  end;
end;


procedure TSocketTestCase.TestAffinity;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 0, FZMQSocket.Affinity, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Affinity :=42;
      CheckEquals( 42, FZMQSocket.Affinity );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestIdentity;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( '', FZMQSocket.Identity, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Identity := 'mynewidentity';
      CheckEquals( 'mynewidentity', FZMQSocket.Identity );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestRate;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 100, FZMQSocket.Rate, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Rate := 200;
      CheckEquals( 200, FZMQSocket.Rate );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestRecoveryIvl;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( {$ifdef zmq3}10000{$else}10{$endif}, FZMQSocket.RecoveryIvl, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.RecoveryIvl := 42;
      CheckEquals( 42, FZMQSocket.RecoveryIvl );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestSndBuf;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 0, FZMQSocket.SndBuf, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.SndBuf := 100000;
      CheckEquals( 100000, FZMQSocket.SndBuf );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestRcvBuf;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 0, FZMQSocket.RcvBuf, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.RcvBuf := 4096;
      CheckEquals( 4096, FZMQSocket.RcvBuf );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestLinger;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( -1, FZMQSocket.Linger, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Linger := 1024;
      CheckEquals( 1024, FZMQSocket.Linger );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestReconnectIvl;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 100, FZMQSocket.ReconnectIvl, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.ReconnectIvl := 2048;
      CheckEquals( 2048, FZMQSocket.ReconnectIvl );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestReconnectIvlMax;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 0, FZMQSocket.ReconnectIvlMax, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.ReconnectIvlMax := 42;
      CheckEquals( 42, FZMQSocket.ReconnectIvlMax );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestBacklog;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( 100, FZMQSocket.Backlog, 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
      FZMQSocket.Backlog := 42;
      CheckEquals( 42, FZMQSocket.Backlog );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestFD;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      Check( Assigned( FZMQSocket.FD ) );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestEvents;
var
  st: TZMQSocketType;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    FZMQSocket := context.Socket( st );
    try
      CheckEquals( True, FZMQSocket.Events = [], 'Default check for socket type: ' + IntToStr( Ord( st ) ) );
    finally
      FZMQSocket.Free;
    end;
  end;
end;

procedure TSocketTestCase.TestSubscribe;
var
  filter: string;
begin
{  FZMQSocket := context.Socket( st );
  try
  // TODO: Setup method call parameters
  FZMQSocket.Subscribe(filter);
  // TODO: Validate method results
  finally
    FZMQSocket.Free;
  end;
}end;

procedure TSocketTestCase.TestunSubscribe;
var
  filter: string;
begin
{  FZMQSocket := context.Socket( st );
  try
  // TODO: Setup method call parameters
  FZMQSocket.unSubscribe(filter);
  // TODO: Validate method results
  finally
    FZMQSocket.Free;
  end;
}end;

procedure TSocketTestCase.SocketPair;
var
  socketbind,
  socketconnect: TZMQSocket;
  s: String;
  tsl: TStringList;
begin
  socketbind := context.Socket( stPair );
  try
    socketbind.bind('tcp://127.0.0.1:5560');

    socketconnect := context.Socket( stPair );
    try
      socketconnect.connect('tcp://127.0.0.1:5560');

      socketbind.send('Hello');
      socketconnect.recv( s );
      CheckEquals( 'Hello', s, 'String' );

      socketbind.send(['Hello','World']);
      tsl := TStringList.Create;
      try
        socketconnect.recv( tsl );
        CheckEquals( 'Hello', tsl[0], 'Multipart 1 message 1' );
        CheckEquals( 'World', tsl[1], 'Multipart 1 message 2' );
      finally
        tsl.Free;
      end;

      tsl := TStringList.Create;
      try
        tsl.Add('Hello');
        tsl.Add('World');
        socketbind.send( tsl );
        tsl.Clear;
        socketconnect.recv( tsl );
        CheckEquals( 'Hello', tsl[0], 'Multipart 2 message 1' );
        CheckEquals( 'World', tsl[1], 'Multipart 2 message 2' );
      finally
        tsl.Free;
      end;


    finally
      socketconnect.Free;
    end;
  finally
    socketbind.Free;
  end;
end;

initialization
  RegisterTest(TSocketTestCase.Suite);
end.
