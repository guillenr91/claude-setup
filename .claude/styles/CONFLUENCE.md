# Confluence Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Use this guide when converting Markdown documentation into Confluence pages or reviewing Confluence-targeted content.

### Rule: Treat the Confluence title as the document H1

Trigger: publishing a Markdown document to a Confluence page.
Do: put the document title in the Confluence page title field.
Do: remove the top Markdown `# <title>` heading from the body before publishing.
Do: start the body with the short intro paragraph or overview content.
Do not: duplicate the page title as the first body heading.

### Rule: Promote body sections one level after removing the title

Trigger: the source Markdown starts with `# <title>` followed by `##` body sections.
Do: convert the body section headings to top-level Confluence body headings.
Do: use `#` headings in Markdown sent to Confluence for primary body sections.
Do not: leave every body section one level lower because the title was removed.

### Rule: Use the native Confluence table of contents

Trigger: updating an existing Confluence guide that already has a table of contents, or publishing a guide that needs a
table of contents.
Do: use the native Confluence TOC macro or element.
Do: preserve the existing TOC element when updating a page in Atlassian Document Format.
Do: place the native TOC at the top of the page before the intro paragraph when that is the existing page style.
Do: represent the TOC as an ADF extension with `extensionType: com.atlassian.confluence.macro.core`,
`extensionKey: toc`, and macro parameter `style: none` when generating ADF directly.
Do: use this reusable ADF node when a native TOC is needed:
```json
{
  "type": "extension",
  "attrs": {
    "layout": "default",
    "extensionType": "com.atlassian.confluence.macro.core",
    "extensionKey": "toc",
    "parameters": {
      "macroParams": {
        "style": {
          "value": "none"
        }
      },
      "macroMetadata": {
        "schemaVersion": {
          "value": "1"
        },
        "title": "Table of Contents"
      }
    }
  }
}
```
Do not: add a handwritten Markdown `Table of contents` heading and link list to Confluence pages.
Do not: replace a native Confluence TOC with static Markdown links when updating the full page body.
Do not: use a Markdown publish path when preserving an existing native TOC is required and the tool cannot preserve it.
Exception: when the available tooling cannot create or preserve the native TOC, omit the static TOC and state that the
native TOC must be added manually in Confluence.

### Rule: Keep Confluence pages self-contained

Trigger: converting a local Markdown guide into a shared Confluence page.
Do: include the commands, values files, YAML manifests, and configuration snippets readers need directly in the page.
Do: describe external prerequisites with stable shared links or plain process names.
Do not: reference local files, local absolute paths, home-directory paths, temp files, agent-only directories, or scratch
artifacts.
Exception: link to a shared repository file only when the target audience is expected to have access and the page does
not need to stand alone.

### Rule: Replace local setup assumptions with reader location

Trigger: a Markdown guide assumes the reader is in a local repository, terminal, control host, container, or remote
machine.
Do: state where the reader must be before each location-sensitive action.
Do: write the instruction from the reader's execution context, such as "In that SSH session, create the file" or "Run
this from the host where the CLI is configured."
Do not: rely on "working directory" or "as above" when the command runs somewhere different from the previous step.

### Rule: Preserve linear guide flow

Trigger: converting a step-by-step Markdown procedure into Confluence.
Do: write steps so each step depends on the previous step unless a branch is explicitly stated.
Do: put file examples directly in the step where the reader creates or applies them.
Do not: move required YAML, JSON, or command examples into appendices when the reader needs them to complete the step.
Do not: repeat prerequisites or working directory notes in every step when the guide is intentionally linear.

### Rule: Explain what each step does before commands

Trigger: a Confluence page is meant for readers unfamiliar with the tooling.
Do: start each procedural step with one short "What this step does" paragraph.
Do: explain the purpose of commands and configuration before showing them.
Do not: make readers infer why they are creating a file, running a command, or applying a manifest.

### Rule: Keep configuration minimal

Trigger: embedding configuration in a Confluence guide.
Do: include only properties required for the described setup to work.
Do: add a short table explaining each included property and why it is needed.
Do not: paste full generated exports, default-heavy configuration, comments from test runs, or fields that only preserve
tool-generated layout noise.
Exception: include a generated field when the target tool requires it for import, stable updates, or layout.

### Rule: Prefer concise success signals over test transcripts

Trigger: documenting verification or expected results in Confluence.
Do: list success signals the reader can check.
Do: use current-state language such as "Success signal:" and "Expected result:".
Do not: include live test dates, operator names, stack names, command logs, or "verified live setup" sections.

### Rule: Use Confluence-friendly code blocks

Trigger: including commands or configuration in a Confluence-bound Markdown body.
Do: use fenced code blocks with a language tag when the language is clear.
Do: prefer `shell` or `bash` for terminal commands, and use the actual data format for files such as `yaml` or `json`.
Do: keep copy-paste blocks free of prompts, output, secrets, and machine-specific paths.
Do not: combine command output with commands unless the output is the actual thing the reader must copy.

### Rule: Prefer ADF for pages with Confluence-only elements

Trigger: updating a page that contains native Confluence elements such as a TOC macro, inline smart cards, layouts,
panels, statuses, expand blocks, or other editor-created elements.
Do: fetch the existing page in Atlassian Document Format before updating.
Do: preserve native extension nodes from the fetched ADF when replacing or regenerating the rest of the body.
Do: validate generated ADF as JSON before publishing.
Do: inspect key generated nodes before publishing, especially the first few nodes, code blocks, tables, and smart links.
Do: fetch the page after publishing in ADF and confirm the native elements still exist.
Do not: assume Markdown round-tripping preserves Confluence-only elements.
Do not: pass very large generated ADF bodies through a tool or prompt boundary that may truncate the content.

Reusable ADF validation snippets:

```ruby
require "json"

doc = JSON.parse(File.read("<adf-file>"))
raise "not an ADF doc" unless doc["type"] == "doc"
raise "missing content" unless doc["content"].is_a?(Array)
```

```ruby
require "json"

doc = JSON.parse(File.read("<adf-file>"))
first = doc.fetch("content").first
raise "missing native TOC" unless first.dig("attrs", "extensionKey") == "toc"
```

```ruby
require "json"

doc = JSON.parse(File.read("<adf-file>"))
code_blocks = []
walk = lambda do |node|
  if node.is_a?(Hash)
    code_blocks << node if node["type"] == "codeBlock"
    node.each_value { |value| walk.call(value) }
  elsif node.is_a?(Array)
    node.each { |value| walk.call(value) }
  end
end
walk.call(doc)
```

### Rule: Use tables for compact reference data

Trigger: explaining names, variables, properties, signals, checks, or troubleshooting mappings.
Do: use Markdown tables with short column names and concise cells.
Do: keep table rows scannable, with one concept per row.
Do not: use tables for long prose or multi-step instructions.

### Rule: Use bullets for short outcomes and records

Trigger: listing success signals, things to record, prerequisites, or expected visible outcomes.
Do: use flat bullet lists.
Do: keep each bullet as one short statement.
Do not: use nested bullets unless hierarchy is required to prevent ambiguity.

### Rule: Use links that survive Confluence conversion

Trigger: linking from a Confluence page to another shared page or external shared resource.
Do: use normal Markdown links with descriptive link text.
Do: use a Confluence smart link for internal Confluence page links when the page should render as a Confluence page
card or inline smart link.
Do: keep short internal-link bullets on one physical line before publishing when line breaks would split a sentence
around the smart link.
Do: format internal Confluence page smart links as
`<custom data-type="smartlink" data-id="id-0">https://<site>/wiki/spaces/<SPACE_KEY>/pages/<PAGE_ID></custom>`.
Do: fetch or otherwise verify links in-session before publishing when the target must be cited or trusted.
Do not: include local file links, draft-only links, or URLs that require an unauthenticated check if the page should be
usable by teammates.
Exception: internal authenticated Confluence links can be used when the page was fetched successfully through the
available Confluence tooling in the current session.

### Rule: Keep Confluence page titles concise

Trigger: creating or updating a Confluence page title.
Do: use a short, searchable title.
Do: remove redundant words that only describe the artifact type when the parent page already supplies context.
Do not: copy an overly long Markdown title into Confluence when a shorter title is clearer.

### Rule: Fetch after publishing

Trigger: creating or updating a Confluence page through tooling.
Do: fetch the page after publishing.
Do: confirm the title, parent, and key content changed as intended.
Do not: assume the Markdown converted correctly without reading the stored page back.
