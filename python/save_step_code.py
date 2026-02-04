# Extracts SAS code and UI JSON from SAS Custom Steps and saves them to a folder

import json
from pathlib import Path

input_dir = Path('Input Directory Here')

sas_output_dir  = input_dir / 'src' / 'sas'
json_output_dir = input_dir / 'src' / 'ui'

sas_output_dir.mkdir(exist_ok=True)
json_output_dir.mkdir(exist_ok=True)

files = input_dir.glob(f'*.step') 

for file_path in files:
    with open(file_path, encoding="utf-8") as step:
        data      = json.load(step)
        sas_code  = data["templates"]["SAS"]
        json_code = data["ui"]

        output_sas_file  = sas_output_dir  / f"{file_path.stem}.sas"
        output_json_file = json_output_dir / f"{file_path.stem}.json"

        with open(output_sas_file, "w", encoding="utf-8", newline="") as s:
            s.write(sas_code)
        
        with open(output_json_file, "w", encoding="utf-8", newline="") as j:
            j.write(json_code)