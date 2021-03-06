#!/usr/bin/env bash
set -e


# export TF_VERSION_GIT_TAG=v1.12.0
# export PYTHON_VERSION=3.6.8
# export USE_GPU=0
#
# export TF_VERSION_GIT_TAG=v1.12.0
# export PYTHON_VERSION=3.6.8
# export USE_GPU=1
# export CUDA_VERSION=9.2
# export CUDNN_VERSION=7.1


export PATH="/conda/bin:/usr/bin:$PATH"

if [ "$USE_GPU" -eq "1" ]; then
	bash setup_cuda.sh
fi

gcc --version

# Install an appropriate Python environment
conda create --yes -n tensorflow python==$PYTHON_VERSION
source activate tensorflow

# Bazel 0.18.0 is required due to bugs in TF 1.12.0
conda install --yes six numpy wheel mock bazel==0.18.0
conda install --yes -c conda-forge keras-applications==1.0.6 keras-preprocessing==1.0.5

# Compile TensorFlow

# Here you can change the TensorFlow version you want to build.
# You can also tweak the optimizations and various parameters for the build compilation.
# See https://www.tensorflow.org/install/install_sources for more details.

cd /
rm -fr tensorflow/
git clone --depth 1 --branch $TF_VERSION_GIT_TAG "https://github.com/tensorflow/tensorflow.git"

TF_ROOT=/tensorflow
cd $TF_ROOT

# Python path options
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib

# Compilation parameters
export TF_NEED_CUDA=0
export TF_NEED_GCP=1
export TF_CUDA_COMPUTE_CAPABILITIES=5.2,3.5
export TF_NEED_HDFS=1
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=1  # Need to be disabled on CentOS 6.6
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_CUDA_CLANG=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MKL=0
export TF_DOWNLOAD_MKL=0
export TF_NEED_MPI=0
export TF_NEED_S3=1
export TF_NEED_KAFKA=1
export TF_NEED_GDR=0
export TF_NEED_OPENCL_SYCL=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_AWS=0

# Compiler options
export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC_OPT_FLAGS="-march=native"

if [ "$USE_GPU" -eq "1" ]; then
	# Cuda parameters
	export CUDA_TOOLKIT_PATH=/usr/local/cuda
	export CUDNN_INSTALL_PATH=/usr/local/cuda
	export TF_CUDA_VERSION="$CUDA_VERSION"
	export TF_CUDNN_VERSION="$CUDNN_VERSION"
	export TF_NEED_CUDA=1
	export TF_NEED_TENSORRT=0
	export TF_NCCL_VERSION=1.3

	# Those two lines are important for the linking step.
	export LD_LIBRARY_PATH="$CUDA_TOOLKIT_PATH/lib64:${LD_LIBRARY_PATH}"
	ldconfig
fi

# Compilation
./configure

if [ "$USE_GPU" -eq "1" ]; then

	bazel build --config=opt \
			    --config=mkl \
	    		--config=cuda \
					--copt=-msse2 --copt=-msse3 --copt=-msse4.2 --copt=-msse4.1 --copt=-mavx --copt=-mavx2 --copt=-mfma \
					--copt=-mfpmath=both \
					--define=grpc_no_ares=true \
	    		--action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
	    		//tensorflow/tools/pip_package:build_pip_package

else
  # SSE4.1 SSE4.2 AVX AVX2 FMA – for macbook
	# -march=native enables all the options your CPU supports, so it makes -mavx512f -mavx2 -mavx -mfma -msse4.2 redundant.
	# TODO: --config=nohdfs --config=noignite --config=nokafka --config=nonccl \
	bazel build --config=opt \
	        --config=mkl \
					--copt=-msse2 --copt=-msse3 --copt=-msse4.2 --copt=-msse4.1 --copt=-mavx --copt=-mavx2 --copt=-mfma \
					--copt=-mfpmath=both \
	        --define=grpc_no_ares=true \
			    --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
			    //tensorflow/tools/pip_package:build_pip_package

fi

# Project name can only be set for TF > 1.8
#PROJECT_NAME="tensorflow_gpu_cuda_${TF_CUDA_VERSION}_cudnn_${TF_CUDNN_VERSION}"
#bazel-bin/tensorflow/tools/pip_package/build_pip_package /wheels --project_name $PROJECT_NAME

bazel-bin/tensorflow/tools/pip_package/build_pip_package /wheels

# Fix wheel folder permissions
chmod -R 777 /wheels/
