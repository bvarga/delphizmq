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
unit zmqcpp;

interface

uses
    SysUtils
  , Classes
  , Windows
  , zmq
  ;

type
  zmq_free_fn = free_fn;
  zmq_pollitem_t = pollitem_t;

  error_t = class( Exception )
  private
    errnum: Integer;
  public
    constructor Create; overload;
    property Num: Integer read errnum;
  end;

function poll( var items: zmq_pollitem_t; nitems: Integer; timeout: Longint = -1 ): Integer;
function device(device: Integer; insocket,outsocket: Pointer): Integer;
procedure version(var major, minor, patch: Integer);

type

  message_t = class
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
    procedure move( msg: message_t );
    procedure copy( msg: message_t );
    function data: Pointer;
    function size: size_t;
  end;

  context_t = class
  private
    fContext: Pointer;
  public
    constructor create( io_threads: Integer );
    destructor Destroy; override;
    // ZMQ_HAS_RVALUE_REFS ??? howto ???
    property ptr: Pointer read fContext;
  end;

  socket_t = class
  private
    fSocket: Pointer;
  public
    constructor Create( context: context_t; type_: Integer );
    destructor Destroy; override;
    // ZMQ_HAS_RVALUE_REFS ??? howto ???
    procedure close;
    procedure setSockOpt( option: Integer; optval: Pointer; optvallen: size_t );
    procedure getSockOpt( option: Integer; optval: Pointer; var optvallen: size_t );
    procedure bind( addr: String );
    procedure connect( addr: String );
    function send( msg: message_t; flags: Integer = 0 ): Boolean; overload;
    function recv( msg: message_t; flags: Integer = 0 ): Boolean; overload;
    property ptr: Pointer read fSocket;
  end;

implementation

const
  EAGAIN = 16;

{ error_t }

constructor error_t.Create;
begin
  errnum := zmq_errno;
  inherited Create( String( AnsiString( zmq_strerror( errnum ) ) ) );
end;

function poll( var items: zmq_pollitem_t; nitems: Integer; timeout: Longint = -1 ): Integer;
begin
  result := zmq_poll( items, nitems, timeout );
  if result < 0 then
    raise error_t.Create
end;

function device( device: Integer; insocket,outsocket: Pointer ): Integer;
begin
  result := zmq_device( device, insocket, outsocket );
  if result <> 0 then
    raise error_t.Create;
end;

procedure version( var major, minor, patch: Integer );
begin
  zmq_version( major, minor, patch );
end;


{ message_t }

constructor message_t.Create;
begin
  if zmq_msg_init( fMessage ) <> 0 then
    raise error_t.Create;
end;

constructor message_t.Create( size: size_t );
begin
  if zmq_msg_init_size( fMessage, size ) <> 0 then
    raise error_t.Create;
end;

constructor message_t.Create( data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer );
begin
  if zmq_msg_init_data( fMessage, data, size, ffn, hint ) <> 0 then
    raise error_t.Create;
end;

destructor message_t.Destroy;
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise error_t.Create;
  inherited;
end;

procedure message_t.rebuild;
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise error_t.Create;
  if zmq_msg_init( fMessage ) <> 0 then
    raise error_t.Create;
end;

procedure message_t.rebuild( size: size_t );
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise error_t.Create;
  if zmq_msg_init_size( fMessage, size ) <> 0 then
    raise error_t.Create;
end;

procedure message_t.rebuild( data: Pointer; size: size_t; ffn: free_fn; hint: Pointer = nil );
begin
  if zmq_msg_close( fMessage ) <> 0 then
    raise error_t.Create;
  if zmq_msg_init_data( fMessage, data, size, ffn, hint ) <> 0 then
    raise error_t.Create;
end;

procedure message_t.move( msg: message_t );
begin
  if zmq_msg_move( fMessage, msg.fMessage ) <> 0 then
    raise error_t.Create;
end;

procedure message_t.copy( msg: message_t );
begin
  if zmq_msg_copy( fMessage, msg.fMessage ) <> 0 then
    Raise error_t.Create;
end;

function message_t.data: Pointer;
begin
  result := zmq_msg_data( fMessage );
end;

function message_t.size: size_t;
begin
 result := zmq_msg_size( fMessage );
end;

{ context_t }

constructor context_t.create( io_threads: Integer );
begin
  fContext := zmq_init( io_threads );
  if fContext = nil then
    raise error_t.Create;
end;

destructor context_t.destroy;
begin
  if zmq_term( fContext ) <> 0 then
    raise error_t.Create;
  inherited;
end;

{ socket_t }

constructor socket_t.Create( context: context_t; type_: Integer );
begin
  fSocket := zmq_socket( context.ptr, type_ );
  if fSocket = nil then
    raise error_t.Create;
end;

destructor socket_t.destroy;
begin
  close;
  inherited;
end;

procedure socket_t.close;
begin
  if ptr = nil then
    exit;
  if zmq_close( ptr ) <> 0 then
    raise error_t.Create;
  fSocket := nil;
end;

procedure socket_t.setSockOpt( option: Integer; optval: Pointer;
  optvallen: size_t );
begin
  if zmq_setsockopt( ptr, option, optval, optvallen ) <> 0 then
    raise error_t.Create;
end;

procedure socket_t.getSockOpt( option: Integer; optval: Pointer; var optvallen: size_t );
begin
  if zmq_getsockopt( ptr, option, optval, optvallen ) <> 0 then
    raise error_t.Create;
end;

procedure socket_t.bind( addr: String );
begin
  if zmq_bind( ptr, PAnsiChar( AnsiString( addr ) ) ) <> 0 then
    raise error_t.Create;
end;

procedure socket_t.connect( addr: String );
begin
  if zmq_connect( ptr, PAnsiChar( AnsiString( addr ) ) ) <> 0 then
    raise error_t.Create;
end;

function socket_t.send( msg: message_t; flags: Integer = 0 ): Boolean;
begin
  // The zmq_send() function shall return zero if successful. Otherwise it
  // shall return -1 and set errno to one of the values defined below
  if zmq_send( ptr, msg.fMessage, flags ) = 0 then
    result := true
  else
  if zmq_errno = EAGAIN then
    result := false
  else
    raise error_t.Create;
end;

function socket_t.recv( msg: message_t; flags: Integer = 0 ): Boolean;
begin
  // The zmq_send() function shall return zero if successful. Otherwise it
  // shall return -1 and set errno to one of the values defined below
  if zmq_recv( ptr, msg.fMessage, flags ) = 0 then
    result := true
  else
  if zmq_errno = EAGAIN then
    result := false
  else
    raise error_t.Create;
end;

end.
