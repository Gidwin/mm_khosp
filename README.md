Инструкция по сборке Go‑проекта, чтобы получить бинарь bin/mattermos для Dockerfile
# Перейдите в каталог сервера
cd /server

# Собрать бинарь (положится в ./bin/mattermost)
make build

# Проверка версии бинаря
./bin/mattermost version

Если нужна чистая сборка перед make build:
make clean
make build

Далее собираем образ 
docker build -t your-image-name:tag . и пушим в облако