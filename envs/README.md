# Environments

- `dev`: Development and un-stable testings purposes.
- `stg`: Stagging and stable testings.
- `prd`: Production ready. 


## datalake

In `datalake/scripts/publisher.sh` is contained the script to build and publish the 
`docker/datalake.Dockerfile`.

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

