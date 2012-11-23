{
    Copyright (c) 2012 Varga Bal�zs (bb.varga@gmail.com)

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

{$ifdef FPC}
  {$mode delphi}{$H+}
{$endif}

{$I zmq.inc}

interface

uses
   {$ifdef UNIX}
   BaseUnix,
   {$else}
   Windows,
   {$endif}
   Classes
  , SysUtils
  , zmq
  ;


const
  ZMQEAGAIN = 11;
  {$ifdef UNIX}
  ZMQEINTR = ESysEINTR;
  {$endif}

type
  {$ifdef zmq3}
  TZMQMonitorEvent = (
    meConnected,
    meConnectDelayed,
    meConnectRetried,
    meListening,
    meBindFailed,
    meAccepted,
    meAcceptFailed,
    meClosed,
    meCloseFailed,
    meDisconnected
  );
  TZMQMonitorEvents = set of TZMQMonitorEvent;


const

  cZMQMonitorEventsAll = [ meConnected,
    meConnectDelayed,
    meConnectRetried,
    meListening,
    meBindFailed,
    meAccepted,
    meAcceptFailed,
    meClosed,
    meCloseFailed,
    meDisconnected
  ];
type
  {$endif}

  UInt64 = Int64;

  EZMQException = class( Exception )
  private
    errnum: Integer;
  public
    constructor Create; overload;
    constructor Create( lerrn: Integer ); overload;
    property Num: Integer read errnum;
  end;

  TZMQContext = class;
  TZMQSocket = class;

  TZMQSendFlag = ( {$ifdef zmq3}sfDontWait{$else}sfNoBlock{$endif}, sfSndMore );
  TZMQSendFlags = set of TZMQSendFlag;

  TZMQRecvFlag = ( {$ifdef zmq3}rfDontWait{$else}rfNoBlock{$endif} );
  TZMQRecvFlags = set of TZMQRecvFlag;

  TZMQMessageProperty = ( mpMore );

  TZMQMessage = class
  private
    fMessage: zmq_msg_t;
    procedure CheckResult( rc: Integer );
    {$ifdef zmq3}
    function getProperty( prop: TZMQMessageProperty ): Integer;
    procedure setProperty( prop: TZMQMessageProperty; value: Integer );
    {$endif}
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
    {$ifdef zmq3}
    function more: Boolean;
    function send( socket: TZMQSocket; flags: TZMQSendFlags = [] ): Integer;
    function recv( socket: TZMQSocket; flags: TZMQRecvFlags = [] ): Integer;
    {$endif}
  end;


  TZMQSocketType = ( stPair, stPub, stSub, stReq, stRep, stDealer,
    stRouter, stPull, stPush, stXPub, stXSub );


  TZMQPollEvent = ( pePollIn, pePollOut, pePollErr );
  TZMQPollEvents = set of TZMQPollEvent;

  {$ifdef zmq3}
  TZMQKeepAlive = ( kaDefault, kaFalse, kaTrue );

  TZMQEvent = record
    event: TZMQMonitorEvent;
    addr: String;
    case TZMQMonitorEvent of
      meConnected,
      meListening,
      meAccepted,
      meClosed,
      meDisconnected:
        (
        fd: Integer;
        );
      meConnectDelayed,
      meBindFailed,
      meAcceptFailed,
      meCloseFailed:
       (
        err: Integer;
        );
      meConnectRetried: ( //connect_retried
        interval: Integer;
        );

  end;

  TZMQMonitorProc = procedure( event: TZMQEvent ) of object;

  PZMQMonitorRec = ^TZMQMonitorRec;
  TZMQMonitorRec = record
    terminated: Boolean;
    context: TZMQContext;
    addr: String;
    proc: TZMQMonitorProc;
  end;

  {$endif}

  TZMQSocket = class
  // low level
  protected
    fSocket: Pointer;
    fContext: TZMQContext;
    {$ifdef FPC}
    fThreadId: TThreadID;
    {$else}
    fThreadId: Cardinal;
    {$endif}
  private
    fRaiseEAgain: Boolean;
    {$ifdef zmq3}
    fAcceptFilter: TStringList;

    fMonitorRec: PZMQMonitorRec;
    fMonitorThread: THandle;
    {$endif}
    function getTerminated: Boolean;
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
    constructor Create;
    destructor Destroy; override;

    function getSocketType: TZMQSocketType;
    function getrcvMore: Boolean;
    function getRcvTimeout: Integer;
    function getSndTimeout: Integer;
    function getAffinity: UInt64;
    function getIdentity: ShortString;
    function getRate: {$ifdef zmq3}Integer{$else}int64{$endif};
    function getRecoveryIvl: {$ifdef zmq3}Integer{$else}int64{$endif};
    function getSndBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif};
    function getRcvBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif};
    function getLinger: Integer;
    function getReconnectIvl: Integer;
    function getReconnectIvlMax: Integer;
    function getBacklog: Integer;
    function getFD: Pointer;
    function getEvents: TZMQPollEvents;
    function getHWM: {$ifdef zmq3}Integer{$else}UInt64{$endif};

    {$ifdef zmq3}
    function getSndHWM: Integer;
    function getRcvHWM: Integer;
    procedure setSndHWM( const Value: Integer );
    procedure setRcvHWM( const Value: Integer );
    procedure setMaxMsgSize( const Value: Int64 );
    function getMaxMsgSize: Int64;
    function getMulticastHops: Integer;
    procedure setMulticastHops( const Value: Integer );
    function getIPv4Only: Boolean;
    procedure setIPv4Only( const Value: Boolean );
    function getLastEndpoint: String;
    function getKeepAlive: TZMQKeepAlive;
    procedure setKeepAlive( const Value: TZMQKeepAlive );
    function getKeepAliveIdle: Integer;
    procedure setKeepAliveIdle( const Value: Integer );
    function getKeepAliveCnt: Integer;
    procedure setKeepAliveCnt( const Value: Integer );
    function getKeepAliveIntvl: Integer;
    procedure setKeepAliveIntvl( const Value: Integer );
    function getAcceptFilter( indx: Integer ): String;
    procedure setAcceptFilter( indx: Integer; const Value: String );
    {$else}
    function getSwap: Int64;
    function getRecoveryIvlMSec: Int64;
    function getMCastLoop: Int64;
    procedure setSwap( const Value: Int64 );
    procedure setRecoveryIvlMSec( const Value: Int64 );
    procedure setMCastLoop( const Value: Int64 );
    {$endif}

    procedure setHWM( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
    procedure setRcvTimeout( const Value: Integer );
    procedure setSndTimeout( const Value: Integer );
    procedure setAffinity( const Value: UInt64 );
    procedure setIdentity( const Value: ShortString );
    procedure setRate( const Value: {$ifdef zmq3}Integer{$else}int64{$endif} );
    procedure setRecoveryIvl( const Value: {$ifdef zmq3}Integer{$else}int64{$endif} );
    procedure setSndBuf( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
    procedure setRcvBuf( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
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
    function recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( var msg: String; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( msg: TStrings; flags: TZMQRecvFlags = [] ): Integer; overload;

    {$ifdef zmq3}
    function recvBuffer( var Buffer; len: size_t; flags: TZMQRecvFlags = [] ): Integer;
    procedure RegisterMonitor( proc: TZMQMonitorProc; events: TZMQMonitorEvents = cZMQMonitorEventsAll );
    procedure DeRegisterMonitor;

    {$endif}

    {$ifndef UNIX}
    // helpers. inspired by the zhelpers.h
    procedure dump;
    {$endif}

    property SocketType: TZMQSocketType read getSocketType;
    property RcvMore: Boolean read getRcvMore;

    {$ifdef zmq3}
    property SndHWM: Integer read getSndHWM write setSndHwm;
    property RcvHWM: Integer read getRcvHWM write setRcvHwm;
    property MaxMsgSize: Int64 read getMaxMsgSize write setMaxMsgSize;
    property MulticastHops: Integer read getMulticastHops write setMulticastHops;
    property IPv4Only: Boolean read getIPv4Only write setIPv4Only;
    property LastEndpoint: String read getLastEndpoint;
    property KeepAlive: TZMQKeepAlive read getKeepAlive write setKeepAlive;
    property KeepAliveIdle: Integer read getKeepAliveIdle write setKeepAliveIdle;
    property KeepAliveCnt: Integer read getKeepAliveCnt write setKeepAliveCnt;
    property KeepAliveIntvl: Integer read getKeepAliveIntvl write setKeepAliveIntvl;

    procedure AddAcceptFilter( addr: String );
    property AcceptFilter[indx: Integer]: String read getAcceptFilter write setAcceptFilter;
    {$else}
    property Swap: Int64 read getSwap write setSwap;
    property RecoveryIvlMSec: Int64 read getRecoveryIvlMSec write setRecoveryIvlMSec;
    property MCastLoop: Int64 read getMCastLoop write setMCastLoop;
    {$endif}

    property HWM: {$ifdef zmq3}Integer{$else}UInt64{$endif} read getHWM write setHWM;
    property RcvTimeout: Integer read getRcvTimeout write setRcvTimeout;
    property SndTimeout: Integer read getSndTimeout write setSndTimeout;
    property Affinity: UInt64 read getAffinity write setAffinity;
    property Identity: ShortString read getIdentity write setIdentity;
    property Rate: {$ifdef zmq3}Integer{$else}int64{$endif} read getRate write setRate;
    property RecoveryIvl: {$ifdef zmq3}Integer{$else}int64{$endif} read getRecoveryIvl write setRecoveryIvl;
    property SndBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif} read getSndBuf write setSndBuf;
    property RcvBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif} read getRcvBuf write setRcvBuf;
    property Linger: Integer read getLinger write setLinger;
    property ReconnectIvl: Integer read getReconnectIvl write setReconnectIvl;
    property ReconnectIvlMax: Integer read getReconnectIvlMax write setReconnectIvlMax;
    property Backlog: Integer read getBacklog write setBacklog;
    property FD: Pointer read getFD;
    property Events: TZMQPollEvents read getEvents;

    property SocketPtr: Pointer read fSocket;
    property Terminated: Boolean read getTerminated;
    property RaiseEAgain: Boolean read fRaiseEAgain write fRaiseEAgain;
  end;

  TZMQContext = class
  private
    fContext: Pointer;
    fSockets: TList;
    fLinger: Integer;
    {$ifdef FPC}
    fThreadId: TThreadID;
    {$else}
    fThreadId: Cardinal;
    {$endif}

    {$ifdef zmq3}
    function getOption( option: Integer ): Integer;
    procedure setOption( option, optval: Integer );
    function getIOThreads: Integer;
    procedure setIOThreads( const Value: Integer );
    function getMaxSockets: Integer;
    procedure setMaxSockets( const Value: Integer );
    {$endif}
  protected
    fInterrupted: Boolean;
    procedure CheckResult( rc: Integer );
    procedure RemoveSocket( lSocket: TZMQSocket );

  public
    constructor create{$ifndef zmq3}( io_threads: Integer = 1 ){$endif};
    destructor Destroy; override;
    function Socket( stype: TZMQSocketType ): TZMQSocket;
    property ContextPtr: Pointer read fContext;
    //  < -1 means dont change linger when destroy
    property Linger: Integer read fLinger write fLinger;
    property Interrupted: Boolean read fInterrupted;
    {$ifdef zmq3}
    property IOThreads: Integer read getIOThreads write setIOThreads;
    property MaxSockets: Integer read getMaxSockets write setMaxSockets;
    {$endif}

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
    function poll( timeout: Longint = -1; pollCount: Integer = -1 ): Integer;

    property pollResult[indx: Integer]: TZMQPollResult read getPollResult;
  end;

  TZMQDevice = ( dStreamer, dForwarder, dQueue );

  procedure ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket );
  procedure ZMQVersion(var major, minor, patch: Integer);

  // for threadSafe logging to the console.
  procedure ZMQNote( str: String );

implementation

var
  contexts: TList;
  cs: TRTLCriticalSection;

procedure ZMQNote( str: String );
begin
  EnterCriticalSection( cs );
  Writeln( str );
  LeaveCriticalSection( cs );
end;

{$ifndef UNIX}
function console_handler( dwCtrlType: DWORD ): BOOL; stdcall; forward;
{$endif}

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
  CheckResult( zmq_msg_init( fMessage ) );
end;

constructor TZMQMessage.Create( size: size_t );
begin
  CheckResult( zmq_msg_init_size( fMessage, size ) );
end;

constructor TZMQMessage.Create( data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer );
begin
  CheckResult( zmq_msg_init_data( fMessage, data, size, ffn, hint ) );
end;

destructor TZMQMessage.Destroy;
begin
  CheckResult( zmq_msg_close( fMessage ) );
  inherited;
end;

procedure TZMQMessage.CheckResult( rc: Integer );
begin
  if rc = 0 then
  begin
  // ok
  end else
  if rc = -1 then
  begin
    raise EZMQException.Create;
  end else
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

procedure TZMQMessage.rebuild;
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init( fMessage ) );
end;

procedure TZMQMessage.rebuild( size: size_t );
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init_size( fMessage, size ) );
end;

procedure TZMQMessage.rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil );
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init_data( fMessage, data, size, ffn, hint ) );
end;

procedure TZMQMessage.move( msg: TZMQMessage );
begin
  CheckResult( zmq_msg_move( fMessage, msg.fMessage ) );
end;

procedure TZMQMessage.copy( msg: TZMQMessage );
begin
  CheckResult( zmq_msg_copy( fMessage, msg.fMessage ) );
end;

function TZMQMessage.data: Pointer;
begin
  result := zmq_msg_data( fMessage );
end;

function TZMQMessage.size: size_t;
begin
 result := zmq_msg_size( fMessage );
end;

{$ifdef zmq3}
function TZMQMessage.getProperty( prop: TZMQMessageProperty ): Integer;
begin
  result := zmq_msg_get( fMessage, Byte( prop ) );
  if result = -1 then
    raise EZMQException.Create
  else
    raise EZMQException.Create( 'zmq_msg_more return value undefined!' );
end;

procedure TZMQMessage.setProperty( prop: TZMQMessageProperty; value: Integer );
begin
  CheckResult( zmq_msg_set( fMessage, Byte( prop ), value ) );
end;

function TZMQMessage.more: Boolean;
var
  rc: Integer;
begin
  rc := zmq_msg_more( fMessage );
  if rc = 0 then
    result := false else
  if rc = 1 then
    result := true else
    raise EZMQException.Create( 'zmq_msg_more return value undefined!' );
end;

function TZMQMessage.send( socket: TZMQSocket; flags: TZMQSendFlags = [] ): Integer;
//var
//  lsize: integer;
begin
  result := socket.send( Self, flags );
  //lsize := size;
  //result := zmq_msg_send( fMessage, socket.SocketPtr, Byte( flags ) );
  //
  //if result < -1 then
  //  raise EZMQException.Create('zmq_msg_send return value less than -1.')
  //else if result = -1 then
  //begin
  //  if zmq_errno = ETERM then
  //    socket.close;
  //  raise EZMQException.Create;
  //end else
  //begin
  //  {$ifdef debug}
  //  //cannot call size after calling zmq_msg_send because zmq_msg_t structure (fMessage) is nullified during the call
  //  //if result <> size then
  //  if result <> lsize then
  //    raise EZMQException.Create('return value of zmq_msg_send and msg size is not equal.');
  //  {$endif}
  //end;
end;

function TZMQMessage.recv( socket: TZMQSocket; flags: TZMQRecvFlags = [] ): Integer;
begin
  rebuild;
  result := socket.recv( Self, flags );
  //{ TODO zmq_msg_recv is deprecated }
  //result := zmq_msg_recv( fMessage, socket.SocketPtr, Byte( flags ) );
  //if result < -1 then
  //  raise EZMQException.Create('zmq_recvmsg return value less than -1.')
  //else if result = -1 then
  //begin
  //  if (zmq_errno = ETERM){$ifdef UNIX} or (zmq_errno = ESysEINTR){$endif} then
  //    socket.close;
  //  { TODO Do we need to handle ZMQEAGAIN ? }
  //  raise EZMQException.Create;
  //end else
  //begin
  //  {$ifdef debug}
  //  if result <> size then
  //    raise EZMQException.Create('return value of zmq_msg_recv and msg size is not equal.');
  //  {$endif}
  //end;
end;
{$endif}

{ TZMQSocket }

constructor TZMQSocket.Create;
begin
  {$ifdef FPC}
  fThreadId := GetCurrentThreadId;
  {$else}
  fThreadId := Windows.GetCurrentThreadId;
  {$endif}
  fRaiseEAgain := False;
  {$ifdef zmq3}
  fAcceptFilter := TStringList.Create;
  fMonitorRec := nil;
  {$endif}
end;

destructor TZMQSocket.destroy;
begin
  {$ifdef zmq3}
  if fMonitorRec <> nil then
    DeRegisterMonitor;
  {$endif}
  close;
  fContext.RemoveSocket( Self );
  {$ifdef zmq3}
  fAcceptFilter.Free;
  {$endif}
  inherited;
end;

procedure TZMQSocket.close;
begin
  if SocketPtr = nil then
    exit;
  CheckResult( zmq_close( SocketPtr ) );
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
  optvallen: size_t;
begin
  optvallen := SizeOf( result );
  getSockOpt( option, @result, optvallen );
end;

function TZMQSocket.getSockOptInteger( option: Integer ): Integer;
var
  optvallen: size_t;
begin
  optvallen := SizeOf( result );
  getSockOpt( option, @result, optvallen );
end;

procedure TZMQSocket.setSockOptInt64( option: Integer; const Value: Int64 );
var
  optvallen: size_t;
begin
  optvallen := SizeOf( Value );
  setSockOpt( option, @Value, optvallen );
end;

procedure TZMQSocket.setSockOptInteger( option: Integer; const Value: Integer );
var
  optvallen: size_t;
begin
  optvallen := SizeOf( Value );
  setSockOpt( option, @Value, optvallen );
end;

function TZMQSocket.getSocketType: TZMQSocketType;
begin
  Result := TZMQSocketType( getSockOptInteger( ZMQ_TYPE ) );
end;

function TZMQSocket.getRcvMore: Boolean;
begin
  {$ifdef zmq3}
  result := getSockOptInteger( ZMQ_RCVMORE ) = 1;
  {$else}
  result := getSockOptInt64( ZMQ_RCVMORE ) = 1;
  {$endif}
end;

function TZMQSocket.getRcvTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_RCVTIMEO );
end;

function TZMQSocket.getSndTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_SNDTIMEO );
end;

function TZMQSocket.getAffinity: UInt64;
begin
  result := getSockOptInt64( ZMQ_AFFINITY );
end;

function TZMQSocket.getIdentity: ShortString;
var
  s: ShortString;
  optvallen: size_t;
begin
  optvallen := 255;
  getSockOpt( ZMQ_IDENTITY, @s[1], optvallen );
  SetLength( s, optvallen );
  result := s;
end;

function TZMQSocket.getRate: {$ifdef zmq3}Integer{$else}int64{$endif};
begin
  {$ifdef zmq3}
  result := getSockOptInteger( ZMQ_RATE );
  {$else}
  result := getSockOptInt64( ZMQ_RATE );
  {$endif}
end;

function TZMQSocket.getRecoveryIVL: {$ifdef zmq3}Integer{$else}int64{$endif};
begin
  {$ifdef zmq3}
  result := getSockOptInteger( ZMQ_RECOVERY_IVL );
  {$else}
  result := getSockOptInt64( ZMQ_RECOVERY_IVL );
  {$endif}
end;

function TZMQSocket.getSndBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif};
begin
  {$ifdef zmq3}
  result := getSockOptInteger( ZMQ_SNDBUF );
  {$else}
  result := getSockOptInt64( ZMQ_SNDBUF );
  {$endif}
end;

function TZMQSocket.getRcvBuf: {$ifdef zmq3}Integer{$else}UInt64{$endif};
begin
  {$ifdef zmq3}
  result := getSockOptInteger( ZMQ_RCVBUF );
  {$else}
  result := getSockOptInt64( ZMQ_RCVBUF );
  {$endif}
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
  optvallen: size_t;
begin
  // Not sure this works, haven't tested.
  optvallen := SizeOf( result );
  getSockOpt( ZMQ_FD, @result, optvallen );
end;

function TZMQSocket.getEvents: TZMQPollEvents;
var
  optvallen: size_t;
  i: Cardinal;
begin
  optvallen := SizeOf( i );
  getSockOpt( ZMQ_EVENTS, @i, optvallen );
  Result := TZMQPollEvents( Byte(i) );
end;

function TZMQSocket.getHWM: {$ifdef zmq3}Integer{$else}UInt64{$endif};
begin
  {$ifdef zmq3}
  result := RcvHWM;
  // warning deprecated.
  {$else}
  result := getSockOptInt64( ZMQ_HWM );
  {$endif}
end;

{$ifdef zmq3}
function TZMQSocket.getSndHWM: Integer;
begin
  result := getSockOptInteger( ZMQ_SNDHWM );
end;

function TZMQSocket.getRcvHWM: Integer;
begin
  result := getSockOptInteger( ZMQ_RCVHWM );
end;

procedure TZMQSocket.setSndHWM( const Value: Integer );
begin
  setSockOptInteger( ZMQ_SNDHWM, Value );
end;

procedure TZMQSocket.setRcvHWM( const Value: Integer );
begin
  setSockOptInteger( ZMQ_RCVHWM, Value );
end;

procedure TZMQSocket.setMaxMsgSize( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_MAXMSGSIZE, Value );
end;

function TZMQSocket.getMaxMsgSize: Int64;
begin
  result := getSockOptInt64( ZMQ_MAXMSGSIZE );
end;

function TZMQSocket.getMulticastHops: Integer;
begin
  result := getSockOptInteger( ZMQ_MULTICAST_HOPS );
end;

procedure TZMQSocket.setMulticastHops( const Value: Integer );
begin
  setSockOptInteger( ZMQ_MULTICAST_HOPS, Value );
end;

function TZMQSocket.getIPv4Only: Boolean;
begin
  result := getSockOptInteger( ZMQ_IPV4ONLY ) <> 0;
end;

procedure TZMQSocket.setIPv4Only( const Value: Boolean );
begin
  setSockOptInteger( ZMQ_IPV4ONLY, Integer(Value) );
end;

function TZMQSocket.getLastEndpoint: String;
var
  s: ShortString;
  optvallen: size_t;
begin
  optvallen := 255;
  getSockOpt( ZMQ_LAST_ENDPOINT, @s[1], optvallen );
  SetLength( s, optvallen - 1);
  result := s;
end;

function TZMQSocket.getKeepAlive: TZMQKeepAlive;
begin
  result := TZMQKeepAlive( getSockOptInteger( ZMQ_TCP_KEEPALIVE ) + 1 );
end;

procedure TZMQSocket.setKeepAlive( const Value: TZMQKeepAlive );
begin
  setSockOptInteger( ZMQ_TCP_KEEPALIVE, Byte(Value) - 1 );
end;

function TZMQSocket.getKeepAliveIdle: Integer;
begin
  result := getSockOptInteger( ZMQ_TCP_KEEPALIVE_IDLE );
end;

procedure TZMQSocket.setKeepAliveIdle( const Value: Integer );
begin
  setSockOptInteger( ZMQ_TCP_KEEPALIVE_IDLE, Value );
end;

function TZMQSocket.getKeepAliveCnt: Integer;
begin
  result := getSockOptInteger( ZMQ_TCP_KEEPALIVE_CNT );
end;

procedure TZMQSocket.setKeepAliveCnt( const Value: Integer );
begin
  setSockOptInteger( ZMQ_TCP_KEEPALIVE_CNT, Value );
end;

function TZMQSocket.getKeepAliveIntvl: Integer;
begin
  result := getSockOptInteger( ZMQ_TCP_KEEPALIVE_INTVL );
end;

procedure TZMQSocket.setKeepAliveIntvl( const Value: Integer );
begin
  setSockOptInteger( ZMQ_TCP_KEEPALIVE_INTVL, Value );
end;

procedure TZMQSocket.AddAcceptFilter( addr: String );
begin
  try
    setSockOpt( ZMQ_TCP_ACCEPT_FILTER, @addr[1], Length( addr ) );
    fAcceptFilter.Add( addr );
  except
    raise;
  end;
end;

function TZMQSocket.getAcceptFilter( indx: Integer ): String;
begin
  if ( indx < 0 ) or ( indx >= fAcceptFilter.Count ) then
    raise EZMQException.Create( '[getAcceptFilter] Index out of bounds.' );
  result := fAcceptFilter[indx];
end;

procedure TZMQSocket.setAcceptFilter( indx: Integer; const Value: String );
var
  i,num: Integer;
begin
  num := 0;
  if ( indx < 0 ) or ( indx >= fAcceptFilter.Count ) then
    raise EZMQException.Create( '[getAcceptFilter] Index out of bounds.' );

  setSockOpt( ZMQ_TCP_ACCEPT_FILTER, nil, 0 );
  for i := 0 to fAcceptFilter.Count - 1 do
  begin
    try
      if i <> indx then
        setSockOpt( ZMQ_TCP_ACCEPT_FILTER, @fAcceptFilter[i][1], Length( fAcceptFilter[i] ) )
      else begin
        setSockOpt( ZMQ_TCP_ACCEPT_FILTER, @Value[1], Length( Value ) );
        fAcceptFilter[i] := Value;
      end;
    except
      on e: EZMQException do
      begin
        num := e.Num;
        if i = indx then
          setSockOpt( ZMQ_TCP_ACCEPT_FILTER, @fAcceptFilter[i][1], Length( fAcceptFilter[i] ) )
      end else
        raise;
    end;
  end;
  if num <> 0 then
    raise EZMQException.Create( num );
end;

{$else}

function TZMQSocket.getSwap: Int64;
begin
  result := getSockOptInt64( ZMQ_SWAP );
end;

function TZMQSocket.getRecoveryIVLMSec: Int64;
begin
  result := getSockOptInt64( ZMQ_RECOVERY_IVL_MSEC );
end;

function TZMQSocket.getMCastLoop: Int64;
begin
  result := getSockOptInt64( ZMQ_MCAST_LOOP );
end;

procedure TZMQSocket.setSwap( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_SWAP, Value );
end;

procedure TZMQSocket.setRecoveryIvlMSec( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_RECOVERY_IVL_MSEC, Value );
end;

procedure TZMQSocket.setMCastLoop( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_MCAST_LOOP, Value );
end;

{$endif}

procedure TZMQSocket.setHWM( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
begin
  {$ifdef zmq3}
  SndHWM := Value;
  RcvHWM := Value;
  {$else}
  setSockOptInt64( ZMQ_HWM, Value );
  {$endif}
end;


procedure TZMQSocket.setAffinity( const Value: UInt64 );
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

procedure TZMQSocket.setRate( const Value: {$ifdef zmq3}Integer{$else}int64{$endif} );
begin
  {$ifdef zmq3}
  setSockOptInteger( ZMQ_RATE, Value );
  {$else}
  setSockOptInt64( ZMQ_RATE, Value );
  {$endif}
end;

procedure TZMQSocket.setRecoveryIvl( const Value: {$ifdef zmq3}Integer{$else}int64{$endif} );
begin
  {$ifdef zmq3}
  setSockOptInteger( ZMQ_RECOVERY_IVL, Value );
  {$else}
  setSockOptInt64( ZMQ_RECOVERY_IVL, Value );
  {$endif}
end;

procedure TZMQSocket.setSndBuf( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
begin
  {$ifdef zmq3}
  setSockOptInteger( ZMQ_SNDBUF, Value );
  {$else}
  setSockOptInt64( ZMQ_SNDBUF, Value );
  {$endif}
end;

procedure TZMQSocket.setRcvBuf( const Value: {$ifdef zmq3}Integer{$else}UInt64{$endif} );
begin
  {$ifdef zmq3}
  setSockOptInteger( ZMQ_RCVBUF, Value );
  {$else}
  setSockOptInt64( ZMQ_RCVBUF, Value );
  {$endif}
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
var
  lmsgsize: integer;
begin
  {$ifdef zmq3}
  lmsgsize := msg.size;
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
//    cannot call msg.size after calling zmq_sendmsg because zmq_msg_t structure (fMessage) is nullified during the call
//    if result <> msg.size then
    if result <> lmsgsize then
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

procedure MonitorProc( ZMQMonitorRec: PZMQMonitorRec );
var
  socket: TZMQSocket;
  msg: TZMQMessage;
  msgsize: Integer;
  event: zmq_event_t;
  zmqEvent: TZMQEvent;
  i: Integer;
begin
  socket := ZMQMonitorRec.context.Socket( stPair );
  socket.RcvTimeout := 100; // 1 sec.
  socket.connect( ZMQMonitorRec.Addr );
  msg := TZMQMessage.create;

  while not ZMQMonitorRec.Terminated do
  begin
    try
      msgsize := socket.recv( msg, [] );
      if msgsize > -1 then
      begin
        {$ifdef UNIX}
        Move( msg.data^, event, SizeOf(event) );
        {$else}
        CopyMemory( @event, msg.data, SizeOf(event) );
        {$endif}
        i := 0;
        while event.event <> 0 do
        begin
        event.event := event.event shr 1;
          inc( i );
        end;
        zmqEvent.event := TZMQMonitorEvent( i - 1 );
        zmqEvent.addr := String( event.addr );
        zmqEvent.fd := event.fd;
        ZMQMonitorRec.proc( zmqEvent );
        msg.rebuild;
      end;
    except
      on e: EZMQException do
      if e.Num <> ZMQEAGAIN then
        raise;
    end;

  end;
  msg.Free;
  socket.Free;
end;

procedure TZMQSocket.RegisterMonitor( proc: TZMQMonitorProc; events: TZMQMonitorEvents = cZMQMonitorEventsAll );
var
  {$ifdef UNIX}
  tid: QWord;
  {$else}
  tid: Cardinal;
  {$endif}
begin
  if fMonitorRec <> nil then
    DeRegisterMonitor;

  New( fMonitorRec );
  fMonitorRec.Terminated := False;
  fMonitorRec.context := fContext;
  fMonitorRec.Addr := 'inproc://monitor.' + IntToHex( Integer( SocketPtr ),8 );
  fMonitorRec.Proc := proc;

  CheckResult( zmq_socket_monitor( SocketPtr,
    PAnsiChar( AnsiString( fMonitorRec.Addr ) ), Word( events ) ) );

  fMonitorThread := BeginThread( nil, 0, @MonitorProc, fMonitorRec, 0, tid );
  sleep(1);

end;

procedure TZMQSocket.DeRegisterMonitor;
var
  rc: Cardinal;
begin
  {$ifdef UNIX}
    raise Exception.Create(Self.ClassName+'.DeRegisterMonitor not implemented');
    { TODO : implement equivalent to WaitForSingleObject like pthread_join() ? }
  {$else}
  if fMonitorRec <> nil then
  begin
    fMonitorRec.Terminated := True;
    rc := WaitForSingleObject( fMonitorThread, INFINITE );
    if rc = WAIT_FAILED then
    raise Exception.Create( 'error in WaitForSingleObject for Monitor Thread' );
    CheckResult( zmq_socket_monitor( SocketPtr, nil ,0 ) );
    Dispose( fMonitorRec );
    fMonitorRec := nil;
  end;
  {$endif}
end;

{$endif}

function TZMQSocket.recv( msg: TZMQMessage; flags: Integer = 0 ): Integer;
var
  errn: Integer;
begin
  {$ifdef zmq3}
  result := zmq_recvmsg( SocketPtr, msg.fMessage, flags );
  if result < -1 then
    raise EZMQException.Create('zmq_recvmsg return value less than -1.')
  else if result = -1 then
  begin
    errn := zmq_errno;

    if (errn = ETERM) {$ifdef UNIX}or (errn = ZMQEINTR){$endif} then
      close
    else if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
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

function TZMQSocket.recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer;
var
  zmqmsg: TZMQMessage;
begin
  zmqmsg := TZMQMessage.Create;
  try
    result := recv( zmqmsg, flags );
    strm.Write( zmqmsg.data^, result );
  finally
    zmqmsg.Free;
  end;
end;

function TZMQSocket.recv( var msg: String; flags: TZMQRecvFlags = [] ): Integer;
var
  sStrm: TStringStream;
begin
  sStrm := TStringStream.Create('');
  try
    Result := recv( sStrm, flags );
    sStrm.Position := 0;
    msg := sStrm.ReadString( result );
  finally
    sStrm.Free;
  end;
end;

// receive multipart message. the result is the number of messages received.
function TZMQSocket.recv( msg: TStrings; flags: TZMQRecvFlags = [] ): Integer;
var
  s: String;
  bRcvMore: Boolean;
  rc: Integer;
begin
  bRcvMore := True;
  result := 0;
  while bRcvMore do
  begin
    rc := recv( s, flags );
    if rc <> -1 then
    begin
      msg.Add( s );
      inc( result );
    end;
    bRcvMore := RcvMore;
  end;
end;

function TZMQSocket.getTerminated: Boolean;
begin
  result := SocketPtr = nil;
end;

{$ifndef UNIX}
// helpers. inspired by the zhelpers.h
// not READY!
procedure TZMQSocket.dump;
var
  msg: TZMQMessage;
  s: AnsiString;
  i,l: Integer;
  pac: PAnsiChar;
  pwc: PWideChar;
  b: BOOL;
begin
  msg := TZMQMessage.create;
  writeln('----------------------------------------');
  try
    repeat
      l := recv( msg, 0 );
      i := 0;
      pac := msg.data;
      while ( i < l ) and ( Ord( PAnsiChar(pac + i )^ ) >=32 ) and
        ( Ord( PAnsiChar(pac + i)^ ) <= 127 ) do Inc( i );
      if i < l then
      begin
        // not AnsiString;
        pac := msg.data;

          i := Windows.MultiByteToWideChar( CP_UTF8, 8, pac, l, nil, 0 );
          if i <> 0  then
            Writeln('some Utf8')
          else begin

          // not unicode string.
          pwc := msg.data;

            b := false;
            i := Windows.WideCharToMultiByte( CP_UTF8, 8, pwc, -1, nil, 0, nil, @b );
            if i <> 0 then
            Writeln('some Wide')
            else

            Writeln( 'Hex' );
          

          end;

      end else
      begin
        SetString( s, PChar(msg.data), l );
        Writeln( s );
      end;
    until not rcvMore;
  finally
    msg.Free;
  end;
end;
{$endif}

{ TZMQContext }

constructor TZMQContext.create{$ifndef zmq3}( io_threads: Integer ){$endif};
begin
  {$ifdef FPC}
  fThreadId := GetCurrentThreadId;
  {$else}
  fThreadId := Windows.GetCurrentThreadId;
  {$endif}
  fInterrupted := false;
  contexts.Add( Self );
  {$ifdef zmq3}
  fContext := zmq_ctx_new;
  {$else}
  fContext := zmq_init( io_threads );
  {$endif}
  fLinger := -2;
  if ContextPtr = nil then
    raise EZMQException.Create;
  fSockets := TList.Create;
end;

destructor TZMQContext.destroy;
var
  i: Integer;
begin
  if fLinger >= -1 then
  for i:= 0 to fSockets.Count - 1 do
    TZMQSocket(fSockets[i]).Linger := Linger;

  // if Socket created in the same Thread, it's safe to
  // terminate here. We assume that the context is terminated
  // in the same Thread as it was created.
  i := 0;
  while i < fSockets.Count do
  if TZMQSocket(fSockets[i]).fThreadId = fThreadId then
    TZMQSocket(fSockets[i]).Free
  else
    Inc( i );

  {$ifdef zmq3}
  CheckResult( zmq_ctx_destroy( ContextPtr ) );
  {$else}
  CheckResult( zmq_term( ContextPtr ) );
  {$endif}

  fSockets.Free;
  contexts.Delete( contexts.IndexOf(Self) );
  inherited;
end;

procedure TZMQContext.CheckResult( rc: Integer );
begin
  if rc = 0 then
  begin
  // ok
  end else
  if rc = -1 then
  begin
    raise EZMQException.Create;
  end else
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

{$ifdef zmq3}
function TZMQContext.getOption( option: Integer ): Integer;
begin
  result := zmq_ctx_get( ContextPtr, option );
  if result = -1 then
    raise EZMQException.Create
  else if result < -1 then
    raise EZMQException.Create('Function result is less than -1!');
end;

procedure TZMQContext.setOption( option, optval: Integer );
begin
  CheckResult( zmq_ctx_set( ContextPtr, option, optval ) );
end;

function TZMQContext.getIOThreads: Integer;
begin
  result := getOption( ZMQ_IO_THREADS );
end;

procedure TZMQContext.setIOThreads( const Value: Integer );
begin
  setOption( ZMQ_IO_THREADS, Value );
end;

function TZMQContext.getMaxSockets: Integer;
begin
  result := getOption( ZMQ_MAX_SOCKETS );
end;

procedure TZMQContext.setMaxSockets( const Value: Integer );
begin
  setOption( ZMQ_MAX_SOCKETS, Value );
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

/// if the second parameter specified, than only the first "pollCount"
/// sockets polled
function TZMQPoller.poll( timeout: Integer = -1; pollCount: Integer = -1 ): Integer;
var
  pc: Integer;
begin
  if fPollItemCount = 0 then
    raise EZMQException.Create( 'Nothing to poll!' );
  if pollCount = -1 then
    pc := fPollItemCount
  else
  if ( pollCount > -1 ) and ( pollCount <= fPollItemCount ) then
    pc := pollCount
  else
    raise EZMQException.Create( 'wrong pollCount parameter.' );
  result := zmq_poll( fPollItems[0], pc, timeout );
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

{$ifdef UNIX}
procedure InterruptContexts;
var
  i: Integer;
begin
  for i := 0 to contexts.Count - 1 do
    TZMQContext(contexts[i]).fInterrupted := True;
end;

procedure HandleSignal(signum: longint; si: psiginfo; sc: PSigcontext); cdecl;
begin
  InterruptContexts;
  Writeln('zmqapi handling signal: ' + IntToStr(signum));
end;

procedure InstallSigHandler(sig: cint); cdecl;
var
  k : integer;
  oa, na : PSigActionRec;
begin
  new(na);
  new(oa);
  na^.sa_handler := @HandleSignal;
  fillchar(na^.sa_mask,sizeof(na^.sa_mask),#0);
  na^.sa_flags := 0;
  na^.sa_restorer := nil;
  k := fpSigaction(sig,na,oa);
  if k<>0 then
    begin
      Writeln('signal handler install error '+IntToStr(k)+' '+IntToStr(fpgeterrno));
      halt(1);
    end;
  Freemem(oa);
  Freemem(na);
end;

{$else}
function console_handler( dwCtrlType: DWORD ): BOOL;
var
  i: Integer;
begin
  if CTRL_C_EVENT = dwCtrlType then
  begin
    for i := 0 to contexts.Count - 1 do
      TZMQContext(contexts[i]).fInterrupted := True;
    result := True;
    // if I set to True than the app won't exit,
    // but it's not the solution.
  end else begin
    result := False;
  end;
end;
{$endif}

initialization
  {$ifdef UNIX}
  InitCriticalSection( cs );
  {$else}
  InitializeCriticalSection( cs );
  {$endif}
  contexts := TList.Create;
  {$ifdef UNIX}
  { TODO : Signal handling should normally be installed at application level, not in library }
  //InstallSigHandler(SIGTERM);
  //InstallSigHandler(SIGINT);
  {$else}
  Windows.SetConsoleCtrlHandler( @console_handler, True );
  {$endif}

finalization
  contexts.Free;
  {$ifdef UNIX}
  DoneCriticalSection( cs );
  {$else}
  DeleteCriticalSection( cs );
  {$endif}

end.
