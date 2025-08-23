# cloud-image
Custom cloud image

## Upload helper script

`script/upload_image.sh` uploads the built image to the configured cloud repository and shows a progress bar during the upload. The script requires `CLOUD_REPOSITORY_APIKEY` to be set and accepts the image path and optional destination URL.

## Cleanup

During the build process the temporary `ubuntu` user is deleted so that the first user created by Cloud-Init on a new instance receives the default UID/GID of 1000.
