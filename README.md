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

Simulate it:

```python
res = evaluate_circuit( amp                                   # Amplifier object
                      , params: Optional[Dict[str, float]]    # Sizing parameters
                      ) => Dict[str, float]                   # Returns performance
```

Get random sizing parameters:

```python
rng = random_sizing(amp) => Dict[str, float]                  # Random sizing parameters
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
