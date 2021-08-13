# protoc-gen-deepcopy

[![Go Reference](https://pkg.go.dev/badge/github.com/protobuf-tools/protoc-gen-deepcopy.svg)](https://pkg.go.dev/github.com/protobuf-tools/protoc-gen-deepcopy)

protoc-gen-deepcopy is a plugin for protoc which generates `DeepCopyInto()`, `DeepCopy()` and `DeepCopyInterface()` functions for .pb.go types.


## Generated

```proto
syntax = "proto3";

package generated;

option go_package = "github.com/protobuf-tools/protoc-gen-deepcopy/testdata/generated";

// TagType for ensure DeepCopyInto method is created.
message TagType {
    uint32 fieldA = 1;
    string fieldB = 2;
}

// TagTypeMap for ensure created map type.
message TagTypeMap {
    map<string, TagType> tag_types = 1;
}

// RepeatedFieldType for ensure repeated field in an API is not copied twice.
message RepeatedFieldType {
    repeated string ns = 1;
}
```

```go
// Code generated by protoc-gen-deepcopy. DO NOT EDIT.

package generated

import (
	proto "google.golang.org/protobuf/proto"
)

// DeepCopyInto supports using TagType within kubernetes types, where deepcopy-gen is used.
func (in *TagType) DeepCopyInto(out *TagType) {
	p := proto.Clone(in).(*TagType)
	*out = *p
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new TagType. Required by controller-gen.
func (in *TagType) DeepCopy() *TagType {
	if in == nil {
		return nil
	}
	out := new(TagType)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInterface is an autogenerated deepcopy function, copying the receiver, creating a new TagType. Required by controller-gen.
func (in *TagType) DeepCopyInterface() interface{} {
	return in.DeepCopy()
}

// DeepCopyInto supports using TagTypeMap within kubernetes types, where deepcopy-gen is used.
func (in *TagTypeMap) DeepCopyInto(out *TagTypeMap) {
	p := proto.Clone(in).(*TagTypeMap)
	*out = *p
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new TagTypeMap. Required by controller-gen.
func (in *TagTypeMap) DeepCopy() *TagTypeMap {
	if in == nil {
		return nil
	}
	out := new(TagTypeMap)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInterface is an autogenerated deepcopy function, copying the receiver, creating a new TagTypeMap. Required by controller-gen.
func (in *TagTypeMap) DeepCopyInterface() interface{} {
	return in.DeepCopy()
}

// DeepCopyInto supports using RepeatedFieldType within kubernetes types, where deepcopy-gen is used.
func (in *RepeatedFieldType) DeepCopyInto(out *RepeatedFieldType) {
	p := proto.Clone(in).(*RepeatedFieldType)
	*out = *p
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new RepeatedFieldType. Required by controller-gen.
func (in *RepeatedFieldType) DeepCopy() *RepeatedFieldType {
	if in == nil {
		return nil
	}
	out := new(RepeatedFieldType)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInterface is an autogenerated deepcopy function, copying the receiver, creating a new RepeatedFieldType. Required by controller-gen.
func (in *RepeatedFieldType) DeepCopyInterface() interface{} {
	return in.DeepCopy()
}
```


## Acknowledgement

protoc-gen-deepcopy was largely inspired by [istio.io/tools/cmd/protoc-gen-deepcopy](https://github.com/istio/tools/tree/master/cmd/protoc-gen-deepcopy).
