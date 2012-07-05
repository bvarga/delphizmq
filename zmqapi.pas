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

interface

uses
    Classes
  , zmqcpp;

type
  TZMQFree = zmq_free_fn;
  EZMQException = zmqcpp.error_t;
  TZMQMessage = message_t;

  TZMQMessageList = class
  private
    fitems: TList;
    function getCount: Integer;
    function getItems(indx: Integer): TZMQMessage;
  protected
    procedure Add( ZMQMessage: TZMQMessage );
    procedure Delete( indx: Integer );
    property Items[indx: Integer]: TZMQMessage read getItems; default;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;


    property Count: Integer read getCount;
  end;

  TZMQContext = zmqcpp.context_t;

  TZMQSocketType = ( stPair, stPub, stSub, stReq, stRep, stDealer,
    stRouter, stPull, stPush, stXPub, stXSub );

  TZMQRecvSendFlag = ( rsfNoBlock, rsfSndMore );
  TZMQRecvSendFlags = set of TZMQRecvSendFlag;

  TZMQPollEvent = ( pePollIn, pePollOut, pePollErr );
  TZMQPollEvents = set of TZMQPollEvent;

  TZMQSocket = class( zmqcpp.socket_t )
  private
    function getSockOptInt64( option: Integer ): Int64;
    function getSockOptInteger( option: Integer ): Integer;
    procedure setSockOptInt64( option: Integer; const Value: Int64 );
    procedure setSockOptInteger( option: Integer; const Value: Integer );
  public
    constructor Create( context: TZMQContext; stype: TZMQSocketType );

    function getSocketType: TZMQSocketType;
    function getrcvMore: Boolean;
    function getHWM: Int64;
    function getRcvTimeout: Integer;
    function getSndTimeout: Integer;
    function getSwap: Int64;
    function getAffinity: Int64;
    function getIdentity: ShortString;
    function getRate: int64;
    function getRecoveryIvl: Int64;
    function getRecoveryIvlMSec: Int64;
    function getMCastLoop: Int64;
    function getSndBuf: Int64;
    function getRcvBuf: Int64;
    function getLinger: Integer;
    function getReconnectIvl: Integer;
    function getReconnectIvlMax: Integer;
    function getBacklog: Integer;
    function getFD: Pointer;
    function getEvents: TZMQPollEvents;

    procedure setHWM( const Value: Int64 );
    procedure setRcvTimeout( const Value: Integer );
    procedure setSndTimeout( const Value: Integer );
    procedure setSwap( const Value: Int64 );
    procedure setAffinity( const Value: Int64 );
    procedure setIdentity( const Value: ShortString );
    procedure setRate( const Value: int64 );
    procedure setRecoveryIvl( const Value: Int64 );
    procedure setRecoveryIvlMSec( const Value: Int64 );
    procedure setMCastLoop( const Value: Int64 );
    procedure setSndBuf( const Value: Int64 );
    procedure setRcvBuf( const Value: Int64 );
    procedure setLinger( const Value: Integer );
    procedure setReconnectIvl( const Value: Integer );
    procedure setReconnectIvlMax( const Value: Integer );
    procedure setBacklog( const Value: Integer );

    procedure Subscribe( filter: String );
    procedure unSubscribe( filter: String );


    function send( msg: TZMQMessage; flags: TZMQRecvSendFlags = [] ): Boolean; overload;

    function send( msg: Array of String; flags: TZMQRecvSendFlags = [] ): Boolean; overload;
    function send( msg: TStrings; flags: TZMQRecvSendFlags = [] ): Boolean; overload;
    function send( msg: String; flags: TZMQRecvSendFlags = [] ): Boolean; overload;

    function recv( msg: TZMQMessage; flags: TZMQRecvSendFlags = [] ): Boolean; reintroduce; overload;

    function recv( msgs: TZMQMessageList; flags: TZMQRecvSendFlags = [] ): Boolean; overload;
    function recv( msg: TStrings; flags: TZMQRecvSendFlags = [] ): Boolean; overload;
    function recv( var msg: String; flags: TZMQRecvSendFlags = [] ): Boolean; overload;

    property SocketType: TZMQSocketType read getSocketType;
    property RcvMore: Boolean read getRcvMore;
    property HWM: Int64 read getHWM write setHWM; // should be uInt64
    property RcvTimeout: Integer read getRcvTimeout write setRcvTimeout;
    property SndTimeout: Integer read getSndTimeout write setSndTimeout;
    property Swap: Int64 read getSwap write setSwap;
    property Affinity: Int64 read getAffinity write setAffinity; // should be uInt64
    property Identity: ShortString read getIdentity write setIdentity;
    property Rate: int64 read getRate write setRate;
    property RecoveryIvl: Int64 read getRecoveryIvl write setRecoveryIvl;
    property RecoveryIvlMSec: Int64 read getRecoveryIvlMSec write setRecoveryIvlMSec;
    property MCastLoop: Int64 read getMCastLoop write setMCastLoop;
    property SndBuf: Int64 read getSndBuf write setSndBuf; // should be uInt64
    property RcvBuf: Int64 read getRcvBuf write setRcvBuf; // should be uInt64
    property Linger: Integer read getLinger write setLinger;
    property ReconnectIvl: Integer read getReconnectIvl write setReconnectIvl;
    property ReconnectIvlMax: Integer read getReconnectIvlMax write setReconnectIvlMax;
    property Backlog: Integer read getBacklog write setBacklog;
    property FD: Pointer read getFD;
    property Events: TZMQPollEvents read getEvents;

  end;

  TZMQPollResult = record
    socket: TZMQSocket;
    revents: TZMQPollEvents;
  end;

  TZMQPollItem = zmq_pollitem_t;
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

  function ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket ): Integer;
  procedure ZMQVersion(var major, minor, patch: Integer);

implementation

uses
    Windows
  , zmq
  ;

{ TZMQMessageList }

constructor TZMQMessageList.Create;
begin
  fItems := TList.Create;
end;

destructor TZMQMessageList.Destroy;
begin
  Clear;
  fItems.Free;
  inherited;
end;

procedure TZMQMessageList.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
     Items[i].Free;
  fItems.Clear;
end;

function TZMQMessageList.getCount: Integer;
begin
  result := fItems.Count;
end;

function TZMQMessageList.getItems( indx: Integer ): TZMQMessage;
begin
  result := fItems[indx];
end;

procedure TZMQMessageList.Add( ZMQMessage: TZMQMessage );
begin
  fItems.Add( ZMQMessage );
end;

procedure TZMQMessageList.Delete( indx: Integer );
begin
  Items[indx].Free;
  fItems.Delete( indx );
end;

{ T0MQSocket }

constructor TZMQSocket.Create( context: TZMQContext; stype: TZMQSocketType );
begin
  inherited Create( context, Byte( stype ) );
end;

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

function TZMQSocket.getHWM: int64;
begin
  result := getSockOptInt64( ZMQ_HWM );
end;

function TZMQSocket.getRcvTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_RCVTIMEO );
end;

function TZMQSocket.getSndTimeout: Integer;
begin
  result := getSockOptInteger( ZMQ_SNDTIMEO );
end;

function TZMQSocket.getSwap: Int64;
begin
  result := getSockOptInt64( ZMQ_SWAP );
end;

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

function TZMQSocket.getRecoveryIVLMSec: Int64;
begin
  result := getSockOptInt64( ZMQ_RECOVERY_IVL_MSEC );
end;

function TZMQSocket.getMCastLoop: Int64;
begin
  result := getSockOptInt64( ZMQ_MCAST_LOOP );
end;

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

procedure TZMQSocket.setHWM( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_HWM, Value );
end;

procedure TZMQSocket.setSwap( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_SWAP, Value );
end;

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

procedure TZMQSocket.setRecoveryIvlMSec( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_RECOVERY_IVL_MSEC, Value );
end;

procedure TZMQSocket.setMCastLoop( const Value: Int64 );
begin
  setSockOptInt64( ZMQ_MCAST_LOOP, Value );
end;

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
begin
  if filter = '' then
    setSockOpt( ZMQ_SUBSCRIBE, nil, 0 )
  else
    setSockOpt( ZMQ_SUBSCRIBE, @filter[1], Length( filter ) );
end;

procedure TZMQSocket.unSubscribe( filter: String );
begin
  if filter = '' then
    setSockOpt( ZMQ_UNSUBSCRIBE, nil, 0 )
  else
    setSockOpt( ZMQ_UNSUBSCRIBE, @filter[1], Length( filter ) );
end;

function TZMQSocket.send( msg: TZMQMessage; flags: TZMQRecvSendFlags = [] ): Boolean;
begin
  result := inherited send( msg, Byte( flags ) );
end;

function TZMQSocket.send( msg: Array of String; flags: TZMQRecvSendFlags = [] ): Boolean;
var
  i,l: Integer;
  zmqMsg: TZMQMessage;
  lflags: TZMQRecvSendFlags;
begin
  Result := True;
  if Length( msg ) = 0 then
    exit;
  lflags := flags;
  Exclude( lflags, rsfSndMore );

  zmqMsg := TZMQMessage.Create( Length( msg[0] ) );
  try
    i := 0;
    l := Length( msg );
    result := true;
    while result and ( i < l ) do
    begin
      CopyMemory( zmqMsg.data, @msg[i][1], Length( msg[i] ) );
      if i = l - 1 then
      begin
        result := send( zmqMsg, lflags );
      end else
      begin
        result := send( zmqMsg, lflags + [rsfSndMore] );
        zmqMsg.rebuild( Length( msg[i+1] ));
      end;
      inc( i );
    end;
  finally
    zmqMsg.Free;
  end;
end;

function TZMQSocket.send( msg: TStrings; flags: TZMQRecvSendFlags = [] ): Boolean;
var
  sa: Array of String;
  i: Integer;
begin
  SetLength( sa, msg.Count );
  try
    for i := 0 to msg.Count - 1 do
      sa[i] := msg[i];
    result := send( sa, flags );
  finally
    sa := nil;
  end;
end;

function TZMQSocket.send( msg: String; flags: TZMQRecvSendFlags = [] ): Boolean;
begin
  result := Send( [msg], flags );
end;

function TZMQSocket.recv( msg: TZMQMessage; flags: TZMQRecvSendFlags = [] ): Boolean;
begin
  result := inherited recv( msg, Byte( flags ) );
end;

function TZMQSocket.recv( msgs: TZMQMessageList; flags: TZMQRecvSendFlags = [] ): Boolean;
var
  bRcvMore: Boolean;
  msgCount: Integer;
begin
  msgCount := 0;
  result := true;
  bRcvMore := true;
  msgs.Add( TZMQMessage.Create );
  while result and bRcvMore do
  begin
    result := recv( TZMQMessage( msgs[ msgs.count - 1 ] ), flags );
    if not result then
      msgs.Delete( msgs.count - 1 )
    else
      inc( msgCount );
    bRcvMore := rcvMore;
    if result and bRcvMore then
      msgs.Add( TZMQMessage.Create );
  end;
  if not result and ( msgCount > 0 ) then
    raise EZMQException.Create( 'Multipart message couldn''t receive all of the messages in non-blocking mode!' );
end;

function TZMQSocket.recv( msg: TStrings; flags: TZMQRecvSendFlags = [] ): Boolean;
var
  list: TZMQMessageList;
  i,isize: Integer;
  s: String;
begin
  list := TZMQMessageList.Create;
  try
    result := recv( list, flags );
    if result then
    begin
      for i := 0 to list.count - 1 do
      begin
        isize := list[i].size;
        SetLength( s, isize );
        CopyMemory( @s[1], list[i].data, isize );
        msg.Add( s );
      end;
    end;
  finally
    list.free;
  end;
end;

function TZMQSocket.recv( var msg: String; flags: TZMQRecvSendFlags = [] ): Boolean;
var
  zmqmsg: TZMQMessage;
  l: Integer;
begin
  zmqmsg := TZMQMessage.Create;
  try
    result := recv( zmqmsg, flags );
    l := zmqmsg.size;
    SetLength( msg, l );
    CopyMemory( @msg[1], zmqmsg.data, l );
  finally
    zmqmsg.Free;
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
  fPollItems[fPollItemCount].socket := socket.ptr;
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
  result := zmqcpp.poll( fPollItems[0], fPollItemCount, timeout );
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

function ZMQDevice( device: TZMQDevice; insocket, outsocket: TZMQSocket ): Integer;
begin
  result := zmqcpp.device( Ord( device ), insocket.ptr, outsocket.ptr );
end;

procedure ZMQVersion(var major, minor, patch: Integer);
begin
  zmqcpp.version( major, minor, patch );
end;

end.
