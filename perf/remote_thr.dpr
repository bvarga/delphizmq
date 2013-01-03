{
    Copyright (c) 2012 Varga Balázs (bb.varga@gmail.com)

    This file is part of 0MQ Delphi binding

    0MQ Delphi binding is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation; either version 3 of the
    License, or (at your option) any later version.

    0MQ Delphi binding is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
}
program remote_thr;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  ;

var
  connectto: String;
  msgsize,
  msgcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQFrame;
  i: Integer;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: remote_thr <connect-to> <message-size> <message-count>' );
    exit;
  end;

  connectto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  msgcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stPush );
  socket.connect( connectto );

  for i := 0 to msgcount - 1 do
  begin
    msg := TZMQFrame.create( msgsize );
    FillMemory( msg.data, msgsize, 0 );
    socket.send( msg );
  end;

  socket.Free;
  context.Free;
end.
