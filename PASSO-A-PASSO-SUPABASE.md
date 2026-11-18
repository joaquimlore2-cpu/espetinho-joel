# Espetinho do Joel · criar o banco no Supabase

Leva uns 10 minutos. No fim, você me manda **duas coisas**: a *Project URL* e a chave *anon public*.

## 1. Criar o projeto
1. Entre em https://supabase.com e faça login (pode ser a mesma conta da Neon Friday).
2. Clique em **New project**.
3. Nome: `espetinho-joel`. Região: **South America (São Paulo)**.
4. Crie uma senha do banco e guarde num lugar seguro. Ela não vai para o site e eu não preciso dela.
5. Clique em **Create new project** e espere uns 2 minutos até ficar pronto.

## 2. Criar as tabelas
1. No menu da esquerda, abra **SQL Editor** e clique em **New query**.
2. Copie todo o conteúdo do arquivo `supabase.sql` desta pasta, cole e clique em **Run**. Deve aparecer *Success. No rows returned*.
3. (Opcional, para a apresentação) Faça uma nova query com o conteúdo de `cardapio-exemplo.sql` e clique em **Run**.

## 3. Criar os logins (e-mail e senha)
1. Abra **Authentication → Users → Add user → Create new user**.
2. Preencha e-mail e senha e deixe marcado **Auto Confirm User**.
3. Repita para o Joel e para cada garçom. Cada pessoa usa o próprio login no celular.
4. Para ninguém criar conta sozinho: vá em **Authentication → Sign In / Providers** e desligue **Allow new users to sign up**.

## 4. Pegar as chaves e me mandar
Abra **Project Settings → API** (ou **Data API**) e copie:
- **Project URL**: algo como `https://abcdxyz.supabase.co`
- **anon public**: uma chave longa que começa com `eyJ...` (ou `sb_publishable_...`)

Pode colar as duas aqui no chat. A chave anon é pública: ela vai no site e só funciona para quem tem login.

> ⚠️ **Não mande** a chave `service_role` / `secret`. Ela dá acesso total ao banco e nunca vai no site.
