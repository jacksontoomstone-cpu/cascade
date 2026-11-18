# Hosting Cascade on Vercel

Cascade is one self-contained HTML file. Its only outside request is for Google Fonts, and it saves progress in the browser's own storage. It has no server and no database, so Vercel hosts it as a static site.

## What's in this folder

| File | What it does |
| --- | --- |
| `plumb.html` | The game itself. This is also the source for the claude.ai artifact. |
| `build.sh` | Vercel runs this. It writes `dist/index.html` with a proper doctype and your settings baked in. |
| `vercel.json` | Tells Vercel to run `sh build.sh` and serve the `dist` folder. |
| `.gitignore` | Keeps `dist/` and `.vercel/` out of git. |

## Deploying: two ways

**A. GitHub + Vercel dashboard (recommended: every push redeploys on its own)**
1. Create a new GitHub repo, e.g. `cascade`.
2. Push this folder to it:
   ```bash
   git init && git add plumb.html build.sh vercel.json .gitignore DEPLOY.md && git commit -m "Cascade"
   git branch -M main && git remote add origin https://github.com/<you>/cascade.git && git push -u origin main
   ```
3. At vercel.com, choose **Add New → Project**, import the repo, and leave the defaults. `vercel.json` already sets the build command and output folder.
4. Click **Deploy**. You get a `cascade-xxxx.vercel.app` URL. Add your own domain under **Settings → Domains**.

**B. Vercel CLI (no GitHub)**
```bash
npm i -g vercel
```
```bash
vercel
```
```bash
vercel --prod
```
The first command installs the CLI. The second logs you in and creates a preview deploy, and the third deploys to production. You need Node installed on your Mac, which you don't have right now; Vercel's own build servers already have what `build.sh` needs.

## Environment variables

A static page can't read Vercel's environment variables in the browser. `build.sh` reads them once at build time and writes them into the page. Set them under **Project → Settings → Environment Variables**, then **redeploy**: changes don't apply to builds that already exist.

**Working now:**

| Variable | Default | What it changes |
| --- | --- | --- |
| `CASCADE_LIVES` | `5` | Lives per board |
| `CASCADE_FIRE_SECONDS` | `5` | How long the fire lasts after cracking the top or side word |
| `CASCADE_ANALYTICS` | off | Set to `1` to load Vercel Web Analytics. Also turn on Analytics in the dashboard. |
| `CASCADE_SITE_URL` | `https://www.playcascade.io` | The address used in search tags, link previews, `robots.txt` and `sitemap.xml` |

Each environment can get its own values. For example, give **Preview** deploys `CASCADE_LIVES=99` so you can test boards without dying, and leave **Production** at 5.

**Worth adding next (each needs a little code):**

| Variable | Idea | Note |
| --- | --- | --- |
| `CASCADE_DAILY_START` | A date. The game opens on one board per day counting from it, like a daily puzzle. | Safe to put in the page |
| `CASCADE_BOARDS` | Which boards to include, e.g. `1-4,7`, so you can hide unfinished ones | Safe to put in the page |
| `CASCADE_COLUMN_DROP` | Turns the column-drop power-up on or off for A/B testing | Safe to put in the page |
| `CASCADE_STAMPS` | The bar size (the current `STAMPS = 6`), to tune difficulty without a code change | Safe to put in the page |
| `KV_REST_API_URL` / `KV_REST_API_TOKEN` | Shared leaderboards and solve times through Upstash Redis from the Vercel Marketplace | **Secret.** Only use it inside a `/api` serverless function, never in the page. |
| `ANTHROPIC_API_KEY` | A `/api/hint` function that writes a fresh hint for a stuck word, or new boards on a schedule | **Secret.** Only use it server-side. Rate-limit it. |
| `SENTRY_DSN` | Error reports from real players' browsers | Public by design, so it's fine in the page |

Rule of thumb: anything written into `dist/index.html` is public. Keys and tokens belong only in serverless functions.

## Skills worth installing (from a quick look on the web)

| Skill | Repo | Why it helps here |
| --- | --- | --- |
| **deploy-to-vercel** | `vercel-labs/agent-skills` | Lets Claude run the git-push or CLI deploy for you |
| **vercel-optimize** | `vercel-labs/agent-skills` | Audits caching, performance and cost once it's live |
| **web-design-guidelines** | `vercel-labs/agent-skills` | Reviews the UI against 100+ accessibility and UX rules: tap targets, focus states, contrast |
| **webapp-testing** | `anthropics/skills` | Playwright-based testing. It could play through boards automatically to catch regressions. |
| **frontend-design** | `anthropics/skills` | Design guidance for future style passes |

Install commands. Read each `SKILL.md` before installing, since skills can run scripts.
```bash
npx skills add vercel-labs/agent-skills --skill deploy-to-vercel
```
```bash
npx skills add vercel-labs/agent-skills --skill web-design-guidelines
```
Inside Claude Code: `/plugin marketplace add anthropics/skills`, then `/plugin install example-skills@anthropic-agent-skills`.

Community lists for browsing: `ComposioHQ/awesome-claude-skills` and `travisvn/awesome-claude-skills`. Many sites mirror these skills, so install only from the original repos.

## Action items

**Done**
- [x] Made the game read `lives` and `fireSeconds` from a build-time config. With no config it falls back to 5 lives and 5 seconds of fire, so the artifact is unchanged.
- [x] Added `build.sh`, `vercel.json` and `.gitignore`. I ran the build locally with and without settings and confirmed it renders in standards mode with the right lives.

**You do (needs your accounts)**
- [ ] Create a GitHub repo and push this folder (Option A, step 2).
- [ ] Import it into Vercel and deploy.
- [ ] Optional: add a custom domain.
- [ ] Optional: set `CASCADE_LIVES=99` for Preview only, then turn on Web Analytics and set `CASCADE_ANALYTICS=1` for Production.
- [ ] Decide which skills to install, and run the install commands after reading their `SKILL.md`.

**Next builds (ask Claude)**
- [ ] Daily-board mode (`CASCADE_DAILY_START`).
- [ ] Board selection plus the bar-size and column-drop flags.
- [ ] Add `og:title`, a description and a share image so links preview nicely in texts and on social media.
- [ ] Turn it into an installable PWA: a manifest and an offline cache.
- [ ] Optional: a leaderboard via a `/api` function plus Upstash Redis.
- [ ] Optional: an AI hint function with `ANTHROPIC_API_KEY`, server-side and rate-limited.
- [ ] Optional: an automated playthrough test with the webapp-testing skill.

**Heads-up:** saved progress lives in each browser, per site. Progress on the claude.ai version won't carry over to the Vercel site, and progress there won't come back.

## Real player results (the "Better than X%" curve)

When someone finishes a puzzle on playcascade.io, the game sends one anonymous line to `api/results.js`: which board, solved or not, the solve time, and how much of the board was filled in. No names, IDs or IP addresses are stored. The curve and the stats panel blend those real results with a built-in baseline for each puzzle (`BASELINES` in `plumb.html`). With n players, the real numbers count for n / (n + 25), so the baseline fades out after a few dozen finishes. Admin play-testing is never sent.

The API needs a Redis database connected to the Vercel project. Until it has one, it answers 503 and the game quietly uses the baselines.

**Setup (one time, about 2 minutes):**
1. Open vercel.com, then the Cascade project.
2. Open the **Storage** tab, click **Create Database**, and choose **Upstash for Redis** (free plan). Name it something like `cascade-results` and pick the region closest to you.
3. When it asks which project to connect, choose the Cascade project with all environments ticked. This adds `KV_REST_API_URL` and `KV_REST_API_TOKEN` to the project.
4. Redeploy: **Deployments**, then the newest deployment, then **⋯**, then **Redeploy**. Or just push any change.
5. Check it: open `https://www.playcascade.io/api/results?p=22`. It should show `{"n":0,"won":{},"lost":{}}`. A "not connected" error means the variables didn't reach the project, so redeploy again.

**When you add a new daily,** give it a line in `BASELINES` with your guess at the share of players who run out of lives and a typical solve time. Boards without one fall back to 30% and 9 minutes.
