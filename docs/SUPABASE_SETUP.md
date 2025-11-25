# Supabase Setup Guide for Salam Quran App

## Option A: Supabase Cloud (Recommended - No Docker needed) ⭐

### Step 1: Create Supabase Project
1. Go to https://supabase.com
2. Sign up for free account
3. Click "New Project"
4. Fill in:
   - **Name**: `Salam Quran Community`
   - **Database Password**: (save this - you'll need it)
   - **Region**: Choose closest to you
5. Wait 1-2 minutes for project creation

### Step 2: Get API Credentials
1. In your project dashboard, go to **Settings** → **API**
2. Copy these two values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### Step 3: Update `.env` File
Open `.env` and replace:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 4: Run Database Migration
In your project dashboard:
1. Go to **SQL Editor**
2. Click **New Query**
3. Copy the entire content from `supabase/migrations/20251117000001_create_community_tables.sql`
4. Paste and click **RUN**
5. You should see "Success. No rows returned"

### Step 5: Link CLI (Optional)
```bash
supabase login
supabase link --project-ref your-project-ref
```

✅ **Done!** Your backend is ready. Skip to "Testing the Setup" below.

---

## Option B: Local Development with Docker 🐳

### Prerequisites
You need Docker running. Choose one:

**Option B1: Start OrbStack** (you have it installed)
```bash
# Open OrbStack app, or:
open -a OrbStack
```

**Option B2: Install Docker Desktop**
- Download from: https://www.docker.com/products/docker-desktop
- Install and start the app
- Wait for "Docker Desktop is running" in menu bar

### Start Supabase Locally
```bash
# This will start Postgres, Auth, Storage, etc.
supabase start
```

First run takes 5-10 minutes (downloads Docker images).

### Get Local Credentials
After `supabase start` completes, it will show:
```
API URL: http://localhost:54321
anon key: eyJhbG...
```

Copy these to your `.env`:
```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbG...
```

### Run Migration
```bash
supabase db reset
```
This creates the tables automatically.

---

## Testing the Setup

### Verify Tables Exist

**Cloud**: Go to **Table Editor** in Supabase dashboard
**Local**: Run `supabase db diff` or check http://localhost:54323

You should see:
- ✅ `posts` table (16 columns)
- ✅ `comments` table (11 columns)
- ✅ Indexes created
- ✅ RLS policies enabled

### Test from Flutter

Run the app:
```bash
flutter run
```

Check for errors. If you see "Supabase client initialized successfully" in logs, you're good!

---

## Quick Commands Reference

```bash
# Cloud
supabase login                    # Authenticate
supabase link                     # Connect to cloud project
supabase db push                  # Push local migrations to cloud

# Local
supabase start                    # Start local backend
supabase stop                     # Stop all containers
supabase status                   # Check what's running
supabase db reset                 # Rerun all migrations
```

---

## Troubleshooting

### "Cannot connect to Docker daemon"
- Start OrbStack: `open -a OrbStack`
- OR install Docker Desktop

### "Failed to push migration"
- Run manually in SQL Editor (cloud)
- OR run `supabase db reset` (local)

### "Invalid API key"
- Double-check `.env` has correct URL and anon key
- No extra spaces or quotes
- Restart Flutter app after changing `.env`

### "RLS policy prevents access"
- For testing, you can temporarily disable RLS:
  ```sql
  ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
  ALTER TABLE comments DISABLE ROW LEVEL SECURITY;
  ```
- Remember to re-enable before production!

---

## Next Steps

Once setup is complete:
1. ✅ Tables created
2. ✅ API keys in `.env`
3. ✅ `flutter pub get` completed
4. → Run the app: `flutter run`
5. → I'll implement the repository and UI!

---

**Need help?** Check:
- Supabase Docs: https://supabase.com/docs
- Flutter Guide: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
