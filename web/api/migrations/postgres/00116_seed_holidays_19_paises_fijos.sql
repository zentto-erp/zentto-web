-- +goose Up

-- Seed cfg.Holiday — feriados FIJOS recurrentes por pais (fecha ancla 2026).
-- IsRecurring=TRUE: la UI/SPs reproducen la fecha para cada ano.
-- EXCLUYE feriados moviles (Semana Santa, Carnavales, fechas trasladadas a lunes).
-- Excluye ES (cubierto por migracion del agente Espana).
-- Fuente: legislacion laboral vigente de cada pais.
-- Idempotente: DELETE por CountryCode + INSERT.

-- +goose StatementBegin
DELETE FROM cfg."Holiday"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- Venezuela
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('VE','2026-01-01','Ano Nuevo',                       TRUE, TRUE),
  ('VE','2026-04-19','Declaracion de Independencia',    TRUE, TRUE),
  ('VE','2026-05-01','Dia del Trabajador',              TRUE, TRUE),
  ('VE','2026-06-24','Batalla de Carabobo',             TRUE, TRUE),
  ('VE','2026-07-05','Dia de la Independencia',         TRUE, TRUE),
  ('VE','2026-07-24','Natalicio de Simon Bolivar',      TRUE, TRUE),
  ('VE','2026-10-12','Dia de la Resistencia Indigena',  TRUE, TRUE),
  ('VE','2026-12-24','Nochebuena',                      TRUE, TRUE),
  ('VE','2026-12-25','Navidad',                         TRUE, TRUE),
  ('VE','2026-12-31','Fin de Ano',                      TRUE, TRUE);
-- +goose StatementEnd

-- Argentina
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('AR','2026-01-01','Ano Nuevo',                                    TRUE, TRUE),
  ('AR','2026-03-24','Dia Nacional Memoria por Verdad y Justicia',   TRUE, TRUE),
  ('AR','2026-04-02','Dia Veteranos y Caidos Guerra Malvinas',       TRUE, TRUE),
  ('AR','2026-05-01','Dia del Trabajador',                           TRUE, TRUE),
  ('AR','2026-05-25','Dia de la Revolucion de Mayo',                 TRUE, TRUE),
  ('AR','2026-06-20','Paso a la Inmortalidad del General Belgrano',  TRUE, TRUE),
  ('AR','2026-07-09','Dia de la Independencia',                      TRUE, TRUE),
  ('AR','2026-08-17','Paso a la Inmortalidad del General San Martin',TRUE, TRUE),
  ('AR','2026-10-12','Dia del Respeto a la Diversidad Cultural',     TRUE, TRUE),
  ('AR','2026-11-20','Dia de la Soberania Nacional',                 TRUE, TRUE),
  ('AR','2026-12-08','Inmaculada Concepcion de Maria',               TRUE, TRUE),
  ('AR','2026-12-25','Navidad',                                      TRUE, TRUE);
-- +goose StatementEnd

-- Colombia
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('CO','2026-01-01','Ano Nuevo',                  TRUE, TRUE),
  ('CO','2026-05-01','Dia del Trabajo',            TRUE, TRUE),
  ('CO','2026-07-20','Dia de la Independencia',    TRUE, TRUE),
  ('CO','2026-08-07','Batalla de Boyaca',          TRUE, TRUE),
  ('CO','2026-12-08','Inmaculada Concepcion',      TRUE, TRUE),
  ('CO','2026-12-25','Navidad',                    TRUE, TRUE);
-- +goose StatementEnd

-- Mexico (Art. 74 LFT - obligatorios + religioso Virgen Guadalupe)
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('MX','2026-01-01','Ano Nuevo',                      TRUE, TRUE),
  ('MX','2026-02-05','Aniversario de la Constitucion', TRUE, TRUE),
  ('MX','2026-03-21','Natalicio de Benito Juarez',     TRUE, TRUE),
  ('MX','2026-05-01','Dia del Trabajo',                TRUE, TRUE),
  ('MX','2026-09-16','Dia de la Independencia',        TRUE, TRUE),
  ('MX','2026-11-20','Dia de la Revolucion Mexicana',  TRUE, TRUE),
  ('MX','2026-12-12','Virgen de Guadalupe',            TRUE, TRUE),
  ('MX','2026-12-25','Navidad',                        TRUE, TRUE);
-- +goose StatementEnd

-- Peru
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('PE','2026-01-01','Ano Nuevo',                     TRUE, TRUE),
  ('PE','2026-05-01','Dia del Trabajo',               TRUE, TRUE),
  ('PE','2026-06-07','Batalla de Arica',              TRUE, TRUE),
  ('PE','2026-06-29','San Pedro y San Pablo',         TRUE, TRUE),
  ('PE','2026-07-23','Dia de la Fuerza Aerea',        TRUE, TRUE),
  ('PE','2026-07-28','Fiestas Patrias - Independencia',TRUE, TRUE),
  ('PE','2026-07-29','Fiestas Patrias - Parada Militar',TRUE, TRUE),
  ('PE','2026-08-06','Dia de la Batalla de Junin',    TRUE, TRUE),
  ('PE','2026-08-30','Santa Rosa de Lima',            TRUE, TRUE),
  ('PE','2026-10-08','Combate de Angamos',            TRUE, TRUE),
  ('PE','2026-11-01','Todos los Santos',              TRUE, TRUE),
  ('PE','2026-12-08','Inmaculada Concepcion',         TRUE, TRUE),
  ('PE','2026-12-09','Batalla de Ayacucho',           TRUE, TRUE),
  ('PE','2026-12-25','Navidad',                       TRUE, TRUE);
-- +goose StatementEnd

-- Ecuador
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('EC','2026-01-01','Ano Nuevo',                        TRUE, TRUE),
  ('EC','2026-05-01','Dia del Trabajo',                  TRUE, TRUE),
  ('EC','2026-05-24','Batalla del Pichincha',            TRUE, TRUE),
  ('EC','2026-08-10','Primer Grito de Independencia',    TRUE, TRUE),
  ('EC','2026-10-09','Independencia de Guayaquil',       TRUE, TRUE),
  ('EC','2026-11-02','Dia de los Difuntos',              TRUE, TRUE),
  ('EC','2026-11-03','Independencia de Cuenca',          TRUE, TRUE),
  ('EC','2026-12-06','Fundacion de Quito',               TRUE, TRUE),
  ('EC','2026-12-25','Navidad',                          TRUE, TRUE);
-- +goose StatementEnd

-- Chile
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('CL','2026-01-01','Ano Nuevo',                      TRUE, TRUE),
  ('CL','2026-05-01','Dia Nacional del Trabajo',       TRUE, TRUE),
  ('CL','2026-05-21','Dia de las Glorias Navales',     TRUE, TRUE),
  ('CL','2026-06-29','San Pedro y San Pablo',          TRUE, TRUE),
  ('CL','2026-07-16','Virgen del Carmen',              TRUE, TRUE),
  ('CL','2026-08-15','Asuncion de la Virgen',          TRUE, TRUE),
  ('CL','2026-09-18','Independencia Nacional',         TRUE, TRUE),
  ('CL','2026-09-19','Glorias del Ejercito',           TRUE, TRUE),
  ('CL','2026-10-12','Encuentro de Dos Mundos',        TRUE, TRUE),
  ('CL','2026-11-01','Dia de Todos los Santos',        TRUE, TRUE),
  ('CL','2026-12-08','Inmaculada Concepcion',          TRUE, TRUE),
  ('CL','2026-12-25','Navidad',                        TRUE, TRUE);
-- +goose StatementEnd

-- Bolivia
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('BO','2026-01-01','Ano Nuevo',                         TRUE, TRUE),
  ('BO','2026-01-22','Dia del Estado Plurinacional',      TRUE, TRUE),
  ('BO','2026-05-01','Dia del Trabajo',                   TRUE, TRUE),
  ('BO','2026-06-21','Ano Nuevo Andino Amazonico',        TRUE, TRUE),
  ('BO','2026-08-06','Dia de la Independencia',           TRUE, TRUE),
  ('BO','2026-11-02','Dia de Todos los Difuntos',         TRUE, TRUE),
  ('BO','2026-12-25','Navidad',                           TRUE, TRUE);
-- +goose StatementEnd

-- Uruguay
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('UY','2026-01-01','Ano Nuevo',                   TRUE, TRUE),
  ('UY','2026-01-06','Dia de los Ninos',            TRUE, TRUE),
  ('UY','2026-04-19','Desembarco de los 33',        TRUE, TRUE),
  ('UY','2026-05-01','Dia de los Trabajadores',     TRUE, TRUE),
  ('UY','2026-05-18','Batalla de las Piedras',      TRUE, TRUE),
  ('UY','2026-06-19','Natalicio de Jose Artigas',   TRUE, TRUE),
  ('UY','2026-07-18','Jura de la Constitucion',     TRUE, TRUE),
  ('UY','2026-08-25','Declaratoria de Independencia',TRUE,TRUE),
  ('UY','2026-10-12','Dia de la Raza',              TRUE, TRUE),
  ('UY','2026-11-02','Dia de los Difuntos',         TRUE, TRUE),
  ('UY','2026-12-25','Dia de la Familia',           TRUE, TRUE);
-- +goose StatementEnd

-- Paraguay
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('PY','2026-01-01','Ano Nuevo',                    TRUE, TRUE),
  ('PY','2026-03-01','Dia de los Heroes',            TRUE, TRUE),
  ('PY','2026-05-01','Dia del Trabajador',           TRUE, TRUE),
  ('PY','2026-05-14','Independencia Nacional',       TRUE, TRUE),
  ('PY','2026-05-15','Independencia Nacional',       TRUE, TRUE),
  ('PY','2026-06-12','Paz del Chaco',                TRUE, TRUE),
  ('PY','2026-08-15','Fundacion de Asuncion',        TRUE, TRUE),
  ('PY','2026-09-29','Victoria de Boqueron',         TRUE, TRUE),
  ('PY','2026-12-08','Virgen de Caacupe',            TRUE, TRUE),
  ('PY','2026-12-25','Navidad',                      TRUE, TRUE);
-- +goose StatementEnd

-- Panama
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('PA','2026-01-01','Ano Nuevo',                            TRUE, TRUE),
  ('PA','2026-01-09','Dia de los Martires',                  TRUE, TRUE),
  ('PA','2026-05-01','Dia del Trabajo',                      TRUE, TRUE),
  ('PA','2026-11-03','Separacion de Colombia',               TRUE, TRUE),
  ('PA','2026-11-04','Dia de los Simbolos Patrios',          TRUE, TRUE),
  ('PA','2026-11-05','Dia de Colon',                         TRUE, TRUE),
  ('PA','2026-11-10','Grito Independencia Villa Los Santos', TRUE, TRUE),
  ('PA','2026-11-28','Independencia de Espana',              TRUE, TRUE),
  ('PA','2026-12-08','Dia de las Madres',                    TRUE, TRUE),
  ('PA','2026-12-25','Navidad',                              TRUE, TRUE);
-- +goose StatementEnd

-- Costa Rica
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('CR','2026-01-01','Ano Nuevo',                     TRUE, TRUE),
  ('CR','2026-04-11','Dia de Juan Santamaria',        TRUE, TRUE),
  ('CR','2026-05-01','Dia del Trabajador',            TRUE, TRUE),
  ('CR','2026-07-25','Anexion del Partido de Nicoya', TRUE, TRUE),
  ('CR','2026-08-02','Virgen de los Angeles',         TRUE, TRUE),
  ('CR','2026-08-15','Dia de la Madre',               TRUE, TRUE),
  ('CR','2026-09-15','Dia de la Independencia',       TRUE, TRUE),
  ('CR','2026-12-01','Abolicion del Ejercito',        TRUE, TRUE),
  ('CR','2026-12-25','Navidad',                       TRUE, TRUE);
-- +goose StatementEnd

-- Republica Dominicana
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('DO','2026-01-01','Ano Nuevo',                      TRUE, TRUE),
  ('DO','2026-01-06','Dia de los Santos Reyes',        TRUE, TRUE),
  ('DO','2026-01-21','Virgen de la Altagracia',        TRUE, TRUE),
  ('DO','2026-01-26','Natalicio de Juan Pablo Duarte', TRUE, TRUE),
  ('DO','2026-02-27','Dia de la Independencia',        TRUE, TRUE),
  ('DO','2026-05-01','Dia del Trabajador',             TRUE, TRUE),
  ('DO','2026-08-16','Dia de la Restauracion',         TRUE, TRUE),
  ('DO','2026-09-24','Virgen de las Mercedes',         TRUE, TRUE),
  ('DO','2026-11-06','Dia de la Constitucion',         TRUE, TRUE),
  ('DO','2026-12-25','Navidad',                        TRUE, TRUE);
-- +goose StatementEnd

-- Guatemala
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('GT','2026-01-01','Ano Nuevo',                       TRUE, TRUE),
  ('GT','2026-05-01','Dia del Trabajo',                 TRUE, TRUE),
  ('GT','2026-06-30','Dia del Ejercito',                TRUE, TRUE),
  ('GT','2026-09-15','Dia de la Independencia',         TRUE, TRUE),
  ('GT','2026-10-20','Dia de la Revolucion',            TRUE, TRUE),
  ('GT','2026-11-01','Dia de Todos los Santos',         TRUE, TRUE),
  ('GT','2026-12-24','Nochebuena (medio dia)',          TRUE, TRUE),
  ('GT','2026-12-25','Navidad',                         TRUE, TRUE),
  ('GT','2026-12-31','Fin de Ano (medio dia)',          TRUE, TRUE);
-- +goose StatementEnd

-- Honduras
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('HN','2026-01-01','Ano Nuevo',                       TRUE, TRUE),
  ('HN','2026-04-14','Dia de las Americas',             TRUE, TRUE),
  ('HN','2026-05-01','Dia del Trabajo',                 TRUE, TRUE),
  ('HN','2026-09-15','Dia de la Independencia',         TRUE, TRUE),
  ('HN','2026-10-03','Dia del Soldado (Morazan)',       TRUE, TRUE),
  ('HN','2026-10-12','Dia de la Hispanidad (Colon)',    TRUE, TRUE),
  ('HN','2026-10-21','Dia de las Fuerzas Armadas',      TRUE, TRUE),
  ('HN','2026-12-25','Navidad',                         TRUE, TRUE);
-- +goose StatementEnd

-- Nicaragua
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('NI','2026-01-01','Ano Nuevo',                          TRUE, TRUE),
  ('NI','2026-05-01','Dia del Trabajo',                    TRUE, TRUE),
  ('NI','2026-07-19','Dia de la Revolucion Popular',       TRUE, TRUE),
  ('NI','2026-09-14','Batalla de San Jacinto',             TRUE, TRUE),
  ('NI','2026-09-15','Dia de la Independencia',            TRUE, TRUE),
  ('NI','2026-12-08','Purisima Concepcion',                TRUE, TRUE),
  ('NI','2026-12-25','Navidad',                            TRUE, TRUE);
-- +goose StatementEnd

-- El Salvador
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('SV','2026-01-01','Ano Nuevo',                   TRUE, TRUE),
  ('SV','2026-05-01','Dia del Trabajador',          TRUE, TRUE),
  ('SV','2026-05-10','Dia de las Madres',           TRUE, TRUE),
  ('SV','2026-06-17','Dia del Padre',               TRUE, TRUE),
  ('SV','2026-09-15','Dia de la Independencia',     TRUE, TRUE),
  ('SV','2026-11-02','Dia de los Difuntos',         TRUE, TRUE),
  ('SV','2026-12-25','Navidad',                     TRUE, TRUE);
-- +goose StatementEnd

-- Puerto Rico (feriados fijos estatales + federales no-lunes)
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('PR','2026-01-01','Ano Nuevo',                       TRUE, TRUE),
  ('PR','2026-01-06','Dia de los Santos Reyes',         TRUE, TRUE),
  ('PR','2026-03-22','Dia de la Emancipacion',          TRUE, TRUE),
  ('PR','2026-06-19','Juneteenth',                      TRUE, TRUE),
  ('PR','2026-07-04','Dia de la Independencia (USA)',   TRUE, TRUE),
  ('PR','2026-07-25','Dia de la Constitucion',          TRUE, TRUE),
  ('PR','2026-11-11','Dia de los Veteranos',            TRUE, TRUE),
  ('PR','2026-11-19','Dia del Descubrimiento',          TRUE, TRUE),
  ('PR','2026-12-25','Navidad',                         TRUE, TRUE);
-- +goose StatementEnd

-- Cuba
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('CU','2026-01-01','Triunfo de la Revolucion',       TRUE, TRUE),
  ('CU','2026-01-02','Dia de la Victoria',             TRUE, TRUE),
  ('CU','2026-05-01','Dia Internacional del Trabajo',  TRUE, TRUE),
  ('CU','2026-07-25','Conmemoracion Moncada',          TRUE, TRUE),
  ('CU','2026-07-26','Dia de la Rebeldia Nacional',    TRUE, TRUE),
  ('CU','2026-07-27','Conmemoracion Moncada',          TRUE, TRUE),
  ('CU','2026-10-10','Inicio Guerras Independencia',   TRUE, TRUE),
  ('CU','2026-12-25','Navidad',                        TRUE, TRUE);
-- +goose StatementEnd

-- Estados Unidos (federales FIJAS; moviles como Memorial Day, Labor Day, Thanksgiving se omiten)
-- +goose StatementBegin
INSERT INTO cfg."Holiday" ("CountryCode","HolidayDate","HolidayName","IsRecurring","IsActive") VALUES
  ('US','2026-01-01','New Year Day',           TRUE, TRUE),
  ('US','2026-06-19','Juneteenth',              TRUE, TRUE),
  ('US','2026-07-04','Independence Day',        TRUE, TRUE),
  ('US','2026-11-11','Veterans Day',            TRUE, TRUE),
  ('US','2026-12-25','Christmas Day',           TRUE, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM cfg."Holiday"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd
