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

(setv HOME       (os.path.expanduser "~")
      time-stamp (-> dt (.now) (.strftime "%H%M%S-%y%m%d"))
      nmos-path  f"../models/xh035-nmos"
      pmos-path  f"../models/xh035-pmos"
      tech       f"xh018-1V8"
      op-id      f"op2"
      sim-path   f"{HOME}/Workspace/sim"
      pdk-path   f"{HOME}/.ace/{tech}/pdk")

(setv amp-path   f"{HOME}/.ace/{tech}/{op-id}")
(setv inv-path   f"{HOME}/.ace/{tech}/nand4")
(setv st1-path   f"{HOME}/.ace/{tech}/st1")


(setv ckts ["op8" "op9"]; ["op1" "op2" "op3" "op4" "op5" "op6"]; "op8" "op9"] ;"nand4" "st1"]
      pdks ["xh035-3V3" "gpdk180-1V8"]) ; "sky130-1V8" 

(for [pdk pdks ckt ckts]
  (setv sys.stdout (open os.devnull "w")
        sys.stderr (open os.devnull "w"))
  (setv op (ac.single-ended-opamp f"{HOME}/.ace/{pdk}/{ckt}" 
                        :pdk-path [f"{HOME}/.ace/{pdk}/pdk"] 
                        :sim-path sim-path))
  (setv obs (ac.evaluate-circuit op))
  (setv sys.stdout sys.__stdout__
        sys.stderr sys.__stderr__)
  (print f"{pdk}, {ckt}: {(+ (len obs) 26 26)}")
  (op.stop)
  (del op))


(setx st (ac.schmitt-trigger st1-path :pdk-path [pdk-path] :sim-path sim-path))
(pp (ac.evaluate-circuit st ))

(setx inv (ac.nand-4 inv-path :pdk-path [pdk-path] :sim-path sim-path))
(ac.evaluate-circuit inv )


(setx op (ac.single-ended-opamp amp-path :pdk-path [pdk-path] :sim-path sim-path))
(pp (setx foo (ac.evaluate-circuit op :blocklist [])))
(pp (setx foo (ac.evaluate-circuit op :blocklist ["ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"])))

["stb" "ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"]

(setv s {
 "Ld" 1.0055183172225952
 "Lcm1" 1.7464110851287842
 "Lcm2" 0.18
 "Lcm3" 1.0655750036239624
 "Wd" 4 ; 100
 "Wcm1" 1.6006662133449312
 "Wcm2" 0.42 ; 100
 "Wcm3" 8.819769412688293
 "Md" 2
 "Mcm11" 1
 "Mcm21" 28
 "Mcm31" 2
 "Mcm12" 12
 "Mcm22" 15
 "Mcm32" 2
 #_/ })

(setx foo (ac.evaluate-circuit op :params s))

(setx foo (ac.evaluate-circuit op :params (ac.random-sizing op)))


(pp (dfor (, k v) (.items foo) :if (| (-> k (first) (.islower)) (= k "A") ) [k v]))

(pp
  (dfor p (filter #%(.islower (first %1)) (ac.performance-identifiers op))
    [p (get (ac.current-performance op) p)]))

(pp
  (dfor p (filter #%(.islower (first %1)) (.keys (ac.current-performance op)))
    [p (get (ac.current-performance op) p)]))

(pp (ac.performance-identifiers op))

(lfor f ["yaml" "json" "csv"] (ac.dump-state op f"foo.{f}"))

(lfor f ["yaml" "json" "csv"] (ac.load-state op f"foo.{f}"))

(pp (setx ros (ac.evaluate-circuit op :blocklist (ac.simulation-analyses op))))
(pp (setx ros (ac.evaluate-circuit op :blocklist ["stb" "ac" "dc1" "dc4" "dc3" "noise" "dcmatch" "tran" "dcop" "xf"])))

(pp (setx res (ac.evaluate-circuit op)))

(setv rp (ac.random-sizing op))
(setv res (ac.evaluate-circuit op rp))
(pp rp)
(pp res)

(pp (setx ip (ac.initial-sizing op)))
(pp (setx rp (ac.random-sizing op)))

(with [jf (open "./perfomance.json" "w")]
  (json.dump (ac.current-performance jf)))


(reduce (fn [df p]
    (->> p (ac.simulate op) (df.append :ignore-index True)))
   (take 10 (repeatedly #%(ac.random-parameters op)))
   (pd.DataFrame :columns (ac.performance-parameters op)))
