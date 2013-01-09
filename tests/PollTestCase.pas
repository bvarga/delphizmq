unit PollTestCase;
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
//  , zmqpoller
  ;

type

  TPollTestCase = class(TTestCase)
  strict private
    context: TZMQContext;
    poller: TZMQPoller;
    procedure PollEvent( socket: TZMQSocket; events: TZMQPollEvents );
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure PollRegister;
  end;

implementation

var
  ehandle: THandle;
  zmqPollItem: ^TZMQPollItem;

{$ifdef UNIX}

{$else}
procedure TPollTestCase.PollEvent( socket: TZMQSocket; events: TZMQPollEvents );
begin
  zmqPollItem^.socket := socket;
  zmqPollItem^.events := events;
  SetEvent( ehandle );
end;
{$endif}

{ TPollTestCase }

procedure TPollTestCase.SetUp;
begin
  inherited;
  context := TZMQContext.Create;
  poller := TZMQPoller.Create( false, context );
  poller.onEvent := PollEvent;
end;

procedure TPollTestCase.TearDown;
begin
  inherited;
  poller.Free;
  context.Free;
end;

procedure TPollTestCase.PollRegister;
var
  sb,sc: TZMQSocket;
  s: Utf8String;
begin
  New( zmqPollItem );
  ehandle := CreateEvent( nil, true, false, nil );

  sb := context.Socket( stPair );
  sb.bind( 'inproc://pair' );
  sc := context.Socket( stPair );
  sc.connect( 'inproc://pair' );

  //poller.register( sb, [pePollIn]);
  //sleep( 1000 );
  poller.Register( sb, [pePollIn], true );


  sc.send('Hello');

  WaitForSingleObject( ehandle, INFINITE );
  ResetEvent( ehandle );

  Check( zmqPollItem.socket = sb, 'wrong socket' );
  Check( zmqPollItem.events = [pePollIn], 'wrong event' );

  zmqPollItem.socket.recv( s );
  CheckEquals( 'Hello', s, 'wrong message received' );

  CloseHandle( ehandle );
  Dispose( zmqPollItem );
end;

initialization
  {$ifdef fpc}
  RegisterTest(TPollTestCase);
  {$else}
  RegisterTest(TPollTestCase.Suite);
  {$endif}

end.
