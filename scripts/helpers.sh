function download_project() {
  project=$1
  version=$(cat versions/$project)
  echo "Downloading $project at $version"
  mkdir -p projects
  curl --output projects/$project.tar.gz -L "https://github.com/code0-tech/$project/archive/$version.tar.gz" || return 1
  tar -xzf projects/$project.tar.gz -C projects || return 1
  rm projects/$project.tar.gz || return 1
  mv projects/$project-* projects/$project || return 1
}

function docker_login() {
  echo $C0_GH_TOKEN | docker login -u $ --password-stdin ghcr.io
}

function build_image() {
  image=$1
  reticulum_tag=$2

  echo "Building image for $image"

  if [ -x "container/$image/renderDockerfile" ]; then
    echo "Rendering Dockerfile for $image"
    container/$image/renderDockerfile
  fi

  docker build \
    -t "ghcr.io/code0-tech/reticulum/ci-builds/$image:$reticulum_tag" \
    -f "container/$image/Dockerfile" \
    --build-arg RETICULUM_IMAGE_TAG=$reticulum_tag \
    .
}

function push_image() {
  docker push "ghcr.io/code0-tech/reticulum/ci-builds/$image:$reticulum_tag"
}
