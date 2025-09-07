# Environments

- `dev`: Development and un-stable testings purposes.
- `stg`: Stagging and stable testings.
- `prd`: Production ready. 


## dataplatform

In `dataplatform/scripts/publisher.sh` is contained the script to build and publish the 
`docker/dataplatform.Dockerfile`.

```shell
export DOCKER_USERNAME="dockerhub-username"
export DOCKER_REPO="repo-in-dockerhub"
export DOCKER_PASSWORD="personal-access-token"
export IMAGE_NAME="image-name"
export IMAGE_TAG="beta"
export BUILD_CONTEXT="."
```

This is the final route of the pushed image: `DOCKER_REPO/IMAGE_NAME:IMAGE_TAG`. Next
run the following command: 

```shell
./publisher.sh
```

## AMI 

Look for images available in the `us-east-1` region, free AMI, compatible with free-tier EC2 in a t4g.small instance, with ubuntu and ARM64. 

```shell
aws ec2 describe-images 
    --region us-east-1 \ 
    --filters \
        "Name=free-tier-eligible,Values=true" \
        "Name=architecture,Values=arm64" \
    --query 'sort_by(Images, &CreationDate)[].{Name: Name, ImageId: ImageId, CreationDate: CreationDate, Architecture: Architecture}' \
    --output table
```

Options: 
    ami-0b866f42728654749 - ubuntu 2204
    ami-082089782931bef58 - ubuntu-2204-standard-arm64-1694819299

