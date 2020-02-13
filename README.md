# acorn-release

## Building and running Acorn 🎉

Acorn can be built and run on:

- Mac OS X
- Ubuntu et al. linux flavours
- Nix (dev only)

It can't run on Windows because holochain conductors don't run on Windows (yet).

High level, there are a few ways to interact with Acorn from this repo:

- Run it via a "packaged" electron installation built with `electron-packager`
- Built an aforementioned package for some target platform with `electron-packager`

The different interactions work differently across mac/ubuntu/nix and generally
are NOT compatible with each other.

Pick a workflow that you like and stick with it.

### Bundling in versions of acorn-hc and acorn-ui

These will need to be run, before other commands will succeed.
It needs to know which versions you want to be packaging.

#### acorn-hc

You can pass in a version number of an acorn-hc release, like 0.0.2
`nix-shell --run acorn-bundle-dna x.y.z`

This will result in there being

1. a `dna_address` file with the address/hash of the DNA for this release
2. a `dna/acorn-hc.dna.json` file which contains the WASM and full DNA contents

#### acorn-ui

It currently just pulls the latest from the `master` branch of `acorn-ui`,
but that will be updated to make it taggable at specific versions,
once `acorn-ui` has its own release and upload process.

Just run
`nix-shell --run acorn-bundle-ui`

This will result in there being a `ui` folder locally, which contains all the html/css/js files for the user interface.

### Running Acorn directly

#### Nix

Run `nix-shell --run acorn`

### Run the package

#### Mac OS X

- Run `Acorn-darwin-x64/Acorn`

#### Ubuntu

- Run `Acorn-linux-x64/Acorn`

#### Nix

Not supported! :(

Electron packager tries to ship its own version of electron, which is not nix friendly.

### Packaging

This will produce an Acorn.app file within `Acorn-$platform-$arch` folder. This can be zipped and shared.

`main.js` is a primary point of development.

#### Nix

- For Mac, run `nix-shell --run acorn-release`, this depends on Apple Developer Certificates, so you will need to have special privileges to make this process work
- For linux, run `nix-shell --run acorn-build` for linux defaults or `nix-shell --run "acorn-build $platform $arch"`

## Authors

**Connor Turland** [Connoropolous](https://github.com/Connoropolous)
**David Meister**
**Sam Cooley**

## License

This project is licensed under the CAL-1.0 Beta 4
