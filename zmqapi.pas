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
unit zmqapi;

{$I zmq.inc}

interface

uses
    Windows
  , Classes
  , SysUtils
  , zmq
  ;

type
  EZMQException = class( Exception )
  private
    errnum: Integer;
  public
    constructor Create; overload;
    constructor Create( lerrn: Integer ); overload;
    property Num: Integer read errnum;
  end;

  TZMQContext = class;

  TZMQMessage = class
  private
    fMessage: zmq_msg_t;
  public
    constructor create; overload;
    constructor create( size: size_t ); overload;
    constructor create( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil ); overload;
    destructor Destroy; override;
    procedure rebuild; overload;
    procedure rebuild( size: size_t ); overload;
    procedure rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil ); overload;
    procedure move( msg: TZMQMessage );
    procedure copy( msg: TZMQMessage );
    function data: Pointer;
    function size: size_t;
  end;


  TZMQSocketType = ( stPair, stPub, stSub, stReq, stRep, stDealer,
    stRouter, stPull, stPush, stXPub, stXSub );

  TZMQSendFlag = ( {$ifdef zmq3}sfDontWait{$else}sfNoBlock{$endif}, sfSndMore );
  TZMQSendFlags = set of TZMQSendFlag;

  TZMQRecvFlag = ( {$ifdef zmq3}rfDontWait{$else}rfNoBlock{$endif} );
  TZMQRecvFlags = set of TZMQRecvFlag;

  TZMQPollEvent = ( pePollIn, pePollOut, pePollErr );
  TZMQPollEvents = set of TZMQPollEvent;

  TZMQSocket = class
  // low level
  protected
    fSocket: Pointer;
    fContext: TZMQContext;
  private
    procedure close;
    procedure setSockOpt( option: Integer; optval: Pointer; optvallen: size_t );
    procedure getSockOpt( option: Integer; optval: Pointer; var optvallen: size_t );
    function send( msg: TZMQMessage; flags: Integer = 0 ): Integer; overload;
    function recv( msg: TZMQMessage; flags: Integer = 0 ): Integer; overload;
  public
    procedure bind( addr: String );
    procedure connect( addr: String );
    {$ifdef zmq3}
    procedure unbind( addr: String );
    procedure disconnect( addr: String );
    {$endif}

  // helpers
  private
    procedure CheckResult( rc: Integer );
    function getSockOptInt64( option: Integer ): Int64;
    function getSockOptInteger( option: Integer ): Integer;
    procedure setSockOptInt64( option: Integer; const Value: Int64 );
    procedure setSockOptInteger( option: Integer; const Value: Integer );
  public
    destructor Destroy; override;

    function getSocketType: TZMQSocketType;
    function getrcvMore: Boolean;
    {$ifndef zmq3}
    function getHWM: Int64;
    {$endif}
    function getRcvTimeout: Integer;
    function getSndTimeout: Integer;
    {$ifndef zmq3}
    function getSwap: Int64;
    {$endif}
    function getAffinity: Int64;
    function getIdentity: ShortString;
    function getRate: int64;
    function getRecoveryIvl: Int64;
    {$ifndef zmq3}
    function getRecoveryIvlMSec: Int64;
    function getMCastLoop: Int64;
    {$endif}
    function getSndBuf: Int64;
    function getRcvBuf: Int64;
    function getLinger: Integer;
    function getReconnectIvl: Integer;
    function getReconnectIvlMax: Integer;
    function getBacklog: Integer;
    function getFD: Pointer;
    function getEvents: TZMQPollEvents;

    {$ifndef zmq3}
    procedure setHWM( const Value: Int64 );
    {$endif}
    procedure setRcvTimeout( const Value: Integer );
    procedure setSndTimeout( const Value: Integer );
    {$ifndef zmq3}
    procedure setSwap( const Value: Int64 );
    {$endif}
    procedure setAffinity( const Value: Int64 );
    procedure setIdentity( const Value: ShortString );
    procedure setRate( const Value: int64 );
    procedure setRecoveryIvl( const Value: Int64 );
    {$ifndef zmq3}
    procedure setRecoveryIvlMSec( const Value: Int64 );
    procedure setMCastLoop( const Value: Int64 );
    {$endif}
    procedure setSndBuf( const Value: Int64 );
    procedure setRcvBuf( const Value: Int64 );
    procedure setLinger( const Value: Integer );
    procedure setReconnectIvl( const Value: Integer );
    procedure setReconnectIvlMax( const Value: Integer );
    procedure setBacklog( const Value: Integer );

    procedure Subscribe( filter: String );
    procedure unSubscribe( filter: String );

    function send( msg: TZMQMessage; flags: TZMQSendFlags = [] ): Integer; overload;
    function send( strm: TStream; size: Integer; flags: TZMQSendFlags = [] ): Integer; overload;
    function send( msg: String; flags: TZMQSendFlags = [] ): Integer; overload;
    function send( msg: Array of String; dontwait: Boolean = false ): Integer; overload;
    function send( msg: TStrings; dontwait: Boolean = false ): Integer; overload;
    {$ifdef zmq3}
    function sendBuffer( const Buffer; len: Size_t; flags: TZMQSendFlags = [] ): Integer;
    {$endif}

    function recv( msg: TZMQMessage; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( strm: TStream; var size: Integer; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( var msg: String; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( msg: TStrings; flags: TZMQRecvFlags = [] ): Integer; overload;
    {$ifdef zmq3}
    function recvBuffer( var Buffer; len: size_t; flags: TZMQRecvFlags = [] ): Integer;
    {$endif}
    
    property SocketType: TZMQSocketType read getSocketType;
    property RcvMore: Boolean read getRcvMore;
    {$ifndef zmq3}
    property HWM: Int64 read getHWM write setHWM; // should be uInt64
    {$endif}
    property RcvTimeout: Integer read getRcvTimeout write setRcvTimeout;
    property SndTimeout: Integer read getSndTimeout write setSndTimeout;
    {$ifndef zmq3}
    property Swap: Int64 read getSwap write setSwap;
    {$endif}
    property Affinity: Int64 read getAffinity write setAffinity; // should be uInt64
    property Identity: ShortString read getIdentity write setIdentity;
    property Rate: int64 read getRate write setRate;
    property RecoveryIvl: Int64 read getRecoveryIvl write setRecoveryIvl;
    {$ifndef zmq3}
    property RecoveryIvlMSec: Int64 read getRecoveryIvlMSec write setRecoveryIvlMSec;
    property MCastLoop: Int64 read getMCastLoop write setMCastLoop;
    {$endif}
    property SndBuf: Int64 read getSndBuf write setSndBuf; // should be uInt64
    property RcvBuf: Int64 read getRcvBuf write setRcvBuf; // should be uInt64
    property Linger: Integer read getLinger write setLinger;
    property ReconnectIvl: Integer read getReconnectIvl write setReconnectIvl;
    property ReconnectIvlMax: Integer read getReconnectIvlMax write setReconnectIvlMax;
    property Backlog: Integer read getBacklog write setBacklog;
    property FD: Pointer read getFD;
    property Events: TZMQPollEvents read getEvents;

    property SocketPtr: Pointer read fSocket;
  end;

  TZMQContext = class
  private
    fContext: Pointer;
    fSockets: TList;
    cs: TRTLCriticalSection;
  private
    procedure RemoveSocket( lSocket: TZMQSocket );
  public
    constructor create{$ifndef zmq3}( io_threads: Integer = 1 ){$endif};
    destructor Destroy; override;

    {$ifdef zmq3}
    function get( option: Integer ): Integer;
    procedure _set( option, optval: Integer );
    //procedure set_monitor
    {$endif}

    function Socket( stype: TZMQSocketType ): TZMQSocket;
    property ContextPtr: Pointer read fContext;
  end;

type

  TZMQFree = zmq.free_fn;

  TZMQPollResult = record
    socket: TZMQSocket;
    revents: TZMQPollEvents;
  end;

  TZMQPollItem = zmq.pollitem_t;
  TZMQPollItemA = array of TZMQPollItem;

  TZMQPoller = class
  private
    fSockets: TList;
    fPollItems: TZMQPollItemA;
    fPollItemCount: Integer;
    function getPollResult(indx: Integer): TZMQPollResult;
  public
    constructor Create;
    destructor Destroy; override;

    procedure regist( socket: TZMQSocket; events: TZMQPollEvents );
    function poll( timeout: Longint = -1 ): Integer;

    property pollResult[indx: Integer]: TZMQPollResult read getPollResult;
  end;

  TZMQDevice = ( dStreamer, dForwarder, dQueue );

  procedure ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket );
  procedure ZMQVersion(var major, minor, patch: Integer);

implementation

const
  EAGAIN = 16;


{ EZMQException }

constructor EZMQException.Create;
begin
  errnum := zmq_errno;
  inherited Create( String( AnsiString( zmq_strerror( errnum ) ) ) );
end;

constructor EZMQException.Create( lerrn: Integer );
begin
  errnum := lerrn;
  inherited Create( String( AnsiString( zmq_strerror( errnum ) ) ) );
end;

{ TZMQMessage }

constructor TZMQMessage.Create;
begin
  if zmq_msg_init( fMessage ) <> 0 then
    raise EZMQException.Create;
end;

constructor TZMQMessage.Create( size: size_t );
begin
  if zmq_msg_init_size( fMessage, size ) <> 0 then
    raise EZMQException.Create;
end;

constructor TZMQMessage.Create( data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer );
begin
  if zmq_msg_init_data( fMessage, data, size, ffn, hint ) <> 0 then
    raise EZMQException.Create;
end;

destructor TZMQMessage.Destroy;
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise EZMQException.Create;
  inherited;
end;

procedure TZMQMessage.rebuild;
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise EZMQException.Create;
  if zmq_msg_init( fMessage ) <> 0 then
    raise EZMQException.Create;
end;

procedure TZMQMessage.rebuild( size: size_t );
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise EZMQException.Create;
  if zmq_msg_init_size( fMessage, size ) <> 0 then
    raise EZMQException.Create;
end;

procedure TZMQMessage.rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil );
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise EZMQException.Create;
  if zmq_msg_init_data( fMessage, data, size, ffn, hint ) <> 0 then
    raise EZMQException.Create;
end;

procedure TZMQMessage.move( msg: TZMQMessage );
begin
  if zmq_msg_move( fMessage, msg.fMessage ) <> 0 then
    raise EZMQException.Create;
end;

procedure TZMQMessage.copy( msg: TZMQMessage );
begin
  if zmq_msg_copy( fMessage, msg.fMessage ) <> 0 then
    Raise EZMQException.Create;
end;

function TZMQMessage.data: Pointer;
begin
  result := zmq_msg_data( fMessage );
end;

function TZMQMessage.size: size_t;
begin
 result := zmq_msg_size( fMessage );
end;

{ TZMQSocket }

destructor TZMQSocket.destroy;
begin
  close;
  fContext.RemoveSocket( Self );
  inherited;
end;

procedure TZMQSocket.close;
begin
  if SocketPtr = nil then
    exit;
  if zmq_close( SocketPtr ) <> 0 then
    raise EZMQException.Create;
  fSocket := nil;
end;

procedure TZMQSocket.CheckResult( rc: Integer );
var
  errn: Integer;
begin
  if rc = 0 then
  begin
  // ok
  end else
  if rc = -1 then
  begin
    errn := zmq_errno;
    case errn of
     ETERM: close;
    end;
    raise EZMQException.Create( errn );
  end else
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

procedure TZMQSocket.setSockOpt( option: Integer; optval: Pointer;
  optvallen: size_t );
begin
  CheckResult( zmq_setsockopt( SocketPtr, option, optval, optvallen ) );
end;

procedure TZMQSocket.getSockOpt( option: Integer; optval: Pointer; var optvallen: size_t );
begin
  CheckResult( zmq_getsockopt( SocketPtr, option, optval, optvallen ) );
end;

procedure TZMQSocket.bind( addr: String );
begin
  CheckResult( zmq_bind( SocketPtr, PAnsiChar( AnsiString( addr ) ) ) );
end;

procedure TZMQSocket.connect( addr: String );
begin
  CheckResult(  zmq_connect( SocketPtr, PAnsiChar( AnsiString( addr ) ) ) );
end;

{$ifdef zmq3}
procedure TZMQSocket.unbind( addr: String );
begin
  CheckResult( zmq_unbind( SocketPtr, PAnsiChar( AnsiString( addr ) ) ) );
end;

procedure TZMQSocket.disconnect( addr: String );
begin
  CheckResult( zmq_disconnect( SocketPtr, PAnsiChar( AnsiString( addr ) ) ) );
end;
{$endif}

function TZMQSocket.getSockOptInt64( option: Integer ): Int64;
var
  optvallen: Cardinal;
begin
  optvallen := SizeOf( result );
  getSockOpt( option, @result, optvallen );
end;

function TZMQSocket.getSockOptInteger( option: Integer ): Integer;
var
  optvallen: Cardinal;
begin
  optvallen := SizeOf( result );
  getSockOpt( option, @result, optvallen );
end;

procedure TZMQSocket.setSockOptInt64( option: Integer; const Value: Int64 );
var
  optvallen: Cardinal;
begin
  optvallen := SizeOf( Value );
  setSockOpt( option, @Value, optvallen );
end;

procedure TZMQSocket.setSockOptInteger( option: Integer; const Value: Integer );
var
  optvallen: Cardinal;
begin
  optvallen := SizeOf( Value );
  getSockOpt( option, @Value, optvallen );
end;

function TZMQSocket.getSocketType: TZMQSocketType;
var
  stype: Integer;
  optvallen: Cardinal;
begin
  optvallen := SizeOf( stype );
  getSockOpt( ZMQ_TYPE, @stype, optvallen );
  Result := TZMQSocketType( stype );
end;

function TZMQSocket.getRcvMore: Boolean;
var
  optvallen: Cardinal;
  i: Int64;
begin
  optvallen := SizeOf( i );
  getSockOpt( ZMQ_RCVMORE, @i, optvallen );
  result := i = 1;
end;

{$ifndef zmq3}
function TZMQSocket.getHWM: int64;
begin
  result := getSockOptInt64( ZMQ_HWM );
end;
{$endif}

function TZMQSocket.getRcvTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_RCVTIMEO );
end;

function TZMQSocket.getSndTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_SNDTIMEO );
end;

{$ifndef zmq3}
function TZMQSocket.getSwap: Int64;
begin
  result := getSockOptInt64( ZMQ_SWAP );
end;
{$endif}

function TZMQSocket.getAffinity: Int64; // should be uInt64
begin
  result := getSockOptInt64( ZMQ_AFFINITY );
end;

function TZMQSocket.getIdentity: ShortString;
var
  optvallen: Cardinal;
begin
  optvallen := 255;
  getSockOpt( ZMQ_IDENTITY, @result[1], optvallen );
  SetLength( result, optvallen );
end;

function TZMQSocket.getRate: int64;
begin
  result := getSockOptInt64( ZMQ_RATE );
end;

function TZMQSocket.getRecoveryIVL: Int64;
begin
  result := getSockOptInt64( ZMQ_RECOVERY_IVL );
end;

{$ifndef zmq3}
function TZMQSocket.getRecoveryIVLMSec: Int64;
begin
  result := getSockOptInt64( ZMQ_RECOVERY_IVL_MSEC );
end;

function TZMQSocket.getMCastLoop: Int64;
begin
  result := getSockOptInt64( ZMQ_MCAST_LOOP );
end;
{$endif}

function TZMQSocket.getSndBuf: Int64;
begin
  result := getSockOptInt64( ZMQ_SNDBUF );
end;

function TZMQSocket.getRcvBuf: Int64;
begin
  result := getSockOptInt64( ZMQ_RCVBUF );
end;

function TZMQSocket.getLinger: Integer;
begin
  result := getSockOptInteger( ZMQ_LINGER );
end;

function TZMQSocket.getReconnectIvl: Integer;
begin
  result := getSockOptInteger( ZMQ_RECONNECT_IVL );
end;

function TZMQSocket.getReconnectIvlMax: Integer;
begin
  result := getSockOptInteger( ZMQ_RECONNECT_IVL_MAX );
end;

function TZMQSocket.getBacklog: Integer;
begin
  result := getSockOptInteger( ZMQ_BACKLOG );
end;

function TZMQSocket.getFD: Pointer;
var
  optvallen: Cardinal;
begin
  // Not sure this works, haven't tested.
  optvallen := SizeOf( result );
  getSockOpt( ZMQ_FD, @result, optvallen );
end;

function TZMQSocket.getEvents: TZMQPollEvents;
var
  optvallen: Cardinal;
  i: Cardinal;
begin
  optvallen := SizeOf( i );
  getSockOpt( ZMQ_EVENTS, @i, optvallen );
  Result := TZMQPollEvents( Byte(i) );
end;

{$ifndef zmq3}
procedure TZMQSocket.setHWM( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_HWM, Value );
end;

procedure TZMQSocket.setSwap( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_SWAP, Value );
end;
{$endif}

procedure TZMQSocket.setAffinity( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_AFFINITY, Value );
end;

procedure TZMQSocket.setIdentity( const Value: ShortString );
begin
  setSockOpt( ZMQ_IDENTITY, @Value[1], Length( Value ) );
end;

procedure TZMQSocket.setRcvTimeout( const Value: Integer );
begin
  setSockOptInteger( ZMQ_RCVTIMEO, Value );
end;

procedure TZMQSocket.setSndTimeout( const Value: Integer );
begin
  setSockOptInteger( ZMQ_SNDTIMEO, Value );
end;

procedure TZMQSocket.setRate( const Value: int64 );
begin
  setSockOptInt64( ZMQ_RATE, Value );
end;

procedure TZMQSocket.setRecoveryIvl( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_RECOVERY_IVL, Value );
end;

{$ifndef zmq3}
procedure TZMQSocket.setRecoveryIvlMSec( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_RECOVERY_IVL_MSEC, Value );
end;

procedure TZMQSocket.setMCastLoop( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_MCAST_LOOP, Value );
end;
{$endif}

procedure TZMQSocket.setSndBuf( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_SNDBUF, Value );
end;

procedure TZMQSocket.setRcvBuf( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_RCVBUF, Value );
end;

procedure TZMQSocket.setLinger( const Value: Integer );
begin
  setSockOptInteger( ZMQ_LINGER, Value );
end;

procedure TZMQSocket.setReconnectIvl( const Value: Integer );
begin
  setSockOptInteger( ZMQ_RECONNECT_IVL, Value );
end;

procedure TZMQSocket.setReconnectIvlMax( const Value: Integer );
begin
  setSockOptInteger( ZMQ_RECONNECT_IVL_MAX, Value );
end;

procedure TZMQSocket.setBacklog( const Value: Integer );
begin
  setSockOptInteger( ZMQ_BACKLOG, Value );
end;

procedure TZMQSocket.subscribe( filter: String );
var
  sFilter: AnsiString;
begin
  sFilter := AnsiString( filter );
  if sfilter = '' then
    setSockOpt( ZMQ_SUBSCRIBE, nil, 0 )
  else
    setSockOpt( ZMQ_SUBSCRIBE, @sfilter[1], Length( sfilter ) );
end;

procedure TZMQSocket.unSubscribe( filter: String );
var
  sFilter: AnsiString;
begin
  sFilter := AnsiString( filter );
  if sfilter = '' then
    setSockOpt( ZMQ_UNSUBSCRIBE, nil, 0 )
  else
    setSockOpt( ZMQ_UNSUBSCRIBE, @sfilter[1], Length( sfilter ) );
end;

{$ifdef zmq3}
function TZMQSocket.sendBuffer( const Buffer; len: Size_t; flags: TZMQSendFlags = [] ): Integer;
begin
  result := zmq_send( SocketPtr, Buffer, len, Byte( flags ) );
  if result < -1 then
    raise EZMQException.Create('zmq_send return value less than -1.')
  else if result = -1 then
  begin
    if zmq_errno = ETERM then
      close;
    raise EZMQException.Create;
  end;
end;
{$endif}

function TZMQSocket.send( msg: TZMQMessage; flags: Integer = 0 ): Integer;
begin
  {$ifdef zmq3}
  result := zmq_sendmsg( SocketPtr, msg.fMessage, flags );

  if result < -1 then
    raise EZMQException.Create('zmq_sendmsg return value less than -1.')
  else if result = -1 then
  begin
    if zmq_errno = ETERM then
      close;
    raise EZMQException.Create;
  end else
  begin
    {$ifdef debug}
    if result <> msg.size then
      raise EZMQException.Create('return value of zmq_sendmsg and msg size is not equal.');
    {$endif}
  end;

  {$else}
  CheckResult( zmq_send( SocketPtr, msg.fMessage, flags ) );
  result := msg.size;
  {$endif}
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocket.send( msg: TZMQMessage; flags: TZMQSendFlags = [] ): Integer;
begin
  result := send( msg, Byte( flags ) );
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocket.send( strm: TStream; size: Integer; flags: TZMQSendFlags = [] ): Integer;
var
  zmqMsg: TZMQMessage;
begin
  zmqMsg := TZMQMessage.Create( size );
  try
    strm.Read( zmqMsg.data^, size );
    result := send( zmqMsg, flags );
  finally
    zmqMsg.Free;
  end;
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocket.send( msg: String; flags: TZMQSendFlags = [] ): Integer;
var
  sStrm: TStringStream;
begin
  sStrm := TStringStream.Create( msg );
  try
    result := send( sStrm, sStrm.Size, flags );
  finally
    sStrm.Free;
  end;
end;

// send multipart message in blocking or nonblocking mode, depending on the
// dontwait parameter. The return value is the nmber of messages sent.
function TZMQSocket.send( msg: Array of String; dontwait: Boolean = false ): Integer;
var
  flags: TZMQSendFlags;
begin
  Result := 0;
  if dontwait then
    flags := [{$ifdef zmq3}sfDontWait{$else}sfNoBlock{$endif}]
  else
    flags := [];
  while result < Length( msg ) do
  begin
    if result = Length( msg ) - 1 then
      send( msg[result], flags )
    else
      send( msg[result], flags + [sfSndMore] );
    inc( result );
  end;
end;

// send multipart message in blocking or nonblocking mode, depending on the
// dontwait parameter. The return value is the nmber of messages sent.
function TZMQSocket.send( msg: TStrings; dontwait: Boolean = false ): Integer;
var
  flags: TZMQSendFlags;
begin
  result := 0;
  if dontwait then
    flags := [{$ifdef zmq3}sfDontWait{$else}sfNoBlock{$endif}]
  else
    flags := [];
  while result < msg.Count do
  begin
    if result = msg.Count - 1 then
      send( msg[result], flags )
    else
      send( msg[result], flags + [sfSndMore] );
    inc( result );
  end;
end;

{$ifdef zmq3}
function TZMQSocket.recvBuffer( var Buffer; len: size_t; flags: TZMQRecvFlags = [] ): Integer;
begin
  result := zmq_recv( SocketPtr, Buffer, len, Byte( flags ) );
  if result < -1 then
    raise EZMQException.Create('zmq_recv return value less than -1.')
  else if result = -1 then
  begin
    if zmq_errno = ETERM then
      close;
    raise EZMQException.Create;
  end;
end;
{$endif}

function TZMQSocket.recv( msg: TZMQMessage; flags: Integer = 0 ): Integer;
begin
  {$ifdef zmq3}
  result := zmq_recvmsg( SocketPtr, msg.fMessage, flags );
  if result < -1 then
    raise EZMQException.Create('zmq_recvmsg return value less than -1.')
  else if result = -1 then
  begin
    if zmq_errno = ETERM then
      close;
    raise EZMQException.Create;
  end else
  begin
    {$ifdef debug}
    if result <> msg.size then
      raise EZMQException.Create('return value of zmq_recvmsg and msg size is not equal.');
    {$endif}
  end;
  {$else}
  CheckResult( zmq_recv( SocketPtr, msg.fMessage, flags ) );
  result := msg.size;
  {$endif}
end;

function TZMQSocket.recv( msg: TZMQMessage; flags: TZMQRecvFlags = [] ): Integer;
begin
  result := recv( msg, Byte( flags ) );
end;

function TZMQSocket.recv( strm: TStream; var size: Integer; flags: TZMQRecvFlags = [] ): Integer;
var
  zmqmsg: TZMQMessage;
begin
  zmqmsg := TZMQMessage.Create;
  try
    result := recv( zmqmsg, flags );
    size := zmqmsg.size;
    strm.Write( zmqmsg.data^, size );
  finally
    zmqmsg.Free;
  end;
end;

function TZMQSocket.recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer;
var
  size: Integer;
begin
  result := recv( strm, size, flags );
end;

function TZMQSocket.recv( var msg: String; flags: TZMQRecvFlags = [] ): Integer;
var
  sStrm: TStringStream;
  size: Integer;
begin
  sStrm := TStringStream.Create('');
  try
    Result := recv( sStrm, size, flags );
    sStrm.Position := 0;
    msg := sStrm.ReadString( size );
  finally
    sStrm.Free;
  end;
end;

// receive multipart message. the result is the number of messages received.
function TZMQSocket.recv( msg: TStrings; flags: TZMQRecvFlags = [] ): Integer;
var
  s: String;
  bRcvMore: Boolean;
begin
  bRcvMore := True;
  result := 0;
  while bRcvMore do
  begin
    recv( s, flags );
    msg.Add( s );
    inc( result );
    bRcvMore := RcvMore;
  end;
end;

{ TZMQContext }

constructor TZMQContext.create{$ifndef zmq3}( io_threads: Integer ){$endif};
begin
  {$ifdef zmq3}
  fContext := zmq_ctx_new;
  {$else}
  fContext := zmq_init( io_threads );
  {$endif}
  if fContext = nil then
    raise EZMQException.Create;
  InitializeCriticalSection( cs );
  fSockets := TList.Create;
end;

destructor TZMQContext.destroy;
begin
  {$ifdef zmq3}
  if zmq_ctx_destroy( fContext ) <> 0 then
  {$else}
  if zmq_term( fContext ) <> 0 then
  {$endif}
    raise EZMQException.Create;

  while fSockets.Count > 0 do
    TZMQSocket(fSockets[0]).Free;

  DeleteCriticalSection( cs );
  inherited;
end;

{$ifdef zmq3}
function TZMQContext.get( option: Integer ): Integer;
begin
  result := zmq_ctx_get( fContext, option );
  if result < 0 then
    raise EZMQException.Create;
end;

procedure TZMQContext._set( option, optval: Integer );
begin
  if zmq_ctx_set( fContext, option, optval ) <> 0 then
    raise EZMQException.Create;
end;
{$endif}

function TZMQContext.Socket( stype: TZMQSocketType ): TZMQSocket;
begin
  EnterCriticalSection( cs );
  try
    result := TZMQSocket.Create;
    result.fSocket := zmq_socket( ContextPtr, Byte( stype ) );
    if result.fSocket = nil then
    begin
      result.Free;
      result := nil;
      raise EZMQException.Create;
    end;
    result.fContext := self;
    fSockets.Add( result );
  finally
    LeaveCriticalSection( cs );
  end;
end;

procedure TZMQContext.RemoveSocket( lSocket: TZMQSocket );
var
  i: Integer;
begin
  EnterCriticalSection( cs );
  try
    i := fSockets.IndexOf( lSocket );
    if i < 0 then
      raise EZMQException.Create( 'Socket not in context' );
    fSockets.Delete( i );
  finally
    LeaveCriticalSection( cs );
  end;
end;

{ TZMQPoll }
const
  fPollItemArrayInc = 10;

constructor TZMQPoller.Create;
begin
  fPollItemCount := 0;
  fSockets := TList.Create;
end;

destructor TZMQPoller.Destroy;
begin
  fPollItems := nil;
  fSockets.Free;
  inherited;
end;

procedure TZMQPoller.regist( socket: TZMQSocket; events: TZMQPollEvents );
begin
  if fPollItemCount = Length( fPollItems ) then
    SetLength( fPollItems, fPollItemCount + fPollItemArrayInc );
  fPollItems[fPollItemCount].socket := socket.SocketPtr;
  fPollItems[fPollItemCount].fd := 0;
  fPollItems[fPollItemCount].events := Byte( events );
  fPollItems[fPollItemCount].revents := 0;
  Inc( fPollItemCount );
  fSockets.Add( socket );
end;

function TZMQPoller.poll( timeout: Integer = -1 ): Integer;
begin
  if fPollItemCount = 0 then
    raise EZMQException.Create( 'Nothing to poll!' );
  result := zmq_poll( fPollItems[0], fPollItemCount, timeout );
  if result < 0 then
    raise EZMQException.Create
end;

function TZMQPoller.getPollResult( indx: Integer ): TZMQPollResult;
var
  i,j: Integer;
begin
  i := 0;
  j := -1;
  while ( i < fPollItemCount) and ( j < indx ) do
  begin
    if ( fPollItems[i].revents and fPollItems[i].events ) > 0 then
      inc( j );
    if j < indx then
      inc( i );
  end;
  result.socket := fSockets[i];
  result.revents := TZMQPollEvents( Byte( fPollItems[i].revents ) );
end;

procedure ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket );
begin
  if zmq_device( Ord( device ), insocket.SocketPtr, outsocket.SocketPtr ) <> -1 then
    raise EZMQException.Create( 'Device does not return -1' );
end;

procedure ZMQVersion(var major, minor, patch: Integer);
begin
  zmq_version( major, minor, patch );
end;

end.
