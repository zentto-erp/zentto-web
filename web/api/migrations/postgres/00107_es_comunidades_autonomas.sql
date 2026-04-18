-- +goose Up

-- ESPAÑA — 50 Provincias + 2 Ciudades Autónomas (Ceuta, Melilla).
-- Codigos ISO 3166-2:ES. Usado para direcciones, facturacion y fiscal.
-- Referencia: https://www.ine.es/daco/daco42/codmun/codmun00i.htm

-- +goose StatementBegin
DELETE FROM cfg."State" WHERE "CountryCode" = 'ES';
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  -- Andalucia (ES-AN)
  ('ES','AL','Almeria',      10, TRUE),
  ('ES','CA','Cadiz',         20, TRUE),
  ('ES','CO','Cordoba',       30, TRUE),
  ('ES','GR','Granada',       40, TRUE),
  ('ES','H', 'Huelva',        50, TRUE),
  ('ES','J', 'Jaen',          60, TRUE),
  ('ES','MA','Malaga',        70, TRUE),
  ('ES','SE','Sevilla',       80, TRUE),
  -- Aragon (ES-AR)
  ('ES','HU','Huesca',       100, TRUE),
  ('ES','TE','Teruel',       110, TRUE),
  ('ES','Z', 'Zaragoza',     120, TRUE),
  -- Asturias (ES-AS)
  ('ES','O', 'Asturias',     130, TRUE),
  -- Islas Baleares (ES-IB)
  ('ES','IB','Islas Baleares',140,TRUE),
  -- Canarias (ES-CN)
  ('ES','GC','Las Palmas',                      150, TRUE),
  ('ES','TF','Santa Cruz de Tenerife',          160, TRUE),
  -- Cantabria (ES-CB)
  ('ES','S', 'Cantabria',    170, TRUE),
  -- Castilla-La Mancha (ES-CM)
  ('ES','AB','Albacete',     180, TRUE),
  ('ES','CR','Ciudad Real',  190, TRUE),
  ('ES','CU','Cuenca',       200, TRUE),
  ('ES','GU','Guadalajara',  210, TRUE),
  ('ES','TO','Toledo',       220, TRUE),
  -- Castilla y Leon (ES-CL)
  ('ES','AV','Avila',        230, TRUE),
  ('ES','BU','Burgos',       240, TRUE),
  ('ES','LE','Leon',         250, TRUE),
  ('ES','P', 'Palencia',     260, TRUE),
  ('ES','SA','Salamanca',    270, TRUE),
  ('ES','SG','Segovia',      280, TRUE),
  ('ES','SO','Soria',        290, TRUE),
  ('ES','VA','Valladolid',   300, TRUE),
  ('ES','ZA','Zamora',       310, TRUE),
  -- Cataluna (ES-CT)
  ('ES','B', 'Barcelona',    320, TRUE),
  ('ES','GI','Girona',       330, TRUE),
  ('ES','L', 'Lleida',       340, TRUE),
  ('ES','T', 'Tarragona',    350, TRUE),
  -- Comunidad Valenciana (ES-VC)
  ('ES','A', 'Alicante',     360, TRUE),
  ('ES','CS','Castellon',    370, TRUE),
  ('ES','V', 'Valencia',     380, TRUE),
  -- Extremadura (ES-EX)
  ('ES','BA','Badajoz',      390, TRUE),
  ('ES','CC','Caceres',      400, TRUE),
  -- Galicia (ES-GA)
  ('ES','C', 'A Coruna',     410, TRUE),
  ('ES','LU','Lugo',         420, TRUE),
  ('ES','OR','Ourense',      430, TRUE),
  ('ES','PO','Pontevedra',   440, TRUE),
  -- La Rioja (ES-RI)
  ('ES','LO','La Rioja',     450, TRUE),
  -- Madrid (ES-MD)
  ('ES','M', 'Madrid',       460, TRUE),
  -- Murcia (ES-MC)
  ('ES','MU','Murcia',       470, TRUE),
  -- Navarra (ES-NC)
  ('ES','NA','Navarra',      480, TRUE),
  -- Pais Vasco (ES-PV)
  ('ES','VI','Alava',        490, TRUE),
  ('ES','SS','Gipuzkoa',     500, TRUE),
  ('ES','BI','Bizkaia',      510, TRUE),
  -- Ciudades Autonomas
  ('ES','CE','Ceuta',        520, TRUE),
  ('ES','ML','Melilla',      530, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM cfg."State" WHERE "CountryCode" = 'ES';
-- +goose StatementEnd
