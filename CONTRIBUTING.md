# Contributing

## Reporting Issues

Open an issue using the appropriate template:

- **Settings Bug**: A repository setting is not being applied correctly
- **Settings Request**: Propose a new setting to enforce

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`feat/your-change`)
3. Make your changes
4. Ensure pre-commit hooks pass
5. Submit a pull request

## Guidelines

- Follow conventional commit messages (`type: description`)
- Shell scripts must pass `shellcheck` and `shellharden`
- All markdown must pass `markdownlint`
- Test changes with `--dry-run` before applying
- Never hardcode credentials or tokens

## Contact

<alejandrogarcia@iteso.mx>
