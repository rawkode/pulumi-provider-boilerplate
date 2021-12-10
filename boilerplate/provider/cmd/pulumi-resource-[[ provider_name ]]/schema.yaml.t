---
name: "[[ provider_name ]]"
version: 0.0.1
resources:
  "[[ provider_name ]]:index:Random":
    properties:
      length:
        type: integer
      result:
        type: string
    required:
    - length
    - result
    inputProperties:
      length:
        type: integer
    requiredInputs:
    - length
language:
  csharp:
    packageReferences:
      Pulumi: 3.*
  go:
    generateResourceContainerTypes: true
    importBasePath: "github.com/[[ git_username ]]/pulumi-[[ provider_name ]]/sdk/go/[[ provider_name ]]"
  nodejs:
    dependencies:
      "@pulumi/pulumi": "^3.0.0"
  python:
    requires:
      pulumi: ">=3.0.0,<4.0.0"
