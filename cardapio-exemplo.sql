-- Opcional: cardápio de exemplo para a apresentação (marcado como exemplo).
-- Rode depois do supabase.sql. No app, "Cardápio → Apagar exemplos" remove tudo.
insert into produtos (nome, categoria, unidade, preco, custo, estoque, minimo, sem_estoque, exemplo, por_embalagem) values
  ('Espeto de carne',               'Espetos',         'espeto',    14, 5.20, 80, 20, false, true, 1),
  ('Espeto de frango',              'Espetos',         'espeto',    11, 3.60, 70, 20, false, true, 1),
  ('Coração de frango',             'Espetos',         'espeto',    12, 3.90, 45, 15, false, true, 1),
  ('Linguiça toscana',              'Espetos',         'espeto',    11, 3.80, 12, 15, false, true, 1),
  ('Queijo coalho',                 'Espetos',         'espeto',    11, 3.50, 40, 10, false, true, 1),
  ('Kafta',                         'Espetos',         'espeto',    13, 4.60, 30, 10, false, true, 1),
  ('Medalhão de frango com bacon',  'Espetos',         'espeto',    15, 5.50, 25, 10, false, true, 1),
  ('Pão de alho',                   'Espetos',         'espeto',     9, 2.40, 35, 10, false, true, 1),
  ('Farofa da casa',                'Acompanhamentos', 'porção',     8, 1.80,  0,  0, true,  true, 1),
  ('Vinagrete',                     'Acompanhamentos', 'porção',     7, 1.50,  0,  0, true,  true, 1),
  ('Mandioca frita',                'Porções',         'porção',    22, 6.00,  0,  0, true,  true, 1),
  ('Brahma 600 ml',                 'Cervejas',        'garrafa',   14, 7.20, 48, 24, false, true, 24),
  ('Heineken long neck',            'Cervejas',        'long neck', 12, 5.90, 36, 12, false, true, 24),
  ('Coca-Cola lata',                'Bebidas',         'lata',       6, 3.10, 40, 12, false, true, 12),
  ('Guaraná lata',                  'Bebidas',         'lata',       6, 2.90, 30, 12, false, true, 12),
  ('Água sem gás',                  'Bebidas',         'un',         4, 1.30, 24, 12, false, true, 12),
  ('Caipirinha de limão',           'Drinks',          'copo',      16, 4.50,  0,  0, true,  true, 1);
