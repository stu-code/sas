import json
import uuid
from pathlib import Path

CWD   = Path(__file__).parent
SASNB = CWD / "sas_python_notebook.sasnb"
IPYNB = CWD / "sas_python_notebook.ipynb"

def to_source_lines(value: str):
    normalized = value.replace("\r\n", "\n").replace("\r", "\n")
    lines = normalized.splitlines(keepends=True)
    return lines


def convert_output(output_entry):
    """A .sasnb output entry can bundle multiple mime items; split each into
    its own nbformat output dict so both render, in original order."""
    results = []
    for item in output_entry.get("items", []):
        mime = item["mime"]
        data = item["data"]
        if mime == "application/vnd.sas.compute.log.lines":
            try:
                log_entries = json.loads(data)
                text = "\n".join(e.get("line", "") for e in log_entries) + "\n"
            except (json.JSONDecodeError, TypeError):
                text = data
            results.append({
                "output_type": "stream",
                "name": "stdout",
                "text": to_source_lines(text),
            })
        elif mime == "application/vnd.sas.ods.html5":
            results.append({
                "output_type": "display_data",
                "data": {
                    "text/html": to_source_lines(data),
                },
                "metadata": {},
            })
        else:
            results.append({
                "output_type": "display_data",
                "data": {mime: data},
                "metadata": {},
            })
    return results


def convert_cell(cell):
    kind = cell["kind"]
    language = cell.get("language", "python")
    value = cell.get("value", "")

    if kind == 1:  # markdown
        return {
            "cell_type": "markdown",
            "id": uuid.uuid4().hex[:8],
            "metadata": {},
            "source": to_source_lines(value),
        }

    # kind == 2 -> code cell
    outputs = []
    for entry in cell.get("outputs", []):
        outputs.extend(convert_output(entry))

    metadata = {}
    if language and language != "python":
        metadata["vscode"] = {"languageId": language}

    return {
        "cell_type": "code",
        "id": uuid.uuid4().hex[:8],
        "execution_count": None,
        "metadata": metadata,
        "outputs": outputs,
        "source": to_source_lines(value),
    }


def main():
    with open(SASNB, "r", encoding="utf-8") as f:
        cells_raw = json.load(f)

    notebook = {
        "cells": [convert_cell(c) for c in cells_raw],
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {
                "name": "python",
            },
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }

    with open(IPYNB, "w", encoding="utf-8") as f:
        json.dump(notebook, f, indent=1, ensure_ascii=False)

    print(f"Wrote {IPYNB}")
    print(f"Cells: {len(notebook['cells'])}")


if __name__ == "__main__":
    main()
