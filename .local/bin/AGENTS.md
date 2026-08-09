# Agent Instructions

When changing scripts in this directory, include matching updates for user-facing help text and shell completions when the CLI surface changes.

For the `wt` entrypoint specifically:
- Command behavior lives under `.config/ivu/wt/*.bash`.
- Update `.config/ivu/wt/help.bash` for new commands, options, examples, or changed semantics.
- Update `.config/ivu/wt/completions.bash` for new commands, options, or completable argument values.
