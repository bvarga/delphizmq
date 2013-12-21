program tests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}
{$I zmq.inc}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  SocketTestCase in '..\src\SocketTestCase.pas',
  ContextTestCase in '..\src\ContextTestCase.pas',
  PushPullTestCase in '..\src\PushPullTestCase.pas',
  PollTestCase in '..\src\PollTestCase.pas',
  ThreadTestCase in '..\src\ThreadTestCase.pas',
  ZmqTestCase in '..\src\ZmqTestCase.pas',
  CurveTestCase in '..\src\CurveTestCase.pas';

{$R *.RES}

begin
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
end.

