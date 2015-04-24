#lang racket
(require racket/tcp)
(require json)

(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 20 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (thread loop))
  (lambda ()
    (custodian-shutdown-all main-cust)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (handle in out)
              (close-input-port in)
              (close-output-port out))))
  (thread (lambda ()
            (sleep 10) ;time out
            (custodian-shutdown-all cust))))

(define (handle in out) 
  (define req
    (regexp-match #rx"^(GET|POST|DELETE) (.+) HTTP/[0-9]+\\.[0-9]+"
                  (read-line in)))
  (when req
    (define (method req) (list-ref req 1))
    (define (action req) (list-ref req 2))
    (match (string->symbol (string-upcase (method req)))
      ['GET (do-get (action req) in out)]
      ['POST (do-post (action req) in out)]
      ;['PUT (do-put (action req) in out)]
      ['DELETE (do-delete (action req) in out)]
      [else (show-message ERROR-UNKNOWN_ACTION out)])))

(define (show-message message port)
  (header port)
  (display (jsexpr->string message) port))  

(define (do-get action in out)
  (show-message (get action) out))

(define (do-delete action in out)
  (delete action)
  (show-message MESSAGE-SUCCESS! out))
  
(define (do-post action in out)
  (regexp-match #rx"(\r\n|^)\r\n" in)
  (put action (string->jsexpr (get-body in)))
  (show-message MESSAGE-SUCCESS! out))

(define (get-body in)
  (define (read-text port lst)
    (let ([char (read-char port)])
      (if (char-ready? port)
          (read-text port (cons char lst))
          (apply string (reverse (cons char lst))))))
  (read-text in '()))

(define db (make-hasheq))

(define (put key obj)
  (hash-set! db (string->symbol key) obj))
(define (get key)
  (hash-ref db (string->symbol key) ERROR-NOT_FOUND))
(define (delete key)
  (hash-remove! db (string->symbol key)))

(define (header out)
  (display "HTTP/1.0 200 Okay\r\n" out) 
  (display "Server: k\r\nContent-Type: application/json\r\n\r\n" out))

(define ERROR-NOT_FOUND '#hasheq((error . "not found")))
(define MESSAGE-SUCCESS!  '#hasheq((message . "success!")))
(define ERROR-UNKNOWN_ACTION '#hasheq((error . "unknown action!")))
