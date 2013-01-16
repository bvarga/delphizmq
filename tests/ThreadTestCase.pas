unit ThreadTestCase;

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
  ;

type
  TMyZMQThread = class( TZMQThread )

  protected
    procedure DoExecute; override;
  public
    tvar: Boolean;
  end;

  TThreadTestCase = class( TTestCase )
  strict private
    context: TZMQContext;

    tvar: Boolean;
    tmpI: Integer;
    tmpS: Utf8String;

  public
    myThr: TMyZMQThread;

    procedure SetUp; override;
    procedure TearDown; override;

    procedure DetachedTestProc( args: Pointer; context: TZMQContext; terminated: PBoolean );
    procedure AttachedTestProc( args: Pointer; context: TZMQContext; pipe: TZMQSocket; terminated: PBoolean );

    procedure AttachedPipeTestProc( args: Pointer; context: TZMQContext; pipe: TZMQSocket; terminated: PBoolean );

    procedure Detached2TestProc( args: Pointer; context: TZMQContext; terminated: PBoolean );

    procedure InheritedThreadTerminate( Sender: TObject );

  published
    procedure CreateAttachedTest;
    procedure CreateDetachedTest;

    procedure CreateInheritedAttachedTest;
    procedure CreateInheritedDetachedTest;

    procedure CreateDetached2Test;

    procedure AttachedPipeTest;
  end;

implementation

uses
  Sysutils
  ;

var
  ehandle: THandle;

{ TMyZMQThread }

procedure TMyZMQThread.doExecute;
begin
  // custom code.
  tvar := true;
  SetEvent( ehandle );
end;

{ TThreadTestCase }

procedure TThreadTestCase.SetUp;
begin
  inherited;
  ehandle := CreateEvent( nil, true, false, nil );

  context := TZMQContext.Create;
  tvar := false;
end;

procedure TThreadTestCase.TearDown;
begin
  inherited;
  if context <> nil then
    context.Free;
  CloseHandle( ehandle );
end;

procedure TThreadTestCase.AttachedTestProc( args: Pointer; context: TZMQContext; pipe: TZMQSocket; terminated: PBoolean );
begin
  tvar := true;
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateAttachedTest;
var
  thr: TZMQThread;
begin
  thr := TZMQThread.CreateAttached( AttachedTestProc, context, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.DetachedTestProc( args: Pointer; context: TZMQContext; terminated: PBoolean );
var
  socket: TZMQSocket;
begin
  tvar := true;
  socket := context.Socket( TZMQSocketType( Args^ ) );
  Dispose( args );
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateDetachedTest;
var
  thr: TZMQThread;
  sockettype: ^TZMQSocketType;
begin
  New( sockettype );
  sockettype^ := stDealer;
  thr := TZMQThread.CreateDetached( DetachedTestProc, sockettype );
  thr.FreeOnTerminate := true;
  thr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.InheritedThreadTerminate( Sender: TObject );
begin
  // this executes in the main thread.
  tvar := myThr.tvar;
end;

procedure TThreadTestCase.CreateInheritedAttachedTest;
begin
  mythr := TMyZMQThread.Create( nil, context );
  mythr.OnTerminate := InheritedThreadTerminate;
  mythr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  sleep(10);
  mythr.Free;
  CheckEquals( true, tvar, 'tvar didn''t set' );
end;

procedure TThreadTestCase.CreateInheritedDetachedTest;
begin
  mythr := TMyZMQThread.Create( nil, nil );
  mythr.OnTerminate := InheritedThreadTerminate;
  mythr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  mythr.Free;
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.Detached2TestProc( args: Pointer; context: TZMQContext;
  terminated: PBoolean );
begin
  while not Terminated^ do
  begin
    // do something.
    inc( tmpI );
  end;
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateDetached2Test;
var
  thr: TZMQThread;
begin

  thr := TZMQThread.CreateDetached( Detached2TestProc, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  sleep(10);
  thr.Terminate;

  WaitForSingleObject( ehandle, INFINITE );
  CheckTrue( tmpI > 100, 'thread cycles less than 100' );

end;

procedure TThreadTestCase.AttachedPipeTestProc(args: Pointer;
  context: TZMQContext; pipe: TZMQSocket; terminated: PBoolean);
begin
  pipe.recv( tmpS );
  SetEvent( ehandle );
end;

procedure TThreadTestCase.AttachedPipeTest;
var
  thr: TZMQThread;
begin
  thr := TZMQThread.CreateAttached( AttachedPipeTestProc, context, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  thr.pipe.send( 'hello pipe' );

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( 'hello pipe', tmpS, 'pipe error' );

end;


initialization
  {$ifdef fpc}
  RegisterTest(TThreadTestCase);
  {$else}
  RegisterTest(TThreadTestCase.Suite);
  {$endif}
end.
