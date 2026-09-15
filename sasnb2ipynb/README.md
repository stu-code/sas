# sasnb2ipynb.py

A simple POC reference program that converts a SAS Notebook (`.sasnb`) to a standard Jupyter Notebook (`.ipynb`) that renders 1:1 in VS Code. This program was built to convert `sas_python_notebook.sasnb` and may not work on all SAS notebooks.

## Why

`.sasnb` files are used by the SAS extension for VS Code and store notebooks as a flat JSON array of cells with SAS-specific output mime types (`application/vnd.sas.ods.html5` for results/graphics, `application/vnd.sas.compute.log.lines` for the compute log). This script is an example of how .sasnb files have a similar enough structure to convert to .ipynb, which renders in GitHub.

## What it does

1. **Reads the `.sasnb`** — a JSON array of cells, each with `kind` (`1` = markdown, `2` = code), a `language` (`python`, `sas`, or `sql`), a `value` (source text), and `outputs`.
2. **Converts each cell**:
   - Markdown cells → nbformat `markdown` cells.
   - Code cells → nbformat `code` cells. Non-Python cells (`sas`, `sql`) get `metadata.vscode.languageId` set so VS Code syntax-highlights them correctly, even though the notebook declares a single Python kernelspec.
3. **Converts each output**:
   - `application/vnd.sas.ods.html5` (SAS ODS results — tables, inline SVG graphics — as full HTML documents) → standard `text/html` `display_data` output.
   - `application/vnd.sas.compute.log.lines` (JSON array of `{line, type}` log entries) → joined into plain text as a `stream`/`stdout` output.
   - A single `.sasnb` output can bundle multiple mime items (e.g. a result table plus a log); each is split into its own nbformat output entry, in original order.
4. **Writes** a valid `nbformat` 4.5 `.ipynb` file (with `kernelspec`, `language_info`, and per-cell `id` fields).

## Usage

Edit `SASNB` and `IPYNB` at the top of the script to choose different input/output files, then run:

```bash
py convert_sasnb.py
```

## Limitations

- The output notebook is set up for **display only**, not re-execution. The original `.sasnb` runs cells against a SAS Compute/Viya server session (with mixed python/sas/sql cells sharing state); there's no equivalent Jupyter kernel, so the generated `.ipynb` uses a plain Python 3 kernelspec as a placeholder.
- Only handles the two mime types observed from the `sas_python_notebook.sasnb` file in this folder (`application/vnd.sas.ods.html5`, `application/vnd.sas.compute.log.lines`). Any other mime type is passed through as-is into a `display_data` output, which may not render if a renderer doesn't understand it.