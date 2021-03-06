fn initialize-table _self: (addr table), n: int {
  var self/esi: (addr table) <- copy _self
  var data-ah/eax: (addr handle array bind) <- get self, data
  populate data-ah, n
}

fn bind-int-in-table _self: (addr table), key: (addr handle array byte), val: int {
  var self/esi: (addr table) <- copy _self
  var data-ah/esi: (addr handle array bind) <- get self, data
  var _data/eax: (addr array bind) <- lookup *data-ah
  var data/esi: (addr array bind) <- copy _data
  var next-empty-slot-index/eax: (offset bind) <- next-empty-slot data, key
  var dest/eax: (addr bind) <- index data, next-empty-slot-index
  make-binding dest, key, val
}

# manual test: full array of binds
fn next-empty-slot _data: (addr array bind), key: (addr handle array byte) -> result/eax: (offset bind) {
  var data/esi: (addr array bind) <- copy _data
  var len/ecx: int <- length data
  var i/edx: int <- copy 0
  $next-empty-slot:loop: {
    result <- compute-offset data, i
    compare i, len
    break-if->=
    {
      var target/esi: (addr bind) <- index data, result
      var target2/esi: (addr handle array byte) <- get target, key
      var target3/eax: (addr array byte) <- lookup *target2
      compare target3, 0
      break-if-= $next-empty-slot:loop
      # TODO: how to indicate that key already exists? we don't want to permit rebinding
    }
    i <- increment
    loop
  }
}

fn make-binding _self: (addr bind), key: (addr handle array byte), _val: int {
  var self/esi: (addr bind) <- copy _self
  var dest/eax: (addr handle array byte) <- get self, key
  copy-object key, dest
  var dest2/eax: (addr handle value) <- get self, value
  allocate dest2
  var dest3/eax: (addr value) <- lookup *dest2
  var dest4/eax: (addr int) <- get dest3, scalar-data
  var val/ecx: int <- copy _val
  copy-to *dest4, val
}

fn lookup-binding _self: (addr table), key: (addr array byte), out: (addr handle value) {
  var self/esi: (addr table) <- copy _self
  var data-ah/esi: (addr handle array bind) <- get self, data
  var _data/eax: (addr array bind) <- lookup *data-ah
  var data/esi: (addr array bind) <- copy _data
  var len/edx: int <- length data
  var i/ebx: int <- copy 0
  $lookup-binding:loop: {
    compare i, len
    break-if->=
    {
      var offset/edx: (offset bind) <- compute-offset data, i
      var target-bind/esi: (addr bind) <- index data, offset
      var target2/edx: (addr handle array byte) <- get target-bind, key
      var target3/eax: (addr array byte) <- lookup *target2
      compare target3, 0
      break-if-= $lookup-binding:loop
      var is-match?/eax: boolean <- string-equal? target3, key
      compare is-match?, 0  # false
      break-if-=
      # found
      var target/eax: (addr handle value) <- get target-bind, value
      copy-object target, out
      break $lookup-binding:loop
    }
    i <- increment
    loop
  }
}
