# Namespace for self-contained tool projects under tools/.
# Each tool is its own module; invoke as `just tools <tool> <recipe>`.

default:
    @just --list

mod meeting-sync 'meeting-sync'
