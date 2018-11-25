FROM jupyter/pyspark-notebook:e8613d84128b

ENV CLOJURE_VERSION 1.9.0.394
ENV LEIN_VERSION 2.8.1
ENV LEIN_INSTALL=/usr/local/bin/

USER root
WORKDIR /tmp

# install some extra packages
RUN apt-get -qy update && apt-get install -qy curl gpg less rlwrap && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# from https://github.com/Quantisan/docker-clojure
RUN mkdir -p $LEIN_INSTALL \
  && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
  && echo "Comparing lein-pkg checksum ..." \
  && echo "019faa5f91a463bf9742c3634ee32fb3db8c47f0 *lein-pkg" | sha1sum -c - \
  && mv lein-pkg $LEIN_INSTALL/lein \
  && chmod 0755 $LEIN_INSTALL/lein \
  && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
  && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

# Install the Clojure command line tools. These instructions are taken directly
# from the Clojure "Getting Started" guide: https://clojure.org/guides/getting_started
RUN curl -O https://download.clojure.org/install/linux-install-${CLOJURE_VERSION}.sh \
      && chmod +x linux-install-${CLOJURE_VERSION}.sh \
      && ./linux-install-${CLOJURE_VERSION}.sh

USER $NB_USER
WORKDIR /home/$NB_USER

# Install clojure 1.9.0 so users don't have to download it every time
RUN echo \
'(defproject dummy ""\n\
   :dependencies [[org.clojure/clojure "1.9.0"]\n\
                  [lein-jupyter "0.1.16"]]\n\
   :plugins [[lein-tools-deps "0.4.1"]\n\
             [lein-jupyter "0.1.16"]])'\
  > project.clj \
  && lein deps && lein jupyter install-kernel

CMD ["start.sh", "lein", "jupyter", "notebook", "--ip", "0.0.0.0", "--NotebookApp.custom_display_url=http://localhost:8888", "--NotebookApp.iopub_data_rate_limit=10000000"]
