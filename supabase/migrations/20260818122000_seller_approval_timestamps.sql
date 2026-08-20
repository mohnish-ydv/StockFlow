alter table public.staging_users add column if not exists seller_approved_at timestamptz;

update public.staging_users
set seller_approved_at = coalesce(seller_approved_at, created_at)
where seller_status = 'approved' and seller_approved_at is null;

create or replace function public.stockflow_set_seller_approved_at()
returns trigger
language plpgsql
as $$
begin
  if new.seller_status = 'approved' and (old.seller_status is distinct from 'approved' or new.seller_approved_at is null) then
    new.seller_approved_at = coalesce(new.seller_approved_at, now());
  elsif new.seller_status is distinct from 'approved' and old.seller_status = 'approved' then
    new.seller_approved_at = null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_stockflow_seller_approved_at on public.staging_users;
create trigger trg_stockflow_seller_approved_at
before update of seller_status on public.staging_users
for each row execute function public.stockflow_set_seller_approved_at();
