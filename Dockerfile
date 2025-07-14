# Use Ubuntu 24.04 as base image
FROM ubuntu:24.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install dependencies
RUN apt update && apt install -y \
    build-essential \
    cmake \
    git \
    g++-14 \
    gfortran \
    libopenmpi-dev \
    openmpi-bin \
    curl \
    && rm -rf /var/lib/apt/lists/*

# # Installing starship: https://starship.rs/guide/
RUN cd /tmp && curl -sS https://starship.rs/install.sh > install_starship.sh  &&  sh install_starship.sh --yes

# Configura usuario para seguridad
RUN useradd -m -s /bin/bash developer
USER developer
WORKDIR /home/developer

# Activar el starship para el usuario developer
RUN echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Clona nekRS directamente en ~/.local/nekRS
RUN git clone https://github.com/Nek5000/nekRS.git .local/nekRS

# Aplica el parche para polyfill.hpp
WORKDIR /home/developer/.local/nekRS
RUN sed -i '1s;^;#include <cstdint>\n;' 3rd_party/occa/src/occa/internal/modes/dpcpp/polyfill.hpp

# Compilar e instalar nekRS
RUN yes "" | CC=mpicc CXX=mpic++ FC=mpif77 ./nrsconfig -DCMAKE_INSTALL_PREFIX=$HOME/.local/nekrs
RUN cmake --build build --target install -j$(nproc)

# Configura variables de entorno (persistentes)
ENV NEKRS_HOME=/home/developer/.local/nekrs
ENV PATH=$NEKRS_HOME/bin:$PATH

WORKDIR /workspace
# Comando por defecto
CMD ["/bin/bash"]
