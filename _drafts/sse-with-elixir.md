---
title: SSE with elixir
#abbrlink: 29323
---
intro...

'Simple' challenge accepted.
First, I fork the [gun](https://github.com/ninenines/gun) repository.
Then I need to make sure I can run the tests.

So far so good. But, yeah, before hacking stuff together I need to do some research.
According to this [issue](https://github.com/ninenines/gun/issues/48#issuecomment-233365030) it should be relatively simple as gun already somewhat? supports receiving of streamed bodies and this body then needs to be parsed.

So lets try to figure out what a SSE stream should look like. The MIME type of SSE should be [text/event-stream](https://html.spec.whatwg.org/multipage/iana.html#text/event-stream) and the basic message format, when decoded as utf-8 looks something like
```
event: add
data: 73857293

event: message
data: This is the second message, it
data: has two lines.

event: remove
data: 113411
```
When no event type is specified it will be the default 'message'.
At a first glance, it seems the client needs to decode the stream and then apply some kind of handler for each specific message.
The client also needs to support redirection using HTTP 301 and 307 redirects as with normal HTTP requests.

Lets use this [super simple elixir sse server](https://gist.github.com/binarytemple/b1c5c20fa7b119f8dd510b4c3ee8647f) example
in order to get things going as a base. Follow the gist to set up the project. I did not get the gist to work initially due to a probable older version of plug in the dependencies. I resolved it by changing the mix.exs dependencies into
```
defp deps do
  [
    {:cowboy, "~> 1.0.0"},
    {:plug, "~> 1.0"}
  ]
end
```

As we will want to use [gun]() and make it support SSE, let's head to [guns documentation](https://github.com/ninenines/gun/blob/master/doc/src/guide/book.asciidoc)

## Sources

* [What is Server-Sent Events?](http://streamdata.io/blog/server-sent-events/)
* [Server-Sent Events: The simplest realtime browser spec](https://segment.com/blog/2014-04-03-server-sent-events-the-simplest-realtime-browser-spec/)
* [SSE Spec](https://html.spec.whatwg.org/multipage/comms.html#server-sent-events)
* [Event handling in Elixir](http://www.tattdcodemonkey.com/blog/2015/4/24/event-handling-in-elixir)
* [Super simple Elixir SSE server](https://gist.github.com/binarytemple/b1c5c20fa7b119f8dd510b4c3ee8647f)

## More

* [link](url)
