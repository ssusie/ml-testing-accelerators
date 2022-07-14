// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License,

local imagenet = import 'imagenet.libsonnet';
local mnist = import 'mnist.libsonnet';
local vit = import 'vit.libsonnet';
local wmt = import 'wmt.libsonnet';

// Add new models here
std.flattenArrays([
  imagenet.configs,
  wmt.configs,
  vit.configs,
  mnist.configs,
])
