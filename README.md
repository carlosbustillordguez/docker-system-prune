# Docker System Prune

Bash script to prune the system by removing:

- All stopped containers.
- All networks not used by at least one container.
- All volumes not used by at least one container (by setting the `-v | --volumes` script argument).
- All images without at least one container associated to them.
- All build cache.

## Instructions

Copy the script to `/usr/local/bin/docker-system-prune.sh`. Then, add execution permisions:

```sh
sudo cp docker-system-prune.sh /usr/local/bin/docker-system-prune.sh && \
sudo chmod +x /usr/local/bin/docker-system-prune.sh
```

## Usage

```sh
docker-system-prune.sh -d "DEVICE_NAME" [ -t "USED_PERCENT_THRESHOLD" ] [ -v ]
```

Where:

- `-d DEVICE_NAME`: Define a valid block device (e.g.: `/dev/sda1`) where Docker componentes are stored.
- `-t USED_PERCENT_THRESHOLD`: Set the used percent threshold to prune the system. It's an optional parameter and its default value is `75`.
- `-v`: Whether to prune or not all volumes not used by at least one container. It's an optional parameter, the default behavior is to keep the volumes.

To prune the system if the used space is greater or equal than 75% for `/dev/sda1`:

```sh
docker-system-prune.sh -d /dev/sda1
```

To remove all volumes not used by at least one container:

```sh
docker-system-prune.sh -d /dev/sda1 -v
```

## Cron example

```sh
cat <<EOF > /etc/cron.d/docker-system-prune
# Prune the system daily if the used percent is greater or equal than 75%
0 0 * * * root /usr/local/bin/docker-system-prune.sh -d /dev/sda1 >/dev/null 2>&1
EOF
```

**NOTE:** Remember to set `/dev/sda1` to your current block device name.

## License

MIT

## Author Information

By: [Carlos M Bustillo Rdguez](https://linkedin.com/in/carlosbustillordguez/)
