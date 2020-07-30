# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

local common = import "common.libsonnet";
local mixins = import "templates/mixins.libsonnet";
local timeouts = import "templates/timeouts.libsonnet";
local tpus = import "templates/tpus.libsonnet";
local gpus = import "templates/gpus.libsonnet";

{
  local efficientnet = common.ModelGardenTest {
    modelName: "classifier-efficientnet",
    paramsOverride:: {
      train: {
        epochs: error "Must set `train.epochs`",
      },
      evaluation: {
        epochs_between_evals: error "Must set `evaluation.epochs_between_evals`",
      },
      train_dataset: {
        builder: "records",
      },
      validation_dataset: {
        builder: "records",
      },
    },
    command: [
      "python3",
      "official/vision/image_classification/classifier_trainer.py",
      "--data_dir=$(IMAGENET_DIR)",
      "--model_type=efficientnet",
      "--dataset=imagenet",
      "--mode=train_and_eval",
      "--model_dir=$(MODEL_DIR)",
      "--params_override=%s" % std.manifestYamlDoc(self.paramsOverride) + "\n",
    ],
  },
  local functional = mixins.Functional {
    paramsOverride+: {
      train+: {
        epochs: 1, 
      },
      evaluation+: {
        epochs_between_evals: 1,
      },
    },
  },
  local convergence = mixins.Convergence {
    paramsOverride+: {
      train+: {
        epochs: 350, 
      },
      evaluation+: {
        epochs_between_evals: 10,
      },
    },
    regressionTestConfig+: {
      metric_success_conditions+: {
        "validation/epoch_accuracy_final": {
          success_threshold: {
            fixed_value: 0.76,
          },
          comparison: "greater",
        },
      },
    },
  },
  local gpu_common = {
    local config = self,

    modelName: "efficientnet",
    paramsOverride+:: {
      runtime: {
        num_gpus: config.accelerator.count,
      },
    },
    command+: [
      "--config_file=official/vision/image_classification/configs/examples/efficientnet/imagenet/efficientnet-b0-gpu.yaml",
    ],
  },
  local k80x8 = gpu_common {
    paramsOverride+:: {
      runtime+: {
        all_reduce_alg: "hierarchical_copy",
      },
    },
    accelerator: gpus.teslaK80 + { count: 8 },
  },
  local v100 = gpu_common {
    accelerator: gpus.teslaV100,
  },
  local v100x4 = gpu_common {
    accelerator: gpus.teslaV100 + { count: 4 },
  },

  local tpu_common = {
    command+: [
      "--tpu=$(KUBE_GOOGLE_CLOUD_TPU_ENDPOINTS)",
      "--config_file=official/vision/image_classification/configs/examples/efficientnet/imagenet/efficientnet-b0-tpu.yaml",
    ],
  },
  local v2_8 = tpu_common {
    accelerator: tpus.v2_8,
  },
  local v3_8 = tpu_common {
    accelerator: tpus.v3_8,
  },
  local v2_32 = tpu_common {
    accelerator: tpus.v2_32,
  },
  local v3_32 = tpu_common {
    accelerator: tpus.v3_32,
  },

  configs: [
    efficientnet + k80x8 + functional + timeouts.Hours(4) + mixins.Suspended,
    efficientnet + k80x8 + convergence + mixins.Experimental,
    efficientnet + v100 + functional + timeouts.Hours(8) + mixins.Suspended,
    efficientnet + v100x4 + functional + timeouts.Hours(2) + mixins.Suspended,
    efficientnet + v100x4 + convergence + mixins.Experimental,
    efficientnet + v2_8 + functional,
    efficientnet + v3_8 + functional,
    efficientnet + v2_8 + convergence + timeouts.Hours(45),
    efficientnet + v3_8 + convergence + timeouts.Hours(45),
    efficientnet + v2_32 + functional,
    efficientnet + v3_32 + functional,
    efficientnet + v2_32 + convergence + timeouts.Hours(30),
    efficientnet + v3_32 + convergence + timeouts.Hours(24),
  ],
}
