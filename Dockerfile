# 第一阶段：构建阶段
FROM python:3.10-slim AS build

# 设置环境变量以防止交互安装
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装构建依赖项
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    gfortran \
    liblapack-dev \
    wget \
    libopenblas-dev \
    libatlas-base-dev \
    liblapack3 \
    libtbb12 \
    libcliquer1 \
    libgsl27 \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 SCIP 9.1.0 自解压归档文件
RUN wget https://scip.zib.de/download/release/scipoptsuite-9.1.0-linux.x86_64.gnu.opt.spx2.sh -O /tmp/scip_install.sh \
    && chmod +x /tmp/scip_install.sh \
    && /tmp/scip_install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/scip_install.sh

# 安装 Python SCIP 接口
RUN pip install --no-cache-dir pyscipopt

# 第二阶段：运行时阶段
FROM python:3.10-slim

# 设置环境变量以防止交互安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装运行时必要的依赖项
RUN apt-get update && apt-get install -y --no-install-recommends \
    liblapack3 \
    libtbb12 \
    libcliquer1 \
    libgsl27 \
    patchelf \
    tzdata \
    ca-certificates \
    locales \
    && rm -rf /var/lib/apt/lists/*

# 设置时区为 Asia/Shanghai 并生成 locale
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL=en_US.UTF-8

# 从构建阶段复制 SCIP 安装到最终镜像
COPY --from=build /usr/local/ /usr/local/
COPY --from=build /usr/lib /usr/lib

# 将项目文件复制到容器中
WORKDIR /app
COPY . /app

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 暴露端口 5500
EXPOSE 5500

# 设置容器启动时的默认命令
CMD ["python", "main.py"]
