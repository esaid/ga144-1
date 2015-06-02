#lang racket

(require compatibility/defmacro)

(provide (all-defined-out))

(defmacro setq (var val)
  `(let [(__v__ ,val)]
     (set! ,var __v__) __v__))

(defmacro push (list item)
  `(set! ,list (cons ,item ,list)))

(defmacro pop (list)
  `(if (equal? ,list '())
       (pretty-display "ERROR: pop -- list is empty")
       (begin0 (car ,list) (set! ,list (cdr ,list)))))

(defmacro swap (list)
  `(set! ,list (cons (cadr ,list) (cons (car ,list) (cddr ,list)))))