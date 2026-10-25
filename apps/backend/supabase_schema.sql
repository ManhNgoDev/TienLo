-- ========================================================
-- TIÊN LỘ - DATABASE SCHEMA (SUPABASE POSTGRESQL)
-- Hệ thống Tu Tiên, 10 Cảnh Giới, Linh Lực, Linh Thạch & AI Campaign
-- Tương thích hoàn toàn với Firebase Auth / Google Sign-In UID
-- ========================================================

-- Tự động gỡ bỏ các ràng buộc Foreign Key cũ trước khi chuyển kiểu dữ liệu:
DO $$ 
BEGIN
    -- 1. Gỡ bỏ tất cả Foreign Key constraints cũ để tránh lỗi xung đột kiểu UUID và TEXT
    ALTER TABLE IF EXISTS public.quests DROP CONSTRAINT IF EXISTS quests_campaign_id_fkey;
    ALTER TABLE IF EXISTS public.quests DROP CONSTRAINT IF EXISTS quests_user_id_fkey;
    ALTER TABLE IF EXISTS public.campaigns DROP CONSTRAINT IF EXISTS campaigns_user_id_fkey;
    ALTER TABLE IF EXISTS public.user_cultivations DROP CONSTRAINT IF EXISTS user_cultivations_user_id_fkey;
    ALTER TABLE IF EXISTS public.spirit_stone_transactions DROP CONSTRAINT IF EXISTS spirit_stone_transactions_user_id_fkey;

    -- 2. Chuyển đổi campaigns(id, user_id)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'campaigns' AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.campaigns ALTER COLUMN id TYPE TEXT USING id::TEXT;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'campaigns' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.campaigns ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
    END IF;

    -- 3. Chuyển đổi quests(id, campaign_id, user_id)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'quests' AND column_name = 'campaign_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.quests ALTER COLUMN campaign_id TYPE TEXT USING campaign_id::TEXT;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'quests' AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.quests ALTER COLUMN id TYPE TEXT USING id::TEXT;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'quests' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.quests ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
    END IF;

    -- 4. Chuyển đổi user_cultivations(user_id)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'user_cultivations' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.user_cultivations ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
    END IF;

    -- 5. Chuyển đổi spirit_stone_transactions(user_id)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'spirit_stone_transactions' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.spirit_stone_transactions ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
    END IF;
END $$;

-- 1. Bảng Người dùng (Đồng bộ Firebase Auth / Google Sign-In)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON public.users(firebase_uid);

-- 2. Bảng Tu Tiên Nhân Vật (10 Cảnh Giới, Bậc 1-10, Linh Lực & Linh Thạch)
CREATE TABLE IF NOT EXISTS public.user_cultivations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT UNIQUE NOT NULL,         -- Firebase UID / Google OAuth UID
    realm_index INT DEFAULT 0,            -- 0: Phàm Nhân, 1: Luyện Khí, ..., 9: Phi Tiên
    realm_name TEXT DEFAULT 'Phàm Nhân',  -- Tên cảnh giới: Khởi đầu từ Phàm Nhân
    sub_realm INT DEFAULT 1,              -- Bậc 1 đến 10
    current_exp INT DEFAULT 0,            -- Linh lực tích lũy trong bậc hiện tại
    max_exp INT DEFAULT 1000,             -- Linh lực cần để lên bậc tiếp theo (1000 EXP để đột phá Luyện Khí)
    total_exp BIGINT DEFAULT 0,           -- Tổng linh lực trọn đời tu sĩ
    spirit_stones INT DEFAULT 50,         -- Linh thạch tích lũy (tiền tệ)
    streak_days INT DEFAULT 0,            -- Chuỗi ngày tu luyện (tăng lên 1 khi hoàn thành hết quest trong ngày)
    last_active_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Cập nhật dữ liệu cũ nếu người dùng đang ở Luyện Khí mà chưa có kinh nghiệm:
UPDATE public.user_cultivations 
SET realm_index = 0, realm_name = 'Phàm Nhân', max_exp = 1000 
WHERE realm_index = 1 AND current_exp = 0;

CREATE INDEX IF NOT EXISTS idx_user_cultivations_user_id ON public.user_cultivations(user_id);

-- 3. Bảng Chiến Dịch Mục Tiêu do AI kiến tạo (Campaigns)
CREATE TABLE IF NOT EXISTS public.campaigns (
    id TEXT PRIMARY KEY,                  -- ID chiến dịch (hỗ trợ cả UUID hoặc camp-xxx)
    user_id TEXT NOT NULL,                -- Firebase UID
    title TEXT NOT NULL,                  -- Tiêu đề chiến dịch
    goal_prompt TEXT NOT NULL,            -- Mục tiêu ban đầu người dùng nhập
    duration_days INT NOT NULL DEFAULT 30,-- Thời gian (ngày)
    status TEXT DEFAULT 'ACTIVE',         -- 'ACTIVE', 'COMPLETED', 'PAUSED'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_user_id ON public.campaigns(user_id);

-- 4. Bảng Nhiệm Vụ Tu Luyện do AI tạo (Quests)
CREATE TABLE IF NOT EXISTS public.quests (
    id TEXT PRIMARY KEY,                  -- ID nhiệm vụ
    campaign_id TEXT,                     -- ID chiến dịch
    user_id TEXT NOT NULL,                -- Firebase UID
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    difficulty TEXT DEFAULT 'MEDIUM',     -- 'EASY' (Luyện Thể), 'MEDIUM' (Trúc Cơ), 'HARD' (Ngưng Đan), 'BREAKTHROUGH' (Độ Kiếp)
    exp_reward INT NOT NULL DEFAULT 100,  -- Phần thưởng Linh Lực
    stone_reward INT NOT NULL DEFAULT 10, -- Phần thưởng Linh Thạch
    icon_type TEXT DEFAULT 'fitness',     -- 'fitness', 'water', 'walk', 'medal', 'meditation', 'study'
    is_daily BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    is_xp_claimed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quests_user_id ON public.quests(user_id);
CREATE INDEX IF NOT EXISTS idx_quests_campaign_id ON public.quests(campaign_id);

-- 5. Bảng Nhật Ký Biến Động Linh Thạch (Spirit Stone Transactions)
CREATE TABLE IF NOT EXISTS public.spirit_stone_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,                -- Firebase UID
    amount INT NOT NULL,                  -- Dương (thưởng), Âm (tiêu thụ)
    type TEXT NOT NULL,                   -- 'QUEST_REWARD', 'LEVEL_UP', 'STREAK_BONUS', 'SHOP_BUY'
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.spirit_stone_transactions(user_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_cultivations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spirit_stone_transactions ENABLE ROW LEVEL SECURITY;

-- Tạo chính sách RLS cho phép truy cập
DROP POLICY IF EXISTS "Cho phep toan quyen voi service role" ON public.users;
CREATE POLICY "Cho phep toan quyen voi service role" ON public.users FOR ALL USING (true);

DROP POLICY IF EXISTS "Cho phep toan quyen voi service role cultivations" ON public.user_cultivations;
CREATE POLICY "Cho phep toan quyen voi service role cultivations" ON public.user_cultivations FOR ALL USING (true);

DROP POLICY IF EXISTS "Cho phep toan quyen voi service role campaigns" ON public.campaigns;
CREATE POLICY "Cho phep toan quyen voi service role campaigns" ON public.campaigns FOR ALL USING (true);

DROP POLICY IF EXISTS "Cho phep toan quyen voi service role quests" ON public.quests;
CREATE POLICY "Cho phep toan quyen voi service role quests" ON public.quests FOR ALL USING (true);

DROP POLICY IF EXISTS "Cho phep toan quyen voi service role transactions" ON public.spirit_stone_transactions;
CREATE POLICY "Cho phep toan quyen voi service role transactions" ON public.spirit_stone_transactions FOR ALL USING (true);
