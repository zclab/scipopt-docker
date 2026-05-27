# ==========================================
# 阶段 1: Builder
# ==========================================
FROM ubuntu:22.04 AS builder

ARG TARGETARCH

COPY scipoptsuite-10.0.2-glibc2_28-amd64.tgz /tmp/
COPY scipoptsuite-10.0.2-glibc2_28-aarch64.tgz /tmp/

RUN mkdir -p /opt/scip && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        tar -xzf /tmp/scipoptsuite-10.0.2-glibc2_28-aarch64.tgz -C /opt/scip --strip-components=1; \
    else \
        tar -xzf /tmp/scipoptsuite-10.0.2-glibc2_28-amd64.tgz -C /opt/scip --strip-components=1; \
    fi

# ==========================================
# 阶段 2: 镜像
# ==========================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    gcc \
    g++ \
    gfortran \
    liblapack3 \
    libtbb12 \
    libcliquer1 \
    libopenblas-dev \
    libgsl27 \
    patchelf \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV SCIPOPTDIR=/usr/local
# 配置动态链接库路径 (核心: 防止 libscip.so 找不到)
ENV LD_LIBRARY_PATH="${SCIPOPTDIR}/lib:${LD_LIBRARY_PATH}"

# 从 Builder 复制 SCIP
COPY --from=builder /opt/scip ${SCIPOPTDIR}

# 1. 创建并激活 Python 虚拟环境
ENV VIRTUAL_ENV=/opt/venv
RUN python3.10 -m venv $VIRTUAL_ENV
# 将虚拟环境路径加入 PATH
ENV PATH="$VIRTUAL_ENV/bin:${SCIPOPTDIR}/bin:${PATH}"

WORKDIR /app

# 2. 缓存优化: 先只复制 requirements.txt 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir PySCIPOpt && \
    pip install --no-cache-dir -r requirements.txt

# 3. 再复制项目代码。这样只要 requirements.txt 不变，上面的依赖安装层就会被 Docker 缓存
COPY . .

# ----------------------------------------------

EXPOSE 5500

CMD ["python", "main.py"]