// Copyright 2022 Google LLC
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
// limitations under the License.

local experimental = import '../experimental.libsonnet';
local common = import 'common.libsonnet';
local mixins = import 'templates/mixins.libsonnet';
local timeouts = import 'templates/timeouts.libsonnet';
local tpus = import 'templates/tpus.libsonnet';
local utils = import 'templates/utils.libsonnet';

{
  local coco = self.coco,
  coco:: {
    scriptConfig+: {
      trainFilePattern: '$(COCO_DIR)/train*',
      evalFilePattern: '$(COCO_DIR)/val*',
      paramsOverride+: {
        task+: {
          annotation_file: '$(COCO_DIR)/instances_val2017.json',
        },
      },
    },
  },
  local tpu_common = self.tpu_common,
  tpu_common:: {
    local config = self,
    scriptConfig+: {
      paramsOverride+: {
        task+: {
          validation_data+: {
            global_batch_size: 8 * config.accelerator.replicas,
          },
        },
      },
    },
  },
  local retinanet = self.retinanet,
  retinanet:: common.TfVisionTest + coco {
    modelName: 'vision-retinanet',
    scriptConfig+: {
      experiment: 'retinanet_resnetfpn_coco',
    },
  },
  local maskrcnn = self.maskrcnn,
  maskrcnn:: common.TfVisionTest + coco {
    modelName: 'vision-maskrcnn',
    scriptConfig+: {
      experiment: 'maskrcnn_resnetfpn_coco',
    },
  },
  local functional = self.functional,
  functional:: common.Functional {
    scriptConfig+: {
      paramsOverride+: {
        trainer+: {
          train_steps: 400,
          validation_interval: 200,
          validation_steps: 100,
        },
      },
    },
  },
  local convergence = self.convergence,
  convergence:: common.Convergence,
  local v2_8 = self.v2_8,
  v2_8:: {
    accelerator: tpus.v2_8,
    scriptConfig+: {
      paramsOverride+: {
        task+: {
          train_data+: {
            global_batch_size: 64,
          },
        },
      },
    },
  },
  local v3_8 = self.v3_8,
  v3_8:: tpu_common {
    accelerator: tpus.v3_8,
  },
  local v2_32 = self.v2_32,
  v2_32:: tpu_common {
    accelerator: tpus.v2_32,
  },
  local v3_32 = self.v3_32,
  v3_32:: tpu_common {
    accelerator: tpus.v3_32,
  },
  local v4_8 = self.v4_8,
  v4_8:: tpu_common {
    accelerator: tpus.v4_8,
  },
  local v4_32 = self.v4_32,
  v4_32:: tpu_common {
    accelerator: tpus.v4_32,
  },
  local tpuVm = self.tpuVm,
  tpuVm:: experimental.TensorFlowTpuVmMixin,

  local functionalTests = [
    benchmark + accelerator + functional
    for benchmark in [retinanet, maskrcnn]
    for accelerator in [v2_8, v3_8]
  ],
  local convergenceTests = [
    retinanet + v2_32 + convergence + timeouts.Hours(15),
    retinanet + v3_32 + convergence + timeouts.Hours(15),
    maskrcnn + v2_32 + convergence + timeouts.Hours(15),
    maskrcnn + v3_32 + convergence + timeouts.Hours(15),
  ],
  configs: functionalTests + convergenceTests + [
    retinanet + v4_8 + functional + tpuVm,
    retinanet + v4_32 + convergence + tpuVm,
    maskrcnn + v4_8 + functional + tpuVm,
    maskrcnn + v4_32 + convergence + tpuVm,
  ],
}
