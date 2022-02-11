FROM ghcr.io/autamus/dyninst:11.0.1
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN  apt-get update && apt-get install -y gcc g++ cmake libboost-dev yajl-tools git vim graphviz libtbb2 libtbb-dev libboost-atomic-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-system-dev libboost-thread-dev libboost-timer-dev curl xz-utils m4 zlib1g zlib1g-dev python3-pip sudo

RUN useradd -ms /bin/bash ccnavuser
USER ccnavuser
WORKDIR /home/ccnavuser

RUN mkdir CcNav
WORKDIR /home/ccnavuser/CcNav
COPY --chown=ccnavuser . .

RUN echo "var ENV = { isContainer: true };" >> /home/ccnavuser/CcNav/static/js/Environment.js

WORKDIR /home/ccnavuser/CcNav/optparser/optparser
RUN make -f Makefile.container

WORKDIR /home/ccnavuser/CcNav
RUN pip3 install -r requirements.txt
ENV FLASK_APP=app.py
EXPOSE 5000

ENTRYPOINT [ "/usr/bin/python3", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000"]
