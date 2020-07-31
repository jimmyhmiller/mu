# Tests for Mu's stream primitives.

fn test-stream {
  # write an int to a stream, then read it back
  var s: (stream int 4)
  var s2/ecx: (addr stream int 4) <- address s
  var tmp/eax: boolean <- stream-empty? s2
  check-true tmp, "F - test-stream/empty?/0"
  tmp <- stream-full? s2
  check-false tmp, "F - test-stream/full?/0"
  var x: int
  copy-to x, 0x34
  var x2/edx: (addr int) <- address x
  write-to-stream s2, x2
  tmp <- stream-empty? s2
  check-false tmp, "F - test-stream/empty?/1"
  tmp <- stream-full? s2
  check-false tmp, "F - test-stream/full?/1"
  var y: int
  var y2/ebx: (addr int) <- address y
  read-from-stream s2, y2
  check-ints-equal y, 0x34, "F - test-stream"
  tmp <- stream-empty? s2
  check-true tmp, "F - test-stream/empty?/2"
  tmp <- stream-full? s2
  check-false tmp, "F - test-stream/full?/2"
}

fn test-stream-full {
  # write an int to a stream of capacity 1
  var s: (stream int 1)
  var s2/ecx: (addr stream int 1) <- address s
  var tmp/eax: boolean <- stream-full? s2
  check-false tmp, "F - test-stream-full?/pre"
  var x: int
  var x2/edx: (addr int) <- address x
  write-to-stream s2, x2
  tmp <- stream-full? s2
  check-true tmp, "F - test-stream-full?"
}
