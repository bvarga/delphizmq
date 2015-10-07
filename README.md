0MQ Binding for Delphi
======================

This is a binding for [ZMQ](http://www.zeromq.org). Should work with Delphi7+ versions and with FPC 2.6.0.

General
=======

The package contains a wrapper (zmq.pas), and a higher level api (zmqapi.pas).
It should work with ZMQ 2.2.x, and with 3.2.x. For version 2.2.x undefine zmq3, in
zmq.inc. The dll's are not part of this repo, you can download the appropriate from
[the official distro](http://www.zeromq.org/intro:get-the-software), and rename it
to `libzmq.dll`.

This is a work in progress, please open an issue if you find bugs, or have question,
or proposal.

Usage
=====

You should use the higher level api, which'll save you a lot of time, and incidentally
the code'll be easier to read.

First, you need to create a context

```delphi
context := TZMQContext.Create;
```

There are various socket types, see the [Guide](http://zguide.zeromq.org), each has a
constant. To create for example a REP socket, just write this:

```delphi
socket := context.Socket( stRep );

// binding the socket
socket.bind( 'tcp://*:5555' );

// connecting the socket
socket.connect( 'tcp://localhost:5555' );
```

To send messages the api has several methods. You can send single, or Multipart messages,
in blocking or nonblocking (in the v3 it's called dontwait) mode.

```delphi
// sending a Utf8String in blocking mode(default) is just as easy as this:
socket.send( 'Hello' );

// or in non-blocking mode
socket.send( 'Hello', [rsfNoBlock] );
// in this case if the message cannot be queued an EZMQException is raised,
// with a value EAGAIN.

// sending data from a stream (don't forget to set the position of the stream, to read to)
socket.send( stream, size );

// sending multipart messages.
// Utf8Strings:
socket.send( ['Hello','World'] );

//this is equivalent to:
socket.send( 'Hello', [rsfSndMore] );
socket.send( 'World' );

// or use TStrings. TString.Strings interpreted as Utf8Strings!
tsl := TStringList.Create;
tsl.Add( 'Hello' );
tsl.Add( 'World' );
socket.send( tsl );
tsl.Free;
```

Receiving messages is as easy as

```delphi
msize := socket.recv( msg );
// the new message is in the msg, and msize holds the length of the message

// to a Stream
msize := socket.recv( stream );

// read multipart message
tsl := TStringList.Create;
mcount := socket.recv( tsl );
// this will add message parts to the stringlist, and returns
// the count of the messages received.
```

**CTRL+C Handling**

it's a bit tricky. On windows signal handling is different, than in posix systems.
Blocking calls won't receive SIGINT, just block continuously. To overcome this issue,
the installed handler terminates the contexts, so blocking calls like `recv`, `poll`,
etc... will receive `ETERM`. It's just on Windows.

if you code your infinite loops like this, you can terminate cleanly.

```delphi
while not context.Terminated do
try
  socket.recv( msg );
except
  // handle exception, or
  context.Terminate;
  // if CTRL+C was pressed, on windows the context already
  // terminated
end;
```

    context.Free;

**Polling**

Polling can work in two different ways, let's call the first
_synchronous_, the second _asynchronous_ way. The _asynchronous_
version creates a thread, and do the polling there.

  - synchronous

	```delphi
	// create context
	context := TZMQContext.Create;
	socket := context.Socket( stDealer );
	socket.connect( address );

	// Create the poller. The `true` parameter tells
	// the poller to use synchronous polling
	poller := TZMQPoller.Create( true );

	// register the socket.
	poller.register( socket, [pePollIn] );
	
	timeout := 100; // 100ms
	while not context.Terminated do
	begin
	  rc := poller.poll(timeout);
	  if rc > 0 then
		do something...
	end;
	
	poller.Free;
	socket.Free;
	context.Free;
	```

  - asynchronous way

	This implementation uses a kind of reactor pattern, the poller
	starts a new thread , and creates a pair socket connection
	between the class and the created thread. So this poller
	implementation is not thread safe, don't register, deregister
	sockets in different threads.

	```delphi
	procedure TMyClass.pollerEvent( socket: TZMQSocket; event: TZMQPollEvents );
	  begin
		do something...
	  end;
	
	// create context.
	context := TZMQContext.Create;

	socket := context.Socket( stDealer );
	socket.connect( address );

	// create the poller. the second parameter can be nil, than
	// the poller creates it's own context.
	poller := TZMQPoller.Create( false, context );

	poller.onEvent := pollerEvent;

	// register the socket. If the third parameter is true,
	// than the register block until the socket is registered.
	poller.register( socket, [pePollIn], false );
	```

Monitoring Sockets ( just available in `v3.2.2`)

```delphi
// define a callback like this.
procedure TMyClass.MonitorCallback( event: TZMQEvent );
begin
  // do something.
end;

// Register the callback
socket.RegisterMonitor( MonitorCallback, cZMQMonitorEventsAll );

// The `MonitorCallback` is called from a separate thread,
// created by `RegisterMonitor`

// you can deregister the monitoring with calling.
socket.DeRegisterMonitor;
```

**Threads**

  Similar to the czmq api. this binding also supports attached and detached thread creation.
  There are two ways to use this class, call the `CreateDetached` or `CreateAttached` constructors,
  with parameters, or create your own descendent class and override the `DoExecute` method.

  - Creating a detached thread.

    ```delphi
	procedure TMyClass.DetachedMeth( args: Pointer; context: TZMQContext );
	var
	  socket: TZMQSocket;
	begin
	  socket := context.Socket( TZMQSocketType( Args^ ) );
	  Dispose( args );
	end;
	
	var
	  thr: TZMQThread;
	  sockettype: ^TZMQSocketType;
	begin
	  New( sockettype );
	  sockettype^ := stDealer;
	  thr := TZMQThread.CreateDetached( DetachedMeth, sockettype );
	  thr.FreeOnTerminate := true;
	  thr.Resume;
	end;
	```

  - or

  	```delphi
	// create descendant class
	TMyZMQThread = class( TZMQThread )
	protected
	  procedure doExecute; override;
	end;
	
	procedure TMyZMQThread.doExecute
	var
	  socket: TZMQSocket;
	begin
	  // do something cool.
	  socket := Context.socket( TZMQSocketType(Args^) );
	end;
	
	var
	  myThread: TMyZMQThread;
	  sockettype: ^TZMQSocketType;
	begin
	  New( sockettype );
	  sockettype^ := stDealer;
	
	  // the nil context means it will be a detached thread.
	  myThread := TMyZMQThread.Create( sockettype, nil );
	  myThread.Resume;
	end;
	```

  - Creating an attached thread.

	```delphi
	procedure TMyClass.AttachedMeth( args: Pointer; context: TZMQContext; pipe: TZMQSocket );
	var
	  socket: TZMQSocket;
	  msg: Utf8String;
	begin
	  while not context.Terminated do
	  begin
		// do some cool stuff.
		socket := Context.socket( TZMQSocketType(Args^) );
		
		// you can use pipe to communicate.
		pipe.recv( msg );
	  end;
	end;
	
	var
	  thr: TZMQThread;
	  sockettype: ^TZMQSocketType;
	begin
	  New( sockettype );
	  sockettype^ := stDealer;
	  thr := TZMQThread.CreateAttached( AttachedMeth, context, sockettype );
	  thr.FreeOnTerminate := true;
	  thr.Resume;

	
	  // use thr.pipe to send stuff to the thread.
	  thr.pipe.send( 'hello thread' );
	end;
	```
  - or

	```delphi
	// create descendant class
	TMyZMQThread = class( TZMQThread )
	protected
	  procedure doExecute; override;
	end;
	
	procedure TMyZMQThread.doExecute
	var
	  socket: TZMQSocket;
	  msg: Utf8String;
	begin
	  // do something cool.
	  socket := Context.socket( TZMQSocketType(Args^) );
	  while true do
	  begin
		pipe.recv( msg );
	  end;
	end;
	
	var
	  myThread: TMyZMQThread;
	  sockettype: ^TZMQSocketType;
	begin
	  New( sockettype );
	  sockettype^ := stDealer;

	  myThread := TMyZMQThread.Create( sockettype, context )
	  myThread.Resume;
	
	  myThread.pipe.send( 'Hello thread' );
	end;
	```

Examples
========

examples are in the [zguide](https://github.com/bvarga/zguide) `examples/Delphi` folder.

Changes
=======
* TZMQThread class
* Fixed bug in context.Destroy
* New poller class
* poll function of TZMQPoller has a new optional parameter "pollCount".
* Upgrade dll-s to v3.2.2 RC2
* New monitoring logic implemented.
* Default ZMQ version for the binding is now 3.2 ( can switch back to 2.2 by not defining `zmq3` in the `zmq.inc` file )

Authors
=======

The following people have contributed to the project:

    Balazs Varga <bb.varga@gmail.com>
    Stathis Gkotsis <stathis.gkotsis@gmail.com>
    Stephane Carre <scarre.lu@gmail.com>

Copying
=======

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPL). For details see the files `COPYING.LESSER` included with
the distribution.
