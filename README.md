# Docker System Prune

Bash script to prune the system by removing:

- All stopped containers.
- All networks not used by at least one container.
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
docker-system-prune.sh -d "DEVICE_NAME" [ -t "USED_PERCENT_THRESHOLD" ]
```

Where:

- `DEVICE_NAME`: A valid block device (e.g.: `/dev/sda1`) where Docker componentes are stored.
- `USED_PERCENT_THRESHOLD`: The used percent threshold to prune the system. It's an optional parameter and its default value is `75`.

To prune the system if the used space is greater or equal than 75% for `/dev/sda1`:

```sh
docker-system-prune.sh -d /dev/sda1
```

## Cron example

```sh
cat <<EOF > /etc/cron.d/docker-system-prune
# Prune the system daily if the used percent is greater or equeal than 75%
0 0 * * * root /usr/local/bin/docker-system-prune.sh -d /dev/sda1
EOF
```

**NOTE:** Remember to set `/dev/sda1` to your current block device name.

## License

MIT

## Author Information

By: [Carlos M Bustillo Rdguez](https://linkedin.com/in/carlosbustillordguez/)
