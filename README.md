# Сборка кастомного образа Mattermost (Khospital)

Образ собирается на базе официального `mattermost/mattermost-team-edition:release-10.12`.
Мы заменяем в нём **серверный бинарь** и **веб‑клиент (webapp)** на собранные из этого
репозитория — это нужно, чтобы наши правки (например, отложенные сообщения без лицензии)
реально попадали в работающий контейнер.

> ВАЖНО про отложенные сообщения (scheduled posts):
> Кнопка «отправить позже» включается/выключается целиком на стороне фронтенда
> (webapp). Поэтому недостаточно пересобрать только сервер — обязательно нужно
> пересобрать и веб‑клиент (`webapp/channels/dist`) и положить его в образ.
> Иначе из базового образа берётся старый клиент, который прячет фичу без лицензии.

---

## 0. Предварительные требования

- Docker с поддержкой `buildx` (для мультиплатформенной сборки на Mac).
- Go (для сборки серверного бинаря).
- **Node.js 20.x и npm 10.x** для сборки webapp.
  В `webapp/.npmrc` стоит `engine-strict=true`, поэтому слишком новый Node (например, 25)
  упадёт с ошибкой `EBADENGINE`. Требуется `node >=18.10.0` и `npm ^9 || ^10`.

  Если у вас в системе стоит более новый Node, поставьте Node 20 через Homebrew и
  используйте его только для этой сборки, не меняя системный:

  ```bash
  brew install node@20
  # путь к бинарю: /opt/homebrew/opt/node@20/bin
  /opt/homebrew/opt/node@20/bin/node -v   # должно быть v20.x
  /opt/homebrew/opt/node@20/bin/npm -v    # должно быть 10.x
  ```

---

## 1. Сборка серверного бинаря

```bash
# из корня репозитория mm_khosp
cd server

# Собрать линуксовый бинарь (положится в ./bin/linux_amd64/mattermost и др.)
make build-linux BUILD_NUMBER=10.12.4-khospital
```

Если нужна чистая сборка:

```bash
make clean
make build-linux BUILD_NUMBER=10.12.4-khospital
```

Dockerfile копирует бинарь из `bin/mattermost` (в корне репозитория), поэтому
кладём туда нужную архитектуру (amd64):

```bash
# вернуться в корень репозитория
cd ..

mkdir -p bin && cp server/bin/linux_amd64/mattermost bin/mattermost && ls -lh bin/

# Проверка версии бинаря
./bin/mattermost version
```

---

## 2. Сборка веб‑клиента (webapp) — ОБЯЗАТЕЛЬНО для фронтенд‑правок

Результат сборки кладётся в `webapp/channels/dist`. Именно эту папку Dockerfile
копирует в `/mattermost/client` внутри образа.

```bash
cd webapp

# Сборка с правильной версией Node (node@20 из Homebrew).
# Команда make dist сама сделает npm install (node_modules) и webpack‑сборку.
PATH="/opt/homebrew/opt/node@20/bin:$PATH" make dist
```

Если ваш системный Node уже подходящей версии (18–20), префикс `PATH=...` не нужен,
достаточно просто:

```bash
cd webapp
make dist
```

Сборка занимает несколько минут (установка зависимостей + webpack).
После успешной сборки проверьте, что появилась папка с собранным клиентом:

```bash
ls -lh channels/dist/   # внутри должны быть root.html, *.js, *.css и т.д.
cd ..
```

Чистая пересборка клиента (если нужно):

```bash
cd webapp
make clean      # удаляет node_modules и dist
PATH="/opt/homebrew/opt/node@20/bin:$PATH" make dist
cd ..
```

---

## 3. Сборка и пуш Docker‑образа

Dockerfile берёт:
- `bin/mattermost` → заменяет серверный бинарь;
- `webapp/channels/dist` → заменяет веб‑клиент (`/mattermost/client`).

```bash
# обычная сборка
docker build -t your-image-name:tag .

# для Mac (мультиплатформенная сборка + пуш в реестр)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/YOUUSERNAME/mattermost-khospital:10.12.4 --push .
```

> Если используете `buildx --push`, убедитесь, что вы залогинены в реестр
> (`docker login ghcr.io`) и заменили `YOUUSERNAME` на свой аккаунт.

---

## 4. После деплоя — проверка

1. В System Console / `config.json` должно быть включено `ServiceSettings.ScheduledPosts = true`
   (это значение по умолчанию).
2. Обновите страницу в браузере с очисткой кэша (**Cmd/Ctrl + Shift + R**), иначе
   может подгрузиться старый JS‑бандл.
3. Рядом с кнопкой «Отправить» должна появиться стрелка с опциями «Запланировать
   сообщение» (Tomorrow at 9:00, Next Monday и т.д.).

---

## Краткая шпаргалка (всё по порядку)

```bash
# 1. Сервер
cd server
make build-linux BUILD_NUMBER=10.12.4-khospital
cd ..
mkdir -p bin && cp server/bin/linux_amd64/mattermost bin/mattermost

# 2. Веб‑клиент (нужен Node 20)
cd webapp
PATH="/opt/homebrew/opt/node@20/bin:$PATH" make dist
cd ..

# 3. Образ
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/YOUUSERNAME/mattermost-khospital:10.12.4 --push .
```
