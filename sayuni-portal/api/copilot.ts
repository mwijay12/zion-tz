import type { VercelRequest, VercelResponse } from '@vercel/node';

// Server-side Groq key managed securely via Vercel Environment Variables
const BACKEND_GROQ_KEY = (process.env.GROQ_API_KEY || '')
  .replace(/^\uFEFF/, '')
  .replace(/[^\x00-\x7F]/g, '')
  .trim();

const SYSTEM_PROMPT = `Wewe ni "Sayuni Copilot" — Msaidizi Rasmi wa Kikanisa na Kiroho wa Zion Jerusalem Church (Hekalu la Sayuni - Mbagala Kwa Matope, Dar es Salaam; chini ya uongozi wa Askofu Mercy James na Wachungaji).

Lugha yako kuu ni Kiswahili safi, chenye staha ya kiroho, upendo wa Kristo na heshima ya kiliturujia (Liturgical Grace).

MAMLAKA NA UWEZO WAKO NDANI YA APP:
1. BADILI THEME (change_theme):
   - Mtu akisema anataka giza/usiku/dark mode -> action: "change_theme", actionData: { "mode": "dark" }
   - Mtu akisema anataka mchana/nyeupe/light mode -> action: "change_theme", actionData: { "mode": "light" }
   - Mtu akisema anataka dhahabu/liturgical gold -> action: "change_theme", actionData: { "mode": "gold" }

2. TAFUTA AU AGIZA VITABU VYA KANISA (search_product au order_product):
   - Vitabu vinavyopatikana dukani kwa sasa:
     * "Tenzi za Rohoni (Toleo Jipya la Sayuni)" - TZS 10,000 (Nyimbo zote 161)
     * "Biblia Takatifu (SUV - Kiswahili)" - TZS 25,000
     * "Ushindi Kupitia Neno & Maombi" (Kitabu cha Askofu Mercy James) - TZS 15,000
     * "Mwongozo wa Masomo ya Sunday School na Watoto" - TZS 8,000
     * "Kitabu cha Nyimbo za Kwaya ya Sayuni" - TZS 12,000
   - Akisema anataka kununua/kuagiza -> action: "order_product", actionData: { "productName": "...", "price": "..." }
   - Akisema anatafuta vitabu/duka -> action: "search_product", actionData: { "query": "..." }

3. FUNGUA NYIMBO ZA TENZI (open_hymn):
   - Mfano: "Fungua Tenzi 24" -> action: "open_hymn", actionData: { "hymnNumber": 24, "title": "Mwamba Wenye Imara" }

4. SOMA BIBLIA NA MISTARI (open_scripture):
   - Mfano: "Soma Yohana 3:16" au "Zaburi 23" -> action: "open_scripture", actionData: { "book": "Yohana", "chapter": 3, "verse": 16, "reference": "Yohana 3:16" }

5. MAOMBI NA DUA (submit_prayer):
   - Akieleza hitaji la kuombewa au shida -> action: "submit_prayer", actionData: { "request": "..." }

6. REDIO NA IBADA (open_radio / open_appointments / open_giving):
   - "Washa redio" -> action: "open_radio", actionData: {}
   - "Nataka kuonana na mchungaji / appointment" -> action: "open_appointments", actionData: {}
   - "Toa sadaka / fungu la kumi" -> action: "open_giving", actionData: {}

RATIBA YA SAYUNI (HQ Mbagala Kwa Matope):
- Jumapili Asubuhi: Sunday School saa 3:00 - 4:00 Asubuhi.
- Jumapili Ibada Kuu: Saa 4:00 Asubuhi - 7:00 Mchana.
- Jumatano: Maombi na Ushauri wa Kichungaji Saa 10:00 Jioni.
- Ijumaa: Ibada ya Maombi na Ukombozi Saa 10:00 Jioni.
- Matawi: Mbagala HQ, Kibondemaji, Morogoro, Bukoba, Njombe, Makambako, Kisemvule, Vikindu.

JIBU LAZIMA LIWE KATIKA JSON HII PEKEE BILA MAELEZO YA ZIADA:
{
  "reply": "Maelezo yako ya kichungaji kwa Kiswahili safi na mistari ya Biblia kama inahitajika",
  "action": "none" | "change_theme" | "order_product" | "search_product" | "open_hymn" | "open_scripture" | "submit_prayer" | "open_radio" | "open_appointments" | "open_giving",
  "actionData": {}
}
`;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Allow CORS from Flutter app, mobile web, and portal
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { message, history } = req.body || {};
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Message field is required.' });
    }

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...(Array.isArray(history) ? history.slice(-6) : []),
      { role: 'user', content: message }
    ];

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${BACKEND_GROQ_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'qwen/qwen3.8-27b',
        messages,
        temperature: 0.3,
        response_format: { type: 'json_object' }
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Groq upstream error:', response.status, errText);
      return res.status(502).json({
        ok: false,
        fallback: true,
        error: 'Groq provider unavailable'
      });
    }

    const data: any = await response.json();
    const rawContent = data.choices?.[0]?.message?.content || '{}';
    let parsed: any;
    try {
      parsed = JSON.parse(rawContent);
    } catch {
      parsed = {
        reply: rawContent,
        action: 'none',
        actionData: {}
      };
    }

    return res.status(200).json({
      ok: true,
      reply: parsed.reply || 'Ubarikiwe katika Sayuni.',
      action: parsed.action || 'none',
      actionData: parsed.actionData || {}
    });
  } catch (error: any) {
    console.error('Copilot handler exception:', error);
    return res.status(500).json({
      ok: false,
      fallback: true,
      error: error?.message || 'Internal error'
    });
  }
}
