# HAC²E

Minimal functional interface to [AC²E](https://github.com/matthschw/ace) for Hy.

## Installation

Make sure [AC²E](https://github.com/matthschw/ace) and all dependencies are
installed.

Install with `pip`:

```bash
$ pip install git+https://github.com/augustunderground/hace.git
```

Or by cloning:

```bash
$ git clone https://github.com/augustunderground/hace.git
$ pushd hace
$ pip install .
```

## Getting Started

```python
import hace as ac

amp = ac.single_ended_opamp([path_to_pdk}], path_to_netlist)
siz = ac.random_sizing(amp)
res = ac.evaluate_circuit(amp, siz)
```

Where `path_to_pdk` is optional, if your netlist requries it, otherwise give an
empty list. `path_to_netlist` should point to a directory with an `input.scs`
and corresponding `.json` as seen in the examples for
[AC²E](https://github.com/matthschw/ace).

## API

Create an amplifier object:

```python
amp = single_ended_opamp( ckt_path: str                       # Path to testbench dir
                        , pdk_path: Optional[List[str]] = []  # Path to PDK 
                        , sim-path: Optional[str] = "/tmp"    # Path to store results
                        ) => amplifier                        # Returns amplifier obj
```

Create a 4 gate NAND inverter chain:

```python
inv = nand_4( ckt_path: str                       # Path to testbench dir
            , pdk_path: Optional[List[str]] = []  # Path to PDK 
            , sim-path: Optional[str] = "/tmp"    # Path to store results
            ) => inverter                         # Returns amplifier obj
```

The current state of a circuit can be evaluated or parameters therein can be
overwritten with the following function:

```python
res = evaluate_circuit( amp                                   # Amplifier object
                      , params: Optional[Dict[str, float]]    # Sizing parameters
                      , blocklist: Optional[List[str]]        # List of blocked simulations
                      ) => Dict[str, float]                   # Returns performance
```

The `blocklist` argument may specify a list of simulations that will _not_ be
performed. To get a list of all available simulation analyses one may call

```python
sim = simulation_analyses(amp) => List[str]     # List of available analyses
```

To get the simulation result of the previous run without simulating again:

```python
res = current_performance(amp) => Dict[str, float]
```

The following functions can be used for accessing and indexing the Dictionaries:

```python
sizing_identifiers(amp) => List[str]        # Keys in optional params dict
performance_identifiers(amp) => List[str]   # Keys in current performance dict
```

Get random sizing parameters:

```python
rng = random_sizing(amp) => Dict[str, float]    # Random sizing parameters
```

Get sensible initial sizing parameters:

```python
siz = initial_sizing(amp) => Dict[str, float]    # "Good" sizing parameters
```

Save the current state to a file (`.json`, `.yaml` and `.csv` are currently
supported):

```python
dump_state(amp, file_name="file.ext") => Dict[str, float]     # Dumps current state
```

Load a state (created with `dump_state`):

```python
load_state(amp, file_name: str) => Dict[str, float]           # Loads the given state 
```

## Further Reading

See [ACE Documentation](https://matthschw.github.io/ace/).
