#!/bin/bash

# Report operating systems in README that have reached end of life.

declare -i eol_count=0
now=$(date +%s)
for eol_date in $(grep EOL: README.md | sed 's,^.*EOL:,,g' | xargs -r -i date -d {} +%s); do
        if [ "$now" -gt "$eol_date" ]; then
                date -d @$eol_date '+%e %b %Y'
                eol_count=eol_count+1
        fi
done

if [ $eol_count != 0 ] ; then
        echo Detected $eol_count end of life in README
        exit $eol_count
fi

# Generate os-release test data files from operating system images

# Copy /etc/os-release from the operating system into a directory
# named for the operating system docker image and the operating system version.
# Once that file is created, this script will detect the existence of the file
# and use the docker image and version from the directory name to insert
# the content of the file.

if [ ! -d alpine ]; then
        cd src/test/resources/org/jvnet/hudson/plugins/platformlabeler || exit 1
fi

args=$@

# Generate os-release files
# Generate redhat-release files for all systems that include the redhat-release file
for Dockerfile in $(find * -type f -name Dockerfile -print); do
        name_version=$(dirname $Dockerfile)
        name=$(dirname $name_version)
        version=$(basename $name_version)
        container=platformlabeler/$name:$version
        echo "Processing Dockerfile $Dockerfile for name $name and version $version"
        (cd $name_version && docker build --pull -t platformlabeler/$name:$version .)

        #
        # Extract os-release file
        #
        echo "=== Generating os-release file"
        docker run --rm -t $container cat /etc/os-release | tr -d '\015' > $name_version/os-release

        #
        # Extract redhat-release file
        #
        docker run --rm -t $container cat /etc/redhat-release | tr -d '\015' > $name_version/redhat-release
        # Remove redhat-release file if it does not exist in the container image
        grep -q -i cat:.*no.such.file $name_version/redhat-release && rm -rf $name_version/redhat-release
        # Remove redhat-release file for Oracle Linux, it contains the wrong vendor name
        if [ "$name" = "oraclelinux" ]; then
                rm -rf $name_version/redhat-release
        fi

        #
        # Collect lsb_release -a output
        #
        if [ "$(grep -c '.*' $Dockerfile)" != "1" ]; then
                docker run -t $container lsb_release -a | tr -d '\015' > $name_version/lsb_release-a
        else
                # Create empty lsb_release-a data file
                : > $name_version/lsb_release-a
        fi
        # Remove lsb_release-a file if it does not exist in the container image
        grep -q -i cat:.*no.such.file $name_version/lsb_release-a && rm -rf $name_version/lsb_release-a
        if [ ! -s $name_version/lsb_release-a ]; then
                # Remove empty lsb_release-a data file
                rm -rf $name_version/lsb_release-a
        fi

done

exit 0
