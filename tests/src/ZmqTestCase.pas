unit ZMQTestCase;

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

  , zmq
  ;

type

  TZmqTestCase = class(TTestCase)
  private

  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure zmq_curve_keypair;
  end;

implementation

uses
  SysUtils;

{ TZmqTestCase }


procedure TZmqTestCase.SetUp;
begin
  inherited;
end;

procedure TZmqTestCase.TearDown;
begin
  inherited;
end;

procedure TZmqTestCase.zmq_curve_keypair;
var
  acPublic,
  acSecret: Array[0..40] of AnsiChar;
  sPublic,
  sSecret : String;

  rc,errn: Integer;
  errstr: String;

begin
  rc := zmq.zmq_curve_keypair( @acSecret[0], @acPublic[0] );
  //rc := zmq.zmq_curve_keypair( @sPublic[1], @sSecret[1] );
  if rc = -1 then
  begin
    errn := zmq_errno;
    errstr := String( AnsiString( zmq_strerror( errn ) ) );
    CheckEquals( 0, rc, errstr );
  end;

  sPublic := acPublic;
  sSecret := acSecret;

  CheckEquals( 40, Length( sPublic ), 'wrong length' );
  CheckEquals( 40, Length( sPublic ), 'wrong length' );

end;

initialization
  {$ifdef fpc}
  RegisterTest(TZmqTestCase);
  {$else}
  RegisterTest(TZmqTestCase.Suite);
  {$endif}

end.
