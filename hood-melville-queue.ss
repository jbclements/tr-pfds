#lang typed-scheme

(provide Queue queue enqueue head tail empty empty? queue->list)

(require scheme/match)

(define-struct: Idle ())
(define-struct: (A) Reversing ([count : Integer]
                               [fst : (Listof A)]
                               [snd : (Listof A)]
                               [trd : (Listof A)]
                               [frt : (Listof A)]))
(define-struct: (A) Appending ([count : Integer]
                               [fst : (Listof A)]
                               [snd : (Listof A)]))
(define-struct: (A) Done ([fst : (Listof A)]))

(define-type-alias (RotationState A) 
  (U Idle (Reversing A) (Appending A) (Done A)))

(define-struct: (A) Queue ([lenf : Integer]
                           [front : (Listof A)]
                           [state : (RotationState A)]
                           [lenr : Integer]
                           [rear : (Listof A)]))

(define IDLE (make-Idle))

(: exec : (All (A) ((RotationState A) -> (RotationState A))))
(define (exec state)
  (match state
    [(struct Reversing (cnt (cons x fst) snd (cons y trd) frt)) 
     (make-Reversing (add1 cnt) fst (cons x snd) trd (cons y frt))]
    [(struct Reversing (cnt null snd (list y) frt)) 
     (make-Appending cnt snd (cons y frt))]
    [(struct Appending (0 fst snd)) (make-Done snd)]
    [(struct Appending (cnt (cons x fst) snd)) 
     (make-Appending (sub1 cnt) fst (cons x snd))]
    [else state]))


(: invalidate : (All (A) ((RotationState A) -> (RotationState A))))
(define (invalidate state)
  (match state
    [(struct Reversing (cnt fst snd trd frt)) 
     (make-Reversing (sub1 cnt) fst snd trd frt)]
    [(struct Appending (0 fst (cons x snd))) (make-Done snd)]
    [(struct Appending (cnt fst snd)) 
     (make-Appending (sub1 cnt) fst snd)]
    [else state]))

(: exec2 : 
   (All (A) (Integer (Listof A) (RotationState A) Integer (Listof A) -> 
                     (Queue A))))
(define (exec2 lenf front state lenr rear)
  (let ([newstate (exec (exec state))])
    (match newstate
      [(struct Done (newf)) (make-Queue lenf newf IDLE lenr rear)]
      [else (make-Queue lenf front newstate lenr rear)])))


(: check : 
   (All (A) (Integer (Listof A) (RotationState A) Integer (Listof A) -> 
                     (Queue A))))
(define (check lenf front state lenr rear)
  (if (<= lenr lenf)
      (exec2 lenf front state lenr rear)
      (exec2 (+ lenf lenr) front 
             (make-Reversing 0 front null rear null) 0 null)))

(: empty? : (All (A) ((Queue A) -> Boolean)))
(define (empty? que)
  (zero? (Queue-lenf que)))

(define empty (make-Queue 0 null (make-Idle) 0 null))

(: enqueue : (All (A) (A (Queue A) -> (Queue A))))
(define (enqueue elem que)
  (check (Queue-lenf que)
         (Queue-front que)
         (Queue-state que)
         (add1 (Queue-lenr que))
         (cons elem (Queue-rear que))))

(: head : (All (A) ((Queue A) -> A)))
(define (head que)
  (let ([fr (Queue-front que)])
    (if (null? fr)
        (error "Queue is empty :" 'head)
        (car fr))))

(: tail : (All (A) ((Queue A) -> (Queue A))))
(define (tail que)
  (let ([fr (Queue-front que)])
    (if (null? fr)
        (error "Queue is empty :" 'tail)
        (check (sub1 (Queue-lenf que))
               (cdr fr)
               (invalidate (Queue-state que))
               (Queue-lenr que)
               (Queue-rear que)))))

(: queue : (All (A) (A * -> (Queue A))))
(define (queue . lst)
  (foldl (inst enqueue A) empty lst))

(: queue->list (All (A) ((Queue A) -> (Listof A))))
(define (queue->list que)
  (if (empty? que)
      null
      (cons (head que) (queue->list (tail que)))))