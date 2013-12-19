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
  private
    context: TZMQContext;

    tvar: Boolean;
    tmpI: Integer;
    tmpS: Utf8String;

  public
    myThr: TMyZMQThread;

    procedure SetUp; override;
    procedure TearDown; override;

    procedure DetachedTestMeth( args: Pointer; context: TZMQContext );
    procedure AttachedTestMeth( args: Pointer; context: TZMQContext; pipe: TZMQSocket );

    procedure AttachedPipeTestMeth( args: Pointer; context: TZMQContext; pipe: TZMQSocket );

    procedure InheritedThreadTerminate( Sender: TObject );

  published
    procedure CreateAttachedTest;
    procedure CreateDetachedTest;

    procedure CreateInheritedAttachedTest;
    procedure CreateInheritedDetachedTest;


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

procedure TThreadTestCase.AttachedTestMeth( args: Pointer; context: TZMQContext; pipe: TZMQSocket );
begin
  tvar := true;
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateAttachedTest;
var
  thr: TZMQThread;
begin
  thr := TZMQThread.CreateAttached( AttachedTestMeth, context, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.DetachedTestMeth( args: Pointer; context: TZMQContext );
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
  thr := TZMQThread.CreateDetached( DetachedTestMeth, sockettype );
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

procedure TThreadTestCase.AttachedPipeTestMeth(args: Pointer;
  context: TZMQContext; pipe: TZMQSocket );
begin
  pipe.recv( tmpS );
  SetEvent( ehandle );
end;

procedure TThreadTestCase.AttachedPipeTest;
var
  thr: TZMQThread;
begin
  thr := TZMQThread.CreateAttached( AttachedPipeTestMeth, context, nil );
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
