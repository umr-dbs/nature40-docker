# Dockerfile for the Nature 4.0 VAT Instance

## build
`docker image build --build-arg MAPPING_CORE_TAG=master --build-arg MAPPING_NATURE40_TAG=master --build-arg MAPPING_R_TAG=master --build-arg WAVE_TAG=master -t vat-nature40:0.1 .`

## run
Example command that uses 10 threads for mapping and mounts the gdal:

`docker container run --detach --name vat-nature40 --publish 7777:80 --env MAPPING_fcgi={threads=10} -v /host/path:/app/data/gdal  vat-nature40:0.1`

## Mountable volumes
| Volume | Description |
|---------------------|-------------|
| /app/data/gdal      | Folder for gdal data set descriptions as JSON files           |
| /app/data/ogr       | Folder for ogr data set descriptions as JSON files            |
| /app/data/userdb    | Folder where the userdb.sqlite is stored                      |

## Specify number of threads
`--env MAPPING_fcgi={threads=10}`

## Add data set
* run docker with mounted volumes
    * ``docker container run --detach --name vat-nature40 --publish 7777:80 -v `pwd`/gdal:/app/data/gdal -v `pwd`/userdb:/app/data/userdb vat-nature40:0.1``
* copy data description to volume
    * data has to be accessible by docker and specified as `path` in JSON
* add permission:
    * `sqlite3 -line userdb/userdb.sqlite 'INSERT INTO group_permissions VALUES (1, "data.gdal_source.example")'`
        * `1` corresponds to the group `users`, which contains all users
        * `example`corresponds to `example.json`
        