(define (repl)
  (display "Welcome to Akeem Scheme.")
  (newline)

  (let ((restart-loop (call/cc (lambda (exit)
                                 exit))))
    (with-exception-handler
     (lambda (error)
       (default-exception-handler error)
       (restart-loop restart-loop))
     (lambda ()
       (let loop ()
         (display "> ")
         (let ((input (read)))
           (if (eof-object? input)
               (exit 0)
               (let ((result (call-with-values
                                 (lambda ()
                                   (eval input (interaction-environment)))
                               list)))
                 (when (> (length result) 1)
                   (display "; ")
                   (display (length result))
                   (display " values")
                   (newline))
                 (for-each
                  (lambda (x)
                    (unless (eq? (if #f #f) x)
                      (write x)
                      (newline)))
                  result))))
         (loop))))))

(define (main args)
  (let ((files (cdr args)))
    (if (null? files)
        (repl)
        (for-each load files))))

(main (command-line))
