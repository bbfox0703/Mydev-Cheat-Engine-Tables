
# 💡 單人開發者 Git 分支操作流程（建議）

本指南適用於一人維護專案，使用 `dev` 分支開發，並透過 Pull Request 合併到 `main`。適合穩定與開發並存的個人專案管理。

---

## 🚀 日常開發流程

### 1️⃣ 更新 `main` 與 `dev`（確保基底乾淨）
```bash
git checkout main
git pull origin main

git checkout dev
git merge main
```

---

### 2️⃣ 在 `dev` 上開發與 commit
```bash
# 開發中...
git add .
git commit -m "新增功能/修正問題"
git push
```

---

### 3️⃣ 發送 PR 從 `dev` → `main`
- 前往 GitHub 網頁
- 建立 Pull Request：`dev` → `main`
- 合併（使用 squash 或 merge 皆可）

---

### 4️⃣ PR 合併後，讓 `dev` 同步回 `main`
```bash
git checkout main
git pull origin main

git checkout dev
git merge main
git push
```

這步驟可以防止 GitHub 顯示：
> This branch is X commits behind `main`

---

## 📦 備註

- **`dev` 為主要開發分支**，日常 commit 都放這裡
- **`main` 為穩定版本**，只接受經由 PR 合併的內容
- 若需另開測試功能，可從 `dev` 開 `feature/xxx` 分支再 PR 回 `dev`

---

## ✅ 常用指令總整理

```bash
# 初始化同步流程
git checkout main
git pull origin main
git checkout dev
git merge main
git push

# 日常開發
git add .
git commit -m "功能說明"
git push

# PR 合併後同步
git checkout main
git pull origin main
git checkout dev
git merge main
git push
```
