# docker-directory-index

This image use Nginx to create a directory index

![image](https://www.keycdn.com/img/support/nginx-directory-index-lg.webp)

## Usage

Map your directory to `/data` directory in container

```bash
docker run -p 80:80 -v /var/logs:/data hatamiarash7/directory-index
```
