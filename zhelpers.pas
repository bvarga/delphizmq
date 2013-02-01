unit zhelpers;

interface

uses
    SysUtils
  , Classes
  , zmqapi
  ;

procedure s_dump( socket: TZMQSocket );
function s_random( len: Integer ): Utf8String;
procedure s_set_id( socket: TZMQSocket );

// for threadSafe logging to the console.
procedure zNote( str: String );

function zTimeStamp: Int64;
function zCalcTimeMs( tstart, tstop: Int64 ): Int64;

function zIncTimeMs( tNow, tIncrementMs: Int64 ): Int64;
function zIncTimeUs( tNow, tIncrementUs: Int64 ): Int64;

implementation

uses
  Windows;

var
  cs: TRTLCriticalSection;
  fFrequency: Int64;


procedure zNote( str: String );
begin
  EnterCriticalSection( cs );
  Writeln( str );
  LeaveCriticalSection( cs );
end;

procedure s_dump( socket: TZMQSocket );

  function validChar( frm: TZMQFrame; indx: Integer ): Boolean;
    var
      pb: PByte;
    begin
      pb := PByte(Integer(frm.data) + indx);
      result := ( pb^ >= 32 ) and ( pb^ < 127 );
    end;

var
  msg: TZMQMsg;
  frame: TZMQFrame;
  i: Cardinal;
  str: Utf8String;
begin
  zNote( '----------------------------------------' );
  msg := TZMQMsg.create;
  try
    socket.recv( msg );
    frame := msg.pop;
    while frame <> nil do
    try
      i := 0;
      while ( i < frame.size ) and validChar( frame, i ) do
        inc( i );

      if i = frame.size then
        str := frame.asUtf8String
      else begin
        SetLength( str, frame.size * 2 );
        BinToHex( frame.data, @str[1], frame.size );
      end;
      zNote( Format( '[%03d] %s', [ frame.size, str ] ) );
    finally
      frame.Free;
      frame := msg.pop;
    end;
  finally
    msg.Free;
  end;
end;

function s_random( len: Integer ): Utf8String;
const
  Chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
var
  s: String;
  i: integer;
begin
  Randomize;
  result := '';
  for i := 1 to len do
    result := result + Chars[Random(Length(Chars)) + 1];
end;

//  Set simple random printable identity on socket
//
procedure s_set_id( socket: TZMQSocket );
begin
  socket.Identity := s_random( 10 );
end;

// get timestamp
function zTimeStamp: Int64;
begin
  QueryPerformanceCounter( result );
end;

function zCalcTimeMs( tstart, tstop: Int64 ): Int64;
begin
  if fFrequency > 0 then
    result := ( MSecsPerSec * (tstop - tstart ) ) div fFrequency
  else
    result := 0;
end;

function zCalcTimeUs( tstart, tstop: Int64 ): Int64;
begin
  if fFrequency > 0 then
    result := ( MSecsPerSec * MSecsPerSec * (tstop - tstart ) ) div fFrequency
  else
    result := 0;
end;

function zIncTimeMs( tNow, tIncrementMs: Int64 ): Int64;
begin
  result := ( tIncrementMs * fFrequency ) div MSecsPerSec + tNow;
end;

function zIncTimeUs( tNow, tIncrementUs: Int64 ): Int64;
begin
  result := ( tIncrementUs * fFrequency ) div ( MSecsPerSec * MSecsPerSec )+ tNow;
end;

initialization
  {$ifdef UNIX}
  InitCriticalSection( cs );
  {$else}
  InitializeCriticalSection( cs );
  {$endif}
  QueryPerformanceFrequency( fFrequency );


finalization
  {$ifdef UNIX}
  DoneCriticalSection( cs );
  {$else}
  DeleteCriticalSection( cs );
  {$endif}

end.
