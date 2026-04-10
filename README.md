Инструкция по сборке Go‑проекта, чтобы получить бинарь bin/mattermos для Dockerfile
# Перейдите в каталог сервера
cd /server

# Собрать бинарь (положится в ./bin/mattermost)
make build-linux BUILD_NUMBER=10.12.4-khospital
Теперь нужно скопировать нужную архитектуру в bin/mattermost для Dockerfile. Dockerfile копирует bin/mattermost, поэтому создам его:


cd mm_khosp && cp server/bin/linux_amd64/mattermost bin/mattermost && ls -lh bin/
mkdir -p bin && cp server/bin/linux_amd64/mattermost bin/mattermost && ls -lh bin/
# Проверка версии бинаря
./bin/mattermost version

Если нужна чистая сборка перед make build:
make clean
make build

Далее собираем образ 
docker build -t your-image-name:tag . и пушим в облако
for macbook user docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/YOUUSERNAME/mattermost-khospital:10.12.4 --push .