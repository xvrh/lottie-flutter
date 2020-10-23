docker run --rm -it -v "${PWD}":/build --workdir /build cirrusci/flutter:1.22.1 sh update_goldens_inside_docker.sh
