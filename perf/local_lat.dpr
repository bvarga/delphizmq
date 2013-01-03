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
program local_lat;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
  bindto: String;
  msgsize: Integer;
  roundtripcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQFrame;
  i: Integer;
begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: local_lat <bind-to> <message-size> <roundtrip-count>' );
    exit;
  end;

  bindto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  roundtripcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stRep );
  socket.bind( bindto );

  for i := 0 to roundtripcount -1 do
  begin
    msg := TZMQFrame.create( msgsize );
    if socket.recv( msg ) <> msgsize then
      raise Exception.Create( 'message of incorrect size received' );
    socket.send( msg );
  end;

  socket.Free;
  context.Free;
end.
