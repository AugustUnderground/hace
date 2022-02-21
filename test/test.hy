(import time)
(import os)
(import sys)
(import csv)
(import yaml)
(import json)
(import [numpy :as np])
(import [pandas :as pd])
(import [datetime [datetime :as dt]])
(import [hace :as ac])
(require [hy.contrib.walk [let]])
(require [hy.contrib.loop [loop]])
(require [hy.extra.anaphoric [*]])
(import [hy.contrib.pprint [pp pprint]])

(setx op2 (ac.make-env "op2" "xh035-3V3"))

(setv tic (.time time))
(setv op2-res (->> op2 (ac.random-sizing) (ac.evaluate-circuit op2)))
(setv toc (.time time))
(print f"Evaluating op2 took {(- toc tic):.4}s.")


(setx op (ac.make-env "op2" "xh035-3V3" :pdk ["./"]))


(try
  (setx foo (ac.evaluate-circuit op))
  (except [e Exception]
    {}))

(setx s (ac.random-sizing op))

(ac.evaluate-circuit op s)

(setv op2-res (->> op2 (ac.random-sizing) (ac.evaluate-circuit op2)))




(setv num-envs 32)
(setx ops (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(setv tic (.time time))
(setv ops-res (->> ops (ac.random-sizing-pool) (ac.evaluate-circuit-pool ops)))
(setv toc (.time time))
(print f"Evaluating {num-envs} op2's took {(- toc tic):.4}s.")

(lfor p (.values ops-res) (get p "MND12:vth"))

(setv num-envs 32)
(setx envs (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(for [i (range 20)]
  (setv tic (.time time))
  (setv res (->> envs (ac.random-sizing-pool) (ac.evaluate-circuit-pool envs)))
  (setv toc (.time time))
  (print f"{i :03}: Evaluating {num-envs} op2's took {(- toc tic):.4}s."))

(setv num-envs 3)
(setx ops (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(ac.current-performance-pool ops)


(dfor (, i e) (.items ops.envs) [i (ac.current-performance e)])
