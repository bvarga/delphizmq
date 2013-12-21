unit CurveTestCase;

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

  TCurveTestCase = class(TTestCase)
  private

  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
  end;

implementation

uses
  SysUtils;

{ TZmqTestCase }


procedure TCurveTestCase.SetUp;
begin
  inherited;
end;

procedure TCurveTestCase.TearDown;
begin
  inherited;
end;

initialization
  {$ifdef fpc}
  RegisterTest(TCurveTestCase);
  {$else}
  RegisterTest(TCurveTestCase.Suite);
  {$endif}

end.
