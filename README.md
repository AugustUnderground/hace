# HAC²E

Minimal functional interface to [AC²E](https://github.com/matthschw/ace) for Hy.

## Installation

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

### Dependencies

Make sure [AC²E](https://github.com/matthschw/ace) and all dependencies are
installed.

### Backend Access

One way is to create a symlink from the `resource` directory of the AC²E
repository, which contains all the backends as git submodules, to `~/.ace`.
`hace` will automatically look there if `pdk_path` and `ckt_path` are not
specified.

```bash
$ ln -s /path/to/ace/resource $HOME/.ace
```

It should look something like this:

```
$HOME/.ace
├── sky130-1V8
│   ├── op1
│   │   ├── input.scs
│   │   └── properties.json
│   ├── ...
│   ├── pdk
│   │   ├── cells
│   │   │   ├── nfet_01v8
│   │   │   │   ├── sky130_fd_pr__nfet_01v8__mismatch.corner.scs
│   │   │   │   ├── sky130_fd_pr__nfet_01v8__tt.corner.scs
│   │   │   │   └── sky130_fd_pr__nfet_01v8__tt.pm3.scs
│   │   │   └── pfet_01v8
│   │   │       ├── sky130_fd_pr__pfet_01v8__mismatch.corner.scs
│   │   │       ├── sky130_fd_pr__pfet_01v8__tt.corner.scs
│   │   │       └── sky130_fd_pr__pfet_01v8__tt.pm3.scs
│   │   ├── models
│   │   │   ├── all.scs
│   │   │   ├── corners
│   │   │   │   └── tt
│   │   │   │       └── nofet.scs
│   │   │   ├── parameters
│   │   │   │   └── lod.scs
│   │   │   └── sky130.scs
│   │   ├── README.md
│   │   └── tests
│   │       ├── nfet_01v8_tt.scs
│   │       └── pfet_01v8_tt.scs
└── ...
```

#### Environment Variables

Alternatively you can set environment variables, telling `hace` where to find
the pdk and testbenches.

```bash
$ export ACE_BACKEND=/path/to/ace/resource
$ export ACE_PDK=/path/to/ace/resource/<tech>/pdk
```

Where `<tech>` has to be a valid backend such as `xh035-3V3` for example.


#### Explicit

Otherwise paths have to be given explicitly to the `make_env` function via the
kwargs `pdk_path` and `ckt_path`.

## Getting Started

Please refer to the [AC²E](https://github.com/matthschw/ace) documentation for
environment IDs and available backends. 

```python
import hace as ac

amp = ac.make_env('op2', 'xh035-3V3') 
siz = ac.random_sizing(amp)
res = ac.evaluate_circuit(amp, params = siz)
```

## API

Create an ace environment object:

```python
amp = make_env( ace_id: str                         # ACE Environment ID
              , ace_backend: str                    # ACE Backend ID
              , pdk_path: Optional[List[str]] = []  # Path to ace backend
              , ckt_path: Optional[str] = None      # Path to testbench
              , sim_path: Optional[str] = None      # Path to store results
              ) => amplifier                        # Returns ace env obj
```

Where `ace_id` can be any supported AC²E environment id such as `op1 .. 9`,
`nand4` or `st1`. And `ace_backend` should be a supported/installed backend,
such as `sky130-1V8`.

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

#### Concurrent / Parallel Programming

The concurrent API acts much the same as the default one. Create pooled
amplifier object:

```python
amps = ac.make_env_pool( ace_ids: List[str],
                       , ace_backends: List[str]
                       , pdk_paths: Optional[List[List[str]]] = [[]]
                       , ckt_paths: Optional[List[str]]       = []
                       , sim_paths: Optional[List[str]]       = ["/tmp", ..] 
                       ) => amplifier_pool
```

There is a short hand for creating a pool of the same environment.

```python
envs = ac.make_same_env_pool( num_envs: int
                            , ace_id: str,
                            , ace_backends: str
                            , pdk_paths: Optional[List[str]] = []
                            , ckt_paths: Optional[str]       = []
                            , sim_paths: Optional[str]       = "/tmp"
                            ) => amplifier_pool
```

The `AcePoolEnvironment` is a
[namedtuple](https://docs.python.org/3/library/collections.html#collections.namedtuple)
with an `envs` and `pool` field. Where the former is a dict mapping an ID to an
environment.

Parameters of environments in a pool can be set with a dict mapping an ID to a
dict that is then passed to `set_parameters`.

```python
envs = ac.set_parameters_pool( pool_env
                             , pool_params dict[int, dict[str, float]]
                             ) => pool_env
```

An environment pool can be evaluated in a similar way.

```python
ress = ac.evaluate_circuit_pool( pool_env
                               , pool_params Optional[dict[int, dict[str, float]]] = {}
                               , npar: int = len(os.shed_getaffinity(0)) // 2
                               ) => simulation_results
```

So far the `blocklist` is not supported in pooled environments.

## Further Reading

See [ACE Documentation](https://matthschw.github.io/ace/).
