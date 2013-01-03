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

  TZMQFrame = class
  private
    fMessage: zmq_msg_t;
    procedure CheckResult( rc: Integer );
    {$ifdef zmq3}
    function getProperty( prop: TZMQMessageProperty ): Integer;
    procedure setProperty( prop: TZMQMessageProperty; value: Integer );
    {$endif}

    function getAsUtf8String: Utf8String;
    procedure setAsUtf8String(const Value: Utf8String);

  public
    constructor create; overload;
    constructor create( size: size_t ); overload;
    constructor create( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil ); overload;
    destructor Destroy; override;
    procedure rebuild; overload;
    procedure rebuild( size: size_t ); overload;
    procedure rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil ); overload;
    procedure move( msg: TZMQFrame );
    procedure copy( msg: TZMQFrame );
    function data: Pointer;
    function size: size_t;
    {$ifdef zmq3}
    function more: Boolean;
    {$endif}

    function dup: TZMQFrame;
    // convert the data into a readable string.
    function dump: Utf8String;

    // copy the whole content of the stream to the message.
    procedure LoadFromStream( strm: TStream );
    procedure SaveToStream( strm: TStream );

    property asUtf8String: Utf8String read getAsUtf8String write setAsUtf8String;

  end;

  // for multipart message
  TZMQMsg = class
  private
   msgs: TList;
   csize: Cardinal;
   cursor: Integer;
    function getItem(indx: Integer): TZMQFrame;
  protected
  public
   constructor create;
   destructor Destroy; override;

   // Return size of message, i.e. number of frames (0 or more).
   function size: Integer;

   // Return size of message, i.e. number of frames (0 or more).
   function content_size: Integer;

   // Push frame to the front of the message, i.e. before all other frames.
   // Message takes ownership of frame, will destroy it when message is sent.
   // Set the cursor to 0
   // Returns 0 on success, -1 on error.
   function push( msg: TZMQFrame ): Integer;

   // Remove first frame from message, if any. Returns frame, or NULL. Caller
   // now owns frame and must destroy it when finished with it.
   // Set the cursor to 0
   function pop: TZMQFrame;

   // Add frame to the end of the message, i.e. after all other frames.
   // Message takes ownership of frame, will destroy it when message is sent.
   // Set the cursor to 0
   // Returns 0 on success
   function add( msg: TZMQFrame ): Integer;

   // Push frame plus empty frame to front of message, before first frame.
   // Message takes ownership of frame, will destroy it when message is sent.
   procedure wrap( msg: TZMQFrame );

   // Pop frame off front of message, caller now owns frame
   // If next frame is empty, pops and destroys that empty frame.
   function unwrap: TZMQFrame;

   // Remove specified frame from list, if present. Does not destroy frame.
   // Set the cursor to 0
   procedure remove( msg: TZMQFrame );

   // Set cursor to first frame in message. Returns frame, or NULL.
   function first: TZMQFrame;

   // Return the next frame. If there are no more frames, returns NULL. To move
   // to the first frame call zmsg_first(). Advances the cursor.
   function next: TZMQFrame;

   // Return the last frame. If there are no frames, returns NULL.
   // Set the cursor to the last
   function last: TZMQFrame;

   // Create copy of message, as new message object
   function dup: TZMQMsg;

   procedure Clear;
   property item[indx: Integer]: TZMQFrame read getItem; default;
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
    procedure close;
    procedure setSockOpt( option: Integer; optval: Pointer; optvallen: size_t );
    procedure getSockOpt( option: Integer; optval: Pointer; var optvallen: size_t );
    function send( var msg: TZMQFrame; flags: Integer = 0 ): Integer; overload;
    function recv( var msg: TZMQFrame; flags: Integer = 0 ): Integer; overload;
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

    function send( var msg: TZMQFrame; flags: TZMQSendFlags = [] ): Integer; overload;
    function send( strm: TStream; size: Integer; flags: TZMQSendFlags = [] ): Integer; overload;
    function send( msg: String; flags: TZMQSendFlags = [] ): Integer; overload;

    function send( var msgs: TZMQMsg; dontwait: Boolean = false ): Integer; overload;
    function send( msg: Array of String; dontwait: Boolean = false ): Integer; overload;
    function send( msg: TStrings; dontwait: Boolean = false ): Integer; overload;
    {$ifdef zmq3}
    function sendBuffer( const Buffer; len: Size_t; flags: TZMQSendFlags = [] ): Integer;
    {$endif}

    function recv( msg: TZMQFrame; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( var msg: String; flags: TZMQRecvFlags = [] ): Integer; overload;

    function recv( var msgs: TZMQMsg; flags: TZMQRecvFlags = [] ): Integer; overload;
    function recv( msg: TStrings; flags: TZMQRecvFlags = [] ): Integer; overload;

    {$ifdef zmq3}
    function recvBuffer( var Buffer; len: size_t; flags: TZMQRecvFlags = [] ): Integer;
    procedure RegisterMonitor( proc: TZMQMonitorProc; events: TZMQMonitorEvents = cZMQMonitorEventsAll );
    procedure DeRegisterMonitor;

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

    property Context: TZMQContext read fContext;
    property SocketPtr: Pointer read fSocket;
    property RaiseEAgain: Boolean read fRaiseEAgain write fRaiseEAgain;
  end;

  TZMQContext = class
  private
    fContext: Pointer;
    fSockets: TList;
    fLinger: Integer;

    {$ifdef zmq3}
    function getOption( option: Integer ): Integer;
    procedure setOption( option, optval: Integer );
    function getIOThreads: Integer;
    procedure setIOThreads( const Value: Integer );
    function getMaxSockets: Integer;
    procedure setMaxSockets( const Value: Integer );
    {$endif}
  protected
    fTerminated: Boolean;
    procedure CheckResult( rc: Integer );
    procedure RemoveSocket( lSocket: TZMQSocket );

  public
    constructor create{$ifndef zmq3}( io_threads: Integer = 1 ){$endif};
    destructor Destroy; override;
    function Socket( stype: TZMQSocketType ): TZMQSocket;
    procedure Terminate;
    property ContextPtr: Pointer read fContext;

    //  < -1 means dont change linger when destroy
    property Linger: Integer read fLinger write fLinger;
    property Terminated: Boolean read fTerminated;
    {$ifdef zmq3}
    property IOThreads: Integer read getIOThreads write setIOThreads;
    property MaxSockets: Integer read getMaxSockets write setMaxSockets;
    {$endif}

  end;

type

  TZMQFree = zmq.free_fn;

  TZMQPollItem = record
    socket: TZMQSocket;
    events: TZMQPollEvents;
    revents: TZMQPollEvents;
  end;

  TZMQPollEventProc = procedure( socket: TZMQSocket; event: TZMQPollEvents ) of object;
  TZMQExceptionProc = procedure( exception: Exception ) of object;
  TZMQPoller = class( TThread )
  private
    fContext: TZMQContext;
    fOwnContext: Boolean;
    sPair: TZMQSocket;
    fAddr: String;

    fPollItem: array of zmq.pollitem_t;
    fPollSocket: array of TZMQSocket;
    fPollItemCapacity,
    fPollItemCount: Integer;

    fTimeOut: Integer;

    fPollNumber: Integer;

    cs: TRTLCriticalSection;
    fSync: Boolean;

    fonException: TZMQExceptionProc;
    fonTimeOut: TNotifyEvent;
    fonEvent: TZMQPollEventProc;
    function getPollItem(indx: Integer): TZMQPollItem;

    procedure CheckResult( rc: Integer );

    procedure AddToPollItems( socket: TZMQSocket; events: TZMQPollEvents );
    procedure DelFromPollItems( socket: TZMQSocket; events: TZMQPollEvents; indx: Integer );

    function getPollResult(indx: Integer): TZMQPollItem;
  protected
    procedure Execute; override;
  public
    constructor Create( lSync: Boolean = false; lContext: TZMQContext = nil );
    destructor Destroy; override;

    procedure Register( socket: TZMQSocket; events: TZMQPollEvents; bWait: Boolean = false );
    procedure Deregister( socket: TZMQSocket; events: TZMQPollEvents; bWait: Boolean = false );
    procedure setPollNumber( const Value: Integer; bWait: Boolean = false );

    function poll( timeout: Longint = -1; lPollNumber: Integer = -1 ): Integer;
    property pollResult[indx: Integer]: TZMQPollItem read getPollResult;

    property PollNumber: Integer read fPollNumber;
    property PollItem[indx: Integer]: TZMQPollItem read getPollItem;

    property onEvent: TZMQPollEventProc read fonEvent write fonEvent;
    property onException: TZMQExceptionProc read fonException write fonException;
    property onTimeOut: TNotifyEvent read fonTimeOut write fonTimeOut;
  end;

  TZMQDevice = ( dStreamer, dForwarder, dQueue );

  {$ifdef zmq3}
  procedure ZMQProxy( frontend, backend, capture: TZMQSocket );
  {$endif}

  procedure ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket );
  procedure ZMQVersion(var major, minor, patch: Integer);

  procedure ZMQTerminate;

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

constructor TZMQFrame.Create;
begin
  CheckResult( zmq_msg_init( fMessage ) );
end;

constructor TZMQFrame.Create( size: size_t );
begin
  CheckResult( zmq_msg_init_size( fMessage, size ) );
end;

constructor TZMQFrame.Create( data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer );
begin
  CheckResult( zmq_msg_init_data( fMessage, data, size, ffn, hint ) );
end;

destructor TZMQFrame.Destroy;
begin
  CheckResult( zmq_msg_close( fMessage ) );
  inherited;
end;

procedure TZMQFrame.CheckResult( rc: Integer );
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

procedure TZMQFrame.rebuild;
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init( fMessage ) );
end;

procedure TZMQFrame.rebuild( size: size_t );
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init_size( fMessage, size ) );
end;

procedure TZMQFrame.rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil );
begin
  CheckResult( zmq_msg_close( fMessage ) );
  CheckResult( zmq_msg_init_data( fMessage, data, size, ffn, hint ) );
end;

procedure TZMQFrame.move( msg: TZMQFrame );
begin
  CheckResult( zmq_msg_move( fMessage, msg.fMessage ) );
end;

procedure TZMQFrame.copy( msg: TZMQFrame );
begin
  CheckResult( zmq_msg_copy( fMessage, msg.fMessage ) );
end;

function TZMQFrame.data: Pointer;
begin
  result := zmq_msg_data( fMessage );
end;

function TZMQFrame.size: size_t;
begin
 result := zmq_msg_size( fMessage );
end;

{$ifdef zmq3}
function TZMQFrame.getProperty( prop: TZMQMessageProperty ): Integer;
begin
  result := zmq_msg_get( fMessage, Byte( prop ) );
  if result = -1 then
    raise EZMQException.Create
  else
    raise EZMQException.Create( 'zmq_msg_more return value undefined!' );
end;

procedure TZMQFrame.setProperty( prop: TZMQMessageProperty; value: Integer );
begin
  CheckResult( zmq_msg_set( fMessage, Byte( prop ), value ) );
end;

function TZMQFrame.more: Boolean;
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

{$endif}

function TZMQFrame.dup: TZMQFrame;
begin
  result := TZMQFrame.create( size );
  System.Move( data^, result.data^, size );
end;

function TZMQFrame.dump: Utf8String;
var
  sUtf8: Utf8String;
  iSize: Integer;
begin
  // not complete.
  iSize := size;
  if iSize = 0 then
    result := ''
  else if Integer(data^) = 0 then
  begin
    SetLength( sutf8, iSize * 2 );
    BinToHex( data, PAnsiChar(sutf8), iSize );
  end else
    result := asUtf8String;
end;

function TZMQFrame.getAsUtf8String: Utf8String;
begin
  SetString( result, PChar(data), size );
end;

procedure TZMQFrame.setAsUtf8String( const Value: Utf8String );
var
  iSize: Integer;
begin
  iSize := Length( Value );
  rebuild( iSize );
  System.Move( Value[1], data^, iSize );
end;

procedure TZMQFrame.LoadFromStream( strm: TStream );
begin
  strm.Position := 0;
  if strm.size <> size then
    rebuild( strm.Size );
  strm.ReadBuffer( data^, strm.Size );
end;

procedure TZMQFrame.SaveToStream( strm: TStream );
begin
  strm.WriteBuffer( data^, size );
end;

{ TZMQMsg }

constructor TZMQMsg.create;
begin
  msgs := TList.Create;
  csize := 0;
  cursor := 0;
end;

destructor TZMQMsg.Destroy;
begin
  msgs.Clear;
  msgs.Free;
  inherited;
end;

function TZMQMsg.size: Integer;
begin
  result := msgs.Count;
end;

function TZMQMsg.content_size: Integer;
begin
  result := csize;
end;

function TZMQMsg.push( msg: TZMQFrame ): Integer;
begin
  try
    msgs.Insert( 0, msg );
    csize := csize + msg.size;
    result := 0;
    cursor := 0;
  except
    result := -1
  end;
end;

function TZMQMsg.pop: TZMQFrame;
begin
  if size > 0 then
  begin
    result := msgs[0];
    csize := csize - result.size;
    msgs.Delete( 0 );
    cursor := 0;
  end else
    result := nil;
end;

function TZMQMsg.add( msg: TZMQFrame ): Integer;
begin
  try
    msgs.Add( msg );
    csize := csize + msg.size;
    result := 0;
    cursor := 0;
  except
    result := -1;
  end;
end;

procedure TZMQMsg.wrap( msg: TZMQFrame );
begin
  push( TZMQFrame.create( 0 ) );
  push( msg );
end;

function TZMQMsg.unwrap: TZMQFrame;
begin
  result := pop;
  if ( size > 0 ) and ( Item[0].size = 0 ) then
    pop.Free;
end;

procedure TZMQMsg.remove( msg: TZMQFrame );
var
  i: Integer;
begin
  i := msgs.IndexOf( msg );
  if i > 0 then
  begin
    csize := csize - Item[i].size;
    msgs.Delete( i );
    cursor := 0;
  end;
end;

function TZMQMsg.first: TZMQFrame;
begin
  if size > 0 then
  begin
    result := msgs[0];
    cursor := 1;
  end else begin
    result := nil;
    cursor := 0;
  end;
end;

function TZMQMsg.next: TZMQFrame;
begin
  if cursor < size then
  begin
    result := msgs[cursor];
    inc( cursor );
  end else
    result := nil;
end;

function TZMQMsg.last: TZMQFrame;
begin
  if size > 0 then
    result := msgs[size - 1]
  else
    result := nil;
  cursor := size;
end;

function TZMQMsg.dup: TZMQMsg;
var
  msg,
  msgnew: TZMQFrame;
  iSize: Integer;
begin
  result := TZMQMsg.create;
  msg := first;
  while msg <> nil do
  begin
    iSize := msg.size;
    msgnew := TZMQFrame.create( iSize );
    {$ifdef UNIX}
    Move( msg.data^, msgnew.data^, iSize );
    {$else}
    CopyMemory( msgnew.data, msg.data, iSize );
    {$endif}
    result.add( msgnew );
    msg := next;
  end;
  result.csize := csize;
  result.cursor := cursor;
end;

procedure TZMQMsg.Clear;
var
  i: Integer;
begin
  for i := 0 to size - 1 do
    Item[i].Free;
  cursor := 0;
end;

function TZMQMsg.getItem( indx: Integer ): TZMQFrame;
begin
  result := msgs[indx];
end;


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
begin
  if rc = -1 then
  begin
    raise EZMQException.Create;
  end else
  if rc <> 0 then
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
    raise EZMQException.Create;
end;
{$endif}

function TZMQSocket.send( var msg: TZMQFrame; flags: Integer = 0 ): Integer;
{$ifdef debug}
var
  lmsgsize: integer;
{$endif}
begin
  {$ifdef zmq3}
  {$ifdef debug}
  lmsgsize := msg.size;
  {$endif}

  result := zmq_sendmsg( SocketPtr, msg.fMessage, flags );
  //result := zmq_msg_send( msg.fMessage, SocketPtr, flags );
  FreeAndNil( msg );

  if result < -1 then
    raise EZMQException.Create('zmq_sendmsg return value less than -1.')
  else if result = -1 then
    raise EZMQException.Create
  else begin
    {$ifdef debug}
    if result <> lmsgsize then
      raise EZMQException.Create('return value of zmq_sendmsg and msg size is not equal.');
    {$endif}
  end;
  {$else}
  result := msg.size;
  CheckResult( zmq_send( SocketPtr, msg.fMessage, flags ) );
  FreeAndNil( msg );
  {$endif}
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocket.send( var msg: TZMQFrame; flags: TZMQSendFlags = [] ): Integer;
begin
  result := send( msg, Byte( flags ) );
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocket.send( strm: TStream; size: Integer; flags: TZMQSendFlags = [] ): Integer;
var
  zmqMsg: TZMQFrame;
begin
  zmqMsg := TZMQFrame.Create( size );
  strm.Read( zmqMsg.data^, size );
  result := send( zmqMsg, flags );
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

function TZMQSocket.send( var msgs: TZMQMsg; dontwait: Boolean = false ): Integer;
var
  flags: TZMQSendFlags;
  frame: TZMQFrame;
begin
  Result := 0;
  if dontwait then
    flags := [{$ifdef zmq3}sfDontWait{$else}sfNoBlock{$endif}]
  else
    flags := [];
  while msgs.size > 0 do
  begin
    frame := msgs.pop;
    if msgs.size = 0 then
      send( frame, flags )
    else
      send( frame, flags + [sfSndMore] );
    inc( result );
  end;
  FreeAndNil( msgs );
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
    raise EZMQException.Create;
end;

procedure MonitorProc( ZMQMonitorRec: PZMQMonitorRec );
var
  socket: TZMQSocket;
  msg: TZMQFrame;
  msgsize: Integer;
  event: zmq_event_t;
  zmqEvent: TZMQEvent;
  i: Integer;
begin
  socket := ZMQMonitorRec.context.Socket( stPair );
  socket.RcvTimeout := 100; // 1 sec.
  socket.connect( ZMQMonitorRec.Addr );
  msg := TZMQFrame.create;

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

function TZMQSocket.recv( var msg: TZMQFrame; flags: Integer = 0 ): Integer;
var
  errn: Integer;
begin
  if msg = nil then
    msg := TZMQFrame.Create;
  if msg.size > 0 then
    msg.rebuild;
  {$ifdef zmq3}
  result := zmq_recvmsg( SocketPtr, msg.fMessage, flags );
  // result := zmq_msg_recv( msg.fMessage, SocketPtr, flags );
  if result < -1 then
    raise EZMQException.Create('zmq_recvmsg return value less than -1.')
  else if result = -1 then
  begin
    errn := zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
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

function TZMQSocket.recv( msg: TZMQFrame; flags: TZMQRecvFlags = [] ): Integer;
begin
  result := recv( msg, Byte( flags ) );
end;

function TZMQSocket.recv( strm: TStream; flags: TZMQRecvFlags = [] ): Integer;
var
  zmqmsg: TZMQFrame;
begin
  zmqmsg := TZMQFrame.Create;
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

function TZMQSocket.recv( var msgs: TZMQMsg; flags: TZMQRecvFlags = [] ): Integer;
var
  msg: TZMQFrame;
  bRcvMore: Boolean;
  rc: Integer;
begin
  if msgs = nil then
    msgs := TZMQMsg.Create;
    
  bRcvMore := True;
  result := 0;
  while bRcvMore do
  begin
    msg := TZMQFrame.create;
    rc := recv( msg, flags );
    if rc <> -1 then
    begin
      msgs.Add( msg );
      inc( result );
    end;
    bRcvMore := RcvMore;
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

{ TZMQContext }

constructor TZMQContext.create{$ifndef zmq3}( io_threads: Integer ){$endif};
begin
  fTerminated := false;
  contexts.Add( Self );
  {$ifdef zmq3}
  fContext := zmq_ctx_new;
  {$else}
  fContext := zmq_init( io_threads );
  {$endif}
  //fLinger := -2;
  fLinger := 0;
  if ContextPtr = nil then
    raise EZMQException.Create;
  fSockets := TList.Create;
end;

destructor TZMQContext.destroy;
var
  i: Integer;
  {$ifdef FPC}
  fThreadId: TThreadID;
  {$else}
  fThreadId: Cardinal;
  {$endif}

begin
  if fLinger >= -1 then
  for i:= 0 to fSockets.Count - 1 do
    TZMQSocket(fSockets[i]).Linger := Linger;

  // if Socket created in the same Thread, it's safe to
  // terminate here.
  {$ifdef FPC}
  fThreadId := GetCurrentThreadId;
  {$else}
  fThreadId := Windows.GetCurrentThreadId;
  {$endif}

  i := 0;
  while i < fSockets.Count do
  begin
    if TZMQSocket(fSockets[i]).fThreadId = fThreadId then
      TZMQSocket(fSockets[i]).Free;
    Inc( i );
  end;

  if fContext <> nil then
  begin
  {$ifdef zmq3}
  CheckResult( zmq_ctx_destroy( ContextPtr ) );
  {$else}
  CheckResult( zmq_term( ContextPtr ) );
  {$endif}
  fContext := nil;
  end;

  fSockets.Free;
  contexts.Delete( contexts.IndexOf(Self) );
  inherited;
end;

procedure TZMQContext.Terminate;
var
  p: Pointer;
begin
  fTerminated := true;

  {$ifdef unix}
  fTerminated := true;
  {$else}
  p := ContextPtr;
  fContext := nil;
  {$ifdef zmq3}
  CheckResult( zmq_ctx_destroy( p ) );
  {$else}
  CheckResult( zmq_term( p ) );
  {$endif}
  {$endif}
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


const
  cZMQPoller_Register = 'reg';
  cZMQPoller_SyncRegister = 'syncreg';
  cZMQPoller_DeRegister = 'dereg';
  cZMQPoller_SyncDeRegister = 'syncdereg';
  cZMQPoller_Terminate = 'term';

  cZMQPoller_PollNumber = 'pollno';
  cZMQPoller_SyncPollNumber = 'syncpollno';

{ TZMQPoller }

constructor TZMQPoller.Create( lSync: Boolean = false; lContext: TZMQContext = nil );
begin
  fSync := lSync;
  {$ifdef UNIX}
  InitCriticalSection( cs );
  {$else}
  InitializeCriticalSection( cs );
  {$endif}

  fonException := nil;

  if not fSync then
  begin
    fOwnContext := lContext = nil;
    if fOwnContext then
      fContext := TZMQContext.create
    else
      fContext := lContext;

    fAddr := 'inproc://poller' + IntToHex( Integer( Self ), 8 );
    sPair := fContext.Socket( stPair );
    sPair.bind( fAddr );
  end;

  fPollItemCapacity := 10;
  fPollItemCount := 0;
  fPollNumber := 0;

  SetLength( fPollItem, fPollItemCapacity );
  SetLength( fPollSocket, fPollItemCapacity );

  fTimeOut := -1;
  inherited Create( fSync );
end;

destructor TZMQPoller.Destroy;
begin
  if not fSync then
  begin
    sPair.send( cZMQPoller_Terminate );
    sPair.Free;
    if fOwnContext then
      fContext.Free;
  end;


  {$ifdef UNIX}
  DoneCriticalSection( cs );
  {$else}
  DeleteCriticalSection( cs );
  {$endif}
  inherited;
end;

procedure TZMQPoller.CheckResult( rc: Integer );
begin
  if rc = -1 then
    raise EZMQException.Create else
  if rc < -1 then
    raise EZMQException.Create('Function result is less than -1!');
end;

procedure TZMQPoller.AddToPollItems( socket: TZMQSocket; events: TZMQPollEvents );
begin
  EnterCriticalSection( cs );
  try
    if fPollItemCapacity = fPollItemCount then
    begin
      fPollItemCapacity := fPollItemCapacity + 10;
      SetLength( fPollItem, fPollItemCapacity );
      SetLength( fPollSocket, fPollItemCapacity );
    end;
    fPollSocket[fPollItemCount] := socket;
    fPollItem[fPollItemCount].socket := socket.SocketPtr;
    fPollItem[fPollItemCount].fd := 0;
    fPollItem[fPollItemCount].events := Byte( events );
    fPollItem[fPollItemCount].revents := 0;
    fPollItemCount := fPollItemCount + 1;
    fPollNumber := fPollItemCount;
  finally
    LeaveCriticalSection( cs );
  end;
end;

procedure TZMQPoller.DelFromPollItems( socket: TZMQSocket; events: TZMQPollEvents; indx: Integer );
var
  i: Integer;
begin
  EnterCriticalSection( cs );
  try
    fPollItem[indx].events := fPollItem[indx].events and not Byte( events );
    if fPollItem[indx].events = 0 then
    begin
      for i := indx to fPollItemCount - 2 do
      begin
        fPollItem[i] := fPollItem[i + 1];
        fPollSocket[i] := fPollSocket[i + 1];
      end;
      Dec( fPollItemCount );
    end;
  finally
    LeaveCriticalSection( cs );
  end;
end;

function TZMQPoller.getPollItem( indx: Integer ): TZMQPollItem;
begin
  EnterCriticalSection( cs );
  try
    result.socket := fPollSocket[indx];
    Byte(result.events) := fPollItem[indx].events;
    Byte(result.revents) := fPollItem[indx].revents;

  finally
    LeaveCriticalSection( cs );
  end;
end;

type
  TTempRec = record
    socket: TZMQSocket;
    events: TZMQPollEvents;
    reg,           // true if reg, false if dereg.
    sync: Boolean; // if true, socket should send back a message
  end;

procedure TZMQPoller.Execute;
var
  sPairThread: TZMQSocket;
  rc: Integer;
  i,j: Integer;
  pes: TZMQPollEvents;
  msg: TStringList;

  reglist: Array of TTempRec;
  reglistcap,
  reglistcount: Integer;

procedure AddToRegList( so: TZMQSocket; ev: TZMQPollEvents; reg: Boolean; sync: Boolean );
begin
  if reglistcap = reglistcount then
  begin
    reglistcap := reglistcap + 10;
    SetLength( reglist, reglistcap );
  end;
  reglist[reglistcount].socket := so;
  reglist[reglistcount].events := ev;
  reglist[reglistcount].reg := reg;
  reglist[reglistcount].sync := sync;
  inc( reglistcount );
end;

begin
  reglistcap := 10;
  reglistcount := 0;
  SetLength( reglist, reglistcap );

  sPairThread := fContext.Socket( stPair );
  sPairThread.connect( fAddr );

  fPollItemCount := 1;
  fPollNumber := 1;

  fPollSocket[0] := sPairThread;
  fPollItem[0].socket := sPairThread.SocketPtr;
  fPollItem[0].fd := 0;
  pes := [pePollIn];
  fPollItem[0].events := Byte( pes );
  fPollItem[0].revents := 0;

  msg := TStringList.Create;

  while not Terminated do
  try
    rc := zmq_poll( fPollItem[0], fPollNumber, fTimeOut );
    CheckResult( rc );

    if rc = 0 then
    begin
      if Assigned( fonTimeOut ) then
        fonTimeOut( self );
    end else
    begin
      for i := 0 to fPollNumber - 1 do
      if fPollItem[i].revents > 0 then
      begin
        if i = 0 then
        begin
          // control messages.
          msg.Clear;
          fPollSocket[0].recv( msg );

          if ( msg[0] = cZMQPoller_Register ) or
             ( msg[0] = cZMQPoller_SyncRegister )then
          begin
            Byte(pes) := StrToInt( msg[2] );
            AddToRegList( TZMQSocket( StrToInt( msg[1] ) ), pes, True,
              msg[0] = cZMQPoller_SyncRegister );
          end else

          if ( msg[0] = cZMQPoller_DeRegister ) or
             ( msg[0] = cZMQPoller_SyncDeRegister ) then
          begin
            Byte(pes) := StrToInt( msg[2] );
            AddToRegList( TZMQSocket( StrToInt( msg[1] ) ), pes, False,
              msg[0] = cZMQPoller_SyncDeRegister );
          end else

          if ( msg[0] = cZMQPoller_PollNumber ) or
             ( msg[0] = cZMQPoller_SyncPollNumber ) then
          begin
            fPollNumber := StrToInt( msg[1] );
            if msg[0] = cZMQPoller_SyncPollNumber then
              sPairThread.send('');
          end;

          if msg[0] = cZMQPoller_Terminate then
            Terminate;

        end else
        if Assigned( fOnEvent ) then
        begin
          Byte(pes) := fPollItem[i].revents;
          fOnEvent( fPollSocket[i], pes );
        end;
      end;

      if reglistcount > 0 then
      begin
        for i := 0 to reglistcount - 1 do
        begin
          j := 1;
          while ( j < fPollItemCount ) and ( fPollSocket[j] <> reglist[i].socket ) do
            inc( j );
          if j < fPollItemCount then
          begin
            if reglist[i].reg then
            begin
              fPollItem[j].events := fPollItem[j].events or Byte( reglist[i].events );
            end else
              DelFromPollItems( reglist[i].socket, reglist[i].events, j );

          end else
          begin
            if reglist[i].reg then
              AddToPollItems( reglist[i].socket, reglist[i].events )
            //else
              //warn not found, but want to delete.
          end;

          if reglist[i].sync then
            sPairThread.send( '' );

        end;
        reglistcount := 0;
      end;
    end;

  except
    on e: Exception do
    begin
      if ( e is EZMQException ) and
         ( EZMQException(e).Num = ETERM ) then
        Terminate;
    if Assigned( fOnException ) then
      fOnException( e );
    end;
  end;
  msg.Free;

  sPairThread.Free;

end;

procedure TZMQPoller.Register( socket: TZMQSocket; events: TZMQPollEvents; bWait: Boolean = false );
var
  s: String;
begin
  if fSync then
    AddToPollItems( socket, events )
  else
  begin
    if bWait then
      s := cZMQPoller_SyncRegister
    else
      s := cZMQPoller_Register;
    sPair.send( [ s, IntToStr( Integer(socket) ), IntToStr( Byte( events ) )] );
    if bWait then
      sPair.recv( s );
  end;
end;

procedure TZMQPoller.DeRegister( socket: TZMQSocket; events: TZMQPollEvents; bWait: Boolean = false );
var
  s: String;
  i: Integer;
begin
  if fSync then
  begin
    i := 0;
    while ( i < fPollItemCount ) and ( fPollSocket[i] <> socket ) do
      inc( i );
    if i = fPollItemCount then
      raise EZMQException.Create( 'socket not in pollitems!' );
    DelFromPollItems( socket, events, i );
  end else begin
    if bWait then
      s := cZMQPoller_SyncDeregister
    else
      s := cZMQPoller_Deregister;
    sPair.send( [ s, IntToStr( Integer(socket) ), IntToStr( Byte( events ) )] );
    if bWait then
      sPair.recv( s );
  end;
end;

procedure TZMQPoller.setPollNumber( const Value: Integer; bWait: Boolean = false );
var
  s: String;
begin
  if fSync then
    fPollNumber := Value
  else begin
    if bWait then
      s := cZMQPoller_PollNumber
    else
      s := cZMQPoller_SyncPollNumber;
    sPair.send( [ s, IntToStr( Value ) ] );
    if bWait then
      sPair.recv( s );
  end;
end;

/// if the second parameter specified, than only the first "pollCount"
/// sockets polled
function TZMQPoller.poll( timeout: Integer = -1; lPollNumber: Integer = -1 ): Integer;
var
  pc: Integer;
begin
  if not fSync then
    raise EZMQException.Create('Poller hasn''t created in Synchronous mode');
  if fPollItemCount = 0 then
    raise EZMQException.Create( 'Nothing to poll!' );
  if lPollNumber = -1 then
    pc := fPollItemCount
  else
  if ( lpollNumber > -1 ) and ( lpollNumber <= fPollItemCount ) then
    pc := lpollNumber
  else
    raise EZMQException.Create( 'wrong pollCount parameter.' );

  {$ifndef zmq3}
  if timeout <> -1 then
    timeout := timeout * 1000;
  {$endif}

  result := zmq_poll( fPollItem[0], pc, timeout );
  if result < 0 then
    raise EZMQException.Create
end;

function TZMQPoller.getPollResult( indx: Integer ): TZMQPollItem;
var
  i,j: Integer;
begin
  if not fSync then
    raise EZMQException.Create('Poller created in Synchronous mode');
  i := 0;
  j := -1;
  while ( i < fPollItemCount) and ( j < indx ) do
  begin
    if ( fPollItem[i].revents and fPollItem[i].events ) > 0 then
      inc( j );
    if j < indx then
      inc( i );
  end;
  result.socket := fPollSocket[i];
  Byte(result.events) := fPollItem[i].revents;
end;

procedure ZMQProxy( frontend, backend, capture: TZMQSocket );
var
  p: Pointer;
begin
  if capture <> nil then
    p := capture.SocketPtr
  else
    p := nil;
  if zmq_proxy( frontend.SocketPtr, backend.SocketPtr, p ) <> -1 then
    raise EZMQException.Create( 'Proxy does not return -1' );
  //raise EZMQException.Create;
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
    TZMQContext(contexts[i]).fTerminated := True;
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
{
  This function is called when a CTRL_C_EVENT received, important that this
  function is executed in a separate thread, because Terminate terminates the
  context, which blocks until there are open sockets.
}
function console_handler( dwCtrlType: DWORD ): BOOL;
var
  i: Integer;
begin
  if CTRL_C_EVENT = dwCtrlType then
  begin
    for i := 0 to contexts.Count - 1 do
      TZMQContext(contexts[i]).Terminate;
    result := True;
    // if I set to True than the app won't exit,
    // but it's not the solution.
    // ZMQTerminate;
  end else begin
    result := False;
  end;
end;
{$endif}

procedure ZMQTerminate;
var
  i: Integer;
begin
  for i := 0 to contexts.Count - 1 do
    TZMQContext(contexts[i]).Terminate;
  while contexts.Count > 0 do
    TZMQContext(contexts[contexts.Count-1]).Free;
end;

initialization
  {$ifdef UNIX}
  InitCriticalSection( cs );
  {$else}
  InitializeCriticalSection( cs );
  {$endif}
  contexts := TList.Create;
  {$ifdef UNIX}
  { TODO : Signal handling should normally be installed at application level, not in library }
  InstallSigHandler(SIGTERM);
  InstallSigHandler(SIGINT);
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
