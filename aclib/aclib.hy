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

(global Opamp1XH035Characterization Opamp2XH035Characterization)

(import [edlab.eda.characterization [ Opamp1XH035Characterization 
                                      Opamp2XH035Characterization ]])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn make-amp [amp ^str sim-path ^str pdk-path ^str ckt-path ]
  (let [op (amp.build sim-path pdk-path ckt-path)]
  (.start op)
  op))

(defn sym-amp-xh035 [^str pdk-path ^str ckt-path
                  &optional ^str [sim-path "/tmp"]]
  (make-amp Opamp2XH035Characterization sim-path pdk-path ckt-path))

(defn miller-amp-xh035 [^str pdk-path ^str ckt-path
                  &optional ^str [sim-path "/tmp"]]
  (make-amp Opamp1XH035Characterization sim-path pdk-path ckt-path))

(defn set-parameter [amp ^str param ^float value]
  (amp.set param value)
  amp)

(defn set-parameters [amp ^dict param-dict]
  (if param-dict
    (set-parameters (set-parameter amp #* (-> param-dict (.items) (first) (tuple))) 
                    (-> param-dict (.items) (rest) (dict)))
    amp))

(defn simulate [amp]
  (.simulate amp)
  (jmap-to-dict (.getPerformanceValues amp)))

(defn evaluate-circuit [amp  &optional ^dict params]
  (-> amp (set-parameters params) (simulate)))

(defn random-sizing [amp]
  (-> amp (.getRandomValues) (jmap-to-dict)))

(defn initial-sizing [amp]
  (-> amp (.getInitValues) (jmap-to-dict)))

(defn performance-parameters [amp]
  (jsa-to-list amp.getPerformanceIdentifiers))
