-- ============================================================
-- PrepAI — Supabase Database Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- ── Profiles ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT,
  email            TEXT,
  target_role      TEXT,
  industry         TEXT,
  experience_level TEXT,  -- 'Entry', 'Mid', 'Senior'
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own profile"
  ON public.profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ── Resumes ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.resumes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  file_name    TEXT,
  file_url     TEXT,
  analysis     JSONB,   -- { score, skills[], education[], experience[], suggestions[], weak_areas[], summary }
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own resumes"
  ON public.resumes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Interviews ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.interviews (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  job_role         TEXT,
  industry         TEXT,
  experience_level TEXT,
  interview_type   TEXT,   -- 'HR' | 'Technical'
  status           TEXT DEFAULT 'pending',  -- 'pending' | 'in_progress' | 'completed'
  overall_score    NUMERIC,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  completed_at     TIMESTAMPTZ
);

ALTER TABLE public.interviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own interviews"
  ON public.interviews FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Questions ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.questions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_id   UUID NOT NULL REFERENCES public.interviews(id) ON DELETE CASCADE,
  question_text  TEXT NOT NULL,
  order_index    INT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view questions for own interviews"
  ON public.questions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.interviews
      WHERE interviews.id = questions.interview_id
        AND interviews.user_id = auth.uid()
    )
  );

-- ── Answers ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.answers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  answer_text   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own answers"
  ON public.answers FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Evaluations ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.evaluations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id   UUID NOT NULL REFERENCES public.answers(id) ON DELETE CASCADE,
  score       NUMERIC,   -- 0-10
  feedback    TEXT,
  strengths   TEXT[],
  weaknesses  TEXT[],
  suggestions TEXT[],
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.evaluations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view evaluations for own answers"
  ON public.evaluations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.answers
      WHERE answers.id = evaluations.answer_id
        AND answers.user_id = auth.uid()
    )
  );

-- ── Auto-create profile on signup ────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── Storage bucket for resumes ────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('resumes', 'resumes', false)
ON CONFLICT DO NOTHING;

CREATE POLICY "Users upload own resumes"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'resumes'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users read own resumes"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'resumes'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users delete own resumes"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'resumes'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
