# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby gem (`obp-access`) that fetches informative content (introduction, scope, terms, bibliography) from the ISO Online Browsing Platform (OBP) and converts it to NISO STS XML. Published by Ribose Inc. under BSD-2-Clause license.

## Commands

- **Install dependencies:** `bundle install`
- **Run tests:** `bundle exec rake test` (uses test-unit framework, tests in `test/`)
- **Lint:** `bundle exec rubocop`
- **Run a single test:** `ruby -Ilib -Itest test/test_something.rb`
- **Console:** `bin/console` (loads the gem for interactive use)

## Architecture

Data flows through four main classes in `lib/obp/access/`:

1. **`Access`** (entry point) — orchestrates the pipeline. `Obp::Access.fetch(urn)` returns an instance that can produce XML (`to_xml`), STS objects (`to_sts`), or XML files (`to_xml_file`).

2. **`Parser`** — fetches content from the ISO OBP API (`https://www.iso.org/obp/ui`) via HTTP POST with a URN payload. Parses the JSON response to extract HTML content, titles (parallelized across languages), and images.

3. **`Converter`** — wraps the HTML source, normalizes whitespace, parses it with Nokogiri, and passes the DOM nodes to the Renderer.

4. **`Renderer`** — recursively walks DOM nodes and dispatches them to element classes (subclasses of `Elements::Base` in `lib/obp/access/elements/`). Each element class matches against CSS classes on the DOM node and builds NISO STS XML via `Nokogiri::XML::Builder`.

### Element system

- **`Elements::Base`** — abstract base class. Subclasses implement `self.classes` (CSS class array to match) and `content` (XML builder). The `render` method inserts the built XML into the document at a target path.
- **`Elements::Root`** — creates the NISO STS document skeleton (`<standard>` with `<front>`, `<body>`, `<back>`).
- **`Elements::Terminology`** and its sub-elements (`definition`, `note`, `source`, `example`, `tig`, `tig_preferred`, `tig_admitted`) handle term entries using the `tbx:` namespace.
- Other elements: `section`, `introduction`, `bibliography`, `paragraph`, `list`, `array`, `figure`, `figure_group`, `table_wrap`, `title`, `copyright`.

`Renderer.elements` discovers all `Elements::Base` subclasses at runtime via `ObjectSpace`, so adding a new element class (that inherits from `Base`) automatically includes it in rendering.

### Supporting classes

- **`Imager`** — downloads images from OBP and saves them locally. Uses `Parallel` for concurrent downloads.

## Key dependencies

- **nokogiri** — HTML/XML parsing and building
- **parallel** — concurrent HTTP requests (title fetching, image downloads)
- **sts** — NISO STS gem for generating STS objects from XML

## Testing

Test fixtures are HTML snapshots in `spec/fixtures/`. The `spec/` directory currently only contains fixtures; `test/` is the test directory but has no test files yet. The Rake default task runs `rake test`.

## Ruby version

Requires Ruby >= 3.1.
