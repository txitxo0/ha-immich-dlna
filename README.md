# Immich DLNA for Home Assistant

This repository packages [Immich-DLNA](https://github.com/SemaiCZE/immich-dlna) as an experimental Home Assistant app. It builds the image locally and uses host networking for DLNA/SSDP.

## Install in Home Assistant

Copy the `immich_dlna` folder into Home Assistant's `/addons` directory, reload the app store, install the app, and configure its options in the Home Assistant UI. Home Assistant manages the app options; you do not need to create or mount an `options.json` file yourself.

For installation details and option descriptions, see [DOCS.md](DOCS.md).

## Build and test with Docker

From this directory:

```sh
docker build -t immich-dlna:local .
cp test_options.example.json test_options.json
```

Edit `test_options.json` with your Immich URL, read-only API key, and the LAN address of the computer running Immich-DLNA. Keep this file private because it contains your API key. Then run:

```sh
docker run --rm --network host \
  -v "$PWD/test_options.json:/data/options.json:ro" \
  immich-dlna:local
```

## Upstream project

Immich-DLNA is developed by [Petr Stefan (SemaiCZE)](https://github.com/SemaiCZE). Many thanks to Petr for creating and maintaining the upstream project that makes this Home Assistant packaging possible.

This package currently pins upstream commit `6c919e6ee98d0c2c3155600db792e3f49f5c7759`. The upstream project is licensed under the MIT License.
