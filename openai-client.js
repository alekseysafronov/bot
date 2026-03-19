// Пример клиента (можно подключить Gemini API через fetch)
import fetch from "node-fetch";

export async function geminiChat(messages, apiKey) {
  const response = await fetch("https://api.gemini.ai/v1/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: "gemini-1.5",
      messages: messages
    })
  });
  return await response.json();
}
