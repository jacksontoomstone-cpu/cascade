// Cascade results: an anonymous tally of how players finish each puzzle, used for the "Better than X%" curve.
//
//   POST /api/results  { p: board index, s: "won" | "lost", t: seconds, c: percent of the board filled }
//   POST /api/results  { p: board index, s: "start" }   (sent once per device the first time someone plays a board)
//   GET  /api/results?p=21  ->  { n, started, won: { "<seconds / 10>": count }, lost: { "<percent, in steps of 5>": count } }
//
// Storage is a Redis hash per puzzle (key cx:r:<board>), counting finishes per 10-second time bucket ("w:<bucket>")
// or per 5% fill bucket for boards that ran out of lives ("l:<pct>"). No names, ids or IP addresses are stored.
//
// It needs a Redis database connected to the Vercel project (Upstash for Redis, from the Vercel Marketplace), which
// adds these environment variables. Without them the API answers 503 and the game falls back to its built-in estimates.
const DB_URL = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
const DB_TOKEN = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;

async function redis(commands) {
  const r = await fetch(`${DB_URL}/pipeline`, {
    method: "POST",
    headers: { Authorization: `Bearer ${DB_TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify(commands),
  });
  if (!r.ok) throw new Error(`database answered ${r.status}`);
  return r.json();
}

const board = v => {
  const p = Number(v);
  return Number.isInteger(p) && p >= 0 && p < 1000 ? p : null;
};

module.exports = async (req, res) => {
  res.setHeader("Cache-Control", "no-store");
  if (!DB_URL || !DB_TOKEN) return res.status(503).json({ error: "results database not connected" });
  try {
    if (req.method === "GET") {
      const p = board(req.query.p);
      if (p === null) return res.status(400).json({ error: "bad puzzle" });
      const [out] = await redis([["HGETALL", `cx:r:${p}`]]);
      const flat = (out && out.result) || [], won = {}, lost = {};
      let n = 0, started = 0;
      for (let k = 0; k + 1 < flat.length; k += 2) {
        const [kind, bucket] = String(flat[k]).split(":"), count = Number(flat[k + 1]) || 0;
        if (kind === "start") { started = count; continue; }
        if (kind === "w") won[bucket] = count;
        else if (kind === "l") lost[bucket] = count;
        else continue;
        n += count;
      }
      return res.status(200).json({ n, started, won, lost });
    }
    if (req.method === "POST") {
      let body = req.body;
      if (typeof body === "string") { try { body = JSON.parse(body); } catch { body = null; } }
      if (!body || typeof body !== "object") return res.status(400).json({ error: "bad request" });
      const p = board(body.p);
      if (p === null) return res.status(400).json({ error: "bad puzzle" });
      let field;
      if (body.s === "start") field = "start";
      else if (body.s === "won") {
        const t = Math.round(Number(body.t));
        if (!(t >= 5 && t <= 6 * 3600)) return res.status(400).json({ error: "bad time" });   // 5 seconds to 6 hours
        field = `w:${Math.floor(t / 10)}`;
      } else if (body.s === "lost") {
        const c = Math.round(Number(body.c));
        if (!(c >= 0 && c <= 100)) return res.status(400).json({ error: "bad percent" });
        field = `l:${Math.floor(c / 5) * 5}`;
      } else return res.status(400).json({ error: "bad status" });
      await redis([["HINCRBY", `cx:r:${p}`, field, 1]]);
      return res.status(204).end();
    }
    res.setHeader("Allow", "GET, POST");
    return res.status(405).json({ error: "method not allowed" });
  } catch (e) {
    return res.status(502).json({ error: "results database unavailable" });
  }
};
