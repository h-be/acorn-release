# acorn-release

## Building and running Acorn 🎉

Acorn can be built and run on:

- Mac OS X
- Ubuntu et al. linux flavours
- Nix (dev only)

It can't run on Windows because holochain conductors don't run on Windows (yet).

High level, there are a few ways to interact with Acorn from this repo:

- Run it directly via. an existing `electron` installation on the current machine
- Run it via. a "packaged" electron installation built with `electron-packager`
- Built an aforementioned package for some target platform with `electron-packager`

The different interactions work differently across mac/ubuntu/nix and generally
are NOT compatible with each other.

Pick a workflow that you like and stick with it.

### Prework

Note that if you aren't using nix you need to _manually_ keep the following up
to date locally in your development environment:

- `node` and `npm` versions
- `hc` and `holochain` binaries
- shared library versions/dependencies

#### Mac OS X

- Install `node` 12+ globally somehow (check version with `node --version`)
- Copy or symlink `hc` and `holochain` into the repo as `hc` and `holochain`

#### Ubuntu

- Install `node` 12+ globally somehow (check version with `node --version`)
- Copy or symlink `hc` and `holochain` into the repo as `hc` and `holochain`
- Run `./ubuntu-deps.sh` to ensure all shared libs are installed globally

#### Nix

Nothing :)

### Running acorn directly

#### Mac OS X & Linux

- Run `./clean.sh`
- Run `npm install` from this repo
- Run `./update-dna-version.sh` and `./update-ui-version.sh`
- Run `npm start`

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

#### Mac OS X & Linux

- Run `./clean.sh`
- Run `npm install` from this repo
- Run `./update-dna-version.sh` and `./update-ui-version.sh`
- Run `npm-build-mac` or `npm-build-linux`

#### Nix

- Run `nix-shell --run acorn-build` for linux defaults or `nix-shell --run "acorn $platform $arch"`

## Authors

**Connor Turland** [Connoropolous](https://github.com/Connoropolous)

## License

This project is licensed under the GPL-3 License - see the [LICENSE](LICENSE) file for details
