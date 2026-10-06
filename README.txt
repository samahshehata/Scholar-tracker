SCHOLARSHIP HUB — COMMUNITY VERSION

WHAT THIS VERSION DOES
- Public Explore page: approved public scholarships are visible to everyone.
- User account: email/password login through Supabase Auth.
- My Scholarships: each user saves public scholarships and sets personal priority/status/progress/notes/tasks.
- My Opportunities: each user can add private scholarships for themselves.
- Public submission: a user can submit a private opportunity for admin review.
- Admin: approve/reject submissions and add public scholarships directly.
- RLS: normal users cannot edit another user's personal data.
- PWA/offline shell is retained.

SETUP
1. Create a free Supabase project.
2. Open Supabase SQL Editor and run supabase_setup.sql.
3. Open config.js and replace:
   YOUR_SUPABASE_PROJECT_URL
   YOUR_SUPABASE_ANON_KEY
   with your real Supabase Project URL and anon/public key.
4. NEVER use the service_role/secret key in the website.
5. Upload all files to GitHub Pages.
6. Open the site and Create account.
7. To make your account an admin, run in Supabase SQL Editor:
   update public.profiles set role='admin' where email='YOUR_EMAIL@example.com';
8. Log out/in again and the Admin button will be available.

DATA MODEL
public_scholarships = shared public opportunities + user private opportunities.
user_scholarships = personal relation/settings for each user and a public scholarship.
profiles = user role (user/admin).

IMPORTANT
The Supabase anon/public key is okay to expose in frontend code when Row Level Security is correctly enabled. Do NOT expose the service_role key.
