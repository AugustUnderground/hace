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

(setx op (ac.make-env "op11" "xh018-1V8"))

(setv perf (ac.evaluate-circuit op :params (ac.random-sizing op)))

(setv perf (ac.evaluate-circuit op :params {"Wd2" 8.0e-6 "Ld2" 5.15e-6}))
(pp (dfor (, k v) (.items perf) :if (.endswith k ":id") [k (* (abs v) 1e6)]))

(get perf "MPD21:gmoverid")

(pp (dfor (, k v) (.items perf) :if (or (= k "A") (.islower (first k))) [k v]))

(len (dfor (, k v) (.items perf) :if (or (= k "A") (.islower (first k))) [k v]))

(len (dfor (, k v) (.items perf) :if (.startswith k "MNCM11/") [k v]))


(setx pool (dfor i (range 32) [i (ac.make-env "op11" "xh035-3V3")]))

(setv df (pd.concat (lfor _ (range 100)
  (. (pd.DataFrame.from-dict (ac.evaluate-circuit-pool pool 
        :pool-params (ac.random-sizing-pool pool))) T))))

(pp (dfor c df.columns :if (or (.islower (first c)) (= c "A")) [c (.mean (get df c))]))



(setv bl ["stb" "noise" "dcmatch" "tran" "xf"])

(setv bl ["stb" "ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"])

(setv tic (.time time))
(setv x (ac.evaluate-circuit op :params (ac.random-sizing op) 
          :blocklist ["stb" "ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"]) )
(pp x)
(setv toc (.time time))
(print f"Evaluating op took {(- toc tic):.4}s.")


(setv tic (.time time))
(setv x (ac.evaluate-circuit op :params (ac.random-sizing op)) )
(setv toc (.time time))
(print f"Evaluating op took {(- toc tic):.4}s.")




(* (get perf "ugbw") 1.02)

(* (get perf "sr_r") 1.05)

(setv params ["MNCM11:gmoverid" "MNCM11:fug" "MNCM31:gmoverid" "MNCM31:fug" "MNCM32:id" "MNCM12:id" "MND11:gmoverid" "MND11:fug" "MPCM221:gmoverid" "MPCM221:fug"])

(setv params ["MNCM1R:gmoverid" "MNCM1R:fug" "MNCM1A:id" "MNCM1B:id" "MPCS1:gmoverid" "MPCS1:fug" "MND1A:gmoverid" "MND1A:fug" "MPCM2R:gmoverid" "MPCM2R:fug"])

(setv params [ "MNCM51:gmoverid" "MPCM41:gmoverid" "MPCM31:gmoverid" "MNCM21:gmoverid" "MNCM11:gmoverid" "MND11:gmoverid" "MNCM51:fug" "MPCM41:fug" "MPCM31:fug" "MNCM21:fug" "MNCM11:fug" "MND11:fug" "MNCM53:id" "MNCM21:id" ])

(pp (dfor p params [p (if (.endswith p ":fug") (np.log10 (get perf p)) (get perf p))]))

(setx op (ac.make-env "op2" "xh018-1V8"))
(setx op (ac.make-env "op2" "xh035-3V3"))
(setv perf (ac.evaluate-circuit op :params (ac.random-sizing op)))
(setv pi (ac.performance-identifiers op))
(setv pp (list (.keys (ac.evaluate-circuit op))))

(.difference (set pi) pp)
(.difference (set pp) pi)

(pp (ac.parameter-dict op))


(setx pool (dict (enumerate (lfor _ (range 32) (ac.make-env "op11" "xh035-3V3")))))

(setx pool (dfor i (range 32) [i (ac.make-env "op11" "xh035-3V3")]))


(setv df (pd.concat (lfor _ (range 25)
  (. (pd.DataFrame.from-dict (ac.evaluate-circuit-pool pool 
        :pool-params (ac.random-sizing-pool pool))) T))))

(setv ref-devs ["MND11" "MPD21" "MNCM11" "MNLS11" "MNR1" "MPCM21" "MPR2" "MPCM31" "MNCM41"])

(for [d ref-devs] (print f"{d}:vbs {(.mean (get df (+ d \":vbs\")))}"))


(pp (dfor (, k v) (.items perf) :if (and (in (first (.split k ":")) ref-devs) (.endswith k ":vbs")) [k v]))

(.describe (np.log10 (np.abs (get df ["i_out_max" "i_out_min" "idd" "iss"]))))
(.describe (get df ["i_out_max" "i_out_min" "idd" "iss"]))
(.describe (get df ["voff_stat" "voff_sys"]))

(.describe (get df (lfor c (. df columns) :if (or (.startswith c "vn_")) c)))

(defn transpose [perf]
  (dfor (, k v) (-> perf (pd.DataFrame.from-dict) (. T) (.to-dict) (.items))
    [k (-> v (.values) (list) (np.array))]))


(lfor (, k v) (.items (ac.parameter-dict op)) :if (get v "sizing") (get v "max"))

(setv perf (ac.evaluate-circuit op :blocklist ["stb" "ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"]))
(setv perf (ac.evaluate-circuit op ))


(lfor p (list (.keys perf)) :if (not-in p (ac.performance-identifiers op)) p)

(op.simulate)

(pp perf)

(get perf "voff_stat")

(pp (dfor (, k v) (.items perf) :if (.endswith k ":vds") [k v]))
(pp (dfor (, k v) (.items perf) :if (.endswith k ":id") [k v]))

(setv tic (.time time))
(setv op-res (->> op (ac.initial-sizing) (ac.evaluate-circuit op)))
(setv toc (.time time))
(print f"Evaluating op took {(- toc tic):.4}s.")

(pp (dfor (, k v) (.items op-res) :if (or (= k "A") (.islower k)) [k v]))

(get perf "a_0")
(pp (ac.current-sizing op))




(setv num-envs 5)
(setx ops (ac.make-same-env-pool num-envs "op2" "xh035-3V3"))

(ac.to-ace-pool [op op op])

(setv obs (ac.evaluate-circuit-pool (dfor i (range 100) [i op])))
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
