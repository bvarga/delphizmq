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

interface

const
  libzmq = 'libzmq.dll';

{  Run-time API version detection                                              }
procedure zmq_version(var major, minor, patch: Integer); cdecl; external libzmq;


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
{*  0MQ message definition.                                                   *}
{******************************************************************************}

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

  free_fn = procedure(data, hint: Pointer);

  size_t = Cardinal;
  
function zmq_msg_init( var msg: zmq_msg_t ): Integer; cdecl; external libzmq;
function zmq_msg_init_size( var msg: zmq_msg_t; size: size_t ): Integer; cdecl; external libzmq;
function zmq_msg_init_data( var msg: zmq_msg_t; data: Pointer; size: size_t;
  ffn: free_fn; hint: Pointer ): Integer; cdecl; external libzmq;
function zmq_msg_close(var msg: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_move(dest, src: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_copy(dest, src: zmq_msg_t): Integer; cdecl; external libzmq;
function zmq_msg_data(var msg: zmq_msg_t): Pointer; cdecl; external libzmq;
function zmq_msg_size(var msg: zmq_msg_t): size_t; cdecl; external libzmq;

{******************************************************************************}
{*  0MQ infrastructure (a.k.a. context) initialisation & termination.         *}
{******************************************************************************}

function zmq_init(io_threads: Integer): Pointer; cdecl; external libzmq;
function zmq_term(context: Pointer): Integer; cdecl; external libzmq;

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
  ZMQ_UPSTREAM = ZMQ_PULL;         {*  Old alias, remove in 3.x               *}
  ZMQ_DOWNSTREAM = ZMQ_PUSH;       {*  Old alias, remove in 3.x               *}

{*  Socket options.                                                           *}
  ZMQ_HWM = 1;
  ZMQ_SWAP = 3;
  ZMQ_AFFINITY = 4;
  ZMQ_IDENTITY = 5;
  ZMQ_SUBSCRIBE = 6;
  ZMQ_UNSUBSCRIBE = 7;
  ZMQ_RATE = 8;
  ZMQ_RECOVERY_IVL = 9;
  ZMQ_MCAST_LOOP = 10;
  ZMQ_SNDBUF = 11;
  ZMQ_RCVBUF = 12;
  ZMQ_RCVMORE = 13;
  ZMQ_FD = 14;
  ZMQ_EVENTS = 15;
  ZMQ_TYPE = 16;
  ZMQ_LINGER = 17;
  ZMQ_RECONNECT_IVL = 18;
  ZMQ_BACKLOG = 19;
  ZMQ_RECOVERY_IVL_MSEC = 20;      {*  opt. recovery time, reconcile in 3.x   *}
  ZMQ_RECONNECT_IVL_MAX = 21;
  ZMQ_RCVTIMEO = 27;
  ZMQ_SNDTIMEO = 28;

{*  Send/recv options.                                                        *}
  ZMQ_NOBLOCK = 1;
  ZMQ_SNDMORE = 2;

function zmq_socket(context: Pointer; stype: Integer): Pointer; cdecl; external libzmq;
function zmq_close(s: Pointer): Integer; cdecl; external libzmq;
function zmq_setsockopt(s: Pointer; option: Integer; optval: Pointer; optvallen: size_t ): Integer; cdecl; external libzmq;
function zmq_getsockopt(s: Pointer; option: Integer; optval: Pointer; var optvallen: Cardinal): Integer; cdecl; external libzmq;
function zmq_bind(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
function zmq_connect(s: Pointer; addr: PAnsiChar): Integer; cdecl; external libzmq;
function zmq_send (s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;
function zmq_recv (s: Pointer; var msg: zmq_msg_t; flags: Integer): Integer; cdecl; external libzmq;

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
const
  ZMQ_STREAMER = 1;
  ZMQ_FORWARDER = 2;
  ZMQ_QUEUE = 3;

function zmq_device(device: Integer; insocket,outsocket: Pointer): Integer; cdecl; external libzmq;

implementation

end.