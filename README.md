# acorn-release

A distributable version of the peer-to-peer [Acorn](https://github.com/h-be/acorn-docs) [holochain](https://holochain.org) system packaged as a native application for Linux and Mac.

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

These will need to be run, before other commands like "running" and "packaging" will succeed.
It needs to know which versions you want to be running or packaging.

#### acorn-hc

You can pass in a version number of an [acorn-hc](https://github.com/h-be/acorn-hc) release, like 0.0.2
```bash
nix-shell --run acorn-bundle-dna x.y.z
```

This will result in there being

1. a `dna_address` file with the address/hash of the DNA for this release
2. a `dna/acorn-hc.dna.json` file which contains the WASM and full DNA contents

#### acorn-ui

It currently just pulls the latest from the `master` branch of [acorn-ui](https://github.com/h-be/acorn-ui),
but that will be updated to make it taggable at specific versions,
once [acorn-ui](https://github.com/h-be/acorn-ui) has its own release and upload process.

Just run
```bash
nix-shell --run acorn-bundle-ui
```

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

##### Mac

**Signed and Notarized (Distribute as a Verified Developer)**

To create a codesigned and notarized build depends on having purchased an Apple developer account and acquiring Apple Developer Certificates, so you will need to have special access to those to make this process work.

Set the following environment variables, before running the following.

```
APPLE_DEV_IDENTITY=Developer ID Application: Happy Coders, Inc. (XYZABCNOP)
APPLE_ID_EMAIL=appledeveloperaccount@hAPPy-coders.com
APPLE_ID_PASSWORD=...
```

```
nix-shell --run acorn-build-mac
```

To get extra details on this build process, or to debug, set the following environment variable:

```
DEBUG=electron-osx-sign*,electron-notarize*
```

This relates to the nodejs/npm package [debug](https://www.npmjs.com/package/debug).

**Unsigned (Distribute as an Unverified Developer)**

This version will require the special step that Mac Gatekeeper enforces, which is to allow unverified apps generally,
or to allow this specific app. This can be done by holding `ctrl` and clicking on the `Acorn` application,
and then clicking `Open`, and then `Open` when it asks about the Unidentified Developer.

```
nix-shell --run acorn-build-mac-unsigned
```

##### Linux

For linux defaults, run

```
nix-shell --run acorn-build-linux
```

or for specific linux platform or arch

```
nix-shell --run "acorn-build $platform $arch"
```

## Authors

* **Connor Turland** [Connoropolous](https://github.com/Connoropolous)
* **David Meister**
* **Sam Cooley**

## License

This project is licensed under the CAL-1.0 Beta 4, see [LICENSE.md](./LICENSE.md) for details.
