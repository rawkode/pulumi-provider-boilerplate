package main

import (
	"github.com/[[ git_username ]]/pulumi-[[ provider_name ]]/provider/pkg/provider"
	"github.com/[[ git_username ]]/pulumi-[[ provider_name ]]/provider/pkg/version"
)

var providerName = "[[ provider_name ]]"

func main() {
	provider.Serve(providerName, version.Version)
}
