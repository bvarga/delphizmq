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
program remote_lat;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , zmqapi
  ;

var
  connectto: String;
  msgsize: Integer;
  roundtripcount: Integer;

  context: TZMQContext;
  socket: TZMQSocket;
  msg: TZMQFrame;
  i: Integer;
  elapsed,
  latency: Real;

  fFrequency,
  fstart,
  fStop : Int64;

begin
  if ParamCount <> 3 then
  begin
    Writeln('usage: remote_lat <connect-to> <message-size> <roundtrip-count>' );
    exit;
  end;

  connectto := ParamStr( 1 );
  msgsize := StrToInt( ParamStr( 2 ) );
  roundtripcount := StrToInt( ParamStr( 3 ) );

  context := TZMQContext.Create;
  socket := context.Socket( stReq );
  socket.connect( connectto );

  msg := TZMQFrame.create( msgsize );

  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to roundtripcount - 1 do
  begin
    socket.send( msg );
    if socket.recv( msg ) <> msgsize then
      raise Exception.Create( 'message of incorrect size received' );
  end;
  QueryPerformanceCounter( fStop );
  elapsed := 1000*1000*(fStop - fStart) / fFrequency;

  msg.Free;

  latency := elapsed / (roundtripcount * 2);

  Writeln( Format('message size: %d [B]',[ msgsize ] ) );
  Writeln( Format('roundtrip count: %d', [roundtripcount] ) );
  Writeln( Format('average latency: %.3f [us]', [ latency ] ) );

  socket.Free;
  context.Free;
end.
