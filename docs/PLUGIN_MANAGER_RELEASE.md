# Climatology 2.0 Plugin Manager packages

This release is the pob220 modernisation, based on scientific/runtime revision
cd00282e6ea2784a6d78ccfe47fed713269ad87e, not an unmodified build of Rick
Gleason's plugin. Rick's source and the OpenCPN master catalogue were both
1.6.37.0 when checked on 21 October 2026. Our plugin is 2.0.0.0; its independent
scientific dataset identity remains ocpn-climatology-2026.2.

The `Plugin Manager packages` GitHub Actions workflow builds native Linux,
Windows x86/x64, macOS universal, Flatpak and Android arm64/armhf artifacts.
It does not publish them. Dispatch `groups=all`, or use comma-separated group
names to rebuild selected targets. Package generation verifies the architecture
and all 52 dataset output hashes before creating an archive. Windows checkouts
preserve the dataset's exact bytes through `.gitattributes`.

Each tarball has a single enclosing directory containing `metadata.xml`, the
native plugin library, complete data, icons, translations, GPL text and
`data/package-provenance.json`. The companion XML includes the SHA256 of the
finished archive; embedded metadata omits that self-referential checksum.
Metadata uses OpenCPN's official schema, copied under `ci/public-packages`.
The archive and metadata URLs are GitHub Release assets under the tag
`v2.0.0.0-modern-data` in `pob220/climatology_pi`.

Windows x86 uses the existing wxWidgets build lanes. Windows x64 uses the
checksum-pinned 5.14.2 testing host and wxWidgets SDK in `windows64-sdk.json`,
generates native import libraries from its actual exports, and checks every
OpenCPN import. The x64 target is `msvc-64`, distinct from x86 `msvc-wx32`.
Stock OpenCPN imports the final archive in a disposable Windows CI profile;
the GUI test opens Options > Plugins and retains the displayed 2.0.0 version
and screenshot. OpenCPN normalises the zero fourth component when displaying
semantic versions. GetPlugInVersionMajor/Minor/Patch/Post are explicit overrides
returning the same release components used in the metadata.

Android packaging checks both native architecture and the library's unique
`libclimatology_pi.so` SONAME, its `libgorp.so` dependency and 16 KiB ELF segment
alignment. Touch-specific layout is applied after Qt styling: readable labels,
large controls, read-only sampled values and scrollable configuration pages.
Only the title recognises panel-drag gestures, leaving slider gestures native.
The previously disabled Android colour-map path is implemented with a GLES2
shader: monthly interpolation, transparency, Mercator rotation and longitude
wrapping work without requiring repeating NPOT textures. The shader restores
host texture, program, buffer and vertex attribute state after drawing.

Download the matching tarball and use OpenCPN Options > Plugins > Import
plugin. Publishing public assets does not add this release to OpenCPN's main
catalogue. That requires a separately reviewed metadata submission.

`collect.py` accepts explicit CI artifact directories and validates all archives
before assembling the public assets, SHA256SUMS, a package index and a combined
catalogue XML. It rejects missing translations, path traversal, native architecture
mismatches, changed binaries, invalid metadata or changed scientific outputs.
Flatpak locale catalogs are collected from the installed extension tree. Retained
Flatpak binaries repackaged with the unchanged PO catalogs record both their
original binary source revision and the packaging revision.
