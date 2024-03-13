# Changelog

## v1.1.1

### Fixes

- Fix compile error when Earmark is not installed

## v1.1.0

### Enhancements

- Add function support for `:build` option. Following forms of functions are supported:
  - `fn path, body, attrs -> _ end`
  - `&Mod.fun/3`
