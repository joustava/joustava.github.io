---
title: 'Exploring IoT with Node.js'
#abbrlink: 30386
---

I've been toying a while with the idea to create a small IoT network for personal use as I own several
Onion Omegas, Raspberry Pi's and a few boxes of electronics and sensors with which I might be able to create interesting use cases. Lately I also acquired a couple of Hue Lamps (and a bridge) and on top of that found out that the apartment I live in at the moment has window shutters that might also be controlable via a IO-homecontrol network. This home network will react to changes in the environment so to get started, let us look at several ways to collect this data, also know as telemetry.

The code in this series will be mostly javascript running on Node.js. If you want to get kick started
with the code and have some basic project setup please get the boilerplate from bitbucket.

### Gathering Telemetry

To start out simple I'll create a TCP server to which clients can connect and periodically send data to it. I'll first create a couple of components which, when put together, will act as an echo service.

First we create a node tcp server.
```javascript
// src/server.js
import log from './logger';
global.log = log;

import net from 'net';

const server = net.createServer();

export default server;
```

The global logger is defined in a separate file
```javascript
import pino from 'pino';

let logger = pino();
logger.levelVal = parseInt(process.env.LOG_LEVEL, 10);

export default logger;
```
The logger is using [pino](https://www.npmjs.com/package/pino) which I chose as it is fast and defaults to
JSON formats. I make sure we can set the log level by supplying the env variable LOG_LEVEL.

Then, we create a connection handler.
```javascript
// src/handlers/echo.js

export default function echo(connection) {
  let remoteAddress = `${connection.remoteAddress}:${connection.remotePort}`;

  log.info('new connection from', remoteAddress);

  // Pipe instead of listening to data event on connection
  connection.pipe(connection);

  // Emit events with strings instead of buffers as payload.
  connection.setEncoding('utf8');
  connection.once('close', onConnectionClose);
  connection.once('error', onConnectionError);

  function onConnectionClose() {
    log.info('connection from %s closed', remoteAddress);
  }

  function onConnectionError(err) {
    log.info(err);
  }
}
```

This handler will execute on every incoming connection, first we resolve the remote address of the connection in order to log it. Then we pipe the incoming connection back to itself, this will simply echo incoming data back to the other end of the connection. We configure a few event handlers, namely one for the close event and one for the error event. Both handlers simply log the event.

In order to make our echo service work we need to piece the parts together

```javascript
// src/index.js
import server from './server';
import handleConnection from './handlers/echo';

server.on('connection', handleConnection);
server.listen(9000, () => {
    log.info('server [version: %s] listening on %j', process.env.npm_package_version, server.address());
  });
```

We add our echo handler to the server 'connection' event and then we start listening on port 9000.
When we start the server with `npm start` you should see something like
```bash
[nodemon] 1.11.0
[nodemon] to restart at any time, enter `rs`
[nodemon] watching: *.*
[nodemon] starting `babel-node src/index.js`
INFO [2017-01-29T17:08:37.413Z] (37385 on egel.fritz.box): server [version: 0.0.4] listening on {"address":"::","family":"IPv6","port":9000}
```

We can connect manually to this server from another shell session with
`nc localhost 9000`


The server will connect this tcp client and wait for incoming data to then echo it back.
```bash
INFO [2017-01-29T17:11:43.845Z] (37385 on egel.fritz.box): new connection from ::1:49238
```

In the client session we can now type some text and send it by pressing enter. You should see an echo almost immediately. Now this is not very interesting yet, but before we continue lets write a couple of tests for the echo service and learn how to minimize manual testing of functionality.
The test framework used here is [mocha](https://github.com/mochajs/mocha).

```javascript
// test/echo_server_test.js
import Code from 'code';
const { expect } = Code;

import echo from '../src/handlers/echo';
import server from '../src/server';

// Client code.
import net from 'net';


describe('Echo Server', () => {
  before((done) => {
    server.on('connection', echo);
    server.listen(0, done);
  });

  after(() => {
    server.removeListener('connection', echo);
    server.close();
  });

  it('lets a client trigger an echo', (done) => {
    let client = net.createConnection(server.address().port, () => {
      client.write('message');
    });

    client.on('data', (data) => {
      expect(data.toString()).to.equal('message');
      client.end();
      done()
    });
  });

});
```

This test begins with importing the [code](https://github.com/hapijs/code) library which is a rewrite of Chai, this node library helps us asserting functionality in our test. We also import our server and the echo handler. We don't need to import index as we will plug in the components ourselves in the before hook. This is an end to end test. In the test we create a tcp client that connects to the server which we started in the before hook. Once the client is created we send a message to the server. We then wait for the echo on the clients data event and if it matches the original string, we're set. Note that we test asynchronous behaviour and we need to tell this to mocha by using the `done` callback.

When we run the test with `npm test` we should see a result similar to
```bash
> LOG_LEVEL=100 mocha --compilers js:babel-register

  Echo Server
    ✓ lets a client trigger an echo


  1 passing (49ms)
```

### Message format

Now that we have some code in place, we should think about the message structure of our telemetry data. Applying some structure to the data will give us a cleaner API and we can start validating the data to minimize the risk of getting useless data into our system.

I will start with creating a data structure that is similar to what Server-Sent-Events spec defines.
We will use the following field names.

*event*
The event's type, a required string.
*data*
The data field for the message, required object
*id*
The event ID unique to the source device, a required number
*origin*
The source device id. A string

Messages will be transmitted in the JSON format. Lets create a new tests first to get an idea of what we'd like to achieve. The test client will now send a JSON message to our service. But, as we want validation to occur it is probably better to reply to the client with a status message that tells if the message was valid.

```javascript
// test/telemetry_server_test.js
import Code from 'code';
const { expect } = Code;

import echo from '../src/handlers/echo';
import server from '../src/server';

// Client code.
import net from 'net';


describe('Telemetry Server', () => {
  before((done) => {
    server.on('connection', echo);
    server.listen(0, done);
  });

  after(() => {
    server.removeListener('connection', echo);
    server.close();
  });

  it('replies with a success message if message is valid', (done) => {
    let json = '{"id":1, "data": {}, "event": "echo", "origin": "test"}'
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        id: 1,
        success: true
      });
      client.end();
      done()
    });
  });

});
```

When we run the tests, they will of course fail.

```
Telemetry Server
   1) replies with a success message if message is valid


 0 passing (54ms)
 1 failing

 1) Telemetry Server replies with a success message if message is valid:

     Uncaught Error: Expected { id: 1, data: {}, event: 'echo', origin: 'test' } to equal specified value
     + expected - actual

      {
     -  "data": {}
     -  "event": "echo"
        "id": 1
     -  "origin": "test"
     +  "success": true
      }
```

We need to create a new handler that only accepts JSON messages and validates them according to our validation rules.

```javascript
// src/handlers/telemetry.js
import jsonDuplexStream from 'json-duplex-stream';

export default function handleConnection(connection) {
  let duplex = jsonDuplexStream();

  connection.setEncoding('utf8');
  connection
    .pipe(duplex.in)
    .pipe(duplex.out)
    .pipe(connection);

    duplex.in.on('error', onProtocolError);
    duplex.out.on('error', onProtocolError);
    connection.on('error', onConnectionError);

    function onProtocolError(error) {
      log.error(error);
      connection.end(JSON.stringify({ error: error.message, success: false }));
    }
}

function onConnectionError(error) {
  log.error(error);
}
```

Here we pipe the incoming data into the input of the JSON object stream, then we pipe it back into the output of the JSON stream.
This simply parses and then stringifies the data. This is still not very awesome, but with this we can already check if our incoming message
is a valid JSON string. The error handler added to the duplex.in stream will be triggered when the client is sending malformed JSON.
Lets skip our existing test for now and add a new test that handles this error case.

```javascript
// test/telemetry_server_test.js
import Code from 'code';
const { expect } = Code;

import telemetry from '../src/handlers/telemetry';
import server from '../src/server';

// Client code.
import net from 'net';


describe('Telemetry Server', () => {
  before((done) => {
    server.on('connection', telemetry);
    server.listen(0, done);
  });

  after(() => {
    server.removeListener('connection', telemetry);
    server.close();
  });

  it.skip('replies with a success message if message is valid', (done) => {
    let json = '{"id":1, "data": {}, "event": "echo", "origin": "test"}\n'
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        id: 1,
        success: true
      });
      client.end();
      done()
    });
  });

  it('replies with an error message if message format is not json', (done) => {
    let json = '{xa]}\n';
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        error: 'Unexpected token x in JSON at position 1',
        success: false
      });
      client.end();
      done()
    });
  });
});
```
The expected error is what JSON.parse would throw when it encounters unexpected tokens. The JSON duplex stream internally emits the error
so we can handle it with the custom onProtocolError handler.

Lets remove the skip statement from the first test and continue with trying to validate the content of our message.
For validation I will introduce [joi](https://github.com/hapijs/joi) into the project. joi makes it possible to
validate JSON objects against a schema. So lets define a schema first.

```javascript
// src/validators/telemetry-schema.js
import Joi from 'joi';

export default Joi.object().keys({
    data: Joi.object().required(),
    event: Joi.string().required(),
    id: Joi.string().required(),
    origin: Joi.string().required()
});
```
This simple Joi schema requires the message to contain an event, id and origin with string values and a data field containing on object.
In the same folder, lets create a transform stream that uses this schema for validation.

```javascript
// src/validators/index.js
import { Transform } from 'stream';
import Joi from 'joi';
import schema from './telemetry-schema';

export default class ValidatorTransform extends Transform {
  _transform(event, encoding, done) {
    const result = Joi.validate(event, schema);

    if (result.error) {
      return done(result.error);
    }

    let reply = {
      id: event.id,
      success: true
    };

    return done(null, reply);
  }
}
```
Because we are using streams, and I want to reply with a status message we can change the validator result into a message or an error.
When a validation error occurs we create an error event by calling the done callback with the error. If everything is ok we create a reply
that will be pushed further onto the stream. Now lets hook the validator into our main flow.

```javascript
// src/handlers/telemetry.js
import jsonDuplexStream from 'json-duplex-stream';
import Validator from '../validators';

export default function handleConnection(connection) {
  let duplex = jsonDuplexStream();
  // configure validator to be an object stream,
  let validator = new Validator({
    objectMode: true
  });

  connection.setEncoding('utf8');
  connection
    .pipe(duplex.in)
    .pipe(validator) // add validator
    .pipe(duplex.out)
    .pipe(connection);

    duplex.in.on('error', onProtocolError);
    duplex.out.on('error', onProtocolError);
    validator.on('error', onProtocolError);
    connection.on('error', onConnectionError);

    function onProtocolError(error) {
      log.error(error);
      connection.end(JSON.stringify({
        error: error.message,
        success: false
      }));
    }
}

function onConnectionError(error) {
  log.error(error);
}
```
We require our new validator and configure it to handle data as objects instead of strings or buffers by setting the objectMode to true.
The validator stream is then added after the duplex.in stream. Our validator will emit en error event when the validation fails, we can handle this with the same onProtocolError function.

Lets update the telemetry server tests again.
```javascript
// test/telemetry_server_test.js
import Code from 'code';
const { expect } = Code;

import telemetry from '../src/handlers/telemetry';
import server from '../src/server';

// Client code.
import net from 'net';


describe('Telemetry Server', () => {
  before((done) => {
    server.on('connection', telemetry);
    server.listen(0, done);
  });

  after(() => {
    server.removeListener('connection', telemetry);
    server.close();
  });

  it('replies with a success message if message is valid', (done) => {
    let json = '{"id": "1", "data": {}, "event": "echo", "origin": "test"}\n'
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        id: '1',
        success: true
      });
      client.end();
      done()
    });
  });

  it('replies with an error message if message format is not json', (done) => {
    let json = '{xa]}\n';
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        error: 'Unexpected token x in JSON at position 1',
        success: false
      });
      client.end();
      done()
    });
  });

  it('replies with an error message if message does not contain data field', (done) => {
    let json = '{"id": "1", "event": "echo", "origin": "test"}\n';
    let client = net.createConnection(server.address().port, () => {
      client.write(json);
    });

    client.on('data', (data) => {
      let message = JSON.parse(data.toString());
      expect(message).to.equal({
        error: 'child "data" fails because ["data" is required]',
        success: false
      });
      client.end();
      done()
    });
  });

});
```
The new tests do not differ much, we only changed the message that the client sends and see if the server response is according to our
expectations. The error messages are the default ones reported by the Joi library.

### Live stream

Now that we have a server that ingests our data we might also want to be able to display this data in a meaningful way. For displaying the data
I want to create a simple web page that updates each time new telemetry data comes in. Unfortunately there is no easy way to create TCP sockets in Javascript on the browser side, apart from creating something like WebSockets. Besides, I want a relatively simple way to update data in the browser. Lets look at SSE, Server Sent Events are a way to stream data over an HTTP connection. In order to create this stream we could connect to the 'ingestion server' via TCP and transform the received data into an SSE compatible format. To do this I will create a new HTTP server which I'll call 'sse server'. First, I'll write some test for this server.

This first test simply checks if we receive a response once we connect to an SSE stream.

```javascript
// test/sse_server_test.js
import { expect } from 'code';

import server from '../src/sse-server';
import sse from '../src/handlers/http/sse';

// Test client
import EventSource from 'eventsource';

describe('SSE Server', () => {
  before((done) => {
    server.on('request', sse);
    server.listen(0, done);
  });

  after(() => {
    server.close();
  });

  it('streams a SSE stream to connected clients', (done) => {
    let es = new EventSource(`http://localhost:${server.address().port}/sse`);
    es.on('message', (event) => {
      expect(event.data).to.equal('Hello world!');
      done();
    });
  });

});
```

This test similar to the one we seen earlier. This time however our server will be an HTTP server, so we set it up by attaching
a handler to the 'request' event. As a client we use an EventSource object that connects to our server. The object we use is a polyfill
and can be used in browsers and in node. The API is similar to what we saw with the TCP client, here we need to listen to a different event 'message' which is the default name for an SSE event. Lets implement the server so our test passes.

```javascript
// src/sse-server.js
import http from 'http';
import log from './logger';
global.log = log;

const server = http.createServer();

export default server;
```

First we instantiate a simple server object in its own file, if we later need to add some server specific configuration we can do it here.
Next we create the request handler.

```javascript
import { Client } from 'sse';

export default (req, res) => {
  if (req.url !== '/sse') {
    res.statusCode = 404;
    return res.end();
  }

  // This will open a SSE connection on the request and will send the message to the client.
  let client = new Client(req, res);
  client.initialize();

  client.send('message', 'Hello world!', 1);
}
```

To keep the code clean we'll use the Client helper of the [sse](https://github.com/einaros/sse.js) library. This library helps us with transforming our data into the SSE event format. When we run the tests, they should again pass. Now we can move onto developing the server so that it transforms incoming TCP data into outgoing HTTP SSE events. To do this we would need to connect to the the telemetry service, let the telemetry service send telemetry data and then assert the data we send corresponds with the SSE data. This however might turn into a whole lot of trouble maintaining both services at the same time and creating elaborate test scripts in order to run the services. We however have defined some kind of service contract by defining the message format that these services listen to and we can leverage that to our advantage by mocking/intercepting the TCP connection
and emit data conform the message format onto this connection. That were a lot of words, but just lets have a look at an example in which we use [mockery](url) a lib that intercepts require/import statements and [sinon]() a library that helps us mock, stub and spy server behavior.

First we'll update our sse server test.

```javascript
import { expect } from 'code';
import mockery from 'mockery';
import server from '../src/sse-server';
import socketStub from './stubs/socket';

// Web client
import EventSource from 'eventsource';

describe('SSE Server', () => {
  let net = null;
  let sse = null;

  before((done) => {
    mockery.enable();
    mockery.warnOnUnregistered(false);
    mockery.registerAllowable('../src/handlers/http/sseRequestHandler');

    net = {
      Socket: (options) => {
        return socketStub;
      }
    };

    mockery.registerMock('net', net);

    sse = require('../src/handlers/http/sseRequestHandler').default;
    server.on('request', sse);
    server.listen(0, done);
  })

  after(() => {
    mockery.disable();
    server.removeListener('request', sse);
    server.close();
  })

  it('streams a SSE stream to a connected client', (done) => {
    let payload = { data: { key: 'value' } };

    let es = new EventSource(`http://localhost:${server.address().port}/sse`);
    es.onopen = () => {
      // Fake telemetry.
      socketStub.write(JSON.stringify(payload), 'utf8', () => {});
    };
    es.on('message', (event) => {
      // This is the event name we listened to.
      expect(event.type).to.equal('message');
      expect(event.data).to.equal('{"key":"value"}');
      expect(event.origin).to.exist();
      expect(event.lastEventId).to.equal('1');
      done();
    });
    es.on('error', (err) => {
      done(err);
    });
  });

});
```

Here we add mockery to the before hook, we enable it, suppress warnings (for clarity) and register a 'net' object as a mock. Then we require
our handler code and pass this as a listener to the server. When we now connect to the server with the EventSource, the 'net' mock is used to return a connected tcp client when the connection event occurs i.e we fake the connection event as there is no real connection going on. The EventSource will however open and when that happens we can then trigger a fake data event on the connecting by writing to our mocked socket, we need to wait for the EventSource to open otherwise the 'data' event on the socket might get lost due to the async nature of our code.
When the data event is triggered our sse server will start pushing the event onto the sse stream, which we then receive in a 'message' event that was emitted on the EventSource. We then check that our sse message conforms to our expectations, i.e that it has the default event type 'message', that the event data is the data carried under data in the tcp message, that the origin is set and that we have a lastEventId (We need to revisit the code later in order to make it an proper incremental value).

As we haven't done anything valuable other than sending mocked data back and forth and test our services in isolation lets look at how we can make the sse data visible onto some kind of web based dashboard.

### Web based dashboard

I'm pretty new (read: never used) Vue.js but I heard some positive feedback about it, so for our dashboard I will start to use Vue.js.
As I only want to showcase some ways of visualizing data by using our API's, I won't delve into Vue.js too deeply, we'll use [vue-cli](https://github.com/vuejs/vue-cli) for setting up our project and create a basic scaffold based on browserify.

First we need to install vue-cli, and we'll do that globally
```bash
$ npm install -g vue-cli
```

Then we'll init a new project by running
```bash
$ vue init browserify vuedashboard
```

You'll need to answer some questions by accepting the default (for this tutorial) and then run (as stated)
```bash
$ cd vuedashboard
$ npm install
$ npm run dev
```

This should open up a browser and serve a boilerplate app on localhost:8080. Before we continue we'll add three libraries
to our package.json.
```bash
$ npm i --save eventsource vuex
$ npm i --save-dev sinon
```

We will use the eventsource library to connect to our sse server, and vuex is a state management library with which we
are able to keep all application state in a central place. Using Vuex will give us the ability to update page components
automatically whenever the application state changes. Sinon is a library to create test doubles such as spies, stubs and mocks.
As we only need sinon in our tests, we install it as a dev dependency.

Lets first implement a service that connects incoming sse messages to a store.
```javascript
// src/services/SseService.js
import EventSource from 'eventsource';

class SseService {
  constructor(store) {
    this.store = store;
  }

  connect(url) {
    let es = new EventSource(url);

    es.on('open', () => {
      this.store.dispatch('connected');
    });

    es.on('message', (event) => {
      this.store.dispatch('message');
    });

    es.on('error', (error) => {
      this.store.dispatch('error', error);
    });
  }
}

export default SseService;
```

We create a simple service class that references a store in its constructor. The service has only one method 'connect'
which when invoked will create a new EventSource. All the default EventSource events are then mapped to asynchronous dispatch
calls on the store. So, at this point the service only supports receiving EventSource events with the event type message.

The test for this service is a bit more involved.
```javascript
// test/unit/SseService.spec.js
import SseService from '../../src/services/SseService';
import sinon from 'sinon';

describe('Sse service', () => {
  let store = null;
  let sseService = null;
  let fakeServer = null;

  beforeAll(() => {
    fakeServer = sinon.fakeServer.create();

    store = {
      dispatch: sinon.spy()
    }
    sseService = new SseService(store);
  })

  it('dispatches the "connected" event when an sse connection has been established', () => {
    fakeServer.respondWith("GET", "/sse",
            [200, { "Content-Type": "text/event-stream" }, 'OK']);

    sseService.connect('/sse');
    fakeServer.respond();

    expect(store.dispatch.calledWith('connected')).toBe(true);
  })

  it('invokes the "error" mutation handler when the event source errors', () => {
    fakeServer.respondWith("GET", "/sse",
            [404, { "Content-Type": "text/event-stream" }, 'OK']);

    sseService.connect('/sse');
    fakeServer.respond();

    expect(store.dispatch.calledWith('error')).toBe(true);
  })

  afterAll(() => {
    fakeServer.restore();
  })
})
```   
The tests are written with Jasmine. First we import the code under test, our service module, and we also import sinon
which we use to create a fake vuex store and a fakeServer. In the beforeAll hook we setup the fakeServer and we create a fake
store object that we pass into the SseService constructor. Now in every test we can validate if and how our store is called.

Each test starts with setting up a stubbed response from our fake sse server. This means we do not have to have our real sse server running
and we only validate a service contract at this point. To be able to create canned responses make the test faster and it is way easier to
test different use cases. After setting up the responses we try to create an sse connection with our service. Then we trigger a response from the fake server. At last we set an expectation on the store that tells us if we have dispatched a certain message or not.

Now that we have a mechanimsm in place to update our store with sse event data, lets implement the actual store.
```javascript
// src/store/index.js
import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

/*
* This is where you define the data structure of your application.
* You can also set default or initial state here.
*/
const state = {
  connected: false,
  devices: []
};

/*
* Actions are where you define the calls that will commit changes to your store.
* A common example of this would be a call to an api to retrieve data, once it completes you
* call store.commit() to invoke a mutation to actually update the data in the store.
* Actions are called in your components via dispatch call.
*/
const actions = {
  connect({ commit }) {
    commit('connect')
  },
  message({ commit }, telemetry) {
    //commit('message', telemetry)
  },
  error({ commit }, error) {
    console.log(error);
  }
};

/*
* The mutations calls are the only place where the store can be updated.
*/
export const mutations = {
  reset(state) {
    state.connected = false;
    state.devices = [];
  },
  connect(state) {
    state.connected = true;
  },
  message(state, telemetry) {
    let index = state.devices.findIndex((item) => {return item.data.id == telemetry.data.id})
    if (~index) {
      state.devices[index] = telemetry;
    } else {
      state.devices.push(telemetry);
    }
  }
};

const options = {
  state,
  mutations,
  actions
};

export default new Vuex.Store(options);
```

First we import vue and vuex and then tell vue that we want to use Vuex. Then we create a state object that holds the initial state
of our store. Then we create the actions, these are called whenever we dispatch an matching event on the store (as we did in the SseService), in this example the actions delegate straight to the store mutations, but if data was needed from an async source we would handle that here. The mutations are the central place where the store state can be changed. Then we gather the state, mutations and actions into an options object which we pass to the Vuex.store constructor and voila, we have a store for our app. As you might have noticed, the mutations are also exported from  this module, this is done so we can easily test them.

```javascript
// test/unit/store.spec.js
import store from '../../src/store';
import { mutations } from '../../src/store';

import sinon from 'sinon';

describe('Store', () => {

  describe('mutations', () => {
    const {
      message
    } = mutations;
    const telemetry = {type: 'message', data: { id: 1 }, origin: '', lastEventId: 1}

    describe('MESSAGE', () => {
      it('adds initial telemetry message', () => {
        const state = { devices: [] }
        message(state, telemetry);
        expect(state.devices.length).toEqual(1)
      })

      it('updates telemetry message from a unique device', () => {
        const state = { devices: [telemetry] }
        message(state, telemetry);
        expect(state.devices.length).toEqual(1)
      })

      it('adds telemetry message from a unique device', () => {
        const state = { devices: [telemetry] }
        const data = {type: 'message', data: { id: 2 }, origin: '', lastEventId: 1}
        message(state, data);
        expect(state.devices.length).toEqual(2)
      })
    })
  })

});
```
These tests only validate the behavior of the 'message' mutation. Mutation functions take the current state as a parameter and mutate it, so
we can simply pass in a mock state object and validate if the expected mutation occurred. As these test are rather simple, I leave the exploring of them to the reader.

The main idea of having a dashboard is to be able to show something, so lets finally implement some Vue components that can display our telemetry
data. Because we use vue-cli to manage this project we can create single file components, which means that everything related to a component such as
its template, styling and javascript can be found in the same source file. The first component we create is a very simple list item.
```javascript
// src/components/Device.vue
<template>
  <li class="flex-item normal">
    {{ device.telemetry }}
  </li>
</template>

<script>

export default {
  name: 'device',
  props: ['device']
}
</script>

<style scoped>
.flex-item {
  padding: 5px;
  width: 250px;
  height: 250px;
  margin: 10px;

  line-height: 150px;
  font-weight: bold;
  font-size: 1.5em;
  text-align: center;
  border-radius: 25px;
}

.normal {
  background: coral;
  color: white;
  border: 10px solid #ffffff;
  box-shadow: 10px 10px 5px #888888;
}
</style>
```
We define the list item markup inside template tags. Handlebars are used to bind data to the template. Then between the script tags
we find a very simple component object, it only has a name which maps to an html tag, and we have a props array to map the properties we can set on
the component. Some styling can be applied with conventional css.

In the next component we will use the device component we created earlier. The DeviceList is also a single file component, we give it the name 'devices' and make it dependent on the Device component. The DeviceList component, when mounted, will attempt to connect to our sse service. As this component is connected to the same store as our sse service we are able to receive the updates to the store and one way we can do that is through computed properties of the component. The connected property will update every time the connected state of the store changes. Each time the devices state updates, the list component will rerender the list with the updated data. When there are no devices, an informative message will be displayed instead of an empty list.
```javascript
// src/components/DeviceList.vue
<template>
  <div>
    <span class="status">{{ connected }}</span>
    <ul id="devices" class="flex-container" v-if="hasDevices">
      <device v-for="device in devices" v-bind:device="device"></device>
    </ul>
    <span class="info" v-else>No devices detected</span>
  </div>
</template>

<script>
import Device from './Device.vue';
import SseService from '../services/SseService'

export default {
  name: 'devices',

  components: {
    Device
  },

  mounted: function () {
    let service = new SseService(this.$store);
    service.connect('http://localhost:9001/sse');
  },

  computed: {
    connected() {
	    return this.$store.state.connected ? 'connected':'disconnected'
    },
    devices() {
      return this.$store.state.devices
    },
    hasDevices() {
      return this.$store.state.devices.length > 0;
    }
  }
}
</script>

<style scoped>

.flex-container {
  padding: 0;
  margin: 0;
  list-style: none;

  display: -webkit-box;
  display: -moz-box;
  display: -ms-flexbox;
  display: -webkit-flex;
  display: flex;

  -webkit-flex-flow: row wrap;
  justify-content: space-around;
}
</style>
```
[WIP]
## React/Ink CLI Monitor]

[NEXT WIP]
[BOOKS TO READ,
  Docker,
  Rest
  ZeroMQ
]

# [WIP] Putting things together.

Run all services/clients and do a 'nc localhost 9000' to send testdata to create list
this should add all devices to the dashboard. Then send update list data to update device 2.

*test data to create list*
{"id": "1", "data": {"id": 1, "telemetry": "99C"}, "event": "message", "origin": "test"}
{"id": "1", "data": {"id": 2, "telemetry": "99C"}, "event": "message", "origin": "test"}
{"id": "1", "data": {"id": 3, "telemetry": "99C"}, "event": "message", "origin": "test"}
*update list*
{"id": "1", "data": {"id": 2, "telemetry": "100C"}, "event": "message", "origin": "test"}

*issues found*
* cors problem -> fix: [access-control](https://github.com/primus/access-control) (todo: e2e test)
* broadcast was sending object -> fix: JSON.stringify (todo: api test)
* [vuex] unknown action type: connected -> fix typo (todo: api test)
* device list is not populated. -> uncomment call to mutation. (todo: api test)
* device data not rendered -> fix object parameters/namespace in Device.vue. (todo: test)
* device data not updating in view -> https://vuejs.org/v2/guide/list.html#Array-Change-Detection replace [index]= with splice(index)

TODO [ISSUES-001]
* Contracts need to be written down!
* Implement E2E tests
* Implement missing api tests

# [WIP] babel for es6 modules is it worth it?

I'll refactor to use commonjs modules as I think es6 modules are not worth the extra babel transpilation steps, node 6.x and up suppport most of es6. Plus it makes debugging easier.

# [WIP] Docker

Running our services on top of Docker is relatively simple. Without using a Dockerfile we can explore how this works
by using the Docker cli.

    docker run --rm -t -v <service-root>:/app --env-file <service-root>/.env -w /app node:6.10.0-alpine sh -c '<script>'

We'd want to run our node service inside an Linux Alpine image with node support (node:6.10.0-alpine), these are very small sized images and thus don't take to much bandwidth to download. We pass --rm to clean up our images after exploring (when everything seems ok we can actually build an image based on a Dockerfile if we want to). With -t we attach a psuedo tty so we can send signals to the process from our host. The service src needs to be mounted into the container, we do this with the -v option and mount our service (full path) to /app in the image. As an example of how to pass in env variables we pass an --env-file (same full path + .env). All env variables will be set an available in the container. As we need to run our scripts from the service root in the container we set the current working dir to /app. The we pass in the image to use, as mentioned before. Finally we pass in our script to run from the shell.

*Dockerfile for services*
```
FROM node:6.10.0-alpine

# Expose port we passed in, our server will serve on this port and we want to expose it to the host.
EXPOSE PORT

# Run the service in dev mode by default
CMD ["yarn", "run", "start"]
```

To run the web application, we only need to do execute one additional step: building the distribution.

    docker run --rm -t -v (pwd)/web:/app -w /app node:6.10.0-alpine sh -c 'yarn install'
    docker run --rm -t -v (pwd)/web:/app -w /app node:6.10.0-alpine sh -c 'yarn run build'
    docker run --rm -t -v (pwd)/web:/app -w /app node:6.10.0-alpine sh -c 'yarn run serve'

*Dockerfile for webapp*




# [WIP] Deployment?

* Platform?

# [WIP] Logging/Logstash?

pino to central logstash or similar (via volumes or log endpoint)

# [WIP] Message gateway between services/ZeroMQ?


# Onion Omega and 1-wire Sensor data

(Docs for my 40 in 1 Sensorkit for 4duino)
*Get all unique links from site that math a regex.*
lynx -dump -unique_urls -nonumbers -listonly "http://sensorkit.joy-it.net/index.php?title=Hauptseite" | grep title=KY-0 | uniq > sensors.txt
*download page for offline usage*
wget -E -H -k -p -i sensors.txt

* [Onion - Reading 1-Wire Sensor Data](https://wiki.onion.io/Tutorials/Reading-1Wire-Sensor-Data)


# SSE store snippet
```
var loki = require('lokijs');
var EventSource = require('eventsource');
var db = new loki('./telemetry.json',
      {
        autosave: true,
        autosaveInterval: 1500, // 1.5 seconds
      });
var telemetry = db.addCollection('telemetry')

let es = new EventSource('http://omega-1e13.local:8888/sse');

es.on('open', () => {
  console.log('OPEN');
});

es.on('message', (event) => {
  console.log(event);
  telemetry.insert(parseTelemetry(event))
});

es.on('error', (error) => {
  console.error(error.status);
});

function parseTelemetry({ id, origin, data, event }) {
  return {
    id,
    origin,
    event,
    data: JSON.parse(data)
  };
};
```

# ONION get uci info in node snippet
```
const spawn = require('child_process').spawn;
const uci = spawn('uci', ['show', 'network.wlan.ipaddr']);

uci.stdout.on('data', (data) => {
  console.log(`stdout: ${data}`);
});

uci.stderr.on('data', (data) => {
  console.log(`stderr: ${data}`);
});

uci.on('close', (code) => {
  console.log(`child process exited with code ${code}`);
});
```

# ONION sse server (sensor data service, uses sensor.js below)
```
var http = require('http');
var path = require('path');
var sync = require('child_process').spawnSync;
var connectionCounter = 1;
var sensor = require('./sensor');

var cmd = path.resolve(__dirname, './checkHumidity/bin/checkHumidity');
http.createServer(function (req, res) {
   res.setHeader("Access-Control-Allow-Origin", "*");
   res.setHeader("Access-Control-Allow-Credentials", "true");
   res.setHeader("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT");
   res.setHeader("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Cache-Control, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers");

  if ( req.method === 'OPTIONS' ) {
    res.writeHead(200)
    res.end()
    return
  }

  if (req.url === '/sse') {

    var clientId = connectionCounter++;
    var eventCounter = 1;

    // Log information about the connecting client.
    console.log('Client connected:');
    console.log('\tconnection #' + clientId);
    console.log('\tLast-Event-Id: ' + req.headers['last-event-id']);

    // Tell clients the data should be interpreted as SSE stream
    // and to not cache the data.
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache'
    });

    // Respond with an SSE event periodically to connected clients
    var ticker = setInterval(function () {
      eventCounter = eventCounter + 1;
      sensor.read([cmd, '19', 'DHT11'].join(' ')).then(sensor.formatMsg).then(function(data) {
        res.write('event: message\n'); // default event type
        res.write('id: ' + (clientId * 1000 + eventCounter) + '\n'); // id to track Last-Event-Id seen on client
        res.write('data: ' + data + '\n\n'); // fake temperature range
      })
    }, 5000);

    // Stop sending SSE events when a client disconnects
    req.on('close', function () {
      console.log('Client disconnected from event stream (connection #' + clientId + ')');
      res.end();
      clearInterval(ticker);
    });

  } else {
    res.writeHead(404);
    res.end();
  }

}).listen(8888);
```

# READ SENSOR LIB ONION SNIPPET
```
const childProcess = require('child_process');

function execute(command) {
  const promise = new Promise(function (resolve, reject) {
    childProcess.exec(command, function (error, stdout, stderr) {
      if (error) {
        return reject(stderr);
      }

      return resolve(stdout);
    });
  });

  return promise;
}

function formatMsg(stdout) {
  console.warn(stdout);
  const promise = new Promise(function (resolve, reject) {
    const msg = JSON.stringify({
      sensor: 'DHT11',
      // date: new Date().toISOString(),
      timestamp: Date.now(),
      reading: stdout.toString().split('\n'),
      unit: ['%', '°C']
    });

    resolve(msg);
  });
  return promise;
}

module.exports = {
  read: execute,
  formatMsg: formatMsg
};
```
