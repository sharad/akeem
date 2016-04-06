(define (repl)
  (let loop ()
    (display "> ")
    (let ((input (read)))
      (unless (eof-object? input)
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
           result)
          (loop))))))

(define (main args)
  (let ((files (cdr args)))
    (if (null? files)
        (repl)
        (for-each load files))))

(main (command-line))
