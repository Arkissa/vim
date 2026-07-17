# haskell.vim

`haskell.vim` is a Vim plugin for Haskell development without HLS. It uses GHCi, tags, and Vim-native systems to provide a lightweight but capable editing experience.

## Goal

Provide a Haskell workflow in Vim that can work with normal GHC/Cabal/Stack projects without depending on the Haskell Language Server.

The plugin should integrate with Vim's own features where possible:

- completion through Vim completion APIs
- symbol lookup through tags and internal indexes
- diagnostics through compiler and quickfix
- hover/type display through popup or preview UI
- external tools through Vim jobs and commands
- debugging through a unified Vim-side debug UI

## Roadmap

### 1. Plugin foundation

Set up the plugin structure, configuration layer, project detection, package detection, session ownership, and buffer attachment model.

### 2. GHCi backend and REPL

Build a long-lived GHCi backend for semantic requests and a user-facing REPL experience that can coexist without corrupting plugin requests.

### 3. Completion

Support Haskell completion without HLS, including identifiers, imports, modules, pragmas, and useful fallback behavior when GHCi is unavailable.

### 4. Type query and hover

Support querying symbol types, expression types, visual-selection types, `:info`, `:kind`, and hover-style display inside Vim.

### 5. Compiler, diagnostics, and quickfix

Integrate build/check/test workflows with Vim's compiler and quickfix systems, including GHC errors, warnings, and type holes.

### 6. Tags, symbols, and navigation

Use Haskell tags tooling and internal indexes to support symbol lists, definition lookup, references, and optional Vim native tags export.

### 7. Rename

Provide Vim-side rename based on GHCi context plus tags/index results, with preview and ambiguity handling before applying edits.

### 8. Hoogle and Haddock

Support symbol and query lookup through Hoogle and Haddock, preferring local tools/docs when available and falling back to browser-based lookup when needed.

### 9. External toolchain integration

Integrate formatters, linters, and other Haskell tools while respecting the current project's GHC, Cabal, Stack, or ghcup environment.

### 10. Debugging

Provide a unified debug UI that can support both GHCi debugging and external debuggers such as `haskell-debug` through DAP.

### 11. Syntax and indentation

Provide rich Haskell syntax highlighting and Vim indentation support for common Haskell language constructs and extensions.

### 12. User interface, commands, documentation, and tests

Define user commands, `<Plug>` mappings, help documentation, smoke tests, and focused Vim9script tests for stable plugin behavior.

## Design approach

Each roadmap item should be designed separately before implementation. The roadmap records the complete intended scope; individual phase designs can expand one section at a time without losing the larger direction.

The implementation should favor small, focused Vim9script modules with clear boundaries. Feature logic should live under `import/haskell.vim/`, while `plugin/`, `ftplugin/`, `syntax/`, `indent/`, and `compiler/` should stay thin and focused on Vim integration points.

## Non-goals

- Do not depend on HLS for core behavior.
- Do not require generating a project-wide tags file for normal operation.
- Do not perform silent broad rename without preview.
- Do not hide external tool version issues behind implicit fallback behavior.
