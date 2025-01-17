# Developer Guide

## First CLI function

Create a `go.mod` file: (`go mod init cli-say-hello`)
```
module cli-say-hello

go 1.18
```

Install the Capsule dependencies:
```bash
go get github.com/bots-garden/capsule/capsulemodule/hostfunctions
```

Create a `hello.go` file:
```go
package main

import hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"

// main is required.
func main() {
	hf.SetHandle(Handle)
}

func Handle(params []string) (string, error) {
	var err error
	for _, param := range params {
		hf.Log("- parameter is: " + param)
	}

    ret := "The first parameter is: " + params[0]

    return ret, err // err = nil
}
```
> - `hf.SetHandle(Handle)` defines the called wasm function
> - `hf.Log(string)` prints a value

Build the wasm module:
```bash
tinygo build -o hello.wasm -scheduler=none --no-debug -target wasi ./hello.go
```

Execute the `Handle` function:
```bash
./capsule \
   -wasm=./hello.wasm \
   -mode=cli \
   "👋 hello world 🌍🎃" 1234 "Bob Morane"
```
> - `-wasm` flag: the path to the wasm file
> - `-mode` execution mode


*output:*
```bash
- parameter is: 👋 hello world 🌍🎃
- parameter is: 1234
- parameter is: Bob Morane
The first parameter is: 👋 hello world 🌍🎃
```

## First HTTP function

Create a `go.mod` file: (`go mod init http-say-hello`)
```
module http-say-hello

go 1.18
```

To serve the function through http, you need to change the signature of the `Handle` function:

```golang
package main

import hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"

// main is required.
func main() {
	hf.SetHandleHttp(Handle)
}

func Handle(request hf.Request) (response hf.Response, errResp error) {
    hf.Log("📝 Body: " + request.Body)

	// Read the request headers
    hf.Log("Content-Type: " + request.Headers["Content-Type"])
    hf.Log("Content-Length: " + request.Headers["Content-Length"])
    hf.Log("User-Agent: " + request.Headers["User-Agent"])

	// Read the MESSAGE environment variable
	envMessage, err := hf.GetEnv("MESSAGE")
	if err != nil {
		hf.Log("😡 " + err.Error())
	} else {
		hf.Log("Environment variable: " + envMessage)
	}

	// Set the response content type and add a message header
	headersResp := map[string]string{
		"Content-Type": "application/json; charset=utf-8",
		"Message":      "👋 hello world 🌍",
	}

	jsonResponse := `{"message": "hey people!"}`

	return hf.Response{Body: jsonResponse, Headers: headersResp}, err
}
```
> - `hf.SetHandleHttp(Handle)` defines the called wasm function
> - `hf.Log(string)` prints a value
> - `hf.GetEnv("MESSAGE")` get the value of the `MESSAGE` environment variable

Build the wasm module:
```bash
tinygo build -o hello.wasm -scheduler=none --no-debug -target wasi ./hello.go
```

Serve the `Handle` function:
```bash
export MESSAGE="🖐 good morning 😄"
./capsule \
   -wasm=./hello.wasm \
   -mode=http \
   -httpPort=8080
```


Call the `Handle` function:
```bash
curl -v -X POST \
  http://localhost:8080 \
  -H 'content-type: application/json; charset=utf-8' \
  -d '{"message": "TinyGo 💚 wasm"}'
```

*request output:*
```bash
> POST / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.79.1
> Accept: */*
> content-type: application/json; charset=utf-8
> Content-Length: 31
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Message: 👋 hello world 🌍
< Date: Sat, 30 Jul 2022 19:17:28 GMT
< Content-Length: 26
<
{"message":"hey people!"}
```

*log server output:*
```bash
📝 body: {"message":"TinyGo 💚 wasm"}
Content-Type: application/json; charset=utf-8
Content-Length: 31
User-Agent: curl/7.79.1
Environment variable: 🖐 good morning 😄
```

### OnLoad function

If you add an `OnLoad` exported function to the module, it will be executed at the start of the HTTP launcher (capsule).
>  *the `main` function will be executed too*

```golang
//export OnLoad
func OnLoad() {
	hf.Log("👋 from the OnLoad function")
}
```
> It can be useful to register your wasm service to a backend (Redis, CouchBase, ...)

### OnExit function

If you add an `OnExit` exported function to the module, it will be executed when you stop the HTTP launcher (capsule).
>  *the `main` function will be executed too*

```golang
//export OnExit
func OnExit() {
	hf.Log("👋 from the OnExit function")
}
```
> It can be useful to unregister your wasm service from a backend (Redis, CouchBase, ...)


### GetExitError and GetExitCode function
> 🖐🚧 it's a work in progress (it's not implemented entirely)
```golang
//export OnExit
func OnExit() {
	hf.Log("👋🤗 have a nice day")
	hf.Log("Exit Error: " + hf.GetExitError())
	hf.Log("Exit Code: " + hf.GetExitCode())
}
```

## Remote loading of the wasm module

You can download the wasm module from a remote location before executing it:

For example, provide the wasm file with an HTTP server, run this command at the root of your project:
```bash
python3 -m http.server 9090
```
> Now you can download the wasm file with this url: http://localhost:9090/hello.wasm


Serve the `Handle` function:
```bash
export MESSAGE="🖐 good morning 😄"
./capsule \
   -url=http://localhost:9090/hello.wasm \
   -wasm=./tmp/hello.wasm \
   -mode=http \
   -httpPort=8080
```
> - `-url` flag: the download url
> - `-wasm` flag: the path where to save the wasm file

## GET Request

**Capsule** accept the `GET` requests, so you can serve, for example, HTML:

```golang
package main

import hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"

// main is required.
func main() {
	hf.SetHandleHttp(Handle)
}

func Handle(request hf.Request) (response hf.Response, errResp error) {
	html := `
    <html>
        <head>
            <title>Wasm is fantastic 😍</title>
        </head>

        <body>
            <h1>👋 Hello World 🌍</h1>
            <h2>Served with 💜 with Capsule 💊</h2>
        </body>

    </html>
    `

	headersResp := map[string]string{
		"Content-Type": "text/html; charset=utf-8",
	}

	return hf.Response{Body: html, Headers: headersResp}, nil
}
```

Build the wasm module:
```bash
tinygo build -o hello.wasm -scheduler=none --no-debug -target wasi ./hello.go
```

Serve the `Handle` "function page":
```bash
./capsule \
   -wasm=./hello.wasm \
   -mode=http \
   -httpPort=8080
```

Now, you can open http://localhost:8080 with your browser or run a curl request:
```bash
curl http://localhost:8080
```

## First Nats function
> 🖐🚧 The NAT integration with **Capsule** is a work in progress and the functions are subject to change

NATS is an open-source messaging system.

> - About NATS: https://nats.io/ and https://docs.nats.io/
> - Nats Overview: https://docs.nats.io/nats-concepts/overview

### Requirements

#### NATS Server

You need to install and run a NATS server: https://docs.nats.io/running-a-nats-service/introduction/installation.
Otherwise, I created a Virtual Machine for this; If you have installed [Multipass](https://multipass.run/), go to the `./nats/vm-nats` directory of this project. I created some scripts for my experiments:

- `create-vm.sh` *create the multipass VM, the settings of the VM are stored in the `vm.nats.config`*
- `01-install-nats-server.sh` *install the NATS server inside the VM*
- `02-start-nats-server.sh` *start the NATS server*
- `03-stop-nats-server.sh` *stop the NATS server*
- `stop-vm.sh` *stop the VM*
- `start-vm.sh` *start the VM*
- `destroy-vm.sh` *delete the VM*
- `shell-vm.sh` *SSH connect to the VM*

#### NATS Client

You need a NATS client to publish messages. You can find sample of Go and Node.js NATS clients in the `./nats/clients`.

### Run **Capsule** as a NATS subscriber:

```bash
capsule \
   -wasm=../wasm_modules/capsule-nats-subscriber/hello.wasm \
   -mode=nats \
   -natssrv=nats.devsecops.fun:4222 \
   -subject=ping
```
> - use the "NATS mode": `-mode=nats`
> - define the NATS subject: `-subject=<subject_name>`
> - define the address of the NATS server: `-natssrv=<nats_server:port>`

### NATS function

A **Capsule** NATS function is a subscription to a subject. **Capsule** is listening on a subject(like a MQTT topic) and execute a function every time a message is posted on the subject:

```golang
package main

import (
	hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
)

func main() {
	hf.OnNatsMessage(Handle) // define the triggered function when a message "arrives" on the subject/topic
}

// at every message on the subject channel, the `Handle` function is executed
func Handle(params []string) {
	// send a message to another subject
	_, err := hf.NatsPublish("notify", "it's a wasm module here")

	if err != nil {
		hf.Log("😡 ouch something bad is happening")
		hf.Log(err.Error())
	}
}
```


### Capsule NATS publisher
> Publish NATS messages from capsule

You can use a **WASM Capsule module** to publish NATS messages, even if **Capsule** is not started in "nats" mode, for example from a **WASM CLI Capsule module**:

```golang
package main

import (
    "errors"
    hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
    "strings"
)

func main() {
    hf.SetHandle(Handle)
}

func Handle(params []string) (string, error) {
    var errs []string

    // a new connection is created at every call/publish
    _, err1stMsg := hf.NatsConnectPublish("nats.devsecops.fun:4222", "ping", "🖐 Hello from WASM with Nats 💜")
    _, err2ndMsg := hf.NatsConnectPublish("nats.devsecops.fun:4222", "notify", "👋 Hello World 🌍")

    if err1stMsg != nil {
        errs = append(errs, err1stMsg.Error())
    }
    if err2ndMsg != nil {
        errs = append(errs, err2ndMsg.Error())
    }

    return "NATS Rocks!", errors.New(strings.Join(errs, "|"))
}
```
> In this use case, you need to define the NATS server and create a connection

### Request and Reply

A NATS "publisher" can make a request to a NATS "subscriber" and wait for an answer

```golang
package main

import (
	"errors"
	hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
	"strings"
)

func main() {
	hf.SetHandle(Handle)
}

func Handle(params []string) (string, error) {

	// Publish and wait for an answer; 1 is the timeout in seconds
	res, err := hf.NatsConnectRequest("nats.devsecops.fun:4222", "notify", "👋 Hello World 🌍", 1)

	if err != nil {
		hf.Log("🔴" + err.Error())
	} else {
        // Display the answer
		hf.Log("🔵" + res)
	}

	return "NATS Rocks!", err
}
```

A NATS "subscriber" can reply to a request received on its subject

```golang
package main

import (
	hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
)

func main() {
	hf.OnNatsMessage(Handle)
}

func Handle(params []string) {

	hf.Log("Message on subject: " + hf.NatsGetSubject() + ", 🎉 message: " + params[0])

	// reply to the message on the current subject; 10 is the timeout in seconds
	_, _ = hf.NatsReply("Hey! What's up", 10)

}
```


## First MQTT function
> 🖐🚧 The MQTT integration with **Capsule** is a work in progress and the functions are subject to change

MQTT is a standard for IOT message.

> - About MQTT: https://mqtt.org/

### Requirements

#### MQTT Server

You need to install and run a MQTT server. To do so, go to the `./mqtt` directory of this project and run the docker-compose file

### Run **Capsule** as a MQTT subscriber:

```bash
capsule \
   -wasm=../wasm_modules/capsule-mqtt-subscriber/hello.wasm \
   -mode=mqtt \
   -mqttsrv=127.0.0.1:1883 \
   -topic=topic/sensor0 \
   -clientId=sensor
```
> - use the "MQTT mode": `-mode=mqtt`
> - define the MQTT topic: `-topic=<topic_name>`
> - define the MQTT clientId: `-clientId=<clientId>`
> - define the address of the MQTT server: `-mqttsrv=<mqtt_server:port>`

### MQTT function

A **Capsule** MQTT function is a subscription to a subject. **Capsule** is listening on a topic and execute a function every time a message is posted on the subject:

```golang
package main

import (
	hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
)

func main() {
	hf.OnMqttMessage(Handle) // define the triggered function when a message "arrives" on the topic
}

// at every message on the subject channel, the `Handle` function is executed
func Handle(params []string) {
	// send a message to another subject
	_, err := hf.MqttPublish("topic/reply", "it's a wasm module here")

	if err != nil {
		hf.Log("😡 ouch something bad is happening")
		hf.Log(err.Error())
	}
}
```


### Capsule MQTT publisher
> Publish MQTT messages from capsule

You can use a **WASM Capsule module** to MQTT messages, even if **Capsule** is not started in "mqtt" mode, for example from a **WASM CLI Capsule module**:

```golang
package main

import (
    "errors"
    hf "github.com/bots-garden/capsule/capsulemodule/hostfunctions"
    "strings"
)

func main() {
    hf.SetHandle(Handle)
}

func Handle(params []string) (string, error) {
    var errs []string

    // a new connection is created at every call/publish
	_, err1stMsg := hf.MqttConnectPublish("127.0.0.1:1883", "sensor", "topic/sensor1", "🖐 Hello from WASM with MQTT 💜")
	_, err2ndMsg := hf.MqttConnectPublish("127.0.0.1:1883", "sensor", "topic/sensor2", "👋 Hello World 🌍")

    if err1stMsg != nil {
        errs = append(errs, err1stMsg.Error())
    }
    if err2ndMsg != nil {
        errs = append(errs, err2ndMsg.Error())
    }

    return "MQTT Rocks!", errors.New(strings.Join(errs, "|"))
}
```
> In this use case, you need to define the MQTT server and create a connection
