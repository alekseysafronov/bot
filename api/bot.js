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
