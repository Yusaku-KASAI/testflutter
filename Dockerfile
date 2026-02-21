FROM ubuntu:24.04

# 1. 依存パッケージのインストール (Flutterに必要なものも追加)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    ca-certificates \
    ripgrep \
    tmux \
    gnupg \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js 20.x のインストール
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
    && apt-get install -y nodejs

# 3. GitHub CLI のインストール
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 4. ユーザー作成
RUN useradd -m -s /bin/bash claude && \
    echo 'claude ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER claude
WORKDIR /home/claude/workspace

# 5. Flutter SDK のインストール
# バージョンは必要に応じて変更してください
ENV FLUTTER_HOME="/home/claude/flutter"
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}

# 6. npm global と Flutter のパス設定
ENV PATH="/home/claude/.npm-global/bin:${FLUTTER_HOME}/bin:$PATH"
RUN npm config set prefix '/home/claude/.npm-global' && \
    npm install -g @anthropic-ai/claude-code

# bashrcへの書き出し
RUN echo "export PATH=\"/home/claude/.npm-global/bin:${FLUTTER_HOME}/bin:\$PATH\"" >> /home/claude/.bashrc

# 7. Flutterのプレダウンロード (オプション)
RUN flutter doctor

CMD ["tail", "-f", "/dev/null"]
