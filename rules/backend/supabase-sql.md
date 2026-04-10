---
paths:
  - "supabase/**/*"
  - "lib/features/sync/**/*.dart"
---

# Supabase SQL

- Keep RLS company-scoped through `get_my_company_id()`. Do not fall back to user-scoped policies.
- Make migrations idempotent when replacing policies and other repeatable objects.
- For child tables, derive scope through the parent chain until you reach `company_id`.
- Do not add `sync_status` columns or indexes back into the sync model.
- Keep privileged helpers and edge functions tightly scoped to the approved service-role and security-definer patterns already used in the repo.
- Treat `42501` as a real security-boundary failure, not a retryable sync hiccup.
