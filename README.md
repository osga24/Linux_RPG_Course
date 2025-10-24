# Linux_RPG_Course

## 使用 Docker Compose 啟動（快速說明）

此專案包含兩個 Docker 映像/服務：`web`（對應 ./Web）與 `challenge`（對應 ./Challenge）。根目錄已新增 `docker-compose.yml`，可用來建立與啟動兩個服務。

常用命令（在專案根目錄執行）：

```zsh
# 建置並在背景啟動
docker-compose up --build -d

# 檢視 web 服務日誌
docker-compose logs -f web

# 停止並移除容器/網路
docker-compose down
```

預設設定：
- `web` 會綁定主機 8080 -> container 80（可透過瀏覽器檢視 `http://localhost:8080`）。
- `web` 會綁定主機 8080 -> container 80（可透過瀏覽器檢視 `http://localhost:8080`）。
- 另外我們已在 compose 中為 `web` 加上 network alias `web.osga`，因此在同一個 compose network 內（例如從 `challenge` container），你可以用 `http://web.osga` 或 `http://web.osga:80` 來存取 `web`。這對練習自訂 DNS 名稱或 domain 樣式的測試很方便。
- `challenge` service 預設為有 tty 與 stdin 開啟，並將 `./Challenge` 掛載到容器中的 `/home/challenge`（唯讀），方便在容器內查看挑戰目錄內容。

注意事項：
- 若要對服務進行開發或編輯檔案，請調整 `docker-compose.yml` 中對應的 volume 權限或移除 `:ro`。
- 若需要額外暴露某些端口（例如 SSH），請修改 `docker-compose.yml` 的 `ports`。
