(defpackage starshot/p0
  (:use :cl)
  (:local-nicknames (:vec :starshot/vector))
  (:local-nicknames (:p :starshot/particle))
  (:local-nicknames (:mop :starshot/mop))
  (:import-from :tactile #:partial)
  (:export #:make-p0 #:particles #:timestep #:iterate-state #:width #:height #:depth #:bounding))

(in-package :starshot/p0)

(defun unique-combinations (objects n)
  (if (zerop n)
      '(())
      (if (null objects)
          '()
          (append (mapcar (lambda (comb)
                            (cons (car objects) comb))
                          (unique-combinations (cdr objects) (1- n)))
                  (unique-combinations (cdr objects) n)))))

(defclass p0 ()
  ((timestep
    :initarg :timestep
    :accessor timestep)
   (particles
    :initarg :particles
    :accessor particles)
   (width
    ;; x
    :initarg :width
    :accessor width)
   (height
    ;; y
    :initarg :height
    :accessor height)
   (depth
    ;; z (for raytracing?)
    :initarg :depth
    :accessor depth)
   (bounding
    :initarg :bounding
    :accessor bounding)))

(defun make-p0 (timestep particles width height depth bounding)
  (make-instance 'p0 :timestep timestep :particles particles :width width :height height :depth depth :bounding bounding))

(defmethod apply-collisions ((state p0))
  (mapcar
   (lambda (particle-pair)
     (when (p:collision? (first particle-pair)
                         (second particle-pair))
       (destructuring-bind ((vx1 vx2) (vy1 vy2) (vz1 vz2))
           (p:calculate-collision (first particle-pair)
                                  (second particle-pair))
         (setf (vec:x (p:v (first particle-pair))) vx1)
         (setf (vec:y (p:v (first particle-pair))) vy1)
         (setf (vec:z (p:v (first particle-pair))) vz1)
         (setf (vec:x (p:v (second particle-pair))) vx2)
         (setf (vec:y (p:v (second particle-pair))) vy2)
         (setf (vec:z (p:v (second particle-pair))) vz2))))
   (unique-combinations (particles state) 2)))

(defmethod integrate-state ((state p0))
  (mapcar
   (lambda (part)
     (let* ((forces
              (mapcar
               (lambda (p2)
                 (p:electric-force part p2))
               (remove part (particles state))))
            (resultant (reduce #'vec:vec+ forces))
           (integrated-part
             (p:integrate part (timestep state)
                          ;; TODO Find resultant force on particle
                          resultant)))
       integrated-part))
   (particles state)))

(defmethod iterate-state ((state p0))
  (apply-collisions state)
  ;; Walls?
  (setf (particles state) (integrate-state state)))
