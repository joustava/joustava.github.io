---
layout: single
title: Creating a PACT with Swift
date: 2020-03-08 18:11 +0100
---
[Fast, easy and reliable testing for your APIs and microservices during development](https://docs.pact.io/)' is the tag line for Pact. This sure sounds promising, but how does it impact the development of client applications that use these services? This post will give some basic overview what is needed for a Swift client of an http service. The code for this article can be found from this [repo](joustava_act-article-example-project)

### Example client and server

We will look at how we could implement a development workflow with PACT in the context of a consumer made in Swift and a Provider created in node.js. I've already created the provider and consumer code examples so we can start right away. We will also use docker for setting up some of the tools provided by Pact to get an idea of what is involved.

The following snippet is our GreetingConsumer created in Swift.

```swift
// GreetingConsumer.swift
import Foundation

/// The response body.
struct Greeting: Codable {
    let message: String
}

/// HTTP Client
class GreetingServiceClient {
    
    let baseUrl: URL!

    init(baseUrl: URL!) {
        self.baseUrl = baseUrl
    }

    func getGreeting(handler: @escaping (Result<Greeting, Error>) -> Void) {

        let resource = self.baseUrl.appendingPathComponent("hello")

        URLSession.shared.dataTask(with: resource) { (result) in
            switch result {
            case .success(_, let data):
                // Handle Data and Response
                do {
                    let greeting: Greeting = try JSONDecoder().decode(Greeting.self, from: data)
                    handler(.success(greeting))
                } catch {
                    handler(.failure(error))
                }
            case .failure(let error):
                // Handle Error
                handler(.failure(error))
            }
        }.resume()

    }
}

/// Simple config struct to set the base url on our client.
struct Config {
    static let baseUrlPact = URL(string: "http://localhost:1234")
}

/// An extension to `URLSession`, this is not really relevant to pact but makes our client code a little cleaner.
extension URLSession {
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: url) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}
```

The Swift implementation is a simple client which makes a http GET request to our API server, The client and server are called consumer and provider respectively in PACT speech. The server is only used for our next integration test example.

```javascript
// server/src/index.js
const express = require('express')

const port = 8080
const app = express()

app.get('/hello', (req, res) => {
    res.send('Hello')
})

app.get('*', function(req, res){
    res.send('Oops!', 404);
  });

app.listen(port, () => {
    console.log('Listening on container port ' + port);
})
```

This provider will, upon a request to GET /hello, respond with json data containing a message. Any other request will result in the server responding with a HTTP 404 not found. 

One of the more typical ways to test that the client and server are working together properly is to create integration tests triggered by the consumer.

```swift
// IntegrationTests.swift
import XCTest
@testable import mobile

final class IntegrationTests: XCTestCase {

    var greetingServiceClient: GreetingServiceClient?

    override func setUp() {
        super.setUp()

        greetingServiceClient = GreetingServiceClient(baseUrl: Config.baseUrlServer)
    }

    func testExampleIntegration() {
        let expectation = self.expectation(description: "greeting client receives response")

        self.greetingServiceClient!.getGreeting { result in
            switch result {
            case .success(let greeting): 
                print(greeting)
                XCTAssertEqual(greeting.message, "Mars!")
                expectation.fulfill()
            case .failure(let error): 
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
```

Integration test are often brittle and are not fun to maintain. Also `green` integration tests do not necessarily mean that production deploys on either side will result in a smooth integration.

During development one will often bumb into the following errors, which slow down development.

1. Example of a failing test due to network connection (simulated by not running server container).

```shell
⟩ make integration-tests
cd mobile; \
	swift test --filter=IntegrationTests 2>&1 | xcpretty --simple --color
Selected tests
Test Suite mobilePackageTests.xctest started
IntegrationTests
    ✗ testExampleIntegration, failed - Could not connect to the server.


mobileTests.IntegrationTests
  testExampleIntegration, failed - Could not connect to the server.
  /Users/joustava/Workspace/spikes/pact-article-example-project/mobile/Tests/mobileTests/IntegrationTests.swift:25
  ```
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation.fulfill()
  ```
Executed 1 test, with 1 failure (0 unexpected) in 0.155 (0.155) seconds
```

2. Example of a failing test because the data received is not in the corect format (expected but a real-world scenario when e.g api documentation does not match implementation)

```shell
⟩ make integration-tests
cd mobile; \
	swift test --filter=IntegrationTests 2>&1 | xcpretty --simple --color
Selected tests
Test Suite mobilePackageTests.xctest started
IntegrationTests
    ✗ testExampleIntegration, failed - The data couldn’t be read because it isn’t in the correct format.


mobileTests.IntegrationTests
  testExampleIntegration, failed - The data couldn’t be read because it isn’t in the correct format.
  /Users/joustava/Workspace/spikes/pact-article-example-project/mobile/Tests/mobileTests/IntegrationTests.swift:25
  ```
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation.fulfill()
  ```
Executed 1 test, with 1 failure (0 unexpected) in 0.213 (0.213) seconds
```

3. Example of a failing test caused by network delays (faked by adding a timeout in server middleware)

```shell
⟩ make integration-tests
cd mobile; \
	swift test --filter=IntegrationTests 2>&1 | xcpretty --simple --color
Selected tests
Test Suite mobilePackageTests.xctest started
IntegrationTests
    ✗ testExampleIntegration, Asynchronous wait failed: Exceeded timeout of 5 seconds, with unfulfilled expectations: "greeting client receives response".


mobileTests.IntegrationTests
  testExampleIntegration, Asynchronous wait failed: Exceeded timeout of 5 seconds, with unfulfilled expectations: "greeting client receives response".
  /Users/joustava/Workspace/spikes/pact-article-example-project/mobile/Tests/mobileTests/IntegrationTests.swift:30
  ```

        waitForExpectations(timeout: 5, handler: nil)
    }
  ```
  Executed 1 test, with 1 failure (0 unexpected) in 5.354 (5.355) seconds
```

Yes, in this case the errors were simulated on purpose but these things can happen during actual integration testing. These issues can result in frustration and loosing a lot of time.

### PACT

Pact aims to help with increasing the front and backend service integration quality by creating a common language. In contrast to integration tests, consumer tests are relatively easy to setup and maintain, give fast feedback, are more stable and make it easier to find out where potential errors or bugs are located within the stack.

PACT requires a couple of different services to run. These services would typically be running somewhere in the cloud and would not require much time once the infrastructure is setup. We will stick with running a few of them on our local machine to get aquainted with some of the pieces that make up PACT.  Setting it up is made easy through the use of docker and docker-compose.

We'll use the [pact-cli](https://hub.docker.com/r/pactfoundation/pact-cli) docker image to run all the needed pact services on the development host. Tip: [****Dry**** is a terminal application to manage ****Docker**** and ****Docker Swarm****](https://github.com/moncho/dry) and might be handy in keeping track of the server status.

If you look at the `pact-cli` docker image examples you will see the different services it supports. I've included a Makefile within the project with the commands needed for the examples in this article. There is no need for us to download anything directly, docker will take care off this under the hood.

### Consumer Driven Testing

First fire up the pact mock server with `$ make pact-mock-run`  . You'll see something like this

```shell
docker run -it \
	--rm \
	--name pact-mock-service \
	-p 1234:1234 \
	-v <your_own_project_workspace>t/pacts:/tmp/pacts \
	pactfoundation/pact-cli:latest \
	mock-service \
	-p 1234 \
	--host 0.0.0.0 \
	--pact-dir /tmp/pacts
INFO  WEBrick 1.6.0
INFO  ruby 2.5.7 (2019-10-01) [x86_64-linux-musl]
INFO  WEBrick::HTTPServer#start: pid=8 port=1234
```

It is basically just `make` echoing the executed command followed by output from a server specific to Ruby. This server has nothing to do with our projects node.js server that responds with greetings. It is the [pact_mock_service](https://github.com/pact-foundation/pact-mock_service) which has an api for managing PACT interactions, don't worry though we don't have to manage it via http calls directly.

To manage expectations before our consumer contract tests run we'll be using a Swift library called [PactConsumerSwift](https://github.com/DiUS/pact-consumer-swift). Here is an XCTestCase that sets up a consumer tests for our client library.

```swift
import XCTest
import PactConsumerSwift
@testable import mobile

final class ContractTests: XCTestCase {

    var greetingMockService: MockService?
    var greetingServiceClient: GreetingServiceClient?

    override func setUp() {
        super.setUp()

        greetingMockService = MockService(provider: "Greeting Provider", consumer: "Greeting Service Client")
        greetingServiceClient = GreetingServiceClient(baseUrl: Config.baseUrlPact)
    }

    func testGreetingResponse() {
       // Expected.
        greetingMockService!
            .given("A greeting endpoint exists")
            .uponReceiving("A request for a greeting")
            .withRequest(method: .GET, path: "/hello")
            .willRespondWith(
                status: 200,
                headers: [ "Content-Type": "application/json"],
                body: [ "message": Matcher.somethingLike("Mars!") ]
            )

        // Run the test
        greetingMockService!.run(timeout: 5) { (testComplete) -> Void in
            self.greetingServiceClient!.getGreeting { result in
                switch result {
                case .success(let greeting): 
                    XCTAssertEqual(greeting.message, "Mars!")
                    testComplete()
                case .failure(let error): 
                    XCTFail(error.localizedDescription)
                    testComplete()
                }
            }
        }
    }
}
```

It does not differ much from the integration test we seen above. What is added is a MockService object with which request and response expectations are set before the tests run, the client call is then wrapped inside a mock service. When this code executes, the expectations are uploaded to the running pact mock server so that it can check if the actuall call fullfills the expectations. Not that we do not have a XCTestExpectation setup anymore, the mock service passes a callback to our client code that we need to call once we deem our tests to be ready.

When we run this contract tests, all is green.

```shell
⟩ make pact-consumer-tests
cd mobile; \
	swift test --filter=ContractTests 2>&1 | xcpretty --simple --color
Selected tests
Test Suite mobilePackageTests.xctest started
ContractTests
    ✓ testGreetingResponse (0.339 seconds)

Executed 1 test, with 0 failures (0 unexpected) in 0.339 (0.340) seconds
```

Now we have a client and a passing test for it, but what else did pact do actually do for us? It created a contract automatically which can be shared with those responsible for the serving side. Sharing can be done manually but the preferred way would be to publish these contracts to a Pact Broker. In this case we're the only ones responsible for both sides, like a real Full Stack Dev! But even if you are the sole developer on a project, I think it is quite interesting to drive the design from the consumer, which needs to be able to handle the data in a meaningfull and maintainable way.

Here is the contract generated as an artifact by the pact-mock-server. It is a json file that recorded our interactions.

```json
{
  "consumer": {
    "name": "Greeting Service Client"
  },
  "provider": {
    "name": "Greeting Provider"
  },
  "interactions": [
    {
      "description": "A request for a greeting",
      "providerState": "A greeting endpoint exists",
      "request": {
        "method": "get",
        "path": "/hello"
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "applicationjson"
        },
        "body": {
          "message": "Mars!"
        },
        "matchingRules": {
          "$.body.message": {
            "match": "type"
          }
        }
      }
    }
  ],
  "metadata": {
    "pactSpecification": {
      "version": "2.0.0"
    }
  }
}
```

As mentioned before, this file can be shared with other developers that would maintain a service on which the client depends. This sharing can be done automatically via a Pact broker. Once the service developer receives the contract they can run provider tests or verifications with them. We won't look at that here though (I might update this post later).

### Provider stub

Pact also supplies us with a stubbing service, that will serve stubbed data based on a contract we generated before with our consumer tests. I think this is really great: You can first design your client implementation with the help of the pact mock, then backend could verify this in their own pace, but you would be able to demo your frontend code with data served by the Pact stub. This all only based on tests you wrote once.

Run `make pact-stub-run`. This will start the stub server with the contract file we generated before in our consumer test.

```shell
⟩ docker run -t -p 8083:8083 -v /Users/joustava/Workspace/spikes/pact-article-example-project/pacts/:/app/pacts pactfoundation/pact-stub-server -p 8083 -f /app/pacts/greeting_service_client-greeting_provider.json
15:52:39 [INFO] Server started on port 8083
```

Now, with curl we can make a invalid request and see what happens

```shell
⟩ curl -v http://localhost:8083/
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 8083 (#0)
> GET / HTTP/1.1
> Host: localhost:8083
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 404 Not Found
< access-control-allow-origin: *
< content-length: 0
< date: Sun, 08 Mar 2020 16:45:11 GMT
<
* Connection #0 to host localhost left intact
* Closing connection 0
```

This 404 response is caused by the pact stub server because it could not find any valid interactions.

```shell
16:45:11 [INFO] ===> Received Request ( method: GET, path: /, query: None, headers: Some({"accept": ["*/*"], "host": ["localhost:8083"], "user-agent": ["curl/7.64.1"]}), body: Empty )
16:45:11 [INFO] comparing to expected Request ( method: GET, path: /hello, query: None, headers: None, body: Missing )
16:45:11 [WARN] No matching request found, sending 404 Not Found
16:45:11 [INFO] <=== Sending Response ( status: 404, headers: None, body: Missing )
```

When we make a valid request

```shell
⟩ curl -v http://localhost:8083/hello
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 8083 (#0)
> GET /hello HTTP/1.1
> Host: localhost:8083
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 200 OK
< content-type: application/json
< access-control-allow-origin: *
< content-length: 19
< date: Sun, 08 Mar 2020 16:45:21 GMT
<
```

The pact stub server will respond with the expected data.

```shell
16:45:21 [INFO] ===> Received Request ( method: GET, path: /hello, query: None, headers: Some({"accept": ["*/*"], "host": ["localhost:8083"], "user-agent": ["curl/7.64.1"]}), body: Empty )
16:45:21 [INFO] comparing to expected Request ( method: GET, path: /hello, query: None, headers: None, body: Missing )
16:45:21 [INFO] <=== Sending Response ( status: 200, headers: Some({"Content-Type": ["application/json"]}), body: Present(19 bytes) )
```

To get this working with the Swift client we need to make some little changes to the Config struct  so that it looks like

```swift
/// Simple config struct to set the base url on our client.
struct Config {
    static let baseUrlPactMock = URL(string: "http://localhost:1234")
    static let baseUrlPactStub = URL(string: "http://localhost:8083")
    static let baseUrlServer = URL(string: "http://localhost:8080")
}
```

Check that your integration test now points to `baseUrlPactStub` and the consumer test points to `baseUrlPactMock`. When you run the integration test once more with `make integration-tests` we see green pastures again (as we have no real app setup I use the integration test as example for the stub service).

```shell
⟩ make integration-tests
cd mobile; \
	swift test --filter=IntegrationTests 2>&1 | xcpretty --simple --color
Selected tests
Test Suite mobilePackageTests.xctest started
IntegrationTests
    ✓ testExampleIntegration (0.193 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.193 (0.194) seconds
```

### Conclusion

Pact seems to give some nice features for decentralized testing of microservices and their clients. It didn't take us so much time to setup those tools needed for consumer testing and we basically got a stub service for free based on our test results. No more maintaining test fixtures AND stub data for demos!

Of course this was a very simple example and typically a service would need tthe client to be authenticated or some tests might need some certain state before they are run. This can also be taken care of by Pact with provider states.

I recommend you to take a further look at these resources to see if this could improve your workflows.

- [Pact documentation](https://docs.pact.io/)
- [Pact on GitHub](https://github.com/pact-foundation)
- [Consumer Driven Contracts](https://www.martinfowler.com/articles/consumerDrivenContracts.html#Consumer-drivenContracts)

What are your experiences with Pact?