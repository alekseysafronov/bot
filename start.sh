#!/bin/bash

# ------------------------------
# Bash-скрипт: Создание проекта Telegram + Gemini Bot
# ------------------------------

PROJECT_DIR=$(pwd)
API_DIR="$PROJECT_DIR/api"

echo "Создание проекта в папке: $PROJECT_DIR"

# 1. Создаём папку api
mkdir -p "$API_DIR"

# 2. Создаём package.json
cat > package.json <<EOL
{
  "name": "telegram-gemini-bot",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "node-fetch": "^3.3.1"
  }
}
EOL

echo "package.json создан"

# 3. Создаём openai-client.js (для Gemini можно использовать fetch, оставим заготовку)
cat > openai-client.js <<EOL
// Пример клиента (можно подключить Gemini API через fetch)
import fetch from "node-fetch";

export async function geminiChat(messages, apiKey) {
  const response = await fetch("https://api.gemini.ai/v1/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": \`Bearer \${apiKey}\`
    },
    body: JSON.stringify({
      model: "gemini-1.5",
      messages: messages
    })
  });
  return await response.json();
}
EOL

echo "openai-client.js создан"

# 4. Создаём edge-функцию bot.js
cat > "$API_DIR/bot.js" <<'EOL'
import { geminiChat } from "../../openai-client.js";
import fetch from "node-fetch";

const sessions = {};

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

  const body = await req.json();
  if (!body.message || !body.message.text) return res.status(200).send("ok");

  const chatId = body.message.chat.id;
  const text = body.message.text;

  if (!sessions[chatId]) sessions[chatId] = [];
  sessions[chatId].push({ role: "user", content: text });

  const prompt = `
Ты — виртуальный помощник по химчистке мебели и ковров. 
Задавай вопросы:
1) Что чистим (диван, ковер, кресло, матрас, салон авто)
2) Размер/место
3) Наличие пятен
4) Материал
5) Район
6) Телефон
Отвечай дружелюбно, помогай записаться на чистку.
История диалога: ${JSON.stringify(sessions[chatId])}
`;

  const geminiData = await geminiChat([{ role: "user", content: prompt }], process.env.GEMINI_API_KEY);
  const reply = geminiData.choices[0].message.content;

  await fetch(`https://api.telegram.org/bot${process.env.TG_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text: reply })
  });

  // Сохраняем телефон, если найден
  const phoneMatch = text.match(/(\+?\d{10,15})/);
  if (phoneMatch) {
    const phone = phoneMatch[1];
    console.log("Найдён телефон:", phone);
    // Здесь можно добавить сохранение в Google Sheets
  }

  res.status(200).send("ok");
}
EOL

echo "api/bot.js создан"

# 5. Создаём .env.example
cat > .env.example <<EOL
TG_BOT_TOKEN=ваш_telegram_bot_token
GEMINI_API_KEY=ваш_gemini_api_key
SHEET_ID=ID_вашей_google_sheet
GOOGLE_API_KEY=ключ_google_api
EOL

echo ".env.example создан. Скопируйте в .env и заполните данные"

# 6. Установка зависимостей
npm install

echo "Проект успешно создан!"
echo "Далее:"
echo "1) Скопируйте .env.example в .env и заполните данные"
echo "2) Деплойте проект на Vercel: vercel"
echo "3) Установите webhook Telegram:"
echo "   https://api.telegram.org/bot<TG_BOT_TOKEN>/setWebhook?url=https://ваш-edge-url.vercel.app/api/bot"
