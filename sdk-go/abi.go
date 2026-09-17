package buffer

import (
	"unsafe"
)

var (
	id      uint64
	setID   uint64
	errCode uint32
	bufCap  uint32 = 1 << 20
	bufLen  uint32
	buf     = make([]byte, int(bufCap))
	meta    = make([]uint32, 6)
)

//export __buffer
func __buffer() (res uint32) {
	for i, p := range []unsafe.Pointer{
		unsafe.Pointer(&id),
		unsafe.Pointer(&setID),
		unsafe.Pointer(&bufCap),
		unsafe.Pointer(&bufLen),
		unsafe.Pointer(&buf[0]),
		unsafe.Pointer(&errCode),
	} {
		meta[i] = uint32(uintptr(p))
	}
	return uint32(uintptr(unsafe.Pointer(&meta[0])))
}

//go:wasm-module pantopic/ext-buffer
//export __buffer_multi_append
func _multi_append(uint32, uint32)

//go:wasm-module pantopic/ext-buffer
//export __buffer_multi_load
func _multi_load()

//go:wasm-module pantopic/ext-buffer
//export __buffer_multi_reset
func _multi_reset()

// Fix for lint rule `unusedfunc`
var _ = __buffer
