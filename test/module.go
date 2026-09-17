package main

import (
	"encoding/binary"

	"github.com/pantopic/ext-buffer/sdk-go"
)

const (
	BUFFER_POOL_MULTI_SET_1 = iota
)

var (
	testMultiValueSet buffer.MultiValueSet
)

func main() {
	testMultiValueSet = buffer.NewMultiValueSet(BUFFER_POOL_MULTI_SET_1)
}

//export testMultiSetAppend
func testMultiSetAppend(id, v uint64) {
	testMultiValueSet.Find(id).Append(binary.LittleEndian.AppendUint64([]byte{}, v))
}

//export testMultiSetIter
func testMultiSetIter(id uint64) (total uint64) {
	for item := range testMultiValueSet.Find(id).Iter() {
		total += binary.LittleEndian.Uint64(item)
	}
	return
}

//export testMultiSetReset
func testMultiSetReset(id uint64) {
	testMultiValueSet.Find(id).Reset()
}
