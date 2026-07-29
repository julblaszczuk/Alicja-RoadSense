# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.0.x   | ✅        |

## Reporting a Vulnerability

**This is a safety-critical application.** Security vulnerabilities could directly impact driver safety.

### How to Report

1. **DO NOT** open a public issue for security vulnerabilities
2. Email: **security@alicja-roadsense.com**
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix**: Depending on severity
- **Disclosure**: After fix is available

### Scope

- On-device processing (no data exfiltration)
- Camera/microphone access (privacy)
- Local database encryption
- Permission handling
- TFLite model integrity

### Out of Scope

- Third-party services (Mapbox, etc.)
- Device-level security
- Physical safety (use at own risk)

## Security Principles

1. **Local-first**: All processing on-device
2. **No cloud upload**: Video/images never leave device without consent
3. **Minimal permissions**: Only request what's needed
4. **Encryption at rest**: Local database encrypted
5. **Fail safely**: Errors don't compromise safety

## Safety Disclaimer

This app is an **assistive tool only**. It does NOT replace driver attention. The developers are not liable for accidents or missed detections.
