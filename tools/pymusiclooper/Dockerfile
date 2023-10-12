FROM python:3.9

RUN apt-get update && apt-get install -y libtag1-dev libsndfile1 libportaudio2 ffmpeg
RUN pip install pymusiclooper

ENTRYPOINT [ "pymusiclooper" ]