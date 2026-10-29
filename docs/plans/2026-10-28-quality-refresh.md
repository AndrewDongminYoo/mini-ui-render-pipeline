# Quality Tooling Refresh Plan

## Work

1. Verify repository identity, instructions, current changes and Oracle precedent.
2. Refresh compatible dependency and linter versions with existing package managers.
3. Run the declared local gates and `trunk check --all --no-fix`.
4. Reconcile affected knowledge and review the scoped candidate.
5. Commit locally and prepare visible evidence before requesting publication approval.

## Declared Gates

- `dart pub get`
- `dart analyze`
- `dart test`
- `dart format --output=none --set-exit-if-changed lib bin test example`

## Constraints and Oracle Waiver

The operator explicitly approved continuing after the project lookup was unavailable.
No indexed project identity or usable precedent was established; this is not a no-precedent claim.
Use the current Dart source, tests and CI as evidence.
Preserve the public Dart 3.10.7 minimum and verify that runtime separately from the installed Dart 3.13.7 SDK.
There are no runtime dependencies; refresh supported developer tools without changing public rendering algorithms or JSON contracts.
Preserve existing library, CLI, test and example source bytes unless a demonstrated maintenance incompatibility requires a narrow repair.
Use an owned temporary official minimum SDK and remove it after preserving evidence.
Run analysis, no-write explicit-path formatting, all tests, a compiled CLI synthetic input smoke check, offline reader regressions and the full no-fix Trunk scan.

## Offline scanner boundary

Run `python3 -B .trunk/configs/tests/test_trufflehog_to_sarif.py` to exercise the 17 filesystem JSONL diagnostic reader cases.
Trunk 1.25.0 consumes native paths in the SARIF path field; URI encoding drops findings for reserved filenames.
This adapter preserves native paths for Trunk and does not promise portable SARIF URI conformance.
Columns use Unicode code points, encoded findings retain file-level diagnostics, and scanner input errors fail the gate with `--fail-on-scan-errors`.
No candidate credential is verified with its provider.
Application source and document fixtures remain unchanged.

Source-location analysis reads at most 1 MiB plus one sentinel byte per file and caches at most eight files.
Oversized sources retain file-level findings without a region.
These limits bound source context; they do not bound all result memory or guarantee that filesystem I/O cannot block.
