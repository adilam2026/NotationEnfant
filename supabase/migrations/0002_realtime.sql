-- Active la réplication temps réel pour que les deux téléphones des parents
-- voient les nouveaux scores sans action manuelle.
alter publication supabase_realtime add table public.children;
alter publication supabase_realtime add table public.star_events;
alter publication supabase_realtime add table public.rewards;
