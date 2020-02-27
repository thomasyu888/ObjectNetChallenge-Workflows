#!/usr/bin/env cwl-runner
#
# Example validate submission file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

hints:
  DockerRequirement:
    dockerPull: python:3.7

inputs:

  - id: entity_type
    type: string
  - id: inputfile
    type: File?
  - id: goldstandard
    type: File

arguments:
  - valueFrom: validate.py
  - valueFrom: $(inputs.inputfile)
    prefix: -f
  - valueFrom: $(inputs.goldstandard)
    prefix: -a
  - valueFrom: result.json
    prefix: -o

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validate.py
        entry: |
          #!/usr/bin/env python
          import argparse
          import json
          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-e", "--entity_type", required=True, help="synapse entity type downloaded")
          parser.add_argument("-s", "--submission_file", help="Submission File")
          # NEW VALIDATION CODE HERE
          args = parser.parse_args()
          
          if args.submission_file is None:
              prediction_file_status = "INVALID"
              invalid_reasons = ['Expected FileEntity type but found ' + args.entity_type]
          else:
              with open(args.submission_file,"r") as sub_file:
                  message = sub_file.read()
              invalid_reasons = []
              prediction_file_status = "VALIDATED"
              # This is where the validation code should go
              #if not message.startswith("test"):
              #    invalid_reasons.append("Submission must have test column")
              #    prediction_file_status = "INVALID"
          result = {'prediction_file_errors':"\n".join(invalid_reasons),'prediction_file_status':prediction_file_status}
          with open(args.results, 'w') as o:
              o.write(json.dumps(result))
     
outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json   

  - id: status
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_status'])

  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_errors'])