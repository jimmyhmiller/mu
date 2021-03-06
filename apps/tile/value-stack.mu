# support for non-int values is untested

type value-stack {
  data: (handle array value)
  top: int
}

fn initialize-value-stack _self: (addr value-stack), n: int {
  var self/esi: (addr value-stack) <- copy _self
  var d/edi: (addr handle array value) <- get self, data
  populate d, n
  var top/eax: (addr int) <- get self, top
  copy-to *top, 0
}

fn clear-value-stack _self: (addr value-stack) {
  var self/esi: (addr value-stack) <- copy _self
  var top/eax: (addr int) <- get self, top
  copy-to *top, 0
}

fn push-int-to-value-stack _self: (addr value-stack), _val: int {
  var self/esi: (addr value-stack) <- copy _self
  var top-addr/ecx: (addr int) <- get self, top
  var data-ah/edx: (addr handle array value) <- get self, data
  var data/eax: (addr array value) <- lookup *data-ah
  var top/edx: int <- copy *top-addr
  var dest-offset/edx: (offset value) <- compute-offset data, top
  var dest-addr/edx: (addr value) <- index data, dest-offset
  var dest-addr2/eax: (addr int) <- get dest-addr, scalar-data
  var val/esi: int <- copy _val
#?   print-int32-hex-to-real-screen val
  copy-to *dest-addr2, val
  increment *top-addr
}

fn push-value-stack _self: (addr value-stack), val: (addr value) {
  var self/esi: (addr value-stack) <- copy _self
  var top-addr/ecx: (addr int) <- get self, top
  var data-ah/edx: (addr handle array value) <- get self, data
  var data/eax: (addr array value) <- lookup *data-ah
  var top/edx: int <- copy *top-addr
  var dest-offset/edx: (offset value) <- compute-offset data, top
  var dest-addr/edx: (addr value) <- index data, dest-offset
  copy-object val, dest-addr
  increment *top-addr
}

fn pop-int-from-value-stack _self: (addr value-stack) -> val/eax: int {
$pop-int-from-value-stack:body: {
  var self/esi: (addr value-stack) <- copy _self
  var top-addr/ecx: (addr int) <- get self, top
  {
    compare *top-addr, 0
    break-if->
    val <- copy -1
    break $pop-int-from-value-stack:body
  }
  decrement *top-addr
  var data-ah/edx: (addr handle array value) <- get self, data
  var data/eax: (addr array value) <- lookup *data-ah
  var top/edx: int <- copy *top-addr
  var dest-offset/edx: (offset value) <- compute-offset data, top
  var result-addr/eax: (addr value) <- index data, dest-offset
  var result-addr2/eax: (addr int) <- get result-addr, scalar-data
  val <- copy *result-addr2
}
}

fn value-stack-empty? _self: (addr value-stack) -> result/eax: boolean {
$value-stack-empty?:body: {
  var self/esi: (addr value-stack) <- copy _self
  var top/eax: (addr int) <- get self, top
  compare *top, 0
  {
    break-if-!=
    result <- copy 1  # true
    break $value-stack-empty?:body
  }
  result <- copy 0  # false
}
}

fn value-stack-length _self: (addr value-stack) -> result/eax: int {
  var self/esi: (addr value-stack) <- copy _self
  var top-addr/eax: (addr int) <- get self, top
  result <- copy *top-addr
}

fn value-stack-max-width _self: (addr value-stack) -> result/eax: int {
  var self/esi: (addr value-stack) <- copy _self
  var data-ah/edi: (addr handle array value) <- get self, data
  var _data/eax: (addr array value) <- lookup *data-ah
  var data/edi: (addr array value) <- copy _data
  var top-addr/ecx: (addr int) <- get self, top
  var i/ebx: int <- copy 0
  result <- copy 0
  {
    compare i, *top-addr
    break-if->=
    var o/edx: (offset value) <- compute-offset data, i
    var g/edx: (addr value) <- index data, o
    var g2/edx: (addr int) <- get g, scalar-data
    var w/ecx: int <- int-width-decimal *g2
    compare w, result
    {
      break-if-<=
      result <- copy w
    }
    i <- increment
    loop
  }
}
