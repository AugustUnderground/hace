(import importlib)
(import [functools [partial]])

(import jpype)
(import jpype.imports)
(import [jpype.types [*]])

(require [hy.contrib.walk [let]])
(require [hy.contrib.loop [loop]])
(require [hy.extra.anaphoric [*]])

(import [.util [*]])

;; JVM HANDLING ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(unless (.isJVMStarted jpype)
    (.startJVM jpype))

(unless (importlib.util.find_spec "edlab")
    (jpype.addClassPath (default-class-path)))

(import [edlab.eda.ace [ SingleEndedOpampEnvironment ]])
(import [java.util.HashSet :as HashSet])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn make-amp [amp ^str sim-path ^(of list str) pdk-path ^str ckt-path]
  """
  Meta function.
  """
  (amp.get sim-path pdk-path ckt-path))

(defn single-ended-opamp [^str ckt-path &optional ^str [sim-path "/tmp"]
                                                  ^(of list str) [pdk-path []]]
  """
  Create a single ended opamp with the given testbench and pdk.
  """
  (make-amp SingleEndedOpampEnvironment sim-path ckt-path pdk-path))

(defn set-parameter ^(of dict str float) [amp ^str param ^float value]
  """
  Change a single parameter. Returns the current sizing.
  """
  (amp.set param value)
  (sizing-parameters amp))

(defn set-parameters [amp ^(of dict str float) param-dict]
  """
  Set a parameter dictionary. (i.e. from `random-sizing`). Returns the current
  sizing.
  """
  (ap-reduce 
    (set-parameter amp #* it)
    (.items param-dict) 
    (current-sizing amp))
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
  **IMPURE**. Returns the current performance of the circuit.
  """
  (-> amp (.getPerformanceValues) (jmap-to-dict)))

(defn performance-parameters ^(of list str) [amp &optional ^list [blocklist []]]
  """
  Get list of available performance parameters.
  """
  (jsa-to-list (.getPerformanceIdentifiers amp (HashSet blocklist))))

(defn random-sizing ^(of dict str float) [amp]
  """
  **IMPURE**. Returns random sizing parameters.
  """
  (-> amp (.getRandomSizingParameters) (jmap-to-dict)))

(defn current-sizing ^(of dict str float) [amp]
  """
  **IMPURE**. Returns the sizing parameters currently in the netlist.
  """
  (-> amp (.getInitialSizingParameters) (jmap-to-dict)))

(defn initial-sizing ^(of dict str float) [amp]
  """
  'Reasonable' initial sizing.
  """
  (-> amp (.getInitialSizingParameters) (jmap-to-dict)))

(defn sizing-parameters ^(of list str) [amp]
  """
  A list of available sizing parameters for a given OP-Amp
  """
  (-> amp (.getParameterValues) (jsa-to-list)))
