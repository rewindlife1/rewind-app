# REWIND — Member App

**The Complete Measure of Longevity.** Flutter app for web, iOS and Android, backed by Supabase.

## What's in v0.1

- **Accounts.** Sign up, sign in, email confirmation, password reset and change password, all through Supabase Auth.
- **Assessment.** 24 questions across the 8 dimensions. Answers produce a 0–100 score for each pillar and a weighted overall Longevity Score.
- **Live score.** Each pillar score is up to 85 points from the assessment plus up to 15 points from 7-day plan adherence. A snapshot is saved every day.
- **Daily plan.** Six tasks are auto-generated from your weakest pillars. You can add more from any pillar. Check-offs are stored and drive your streak.
- **Dashboard.** Score ring, streak, today's plan and the 8-dimension grid.
- **Track.** Score history chart, 7-day completion chart and past assessments.
- **Assess.** Radar chart, a detail page for each pillar, and a retake option.
- **REWIND Coach.** Chat that answers from the member's own scores. Conversations are saved. v1 is rules-based and is built to be swapped for an AI model later.
- **Profile & membership.** The trial, $29/mo and $249/yr placeholders. Stripe is not connected yet.
- **Security.** Row-level security on every table, so members only ever see their own data. Billing fields are server-only.
- **Installable web app.** Members can add it to their home screen. No App Store needed.

## Stack

- Flutter
- Riverpod
- go_router
- supabase_flutter
- google_fonts

Charts are drawn with custom painters, so there are no extra chart dependencies.

## One-time setup (about 15 minutes)

### 1. Supabase

1. Sign in at supabase.com and create a project named **rewind**. A region near Utah works best, e.g. *West US*.
2. Open **SQL Editor → New query**. Paste the whole of `supabase/migrations/0001_init.sql` and click **Run**.
3. Open **Authentication → URL Configuration**:
   - Site URL: where the app lives, e.g. `https://app.rewindlife.co` or your GitHub Pages URL.
   - Redirect URLs: add the same URL.
4. Open **Authentication → Emails → SMTP Settings** (optional, recommended). Send auth emails from ash@rewindlife.co rather than Supabase's default sender.
5. Open **Project Settings → API** and copy the **Project URL** and the **anon / publishable key**. The anon key is designed to be public, because RLS protects the data. Never use the `service_role` key in the app.

### 2. GitHub

1. Create a new **private** repo, e.g. `rewind-app`, and push this folder to it:

   ```bash
   git remote add origin https://github.com/<you>/rewind-app.git
   git push -u origin main
   ```

2. Open **Settings → Secrets and variables → Actions**.
   - Under **Secrets**, add `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
   - Under **Variables** (optional), add:
     - `CUSTOM_DOMAIN`, e.g. `app.rewindlife.co`
     - `BASE_HREF`, set to `/` when you use a custom domain
3. Open **Settings → Pages → Source** and choose **GitHub Actions**.
4. Open **Actions** and run **Build, test & deploy**. Every push to `main` then analyzes, tests, builds and deploys automatically.

### 3. Custom domain (recommended: app.rewindlife.co)

1. In GoDaddy DNS, add a **CNAME** record: `app` → `<you>.github.io`.
2. In the GitHub repo, set the variables `CUSTOM_DOMAIN=app.rewindlife.co` and `BASE_HREF=/`.
3. Re-run the workflow.
4. In Settings → Pages, tick **Enforce HTTPS**.
5. Point the rewindlife.co **Become a member** buttons to `https://app.rewindlife.co/#/signup`.

## Run locally

```bash
flutter create --platforms=web,android,ios --project-name rewind --org co.rewindlife .
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxxx
flutter test
```

## Project layout

```
lib/
  app/router.dart          routes + auth guard
  core/                    env + theme (lime #CEFF00, soft light)
  domain/                  pillars, questions, scoring, task library, coach (pure Dart, unit-tested)
  data/                    models + Supabase repository
  state/providers.dart     Riverpod providers (live score, plan, history)
  features/                auth, assessment, dashboard, track, pillars, coach, profile, shell
supabase/migrations/       database schema + RLS
.github/workflows/         CI: analyze → test → build web → deploy to Pages
```

## Next milestones

1. **Stripe:** Checkout with a 7-day trial (card required), plus a webhook (Supabase Edge Function) that sets `profiles.membership`. Gate the app on an active membership.
2. **Quest labs:** import results into a `lab_results` table so the Blood Biomarkers pillar uses real values instead of estimates.
3. **REWIND Coach:** move replies to an Edge Function backed by an AI model, with the member's scores as context.
4. **Native builds:** Android APK/AAB from CI. iOS requires an Apple developer account if you ever want the App Store.
