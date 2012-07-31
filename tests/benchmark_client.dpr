program benchmark_client;

{$APPTYPE CONSOLE}

uses
    SysUtils
  , Windows
  , Classes
  , zmq
  , zmqapi
  ;
const
  cSend = 'Hello';
  sCount = 10000;
var
  c,
  s: Pointer;
  ms,
  mr: zmq_msg_t;
  str: String;

  i: Integer;
  tsl: TStringList;

  fFrequency,
  fstart,
  fStop : Int64;

  context: TZMQContext;
  socket: TZMQSocket;

begin
  c := zmq_init(1);
  s := zmq_socket( c, ZMQ_REQ );
  zmq_connect( s, 'tcp://localhost:5555' );

  Writeln( Format( 'sending %d "%s" with pure zmq', [sCount,cSend] ) );
  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to sCount - 1  do
  begin
    zmq_msg_init_size( ms, 5 );

    CopyMemory( zmq_msg_data( ms ), @cSend[1], 5 );
    zmq_send( s, ms, 0 );
    zmq_msg_close( ms );

    zmq_msg_init( mr );
    zmq_recv( s, mr, 0 );

    SetString( str, PChar( zmq_msg_data( mr ) ), 5 );
    zmq_msg_close( mr );
  end;

  QueryPerformanceCounter( fStop );
  Writeln( Format( 'Total elapsed time: %d msec', [
    ((MSecsPerSec * (fStop - fStart)) div fFrequency) ]) );

  zmq_close( s );
  zmq_term( c );

  context := TZMQContext.create(1);
  socket := TZMQSocket.Create( context, stReq );
  socket.connect('tcp://localhost:5555');
  Writeln( Format( 'sending %d "%s" with zmqapi', [sCount,cSend] ) );
  QueryPerformanceFrequency( fFrequency );
  QueryPerformanceCounter( fStart );

  for i := 0 to sCount - 1  do
  begin
    socket.send( cSend );
    socket.recv( str );
  end;

  QueryPerformanceCounter( fStop );
  Writeln( Format( 'Total elapsed time: %d msec', [
    ((MSecsPerSec * (fStop - fStart)) div fFrequency) ]) );

  socket.Free;
  context.Free;
end.
