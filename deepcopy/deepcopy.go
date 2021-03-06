// SPDX-FileCopyrightText: Copyright 2021 The protobuf-tools Authors
// SPDX-License-Identifier: BSD-3-Clause

// Package deepcopy generates DeepCopyInto(), DeepCopy() and DeepCopyInterface() functions for .pb.go types.
package deepcopy

import (
	"path/filepath"

	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/types/pluginpb"
)

// SupportedFeatures reports the set of supported protobuf language features.
const SupportedFeatures = uint64(pluginpb.CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL)

// list of _deepcopy.pb.go files package dependencies.
const (
	protoPackage = protogen.GoImportPath("google.golang.org/protobuf/proto")
)

// FileNameSuffix is the suffix added to files generated by deepcopy
const FileNameSuffix = "_deepcopy.pb.go"

// GenerateFile generates DeepCopyInto() and DeepCopy() functions for .pb.go types.
func GenerateFile(gen *protogen.Plugin, file *protogen.File) *protogen.GeneratedFile {
	if len(file.Messages) == 0 {
		return nil
	}

	filename := file.GeneratedFilenamePrefix + FileNameSuffix
	goImportPath := file.GoImportPath
	g := gen.NewGeneratedFile(filename, goImportPath)

	g.P("// Code generated by protoc-gen-deepcopy. DO NOT EDIT.")
	g.P()
	g.P("package ", filepath.Base(string(goImportPath)))
	g.P()

	for _, message := range file.Messages {
		typeName := message.Desc.Name()

		// Generate DeepCopyInto() method for this type
		g.P(`// DeepCopyInto supports using `, typeName, ` within kubernetes types, where deepcopy-gen is used.`)
		g.P(`func (in *`, typeName, `) DeepCopyInto(out *`, typeName, `) {`)
		g.P(`	p := `+g.QualifiedGoIdent(protoPackage.Ident("Clone"))+`(in).(*`, typeName, `)`)
		g.P(`	*out = *p`)
		g.P(`}`)

		// Generate DeepCopy() method for this type
		g.P(`// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new `, typeName, `. Required by controller-gen.`)
		g.P(`func (in *`, typeName, `) DeepCopy() *`, typeName, ` {`)
		g.P(`	if in == nil { return nil }`)
		g.P(`	out := new(`, typeName, `)`)
		g.P(`	in.DeepCopyInto(out)`)
		g.P(`	return out`)
		g.P(`}`)

		// Generate DeepCopyInterface() method for this type
		g.P(`// DeepCopyInterface is an autogenerated deepcopy function, copying the receiver, creating a new `, typeName, `. Required by controller-gen.`)
		g.P(`func (in *`, typeName, `) DeepCopyInterface() interface{} {`)
		g.P(`	return in.DeepCopy()`)
		g.P(`}`)
	}

	return g
}
