import os
import requests
import json
from pathlib import Path

def get_program_path() -> str:
    """
    Gets the current directory of the program. If it is in a SAS Macro Variable, returns that value.
    Otherwise, if in a job, sends a request to the SAS Viya endpoint and returns the parent 
    directory of the job definition's property value.

    Has not been tested with SAS Studio Flows.
    
    Returns:
        str: The parent directory path as a string, or None if unavailable.
    """
    try:
        if SAS.symget('_SASPROGRAMFILE') != None:
            full_path = SAS.symget('_SASPROGRAMFILE')

        else:
            viya_url = os.getenv('SAS_SERVICES_URL')    # URL to Viya
            job_uri  = SAS.symget('SYS_JES_JOB_URI')    # Name of the running job
            token    = os.getenv('SAS_SERVICES_TOKEN')  # Oauth token

            # Set up the headers for authentication and content-type
            headers = {
                "Authorization": f"Bearer {token}",
                "Accept": "application/json"
            }

            request_url = f"{viya_url}/{job_uri}"

            # Send the GET request to the SAS Viya endpoint
            resp = requests.get(request_url, headers=headers)
            resp.raise_for_status()
            resp_json = resp.json()

            # Extract the path from the JSON response
            full_path = resp_json['jobRequest']['jobDefinition']['properties'][0]['value']
            
        parent_path = Path(full_path).parent

        return str(parent_path)  # Return as string

    except Exception as e:
        print(f"Error retrieving file path: {e}")
        return None