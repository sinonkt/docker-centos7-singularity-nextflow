# docker-centos7-singularity-nextflow

Frontend like Environment while developing Nextflow script and run as local executor.
### How to use
`dev` is main user while developing, 
- mount data volume to `/home/dev/data`. (imitate `gpfs mount point`)
- mount code volume to `/home/dev/code`.
spawn container
```
IMAGE=sinonkt/docker-centos7-singularity-nextflow
docker run --privileged \ 
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v /path/to/your/data:/home/dev/data \
  -v /path/to/your/code:/home/dev/code \
  -p 22222:22 \
  -d $IMAGE
```
- save private key `.ssh/dev` to local machine (for passwordless ssh)
- add private key `ssh-add .ssh/dev`
- `ssh dev@localhost -p 22222` (you can also directly spawn bash via `docker exec`)


### What's Included
- openssh-server
- Singularity 3.0
- Nextflow 18.0
- AWS client
