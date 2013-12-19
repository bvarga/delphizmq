program fpctests;

{$mode delphi}{$H+}

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  Interfaces, Forms, SocketTestCase, ContextTestCase, GuiTestRunner;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

