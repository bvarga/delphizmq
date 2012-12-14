program rtpapa;
//
//  Custom routing Router to Papa (ROUTER to REP)
//

{$APPTYPE CONSOLE}

uses
    SysUtils
  , zmqapi
  ;

var
    context: TZMQContext;
    client
  , worker: TZMQSocket;
begin
  //  We will do this all in one thread to emphasize the sequence
  //  of events…
  context := TZMQContext.create;
  client := context.Socket( stRouter );
  client.bind( 'tcp://127.0.0.1:5555' );

  worker := context.Socket( stRep );
  worker.Identity := 'A';
  worker.connect( 'tcp://127.0.0.1:5555' );

  //  Wait for the worker to connect so that when we send a message
  //  with routing envelope, it will actually match the worker…
  sleep( 10 );

  //  Send papa address, address stack, empty part, and request
  client.send([
    'A',
    'address 3',
    'address 2',
    'address 1',
    '',
    'This is the workload'
  ]);

  //  Worker should get just the workload
  //worker.dump; [todo]

  //  We don't play with envelopes in the worker
  worker.send( 'This is the reply' );

  //  Now dump what we got off the ROUTER socket…
  //client.dump; [todo]

  client.Free;
  worker.Free;
  context.Free;
end.
