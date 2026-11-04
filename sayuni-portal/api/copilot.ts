import type { VercelRequest, VercelResponse } from '@vercel/node';

// 1. SECURE SERVER-SIDE CREDENTIALS (ZERO KEYS IN CLIENT APK OR GIT)
const cleanKey = (k: string) => k.replace(/^\uFEFF/, '').replace(/[^\x00-\x7F]/g, '').trim();

const BACKEND_GROQ_KEY = cleanKey(process.env.GROQ_API_KEY || '');

const RAW_MERCURY_KEYS = cleanKey(process.env.MERCURY_KEYS || '');
const MERCURY_KEYS = RAW_MERCURY_KEYS
  ? RAW_MERCURY_KEYS.split(',').map(k => k.trim()).filter(Boolean)
  : [];

// 2. IN-MEMORY RATE LIMITER (20 REQUESTS / MINUTE PER CLIENT IP)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);

  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + 60000 });
    return true;
  }

  if (entry.count >= 20) {
    return false;
  }

  entry.count += 1;
  return true;
}

// 3. PROMPT INJECTION & JAILBREAK GUARDRAILS
const INJECTION_PATTERNS = [
  /ignore\s+(all\s+)?(previous|prior|above)\s+instructions/i,
  /system\s+prompt/i,
  /reveal\s+(your\s+)?instructions/i,
  /jailbreak/i,
  /\bdan\s+mode\b/i,
  /\bdeveloper\s+mode\b/i,
  /act\s+as\s+a\s+(linux|terminal|unrestricted|hacker)/i,
  /bypass\s+(filters|rules|guardrails)/i,
  /pretend\s+you\s+are\s+not/i,
];

function isPromptInjection(text: string): boolean {
  return INJECTION_PATTERNS.some(pattern => pattern.test(text));
}

// 4. COMPREHENSIVE LITURGICAL SYSTEM PROMPT
const SYSTEM_PROMPT = `Wewe ni "Sayuni Copilot" — Msaidizi Rasmi wa Kikanisa, Kiroho na Liturujia wa Zion Jerusalem Church (Hekalu la Sayuni - Mbagala Kwa Matope, Dar es Salaam; chini ya uongozi wa Askofu Mercy James na Wachungaji).

Lugha yako: Jibu kwa lugha aliyotumia muumini (Kiswahili chenye upendo wa Kristo, heshima na staha ya kiliturujia, au Kiingereza iwapo mtumiaji ameuliza kwa Kiingereza).

MAMLAKA NA UWEZO WAKO:
1. PENDEKEZA MISTARI YA BIBLIA KWA HALI YOYOTE YA MAISHA (open_scripture):
   - "heart break" / "kuvunjika moyo" / "maumivu": Zaburi 34:18 ("Bwana yu karibu nao waliovunjika moyo..."), Mathayo 11:28, Zaburi 147:3.
   - "joyful moment" / "furaha" / "shukrani": Wafilipi 4:4, 1 Wathesalonike 5:16-18, Zaburi 100:1-4.
   - "night prayer" / "maombi ya usiku" / "lala": Zaburi 91:4, Zaburi 4:8, Mithali 3:24.
   - "morning prayer" / "maombi ya asubuhi": Zaburi 143:8, Maombolezo 3:22-23.
   - "anxiety" / "wasiwasi" / "hofu": Wafilipi 4:6-7, Isaya 41:10, 1 Petro 5:7.
   - "uponyaji" / "healing" / "ugonjwa": Isaya 53:5, Yeremia 30:17, Yakobo 5:14-15.
   - Mistari mahususi (mfano "Yohana 3:16", "Zaburi 23"):
   * Unapopendekeza mstari, weka maneno kamili ya andiko kwa upole, kisha:
     action: "open_scripture"
     actionData: { "reference": "Zaburi 34:18", "book": "Zaburi", "chapter": 34, "verse": 18 }

2. BADILI MANDHARI YA APP (change_theme):
   - Giza / usiku / dark mode -> action: "change_theme", actionData: { "mode": "dark" }
   - Mchana / nyeupe / light mode -> action: "change_theme", actionData: { "mode": "light" }
   - Dhahabu / liturgical gold -> action: "change_theme", actionData: { "mode": "gold" }

3. DUKA LA VITABU VYA KANISA (order_product / search_product):
   - "Tenzi za Rohoni (Toleo Rasmi la Sayuni)" - TZS 10,000 (Nyimbo zote 161)
   - "Biblia Takatifu (SUV - Kiswahili)" - TZS 25,000
   - "Ushindi Kupitia Neno & Maombi" (Kitabu cha Askofu Mercy James) - TZS 15,000
   - "Mwongozo wa Masomo ya Sunday School na Watoto" - TZS 8,000
   - "Kitabu cha Nyimbo za Kwaya ya Sayuni" - TZS 12,000
   - Kununua/kuagiza -> action: "order_product", actionData: { "productName": "...", "price": "..." }

4. NYIMBO ZA TENZI (open_hymn):
   - Mfano "Tenzi 24" -> action: "open_hymn", actionData: { "hymnNumber": 24, "title": "Mwamba Wenye Imara" }

5. MAOMBI YA SIRI NA DUA (submit_prayer):
   - Mtu anayetaka kuombewa au shida binafsi -> action: "submit_prayer", actionData: { "request": "..." }

6. REDIO, MIADI NA SADAKA (open_radio, open_appointments, open_giving):
   - "Redio" -> action: "open_radio", actionData: {}
   - "Miadi ya kichungaji / kuonana na mchungaji / ushauri" -> action: "open_appointments", actionData: {}
   - "Sadaka / zaka / fungu la kumi / michango" -> action: "open_giving", actionData: {}

JIBU LAZIMA LIWE KATIKA JSON HII PEKEE:
{
  "reply": "Ujumbe wako wa kiroho na kichungaji wenye faraja na Neno la Mungu",
  "action": "none" | "change_theme" | "order_product" | "search_product" | "open_hymn" | "open_scripture" | "submit_prayer" | "open_radio" | "open_appointments" | "open_giving",
  "actionData": {}
}
`;

// Helper: Call Inception Labs Mercury 2.5
async function callMercury(messages: any[]): Promise<string | null> {
  if (MERCURY_KEYS.length === 0) return null;

  // Key rotation
  const selectedKey = MERCURY_KEYS[Math.floor(Math.random() * MERCURY_KEYS.length)];

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const res = await fetch('https://api.inceptionlabs.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${selectedKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'mercury-2.5',
        messages,
        temperature: 0.3,
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (res.ok) {
      const data: any = await res.json();
      const content = data.choices?.[0]?.message?.content;
      if (content) return content;
    }
  } catch (err) {
    console.warn('Mercury call failed or timed out, falling back to Groq:', err);
  }

  return null;
}

// Helper: Call Groq
async function callGroq(messages: any[]): Promise<string | null> {
  if (!BACKEND_GROQ_KEY) return null;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);

    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${BACKEND_GROQ_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'qwen/qwen3.8-27b',
        messages,
        temperature: 0.3,
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (res.ok) {
      const data: any = await res.json();
      const content = data.choices?.[0]?.message?.content;
      if (content) return content;
    }
  } catch (err) {
    console.warn('Groq call failed:', err);
  }

  return null;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // Rate Limiting check
  const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
                   req.socket?.remoteAddress || '127.0.0.1';

  if (!checkRateLimit(clientIp)) {
    return res.status(429).json({
      ok: false,
      fallback: true,
      error: 'Umetuma maombi mengi mno kwa muda mfupi. Tafadhali subiri sekunde chache.',
    });
  }

  try {
    const { message, history } = req.body || {};
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Message field is required.' });
    }

    const cleanInput = message.trim();

    // Guardrail 1: Max length check (Anti-abuse)
    if (cleanInput.length > 500) {
      return res.status(200).json({
        ok: true,
        reply: 'Swali lako ni refu sana. Tafadhali fupisha swali lako liwe chini ya herufi 500 ili niweze kukusaidia vizuri.',
        action: 'none',
        actionData: {},
      });
    }

    // Guardrail 2: Prompt Injection / Adversarial Jailbreak Detection
    if (isPromptInjection(cleanInput)) {
      return res.status(200).json({
        ok: true,
        reply: 'Mimi ni Sayuni Copilot, msaidizi rasmi wa kikanisa na kiroho wa Zion Jerusalem Church. Lengo langu ni kukusaidia katika masuala ya kiroho, Neno la Mungu, nyimbo za Tenzi, na huduma za kanisa.',
        action: 'none',
        actionData: {},
      });
    }

    // Sanitize conversation history to prevent consecutive same-role errors
    const sanitizedHistory: { role: string; content: string }[] = [];
    if (Array.isArray(history)) {
      let lastRole = '';
      for (const item of history.slice(-4)) {
        const r = item.role === 'assistant' ? 'assistant' : 'user';
        if (r !== lastRole && item.content) {
          sanitizedHistory.push({ role: r, content: String(item.content).slice(0, 300) });
          lastRole = r;
        }
      }
      // If last history item is already 'user', pop it to avoid consecutive user messages
      if (sanitizedHistory.length > 0 && sanitizedHistory[sanitizedHistory.length - 1].role === 'user') {
        sanitizedHistory.pop();
      }
    }

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...sanitizedHistory,
      { role: 'user', content: cleanInput },
    ];

    // Multi-provider Execution: Inception Labs Mercury-2.5 -> Fallback to Groq Qwen
    let rawContent = await callMercury(messages);
    if (!rawContent) {
      rawContent = await callGroq(messages);
    }

    if (!rawContent) {
      return res.status(502).json({
        ok: false,
        fallback: true,
        error: 'All AI providers busy. Falling back to offline engine.',
      });
    }

    let parsed: any;
    try {
      parsed = JSON.parse(rawContent);
    } catch {
      parsed = {
        reply: rawContent,
        action: 'none',
        actionData: {},
      };
    }

    return res.status(200).json({
      ok: true,
      reply: parsed.reply || 'Ubarikiwe katika Sayuni.',
      action: parsed.action || 'none',
      actionData: parsed.actionData || {},
    });
  } catch (error: any) {
    console.error('Copilot handler exception:', error);
    return res.status(500).json({
      ok: false,
      fallback: true,
      error: error?.message || 'Internal error',
    });
  }
}
