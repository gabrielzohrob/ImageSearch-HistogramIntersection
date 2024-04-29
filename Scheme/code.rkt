#lang racket

(require racket/file)

;; Function: calculate-sum
;; Purpose: Calculates the sum of all the numerical values within a given list (histogram).
;; Input: A list of numbers (histogram).
;; Output: A single number representing the sum of all elements in the list.
(define (sum histogram)
  ;; Base case: if the list is empty, return 0.
  (if (null? histogram)
      0
      ;; Recursive step: add the first element to the sum of the rest of the list.
      (+ (car histogram) (sum (cdr histogram)))))

;; Function: normalize-histogram
;; Purpose: Normalizes the values in a histogram by dividing each value by the total sum of all values, resulting in a distribution that sums to 1.
;; Input: A list of numbers (histogram).
;; Output: A list of numbers representing the normalized distribution of the histogram.
(define (normalize-histogram histogram)
  ;; Calculate the total sum of the histogram values.
  (let ((sum (sum histogram)))
    ;; Define a recursive function to normalize each element of the histogram.
    (letrec ((normalize (lambda (hist)
                          (if (null? hist)
                              '()
                              ;; Divide each element by the total sum and recurse on the rest of the list.
                              (cons (/ (car hist) sum) (normalize (cdr hist)))))))
      ;; Call the normalize function on the entire histogram.
      (normalize histogram))))

;; Function: calculate-similarity
;; Purpose: Calculates the similarity between two histograms by summing the minimum value for each corresponding pair of elements.
;; Input: Two histograms (list of numbers).
;; Output: A single number representing the cumulative similarity between the two histograms.
(define (calculate-similarity histogram1 histogram2)
  ;; Base case: if either histogram is empty, return 0.
  (if (or (null? histogram1) (null? histogram2))
      0
      ;; Choose the smaller of the two corresponding elements, sum it with the result of the recursive call.
      (cond
        ((< (car histogram1) (car histogram2))
         (+ (car histogram1) (calculate-similarity (cdr histogram1) (cdr histogram2))))
        ((>= (car histogram1) (car histogram2))
         (+ (car histogram2) (calculate-similarity (cdr histogram1) (cdr histogram2)))))))

;; Function: create-priority-queue
;; Purpose: Initializes an empty priority queue.
;; Input: None.
;; Output: An empty list representing the priority queue.
(define (priority-queue) '())

;; Function: dequeue
;; Purpose: Removes the first element from the priority queue.
;; Input: A priority queue.
;; Output: The priority queue without its first element.
(define (dequeue q) (if (null? q) '() (cdr q)))

;; Function: get-first-element
;; Purpose: Retrieves the first element from the priority queue without removing it.
;; Input: A priority queue.
;; Output: The first element of the priority queue.
(define (get-first-element q) (if (null? q) '() (car q)))

;; Function: length-of-queue
;; Purpose: Calculates the number of elements in the priority queue.
;; Input: A priority queue.
;; Output: An integer representing the number of elements in the queue.
(define (queue-length q) (if (null? q) 0 (+ 1 (queue-length (cdr q)))))

;; Function: enqueue-helper
;; Purpose: A helper function for enqueue; inserts an item based on its similarity into the priority queue in the correct position.
;; Input: The query image histogram, the priority queue, the name of the image to be inserted, and its histogram.
;; Output: A priority queue with the new image inserted in the correct position.
(define (enqueue-helper query-image q image-name histogram)
  ;; Calculate the similarity between the query image and the current image.
  (let* ((similarity (calculate-similarity query-image histogram))
         ;; Create a pair of the image name and its similarity.
         (file-list (cons image-name similarity)))
    ;; If the queue is empty, start a new queue with this image.
    (if (null? q)
        (list file-list)
        (let ((current (car q)))
          ;; If the current item's similarity is less, insert the new item before it.
          (if (< similarity (cdr current))
              (cons file-list q)
              ;; Otherwise, recurse to find the right position for the new item.
              (cons current (enqueue-helper query-image (cdr q) image-name histogram)))))))

;; Function: enqueue
;; Purpose: Inserts an image into the priority queue based on its similarity to the query image, maintaining the queue's size limit.
;; Input: The query image histogram, the priority queue, the name of the image to be inserted, and its histogram.
;; Output: A priority queue with the new image inserted, respecting the size limit.
(define (enqueue query-image q image-name histogram)
  ;; If the queue exceeds the size limit (5), dequeue the first element before inserting.
  (if (> (queue-length q) 5)
      (let* ((new-queue (dequeue q)))
        (enqueue-helper query-image new-queue image-name histogram))
      ;; Otherwise, insert the new image directly.
      (enqueue-helper query-image q image-name histogram)))

;; Function: display-closest-images
;; Purpose: Displays the names of the images in the priority queue, ordered by similarity to the query image.
;; Input: The name of the query image and the priority queue containing the closest images.
;; Output: A printed list of the top 5 similar images and their similarity levels.
(define (print-images query q)
  ;; Reverse the queue for display (since it's likely ordered from least to most similar).
  (let ((reversed-queue (reverse (dequeue q))))
    (display "The 5 most similar images to \"")
    (display query)
    (display "\" are:\n")
    ;; Define a recursive function to display each item in the queue.
    (letrec ((display-items (lambda (queue)
                              (if (null? queue)
                                  (display "")
                                  (let* ((item (car queue))
                                         ;; Extract the filename from the path for display.
                                         (full-path (car item))
                                         (filename (regexp-match #rx"[^/\\]+$" full-path)))
                                    ;; Display the filename and similarity level.
                                    (when filename
                                      (display (car filename))
                                      (display " with a similarity level of ")
                                      (display (cdr item))
                                      (newline))
                                    (display-items (cdr queue)))))))
      ;; Call the display function on the reversed queue.
      (display-items reversed-queue)
      (display ""))))

;; Function: read-file
;; Purpose: Reads a file and returns its contents as a list.
;; Input: The filename (path) of the file to be read.
;; Output: A list containing the contents of the file.
(define (read-file filename)
  (let ((p (open-input-file filename)))
    ;; Read the file content into a list, element by element.
    (let f ((c (read p)))
      (if (eof-object? c)
          (begin (close-input-port p) '())
          ;; If not end of file, cons the read item onto the rest of the list.
          (cons c (f (read p)))))))

;; Function: SimilaritySearch
;; Purpose: Performs a similarity search for a query image against a directory of images and displays the closest matches.
;; Input: The histogram of the query image and the path to the directory containing images.
;; Output: A display of the top 5 images most similar to the query image.
(define (SimilaritySearch queryHistogram directory-path)
  ;; Create an empty priority queue.
  (let ((q (priority-queue))
        ;; List all .jpg files in the directory, with ".txt" appended to each filename.
        (file-list (list-jpg-file-names directory-path)))
    ;; Process each file in the directory, updating the queue with each one.
    (letrec ((process-files (lambda (files queue)
                              (if (null? files)
                                  queue
                                  (let* ((file (car files))
                                         ;; Normalize the histogram for each image file.
                                         (image-histogram (normalize-histogram (read-file file)))
                                         ;; Normalize the histogram for the query image.
                                         (query (normalize-histogram (read-file queryHistogram)))
                                         ;; Enqueue the current file based on its similarity to the query.
                                         (updated-queue (enqueue query queue file image-histogram)))
                                    (process-files (cdr files) updated-queue))))))
      ;; Process all files and then display the closest images.
      (let ((final-queue (process-files file-list q)))
        (print-images queryHistogram final-queue)))))

;; Function: list-jpg-file-names
;; Purpose: Lists the filenames of all JPEG images in a given directory, appending ".txt" to each name for processing.
;; Input: The path to the directory containing JPEG images.
;; Output: A list of filenames (with ".txt" appended) for each JPEG image in the directory.
(define (list-jpg-file-names directory-path)
  ;; Filter the directory list for .jpg files, then append ".txt" to each.
  (map (lambda (path)
         (string-append directory-path "/"
                        (path->string (file-name-from-path path)) ".txt"))
       (filter (lambda (path)
                 (string-suffix? (path->string (file-name-from-path path)) ".jpg"))
               (directory-list directory-path))))
