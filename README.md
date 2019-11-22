# acorn-release

## Package It (For Developers)

To package, open a terminal @ acorn-release
`npm install`

First, clean your local state, so it doesn't get packaged up for other users
```
./clean.sh
```

Then package it for your platform

**mac**
```
npm run build-mac
```

**linux**
```
npm run build-linux
```

## Update acorn version

In order to update the Acorn version that is packaged here, a script is included, just run:

```shell
./update-version.sh
```

## To develop

Run `npm install` and `npm start`

`main.js` is a primary point of development.


## Authors

**Connor Turland** [Connoropolous](https://github.com/Connoropolous)

## License

This project is licensed under the GPL-3 License - see the [LICENSE](LICENSE) file for details

