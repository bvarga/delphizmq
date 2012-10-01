unit simpleTestCase;

interface

{$I zmq.inc}

uses

    TestFramework
  , Classes
  , Windows
  , zmqapi
  ;

type

  TSimpleTestCase = class(TTestCase)
  strict private
    context: TZMQContext;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure SocketPair;
  end;

implementation

{ TSimpleTestCase }

procedure TSimpleTestCase.SetUp;
begin
  inherited;
  context := TZMQContext.Create;
end;

procedure TSimpleTestCase.TearDown;
begin
  inherited;
  if context <> nil then
    context.Free;
end;

procedure TSimpleTestCase.SocketPair;
var
  socketbind,
  socketconnect: TZMQSocket;
  s: String;
begin
  socketbind := context.Socket( stPair );
  socketbind.bind('tcp://127.0.0.1:5560');

  socketconnect := context.Socket( stPair );
  socketconnect.connect('tcp://127.0.0.1:5560');

  socketbind.send('Hello');
  socketconnect.recv( s );

  CheckEquals( 'Hello', s, 'stPair: Received something else' );

  socketconnect.Free;
  socketbind.Free;
end;

initialization
  RegisterTest(TSimpleTestCase.Suite);

end.
