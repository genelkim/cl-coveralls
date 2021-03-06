(in-package :cl-user)
(defpackage cl-coveralls.service
  (:use :cl)
  (:import-from :alexandria
                :when-let
                :make-keyword)
  (:import-from :cl-yaclyaml
                :yaml-load-file)
  (:export :service-name
           :service-job-id
           :project-dir
           :commit-sha
           :pull-request-num))
(in-package :cl-coveralls.service)

(defun service-name ()
  (let ((config-service-name
          (if (probe-file ".coveralls.yaml")
            (gethash "service_name"
                     (yaml-load-file ".coveralls.yaml")))))
    (cond
      (config-service-name (make-keyword (string-upcase config-service-name)))
      ((uiop:getenv "TRAVIS") :travis-ci)
      ((uiop:getenv "CIRCLECI") :circleci)
      (t :travis-ci))))

(defun service-job-id (&optional (service-name (service-name)))
  (ecase service-name
    ((:travis-ci :travis-pro) (uiop:getenv "TRAVIS_JOB_ID"))
    (:circleci (uiop:getenv "CIRCLE_BUILD_NUM"))))

(defun project-dir (&optional service-name)
  (case service-name
    ((:travis-ci :travis-pro)
     (when-let (travis-build-dir (uiop:getenv "TRAVIS_BUILD_DIR"))
       (uiop:ensure-directory-pathname travis-build-dir)))
    (:circleci
     (when-let (circleci-build-dir (uiop:getenv "CIRCLE_PROJECT_REPONAME"))
       (uiop:ensure-directory-pathname
        (merge-pathnames circleci-build-dir (user-homedir-pathname)))))
    (otherwise *default-pathname-defaults*)))

(defun commit-sha (&optional (service-name (service-name)))
  (ecase service-name
    ((:travis-ci :travis-pro) (uiop:getenv "TRAVIS_COMMIT"))
    (:circleci (uiop:getenv "CIRCLE_SHA1"))))

(defun pull-request-num (&optional (service-name (service-name)))
  (ecase service-name
    ((:travis-ci :travis-pro) (uiop:getenv "TRAVIS_PULL_REQUEST"))
    (:circleci (uiop:getenv "CIRCLE_PR_NUMBER"))))
