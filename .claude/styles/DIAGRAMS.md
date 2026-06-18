# Diagrams Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Use this guide when creating, modifying, or reviewing workflow diagrams, architecture diagrams, or any visual
documentation.

## Tool

### Rule: Use diagrams.net as the default diagramming tool

Trigger: Creating any diagram for documentation purposes.
Do: Use diagrams.net (formerly draw.io) with `.drawio` file format.
Do not: Use PlantUML, Mermaid, or other text-based diagramming tools unless explicitly requested.

Rationale: diagrams.net provides full control over element positioning, supports multi-page documents, and produces
files that can be edited in the desktop app, web app, or VS Code extension.

## File Structure

### Rule: Use multi-page documents for related diagrams

Trigger: Creating multiple diagrams for the same feature or ticket.
Do: Place all related diagrams in a single `.drawio` file with separate pages (tabs).
Do not: Create separate files for each diagram variation.
Example: A feature with Option A, Option B, and Current Flow diagrams should have three pages in one file.

### Rule: Name files descriptively with ticket prefix

Trigger: Creating a new diagram file.
Do: Use format `<TICKET_ID>-<descriptive-name>.drawio`.

### Rule: Store diagrams in a dedicated directory

Trigger: Creating diagrams for a ticket or feature.
Do: Place `.drawio` files in a `diagrams/` subdirectory within the ticket or feature context folder.

## Page Layout

### Rule: Use column-based layout for workflow diagrams

Trigger: Creating a workflow diagram with sequential steps.
Do: Organize the diagram into vertical columns, one per step or phase.
Do: Include for each column:
- Header box at top (colored, contains step title)
- Description text box below header (white background with colored border matching header)
- Workflow elements below the description

### Rule: Maintain vertical separation between sections

Trigger: Positioning elements in different diagram sections (e.g., descriptions above workflow elements).
Do: Ensure clear visual separation between stacked sections.
Do: Leave adequate whitespace so elements do not overlap or crowd each other.
Do: Keep consistent vertical gaps between section types across the diagram.
Do not: Allow elements from one section to touch or overlap elements from another section.

### Rule: Size containers to fit content with margins

Trigger: Creating any container element (headers, descriptions, process boxes).
Do: Size width and height to fit all text content plus comfortable margins on all sides.
Do: Make containers wide enough that text does not wrap excessively or become cramped.
Do: Use consistent sizing for similar elements across the diagram.
Do: Prefer wider containers over narrow ones when content includes technical terms or code.
Do not: Force text to wrap into many short lines to fit a narrow container.

### Rule: Space elements to prevent overlap

Trigger: Positioning multiple elements horizontally or vertically.
Do: Leave adequate gaps between adjacent elements.
Do: Ensure connectors have room to route without crossing through elements.
Do: Keep consistent spacing between similar element types.
Do: Adjust spacing based on content width to maintain visual balance.
Do not: Crowd elements together or allow them to touch.

### Rule: Include a legend section

Trigger: Creating any diagram with color-coded elements.
Do: Add a legend explaining each color's meaning.
Do: Position the legend in a consistent location (typically rightmost area of the diagram).
Do: Include a summary box listing key information relevant to the diagram.

### Rule: Group legend items together

Trigger: Creating legend color indicators.
Do: Use a group element (`style="group"`) to contain all legend color items.
Do: Each legend item consists of a small color box and a text label.
Do: Space legend items consistently with equal vertical gaps.
Do: Align color boxes and text labels.

### Rule: Size canvas to fit all content

Trigger: Creating or modifying a diagram page.
Do: Set `dx` and `dy` values large enough to display all diagram content.
Do: Set `pageWidth` and `pageHeight` to accommodate the diagram layout.
Do: Expand canvas dimensions when adding more content rather than cramping elements.
Do not: Leave content extending beyond the visible canvas area.

## Color Coding

### Rule: Use consistent colors for element categories

Trigger: Coloring diagram elements.
Do: Apply these standard colors:

| Category | Fill Color | Stroke Color | Use For |
|----------|------------|--------------|---------|
| Blue | #dae8fc | #6c8ebf | Primary service steps (e.g., main service being modified) |
| Green | #d5e8d4 | #82b366 | Requirement met, success states, preserved data |
| Yellow | #fff2cc | #d6b656 | Decision points, no code changes needed, intermediate states |
| Pink/Coral | #f8cecc | #b85450 | Code change required, deletion actions, end states |
| Purple | #e1d5e7 | #9673a6 | External services (e.g., AWS, third-party) |

### Rule: Match description box border to header color

Trigger: Creating a step column with header and description.
Do: Set the description text box `strokeColor` to match the header's `strokeColor`.
Do: Keep description box `fillColor=#FFFFFF` (white background).

## Workflow Elements

### Rule: Use standard shapes for workflow components

Trigger: Adding elements to a workflow diagram.
Do: Apply these shape conventions:

| Element Type | Shape | Style |
|--------------|-------|-------|
| Start/End | Filled circle | `ellipse;fillColor=#000000` |
| Process step | Rounded rectangle | `rounded=1` |
| Decision | Diamond | `rhombus` |
| Header | Rectangle | `rounded=0` |

### Rule: Add spacing to prevent text overlap with element borders

Trigger: Creating any workflow element with text (headers, process boxes, decisions).
Do: Add `spacing=5;` to the style attribute for all workflow elements.
Do: This creates a 5px margin between the text and the element outline on all sides.
Example: `style="rounded=1;whiteSpace=wrap;html=1;spacing=5;fillColor=#dae8fc;strokeColor=#6c8ebf;"`

For description text boxes, use individual spacing properties:
`spacingLeft=5;spacingTop=5;spacingRight=5;spacingBottom=5;`

### Rule: Text must never exceed container bounds

Trigger: Adding or modifying text in any diagram element.
Do: Ensure all text fits completely within its containing shape with proper margins.
Do: After any font change, verify text does not overflow the element boundaries.
Do: Increase element width and/or height when text exceeds bounds - never truncate or allow overflow.
Do: Account for larger fonts (Verdana is wider than default, Courier New at 14px is larger than regular text).
Do: Test with the longest text content to ensure the element size accommodates it.

This rule takes priority over minimum size guidelines - if text requires a larger container, increase the size.

### Rule: Size workflow elements to fit content

Trigger: Creating workflow element boxes.
Do: Size elements to fit their text content with comfortable margins.
Do: Make elements wider when they contain code text (Courier New is wider than Verdana).
Do: Increase height for multi-line labels.
Do: If text overlaps borders after adding spacing, increase element dimensions rather than reducing spacing.
Do not: Use elements so narrow that text wraps awkwardly or touches borders.

### Rule: Label decision branches

Trigger: Creating arrows from decision diamonds.
Do: Add "Yes" or "No" labels to outgoing arrows using the `value` attribute.

### Rule: Use orthogonal connectors

Trigger: Connecting workflow elements.
Do: Use `edgeStyle=orthogonalEdgeStyle` for all connectors.
Do: Use waypoints (`<Array as="points">`) for complex routing.

## Text Content

### Rule: Include a page title

Trigger: Creating a new diagram page.
Do: Add a title element at the top of the page.
Do: Center the title horizontally.
Do: Use `fontSize=16` for titles (larger than body text).
Do: Use bold formatting for the main title text.
Do: Include a subtitle or brief description below the main title if helpful.
Do: Use `strokeColor=none;fillColor=none` for title elements (no border or background).

### Rule: Include detailed step descriptions

Trigger: Creating a step column.
Do: Add a description text box containing:
- Context for when this step occurs
- Numbered list of actions taken
- Key data or field values involved

Do not: Put lengthy descriptions inside workflow element boxes.
Do: Keep workflow element labels short (2-3 words max).

### Rule: Use Verdana font for all regular text

Trigger: Adding any text to diagram elements.
Do: Set `fontFamily=Verdana;` in the style attribute for all text elements.
Do: Use minimum `fontSize=12` for all regular text (headers, descriptions, workflow labels).
Example: `style="text;html=1;fontFamily=Verdana;fontSize=12;..."`

### Rule: Use Courier New font for code text

Trigger: Including code references in diagram text (API endpoints, variable names, constants, field names).
Do: Use `fontFamily=Courier New;fontSize=14;` for code text.
Do: Identify code text as: API paths, variable names, constants, field names, plan codes, table names.
Examples of code text:
- API endpoints: `<METHOD> /<resource>/<action>/{<param>}`
- Constants: `<CONSTANT_NAME>`, `<NAMESPACED-CONSTANT-1>`
- Field names: `<fieldName>`, `<otherFieldName>`
- Table names: `<TableName>`, `<OtherTableName>`

For mixed text in description boxes, use inline HTML formatting:
```
value="Regular text &lt;font face=&apos;Courier New&apos; style=&apos;font-size:14px&apos;&gt;CODE_TEXT&lt;/font&gt; more regular text"
```

### Rule: Use consistent text formatting

Trigger: Adding text to diagram elements.
Do: Use `fontSize=12` minimum for headers, descriptions, and workflow elements.
Do: Use `fontSize=14` minimum for code text.
Do: Use `&lt;b&gt;` for bold text in titles (XML-escaped).
Do: Use `&#xa;` for line breaks in multi-line text.

## XML Structure

### Rule: Use unique IDs with semantic prefixes

Trigger: Creating diagram elements programmatically.
Do: Use descriptive IDs with step prefixes: `step1-header`, `step2-desc`, `arrow1-2`.
Do not: Use auto-generated or numeric-only IDs.

### Rule: Set required mxGraphModel attributes

Trigger: Creating a new diagram page.
Do: Include these attributes in `<mxGraphModel>`:

    dx="..." dy="..." grid="1" gridSize="10" guides="1" tooltips="1" 
    connect="1" arrows="1" fold="1" page="1" pageScale="1" 
    pageWidth="..." pageHeight="..." math="0" shadow="0"

Do: Set `dx`, `dy`, `pageWidth`, and `pageHeight` values to fit all diagram content.

### Rule: Structure multi-page files correctly

Trigger: Creating a `.drawio` file with multiple pages.
Do: Use this structure:
```xml
<mxfile host="app.diagrams.net" agent="Claude" pages="N">
  <diagram name="Page 1 Name" id="unique-id-1">
    <mxGraphModel ...>...</mxGraphModel>
  </diagram>
  <diagram name="Page 2 Name" id="unique-id-2">
    <mxGraphModel ...>...</mxGraphModel>
  </diagram>
</mxfile>
```
Do: Set `pages="N"` in the `<mxfile>` tag to match the number of diagram pages.
