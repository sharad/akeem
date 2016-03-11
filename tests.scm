(define (assert x)
  (write x)
  (newline))

;;; 2. Lexical conventions

;;; 2.2. Whitespace and comments

;;; The FACT procedure computes the factorial
;;; of a non-negative integer.
(define fact
  (lambda (n)
    (if (= n 0)
        1 ;Base case: return 1
        (* n (fact (- n 1))))))
(assert (fact 10))

;;; 4. Expressions

;;; 4.1. Primitive expression types

;;; 4.1.1. Variable references
(define x 28)
(assert x)

;;; 4.1.2. Literal expressions
(assert (quote a))
(assert (quote #(a b c)))
(assert (quote (+ 1 2)))

(assert 'a)
(assert '#(a b c))
(assert '())
(assert '(+ 1 2))
(assert '(quote a))
(assert ''a)

(assert '"abc")
(assert "abc")
(assert '145932)
(assert 145932)
(assert '#t)
(assert #t)

;;; 4.1.3. Procedure calls
(assert (+ 3 4))
(assert ((if #f + *) 3 4))

;;; 4.1.4. Procedures
(assert (lambda (x) (+ x x)))
(assert ((lambda (x) (+ x x)) 4))

(define reverse-subtract
  (lambda (x y) (- y x)))
(assert (reverse-subtract 7 10))

;; (define add4
;;   (let ((x 4))
;;     (lambda (y) (+ x y))))
;; (assert (add4 6))

;;; 4.1.5. Conditionals
(assert (if (> 3 2) 'yes 'no))
(assert (if (> 2 3) 'yes 'no))
(assert (if (> 3 2)
            (- 3 2)
            (+ 3 2)))

;;; 4.1.6. Assignments
(define x 2)
(assert (+ x 1))
(assert (set! x 4))
(assert (+ x 1))

;;; 4.2. Derived expression types

;;; 4.2.1. Conditionals
(assert (cond ((> 3 2) 'greater)
              ((< 3 2) 'less)))
(assert (cond ((> 3 3) 'greater)
              ((< 3 3) 'less)
              (else 'equal)))
(assert (cond ((assv 'b '((a 1) (b 2))) => cadr)
              (else #f)))

(assert (case (* 2 3)
          ((2 3 5 7) 'prime)
          ((1 4 6 8 9) 'composite)))
(assert (case (car '(c d))
          ((a) 'a)
          ((b) 'b)))
(assert (case (car '(c d))
          ((a e i o u) 'vowel)
          ((w y) 'semivowel)
          (else 'consonant)))


(assert (and (= 2 2) (> 2 1)))
(assert (and (= 2 2) (< 2 1)))
(assert (and 1 2 'c '(f g)))
(assert (and))

(assert (or (= 2 2) (> 2 1)))
(assert (or (= 2 2) (< 2 1)))
(assert (or #f #f #f))
(assert (or (memq 'b '(a b c))
            (/ 3 0)))

;;; 4.2.2. Binding constructs

(assert (let ((x 2) (y 3))
          (* x y)))
;; (assert (let ((x 2) (y 3))
;;           (let ((x 7)
;;                 (z (+ x y)))
;;             (* z x))))
(assert (let ((x 2) (y 3))
          (let* ((x 7)
                 (z (+ x y)))
            (* z x))))
(assert (letrec ((even?
                  (lambda (n)
                    (if (zero? n)
                        #t
                        (odd? (- n 1)))))
                 (odd?
                  (lambda (n)
                    (if (zero? n)
                        #f
                        (even? (- n 1))))))
          (even? 88)))

;;; 4.2.3. Sequencing

(define x 0)
(assert (begin (set! x 5)
               (+ x 1)))
(begin (display "4 plus 1 equals ")
       (display (+ 4 1)))
(newline)

;;; 5. Program structure

;;; 5.1. Programs

;;; 5.2. Definitions

;;; 5.2.1. Top level definitions

(define add3
  (lambda (x) (+ x 3)))
(assert (add3 3))
(define first car)
(assert (first '(1 2)))

;;; 6. Standard procedures

;;; 6.1. Equivalence predicates

(assert (eqv? 'a 'a))
(assert (eqv? 'a 'b))
(assert (eqv? 2 2))
(assert (eqv? '() '()))
(assert (eqv? 100000000 100000000))
(assert (eqv? (cons 1 2) (cons 1 2)))
(assert (eqv? (lambda () 1)
              (lambda () 2)))
(assert (eqv? #f 'nil))
(assert (let ((p (lambda (x) x)))
          (eqv? p p)))

(assert (eqv? "" ""))
(assert (eqv? '#() '#()))
(assert (eqv? (lambda (x) x)
              (lambda (x) x)))
(assert (eqv? (lambda (x) x)
              (lambda (y) y)))

(define gen-counter
  (lambda ()
    (let ((n 0))
      (lambda () (set! n (+ n 1)) n))))
(assert (let ((g (gen-counter)))
          (eqv? g g)))
;; (assert (eqv? (gen-counter) (gen-counter)))


(define gen-loser
  (lambda ()
    (let ((n 0))
      (lambda () (set! n (+ n 1)) 27))))
(assert (let ((g (gen-loser)))
          (eqv? g g)))
;; (assert (eqv? (gen-loser) (gen-loser)))


(assert (letrec ((f (lambda () (if (eqv? f g) 'both 'f)))
                 (g (lambda () (if (eqv? f g) 'both 'g))))
          (eqv? f g)))

(assert (letrec ((f (lambda () (if (eqv? f g) 'f 'both)))
                 (g (lambda () (if (eqv? f g) 'g 'both))))
          (eqv? f g)))

(assert (eqv? '(a) '(a)))
(assert (eqv? "a" "a"))
(assert (eqv? '(b) (cdr '(a b))))
(assert (let ((x ’(a)))
          (eqv? x x)))

(assert (eq? 'a 'a))
(assert (eq? '(a) '(a)))
;; (assert (eq? (list 'a) (list 'a)))
(assert (eq? "a" "a"))
(assert (eq? "" ""))
(assert (eq? '() '()))
(assert (eq? 2 2))
(assert (eq? #\A #\A))
(assert (eq? car car))
(assert (let ((n (+ 2 3)))
          (eq? n n)))
(assert (let ((x '(a)))
          (eq? x x)))
(assert (let ((x '#()))
          (eq? x x)))
(assert (let ((p (lambda (x) x)))
          (eq? p p)))

;;; 6.2. Numbers

;;; 6.2.5. Numerical operations