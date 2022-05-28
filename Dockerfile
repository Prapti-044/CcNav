FROM ghcr.io/autamus/dyninst:11.0.1
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LD_LIBRARY_PATH /opt/view/lib

RUN  apt-get update && apt-get install -y gcc g++ libboost-dev yajl-tools git neovim graphviz libtbb2 libtbb-dev libboost-atomic-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-system-dev libboost-thread-dev libboost-timer-dev curl xz-utils m4 zlib1g zlib1g-dev python3-pip fish build-essential libssl-dev wget openmpi-bin

# Install CMake
RUN mkdir /root/cmake
WORKDIR /root/cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2.tar.gz
RUN tar -zxvf cmake-3.23.2.tar.gz
WORKDIR /root/cmake/cmake-3.23.2
RUN ./bootstrap
RUN make -j8
RUN make install
WORKDIR /root/
RUN rm -rf /root/cmake

# # Install simple-optparser (comment this if optparser is used)
WORKDIR /root/
RUN git clone https://github.com/Prapti-044/simple-optparser.git
WORKDIR /root/simple-optparser
RUN git fetch
RUN python3 setup.py install
WORKDIR /
RUN rm -rf /root/simple-optparser

# Add user for flask app
RUN useradd -ms /bin/bash ccnavuser
USER ccnavuser
WORKDIR /home/ccnavuser


# Clone Rajaperf
WORKDIR /home/ccnavuser
RUN mkdir RAJA-PERFSUITE
WORKDIR /home/ccnavuser/RAJA-PERFSUITE
RUN git clone --recursive https://github.com/llnl/RAJAPerf.git
WORKDIR /home/ccnavuser/RAJA-PERFSUITE/RAJAPerf
RUN git fetch

# Build Rajaperf with debug flags
RUN sed -i 's/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=Debug/g' scripts/ubuntu-builds/ubuntu_gcc.sh
RUN ./scripts/ubuntu-builds/ubuntu_gcc.sh 7
WORKDIR /home/ccnavuser/RAJA-PERFSUITE/RAJAPerf/build_ubuntu-gcc-7/
RUN make -j8
# RUN make test
# Binary is in /home/ccnavuser/RAJA-PERFSUITE/RAJAPerf/build_ubuntu-gcc-7/bin/raja-perf.exe



# Build lulesh
WORKDIR /home/ccnavuser
RUN git clone https://github.com/LLNL/LULESH.git
WORKDIR /home/ccnavuser/LULESH
RUN cmake -DCMAKE_BUILD_TYPE=Debug -DWITH_MPI=FALSE -S . -B build
WORKDIR /home/ccnavuser/LULESH/build
RUN make
# lulesh exe is in /home/ccnavuser/LULESH/build/lulesh2.0

# Copy ccnav
WORKDIR /home/ccnavuser
RUN mkdir CcNav
WORKDIR /home/ccnavuser/CcNav
COPY --chown=ccnavuser . .
RUN echo "var ENV = { isContainer: true };" >> /home/ccnavuser/CcNav/static/js/Environment.js
WORKDIR /home/ccnavuser/CcNav
RUN pip3 install -r requirements.txt
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
EXPOSE 5000

# Install optparser (comment this if simple-opt is used)
# WORKDIR /home/ccnavuser/CcNav/optparser/optparser
# RUN make -f Makefile.container


# create sample a3.out executable for testing purposes.
WORKDIR /home/ccnavuser/CcNav/misc/sample_inputs/a0
RUN gcc -g -o0 hello.c -o /home/ccnavuser/a3.out

# Run flask app as entrypoint
WORKDIR /home/ccnavuser/CcNav
ENTRYPOINT [ "/usr/bin/python3", "-m", "flask", "run"]
