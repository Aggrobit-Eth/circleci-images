#
format(`# DO NOT MODIFY THIS FILE.  THIS FILE HAS BEEN AUTOGENERATED')
#
FROM openjdk:11-jdk-slim

LABEL maintainer="marc@circleci.com"

# Initial Command run as `root`.

ADD https://raw.githubusercontent.com/circleci/circleci-images/master/android/bin/circle-android /bin/circle-android
RUN chmod +rx /bin/circle-android

# Skip the first line of the Dockerfile template (FROM ${BASE})
syscmd(`tail -n +2 ../shared/images/Dockerfile-basic.template')

# Now commands run as user `circleci`

# Switching user can confuse Docker's idea of $HOME, so we set it explicitly
ENV HOME /home/circleci

# Install Google Cloud SDK

RUN sudo apt-get update -qqy && sudo apt-get install -qqy \
        python-dev \
        python-pip \
        python-setuptools \
        apt-transport-https \
        lsb-release && \
    sudo rm -rf /var/lib/apt/lists/*

RUN sudo apt-get update && sudo apt-get install gcc-multilib && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo pip uninstall crcmod && \
    sudo pip install --no-cache -U crcmod

RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

RUN sudo apt-get update && sudo apt-get install -y google-cloud-sdk && \
    sudo rm -rf /var/lib/apt/lists/* && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true

ARG cmdline_tools=https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip
ARG android_home=/opt/android/sdk

# SHA-256 92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9

RUN sudo apt-get update && \
    sudo apt-get install --yes \
        xvfb lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev \
        libglu1-mesa-dev && \
    sudo rm -rf /var/lib/apt/lists/*

# Install Ruby
RUN sudo apt-get update && \
    cd /tmp && wget -O ruby-install-0.6.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.1.tar.gz && \
    tar -xzvf ruby-install-0.6.1.tar.gz && \
    cd ruby-install-0.6.1 && \
    sudo make install && \
    ruby-install --cleanup ruby 2.6.1 && \
    rm -r /tmp/ruby-install-* && \
    sudo rm -rf /var/lib/apt/lists/*

ENV PATH ${HOME}/.rubies/ruby-2.6.1/bin:${PATH}
RUN echo 'gem: --env-shebang --no-rdoc --no-ri' >> ~/.gemrc && gem install bundler

# Download and install Android Commandline Tools
RUN sudo mkdir -p ${android_home}/cmdline-tools && \
    sudo chown -R circleci:circleci ${android_home} && \
    wget -O /tmp/cmdline-tools.zip -t 5 "${cmdline_tools}" && \
    unzip -q /tmp/cmdline-tools.zip -d ${android_home}/cmdline-tools && \
    rm /tmp/cmdline-tools.zip

# Set environmental variables
# deprecated upstream, should be removed in next-gen image
ENV ANDROID_HOME ${android_home}
ENV ANDROID_SDK_ROOT ${android_home}
ENV ADB_INSTALL_TIMEOUT 120
ENV PATH=${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN yes | sdkmanager --licenses && yes | sdkmanager --update

# Update SDK manager and install system image, platform and build tools
RUN sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator"

RUN sdkmanager \
  "build-tools;27.0.0" \
  "build-tools;27.0.1" \
  "build-tools;27.0.2" \
  "build-tools;27.0.3" \
  # 28.0.0 is failing to download from Google for some reason
  #"build-tools;28.0.0" \
  "build-tools;28.0.1" \
  "build-tools;28.0.2" \
  "build-tools;28.0.3" \
  "build-tools;29.0.0" \
  "build-tools;29.0.1" \
  "build-tools;29.0.2" \
  "build-tools;29.0.3" \
  "build-tools;30.0.0" \
  "build-tools;30.0.1" \
  "build-tools;30.0.2"

# API_LEVEL string gets replaced by m4
RUN sdkmanager "platforms;android-API_LEVEL"
