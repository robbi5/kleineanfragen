FROM dockerfile/java:oracle-java8

ENV MAVEN_VERSION 3.2.5
RUN curl -sSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

RUN mkdir /app /build
WORKDIR /app

RUN git clone https://github.com/robbi5/s3ninja.git /build && \
    cd /build && \
    git checkout s3-root && \
    sed -i '0,/<version>/{s#<version>2.0</version>#<version>2.0-SNAPSHOT</version>#}' /build/pom.xml && \
    mvn compile package && \
    cd /app && unzip /build/target/*.zip && \
    chmod +x sirius.sh

RUN sed -i 's#baseDir = "data/s3"#baseDir = "/data"#' /app/app/application.conf

VOLUME /data

#CMD java -server -Xmx1024m -Djava.net.preferIPv4Stack=true IPL
CMD /app/sirius.sh start && tail -F /app/logs/stdout.txt

EXPOSE 9444