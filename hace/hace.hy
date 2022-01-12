(import os)
(import csv)
(import json)
(import yaml)
(import importlib)
(import errno warnings)
(import [functools [partial]])
(import [collections [namedtuple]])

(import jpype)
(import jpype.imports)
(import [jpype.types [*]])

(require [hy.contrib.walk [let]])
(require [hy.contrib.loop [loop]])
(require [hy.extra.anaphoric [*]])
(import [hy.contrib.pprint [pp pprint]])

(import [.util [*]])

;; JVM HANDLING ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                            ;;
(unless (.isJVMStarted jpype)                                               ;;
    (.startJVM jpype))                                                      ;;
                                                                            ;;
(unless (importlib.util.find_spec "edlab")                                  ;;
    (jpype.addClassPath (default-class-path)))                              ;;
                                                                            ;;
(import [edlab.eda.ace [ SingleEndedOpampEnvironment                        ;;
                         Nand4Environment                                   ;;
                         SchmittTriggerEnvironment                          ;;
                         EnvironmentPool                                    ;;
                         Parameter ]])                                      ;;
(import [java.util.HashSet :as HashSet])                                    ;;
                                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn make-env [^str ace-id ^str ace-backend 
        &optional ^(of list str) [pdk []] ^str [ckt None] ^str [sim None]]
  """
  Function for creating ACE environments for a given backend.
    Example: `make_env('op1', 'xh035-3V3')`
  """
  (let [HOME (os.path.expanduser "~")
        pdk-path ;; Check for PDK
          (cond [(and (all (lfor p pdk (and p (os.path.exists p)))) pdk)
                  pdk]
                [(in "ACE_PDK" os.environ) [(os.environ.get "ACE_PDK")]]
                [(os.path.exists (.format "{}/.ace/{}/pdk" HOME ace-backend))
                 [(.format "{}/.ace/{}/pdk" HOME ace-backend)]]
                [True (raise (FileNotFoundError errno.ENOENT 
                              (os.strerror errno.ENOENT) 
                              (.format "No PDK found for {} and {}"
                                       ace-id ace-backend)))])
        ckt-path ;; Check ACE backend Testbench
          (cond [(and ckt (os.path.exists ckt)) ckt]
                [(in "ACE_BACKEND" os.environ) 
                 (.format "{}/{}" (os.environ.get "ACE_BACKEND") ace-id)]
                [(os.path.exists (.format "{}/.ace/{}/{}" HOME ace-backend ace-id))
                 (.format "{}/.ace/{}/{}" HOME ace-backend ace-id)]
                [True (raise (FileNotFoundError errno.ENOENT 
                              (os.strerror errno.ENOENT) 
                              (.format "No ACE Testbench found for {} in {}"
                                       ace-id ace-backend)))])
        sim-path ;; Check if path to a simlulation directory was given
          (or sim "/tmp")
        ace-env
          (cond [(.startswith ace-id "op")   SingleEndedOpampEnvironment]
                [(.startswith ace-id "st")   SchmittTriggerEnvironment]
                [(.startswith ace-id "nand") Nand4Environment]
                [True (raise (NotImplementedError errno.ENOSYS
                              (os.strerror errno.ENOSYS) 
                              (.format "{} is not a valid ACE id." ace-id)))])]
    (ace-env.get sim-path ckt-path pdk-path)))

;; Wrapper class for creating an Env Pool and keeping track of individual envs.
(setv AcePoolEnvironment (namedtuple "AcePoolEnvironment" "envs pool"))

(defn make-env-pool [^(of list str) ace-ids ^(of list str) ace-backends
        &optional ^(of list (of list str)) [pdks (repeat [])] 
                  ^(of list str) [ckts (repeat None)] 
                  ^(of list str) [sims (repeat None)]]
  """
  Function for creating a pool of ACE environments.
  """
  (let [env-ids (-> ace-ids (len) (range))
        envs (dfor (, env-id ace-id ace-backend pdk ckt sim) 
                   (zip env-ids ace-ids ace-backends pdks ckts sims) 
                   [env-id (make-env ace-id ace-backend pdk ckt sim)])
        pool (EnvironmentPool)]
    (for [e (.values envs)] (.add pool e))
    (AcePoolEnvironment envs pool)))

(defn make-same-env-pool [^int num-envs ^str ace-id ^str ace-backend
        &optional ^(of list str) [pdk []] ^str [ckt None] ^str [sim None]]
  """
  Function for creating a pool of the same ACE environment, n times.
  """
  (let [ace-ids (-> ace-id (repeat num-envs) (list))
        ace-backends (-> ace-backend (repeat num-envs) (list)) 
        pdks (-> pdk (repeat num-envs) (list))
        ckts (-> ckt (repeat num-envs) (list))
        sims (-> sim (repeat num-envs) (list))]
    (make-env-pool ace-ids ace-backends pdks ckts sims)))

;;;;;;;;; REMOVE THIS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defn single-ended-opamp [^str ckt-path &optional ^str [sim-path "/tmp"]
                                                  ^(of list str) [pdk-path []]]
  """
  Create a single ended opamp with the given testbench and pdk.
  """
  (warnings.warn f"single-ended-opamp is deprecated, and will be removed, use make-env instead" 
                 DeprecationWarning)
  (SingleEndedOpampEnvironment.get sim-path ckt-path pdk-path))

(defn nand-4 [^str ckt-path &optional ^str [sim-path "/tmp"]
                                      ^(of list str) [pdk-path []]]
  """
  Create a 4 gate nand inverter chain with the given testbench and pdk.
  """
  (warnings.warn f"nand-4 is deprecated, and will be removed, use make-env instead" 
                 DeprecationWarning)
  (Nand4Environment.get sim-path ckt-path pdk-path))

(defn schmitt-trigger [^str ckt-path &optional ^str [sim-path "/tmp"]
                                      ^(of list str) [pdk-path []]]
  """
  Create a schmitt trigger with the given testbench and pdk.
  """
  (warnings.warn f"single-ended-opamp is deprecated, and will be removed, use make-env instead" 
                 DeprecationWarning)
  (SchmittTriggerEnvironment.get sim-path ckt-path pdk-path))
;;;;;;;;; REMOVE THIS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn set-parameter ^(of dict str float) [env ^str param ^float value]
  """
  Change a single parameter. Returns the current sizing.
  """
  (env.set param value)
  (current-parameters env))

(defn set-parameters [env ^(of dict str float) param-dict]
  """
  Set a parameter dictionary. (i.e. from `random-sizing`). Returns the current
  sizing.
  """
  (for [(, p v) (.items param-dict)] (set-parameter env p v))
  env)

(defn set-parameters-pool [pool-env pool-params]
  """
  Takes dict of the following shape:
    { 'env_id': {'sizing_parameter': 'value
                , ...  }
    , ... }
  """
  (for [(, i ps) (.items pool-params)] 
    (set-parameters (get pool-env.envs i) ps))
  pool-env)

(defn evaluate-circuit ^(of dict str float) 
    [env  &optional ^(of dict str float) [params {}]
                    ^list [blocklist []]]
  """
  Evaluates a given ACE env.
  """
  (-> env (set-parameters params) 
          (.simulate (HashSet blocklist))
          (current-performance)))

(defn evaluate-circuit-pool ^dict [pool-env &optional ^dict [pool-params {}]
          ^int [npar (-> 0 (os.shed-getaffinity) (len) (// 2))]] 
  """
  Takes a dict of the same shape as `set_parameters_pool` and evaluates a given
  ace env.
  """
  (-> pool-env (set-parameters-pool pool-params) (. pool) (.execute npar))
  (current-performance-pool pool-env))

(defn current-performance ^(of dict str float) [env]
  """
  Returns the current performance of the circuit. Values not present for
  whatever reason will be filled with 0.
  """
  (| (dict (zip (performance-identifiers env) (repeat 0)))
     (-> env (.getPerformanceValues) (jmap-to-dict))))

(defn current-performance-pool ^(of dict int (of dict str float)) [pool-env]
  """
  Returns the current performance of all circuits in the pool. Values not
  present for whatever reason will be filled with 0.
  """
  (dfor (, i e) (.items pool-env.envs) [i (current-performance e)]))

(defn performance-identifiers ^(of list str) [env &optional ^list [blocklist []]]
  """
  Get list of available performance parameters.
  """
  (jsa-to-list (.getPerformanceIdentifiers env (HashSet blocklist))))

(defn current-sizing ^(of dict str float) [env]
  """
  Get dictionary with current sizing parameters.
  """
  (let [cp (-> env (.getParameterValues) (jmap-to-dict))]
    (dfor s (sizing-identifiers env)
      [s (get cp s)])))

(defn current-parameters ^(of dict str float) [env]
  """
  Returns the sizing parameters currently in the netlist.
  """
  (-> env (.getParameterValues) (jmap-to-dict)))

(defn random-sizing ^(of dict str float) [env]
  """
  Returns random sizing parameters.
  """
  (-> env (.getRandomSizingParameters) (jmap-to-dict)))

(defn random-sizing-pool ^(of dict int (of dict str float)) [pool-env]
  """
  Returns random sizing parameters for a pool.
  """
  (dfor (, i env) (.items pool-env.envs) [i (random-sizing env)]))

(defn initial-sizing ^(of dict str float) [env]
  """
  'Reasonable' initial sizing.
  """
  (-> env (.getInitialSizingParameters) (jmap-to-dict)))

(defn initial-sizing-pool ^(of dict int (of dict str float)) [pool-env]
  """
  Returns 'reasonable' sizing parameters for a pool.
  """
  (dfor (, i env) (.items pool-env.envs) [i (initial-sizing env)]))

(defn sizing-identifiers ^(of list str) [env]
  """
  A list of available sizing parameters for a given OP-Amp
  """
  (let [ap (parameter-identifiers env)]
    (list (filter (fn [p] (-> p (first) (in ["W" "L" "M"]) )) ap))))

(defn parameter-identifiers ^(of list str) [env]
  """
  A list of all available netlist parameters for a given OP-Amp
  """
  (-> env (.getParameters) (jsa-to-list)))

(defn parameter-dict [env]
  """
  Turn parameters into a nested dict
  """
  (dfor (, k v) (-> env (.getParameters) (dict) (.items))
    [(str k) (jparam-to-dict v)]))

(defn simulation-analyses ^(of list str) [env]
  (-> env (.getAnalyses) (jsa-to-list)))

(defn dump-state ^(of dict str float) [env &optional ^str [file-name None]]
  """
  Returns the current state dict and dumps it to a file, if a `file-name` is
  specified. Supported formats are `csv`, `json` and `yaml`.
  """

  (let [state-dict (| (current-parameters env) (current-performance env))
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

(defn load-state ^(of dict str float) [env ^str file-name]
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
        
        sizing-dict     (dfor p (sizing-identifiers env) [p (get state-dict p)])

        perfomance-dict (evaluate-circuit env :params sizing-dict) ]
    (| (current-parameters env) (current-performance env))))
