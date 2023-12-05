FROM python:3.10

RUN apt update && apt install -y jq ffmpeg xfonts-utils
RUN curl -sSL https://bit.ly/install-xq | bash 
RUN pip install edge-tts
RUN pip install git+https://github.com/openai/whisper.git
RUN wget -O /tmp/YaHei.Consolas.1.12.zip https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/uigroupcode/YaHei.Consolas.1.12.zip \
    && unzip /tmp/YaHei.Consolas.1.12.zip \
    && mkdir -p /usr/share/fonts/consolas \
    && mv YaHei.Consolas.1.12.ttf /usr/share/fonts/consolas/ \
    && chmod 644 /usr/share/fonts/consolas/YaHei.Consolas.1.12.ttf \
    && cd /usr/share/fonts/consolas \
    && mkfontscale && mkfontdir && fc-cache -fv

ENTRYPOINT [ "/bin/bash" ]
