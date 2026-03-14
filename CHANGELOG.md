# Changelog

All notable changes to this project will be documented in this file.

## [0.1.4] - 2026-03-14

### Security

- **CRITICAL FIX**: Fixed command injection vulnerability in device configuration (CVE pending)
- Added input validation for IP addresses and USB bus IDs
- Improved variable quoting in generated shell scripts
- Added protection against malicious configuration values

### Added

- Comprehensive security audit documentation (SECURITY_AUDIT.md)
- Security policy and vulnerability reporting guidelines (SECURITY.md)
- Input validation functions for IP addresses and bus IDs
- Security-focused code comments throughout scripts

### Changed

- Enhanced README with security features section
- Updated security considerations with best practices
- Improved error handling for invalid configuration values

## [0.1.3] - 2024-12-21

### Changed

- Added an automation example to the README.md.

## [0.1.2] - 2024-10-18

### Added

- `log_level` option to configure the verbosity of the add-on logs.
- Enhanced scripts to respect the `log_level` setting for better debugging.

## [0.1.1] - 2024-10-09

### Added

- `repository.yaml` file for Home Assistant add-on repository metadata, enabling add-on discovery and compatibility with Home Assistant.

## [0.1.0] - 2024-10-07

### Added

- Initial release.

---

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
