# Mu: a human-scale computer

Mu is a minimal-dependency hobbyist computing stack (everything above the
processor and OS kernel).

Mu is not designed to operate in large clusters providing services for
millions of people. Mu is designed for _you_, to run one computer. (Or a few.)
Running the code you want to run, and nothing else.

```sh
$ git clone https://github.com/akkartik/mu
$ cd mu
$ ./translate_mu apps/ex2.mu  # emit a.elf
$ ./a.elf  # adds 3 and 4
$ echo $?
7
```

[![Build Status](https://api.travis-ci.org/akkartik/mu.svg?branch=master)](https://travis-ci.org/akkartik/mu)

Rather than start from some syntax and introduce layers of translation to
implement it, Mu starts from the processor's instruction set and tries to get
to _some_ safe and clear syntax with as few layers of translation as possible.
The emphasis is on internal consistency at any point in time rather than
compatibility with the past. ([More details.](http://akkartik.name/akkartik-convivial-20200607.pdf))

Currently Mu requires a 32-bit x86 processor and Linux kernel.

## Goals

In priority order:

- [Reward curiosity.](http://akkartik.name/about)
  - Easy to build, easy to run. [Minimal dependencies](https://news.ycombinator.com/item?id=16882140#16882555),
    so that installation is always painless.
  - All design decisions comprehensible to a single individual. (On demand.)
  - All design decisions comprehensible without needing to talk to anyone.
    (I always love talking to you, but I try hard to make myself redundant.)
  - [A globally comprehensible _codebase_ rather than locally clean code.](http://akkartik.name/post/readable-bad)
  - Clear error messages over expressive syntax.
- Safe.
  - Thorough test coverage. If you break something you should immediately see
    an error message. If you can manually test for something you should be
    able to write an automated test for it.
  - Memory leaks over memory corruption.
- Teach the computer bottom-up.

## Non-goals

- Speed. Staying close to machine code should naturally keep Mu fast enough.
- Efficiency. Controlling the number of abstractions should naturally keep Mu
  using far less than the gigabytes of memory modern computers have.
- Portability. Mu will run on any computer as long as it's x86. I will
  enthusiastically contribute to support for other processors -- in separate
  forks. Readers shouldn't have to think about processors they don't have.
- Compatibility. The goal is to get off mainstream stacks, not to perpetuate
  them. Sometimes the right long-term solution is to [bump the major version number](http://akkartik.name/post/versioning).
- Syntax. Mu code is meant to be comprehended by [running, not just reading](http://akkartik.name/post/comprehension).
  For now it's a thin veneer over machine code. I'm working on memory safety
  before expressive syntax.

## Toolchain

The Mu stack consists of:
- the Mu type-safe language;
- SubX, an unsafe notation for a subset of x86 machine code; and
- _bare_ SubX, a more rudimentary form of SubX without certain syntax sugar.

All Mu programs get translated through these layers into tiny zero-dependency
ELF binaries. The translators for most levels are built out of lower levels.
The translator from Mu to SubX is written in SubX, and the translator from
SubX to bare SubX is built in bare SubX.

Mu programs can be run in emulated mode to emit traces, which permit time-travel
debugging. ([More details.](subx_debugging.md))

### incomplete tools

The Mu translator is still a work in progress; not all incorrect programs
result in good error messages.

Once generated, ELF binaries can be packaged up with a Linux kernel into a
bootable disk image:

```sh
$ ./translate_mu apps/ex2.mu  # emit a.elf
# dependencies
$ sudo apt install build-essential flex bison wget libelf-dev libssl-dev xorriso
$ tools/iso/linux a.elf
$ qemu-system-x86_64 -m 256M -cdrom mu_linux.iso -boot d
```

The disk image also runs on [any cloud server that supports custom images](http://akkartik.name/post/iso-on-linode).

Mu also runs on the minimal hobbyist OS [Soso](https://github.com/ozkl/soso).
(Requires graphics and sudo access. Currently doesn't work on a cloud server.)

```sh
$ ./translate_mu apps/ex2.mu  # emit a.elf
# dependencies
$ sudo apt install build-essential util-linux nasm xorriso  # maybe also dosfstools and mtools
$ tools/iso/soso a.elf  # requires sudo
$ qemu-system-i386 -cdrom mu_soso.iso
```

## Syntax

The entire stack shares certain properties and conventions. Programs consist
of functions and functions consist of statements, each performing a single
operation. Operands to statements are always variables or constants. You can't
say `a + b*c`, you have to break it up into two operations. Variables can live
in memory or in registers. Registers must be explicitly specified. There are
some shared lexical rules; comments always start with '#', and numbers are
always written in hex.

Here's an example program in Mu:

<img alt='ex2.mu' src='html/ex2.mu.png'>

[More details on Mu syntax &rarr;](mu.md)

Here's an example program in SubX:

```sh
== code
Entry:
  # ebx = 1
  bb/copy-to-ebx  1/imm32
  # increment ebx
  43/increment-ebx
  # exit(ebx)
  e8/call  syscall_exit/disp32
```

[More details on SubX syntax &rarr;](subx.md)

## Forks

Forks of Mu are encouraged. If you don't like something about this repo, feel
free to make a fork. If you show it to me, I'll link to it here, so others can
use it. I might even pull your changes into this repo!

- [mu-normie](https://git.sr.ht/~akkartik/mu-normie): with a more standard
  build system and C++ modules.

## Desiderata

If you're still reading, here are some more things to check out:

- The references on [Mu](mu.md) and [SubX](subx.md) syntax, and also [bare
  SubX](subx_bare.md) without any syntax sugar.

- [How to get your text editor set up for Mu and SubX programs.](editor.md)

- [Some tips for debugging SubX programs.](subx_debugging.md)

- [Shared vocabulary of data types and functions shared by Mu programs.](vocabulary.md)
  Mu programs can transparently call low-level functions written in SubX.

- [A summary](mu_instructions) of how the Mu compiler translates instructions
  to SubX. ([colorized version](http://akkartik.github.io/mu/html/mu_instructions.html))

- [Some starter exercises for learning SubX](https://github.com/akkartik/mu/pulls)
  (labelled `hello`). Feel free to [ping me](mailto:ak@akkartik.com) with any questions.

- [Commandline reference for the bootstrap C++ program.](bootstrap.md)

- The [list of x86 opcodes](subx_opcodes) supported in SubX: `./bootstrap
  help opcodes`.

- [Some details on the unconventional organization of this project.](http://akkartik.name/post/four-repos)

- Previous prototypes: [mu0](https://github.com/akkartik/mu0), [mu1](https://github.com/akkartik/mu1).

## Credits

Mu builds on many ideas that have come before, especially:

- [Peter Naur](http://akkartik.name/naur.pdf) for articulating the paramount
  problem of programming: communicating a codebase to others;
- [Christopher Alexander](http://www.amazon.com/Notes-Synthesis-Form-Harvard-Paperbacks/dp/0674627512)
  and [Richard Gabriel](http://dreamsongs.net/Files/PatternsOfSoftware.pdf) for
  the intellectual tools for reasoning about the higher order design of a
  codebase;
- [David Parnas](http://www.cs.umd.edu/class/spring2003/cmsc838p/Design/criteria.pdf)
  and others for highlighting the value of separating concerns and stepwise
  refinement;
- The folklore of debugging by print and the trace facility in many lisp
  systems;
- Automated tests for showing the value of developing programs inside an
  elaborate harness;
- [Minimal Linux Live](http://minimal.linux-bg.org) for teaching how to create
  a bootable disk image.
- [&ldquo;Bootstrapping a compiler from nothing&rdquo;](http://web.archive.org/web/20061108010907/http://www.rano.org/bcompiler.html) by Edmund Grumley-Evans.
- [&ldquo;Creating tiny ELF executables&rdquo;](https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html) by Brian Raiter.
- [StoneKnifeForth](https://github.com/kragen/stoneknifeforth) by [Kragen Sitaker](http://canonical.org/~kragen).
