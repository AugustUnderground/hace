(import os)
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
      sim-path   f"{HOME}/Workspace/sim"
      pdk-path   f"/mnt/data/pdk/XKIT/xh035/cadence/v6_6/spectre/v6_6_2/mos"
      amp-path   f"../ACE/ace/resource/xh035-3V3/op4"
      inv-path   f"../ACE/ace/resource/xh035-3V3/nand4"
      st1-path   f"../ACE/ace/resource/xh035-3V3/st1")

(setx st (ac.schmitt-trigger st1-path :pdk-path [pdk-path] :sim-path sim-path))
(pp (ac.evaluate-circuit st ))

(setx inv (ac.nand-4 inv-path :pdk-path [pdk-path] :sim-path sim-path))
(ac.evaluate-circuit inv )

(setx op (ac.single-ended-opamp ckt-path :pdk-path [pdk-path] :sim-path sim-path))
(ac.evaluate-circuit op :blocklist ["xf" "tran"])

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
