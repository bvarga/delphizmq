program identity;
//
//  Demonstrate identities as used by the request-reply pattern.  Run this
//  program by itself.  Note that the utility functions s_ are provided by
//  zhelpers.h.  It gets boring for everyone to keep repeating this code.
//

{$APPTYPE CONSOLE}

uses
    Classes
  , SysUtils
  , zmqapi
  ;
var context: TZMQContext;
    sink
  , anonymous
  , identified: TZMQSocket;
    msg: TStringList;
begin
  context := TZMQContext.create;
  sink := context.Socket( stRouter );
  sink.bind( 'inproc://example' );

  //  First allow 0MQ to set the identity
  anonymous := context.Socket( stReq );
  anonymous.connect( 'inproc://example' );
  anonymous.send( 'ROUTER uses a generated UUID' );

  sink.dump;

  //  Then set the identity ourself
  identified := context.Socket( stReq );
  identified.Identity := 'Hello';
  identified.connect( 'inproc://example' );
  identified.send( 'ROUTER socket uses REQ''s socket identity' );

  sink.dump;

  sink.Free;
  anonymous.Free;
  identified.Free;
  context.Free;
end.

