create or replace function public.stockflow_guard_session_account_status()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  select account_status into v_status from public.staging_users where id = new.user_id;
  if coalesce(v_status,'active') <> 'active' then
    raise exception 'Account is not active.' using errcode='42501';
  end if;
  return new;
end;
$$;

drop trigger if exists staging_session_account_status_guard on public.staging_sessions;
create trigger staging_session_account_status_guard
before insert or update on public.staging_sessions
for each row execute function public.stockflow_guard_session_account_status();
