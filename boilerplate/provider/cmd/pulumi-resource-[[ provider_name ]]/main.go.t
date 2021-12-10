package main

import (
	"[[ git_url ]]/provider/pkg/provider"
	"[[ git_url ]]/provider/pkg/version"
)

var providerName = "[[ provider_name ]]"

func main() {
	provider.Serve(providerName, version.Version)
}
