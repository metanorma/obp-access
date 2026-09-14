# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby gem (`obp-access`) that fetches informative content (introduction, scope, terms, bibliography) from the ISO Online Browsing Platform (OBP) and converts it to NISO STS XML. Published by Ribose Inc. under BSD-2-Clause license.

## Commands

- **Install dependencies:** `bundle install`
- **Run tests:** `bundle exec rspec` (note: retriever/access-fetch specs hit the live OBP API)
- **Lint:** `bundle exec rubocop`
- **Run a single test:** `bundle exec rspec spec/obp/access/grammar_parser_spec.rb`
- **Console:** `bin/console` (loads the gem for interactive use)
- **CLI:** `bundle exec exe/obp-access` (fetch a document or all languages from OBP)

## Critical rules

- **NEVER use Nokogiri for XML building.** The sts gem and lutaml-model handle all XML serialization. Nokogiri is used internally by those libraries but must not appear in our application code. The `Nokogiri::XML::Builder` usage in `elements/` is legacy tech debt being migrated to the sts gem's model-driven approach.
- **Never use `send` to call private methods** (breaks encapsulation).
- **Never use `respond_to?`** (poor typing — use type checking or duck typing).
- **Never use `instance_double` in specs** — use `double` instead.

## Architecture

Data flows through these classes in `lib/obp/access/`:

1. **`Access`** (entry point) — orchestrates the pipeline. `Obp::Access.fetch(urn)` returns an instance per language. `Access.fetch_all(urn, languages:)` returns separate instances per language. `Access.from_html(urn:, html:, caption:, titles:)` converts an already-downloaded OBP HTML fragment with no network access (the offline path used by fixture-based tests).

2. **`Parser`** — fetches content from the ISO OBP API (`https://www.iso.org/obp/ui`) via HTTP POST with a URN payload. Parses the JSON response to extract HTML content, titles, and images. **`RawHtmlParser`** subclasses it and duck-types the API for pre-captured HTML.

3. **`Urn`** — parses URN identity metadata (`originator`, `doc_number` incl. part numbers like `80000:-12` → "80000-12", `doc_type` IS/TS/TR/PAS/Guide/IWA, `edition`, `version`). `Elements::Root` builds `<std-ident>` from these — never parse URN segments positionally elsewhere.

4. **`Converter`** — wraps the HTML source, normalizes whitespace, parses it with Nokogiri, and passes DOM nodes to the Renderer.

5. **`Renderer`** — recursively walks DOM nodes and dispatches them to element classes registered in `ElementRegistry`. Each element class matches against CSS classes and builds NISO STS XML.

### Element system

- **`ElementRegistry`** — explicit registry of element classes. Elements call `ElementRegistry.register(Class)` at load time.
- **`Elements::Base`** — abstract base class. Subclasses implement `self.classes` (CSS class array) and `content` (XML builder).
- **`Elements::Root`** — creates the NISO STS document skeleton (`<standard>` with `<front>`, `<body>`, `<back>`).
- **`Elements::Terminology`** sub-elements handle term entries using the `tbx:` namespace.
- Other elements: `section`, `introduction`, `bibliography`, `paragraph`, `list`, `array`, `figure`, `figure_group`, `table_wrap`, `title`, `copyright`, `index`, `non_normative_note`.

### Supporting classes

- **`GrammarParser`** — extracts part-of-speech and gender from bold term markup (POS markers `adj.`/`verb`, gender markers `m`/`f`/`n`, 〈bracketed〉 subject fields). Gender/POS only occur in non-English term entries (fr/de/ru); examples live in `spec/obp/access/grammar_parser_spec.rb`.
- **`DomainExtractor`** — extracts subject-field domains from definition text.
- **`InlineRenderer`** — renders inline HTML elements (links, xrefs, italic, bold, entailed terms) to STS XML.
- **`Imager`** — downloads images from OBP. Uses `Parallel` for concurrent downloads.

### Testing conventions

- Captured OBP HTML fixtures live in `obp-output/` at the repo root (gitignored — download them via the CLI or a browser). Conversion specs read them through `Access.from_html` and **skip** when the fixture is absent, so the offline suite never touches the network.

## Key dependencies

- **sts** — NISO STS gem for generating STS objects from XML
- **lutaml/model** — model serialization framework
- **parallel** — concurrent HTTP requests

## Ruby version

Requires Ruby >= 3.1.
