// SPDX-FileCopyrightText: Copyright 2021 The protobuf-tools Authors
// SPDX-License-Identifier: BSD-3-Clause

package test

import (
	"testing"

	"google.golang.org/protobuf/proto"

	"github.com/protobuf-tools/protoc-gen-deepcopy/testdata/generated"
)

func TestTagType(t *testing.T) {
	if !checkTagTypeDeepCopy(&generated.TagType{}) {
		t.Fail()
	}
}

func checkTagTypeDeepCopy(value interface{}) bool {
	type TagTypeDeepCopy interface {
		DeepCopyInto(*generated.TagType)
		DeepCopy() *generated.TagType
		DeepCopyInterface() interface{}
	}
	_, ok := value.(TagTypeDeepCopy)
	return ok
}

func TestTypeWithRepeatedField(t *testing.T) {
	in := &generated.RepeatedFieldType{
		Ns: []string{"ns-1", "ns-2"},
	}
	out := &generated.RepeatedFieldType{}
	in.DeepCopyInto(out)
	if !proto.Equal(in, out) {
		t.Fatalf("Deepcopy of proto(DeepCopyInto) is not equal. got: %v, want: %v", *out, *in)
	}

	out = in.DeepCopy()
	if !proto.Equal(in, out) {
		t.Fatalf("Deepcopy of proto(DeepCopy) is not equal. got: %v, want: %v", *out, *in)
	}

	outInterface := in.DeepCopyInterface()
	outPb, ok := outInterface.(*generated.RepeatedFieldType)
	if !ok {
		t.Fatalf("DeepCopyInterface was not a proto message, was %T", outInterface)
	}
	if !proto.Equal(in, outPb) {
		t.Fatalf("Deepcopy of proto(DeepCopy) is not equal. got: %v, want: %v", outPb, in)
	}
}
