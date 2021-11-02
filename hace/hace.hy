(import os)
(import csv)
(import json)
(import yaml)
(import importlib)
(import [functools [partial]])

(import jpype)
(import jpype.imports)
(import [jpype.types [*]])

(require [hy.contrib.walk [let]])
(require [hy.contrib.loop [loop]])
(require [hy.extra.anaphoric [*]])
(import [hy.contrib.pprint [pp pprint]])

(import [.util [*]])

;; JVM HANDLING ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(unless (.isJVMStarted jpype)
    (.startJVM jpype))

(unless (importlib.util.find_spec "edlab")
    (jpype.addClassPath (default-class-path)))

(import [edlab.eda.ace [SingleEndedOpampEnvironment Nand4Environment]])
(import [java.util.HashSet :as HashSet])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn make-env [env ^str sim-path ^(of list str) pdk-path ^str ckt-path]
  """
  Meta function for creating objects.
  """
  (env.get sim-path pdk-path ckt-path))

(defn single-ended-opamp [^str ckt-path &optional ^str [sim-path "/tmp"]
                                                  ^(of list str) [pdk-path []]]
  """
  Create a single ended opamp with the given testbench and pdk.
  """
  (make-env SingleEndedOpampEnvironment sim-path ckt-path pdk-path))

(defn nand-4 [^str ckt-path &optional ^str [sim-path "/tmp"]
                                      ^(of list str) [pdk-path []]]
  """
  Create a 4 gate nand inverter chain with the given testbench and pdk.
  """
  (make-env Nand4Environment sim-path ckt-path pdk-path))

(defn set-parameter ^(of dict str float) [amp ^str param ^float value]
  """
  Change a single parameter. Returns the current sizing.
  """
  (amp.set param value)
  (current-parameters amp))

(defn set-parameters [amp ^(of dict str float) param-dict]
  """
  Set a parameter dictionary. (i.e. from `random-sizing`). Returns the current
  sizing.
  """
  (ap-reduce 
    (set-parameter amp #* it)
    (.items param-dict) 
    (current-parameters amp))
  amp)

(defn evaluate-circuit ^(of dict str float) 
    [amp  &optional ^(of dict str float) [params {}]
                    ^list [blocklist []]]
  """
  Functionally evaluate a given amplifier.
  """
  (-> amp (set-parameters params) 
          (.simulate (HashSet blocklist)) 
          (current-performance)))

(defn current-performance ^(of dict str float) [amp]
  """
  Returns the current performance of the circuit.
  """
  (-> amp (.getPerformanceValues) (jmap-to-dict)))

(defn performance-identifiers ^(of list str) [amp &optional ^list [blocklist []]]
  """
  Get list of available performance parameters.
  """
  (jsa-to-list (.getPerformanceIdentifiers amp (HashSet blocklist))))

(defn current-sizing ^(of dict str float) [amp]
  """
  Get dictionary with current sizing parameters.
  """
  (let [cp (-> amp (.getParameterValues) (jmap-to-dict))]
    (dfor s (sizing-identifiers amp)
      [s (get cp s)])))

(defn current-parameters ^(of dict str float) [amp]
  """
  Returns the sizing parameters currently in the netlist.
  """
  (-> amp (.getParameterValues) (jmap-to-dict)))

(defn random-sizing ^(of dict str float) [amp]
  """
  Returns random sizing parameters.
  """
  (-> amp (.getRandomSizingParameters) (jmap-to-dict)))

(defn initial-sizing ^(of dict str float) [amp]
  """
  'Reasonable' initial sizing.
  """
  (-> amp (.getInitialSizingParameters) (jmap-to-dict)))

(defn sizing-identifiers ^(of list str) [amp]
  """
  A list of available sizing parameters for a given OP-Amp
  """
  (let [ap (parameter-identifiers amp)]
    (list (filter (fn [p] (-> p (first) (in ["W" "L" "M"]) )) ap))))

(defn parameter-identifiers ^(of list str) [amp]
  """
  A list of all available netlist parameters for a given OP-Amp
  """
  (-> amp (.getParameters) (jsa-to-list)))

(defn simulation-analyses ^(of list str) [amp]
  (-> amp (.getAnalyses) (jsa-to-list)))

(defn dump-state ^(of dict str float) [amp &optional ^str [file-name None]]
  """
  Returns the current state dict and dumps it to a file, if a `file-name` is
  specified. Supported formats are `csv`, `json` and `yaml`.
  """

  (let [state-dict (| (current-parameters amp) (current-performance amp))
        file-format     (-> file-name (os.path.splitext) (second))]

        (when file-name
          (with [f (open file-name "w")]
            (cond [(= file-format ".json")
                (json.dump state-dict f)]
               [(= file-format ".yaml")
                (yaml.dump state-dict f)]
               [(= file-format ".csv")
                (let [w (csv.DictWriter f :fieldnames (list (.keys state-dict)))]
                    (.writeheader w) (.writerow w state-dict))]
               [True
                (raise (ValueError errno.EINVAL
                       (os.strerror errno.EINVAL) 
                       "Unnsupported file-format, has to be either json, yaml or csv."))])))

    state-dict))

(defn load-state ^(of dict str float) [amp ^str file-name]
  """
  Loads the given state into the given amplifier.
  """
  (unless (os.path.exists file-name)
    (raise (FileNotFoundError errno.ENOENT 
                              (os.strerror errno.ENOENT) 
                              file-name)))

  (let [file-format (-> file-name (os.path.splitext) (second))

        state-dict (with [f (open file-name "r")]
                    (cond [(= file-format ".json")
                        (json.load f)]
                       [(= file-format ".yaml")
                        (yaml.full-load f)]
                       [(= file-format ".csv")
                        (dfor (, k v) (.items (first (csv.DictReader f))) 
                          [k (float v)])]
                       [True
                        (raise (ValueError errno.EINVAL
                               (os.strerror errno.EINVAL) 
                               "Unnsupported file-format, has to be either json, yaml or csv."))]))
        
        sizing-dict     (dfor p (sizing-identifiers amp) [p (get state-dict p)])

        perfomance-dict (evaluate-circuit amp :params sizing-dict) ]
    (| (current-parameters amp) (current-performance amp))))
