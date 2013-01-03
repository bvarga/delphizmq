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
program local_thr;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  ;

var
  bindto: String;
  msgsize,
  msgcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQFrame;

  fFrequency,
  fstart,
  fStop : Int64;

  i: Integer;
  elapsed,
  throughput,
  megabits: Real;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: local_thr <bind-to> <message-size> <message-count>' );
    exit;
  end;

  bindto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  msgcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stPull );
  socket.bind( bindto );

  msg := TZMQFrame.create;
  if socket.recv( msg ) <> msgsize then
    raise Exception.Create('message of incorrect size received');

  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to msgcount - 2 do
  if socket.recv( msg ) <> msgsize then
    raise Exception.Create( 'message of incorrect size received' );

  QueryPerformanceCounter( fStop );
  elapsed := 1000*1000*(fStop - fStart) / fFrequency;
  if elapsed = 0 then
    elapsed := 1;

  msg.Free;
  throughput := msgcount / elapsed * 1000000;
  megabits := throughput * msgsize * 8 / 1000000;

  Writeln( Format('message size: %d [B]',[ msgsize ] ) );
  Writeln( Format('message count: %d', [ msgcount ] ) );
  Writeln( Format('mean throughput: %f [msg/s]', [ throughput ] ) );
  Writeln( Format('mean throughput: %.3f [Mb/s]', [ megabits ] ) );

  socket.Free;
  context.Free;
end.
