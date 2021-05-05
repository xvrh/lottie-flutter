docker run --rm -it -v "${PWD}":/build --workdir /build cirrusci/flutter:2.0.6 sh update_goldens_inside_docker.sh
