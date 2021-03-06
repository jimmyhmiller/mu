fn evaluate functions: (addr handle function), bindings: (addr table), scratch: (addr line), end: (addr word), out: (addr value-stack) {
  var line/eax: (addr line) <- copy scratch
  var word-ah/eax: (addr handle word) <- get line, data
  var curr/eax: (addr word) <- lookup *word-ah
  var curr-stream-storage: (stream byte 0x10)
  var curr-stream/edi: (addr stream byte) <- address curr-stream-storage
  clear-value-stack out
  $evaluate:loop: {
    # precondition (should never hit)
    compare curr, 0
    break-if-=
    # update curr-stream
    emit-word curr, curr-stream
#?     print-stream-to-real-screen curr-stream
#?     print-string-to-real-screen "\n"
    $evaluate:process-word: {
      # if curr-stream is an operator, perform it
      {
        var is-add?/eax: boolean <- stream-data-equal? curr-stream, "+"
        compare is-add?, 0
        break-if-=
        var _b/eax: int <- pop-int-from-value-stack out
        var b/edx: int <- copy _b
        var a/eax: int <- pop-int-from-value-stack out
        a <- add b
        push-int-to-value-stack out, a
        break $evaluate:process-word
      }
      {
        var is-sub?/eax: boolean <- stream-data-equal? curr-stream, "-"
        compare is-sub?, 0
        break-if-=
        var _b/eax: int <- pop-int-from-value-stack out
        var b/edx: int <- copy _b
        var a/eax: int <- pop-int-from-value-stack out
        a <- subtract b
        push-int-to-value-stack out, a
        break $evaluate:process-word
      }
      {
        var is-mul?/eax: boolean <- stream-data-equal? curr-stream, "*"
        compare is-mul?, 0
        break-if-=
        var _b/eax: int <- pop-int-from-value-stack out
        var b/edx: int <- copy _b
        var a/eax: int <- pop-int-from-value-stack out
        a <- multiply b
        push-int-to-value-stack out, a
        break $evaluate:process-word
      }
      # if curr-stream is a known function name, call it appropriately
      {
        var callee-h: (handle function)
        var callee-ah/eax: (addr handle function) <- address callee-h
        find-function functions, curr-stream, callee-ah
        var callee/eax: (addr function) <- lookup *callee-ah
        compare callee, 0
        break-if-=
        perform-call callee, out, functions
        break $evaluate:process-word
      }
      # if it's a name, push its value
      {
        compare bindings, 0
        break-if-=
        var tmp: (handle array byte)
        var curr-string-ah/edx: (addr handle array byte) <- address tmp
        stream-to-string curr-stream, curr-string-ah  # unfortunate leak
        var curr-string/eax: (addr array byte) <- lookup *curr-string-ah
        var val-storage: (handle value)
        var val-ah/edi: (addr handle value) <- address val-storage
        lookup-binding bindings, curr-string, val-ah
        var val/eax: (addr value) <- lookup *val-ah
        compare val, 0
        break-if-=
#?         print-string-to-real-screen "value of "
#?         print-string-to-real-screen curr-string
#?         print-string-to-real-screen " is "
#?         print-int32-hex-to-real-screen result
#?         print-string-to-real-screen "\n"
        push-value-stack out, val
        break $evaluate:process-word
      }
      # otherwise assume it's a literal int and push it
      {
        var n/eax: int <- parse-decimal-int-from-stream curr-stream
        push-int-to-value-stack out, n
      }
    }
    # termination check
    compare curr, end
    break-if-=
    # update
    var next-word-ah/edx: (addr handle word) <- get curr, next
    curr <- lookup *next-word-ah
    #
    loop
  }
}

fn find-function first: (addr handle function), name: (addr stream byte), out: (addr handle function) {
  var curr/esi: (addr handle function) <- copy first
  $find-function:loop: {
    var _f/eax: (addr function) <- lookup *curr
    var f/ecx: (addr function) <- copy _f
    compare f, 0
    break-if-=
    var curr-name-ah/eax: (addr handle array byte) <- get f, name
    var curr-name/eax: (addr array byte) <- lookup *curr-name-ah
    var done?/eax: boolean <- stream-data-equal? name, curr-name
    compare done?, 0  # false
    {
      break-if-=
      copy-handle *curr, out
      break $find-function:loop
    }
    curr <- get f, next
    loop
  }
}

fn perform-call _callee: (addr function), caller-stack: (addr value-stack), functions: (addr handle function) {
  var callee/ecx: (addr function) <- copy _callee
  # create bindings for args
  var table-storage: table
  var table/esi: (addr table) <- address table-storage
  initialize-table table, 0x10
  bind-args callee, caller-stack, table
  # obtain body
  var body-ah/eax: (addr handle line) <- get callee, body
  var body/eax: (addr line) <- lookup *body-ah
  # perform call
  var stack-storage: value-stack
  var stack/edi: (addr value-stack) <- address stack-storage
  initialize-value-stack stack, 0x10
#?   print-string-to-real-screen "about to enter recursive eval\n"
  evaluate functions, table, body, 0, stack
#?   print-string-to-real-screen "exited recursive eval\n"
  # stitch result from stack into caller
  var result/eax: int <- pop-int-from-value-stack stack
  push-int-to-value-stack caller-stack, result
}

fn bind-args _callee: (addr function), caller-stack: (addr value-stack), table: (addr table) {
  var callee/ecx: (addr function) <- copy _callee
  var curr-arg-ah/eax: (addr handle word) <- get callee, args
  var curr-arg/eax: (addr word) <- lookup *curr-arg-ah
  #
  var curr-key-storage: (handle array byte)
  var curr-key/edx: (addr handle array byte) <- address curr-key-storage
  {
    compare curr-arg, 0
    break-if-=
    # create binding
    word-to-string curr-arg, curr-key
    {
#?       var tmp/eax: (addr array byte) <- lookup *curr-key
#?       print-string-to-real-screen "binding "
#?       print-string-to-real-screen tmp
#?       print-string-to-real-screen " to "
      var curr-val/eax: int <- pop-int-from-value-stack caller-stack
#?       print-int32-decimal-to-real-screen curr-val
#?       print-string-to-real-screen "\n"
      bind-int-in-table table, curr-key, curr-val
    }
    #
    var next-arg-ah/edx: (addr handle word) <- get curr-arg, next
    curr-arg <- lookup *next-arg-ah
    loop
  }
}

# Copy of 'simplify' that just tracks the maximum stack depth needed
# Doesn't actually need to simulate the stack, since every word has a predictable effect.
fn max-stack-depth first-word: (addr word), final-word: (addr word) -> result/edi: int {
  var curr-word/eax: (addr word) <- copy first-word
  var curr-depth/ecx: int <- copy 0
  result <- copy 0
  $max-stack-depth:loop: {
    $max-stack-depth:process-word: {
      # handle operators
      {
        var is-add?/eax: boolean <- word-equal? curr-word, "+"
        compare is-add?, 0
        break-if-=
        curr-depth <- decrement
        break $max-stack-depth:process-word
      }
      {
        var is-sub?/eax: boolean <- word-equal? curr-word, "-"
        compare is-sub?, 0
        break-if-=
        curr-depth <- decrement
        break $max-stack-depth:process-word
      }
      {
        var is-mul?/eax: boolean <- word-equal? curr-word, "*"
        compare is-mul?, 0
        break-if-=
        curr-depth <- decrement
        break $max-stack-depth:process-word
      }
      # otherwise it's an int (do we need error-checking?)
      curr-depth <- increment
      # update max depth if necessary
      {
        compare curr-depth, result
        break-if-<=
        result <- copy curr-depth
      }
    }
    # if curr-word == final-word break
    compare curr-word, final-word
    break-if-=
    # curr-word = curr-word->next
    var next-word-ah/edx: (addr handle word) <- get curr-word, next
    curr-word <- lookup *next-word-ah
    #
    loop
  }
}
