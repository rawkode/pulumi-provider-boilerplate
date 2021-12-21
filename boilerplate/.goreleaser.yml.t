archives:
  - id: archive
    name_template: "{{ .Binary }}-{{ .Tag }}-{{ .Os }}-{{ .Arch }}"

before:
  hooks:
    - make provider

builds:
  - binary: pulumi-resource-[[ provider_name ]]
    dir: provider
    env:
      - CGO_ENABLED=0
    goarch:
      - amd64
      - arm64
    goos:
      - darwin
      - windows
      - linux
    ldflags:
      - -X github.com/[[ git_username ]]/pulumi-[[ provider_name]]/provider/pkg/version.Version={{.Tag}}
    main: ./cmd/pulumi-resource-[[ provider_name ]]/
changelog:
  skip: true

release:
  disable: false
  prerelease: auto

snapshot:
  name_template: "{{ .Tag }}-SNAPSHOT"
