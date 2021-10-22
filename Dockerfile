# Pull base image.
FROM ubuntu:21.10

# Set the timezone
ENV TZ=Africa/Algiers
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install base software packages
RUN apt-get update && \
    apt-get install software-properties-common \
    wget \
    curl \
    git \
    lftp \
    unzip -y && \
    apt-get clean


# ——————————
# Install Java.
# ——————————

RUN \
  echo oracle-java17-installer shared/accepted-oracle-license-v1-3 select true | /usr/bin/debconf-set-selections && \
  add-apt-repository -y ppa:linuxuprising/java && \
  apt-get update && \
  apt-get install -y oracle-java17-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-java17-installer


# ——————————
# Installs i386 architecture required for running 32 bit Android tools
# ——————————

RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean

# ——————————
# Installs Android CMDLINE
# ——————————

ARG ANDROID_CMDLINE_VERSION=7302050
ENV ANDROID_CMDLINE_ROOT /opt/android-cmdline
RUN mkdir -p ${ANDROID_CMDLINE_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_VERSION}_latest.zip && \
    unzip *tools*linux*.zip -d ${ANDROID_CMDLINE_ROOT}/cmdline-tools && \
    mv ${ANDROID_CMDLINE_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_CMDLINE_ROOT}/cmdline-tools/tools && \
    rm *tools*linux*.zip

# set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
ENV GRADLE_HOME /opt/gradle
ENV KOTLIN_HOME /opt/kotlinc
ENV PATH ${PATH}:${GRADLE_HOME}/bin:${KOTLIN_HOME}/bin:${ANDROID_CMDLINE_ROOT}/cmdline-tools/latest/bin:${ANDROID_CMDLINE_ROOT}/cmdline-tools/tools/bin:${ANDROID_CMDLINE_ROOT}/platform-tools:${ANDROID_CMDLINE_ROOT}/emulator
# WORKAROUND: for issue https://issuetracker.google.com/issues/37137213
ENV LD_LIBRARY_PATH ${ANDROID_CMDLINE_ROOT}/emulator/lib64:${ANDROID_CMDLINE_ROOT}/emulator/lib64/qt/lib
# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
ENV QTWEBENGINE_DISABLE_SANDBOX 1

# accept the license agreements of the CMDLINE components
ADD license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh && /opt/license_accepter.sh $ANDROID_CMDLINE_ROOT

# ——————————
# Installs Gradle
# ——————————

# Gradle
ENV GRADLE_VERSION 3.3

RUN cd /usr/lib \
 && curl -fl https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle-bin.zip \
 && unzip "gradle-bin.zip" \
 && ln -s "/usr/lib/gradle-${GRADLE_VERSION}/bin/gradle" /usr/bin/gradle \
 && rm "gradle-bin.zip"

# Set Appropriate Environmental Variables
ENV GRADLE_HOME /usr/lib/gradle
ENV PATH $PATH:$GRADLE_HOME/bin


# ——————————
# Install Node and global packages
# ——————————
ENV NODE_VERSION 17.0.1
RUN cd && \
    wget -q http://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz && \
    tar -xzf node-v${NODE_VERSION}-linux-x64.tar.gz && \
    mv node-v${NODE_VERSION}-linux-x64 /opt/node && \
    rm node-v${NODE_VERSION}-linux-x64.tar.gz
ENV PATH ${PATH}:/opt/node/bin


# ——————————
# Install Basic React-Native packages
# ——————————
RUN npm install react-native-cli -g
RUN npm install yarn -g

ENV LANG en_US.UTF-8
