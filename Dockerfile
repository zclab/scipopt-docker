# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置环境变量以防止交互安装
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装 Python 3.10 和 SCIP 所需的依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    gcc \
    g++ \
    gfortran \
    liblapack3 \
    libtbb12 \
    libcliquer1 \
    libopenblas-dev \
    libgsl27 \
    patchelf \
    wget \
    tzdata \
    ca-certificates \
    locales \
    && rm -rf /var/lib/apt/lists/*

# 设置 Python 3.10 为默认版本
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3 1

# 设置时区为 Asia/Shanghai 并生成 locale
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL=en_US.UTF-8

# 将本地下载的文件复制到容器中
COPY SCIPOptSuite-9.1.0-Linux-ubuntu22.sh /tmp/scip_install.sh

# 下载并安装 SCIP 9.1.0 自解压归档文件
RUN chmod +x /tmp/scip_install.sh \
    && /tmp/scip_install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/scip_install.sh

# 安装 Python SCIP 接口
RUN pip3 install --no-cache-dir pyscipopt

# 设置 SCIP 二进制文件路径
ENV PATH="/usr/local/bin:${PATH}"

# 将项目文件复制到容器中
WORKDIR /app
COPY . /app

# 安装 Python 依赖
RUN pip3 install --no-cache-dir -r requirements.txt

# 暴露端口 5500
EXPOSE 5500

# 设置容器启动时的默认命令
CMD ["python3", "main.py"]
