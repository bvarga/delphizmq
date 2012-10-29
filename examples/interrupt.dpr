program interrupt;
//
//  Shows how to handle Ctrl-C
//
{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQMessage;


begin
//  IsMultiThread := True;

  context := TZMQContext.Create;
  socket := Context.Socket( stRep );
  socket.bind( 'tcp://*:5555' );

  while True do
  begin

      //  Blocking read will exit on a signal
      // it's not true on windows. :(
      msg := TZMQMessage.Create;
      socket.recv( msg );

      if context.Interrupted then
      begin
        Writeln( 'W: interrupt received, killing server...');
        break;
      end;
  end;
  socket.Free;
  context.Free;
end.
