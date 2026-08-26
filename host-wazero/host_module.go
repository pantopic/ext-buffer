package wazero_buffer

import (
	"context"
	"encoding/binary"
	"log"
	"sync"

	"github.com/tetratelabs/wazero"
	"github.com/tetratelabs/wazero/api"
)

// Name is the name of this host module.
const Name = "pantopic/ext-buffer"

var (
	ctxKeyMeta = Name + `/meta`
	ctxKeyPool = Name + `/pool`
)

type meta struct {
	ptrID      uint32
	ptrSize    uint32
	ptrSetID   uint32
	ptrErrCode uint32
}

type hostModule struct {
	sync.RWMutex

	module api.Module
}

type Option func(*hostModule)

func New(opts ...Option) *hostModule {
	p := &hostModule{}
	for _, opt := range opts {
		opt(p)
	}
	return p
}

func (h *hostModule) Name() string {
	return Name
}

func (h *hostModule) ContextCopy(dst, src context.Context) context.Context {
	if v := src.Value(ctxKeyMeta); v != nil {
		dst = context.WithValue(dst, ctxKeyMeta, v.(*meta))
		if v := src.Value(ctxKeyPool); v != nil {
			dst = context.WithValue(dst, ctxKeyPool, v.(map[uint64]map[uint64][]byte))
		} else {
			dst = context.WithValue(dst, ctxKeyPool, make(map[uint64]map[uint64][]byte))
		}
	}
	return dst
}

func (h *hostModule) Stop() {}

// Register instantiates the host module, making it available to all module instances in this runtime
func (h *hostModule) Register(ctx context.Context, r wazero.Runtime) (err error) {
	builder := r.NewHostModuleBuilder(Name)
	register := func(name string, in, out []api.ValueType, fn func(ctx context.Context, m api.Module, stack []uint64)) {
		builder = builder.NewFunctionBuilder().WithGoModuleFunction(api.GoModuleFunc(fn), in, out).Export(name)
	}
	register("__buffer_multi_reset", nil, nil,
		func(ctx context.Context, mod api.Module, stack []uint64) {
			meta := get[*meta](ctx, ctxKeyMeta)
			m := h.getMap(ctx, mod, meta)
			id := getID(mod, meta)
			delete(m, id)
		})
	register("__buffer_multi_append", []api.ValueType{api.ValueTypeI32, api.ValueTypeI32}, nil,
		func(ctx context.Context, mod api.Module, stack []uint64) {
			meta := get[*meta](ctx, ctxKeyMeta)
			errCode := uint32(0)
			m := h.getMap(ctx, mod, meta)
			id := getID(mod, meta)
			v := getBuf(mod, api.DecodeU32(stack[0]), api.DecodeU32(stack[1]))
			if _, ok := m[id]; !ok {
				m[id] = make([]byte, 0, getSize(mod, meta))
			}
			var scratch = make([]byte, 8)
			n := binary.PutUvarint(scratch, uint64(len(v)))
			if len(m[id])+n+len(v) > cap(m[id]) {
				errCode = 1
			} else {
				m[id] = append(binary.AppendUvarint(m[id], uint64(len(v))), v...)
			}
			writeUint32(mod, meta.ptrErrCode, errCode)
		})
	register("__buffer_multi_load", []api.ValueType{api.ValueTypeI32, api.ValueTypeI32}, []api.ValueType{api.ValueTypeI32},
		func(ctx context.Context, mod api.Module, stack []uint64) {
			meta := get[*meta](ctx, ctxKeyMeta)
			m := h.getMap(ctx, mod, meta)
			id := getID(mod, meta)
			buf := getBuf(mod, api.DecodeU32(stack[0]), api.DecodeU32(stack[1]))
			if cap(buf) < len(m[id]) {
				writeUint32(mod, meta.ptrErrCode, 2)
				stack[0] = 0
				return
			}
			copy(buf[:len(m[id])], m[id])
			writeUint32(mod, meta.ptrErrCode, 0)
			stack[0] = api.EncodeU32(uint32(len(m[id])))
		})
	h.module, err = builder.Instantiate(ctx)
	return
}

// InitContext retrieves the meta page from the wasm module
func (h *hostModule) InitContext(ctx context.Context, m api.Module) (context.Context, error) {
	fn := m.ExportedFunction(`__buffer`)
	if fn == nil {
		return ctx, nil
	}
	stack, err := fn.Call(ctx)
	if err != nil {
		return ctx, err
	}
	meta := &meta{}
	ptr := uint32(stack[0])
	for i, v := range []*uint32{
		&meta.ptrID,
		&meta.ptrSize,
		&meta.ptrSetID,
		&meta.ptrErrCode,
	} {
		*v = readUint32(m, ptr+uint32(4*i))
	}
	return context.WithValue(ctx, ctxKeyMeta, meta), nil
}

func (h *hostModule) getMap(ctx context.Context, mod api.Module, meta *meta) map[uint64][]byte {
	id := readUint64(mod, meta.ptrID)
	m := get[map[uint64]map[uint64][]byte](ctx, ctxKeyPool)
	h.RLock()
	_, ok := m[id]
	h.RUnlock()
	if !ok {
		h.Lock()
		if _, ok := m[id]; !ok {
			m[id] = map[uint64][]byte{}
		}
		h.Unlock()
	}
	return m[id]
}

func getID(mod api.Module, meta *meta) uint64 {
	return readUint64(mod, meta.ptrID)
}

func getSize(mod api.Module, meta *meta) uint64 {
	return readUint64(mod, meta.ptrSize)
}

func getBuf(mod api.Module, ptrBuf uint32, bufLen uint32) []byte {
	buf, ok := mod.Memory().Read(ptrBuf, bufLen)
	if !ok {
		log.Panicf("Memory.Read(%d, %d) out of range", ptrBuf, bufLen)
	}
	return buf
}

func get[T any](ctx context.Context, key string) T {
	v := ctx.Value(key)
	if v == nil {
		log.Panicf("Context item missing %s", key)
	}
	return v.(T)
}

func id(m api.Module, meta *meta) uint32 {
	return readUint32(m, meta.ptrID)
}

func readUint32(m api.Module, ptr uint32) (val uint32) {
	val, ok := m.Memory().ReadUint32Le(ptr)
	if !ok {
		log.Panicf("Memory.Read(%d) out of range", ptr)
	}
	return
}

func read(m api.Module, ptrData, ptrLen, ptrCap uint32) (buf []byte) {
	buf, ok := m.Memory().Read(ptrData, readUint32(m, ptrCap))
	if !ok {
		log.Panicf("Memory.Read(%d, %d) out of range", ptrData, ptrLen)
	}
	return buf[:readUint32(m, ptrLen)]
}

func readUint64(m api.Module, ptr uint32) (val uint64) {
	val, ok := m.Memory().ReadUint64Le(ptr)
	if !ok {
		log.Panicf("Memory.Read(%d) out of range", ptr)
	}
	return
}

func writeUint64(m api.Module, ptr uint32, val uint64) {
	if ok := m.Memory().WriteUint64Le(ptr, val); !ok {
		log.Panicf("Memory.Read(%d) out of range", ptr)
	}
}

func writeUint32(m api.Module, ptr uint32, val uint32) {
	if ok := m.Memory().WriteUint32Le(ptr, val); !ok {
		log.Panicf("Memory.Read(%d) out of range", ptr)
	}
}
