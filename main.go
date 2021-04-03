// SPDX-FileCopyrightText: Copyright 2021 The protobuf-tools Authors
// SPDX-License-Identifier: BSD-3-Clause

// Command protoc-gen-deepcopy is a plugin for protoc which generates DeepCopyInto(), DeepCopy() and DeepCopyInterface() functions for .pb.go types.
package main

import (
	"flag"
	"fmt"

	"google.golang.org/protobuf/compiler/protogen"

	"github.com/protobuf-tools/protoc-gen-deepcopy/deepcopy"
)

// version is the this binary vesion.
// TODO(zchee): parse module version itself.
var version = "v0.0.1"

func main() {
	showVersion := flag.Bool("version", false, "print the version and exit")
	flag.Parse()
	if *showVersion {
		fmt.Printf("protoc-gen-go-grpc %v\n", version)
		return
	}

	var flags flag.FlagSet

	protogen.Options{
		ParamFunc: flags.Set,
	}.Run(func(gen *protogen.Plugin) error {
		gen.SupportedFeatures = deepcopy.SupportedFeatures

		for _, f := range gen.Files {
			if f.Generate {
				deepcopy.GenerateFile(gen, f)
			}
		}

		return nil
	})
}
