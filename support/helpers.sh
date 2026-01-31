function download_project() {
  project=$1
  version=$(get_component_version $project)
  echo "Downloading $project at $version"
  mkdir -p projects
  curl --output projects/$project.tar.gz --fail-with-body -L "https://github.com/code0-tech/$project/archive/$version.tar.gz" || return 10
  tar -xzf projects/$project.tar.gz -C projects || return 10
  rm projects/$project.tar.gz || return 1
  mv projects/$project-* projects/$project || return 1
}

function docker_login() {
  echo $C0_GH_TOKEN | docker login -u $ --password-stdin ghcr.io
}

function docker_setup_builder() {
  docker context create build-context
  docker buildx create \
    --name container-builder \
    --driver docker-container \
    --bootstrap \
    --use \
    build-context
}

function build_image() {
  image=$1
  reticulum_tag=$2
  build_args=$3
  reticulum_push_tag=${4-":$reticulum_tag"}

  echo "Building image for $image"

  if [ -x "container/$image/renderDockerfile" ]; then
    echo "Rendering Dockerfile for $image"
    container/$image/renderDockerfile
  fi

  build_args+=" --label org.opencontainers.image.source=https://github.com/code0-tech/reticulum"

  if [[ -n "$(get_component_version $image)" ]]; then
    build_args+=" --label org.opencontainers.image.version=$(get_component_version $image)"
  fi

  docker buildx build \
    -t "ghcr.io/code0-tech/reticulum/ci-builds/$image$reticulum_push_tag" \
    -f "container/$image/Dockerfile" \
    --build-arg RETICULUM_IMAGE_TAG=$reticulum_tag \
    $build_args \
    .
}

function extract_version_from_image() {
  image=$1
  config_sha=$(sed -n 's/.*exporting config \(sha256:[a-f0-9]*\).*done/\1/p' build_output || echo "")
  echo $config_sha >&2
  docker buildx imagetools inspect \
    "ghcr.io/code0-tech/reticulum/ci-builds/$image@$config_sha" \
    --raw \
    | jq -r '.config.Labels["org.opencontainers.image.version"] // ""'
}

function create_manifest() {
  image=$1
  reticulum_tag=$2

  args=(-t "ghcr.io/code0-tech/reticulum/ci-builds/$image:$reticulum_tag")
  args+=(--annotation "index:org.opencontainers.image.source=https://github.com/code0-tech/reticulum")

  if [[ -n "$(cat version_label)" ]]; then
    args+=(--annotation "index:org.opencontainers.image.version=$(cat version_label)")
  fi

  for manifest in manifest-*.json; do
      args+=("$(jq -r '."image.name"' $manifest)@$(jq -r '."containerimage.digest"' $manifest)")
  done

  docker buildx imagetools create "${args[@]}"
}

function get_image_tag() {
  reticulum_tag=$1
  reticulum_variant=$2
  if [ -z "$reticulum_variant" ]; then
    echo $reticulum_tag
  else
    echo $reticulum_tag-$reticulum_variant
  fi
}

function get_component_version() {
  component=$1
  override_variable="OVERRIDE_${component}_VERSION"

  if [[ -n "${!override_variable:+x}" ]]; then
    echo ${!override_variable}
  elif [[ -e "versions/$component" ]]; then
    cat versions/$component
  else
    echo ""
  fi
}
