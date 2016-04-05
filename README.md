# Akeem

*When you think of garbage, think of Akeem.* —
[Prince Akeem of Zamunda](http://www.imdb.com/title/tt0094898/)

Akeem is a small JIT-ed subset of
[R7RS Scheme](http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs.pdf)
("small") written in x86-64 assembler as an experiment.

Written in [GNU Assembler](https://sourceware.org/binutils/docs/as/)
using AT&T syntax. Only builds on Linux as Apple has their own version
of `as`.

Akeem depends on
[glibc](https://www.gnu.org/software/libc/manual/html_mono/libc.html).


## Usage

``` bash
make
`which rlwrap` ./akeem # or make run-repl
```

### Emacs

``` el
(setq scheme-program-name "/path/to/akeem")
(run-scheme)
```

See [this tutorial](http://community.schemewiki.org/?emacs-tutorial).

### Docker

``` bash
make run-docker
```

The
[`Dockerfile`](https://github.com/hraberg/akeem/blob/master/Dockerfile)
will create a development container than can both run and compile
Akeem. Running under Docker should work on Mac as well.

If `rlwrap` crashes, the above command usually works when
trying again.


## What Works?

* Subset of R7RS "small" procedures.
* JIT for `if`, `lambda`, `set!`, `let`, `letrec` and `begin`
* Syntax for `and`, `or`, `cond`, `case`, `when`, `unless`, `let*`,
  "named `let`", `do`, `delay`, `define`, `parameterize`, `guard`,
  `case-lambda` and `define-record-type`.
* Basic support for `define-syntax` / `syntax-rules` and `quasiquote`.
* Basic support for R7RS Exceptions and `dynamic-wind`.
* NaN-boxed 32-bit integers and 64-bit doubles
* Function application up to 6 named arguments with varargs support.
* TCO for calls in tail position across functions.
* The bootstrap Scheme code is embedded in the executable.
* Mark and Sweep GC.


## What Doesn't Work?

* No hygienic macro expansion.
* No GC for functions or their constant literals.
* Max arity is currently 6, higher requires the use of the stack.
* No register allocation.
* No `let-syntax` and `letrec-syntax`.
* No Scheme library system.
* The JIT is static, once a function is generated its done.
* Not full support for Scheme numbers in the reader.
* No support for converting internal `define` to `letrec`.
* No mutation of closed over variables (needs array boxing).
* Closures needlessly capture variables shadowed by inner `let`
  expressions.
* Limited numeric tower, see above.

Most of the above is intended to be solved at some point, in roughly
the order listed. The focus is slightly geared towards hacking on and
exploring the JIT more than aiming for full R7RS compliance.


## Implementation Notes

Akeem is a template based JIT which copies snippets of its own
assembled source to compile functions at runtime - code is data.

It's worth noting that John Aycock in his
[A Brief History of Just-In-Time](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.97.3985&rep=rep1&type=pdf)
doesn't consider template based compilers to be proper JIT compilers:

> As just described, template-based systems arguably do not fit our
> description of JIT compilers, since there would appear to be no
> nontrivial translation aspect.

Akeem is somewhat inspired by Abdulaziz Ghuloum's classic paper
[An Incremental Approach to Compiler Construction](http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf)
and Ian Piumarta's
[PEG-based transformer provides front-, middle and back-end stages in a simple compiler](http://www.vpri.org/pdf/tr2010003_PEG.pdf)
and his related work on [Maru](http://piumarta.com/software/maru/).

Unlike these Lisps Akeem does not generate assembly in text
form. Akeem is inspired by Clojure in the sense that there's only a
JIT compiler to simplify the overall implementation — there's no
interpreter. Also, like Clojure, the compiler is planned to stay close
to a normal procedural language, with limited TCO and no CPS.

### Development

Most of the implementation is in
[`lisp.s`](https://github.com/hraberg/akeem/blob/master/lisp.s). It
relies heavily on
[`macros.s`](https://github.com/hraberg/akeem/blob/master/macros.s) to
make the code less verbose. The
[`tests.scm`](https://github.com/hraberg/akeem/blob/master/tests.scm)
are compared to
[`tests.out`](https://github.com/hraberg/akeem/blob/master/tests.out)
for simple unit testing. To run and keep watching the tests (uses
[entr](http://entrproject.org/)):

``` bash
make retest
```

Parts of the implementation are in
[`boot.scm`](https://github.com/hraberg/akeem/blob/master/boot.scm),
[`r7rs.scm`](https://github.com/hraberg/akeem/blob/master/r7rs.scm)
and
[`init.scm`](https://github.com/hraberg/akeem/blob/master/init.scm),
which are embedded as strings during compilation and are loaded at
startup in this order.

While running, the result of the JIT can be logged into `jit_code` and
can be inspected using `objdump` via:

``` bash
make jit-dissassmble
```
This can be turned on by setting `LOG_JIT` to `1` in
[`constants.s`](https://github.com/hraberg/akeem/blob/master/constants.s).

Too simplify debugging you can wrap the tests using `catchsegv` which
will give you a register dump when Akeem crashes and occasionally even
a stack trace:

``` bash
make run-tests-catchsegv
```

### Benchmarks

You can run a small subset of the Racket benchmarks using:

``` bash
make RACKET_HOME=/path/to/racket benchmarks
```

The `racket` executable itself is assumed to be on the path. Akeem can
currently run about 10% of the benchmarks, and is about 4 times slower
than Racket.

### Profiling

You can run a single benchmark followed by
[`gprof`](https://sourceware.org/binutils/docs/gprof/) using:

``` bash
make RACKET_BENCHMARKS=nqueens profile
```

Only functions written in assembler will show up in the profile
report.


## References

### Assembler

* http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html
* http://ref.x86asm.net/coder64-abc.html
* http://www.x86-64.org/documentation/abi.pdf
* https://sourceware.org/binutils/docs/as/
* http://rayseyfarth.com/asm/
* http://bob.cs.sonoma.edu/IntroCompOrg/book.html
* http://www.agner.org/optimize/
* http://www.avabodh.com/cin/cin.html
* http://github.com/nineties/amber
* https://rwmj.wordpress.com/2010/08/07/jonesforth-git-repository/
* http://lemick.sourceforge.net/papers/JIT_design.pdf
* http://piumarta.com/doc/dcg-1992.pdf
* http://nickdesaulniers.github.io/blog/2014/04/18/lets-write-some-x86-64/
* http://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64/

### Lisp

* http://piumarta.com/software/maru/
* http://piumarta.com/papers/S3-2010.pdf
* http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf
* http://library.readscheme.org/page1.html
* https://dspace.mit.edu/handle/1721.1/5600
* http://www.schemers.org/Documents/Standards/R5RS/r5rs.pdf
* http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs.pdf
* http://srfi.schemers.org/final-srfis.html
* http://www.phyast.pitt.edu/~micheles/syntax-rules.pdf
* https://github.com/kanaka/mal
* http://shenlanguage.org/


## License

Copyright © 2016 Håkan Råberg

Distributed under the MIT License.
