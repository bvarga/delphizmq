program tests.zmq3;
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
  SocketTestCase in 'SocketTestCase.pas',
  ContextTestCase in 'ContextTestCase.pas',
  PushPullTestCase in 'PushPullTestCase.pas',
  PollTestCase in 'PollTestCase.pas',
  ThreadTestCase in 'ThreadTestCase.pas';

{$R *.RES}

begin
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
end.

