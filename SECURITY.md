# Security Policy

## Scope

This repository contains automation scripts that interact with GitHub
APIs using tokens. Security of these tokens and the settings they
manage is critical.

## Reporting a Vulnerability

If you discover a security issue, please report it privately:

- Email: alejandrogarcia@iteso.mx
- Include: affected file, description, reproduction steps

Do not open a public issue for security vulnerabilities.

## Security Practices

- GitHub tokens are stored as repository secrets, never in code
- Scripts use least-privilege API scopes
- All dependencies are monitored via Dependabot
- Secret scanning and push protection are enabled
