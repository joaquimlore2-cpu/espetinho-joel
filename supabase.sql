-- Espetinho do Joel · banco do caixa (Supabase / Postgres)
-- Rode tudo de uma vez em: Supabase → SQL Editor → New query → colar → Run.
-- Pode rodar de novo sem problema: ele só cria o que ainda não existe.
--
-- Acesso: só quem entra com e-mail e senha (usuário criado em Authentication → Users)
-- consegue ver ou mexer nos dados. Sem login, nada aparece.
-- O site usa apenas a chave "anon" (pública). Nunca coloque a chave service_role no site.

-- ---------------------------------------------------------------- tabelas

create table if not exists produtos (
  id             uuid primary key default gen_random_uuid(),
  nome           text not null,
  categoria      text not null default 'Outros',
  unidade        text not null default 'un',
  preco          numeric(10,2) not null default 0,
  custo          numeric(10,2) not null default 0,
  estoque        numeric(10,2) not null default 0,
  minimo         numeric(10,2) not null default 0,
  sem_estoque    boolean not null default false,   -- vinagrete, farofa: não conta estoque
  ativo          boolean not null default true,
  exemplo        boolean not null default false,
  por_embalagem  numeric(10,2) not null default 1,
  criado         bigint not null default (extract(epoch from now()) * 1000)::bigint
);

-- Conta aberta. Mesa usa o id "mesa-<n>" (impede abrir a mesma mesa duas vezes).
create table if not exists contas (
  id       text primary key,
  mesa     int unique,
  nome     text not null default '',
  pessoas  int not null default 1,
  aberta   bigint not null,
  servico  boolean not null default true,
  exemplo  boolean not null default false
);

-- Cada item da conta é uma linha: dois garçons lançando na mesma mesa não se atropelam.
create table if not exists conta_itens (
  conta_id    text not null references contas(id) on update cascade on delete cascade,
  produto_id  uuid not null,
  nome        text not null,
  preco       numeric(10,2) not null,
  custo       numeric(10,2) not null default 0,
  qtd         int not null,
  ordem       bigint not null default (extract(epoch from clock_timestamp()) * 1000)::bigint,
  primary key (conta_id, produto_id)
);

-- Partes já pagas de uma conta (conta dividida).
create table if not exists conta_pagos (
  id        uuid primary key default gen_random_uuid(),
  conta_id  text not null references contas(id) on update cascade on delete cascade,
  base      numeric(10,2) not null,
  cobrado   numeric(10,2) not null,
  acresc    numeric(10,2) not null default 0,
  taxa      numeric(10,2) not null default 0,
  pag       text not null,
  ts        bigint not null
);

create table if not exists vendas (
  id          uuid primary key default gen_random_uuid(),
  ts          bigint not null,
  dia         text not null,
  itens       jsonb not null default '[]',
  sub         numeric(10,2) not null default 0,
  servico     numeric(10,2) not null default 0,
  custo       numeric(10,2) not null default 0,
  total       numeric(10,2) not null default 0,
  acrescimo   numeric(10,2) not null default 0,
  taxa        numeric(10,2) not null default 0,
  pagamentos  jsonb not null default '[]',
  pagamento   text not null default '',
  mesa        int,
  nome        text not null default '',
  aberta      bigint
);
create index if not exists vendas_dia on vendas (dia);

create table if not exists fechamentos (
  dia         text primary key,
  resumo      jsonb not null,
  fechado_em  bigint not null
);

create table if not exists compras (
  id        uuid primary key default gen_random_uuid(),
  ts        bigint not null,
  tipo      text not null,          -- entrada | ajuste
  produto   uuid,
  nome      text not null,
  unidades  numeric(10,2) not null,
  valor     numeric(10,2) not null default 0
);

create table if not exists config (
  id     text primary key,          -- sempre 'geral'
  dados  jsonb not null default '{}'
);
insert into config (id, dados)
values ('geral', '{"nome":"Espetinho do Joel","mesas":12,"servico":10,"taxas":{"pix":0,"debito":1.4,"credito":3.2,"dinheiro":0},"repassar":false,"appCartao":"infinitepay","pixModo":"direto","pix":{"chave":"","nome":"","cidade":"Curitiba"}}')
on conflict (id) do nothing;

-- ---------------------------------------------------------------- acesso: só usuários logados

-- Projetos novos do Supabase não dão permissão automática nas tabelas: libera só para quem tem login.
grant usage on schema public to authenticated;
grant select, insert, update, delete on produtos, contas, conta_itens, conta_pagos, vendas, fechamentos, compras, config to authenticated;
revoke all on produtos, contas, conta_itens, conta_pagos, vendas, fechamentos, compras, config from anon;

do $$
declare t text;
begin
  foreach t in array array['produtos','contas','conta_itens','conta_pagos','vendas','fechamentos','compras','config'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "logados" on %I', t);
    execute format('create policy "logados" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ---------------------------------------------------------------- operações que precisam ser de uma vez só

-- Lança (+1) ou tira (-1) um item na conta, somando no que já existe.
create or replace function lancar(p_conta text, p_produto uuid, p_delta int)
returns void language plpgsql security invoker as $$
begin
  insert into conta_itens (conta_id, produto_id, nome, preco, custo, qtd)
  select p_conta, p.id, p.nome, p.preco, p.custo, p_delta from produtos p where p.id = p_produto
  on conflict (conta_id, produto_id) do update set qtd = conta_itens.qtd + excluded.qtd;
  delete from conta_itens where conta_id = p_conta and produto_id = p_produto and qtd <= 0;
end $$;

-- Registra uma venda e dá baixa no estoque. Com p_conta, também fecha (apaga) a conta.
-- Se a conta já foi fechada por outro celular, não registra de novo.
create or replace function registrar_venda(p_venda jsonb, p_conta text default null)
returns uuid language plpgsql security invoker as $$
declare v_id uuid; it jsonb;
begin
  if p_conta is not null then
    perform 1 from contas where id = p_conta for update;
    if not found then raise exception 'conta_fechada'; end if;
  end if;
  insert into vendas (ts, dia, itens, sub, servico, custo, total, acrescimo, taxa, pagamentos, pagamento, mesa, nome, aberta)
  values ((p_venda->>'ts')::bigint, p_venda->>'dia', coalesce(p_venda->'itens','[]'),
          coalesce((p_venda->>'sub')::numeric,0), coalesce((p_venda->>'servico')::numeric,0), coalesce((p_venda->>'custo')::numeric,0),
          coalesce((p_venda->>'total')::numeric,0), coalesce((p_venda->>'acrescimo')::numeric,0), coalesce((p_venda->>'taxa')::numeric,0),
          coalesce(p_venda->'pagamentos','[]'), coalesce(p_venda->>'pagamento',''),
          (p_venda->>'mesa')::int, coalesce(p_venda->>'nome',''), (p_venda->>'aberta')::bigint)
  returning id into v_id;
  for it in select * from jsonb_array_elements(coalesce(p_venda->'itens','[]')) loop
    update produtos set estoque = estoque - (it->>'qtd')::numeric
     where id = (it->>'id')::uuid and not sem_estoque;
  end loop;
  if p_conta is not null then delete from contas where id = p_conta; end if;
  return v_id;
end $$;

-- Estorna uma venda: devolve o estoque e apaga a venda.
create or replace function estornar_venda(p_venda uuid)
returns void language plpgsql security invoker as $$
declare it jsonb; v vendas;
begin
  select * into v from vendas where id = p_venda for update;
  if not found then return; end if;
  for it in select * from jsonb_array_elements(v.itens) loop
    update produtos set estoque = estoque + (it->>'qtd')::numeric
     where id = (it->>'id')::uuid and not sem_estoque;
  end loop;
  delete from vendas where id = p_venda;
end $$;

-- Entrada de mercadoria: soma no estoque e recalcula o custo médio.
create or replace function entrada_estoque(p_produto uuid, p_unidades numeric, p_valor numeric, p_por numeric)
returns void language plpgsql security invoker as $$
declare p produtos;
begin
  select * into p from produtos where id = p_produto for update;
  if not found then return; end if;
  update produtos set
    custo = case when p_valor > 0 then round((greatest(p.estoque,0) * p.custo + p_valor) / (greatest(p.estoque,0) + p_unidades), 2) else p.custo end,
    estoque = p.estoque + p_unidades,
    por_embalagem = p_por
  where id = p_produto;
  insert into compras (ts, tipo, produto, nome, unidades, valor)
  values ((extract(epoch from now()) * 1000)::bigint, 'entrada', p_produto, p.nome, p_unidades, p_valor);
end $$;

-- Fecha o dia: guarda o resumo e apaga as vendas daquele dia.
create or replace function fechar_dia(p_dia text, p_resumo jsonb)
returns void language plpgsql security invoker as $$
begin
  insert into fechamentos (dia, resumo, fechado_em)
  values (p_dia, p_resumo, (extract(epoch from now()) * 1000)::bigint)
  on conflict (dia) do update set resumo = excluded.resumo, fechado_em = excluded.fechado_em;
  delete from vendas where dia = p_dia;
end $$;

grant execute on function lancar(text, uuid, int), registrar_venda(jsonb, text), estornar_venda(uuid),
  entrada_estoque(uuid, numeric, numeric, numeric), fechar_dia(text, jsonb) to authenticated;
revoke execute on function lancar(text, uuid, int), registrar_venda(jsonb, text), estornar_venda(uuid),
  entrada_estoque(uuid, numeric, numeric, numeric), fechar_dia(text, jsonb) from anon, public;

-- ---------------------------------------------------------------- tempo real (todos os celulares ao vivo)

do $$
declare t text;
begin
  foreach t in array array['produtos','contas','conta_itens','conta_pagos','vendas','fechamentos','compras','config'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;
