#!/bin/bash

# Function to fetch all tags from a Git repository
function fetch_tags() {
  local repo_url=$1
  git ls-remote --tags $repo_url | grep refs/tags | awk '{print $2}' | cut -d/ -f3 | sort -V
}

# Fetch all tags for lightwalletd and zcash
LIGHTWALLETD_TAGS=$(fetch_tags https://github.com/zcash/lightwalletd.git)
ZCASH_TAGS=$(fetch_tags https://github.com/zcash/zcash.git)

# Get the latest tags
LATEST_LIGHTWALLETD_TAG=$(echo "$LIGHTWALLETD_TAGS" | tail -1)
LATEST_ZCASH_TAG=$(echo "$ZCASH_TAGS" | tail -1)

# Confirm the latest tags
echo "Latest lightwalletd tag: $LATEST_LIGHTWALLETD_TAG"
read -p "Is this correct? (Y/n) " confirm_lightwalletd

if [[ "$confirm_lightwalletd" == "n" ]]; then
  echo "Available lightwalletd tags:"
  echo "$LIGHTWALLETD_TAGS" | nl
  read -p "Select the desired tag number: " selected_lightwalletd_tag_num
  LATEST_LIGHTWALLETD_TAG=$(echo "$LIGHTWALLETD_TAGS" | sed -n "${selected_lightwalletd_tag_num}p")
fi

echo "Latest zcash tag: $LATEST_ZCASH_TAG"
read -p "Is this correct? (Y/n) " confirm_zcash

if [[ "$confirm_zcash" == "n" ]]; then
  echo "Available zcash tags:"
  echo "$ZCASH_TAGS" | nl
  read -p "Select the desired tag number: " selected_zcash_tag_num
  LATEST_ZCASH_TAG=$(echo "$ZCASH_TAGS" | sed -n "${selected_zcash_tag_num}p")
fi

# Display the selected tags
echo "---------------------------"
echo "Selected tags:"
echo "lightwalletd: $LATEST_LIGHTWALLETD_TAG"
echo "zcash: $LATEST_ZCASH_TAG"
echo "---------------------------"

# Prompt for the new image version number
while true; do
  read -p "Enter the new image version number: " NEW_IMAGE_VERSION
  if [[ -n "$NEW_IMAGE_VERSION" ]]; then
    break
  fi
  echo "Image version number cannot be empty. Please try again."
done

# Confirm before building (with Y as default)
read -p "Proceed with building the image with these settings? (Y/n) " confirm_build
confirm_build=${confirm_build:-Y} # Set default to Y if empty

if [[ "$confirm_build" != "y" && "$confirm_build" != "Y" ]]; then
  echo "Build cancelled."
  exit 1
fi

# Update the Dockerfile with the confirmed tags
sed -i "s/LIGHTWALLETD_TAG=.*/LIGHTWALLETD_TAG=$LATEST_LIGHTWALLETD_TAG/g" docker-ci/Dockerfile
sed -i "s/ZCASH_TAG=.*/ZCASH_TAG=$LATEST_ZCASH_TAG/g" docker-ci/Dockerfile

# Change to the docker-ci directory
cd docker-ci

# Build the Docker image (commented out)
docker build -t zingodevops/ci-build:$NEW_IMAGE_VERSION .
echo "Building Docker image: docker build -t zingodevops/ci-build:$NEW_IMAGE_VERSION ."

# Log in to Docker Hub (commented out)
# docker login
echo "Logging in to Docker Hub: docker login"

# Push the Docker image to Docker Hub (commented out)
docker push zingodevops/ci-build:$NEW_IMAGE_VERSION
echo "Pushing Docker image to Docker Hub: docker push zingodevops/ci-build:$NEW_IMAGE_VERSION"

# Echo dynamic information with links
echo "Docker image updated and pushed to Docker Hub:"
echo "  - Image: zingodevops/ci-build:$NEW_IMAGE_VERSION"
echo "  - Link: https://hub.docker.com/r/zingodevops/ci-build/tags?name=$NEW_IMAGE_VERSION"

# GitHub workflow files update (commented out)
sed -i "s/zingodevops\/ci-build:.*/zingodevops\/ci-build:$NEW_IMAGE_VERSION/g" .github/workflows/*.{yml,yaml}

echo "GitHub workflow files updated:"
echo "  - Repository: https://github.com/zingolabs/zingolib/actions"
