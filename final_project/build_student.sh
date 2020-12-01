#!/bin/bash
echo "Building mxnet with modified new-forward.cuh"
module load gcc/4.8.5
module load openblas/0.3.5
module load cudnn/9.2-v7.6.5
module load cuda/9.2.148
cp -fv new-forward.cuh incubator-mxnet/src/operator/custom
make -C incubator-mxnet USE_CUDA=1 USE_CUDA_PATH=/sw/arcts/centos7/cuda/9.2.148 USE_CUDNN=1 USE_BLAS=openblas && pip install --user -e incubator-mxnet/python
echo "Finished building mxnet"
