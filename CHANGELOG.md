# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Telemetry events are now fired during event handling.
- Events can be delivered directly to handlers, bypassing the queue.

### Changed
- Messages are now deleted after handlers complete.

### Fixed
- Fixed a crash that occurred when message decoding failed.

## [0.5.1] - 2019-06-04
### Changed
- Documentation and test updates.

### Fixed
- Work around a hackney issue leaving SSL messages in queue.
- Improve crash handling in the poller.

## [0.5.0] - 2019-04-16
- Major rewrite.
- Add a new API and deprecate the old one.

## [0.4.0] - 2018-04-30
### Changed
- Support timeouts longer than 15 minutes.

## [0.3.0] - 2018-04-19
### Changed
- Renamed `send` to `call_after`.
- Update README.md.

## [0.2.0] - 2018-04-19
### Added
- Add documentation to README.md

## [0.1.0] - 2018-04-18
Initial release.

[Unreleased]: https://github.com/hippware/dawdle/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/hippware/dawdle/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/hippware/dawdle/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/hippware/dawdle/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/hippware/dawdle/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/hippware/dawdle/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/hippware/dawdle/releases/tag/v0.1.0
