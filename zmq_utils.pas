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
unit zmq_utils;

interface

const
  libzmq = 'libzmq.dll';

{*  Helper functions are used by perf tests so that they don't have to care   *}
{*  about minutiae of time-related functions on different OS platforms.       *}

{*  Starts the stopwatch. Returns the handle to the watch.                    *}
function zmq_stopwatch: Pointer; stdcall; external libzmq;

{*  Stops the stopwatch. Returns the number of microseconds elapsed since     *}
{*  the stopwatch was started.                                                *}
function zmq_stopwatch_stop( watch: Pointer ): LongWord; stdcall; external libzmq;

{*  Sleeps for specified number of seconds.                                   *}
procedure zmq_sleep( seconds: Integer ); stdcall; external libzmq;

implementation

end.
