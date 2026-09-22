# Buffer

A pantopic extension providing external buffers.

## Host Module

[![Go Reference](https://godoc.org/github.com/pantopic/ext-buffer/wazero-host?status.svg)](https://godoc.org/github.com/pantopic/ext-buffer/wazero-host)
[![Go Report Card](https://goreportcard.com/badge/github.com/pantopic/ext-buffer/wazero-host)](https://goreportcard.com/report/github.com/pantopic/ext-buffer/wazero-host)
[![Go Coverage](https://github.com/pantopic/ext-buffer/wiki/host/coverage.svg)](https://raw.githack.com/wiki/pantopic/ext-buffer/wazero-host/coverage.html)

First register the host module with the runtime

```go
import (
    "github.com/tetratelabs/wazero"
    "github.com/tetratelabs/wazero/imports/wasi_snapshot_preview1"

    "github.com/pantopic/ext-buffer/wazero-host"
)

func main() {
    ctx := context.Background()
    r := wazero.NewRuntimeWithConfig(ctx, wazero.NewRuntimeConfig())
    wasi_snapshot_preview1.MustInstantiate(ctx, r)

    module := wazero_buffer.New()
    module.Register(ctx, r)

    // ...
}
```

## Guest SDK (Go)

[![Go Reference](https://godoc.org/github.com/pantopic/ext-buffer/sdk-go?status.svg)](https://godoc.org/github.com/pantopic/ext-buffer/sdk-go)
[![Go Report Card](https://goreportcard.com/badge/github.com/pantopic/ext-buffer/sdk-go)](https://goreportcard.com/report/github.com/pantopic/ext-buffer/sdk-go)

Then you can import the guest SDK into your WASI module to send messages from one WASI module to another.

```go
package main

import (
    "github.com/pantopic/ext-buffer/sdk-go"
)

const (
	BUFFER_POOL_TEST = iota
)

var set *buffer.MultiValueSet

func main() {
    set = buffer.NewMutliValueSet(BUFFER_POOL_TEST)
}

//export test
func test() {
    buf := set.Find(1)
    buf.Append([]byte(`a`))
    buf.Append([]byte(`b`))
    for val := range buf.Iter() {
        println(string(val)) // a, b
    }
    buf.Reset()
}
```

## Roadmap

This project is in alpha. Breaking API changes should be expected until Beta.

- `v0.0.x` - Alpha
  - [ ] Stabilize API
- `v0.x.x` - Beta
  - [ ] Finalize API
  - [ ] Test in production
- `v1.x.x` - General Availability
  - [ ] Proven long term stability in production
