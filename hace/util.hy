(import os)
(import shutil)
(import errno)
(import importlib)
(import [math [nan inf isnan isinf]])
(import [pkg-resources [get-distribution]])
(import [typing [Union]])

(require [hy.contrib.walk [let]])
(require [hy.contrib.loop [loop]])
(require [hy.extra.anaphoric [*]])

(setv __name__ "hace"
      __version__ (-> __name__ (get-distribution) (. version)))

(defn get-maven-home ^str [] 
  """
  Get the default maven home directory.
  """
  (let [mvn-command (+ "mvn help:evaluate " 
                     "-Dexpression=settings.localRepository "
                     "-B 2> /dev/null")]
    (if (shutil.which "mvn")
      (first (list (filter (fn [l] (-> l (.startswith "[") (not))) 
               (-> mvn-command (os.popen) (.read) (.split :sep "\n")))))
      (raise (ChildProcessError errno.ECHILD 
                                (os.strerror errno.ECHILD) 
                                "sh: command not found: mvn")))))

(defn default-class-path ^str []
  """
  Get the expected class path for the `ace-X.Y.Z-jar-with-dependencies.jar`
  archive, including all dependencies.
  """
  (let [maven-home (get-maven-home)
        class-path (.format (+ "{}/edlab/eda/ace/{}/"
                               "ace-{}-jar-with-dependencies.jar")
                            maven-home __version__ __version__)]
    (if (and (os.path.isfile class-path)
          (os.access class-path os.R-OK))
      class-path
      (raise (FileNotFoundError errno.ENOENT 
                                (os.strerror errno.ENOENT) 
                                class-path)))))

(defn sub-set ^dict [^dict dct ^list idx]
  """
  Get a subset of the pool env.
  """
  (dfor i idx :if (in i (.keys dct)) [i (get dct i)]))

(defn nan-to-num ^float [^float num]
  """
  convert nans and +/- infs to numeric
  """
  (cond [(and (isinf num) (> num 0)) 1.0e10]
        [(and (isinf num) (> num 0)) (- 1.0e10)]
        [(isnan num) 0.0]
        [True num]))

(defn jparam-to-dict ^dict [jparam]
  """
  Convert a parameter to a dict.
  """
  { ;"name"   (str (.getName jparam))
    "grid"   (float (.getGrid jparam))
    "init"   (float (.getInit jparam))
    "max"    (float (.getMax jparam))
    "min"    (float (.getMin jparam))
    "sizing" (bool (.isSizingParameter jparam)) })

(defn jmap-to-dict ^dict [jmap]
  """
  Convert Java HashMap to native Python dictionary.
  """
  (dfor (, k v) (.items (dict jmap))
    [(str k) (if (hasattr v "real") (nan-to-num v.real) (jmap-to-dict v)) ]))

(defn jna-to-list ^list [jna]
  """
  Convert Java Numeric List/Array to native Python list.
  """
  (list (map #%(nan-to-num (.real %1)) jna)))

(defn jsa-to-list ^(of list str) [jsa]
  """
  Convert Java String List/Array to native Python list.
  """
  (list (map str jsa)))
