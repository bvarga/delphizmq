0MQ Binding for Delphi
======================

This is a binding for [ZMQ](http://www.zeromq.org). Tested with Delphi7, BDS2006, and 
FPC 2.6.0. (Just in Windows for now). 

General
=======

The package contains a wrapper (zmq.pas) for the dll, and a higher level api (zmqapi.pas). 
It should work with ZMQ 2.2.0, and with 3.2.0 rc1 (experimental). To use the v3.2 dll, in
zmq.inc define zmq3 (($define zmq3}). The dll's come from the 
[official distro](http://www.zeromq.org/intro:get-the-software) 

Usage
=====

You should use the higher level api, which'll save you a lot of time, and incidentally 
the code'll be easier to read.

First, you need to create a context

    context := TZMQContext.Create; 
    
There are various socket types, see the [Guide](http://zguide.zeromq.org), each has a 
constant. To create for example a REP socket, just write this:

    socket := context.Socket( stRep );
    
    // binding the socket
    socket.bind( 'tcp://*:5555' );
    
    // connecting the socket
    socket.connect( 'tcp://localhost:5555' );
    
To send messages the api has several methods. You can send single, or Multipart messages,
in blocking or nonblocking (in the v3 it's called dontwait) mode.
    
    // sending a string in blocking mode(default) is just as easy as this:
    socket.send( 'Hello' );
    
    // or in non-blocking mode
    socket.send( 'Hello', [rsfNoBlock] );
    // in this case if the message cannot be queued an EZMQException is raised,
    // with a value EAGAIN.
    
    // sending data from a stream (don't forget to set the position of the stream, to read to)
    socket.send( stream, size );
    
    // sending multipart messages.
    // strings:
    socket.send( ['Hello','World'] );
    
    //this is equivalent to:
    socket.send( 'Hello', [rsfSndMore] );
    socket.send( 'World' );
    
    // or use TStrings.
    tsl := TStringList.Create;
    tsl.Add( 'Hello' );
    tsl.Add( 'World' );
    socket.send( tsl );
    tsl.Free;
      
Receiving messages is as easy as

    msize := socket.recv( msg );
    // the new message is in the msg, and msize holds the length of the message
    
    // to a Stream
    msize := socket.recv( stream );
    
    // read multipart message
    tsl := TStringList.Create;
    mcount := socket.recv( tsl );
    // this will add message parts to the stringlist, and returns
    // the count of the messages received.

Monitoring Sockets ( just available in `v3.2`)

    // define a callback like this.
    procedure TMyClass.MonitorCallback( event: TZMQEvent );
    begin
      // do something.
    end;
    
    // Register the callback
    socket.RegisterMonitor( MonitorCallback, cZMQMonitorEventsAll );
    
    // The `MonitorCallback` is called from a separate thread, created by `RegisterMonitor`
    
    // you can deregister the monitoring with calling.
    socket.DeRegisterMonitor; 

    
Examples
========

in the examples directory there are some examples translated from the guide.

Changes
=======
* poll function of TZMQPoller has a new optional parameter "pollCount".
  

* Upgrade dll-s to v3.2.2 RC2
* New monitoring logic implemented.
* Default ZMQ version for the binding is now 3.2 ( can switch back to 2.2 by not defining `zmq3` in the `zmq.inc` file )


TODO
====

* if poll returns ETERM the socket with the terminated context should be 
  removed from the poll, and closed;
* zmq_stopwatch_stop returns the correct value, but on program exit there's 
  an exception.
* if recv(string) recieves not a valid string ,but a binary data convert it 
  to Hex.(not trivial, because String definition changes through delphi versions)
  (the identity.dpr is a test case)
* Decide the need of the zhelpers.h
* beter CTRL+C handling
* improve lruqueue2.dpr ( in client task CTRL+C handling)

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