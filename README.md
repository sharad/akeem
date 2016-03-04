# Akeem

*When you think of garbage, think of Akeem.*
-- [Prince Akeem of Zamunda](http://www.imdb.com/title/tt0094898/)

Akeem is a small JIT-ed subset of
[R5RS Scheme](http://www.schemers.org/Documents/Standards/R5RS/)
written in x86-64 assembler as an experiment.

Only tested on Linux. Written in GNU Assembler using AT&T
syntax. Akeem depends on
[glibc](https://www.gnu.org/software/libc/manual/html_mono/libc.html).


## Usage

``` bash
make
`which rlwrap` ./akeem
```

## What Works?

* Subset of R5RS procedures.
* JIT for if, lambda, define, set!, and, or, begin.
* NaN-boxed 32-bit integers and 64-bit doubles
* Function application up to 6 arguments.
* The bootstrap Scheme code is embedded in the executable.
* Mark and Sweep GC.


## What doesn't work?

* Almost no error handling.
* let, letrec, cond, case, define-syntax
* No closures
* No TCO.
* Max arity is currently 6, higher requires the use of the stack.
* No vararg support.
* No GC for functions or their constant literals.
* No quasiquote.
* Not full support for Scheme numbers in the reader.
* Limited numeric tower, see above.
* call/cc only uses setjmp, and can't be nested.
* A lot of needless moving and popping of data in the generated code.
* No register allocation.
* The JIT is static, once a function is generated its done.
* The memory for the generated code is allocated in a very wasteful
  way.


## Implementation Notes

Akeem is a template based JIT and adheres which copies snippets of its
own source to compile functions at runtime - code is data. It is
somewhat inspired by Abdulaziz Ghuloum's classic paper
[An Incremental Approach to Compiler Construction](http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf)
and Ian Piumarta's
[PEG-based transformer provides front-, middle and back-end stages in a simple compiler](http://www.vpri.org/pdf/tr2010003_PEG.pdf)
and his related work on [Maru](http://piumarta.com/software/maru/).

Unlike these Lisps Akeem does not generate assembly in text
form. Akeem is inspired by Clojure in the sense that there's only a
JIT compiler to simplify the overall implementation.

Most of the implementation is in [`lisp.s`]. It relies heavily on
[`macros.s`] to make the code less verbose.. The [`tests.s`] are
compared to [`test_output.txt`] for simple unit testing. To run and
keep watching the tests (uses [entr](http://entrproject.org/)):

``` bash
make retest
```


## References

### Assembler

* http://ref.x86asm.net/coder64-abc.html
* http://www.x86-64.org/documentation/abi.pdf
* https://sourceware.org/binutils/docs/as/
* http://rayseyfarth.com/asm/
* http://bob.cs.sonoma.edu/IntroCompOrg/book.html
* http://www.agner.org/optimize/
* http://www.avabodh.com/cin/cin.html
* http://github.com/nineties/amber
* http://lemick.sourceforge.net/papers/JIT_design.pdf

### Lisp

* http://piumarta.com/software/maru/
* http://piumarta.com/papers/S3-2010.pdf
* http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf
* http://library.readscheme.org/page1.html
* https://dspace.mit.edu/handle/1721.1/5600
* http://www.schemers.org/Documents/Standards/R5RS/r5rs.pdf
* http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs.pdf
* http://srfi.schemers.org/final-srfis.html
* https://github.com/kanaka/mal
* http://shenlanguage.org/


## License

Copyright © 2016 Håkan Råberg

Distributed under the MIT License.
