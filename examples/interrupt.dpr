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
  frame: TZMQFrame;
  rc: Integer;

begin
//  IsMultiThread := True;

  context := TZMQContext.Create;
  socket := Context.Socket( stRep );
  socket.bind( 'tcp://*:5555' );

  while True do
  begin
    frame := TZMQFrame.Create;
    try
      socket.recv( frame );
    except
      on e: EZMQException  do
      begin
        Writeln('Exception: ' + e.Message );
      end;
    end;
    FreeAndNil( frame );

    if socket.context.Terminated then
    begin
      Writeln( 'W: interrupt received, killing server...');
      break;
    end;

  end;
  socket.Free;
  context.Free;
  sleep(1000);
end.
