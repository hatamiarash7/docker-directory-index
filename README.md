# docker-directory-index

![Github](https://github.com/hatamiarash7/docker-directory-index/workflows/Github/badge.svg?branch=master) ![Dockerhub](https://github.com/hatamiarash7/docker-directory-index/workflows/Dockerhub/badge.svg?branch=master)

This image use Nginx to create a directory index

![image](https://www.keycdn.com/img/support/nginx-directory-index-lg.webp)

## Usage

Map your directory to `/data` directory in container

```bash
docker run -p 80:80 -v /var/log:/data hatamiarash7/directory-index
```
