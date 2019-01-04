# Compile Tensorflow on Docker

Here's a fork that I'm using for my personal TF builds.

Finally, I decided to build TF myself, without relying on 3rd party suppliers of pre-compiled builds.

Python 3.7 & TF 2.0 not supported yet.

## Requirements

- `docker`.
- `docker-compose`.

## Usage

- Clone this repository:

```bash
git clone https://github.com/hadim/docker-tensorflow-builder.git
```

### TensoFlow CPU

- Edit the `build.sh` file as you wish. Here you can modify TensorFlow compilation options.

```bash
cd tensorflow/ubuntu-16.04/
# or
# cd tensorflow/centos-6.6

# Build the Docker image
docker-compose build

# Set env variables
export PYTHON_VERSION=3.6.8
export TF_VERSION_GIT_TAG=v1.12.0
export USE_GPU=0

# Start the compilation
docker-compose run tf

# You can also do:
# docker-compose run tf bash
# bash build.sh
```

### TensorFlow GPU

- Edit the `build.sh` file as you wish. Here you can modify TensorFlow compilation options.

```bash
cd tensorflow/ubuntu-16.04/
# or
# cd tensorflow/centos-6.6

# Build the Docker image
docker-compose build

# Set env variables
export PYTHON_VERSION=3.6.8
export TF_VERSION_GIT_TAG=v1.12.0
export USE_GPU=1
export CUDA_VERSION=9.2
export CUDNN_VERSION=7.1

# Start the compilation
docker-compose run tf

# You can also do:
# docker-compose run tf bash
# bash build.sh
```

---

- Be patient, the compilation can be long.
- Enjoy your Python wheels in the `wheels/` folder.
- *Don't forget to remove the container to free the space after the build: `docker-compose rm --force`.*

## Original Authors

- Hadrien Mary <hadrien.mary@gmail.com>

## License

MIT License. See [LICENSE](LICENSE).
