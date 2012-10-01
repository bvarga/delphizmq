program interrupt;
//
//  Shows how to handle Ctrl-C
//
{$APPTYPE CONSOLE}

uses
    Windows
  , SysUtils
  , zmqapi
  ;

//  ---------------------------------------------------------------------
//  Signal handling
//
//  Call s_catch_signals() in your application at startup, and then exit
//  your main loop if s_interrupted is ever 1. Works especially well with
//  zmq_poll.

var
  s_interrupted: Integer = 0;
  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;

function console_handler( dwCtrlType: DWORD ): BOOL; stdcall;
begin
  if CTRL_C_EVENT = dwCtrlType then
  begin
    s_interrupted := 1;
    result := True;
  end else
  result := False;
end;

begin
  IsMultiThread := True;
  Windows.SetConsoleCtrlHandler( @console_handler, True );


  context := TZMQContext.Create;
  socket := Context.Socket( stRep );
  socket.bind( 'tcp://*:5555' );

  while True do
  begin

      //  Blocking read will exit on a signal
      // it's not true on windows. :(
      msg := TZMQMessage.Create;
      socket.recv( msg );

      if s_interrupted > 0 then
      begin
        Writeln( 'W: interrupt received, killing server...');
        break;
      end;
  end;
  socket.Free;
  context.Free;
end.
