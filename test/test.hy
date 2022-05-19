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


(setx op (ac.make-env "op2" "xh018-1V8"))

(setv tic (.time time))
(setv op-res (->> op (ac.initial-sizing) (ac.evaluate-circuit op)))
(setv toc (.time time))
(print f"Evaluating op took {(- toc tic):.4}s.")

(pp (dfor (, k v) (.items op-res) :if (or (= k "A") (.islower k)) [k v]))

(get op-res "voff_stat")
(pp (ac.current-sizing op))




(setv num-envs 5)
(setx ops (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(ac.evaluate-circuit-pool ops)
(pp (ac.random-sizing-pool ops))
(pp (ac.random-sizing-pool ops))


(setv tic (.time time))
(setv ops-res (->> ops (ac.random-sizing-pool) (ac.evaluate-circuit-pool ops)))
(setv toc (.time time))
(print f"Evaluating op2 took {(- toc tic):.4}s.")

(setx a000 (get ops-res 0 "a_0"))
(setx a004 (get ops-res 4 "a_0"))

(ac.random-sizing-pool ops)
(dfor i [0 2] [i (.get (ac.random-sizing-pool ops) i {})])


(setv res-002 (ac.evaluate-circuit-pool ops (ac.random-sizing-pool ops) [0 2]))

(setx a020 (get res-002 0 "a_0"))
(setx a024 (get res-002 4 "a_0"))


(setv ss [(get ops.envs 0) (get ops.envs 2)])
(setv sp (ac.to-pool ss))

(setx a010 (get sub-res 0 "a_0"))
(setx a010 (get ops-res 0 "a_0"))
(setx a014 (get ops-res 4 "a_0"))













(setx op2 (ac.make-env "op2" "xh035-3V3"))

(setv tic (.time time))
(setv op2-res (->> op2 (ac.random-sizing) (ac.evaluate-circuit op2)))
(setv toc (.time time))
(print f"Evaluating op2 took {(- toc tic):.4}s.")

(pp (ac.evaluate-circuit op2 (ac.initial-sizing op2)))



(setv observation (ac.evaluate-circuit op2))






(pp (dfor (, k v) (.items (ac.current-performance op2)) :if (.islower (get k 0)) [k v]))

(setx op (ac.make-env "op2" "xh035-3V3"))


(try
  (setx foo (ac.evaluate-circuit op))
  (except [e Exception]
    {}))

(setx s (ac.random-sizing op))

(ac.evaluate-circuit op s)

(setv op2-res (->> op2 (ac.random-sizing) (ac.evaluate-circuit op2)))

(setv p (ac.to-pool []))

(ac.evaluate-circuit-pool p)

(setv env-list (lfor _ (range 5) (ac.make-env "op2" "xh035-3V3")))

(setx pool-list (lfor _ (range 3) (ac.to-pool env-list)))

(setv p1 (get pool-list 1))

(setv p2 (get pool-list 2))

(setv res1 (->> p1 (ac.random-sizing-pool) (ac.evaluate-circuit-pool p1)))
(setv res2  (ac.current-performance-pool p2))

(get res1 0 "a_0")
(get res2 0 "a_0")


(setv num-envs 5)
(setx ops (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(setx a000 (get ops-res 0 "a_0"))
(setx a004 (get ops-res 4 "a_0"))

(setv ss [(get ops.envs 0) (get ops.envs 2)])
(setv sp (ac.to-pool ss))

(setx a010 (get sub-res 0 "a_0"))
(setx a010 (get ops-res 0 "a_0"))
(setx a014 (get ops-res 4 "a_0"))


(setv sub-res (->> sp (ac.random-sizing-pool) (ac.evaluate-circuit-pool sp)))

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
