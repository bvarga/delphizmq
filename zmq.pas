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
unit zmq;

{$ifdef UNIX}
  {$linklib pthread}
{$endif}

{$I zmq.inc}

interface

{$ifdef FPC}
uses
  ctypes;
{$endif}

const
  {$ifdef UNIX}
  libzmq = 'libzmq.so';
  {$else}
  libzmq = 'libzmq.dll';
  {$endif}

{  Run-time API version detection                                              }
procedure zmq_version( var major, minor, patch: Integer ); cdecl; external libzmq;

{******************************************************************************}
{*  0MQ errors.                                                               *}
{******************************************************************************}

{*  A number random enough not to collide with different errno ranges on      *}
{*  different OSes. The assumption is that error_t is at least 32-bit type.   *}
const
  ZMQ_HAUSNUMERO = 156384712;

{*  On Windows platform some of the standard POSIX errnos are not defined.    *}
  ENOTSUP = (ZMQ_HAUSNUMERO + 1);
  EPROTONOSUPPORT = (ZMQ_HAUSNUMERO + 2);
  ENOBUFS = (ZMQ_HAUSNUMERO + 3);
  ENETDOWN = (ZMQ_HAUSNUMERO + 4);
  EADDRINUSE = (ZMQ_HAUSNUMERO + 5);
  EADDRNOTAVAIL = (ZMQ_HAUSNUMERO + 6);
  ECONNREFUSED = (ZMQ_HAUSNUMERO + 7);
  EINPROGRESS = (ZMQ_HAUSNUMERO + 8);
  ENOTSOCK = (ZMQ_HAUSNUMERO + 9);
  EMSGSIZE = (ZMQ_HAUSNUMERO + 10);
  EAFNOSUPPORT = (ZMQ_HAUSNUMERO + 11);
  ENETUNREACH = (ZMQ_HAUSNUMERO + 12);
  ECONNABORTED = (ZMQ_HAUSNUMERO + 13);
  ECONNRESET = (ZMQ_HAUSNUMERO + 14);
  ENOTCONN = (ZMQ_HAUSNUMERO + 15);
  ETIMEDOUT = (ZMQ_HAUSNUMERO + 16);
  EHOSTUNREACH = (ZMQ_HAUSNUMERO + 17);
  ENETRESET = (ZMQ_HAUSNUMERO + 18);

{*  Native 0MQ error codes.                                                   *}
  EFSM = (ZMQ_HAUSNUMERO + 51);
  ENOCOMPATPROTO = (ZMQ_HAUSNUMERO + 52);
  ETERM = (ZMQ_HAUSNUMERO + 53);
  EMTHREAD = (ZMQ_HAUSNUMERO + 54);

{*  This function retrieves the errno as it is known to 0MQ library. The goal *}
{*  of this function is to make the code 100% portable, including where 0MQ   *}
{*  compiled with certain CRT library (on Windows) is linked to an            *}
{*  application that uses different CRT library.                              *}
function zmq_errno: Integer; cdecl; external libzmq;

{*  Resolves system errors and 0MQ errors to human-readable string.           *}
function zmq_strerror(errnum: Integer):PAnsiChar; cdecl; external libzmq;

{******************************************************************************}
{*  0MQ infrastructure (a.k.a. context) initialisation & termination.         *}
{******************************************************************************}

{$ifdef zmq3}
{*  New API                                                                   *}
{*  Context options                                                           *}
const
  ZMQ_IO_THREADS = 1;
  ZMQ_MAX_SOCKETS = 2;

{*  Default for new contexts                                                  *}
  ZMQ_IO_THREADS_DFLT = 1;
  ZMQ_MAX_SOCKETS_DFLT = 1024;

function zmq_ctx_new: Pointer; cdecl; external libzmq;
function zmq_ctx_destroy( context: Pointer ): Integer; cdecl; external libzmq;
function zmq_ctx_set( context: Pointer; option: Integer; optval: Integer ): Integer; cdecl; external libzmq;
function zmq_ctx_get( context: Pointer; option: Integer ): Integer; cdecl; external libzmq;
{$endif}

{*  Old (legacy) API                                                          *}
function zmq_init(io_threads: Integer): Pointer; cdecl; external libzmq;
function zmq_term(context: Pointer): Integer; cdecl; external libzmq;

{******************************************************************************}
{*  0MQ message definition.                                                   *}
{******************************************************************************}

{$ifdef zmq3}

type
  zmq_msg_t = record
    _: Array[0..32-1] of Byte;
  end;

{$else}

{*  Maximal size of "Very Small Message". VSMs are passed by value            *}
{*  to avoid excessive memory allocation/deallocation.                        *}
{*  If VMSs larger than 255 bytes are required, type of 'vsm_size'            *}
{*  field in zmq_msg_t structure should be modified accordingly.              *}
const
  ZMQ_MAX_VSM_SIZE = 30;

{*  Message types. These integers may be stored in 'content' member of the    *}
{*  message instead of regular pointer to the data.                           *}
  ZMQ_DELIMITER = 31;
  ZMQ_VSM = 32;

{*  Message flags. ZMQ_MSG_SHARED is strictly speaking not a message flag     *}
{*  (it has no equivalent in the wire format), however, making  it a flag     *}
{*  allows us to pack the stucture tigher and thus improve performance.       *}
  ZMQ_MSG_MORE = 1;
  ZMQ_MSG_SHARED = 128;
  ZMQ_MSG_MASK = 129; {* Merges all the flags *}

{*  A message. Note that 'content' is not a pointer to the raw data.          *}
{*  Rather it is pointer to zmq::msg_content_t structure                      *}
{*  (see src/msg_content.hpp for its definition).                             *}

type
  zmq_msg_t = record
    content: Pointer;
    flags: Byte;
    vsm_size: Byte;
    vsm_data: Array[0..ZMQ_MAX_VSM_SIZE-1] of Byte;
  end;

{$endif}

  free_fn = procedure(data, hint: Pointer);

{$ifdef FPC}  
  size_t = clong;
{$else}
  size_t = Cardinal;
{$endif}

function zmq_msg_init( var msg: zmq_msg_t ): Integer; cdecl; external libzmq;
function zmq_msg_init_size( var msg: zmq_msg_t; size: size_t ): Integer; cdecl; external libzmq;
function zmq_msg_init_data( var msg: zmq_msg_t; data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer ): Integer; cdecl; external libzmq;

function zmq_msg_close(var msg: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_move(dest, src: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_copy(dest, src: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_data(var msg: zmq_msg_t): Pointer; cdecl; external libzmq;
function zmq_msg_size(var msg: zmq_msg_t): size_t; cdecl; external libzmq;

{$ifdef zmq3}
function zmq_msg_more (var msg: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_get (var msg: zmq_msg_t; option: Integer): Integer; cdecl; external libzmq;
function zmq_msg_set (var msg: zmq_msg_t; option: Integer; optval: Integer): Integer; cdecl; external libzmq;
function zmq_msg_send (var msg: zmq_msg_t; s: Pointer; flags: Integer): Integer; cdecl; external libzmq;
function zmq_msg_recv (var msg: zmq_msg_t; s: Pointer; flags: Integer): Integer; cdecl; external libzmq;
{$endif}
{******************************************************************************}
{*  0MQ socket definition.                                                    *}
{******************************************************************************}

{*  Socket types.                                                             *}
const
  ZMQ_PAIR = 0;
  ZMQ_PUB = 1;
  ZMQ_SUB = 2;
  ZMQ_REQ = 3;
  ZMQ_REP = 4;
  ZMQ_DEALER = 5;
  ZMQ_ROUTER = 6;
  ZMQ_PULL = 7;
  ZMQ_PUSH = 8;
  ZMQ_XPUB = 9;
  ZMQ_XSUB = 10;
  ZMQ_XREQ = ZMQ_DEALER;           {*  Old alias, remove in 3.x               *}
  ZMQ_XREP = ZMQ_ROUTER;           {*  Old alias, remove in 3.x               *}
{$ifndef zmq3}
  ZMQ_UPSTREAM = ZMQ_PULL;         {*  Old alias, remove in 3.x               *}
  ZMQ_DOWNSTREAM = ZMQ_PUSH;       {*  Old alias, remove in 3.x               *}
{$endif}

{*  Socket options.                                                           *}

{$ifndef zmq3}
  ZMQ_HWM = 1;
  ZMQ_SWAP = 3;
{$endif}
  ZMQ_AFFINITY = 4;
  ZMQ_IDENTITY = 5;
  ZMQ_SUBSCRIBE = 6;
  ZMQ_UNSUBSCRIBE = 7;
  ZMQ_RATE = 8;
  ZMQ_RECOVERY_IVL = 9;
{$ifndef zmq3}
  ZMQ_MCAST_LOOP = 10;
{$endif}
  ZMQ_SNDBUF = 11;
  ZMQ_RCVBUF = 12;
  ZMQ_RCVMORE = 13;
  ZMQ_FD = 14;
  ZMQ_EVENTS = 15;
  ZMQ_TYPE = 16;
  ZMQ_LINGER = 17;
  ZMQ_RECONNECT_IVL = 18;
  ZMQ_BACKLOG = 19;
{$ifndef zmq3}
  ZMQ_RECOVERY_IVL_MSEC = 20;      {*  opt. recovery time, reconcile in 3.x   *}
{$endif}
  ZMQ_RECONNECT_IVL_MAX = 21;
{$ifdef zmq3}
  ZMQ_MAXMSGSIZE = 22;
  ZMQ_SNDHWM = 23;
  ZMQ_RCVHWM = 24;
  ZMQ_MULTICAST_HOPS = 25;
{$endif}
  ZMQ_RCVTIMEO = 27;
  ZMQ_SNDTIMEO = 28;
{$ifdef zmq3}
  ZMQ_IPV4ONLY = 31;
  ZMQ_LAST_ENDPOINT = 32;
  ZMQ_ROUTER_MANDATORY = 33;
  ZMQ_TCP_KEEPALIVE = 34;
  ZMQ_TCP_KEEPALIVE_CNT = 35;
  ZMQ_TCP_KEEPALIVE_IDLE = 36;
  ZMQ_TCP_KEEPALIVE_INTVL = 37;
  ZMQ_TCP_ACCEPT_FILTER = 38;
  ZMQ_DELAY_ATTACH_ON_CONNECT = 39;
  ZMQ_XPUB_VERBOSE = 40;

{*  Message options                                                           *}
  ZMQ_MORE = 1;
{$endif}

{*  Send/recv options.                                                        *}
{$ifdef zmq3}
  ZMQ_DONTWAIT = 1;
{$else}
  ZMQ_NOBLOCK = 1;
{$endif}
  ZMQ_SNDMORE = 2;

{$ifdef zmq3}
{******************************************************************************}
{*  0MQ socket events and monitoring                                          *}
{******************************************************************************}

{*  Socket transport events (tcp and ipc only)                                *}
  ZMQ_EVENT_CONNECTED = 1;
  ZMQ_EVENT_CONNECT_DELAYED = 2;
  ZMQ_EVENT_CONNECT_RETRIED = 4;

  ZMQ_EVENT_LISTENING = 8;
  ZMQ_EVENT_BIND_FAILED = 16;

  ZMQ_EVENT_ACCEPTED = 32;
  ZMQ_EVENT_ACCEPT_FAILED = 64;

  ZMQ_EVENT_CLOSED = 128;
  ZMQ_EVENT_CLOSE_FAILED = 256;
  ZMQ_EVENT_DISCONNECTED =512;

  ZMQ_EVENT_ALL =
    ZMQ_EVENT_CONNECTED or
    ZMQ_EVENT_CONNECT_DELAYED or
    ZMQ_EVENT_CONNECT_RETRIED or
    ZMQ_EVENT_LISTENING or
    ZMQ_EVENT_BIND_FAILED or
    ZMQ_EVENT_ACCEPTED or
    ZMQ_EVENT_ACCEPT_FAILED or
    ZMQ_EVENT_CLOSED or
    ZMQ_EVENT_CLOSE_FAILED or
    ZMQ_EVENT_DISCONNECTED;

{*  Socket event data (union member per event)                                *}
type
  zmq_event_t = record
    event: Integer;
    addr: PAnsiChar;
    case Integer of
      0, // connected
      3, // listening
      5, // accepted
      7, // closed
      9: // disconnected
        (
        fd: Integer;
        );
      1, // connect_delayed
      4, // bind_failed
      6, // accept_failed
      8: // close_failed
        (
        err: Integer;
        );
      2: ( //connect_retried
        interval: Integer;
        );
  end;

{$endif}

function zmq_socket(context: Pointer; stype: Integer): Pointer; cdecl; external libzmq;
function zmq_close(s: Pointer): Integer; cdecl; external libzmq;
function zmq_setsockopt(s: Pointer; option: Integer; optval: Pointer; optvallen: size_t ): Integer; cdecl; external libzmq;
function zmq_getsockopt(s: Pointer; option: Integer; optval: Pointer; var optvallen: size_t): Integer; cdecl; external libzmq;
function zmq_bind(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
function zmq_connect(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
{$ifdef zmq3}
function zmq_unbind(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
function zmq_disconnect(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
{$endif}

{$ifdef zmq3}
function zmq_send (s: Pointer; const buffer; len: size_t; flags: Integer): Integer; cdecl; external libzmq;
function zmq_recv (s: Pointer; var buffer; len: size_t; flags: Integer): Integer; cdecl; external libzmq;
{$else}
function zmq_send (s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;
function zmq_recv (s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;
{$endif}

{$ifdef zmq3}
function zmq_sendmsg(s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;
function zmq_recvmsg(s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;

function zmq_socket_monitor( s: Pointer; addr: PAnsiChar; events: Integer ): Integer; cdecl; external libzmq;

{
/*  Experimental                                                              */
struct iovec;

ZMQ_EXPORT int zmq_sendiov (void *s, struct iovec *iov, size_t count, int flags);
ZMQ_EXPORT int zmq_recviov (void *s, struct iovec *iov, size_t *count, int flags);
}
{$endif}

{******************************************************************************}
{*  I/O multiplexing.                                                         *}
{******************************************************************************}
const
  ZMQ_POLLIN = 1;
  ZMQ_POLLOUT = 2;
  ZMQ_POLLERR = 4;

type
  pollitem_t = record
    socket: Pointer;
    fd: Integer; // TSocket???
    events: Word;
    revents: Word;
  end;

function zmq_poll( var items: pollitem_t; nitems: Integer; timeout: Longint ): Integer; cdecl; external libzmq;

{******************************************************************************}
{*  Built-in devices                                                          *}
{******************************************************************************}

{$ifdef zmq3}
{*  Built-in message proxy (3-way) *}
function zmq_proxy( frontend, backend, capture: Pointer ): Integer; cdecl; external libzmq;

{$endif}
{*  Deprecated aliases *}
const
  ZMQ_STREAMER = 1;
  ZMQ_FORWARDER = 2;
  ZMQ_QUEUE = 3;
  
{*  Deprecated method *}
function zmq_device(device: Integer; insocket,outsocket: Pointer): Integer; cdecl; external libzmq;

{*  Helper functions are used by perf tests so that they don't have to care   *}
{*  about minutiae of time-related functions on different OS platforms.       *}

{*  Starts the stopwatch. Returns the handle to the watch.                    *}
function zmq_stopwatch_start: Pointer; stdcall; external libzmq;

{*  Stops the stopwatch. Returns the number of microseconds elapsed since     *}
{*  the stopwatch was started.                                                *}
function zmq_stopwatch_stop( watch: Pointer ): LongWord; stdcall; external libzmq;

{*  Sleeps for specified number of seconds.                                   *}
procedure zmq_sleep( seconds: Integer ); stdcall; external libzmq;

implementation

end.
