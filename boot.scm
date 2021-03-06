;;; R7RS Boot

;;; 4. Expressions

;;; 4.2. Derived expression types

;;; 4.2.1. Conditionals

(define-syntax and
  (lambda (form env)
    (append (cons 'if (cdr form)) '(#f))))

(define-syntax or
  (lambda (form env)
    (let ((form (cdr form)))
      (cons 'if (cons (car form) (cons #t (cdr form)))))))

;;; 4.2.8. Quasiquotation

(set! list (lambda obj obj))

;; Based on https://github.com/mishoo/SLip/blob/master/lisp/compiler.lisp#L25
(define-syntax quasiquote
  (lambda (qq-template env)
    (letrec ((qq (lambda (x)
                   (if (pair? x)
                       (if (eq? 'unquote (car x))
                           (car (cdr x))
                           (if (eq? 'quasiquote (car x))
                               (qq (qq (car (cdr x))))
                               (if (and (pair? (car x))
                                        (eq? 'unquote-splicing (car (car x))))
                                   (list 'append (car (cdr (car x))) (qq (cdr x)))
                                   (list 'cons (qq (car x)) (qq (cdr x))))))
                       (if (vector? x)
                           (list 'list->vector (qq (vector->list x)))
                           (list 'quote x))))))
      (qq (car (cdr qq-template))))))

;;; 4.3. Macros

;;; 4.3.2. Pattern language

(set! equal?
      (lambda (obj1 obj2)
        (if (and (pair? obj1) (pair? obj2))
            (and (equal? (car obj1) (car obj2))
                 (equal? (cdr obj1) (cdr obj2)))
            (eqv? obj1 obj2))))

(set! memv
      (lambda (obj list)
        (and (pair? list)
             (if (eqv? (car list) obj)
                 list
                 (memv obj (cdr list))))))

(set! syntax-pattern-variable?
      (lambda (literals pattern)
        (and (symbol? pattern)
             (not (memv pattern (cons '... literals))))))

(set! collect-syntax-variables
      (lambda (literals pattern match idxs)
        (if (pair? pattern)
            (collect-syntax-variables literals (car pattern)
                                      (collect-syntax-variables literals (cdr pattern) match idxs)
                                      idxs)
            (if (syntax-pattern-variable? literals pattern)
                (cons (cons 'transcribe-failure (cons pattern (cons 0 idxs))) match)
                match))))

(set! syntax-ellipsis?
      (lambda (pattern)
        (and (pair? pattern)
             (eq? '... (car pattern)))))

(set! match-syntax-rule
      (lambda (literals pattern form match idxs env)
        (if (not (pair? pattern))
            (if (null? pattern)
                (and (null? form) match)
                (match-syntax-rule literals (cons pattern '()) (cons form '()) match idxs env))
            (if (and (not (null? form)) (not (pair? form)))
                (match-syntax-rule literals (cons pattern '()) (cons form '()) match idxs env)
                (let ((first-pattern (car pattern))
                      (rest-pattern (cdr pattern)))
                  (if (pair? first-pattern)
                      (if (null? form)
                          (and (syntax-ellipsis? rest-pattern)
                               (collect-syntax-variables literals first-pattern match idxs))
                          (and (and (pair? form)
                                    (or (pair? (car form))
                                        (null? (car form))))
                               (if (syntax-ellipsis? rest-pattern)
                                   (letrec ((loop
                                             (lambda (form match idx)
                                               (if (null? form)
                                                   match
                                                   (let ((match (match-syntax-rule literals first-pattern (car form) match (cons idx idxs) env)))
                                                     (and match (loop (cdr form) match (+ 1 idx))))))))
                                     (loop form match 0))
                                   (let ((match (match-syntax-rule literals first-pattern (car form) match idxs env)))
                                     (and match (match-syntax-rule literals rest-pattern (cdr form) match idxs env))))))
                      (if (syntax-pattern-variable? literals first-pattern)
                          (if (syntax-ellipsis? rest-pattern)
                              (letrec ((loop (lambda (form match idx)
                                               (if (null? form)
                                                   (cons (cons 'transcribe-failure (cons first-pattern (cons idx idxs))) match)
                                                   (and (pair? form)
                                                        (loop (cdr form)
                                                              (cons (cons (car form) (cons first-pattern (cons idx idxs))) match)
                                                              (+ 1 idx)))))))
                                (loop form match 0))
                              (and (pair? form)
                                   (match-syntax-rule literals rest-pattern (cdr form)
                                                      (cons (cons (car form) (cons first-pattern idxs)) match) idxs env)))
                          (and (and (pair? form) (equal? first-pattern (car form)))
                               (and (not (memv first-pattern env))
                                    (match-syntax-rule literals rest-pattern (cdr form) match idxs env))))))))))

(set! syntax-template-pattern-variable?
      (lambda (match template)
        (and (pair? match)
             (or (eqv? (car (cdr (car match))) template)
                 (syntax-template-pattern-variable? (cdr match) template)))))

(set! transcribe-syntax-template
      (lambda (match template-idxs)
        (if (null? match)
            'transcribe-failure
            (if (equal? (cdr (car match)) template-idxs)
                (car (car match))
                (transcribe-syntax-template (cdr match) template-idxs)))))

(set! transcribe-syntax-rule
      (lambda (match template idxs)
        (if (not (pair? template))
            (if (syntax-template-pattern-variable? match template)
                (transcribe-syntax-template match (cons template idxs))
                template)
            (let ((first-template (car template))
                  (rest-template (cdr template)))
              (if (syntax-ellipsis? rest-template)
                  (append
                   (letrec ((loop (lambda (transcribed new-idx)
                                    (let ((new-transcribed (transcribe-syntax-rule match first-template (cons new-idx idxs))))
                                      (if (eq? 'transcribe-failure new-transcribed)
                                          transcribed
                                          (loop (append transcribed (cons new-transcribed '()))
                                                (+ new-idx 1)))))))
                     (loop '() 0))
                   (transcribe-syntax-rule match (cdr rest-template) idxs))
                  (let ((first-new-transcribed (transcribe-syntax-rule match first-template idxs))
                        (rest-new-transcribed (transcribe-syntax-rule match rest-template idxs)))
                    (if (or (eq? 'transcribe-failure first-new-transcribed)
                            (eq? 'transcribe-failure rest-new-transcribed))
                        'transcribe-failure
                        (cons first-new-transcribed rest-new-transcribed))))))))

(set! transform-syntax-rules
      (lambda (literals syntax-rules form env)
        (if (null? syntax-rules)
            'transform-failure
            (let ((pattern (cdr (car (car syntax-rules))))
                  (template (cdr (car syntax-rules))))
              (let ((match (match-syntax-rule literals pattern form '() '() env)))
                (if match
                    (transcribe-syntax-rule (reverse match) template '())
                    (transform-syntax-rules literals (cdr syntax-rules) form env)))))))

(set! syntax-error?
      (lambda (transformed)
        (and (pair? transformed)
             (and (pair? (car transformed))
                  (eq? 'syntax-error (car (car transformed)))))))

(set! transform-syntax
      (lambda (transformer-spec form env)
        (let ((literals (car (cdr transformer-spec)))
              (syntax-rules (cdr (cdr transformer-spec))))
          (let ((transformed (transform-syntax-rules literals syntax-rules (cdr form) env)))
            (if (eq? 'transform-failure transformed)
                (error "Bad syntax:" form)
                (if (syntax-error? transformed)
                    (apply error (cdr (car transformed)))
                    (cons 'begin transformed)))))))

(define-syntax syntax-rules
  (lambda (transformer-spec env)
    (cons 'lambda (cons (cons 'form (cons 'env '()))
                        (cons (cons 'transform-syntax
                                    (cons (cons 'quote (cons transformer-spec '()))
                                          (cons 'form (cons 'env '()))))
                              '())))))


(define-syntax assert-predicate
  (syntax-rules ()
    ((assert-predicate pred value)
     (assert-predicate pred 'value value))
    ((assert-predicate pred name value)
     (if (not (pred value))
         (error "Bad syntax:" name value "doesn't satisfy" 'pred)))))

;;; 4.1.2. Literal expressions

(define-syntax quote
  (syntax-rules ()
    ((quote datum)
     (quote-internal datum))))

;;; 4.1.4. Procedures

(define-syntax lambda
  (lambda (form env)
    (if (not (>= (length form) 2))
        (error "Bad syntax:" form)
        (let ((formals (car (cdr form)))
              (body (cdr (cdr form))))
          (if (not (or (symbol? formals) (null? formals)))
              (begin
                (assert-predicate pair? formals)
                (let ((arity (letrec ((loop (lambda (formals arity)
                                              (if (null? formals)
                                                  arity
                                                  (if (pair? formals)
                                                      (let ((formal (car formals)))
                                                        (assert-predicate symbol? formal)
                                                        (loop (cdr formals) (+ 1 arity)))
                                                      (begin
                                                        (assert-predicate symbol? formals)
                                                        (+ 1 arity)))))))
                               (loop formals 0))))
                  (if (> arity 6)
                      (error "Maximum arity is 6:" formals)))))
          `(lambda-internal ,formals ,@body)))))

;;; 4.1.5. Conditionals

(define-syntax if
  (syntax-rules ()
    ((if test consequent alternate)
     (if-internal test consequent alternate))
    ((if test consequent)
     (if-internal test consequent))))

;;; 4.1.6. Assignments

(define-syntax set!
  (lambda (form env)
    (if (not (= 3 (length form)))
        (error "Bad syntax:" form)
        (let ((variable (car (cdr form)))
              (expression (car (cdr (cdr form)))))
          (assert-predicate symbol? variable)
          `(set!-internal ,variable ,expression)))))

;;; 4.2.2. Binding constructs

(set! assert-bindings
      (lambda (bindings)
        (if (pair? bindings)
            (let ((binding (car bindings)))
              (if (not (= 2 (length binding)))
                  (error "Bad syntax: binding" binding))
              (let ((var (car binding)))
                (assert-predicate symbol? var)
                (assert-bindings (cdr bindings)))))))

(define-syntax let
  (lambda (form env)
    (if (not (<= 3 (length form)))
        (error "Bad syntax:" form)
        (let ((bindings (car (cdr form)))
              (body (cdr (cdr form))))
          (if (or (pair? bindings) (null? bindings))
              (begin
                (assert-bindings bindings)
                `(let-internal ,bindings ,@body))
              ((syntax-rules ()
                 ((let tag ((name val) ...) body1 body2 ...)
                  ((letrec ((tag (lambda (name ...)
                                   body1 body2 ...)))
                     tag)
                   val ...))) form env))))))

(define-syntax letrec
  (lambda (form env)
    (if (not (<= 3 (length form)))
        (error "Bad syntax:" form)
        (let ((bindings (car (cdr form)))
              (body (cdr (cdr form))))
          (begin
            (assert-bindings bindings)
            `(letrec-internal ,bindings ,@body))))))

;;; 5. Program structure

;;; 5.3. Variable definitions

(define-syntax define
  (syntax-rules ()
    ((define (variable . formal) body ...)
     (define variable (lambda formal body ...)))
    ((define (variable formals ...) body ...)
     (define variable (lambda (formals ...) body ...)))
    ((define variable expression)
     (set! variable expression))))

;;; 5.4. Syntax definitions

(define-syntax define-syntax
  (lambda (form env)
    (if (not (= 3 (length form)))
        (error "Bad syntax:" form)
        (let ((keyword (car (cdr form)))
              (transformer-spec (car (cdr (cdr form)))))
          (assert-predicate symbol? keyword)
          (assert-predicate pair? transformer-spec)
          `(define-syntax-internal ,keyword ,transformer-spec)))))
