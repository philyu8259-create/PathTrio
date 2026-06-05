import http from "node:http";

const PORT = Number(process.env.PORT || 8787);
const DEFAULT_QWEN_BASE_URL = "https://api.qwen.ai/v1";
const FOOD_RECOGNITION_PROVIDER = (process.env.FOOD_RECOGNITION_PROVIDER || "qwen").toLowerCase();

const qwenApiKey = process.env.QWEN_API_KEY || "";
const qwenBaseUrl = process.env.QWEN_API_BASE_URL || DEFAULT_QWEN_BASE_URL;
const qwenVisionModel = process.env.QWEN_VISION_MODEL || "qwen-vl-max-latest";

const server = http.createServer(async (request, response) => {
  const normalizedPath = new URL(request.url, "http://localhost").pathname;
  if (request.method === "GET" && normalizedPath === "/v1/health") {
    const payload = {
      status: "ok",
      provider: FOOD_RECOGNITION_PROVIDER,
      qwen: {
        configured: Boolean(qwenApiKey),
        model: qwenVisionModel,
        baseURL: qwenBaseUrl
      },
      timestamp: new Date().toISOString()
    };

    sendJson(response, 200, payload);
    return;
  }

  if (request.method === "POST" && normalizedPath === "/v1/food/recognize") {
    if (FOOD_RECOGNITION_PROVIDER !== "qwen") {
      sendJson(response, 400, { error: `Unsupported provider: ${FOOD_RECOGNITION_PROVIDER}` });
      return;
    }

    if (!qwenApiKey) {
      sendJson(response, 503, { error: "QWEN_API_KEY is not configured" });
      return;
    }

    try {
      const requestBody = await readJsonBody(request);
      const imageBase64 = requestBody.imageBase64 || "";
      const mimeType = requestBody.mimeType || "image/jpeg";

      if (!imageBase64) {
        sendJson(response, 400, { error: "Missing imageBase64" });
        return;
      }

      const payload = {
        model: qwenVisionModel,
        messages: [
          {
            role: "system",
            content: [
              {
                type: "text",
                text: "You are a nutrition assistant. Return compact JSON with fields foodName (string) and estimatedCalories (integer). Use only JSON output."
              }
            ]
          },
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`
                }
              }
            ]
          }
        ],
        max_tokens: 512,
        temperature: 0.1
      };

      const upstream = await fetch(`${qwenBaseUrl.replace(/\/$/, "")}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${qwenApiKey}`
        },
        body: JSON.stringify(payload)
      });

      if (!upstream.ok) {
        const errorBody = await upstream.text();
        response.writeHead(502, { "Content-Type": "application/json; charset=utf-8" });
        response.end(JSON.stringify({ error: `Upstream rejected request (${upstream.status})`, details: errorBody }));
        return;
      }

      const upstreamData = await upstream.json();
      const content = upstreamData?.choices?.[0]?.message?.content || "";
      const parsed = parseRecognition(content);

      if (!parsed.foodName) {
        sendJson(response, 502, { error: "Upstream response did not contain food name", raw: content });
        return;
      }

      sendJson(response, 200, {
        foodName: parsed.foodName,
        estimatedCalories: parsed.estimatedCalories,
        provider: "qwen",
        model: qwenVisionModel
      });
    } catch (error) {
      sendJson(response, 500, { error: error?.message || "Food recognition failed" });
    }

    return;
  }

  sendJson(response, 404, { error: "Not found" });
});

server.listen(PORT, () => {
  console.log(`ecs-food-api listening on :${PORT}`);
});

function sendJson(response, statusCode, value) {
  const data = JSON.stringify(value);
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(data)
  });
  response.end(data);
}

function parseRecognition(content) {
  const fallback = {
    foodName: "",
    estimatedCalories: 0
  };

  try {
    const parsed = JSON.parse(content);
    if (typeof parsed.foodName === "string" && parsed.foodName.trim()) {
      return {
        foodName: parsed.foodName.trim(),
        estimatedCalories: Math.max(0, Number(parsed.estimatedCalories ?? 0))
      };
    }
    if (typeof parsed.name === "string" && parsed.name.trim()) {
      return {
        foodName: parsed.name.trim(),
        estimatedCalories: Math.max(0, Number(parsed.calories ?? parsed.kcal ?? 0))
      };
    }
  } catch {
    // Fall through to heuristic extraction.
  }

  const rawText = String(content || "");
  const foodName = rawText.match(/"foodName"\s*:\s*"([^"]+)"/i)?.[1]?.trim()
    || rawText.match(/\\b(food|meal)[:\\-：]\\s*([^\\n.,;]+)/i)?.[2]?.trim()
    || "";
  const calorieText = rawText.match(/(\\d+)\\s*(kcal|calorie|cals?)?/i)?.[1];

  return {
    foodName,
    estimatedCalories: Math.max(0, Number(calorieText || 0))
  };
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    let raw = "";
    request.on("data", (chunk) => {
      raw += chunk;
    });
    request.on("end", () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
    request.on("error", () => reject(new Error("Failed to read request body")));
  });
}
