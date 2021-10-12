(import os)
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
      nmos-path f"../models/xh035-nmos"
      pmos-path f"../models/xh035-pmos"
      sim-path f"{HOME}/Workspace/sim"
      pdk-path  f"/mnt/data/pdk/XKIT/xh035/cadence/v6_6/spectre/v6_6_2/mos"
      ckt-path  f"../library/testbenches/op2")

(setx op (ac.single-ended-opamp ckt-path :pdk-path [pdk-path] :sim-path sim-path))

(pp (setx res (ac.evaluate-circuit op)))

(setv rp (ac.random-sizing op))
(setv res (ac.evaluate-circuit op rp))
(pp rp)
(pp res)

(pp (setx ip (ac.initial-sizing op)))
(pp (setx rp (ac.random-sizing op)))

(reduce (fn [df p]
    (->> p (ac.simulate op) (df.append :ignore-index True)))
   (take 10 (repeatedly #%(ac.random-parameters op)))
   (pd.DataFrame :columns (ac.performance-parameters op)))
