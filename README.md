# Redis&trade; packaged by Bitnami

## What is Redis&trade;?

> Redis&trade; is an open source, advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets.

[Overview of Redis&trade;](http://redis.io)

This project has been forked from [bitnami-docker-redis](https://github.com/bitnami/bitnami-docker-redis),  We mainly modified the dockerfile in order to build the images of amd64 and arm64 architectures. 

Disclaimer: Redis is a registered trademark of Redis Labs Ltd. Any rights therein are reserved to Redis Labs Ltd. Any use by Bitnami is for referential purposes only and does not indicate any sponsorship, endorsement, or affiliation between Redis Labs Ltd.

## TL;DR

```console
$ docker run --name redis -e ALLOW_EMPTY_PASSWORD=yes quay.io/drycc-addons/redis:6.2
```

### Docker Compose

```console
$ curl -sSL https://raw.githubusercontent.com/drycc-addons/drycc-docker-redis/main/docker-compose.yml > docker-compose.yml
$ docker-compose up -d
```

**Warning**: These quick setups are only intended for development environments. You are encouraged to change the insecure default credentials and check out the available configuration options in the [Configuration](#configuration) section for a more secure deployment.

## Get this image

The recommended way to get the Bitnami Redis(TM) Docker Image is to pull the prebuilt image from the [Container Image Registry](https://quay.io/repository/drycc-addons/redis).

```console
$ docker pull quay.io/drycc-addons/redis:6.2
```

To use a specific version, you can pull a versioned tag. You can view the [list of available versions](https://quay.io/repository/drycc-addons/redis?tab=tags) in the Container Image Registry.

```console
$ docker pull quay.io/drycc-addons/redis:[TAG]
```

If you wish, you can also build the image yourself.

```console
$ docker build -t quay.io/drycc-addons/redis:6.2 'https://github.com/drycc-addons/drycc-docker-redis.git#main:6.2/debian-10'
```

## Persisting your database

Redis(TM) provides a different range of [persistence options](https://redis.io/topics/persistence). This contanier uses *AOF persistence by default* but it is easy to overwrite that configuration in a `docker-compose.yaml` file with this entry `command: /opt/drycc/scripts/redis/run.sh --appendonly no`. Alternatively, you may use the `REDIS_AOF_ENABLED` env variable as explained in [Disabling AOF persistence](https://github.com/drycc-addons/drycc-docker-redis#disabling-aof-persistence).

If you remove the container all your data will be lost, and the next time you run the image the database will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should mount a directory at the `/drycc` path. If the mounted directory is empty, it will be initialized on the first run.

```console
$ docker run \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /path/to/redis-persistence:/drycc/redis/data \
    quay.io/drycc-addons/redis:6.2
```

You can also do this by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    volumes:
      - /path/to/redis-persistence:/drycc/redis/data
  ...
```

> NOTE: As this is a non-root container, the mounted files and directories must have the proper permissions for the UID `1001`.

## Connecting to other containers

Using [Docker container networking](https://docs.docker.com/engine/userguide/networking/), a Redis(TM) server running inside a container can easily be accessed by your application containers.

Containers attached to the same network can communicate with each other using the container name as the hostname.

### Using the Command Line

In this example, we will create a Redis(TM) client instance that will connect to the server instance that is running on the same docker network as the client.

#### Step 1: Create a network

```console
$ docker network create app-tier --driver bridge
```

#### Step 2: Launch the Redis(TM) server instance

Use the `--network app-tier` argument to the `docker run` command to attach the Redis(TM) container to the `app-tier` network.

```console
$ docker run -d --name redis-server \
    -e ALLOW_EMPTY_PASSWORD=yes \
    --network app-tier \
    quay.io/drycc-addons/redis:6.2
```

#### Step 3: Launch your Redis(TM) client instance

Finally we create a new container instance to launch the Redis(TM) client and connect to the server created in the previous step:

```console
$ docker run -it --rm \
    --network app-tier \
    quay.io/drycc-addons/redis:6.2 redis-cli -h redis-server
```

### Using Docker Compose

When not specified, Docker Compose automatically sets up a new network and attaches all deployed services to that network. However, we will explicitly define a new `bridge` network named `app-tier`. In this example we assume that you want to connect to the Redis(TM) server from your own custom application image which is identified in the following snippet by the service name `myapp`.

```yaml
version: '2'

networks:
  app-tier:
    driver: bridge

services:
  redis:
    image: 'quay.io/drycc-addons/redis:6.2'
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    networks:
      - app-tier
  myapp:
    image: 'YOUR_APPLICATION_IMAGE'
    networks:
      - app-tier
```

> **IMPORTANT**:
>
> 1. Please update the **YOUR_APPLICATION_IMAGE_** placeholder in the above snippet with your application image
> 2. In your application container, use the hostname `redis` to connect to the Redis(TM) server

Launch the containers using:

```console
$ docker-compose up -d
```

## Configuration

### Disabling Redis(TM) commands

For security reasons, you may want to disable some commands. You can specify them by using the following environment variable on the first run:

- `REDIS_DISABLE_COMMANDS`: Comma-separated list of Redis(TM) commands to disable. Defaults to empty.

```console
$ docker run --name redis -e REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL,CONFIG quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL,CONFIG
  ...
```

As specified in the docker-compose, `FLUSHDB` and `FLUSHALL` commands are disabled. Comment out or remove the
environment variable if you don't want to disable any commands:

```yaml
services:
  redis:
  ...
    environment:
      # - REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL
  ...
```

### Passing extra command-line flags to redis-server startup

Passing extra command-line flags to the redis service command is possible by adding them as arguments to *run.sh* script:

```console
$ docker run --name redis -e ALLOW_EMPTY_PASSWORD=yes quay.io/drycc-addons/redis:6.2 /opt/drycc/scripts/redis/run.sh --maxmemory 100mb
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    command: /opt/drycc/scripts/redis/run.sh --maxmemory 100mb
  ...
```

Refer to the [Redis(TM) documentation](https://redis.io/topics/config#passing-arguments-via-the-command-line) for the complete list of arguments.

### Setting the server password on first run

Passing the `REDIS_PASSWORD` environment variable when running the image for the first time will set the Redis(TM) server password to the value of `REDIS_PASSWORD` (or the content of the file specified in `REDIS_PASSWORD_FILE`).

```console
$ docker run --name redis -e REDIS_PASSWORD=password123 quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_PASSWORD=password123
  ...
```

**NOTE**: The at sign (`@`) is not supported for `REDIS_PASSWORD`.

**Warning** The Redis(TM) database is always configured with remote access enabled. It's suggested that the `REDIS_PASSWORD` env variable is always specified to set a password. In case you want to access the database without a password set the environment variable `ALLOW_EMPTY_PASSWORD=yes`. **This is recommended only for development**.

### Allowing empty passwords

By default the Redis(TM) image expects all the available passwords to be set. In order to allow empty passwords, it is necessary to set the `ALLOW_EMPTY_PASSWORD=yes` env variable. This env variable is only recommended for testing or development purposes. We strongly recommend specifying the `REDIS_PASSWORD` for any other scenario.

```console
$ docker run --name redis -e ALLOW_EMPTY_PASSWORD=yes quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
  ...
```

### Disabling AOF persistence

Redis(TM) offers different [options](https://redis.io/topics/persistence) when it comes to persistence. By default, this image is set up to use the AOF (Append Only File) approach. Should you need to change this behaviour, setting the `REDIS_AOF_ENABLED=no` env variable will disable this feature.

```console
$ docker run --name redis -e REDIS_AOF_ENABLED=no quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_AOF_ENABLED=no
  ...
```

### Enabling Access Control List

Redis(TM) offers [ACL](https://redis.io/topics/acl) since 6.0 which allows certain connections to be limited in terms of the commands that can be executed and the keys that can be accessed. We strongly recommend enabling ACL in production by specifiying the `REDIS_ACLFILE`.

```console
$ docker run -name redis -e REDIS_ACLFILE=/opt/drycc/redis/mounted-etc/users.acl -v /path/to/users.acl:/opt/drycc/redis/mounted-etc/users.acl quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_ACLFILE=/opt/drycc/redis/mounted-etc/users.acl
    volumes:
      - /path/to/users.acl:/opt/drycc/redis/mounted-etc/users.acl
  ...
```

### Setting up a standalone instance

By default, this image is set up to launch Redis(TM) in standalone mode on port 6379. Should you need to change this behavior, setting the `REDIS_PORT_NUMBER` environment variable will modify the port number. This is not to be confused with `REDIS_MASTER_PORT_NUMBER` or `REDIS_REPLICA_PORT` environment variables that are applicable in replication mode.

```console
$ docker run --name redis -e REDIS_PORT_NUMBER=7000 -p 7000:7000 quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_PORT_NUMBER=7000
    ...
    ports:
      - '7000:7000'
  ....
```

### Setting up replication

A [replication](http://redis.io/topics/replication) cluster can easily be setup with the Bitnami Redis(TM) Docker Image using the following environment variables:

 - `REDIS_REPLICATION_MODE`: The replication mode. Possible values `master`/`slave`. No defaults.
 - `REDIS_REPLICA_IP`: The replication announce ip. Defaults to `$(get_machine_ip)` which return the ip of the container.
 - `REDIS_REPLICA_PORT`: The replication announce port. Defaults to `REDIS_MASTER_PORT_NUMBER`.
 - `REDIS_MASTER_HOST`: Hostname/IP of replication master (replica node parameter). No defaults.
 - `REDIS_MASTER_PORT_NUMBER`: Server port of the replication master (replica node parameter). Defaults to `6379`.
 - `REDIS_MASTER_PASSWORD`: Password to authenticate with the master (replica node parameter). No defaults. As an alternative, you can mount a file with the password and set the `REDIS_MASTER_PASSWORD_FILE` variable.

In a replication cluster you can have one master and zero or more replicas. When replication is enabled the master node is in read-write mode, while the replicas are in read-only mode. For best performance its advisable to limit the reads to the replicas.

#### Step 1: Create the replication master

The first step is to start the Redis(TM) master.

```console
$ docker run --name redis-master \
  -e REDIS_REPLICATION_MODE=master \
  -e REDIS_PASSWORD=masterpassword123 \
  quay.io/drycc-addons/redis:6.2
```

In the above command the container is configured as the `master` using the `REDIS_REPLICATION_MODE` parameter. The `REDIS_PASSWORD` parameter enables authentication on the Redis(TM) master.

#### Step 2: Create the replica node

Next we start a Redis(TM) replica container.

```console
$ docker run --name redis-replica \
  --link redis-master:master \
  -e REDIS_REPLICATION_MODE=slave \
  -e REDIS_MASTER_HOST=master \
  -e REDIS_MASTER_PORT_NUMBER=6379 \
  -e REDIS_MASTER_PASSWORD=masterpassword123 \
  -e REDIS_PASSWORD=password123 \
  quay.io/drycc-addons/redis:6.2
```

In the above command the container is configured as a `slave` using the `REDIS_REPLICATION_MODE` parameter. The `REDIS_MASTER_HOST`, `REDIS_MASTER_PORT_NUMBER` and `REDIS_MASTER_PASSWORD ` parameters are used connect and authenticate with the Redis(TM) master. The `REDIS_PASSWORD` parameter enables authentication on the Redis(TM) replica.

You now have a two node Redis(TM) master/replica replication cluster up and running which can be scaled by adding/removing replicas.

If the Redis(TM) master goes down you can reconfigure a replica to become a master using:

```console
$ docker exec redis-replica redis-cli -a password123 SLAVEOF NO ONE
```

> **Note**: The configuration of the other replicas in the cluster needs to be updated so that they are aware of the new master. In our example, this would involve restarting the other replicas with `--link redis-replica:master`.

With Docker Compose the master/replica mode can be setup using:

```yaml
version: '2'

services:
  redis-master:
    image: 'quay.io/drycc-addons/redis:6.2'
    ports:
      - '6379'
    environment:
      - REDIS_REPLICATION_MODE=master
      - REDIS_PASSWORD=my_master_password
    volumes:
      - '/path/to/redis-persistence:/drycc'

  redis-replica:
    image: 'quay.io/drycc-addons/redis:6.2'
    ports:
      - '6379'
    depends_on:
      - redis-master
    environment:
      - REDIS_REPLICATION_MODE=slave
      - REDIS_MASTER_HOST=redis-master
      - REDIS_MASTER_PORT_NUMBER=6379
      - REDIS_MASTER_PASSWORD=my_master_password
      - REDIS_PASSWORD=my_replica_password
```

Scale the number of replicas using:

```console
$ docker-compose up --detach --scale redis-master=1 --scale redis-secondary=3
```

The above command scales up the number of replicas to `3`. You can scale down in the same way.

> **Note**: You should not scale up/down the number of master nodes. Always have only one master node running.

### Securing Redis(TM) traffic

Starting with version 6, Redis(TM) adds the support for SSL/TLS connections. Should you desire to enable this optional feature, you may use the following environment variables to configure the application:

 - `REDIS_TLS_ENABLED`: Whether to enable TLS for traffic or not. Defaults to `no`.
 - `REDIS_TLS_PORT`: Port used for TLS secure traffic. Defaults to `6379`.
 - `REDIS_TLS_CERT_FILE`: File containing the certificate file for the TSL traffic. No defaults.
 - `REDIS_TLS_KEY_FILE`: File containing the key for certificate. No defaults.
 - `REDIS_TLS_CA_FILE`: File containing the CA of the certificate. No defaults.
 - `REDIS_TLS_DH_PARAMS_FILE`: File containing DH params (in order to support DH based ciphers). No defaults.
 - `REDIS_TLS_AUTH_CLIENTS`: Whether to require clients to authenticate or not. Defaults to `yes`.

When enabling TLS, conventional standard traffic is disabled by default. However this new feature is not mutually exclusive, which means it is possible to listen to both TLS and non-TLS connection simultaneously. To enable non-TLS traffic, set `REDIS_TLS_PORT` to another port different than `0`.

1. Using `docker run`

    ```console
    $ docker run --name redis \
        -v /path/to/certs:/opt/drycc/redis/certs \
        -v /path/to/redis-data-persistence:/drycc/redis/data \
        -e ALLOW_EMPTY_PASSWORD=yes \
        -e REDIS_TLS_ENABLED=yes \
        -e REDIS_TLS_CERT_FILE=/opt/drycc/redis/certs/redis.crt \
        -e REDIS_TLS_KEY_FILE=/opt/drycc/redis/certs/redis.key \
        -e REDIS_TLS_CA_FILE=/opt/drycc/redis/certs/redisCA.crt \
        quay.io/drycc-addons/redis:6.2
    ```

2. Modifying the `docker-compose.yml` file present in this repository:

    ```yaml
    services:
      redis:
      ...
        environment:
          ...
          - REDIS_TLS_ENABLED=yes
          - REDIS_TLS_CERT_FILE=/opt/drycc/redis/certs/redis.crt
          - REDIS_TLS_KEY_FILE=/opt/drycc/redis/certs/redis.key
          - REDIS_TLS_CA_FILE=/opt/drycc/redis/certs/redisCA.crt
        ...
        volumes:
          - /path/to/certs:/opt/drycc/redis/certs
          - /path/to/redis-persistence:/drycc/redis/data
      ...
    ```

Alternatively, you may also provide with this configuration in your [custom](https://github.com/drycc-addons/drycc-docker-redis#configuration-file) configuration file.

### Configuration file

The image looks for configurations in `/opt/drycc/redis/mounted-etc/redis.conf`. You can overwrite the `redis.conf` file using your own custom configuration file.

```console
$ docker run --name redis \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /path/to/your_redis.conf:/opt/drycc/redis/mounted-etc/redis.conf \
    -v /path/to/redis-data-persistence:/drycc/redis/data \
    quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    volumes:
      - /path/to/your_redis.conf:/opt/drycc/redis/mounted-etc/redis.conf
      - /path/to/redis-persistence:/drycc/redis/data
  ...
```

Refer to the [Redis(TM) configuration](http://redis.io/topics/config) manual for the complete list of configuration options.

### Overriding configuration

Instead of providing a custom `redis.conf`, you may also choose to provide only settings you wish to override. The image will look for `/opt/drycc/redis/mounted-etc/overrides.conf`. This will be ignored if custom `redis.conf` is provided.

```console
$ docker run --name redis \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /path/to/overrides.conf:/opt/drycc/redis/mounted-etc/overrides.conf \
    quay.io/drycc-addons/redis:6.2
```

Alternatively, modify the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-redis/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  redis:
  ...
    volumes:
      - /path/to/overrides.conf:/opt/drycc/redis/mounted-etc/overrides.conf
  ...
```


## Logging

The Bitnami Redis(TM) Docker image sends the container logs to the `stdout`. To view the logs:

```console
$ docker logs redis
```

or using Docker Compose:

```console
$ docker-compose logs redis
```

You can configure the containers [logging driver](https://docs.docker.com/engine/admin/logging/overview/) using the `--log-driver` option if you wish to consume the container logs differently. In the default configuration docker uses the `json-file` driver.

## Maintenance

### Upgrade this image

Bitnami provides up-to-date versions of Redis(TM), including security patches, soon after they are made upstream. We recommend that you follow these steps to upgrade your container.

#### Step 1: Get the updated image

```console
$ docker pull quay.io/drycc-addons/redis:6.2
```

or if you're using Docker Compose, update the value of the image property to
`quay.io/drycc-addons/redis:6.2`.

#### Step 2: Stop and backup the currently running container

Stop the currently running container using the command

```console
$ docker stop redis
```

or using Docker Compose:

```console
$ docker-compose stop redis
```

Next, take a snapshot of the persistent volume `/path/to/redis-persistence` using:

```console
$ rsync -a /path/to/redis-persistence /path/to/redis-persistence.bkp.$(date +%Y%m%d-%H.%M.%S)
```

#### Step 3: Remove the currently running container

```console
$ docker rm -v redis
```

or using Docker Compose:

```console
$ docker-compose rm -v redis
```

#### Step 4: Run the new image

Re-create your container from the new image.

```console
$ docker run --name redis quay.io/drycc-addons/redis:6.2
```

or using Docker Compose:

```console
$ docker-compose up redis
```

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/drycc/drycc-docker-redis/issues), or submit a [pull request](https://github.com/drycc/drycc-docker-redis/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can file an [issue](https://github.com/drycc-addons/drycc-docker-redis/issues/new). For us to provide better support, be sure to include the following information in your issue:

- Host OS and version
- Docker version (`docker version`)
- Output of `docker info`
- Version of this container
- The command you used to run the container, and any relevant output you saw (masking any sensitive information)
