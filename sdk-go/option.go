package buffer

type Option func(*MultiValueSet)

func WithSizeLimit(size int) Option {
	return func(m *MultiValueSet) {
		m.size = uint64(size)
	}
}
