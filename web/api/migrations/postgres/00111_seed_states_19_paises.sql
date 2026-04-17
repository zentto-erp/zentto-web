-- +goose Up

-- Seed cfg.State para 19 paises (LATAM + Caribe hispano + PR + US).
-- Excluye ES: cubierto por migracion 00110 del agente Espana.
-- Fuente: ISO 3166-2 + catalogos oficiales de cada pais.
-- Idempotente: DELETE + INSERT por (CountryCode, StateCode).

-- +goose StatementBegin
DELETE FROM cfg."State"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- Venezuela - 24 entidades (23 estados + Distrito Capital + Dependencias Federales)
-- Fuente: ISO 3166-2:VE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('VE','A','Distrito Capital',10,TRUE),
  ('VE','B','Anzoategui',20,TRUE),
  ('VE','C','Apure',30,TRUE),
  ('VE','D','Aragua',40,TRUE),
  ('VE','E','Barinas',50,TRUE),
  ('VE','F','Bolivar',60,TRUE),
  ('VE','G','Carabobo',70,TRUE),
  ('VE','H','Cojedes',80,TRUE),
  ('VE','I','Falcon',90,TRUE),
  ('VE','J','Guarico',100,TRUE),
  ('VE','K','Lara',110,TRUE),
  ('VE','L','Merida',120,TRUE),
  ('VE','M','Miranda',130,TRUE),
  ('VE','N','Monagas',140,TRUE),
  ('VE','O','Nueva Esparta',150,TRUE),
  ('VE','P','Portuguesa',160,TRUE),
  ('VE','R','Sucre',170,TRUE),
  ('VE','S','Tachira',180,TRUE),
  ('VE','T','Trujillo',190,TRUE),
  ('VE','U','Yaracuy',200,TRUE),
  ('VE','V','Zulia',210,TRUE),
  ('VE','W','Dependencias Federales',220,TRUE),
  ('VE','X','La Guaira',230,TRUE),
  ('VE','Y','Delta Amacuro',240,TRUE),
  ('VE','Z','Amazonas',250,TRUE);
-- +goose StatementEnd

-- Colombia - 32 departamentos + Bogota D.C.
-- Fuente: ISO 3166-2:CO + DANE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('CO','DC','Bogota D.C.',10,TRUE),
  ('CO','AMA','Amazonas',20,TRUE),
  ('CO','ANT','Antioquia',30,TRUE),
  ('CO','ARA','Arauca',40,TRUE),
  ('CO','ATL','Atlantico',50,TRUE),
  ('CO','BOL','Bolivar',60,TRUE),
  ('CO','BOY','Boyaca',70,TRUE),
  ('CO','CAL','Caldas',80,TRUE),
  ('CO','CAQ','Caqueta',90,TRUE),
  ('CO','CAS','Casanare',100,TRUE),
  ('CO','CAU','Cauca',110,TRUE),
  ('CO','CES','Cesar',120,TRUE),
  ('CO','CHO','Choco',130,TRUE),
  ('CO','COR','Cordoba',140,TRUE),
  ('CO','CUN','Cundinamarca',150,TRUE),
  ('CO','GUA','Guainia',160,TRUE),
  ('CO','GUV','Guaviare',170,TRUE),
  ('CO','HUI','Huila',180,TRUE),
  ('CO','LAG','La Guajira',190,TRUE),
  ('CO','MAG','Magdalena',200,TRUE),
  ('CO','MET','Meta',210,TRUE),
  ('CO','NAR','Narino',220,TRUE),
  ('CO','NSA','Norte de Santander',230,TRUE),
  ('CO','PUT','Putumayo',240,TRUE),
  ('CO','QUI','Quindio',250,TRUE),
  ('CO','RIS','Risaralda',260,TRUE),
  ('CO','SAN','Santander',270,TRUE),
  ('CO','SAP','San Andres y Providencia',280,TRUE),
  ('CO','SUC','Sucre',290,TRUE),
  ('CO','TOL','Tolima',300,TRUE),
  ('CO','VAC','Valle del Cauca',310,TRUE),
  ('CO','VAU','Vaupes',320,TRUE),
  ('CO','VID','Vichada',330,TRUE);
-- +goose StatementEnd

-- Mexico - 32 entidades federativas
-- Fuente: ISO 3166-2:MX + INEGI
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('MX','CMX','Ciudad de Mexico',10,TRUE),
  ('MX','AGU','Aguascalientes',20,TRUE),
  ('MX','BCN','Baja California',30,TRUE),
  ('MX','BCS','Baja California Sur',40,TRUE),
  ('MX','CAM','Campeche',50,TRUE),
  ('MX','COA','Coahuila',60,TRUE),
  ('MX','COL','Colima',70,TRUE),
  ('MX','CHP','Chiapas',80,TRUE),
  ('MX','CHH','Chihuahua',90,TRUE),
  ('MX','DUR','Durango',100,TRUE),
  ('MX','GUA','Guanajuato',110,TRUE),
  ('MX','GRO','Guerrero',120,TRUE),
  ('MX','HID','Hidalgo',130,TRUE),
  ('MX','JAL','Jalisco',140,TRUE),
  ('MX','MEX','Estado de Mexico',150,TRUE),
  ('MX','MIC','Michoacan',160,TRUE),
  ('MX','MOR','Morelos',170,TRUE),
  ('MX','NAY','Nayarit',180,TRUE),
  ('MX','NLE','Nuevo Leon',190,TRUE),
  ('MX','OAX','Oaxaca',200,TRUE),
  ('MX','PUE','Puebla',210,TRUE),
  ('MX','QUE','Queretaro',220,TRUE),
  ('MX','ROO','Quintana Roo',230,TRUE),
  ('MX','SLP','San Luis Potosi',240,TRUE),
  ('MX','SIN','Sinaloa',250,TRUE),
  ('MX','SON','Sonora',260,TRUE),
  ('MX','TAB','Tabasco',270,TRUE),
  ('MX','TAM','Tamaulipas',280,TRUE),
  ('MX','TLA','Tlaxcala',290,TRUE),
  ('MX','VER','Veracruz',300,TRUE),
  ('MX','YUC','Yucatan',310,TRUE),
  ('MX','ZAC','Zacatecas',320,TRUE);
-- +goose StatementEnd

-- Argentina - 24 provincias (23 + CABA)
-- Fuente: ISO 3166-2:AR
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('AR','C','Ciudad Autonoma de Buenos Aires',10,TRUE),
  ('AR','B','Buenos Aires',20,TRUE),
  ('AR','K','Catamarca',30,TRUE),
  ('AR','H','Chaco',40,TRUE),
  ('AR','U','Chubut',50,TRUE),
  ('AR','X','Cordoba',60,TRUE),
  ('AR','W','Corrientes',70,TRUE),
  ('AR','E','Entre Rios',80,TRUE),
  ('AR','P','Formosa',90,TRUE),
  ('AR','Y','Jujuy',100,TRUE),
  ('AR','L','La Pampa',110,TRUE),
  ('AR','F','La Rioja',120,TRUE),
  ('AR','M','Mendoza',130,TRUE),
  ('AR','N','Misiones',140,TRUE),
  ('AR','Q','Neuquen',150,TRUE),
  ('AR','R','Rio Negro',160,TRUE),
  ('AR','A','Salta',170,TRUE),
  ('AR','J','San Juan',180,TRUE),
  ('AR','D','San Luis',190,TRUE),
  ('AR','Z','Santa Cruz',200,TRUE),
  ('AR','S','Santa Fe',210,TRUE),
  ('AR','G','Santiago del Estero',220,TRUE),
  ('AR','V','Tierra del Fuego',230,TRUE),
  ('AR','T','Tucuman',240,TRUE);
-- +goose StatementEnd

-- Chile - 16 regiones
-- Fuente: ISO 3166-2:CL + SUBDERE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('CL','RM','Region Metropolitana de Santiago',10,TRUE),
  ('CL','AP','Arica y Parinacota',20,TRUE),
  ('CL','TA','Tarapaca',30,TRUE),
  ('CL','AN','Antofagasta',40,TRUE),
  ('CL','AT','Atacama',50,TRUE),
  ('CL','CO','Coquimbo',60,TRUE),
  ('CL','VS','Valparaiso',70,TRUE),
  ('CL','LI','Libertador General Bernardo OHiggins',80,TRUE),
  ('CL','ML','Maule',90,TRUE),
  ('CL','NB','Nuble',100,TRUE),
  ('CL','BI','Biobio',110,TRUE),
  ('CL','AR','La Araucania',120,TRUE),
  ('CL','LR','Los Rios',130,TRUE),
  ('CL','LL','Los Lagos',140,TRUE),
  ('CL','AI','Aysen del General Carlos Ibanez del Campo',150,TRUE),
  ('CL','MA','Magallanes y de la Antartica Chilena',160,TRUE);
-- +goose StatementEnd

-- Peru - 25 departamentos + Provincia Constitucional del Callao
-- Fuente: ISO 3166-2:PE + INEI
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('PE','LMA','Lima Metropolitana',10,TRUE),
  ('PE','AMA','Amazonas',20,TRUE),
  ('PE','ANC','Ancash',30,TRUE),
  ('PE','APU','Apurimac',40,TRUE),
  ('PE','ARE','Arequipa',50,TRUE),
  ('PE','AYA','Ayacucho',60,TRUE),
  ('PE','CAJ','Cajamarca',70,TRUE),
  ('PE','CAL','Callao',80,TRUE),
  ('PE','CUS','Cusco',90,TRUE),
  ('PE','HUV','Huancavelica',100,TRUE),
  ('PE','HUC','Huanuco',110,TRUE),
  ('PE','ICA','Ica',120,TRUE),
  ('PE','JUN','Junin',130,TRUE),
  ('PE','LAL','La Libertad',140,TRUE),
  ('PE','LAM','Lambayeque',150,TRUE),
  ('PE','LIM','Lima',160,TRUE),
  ('PE','LOR','Loreto',170,TRUE),
  ('PE','MDD','Madre de Dios',180,TRUE),
  ('PE','MOQ','Moquegua',190,TRUE),
  ('PE','PAS','Pasco',200,TRUE),
  ('PE','PIU','Piura',210,TRUE),
  ('PE','PUN','Puno',220,TRUE),
  ('PE','SAM','San Martin',230,TRUE),
  ('PE','TAC','Tacna',240,TRUE),
  ('PE','TUM','Tumbes',250,TRUE),
  ('PE','UCA','Ucayali',260,TRUE);
-- +goose StatementEnd

-- Ecuador - 24 provincias
-- Fuente: ISO 3166-2:EC + INEC
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('EC','P','Pichincha',10,TRUE),
  ('EC','G','Guayas',20,TRUE),
  ('EC','A','Azuay',30,TRUE),
  ('EC','B','Bolivar',40,TRUE),
  ('EC','F','Canar',50,TRUE),
  ('EC','C','Carchi',60,TRUE),
  ('EC','H','Chimborazo',70,TRUE),
  ('EC','X','Cotopaxi',80,TRUE),
  ('EC','O','El Oro',90,TRUE),
  ('EC','E','Esmeraldas',100,TRUE),
  ('EC','W','Galapagos',110,TRUE),
  ('EC','I','Imbabura',120,TRUE),
  ('EC','L','Loja',130,TRUE),
  ('EC','R','Los Rios',140,TRUE),
  ('EC','M','Manabi',150,TRUE),
  ('EC','S','Morona Santiago',160,TRUE),
  ('EC','N','Napo',170,TRUE),
  ('EC','D','Orellana',180,TRUE),
  ('EC','Y','Pastaza',190,TRUE),
  ('EC','SE','Santa Elena',200,TRUE),
  ('EC','SD','Santo Domingo de los Tsachilas',210,TRUE),
  ('EC','U','Sucumbios',220,TRUE),
  ('EC','T','Tungurahua',230,TRUE),
  ('EC','Z','Zamora Chinchipe',240,TRUE);
-- +goose StatementEnd

-- Bolivia - 9 departamentos
-- Fuente: ISO 3166-2:BO + INE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('BO','L','La Paz',10,TRUE),
  ('BO','C','Cochabamba',20,TRUE),
  ('BO','S','Santa Cruz',30,TRUE),
  ('BO','H','Chuquisaca',40,TRUE),
  ('BO','O','Oruro',50,TRUE),
  ('BO','P','Potosi',60,TRUE),
  ('BO','T','Tarija',70,TRUE),
  ('BO','B','Beni',80,TRUE),
  ('BO','N','Pando',90,TRUE);
-- +goose StatementEnd

-- Uruguay - 19 departamentos
-- Fuente: ISO 3166-2:UY + INE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('UY','MO','Montevideo',10,TRUE),
  ('UY','AR','Artigas',20,TRUE),
  ('UY','CA','Canelones',30,TRUE),
  ('UY','CL','Cerro Largo',40,TRUE),
  ('UY','CO','Colonia',50,TRUE),
  ('UY','DU','Durazno',60,TRUE),
  ('UY','FS','Flores',70,TRUE),
  ('UY','FD','Florida',80,TRUE),
  ('UY','LA','Lavalleja',90,TRUE),
  ('UY','MA','Maldonado',100,TRUE),
  ('UY','PA','Paysandu',110,TRUE),
  ('UY','RN','Rio Negro',120,TRUE),
  ('UY','RV','Rivera',130,TRUE),
  ('UY','RO','Rocha',140,TRUE),
  ('UY','SA','Salto',150,TRUE),
  ('UY','SJ','San Jose',160,TRUE),
  ('UY','SO','Soriano',170,TRUE),
  ('UY','TA','Tacuarembo',180,TRUE),
  ('UY','TT','Treinta y Tres',190,TRUE);
-- +goose StatementEnd

-- Paraguay - 18 (17 departamentos + Asuncion capital)
-- Fuente: ISO 3166-2:PY + DGEEC
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('PY','ASU','Asuncion',10,TRUE),
  ('PY','11','Central',20,TRUE),
  ('PY','1','Concepcion',30,TRUE),
  ('PY','2','San Pedro',40,TRUE),
  ('PY','3','Cordillera',50,TRUE),
  ('PY','4','Guaira',60,TRUE),
  ('PY','5','Caaguazu',70,TRUE),
  ('PY','6','Caazapa',80,TRUE),
  ('PY','7','Itapua',90,TRUE),
  ('PY','8','Misiones',100,TRUE),
  ('PY','9','Paraguari',110,TRUE),
  ('PY','10','Alto Parana',120,TRUE),
  ('PY','12','Neembucu',130,TRUE),
  ('PY','13','Amambay',140,TRUE),
  ('PY','14','Canindeyu',150,TRUE),
  ('PY','15','Presidente Hayes',160,TRUE),
  ('PY','16','Alto Paraguay',170,TRUE),
  ('PY','19','Boqueron',180,TRUE);
-- +goose StatementEnd

-- Panama - 13 (10 provincias + 3 comarcas indigenas)
-- Fuente: ISO 3166-2:PA + INEC
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('PA','8','Panama',10,TRUE),
  ('PA','10','Panama Oeste',20,TRUE),
  ('PA','1','Bocas del Toro',30,TRUE),
  ('PA','2','Cocle',40,TRUE),
  ('PA','3','Colon',50,TRUE),
  ('PA','4','Chiriqui',60,TRUE),
  ('PA','5','Darien',70,TRUE),
  ('PA','6','Herrera',80,TRUE),
  ('PA','7','Los Santos',90,TRUE),
  ('PA','9','Veraguas',100,TRUE),
  ('PA','EM','Embera-Wounaan',110,TRUE),
  ('PA','KY','Guna Yala',120,TRUE),
  ('PA','NB','Ngabe-Bugle',130,TRUE);
-- +goose StatementEnd

-- Costa Rica - 7 provincias
-- Fuente: ISO 3166-2:CR + INEC
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('CR','SJ','San Jose',10,TRUE),
  ('CR','A','Alajuela',20,TRUE),
  ('CR','C','Cartago',30,TRUE),
  ('CR','H','Heredia',40,TRUE),
  ('CR','G','Guanacaste',50,TRUE),
  ('CR','P','Puntarenas',60,TRUE),
  ('CR','L','Limon',70,TRUE);
-- +goose StatementEnd

-- Republica Dominicana - 32 (31 provincias + Distrito Nacional)
-- Fuente: ISO 3166-2:DO + ONE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('DO','01','Distrito Nacional',10,TRUE),
  ('DO','32','Santo Domingo',20,TRUE),
  ('DO','02','Azua',30,TRUE),
  ('DO','03','Baoruco',40,TRUE),
  ('DO','04','Barahona',50,TRUE),
  ('DO','05','Dajabon',60,TRUE),
  ('DO','06','Duarte',70,TRUE),
  ('DO','07','Elias Pina',80,TRUE),
  ('DO','08','El Seibo',90,TRUE),
  ('DO','09','Espaillat',100,TRUE),
  ('DO','10','Independencia',110,TRUE),
  ('DO','11','La Altagracia',120,TRUE),
  ('DO','12','La Romana',130,TRUE),
  ('DO','13','La Vega',140,TRUE),
  ('DO','14','Maria Trinidad Sanchez',150,TRUE),
  ('DO','15','Monte Cristi',160,TRUE),
  ('DO','16','Pedernales',170,TRUE),
  ('DO','17','Peravia',180,TRUE),
  ('DO','18','Puerto Plata',190,TRUE),
  ('DO','19','Hermanas Mirabal',200,TRUE),
  ('DO','20','Samana',210,TRUE),
  ('DO','21','San Cristobal',220,TRUE),
  ('DO','22','San Juan',230,TRUE),
  ('DO','23','San Pedro de Macoris',240,TRUE),
  ('DO','24','Sanchez Ramirez',250,TRUE),
  ('DO','25','Santiago',260,TRUE),
  ('DO','26','Santiago Rodriguez',270,TRUE),
  ('DO','27','Valverde',280,TRUE),
  ('DO','28','Monsenor Nouel',290,TRUE),
  ('DO','29','Monte Plata',300,TRUE),
  ('DO','30','Hato Mayor',310,TRUE),
  ('DO','31','San Jose de Ocoa',320,TRUE);
-- +goose StatementEnd

-- Guatemala - 22 departamentos
-- Fuente: ISO 3166-2:GT + INE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('GT','GU','Guatemala',10,TRUE),
  ('GT','AV','Alta Verapaz',20,TRUE),
  ('GT','BV','Baja Verapaz',30,TRUE),
  ('GT','CM','Chimaltenango',40,TRUE),
  ('GT','CQ','Chiquimula',50,TRUE),
  ('GT','PR','El Progreso',60,TRUE),
  ('GT','ES','Escuintla',70,TRUE),
  ('GT','HU','Huehuetenango',80,TRUE),
  ('GT','IZ','Izabal',90,TRUE),
  ('GT','JA','Jalapa',100,TRUE),
  ('GT','JU','Jutiapa',110,TRUE),
  ('GT','PE','Peten',120,TRUE),
  ('GT','QZ','Quetzaltenango',130,TRUE),
  ('GT','QC','Quiche',140,TRUE),
  ('GT','RE','Retalhuleu',150,TRUE),
  ('GT','SA','Sacatepequez',160,TRUE),
  ('GT','SM','San Marcos',170,TRUE),
  ('GT','SR','Santa Rosa',180,TRUE),
  ('GT','SO','Solola',190,TRUE),
  ('GT','SU','Suchitepequez',200,TRUE),
  ('GT','TO','Totonicapan',210,TRUE),
  ('GT','ZA','Zacapa',220,TRUE);
-- +goose StatementEnd

-- Honduras - 18 departamentos
-- Fuente: ISO 3166-2:HN + INE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('HN','FM','Francisco Morazan',10,TRUE),
  ('HN','CR','Cortes',20,TRUE),
  ('HN','AT','Atlantida',30,TRUE),
  ('HN','CH','Choluteca',40,TRUE),
  ('HN','CL','Colon',50,TRUE),
  ('HN','CM','Comayagua',60,TRUE),
  ('HN','CP','Copan',70,TRUE),
  ('HN','EP','El Paraiso',80,TRUE),
  ('HN','GD','Gracias a Dios',90,TRUE),
  ('HN','IN','Intibuca',100,TRUE),
  ('HN','IB','Islas de la Bahia',110,TRUE),
  ('HN','LP','La Paz',120,TRUE),
  ('HN','LE','Lempira',130,TRUE),
  ('HN','OC','Ocotepeque',140,TRUE),
  ('HN','OL','Olancho',150,TRUE),
  ('HN','SB','Santa Barbara',160,TRUE),
  ('HN','VA','Valle',170,TRUE),
  ('HN','YO','Yoro',180,TRUE);
-- +goose StatementEnd

-- Nicaragua - 17 (15 departamentos + 2 regiones autonomas del Caribe)
-- Fuente: ISO 3166-2:NI + INIDE
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('NI','MN','Managua',10,TRUE),
  ('NI','BO','Boaco',20,TRUE),
  ('NI','CA','Carazo',30,TRUE),
  ('NI','CI','Chinandega',40,TRUE),
  ('NI','CO','Chontales',50,TRUE),
  ('NI','ES','Esteli',60,TRUE),
  ('NI','GR','Granada',70,TRUE),
  ('NI','JI','Jinotega',80,TRUE),
  ('NI','LE','Leon',90,TRUE),
  ('NI','MD','Madriz',100,TRUE),
  ('NI','MS','Masaya',110,TRUE),
  ('NI','MT','Matagalpa',120,TRUE),
  ('NI','NS','Nueva Segovia',130,TRUE),
  ('NI','RI','Rivas',140,TRUE),
  ('NI','SJ','Rio San Juan',150,TRUE),
  ('NI','AN','Region Autonoma Costa Caribe Norte',160,TRUE),
  ('NI','AS','Region Autonoma Costa Caribe Sur',170,TRUE);
-- +goose StatementEnd

-- El Salvador - 14 departamentos
-- Fuente: ISO 3166-2:SV + DIGESTYC
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('SV','SS','San Salvador',10,TRUE),
  ('SV','AH','Ahuachapan',20,TRUE),
  ('SV','CA','Cabanas',30,TRUE),
  ('SV','CH','Chalatenango',40,TRUE),
  ('SV','CU','Cuscatlan',50,TRUE),
  ('SV','LI','La Libertad',60,TRUE),
  ('SV','PA','La Paz',70,TRUE),
  ('SV','UN','La Union',80,TRUE),
  ('SV','MO','Morazan',90,TRUE),
  ('SV','SM','San Miguel',100,TRUE),
  ('SV','SV','San Vicente',110,TRUE),
  ('SV','SA','Santa Ana',120,TRUE),
  ('SV','SO','Sonsonate',130,TRUE),
  ('SV','US','Usulutan',140,TRUE);
-- +goose StatementEnd

-- Puerto Rico - 78 municipios
-- Fuente: ISO 3166-2:PR + Junta de Planificacion PR
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('PR','001','Adjuntas',10,TRUE),
  ('PR','003','Aguada',20,TRUE),
  ('PR','005','Aguadilla',30,TRUE),
  ('PR','007','Aguas Buenas',40,TRUE),
  ('PR','009','Aibonito',50,TRUE),
  ('PR','011','Anasco',60,TRUE),
  ('PR','013','Arecibo',70,TRUE),
  ('PR','015','Arroyo',80,TRUE),
  ('PR','017','Barceloneta',90,TRUE),
  ('PR','019','Barranquitas',100,TRUE),
  ('PR','021','Bayamon',110,TRUE),
  ('PR','023','Cabo Rojo',120,TRUE),
  ('PR','025','Caguas',130,TRUE),
  ('PR','027','Camuy',140,TRUE),
  ('PR','029','Canovanas',150,TRUE),
  ('PR','031','Carolina',160,TRUE),
  ('PR','033','Catano',170,TRUE),
  ('PR','035','Cayey',180,TRUE),
  ('PR','037','Ceiba',190,TRUE),
  ('PR','039','Ciales',200,TRUE),
  ('PR','041','Cidra',210,TRUE),
  ('PR','043','Coamo',220,TRUE),
  ('PR','045','Comerio',230,TRUE),
  ('PR','047','Corozal',240,TRUE),
  ('PR','049','Culebra',250,TRUE),
  ('PR','051','Dorado',260,TRUE),
  ('PR','053','Fajardo',270,TRUE),
  ('PR','054','Florida',280,TRUE),
  ('PR','055','Guanica',290,TRUE),
  ('PR','057','Guayama',300,TRUE),
  ('PR','059','Guayanilla',310,TRUE),
  ('PR','061','Guaynabo',320,TRUE),
  ('PR','063','Gurabo',330,TRUE),
  ('PR','065','Hatillo',340,TRUE),
  ('PR','067','Hormigueros',350,TRUE),
  ('PR','069','Humacao',360,TRUE),
  ('PR','071','Isabela',370,TRUE),
  ('PR','073','Jayuya',380,TRUE),
  ('PR','075','Juana Diaz',390,TRUE),
  ('PR','077','Juncos',400,TRUE),
  ('PR','079','Lajas',410,TRUE),
  ('PR','081','Lares',420,TRUE),
  ('PR','083','Las Marias',430,TRUE),
  ('PR','085','Las Piedras',440,TRUE),
  ('PR','087','Loiza',450,TRUE),
  ('PR','089','Luquillo',460,TRUE),
  ('PR','091','Manati',470,TRUE),
  ('PR','093','Maricao',480,TRUE),
  ('PR','095','Maunabo',490,TRUE),
  ('PR','097','Mayaguez',500,TRUE),
  ('PR','099','Moca',510,TRUE),
  ('PR','101','Morovis',520,TRUE),
  ('PR','103','Naguabo',530,TRUE),
  ('PR','105','Naranjito',540,TRUE),
  ('PR','107','Orocovis',550,TRUE),
  ('PR','109','Patillas',560,TRUE),
  ('PR','111','Penuelas',570,TRUE),
  ('PR','113','Ponce',580,TRUE),
  ('PR','115','Quebradillas',590,TRUE),
  ('PR','117','Rincon',600,TRUE),
  ('PR','119','Rio Grande',610,TRUE),
  ('PR','121','Sabana Grande',620,TRUE),
  ('PR','123','Salinas',630,TRUE),
  ('PR','125','San German',640,TRUE),
  ('PR','127','San Juan',650,TRUE),
  ('PR','129','San Lorenzo',660,TRUE),
  ('PR','131','San Sebastian',670,TRUE),
  ('PR','133','Santa Isabel',680,TRUE),
  ('PR','135','Toa Alta',690,TRUE),
  ('PR','137','Toa Baja',700,TRUE),
  ('PR','139','Trujillo Alto',710,TRUE),
  ('PR','141','Utuado',720,TRUE),
  ('PR','143','Vega Alta',730,TRUE),
  ('PR','145','Vega Baja',740,TRUE),
  ('PR','147','Vieques',750,TRUE),
  ('PR','149','Villalba',760,TRUE),
  ('PR','151','Yabucoa',770,TRUE),
  ('PR','153','Yauco',780,TRUE);
-- +goose StatementEnd

-- Cuba - 16 (15 provincias + Municipio Especial Isla de la Juventud)
-- Fuente: ISO 3166-2:CU + ONEI
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('CU','03','La Habana',10,TRUE),
  ('CU','01','Pinar del Rio',20,TRUE),
  ('CU','02','Artemisa',30,TRUE),
  ('CU','04','Mayabeque',40,TRUE),
  ('CU','05','Matanzas',50,TRUE),
  ('CU','06','Villa Clara',60,TRUE),
  ('CU','07','Cienfuegos',70,TRUE),
  ('CU','08','Sancti Spiritus',80,TRUE),
  ('CU','09','Ciego de Avila',90,TRUE),
  ('CU','10','Camaguey',100,TRUE),
  ('CU','11','Las Tunas',110,TRUE),
  ('CU','12','Holguin',120,TRUE),
  ('CU','13','Granma',130,TRUE),
  ('CU','14','Santiago de Cuba',140,TRUE),
  ('CU','15','Guantanamo',150,TRUE),
  ('CU','99','Isla de la Juventud',160,TRUE);
-- +goose StatementEnd

-- Estados Unidos - 50 estados + Distrito de Columbia
-- Fuente: ISO 3166-2:US + USPS
-- +goose StatementBegin
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder","IsActive") VALUES
  ('US','AL','Alabama',10,TRUE),
  ('US','AK','Alaska',20,TRUE),
  ('US','AZ','Arizona',30,TRUE),
  ('US','AR','Arkansas',40,TRUE),
  ('US','CA','California',50,TRUE),
  ('US','CO','Colorado',60,TRUE),
  ('US','CT','Connecticut',70,TRUE),
  ('US','DE','Delaware',80,TRUE),
  ('US','DC','District of Columbia',90,TRUE),
  ('US','FL','Florida',100,TRUE),
  ('US','GA','Georgia',110,TRUE),
  ('US','HI','Hawaii',120,TRUE),
  ('US','ID','Idaho',130,TRUE),
  ('US','IL','Illinois',140,TRUE),
  ('US','IN','Indiana',150,TRUE),
  ('US','IA','Iowa',160,TRUE),
  ('US','KS','Kansas',170,TRUE),
  ('US','KY','Kentucky',180,TRUE),
  ('US','LA','Louisiana',190,TRUE),
  ('US','ME','Maine',200,TRUE),
  ('US','MD','Maryland',210,TRUE),
  ('US','MA','Massachusetts',220,TRUE),
  ('US','MI','Michigan',230,TRUE),
  ('US','MN','Minnesota',240,TRUE),
  ('US','MS','Mississippi',250,TRUE),
  ('US','MO','Missouri',260,TRUE),
  ('US','MT','Montana',270,TRUE),
  ('US','NE','Nebraska',280,TRUE),
  ('US','NV','Nevada',290,TRUE),
  ('US','NH','New Hampshire',300,TRUE),
  ('US','NJ','New Jersey',310,TRUE),
  ('US','NM','New Mexico',320,TRUE),
  ('US','NY','New York',330,TRUE),
  ('US','NC','North Carolina',340,TRUE),
  ('US','ND','North Dakota',350,TRUE),
  ('US','OH','Ohio',360,TRUE),
  ('US','OK','Oklahoma',370,TRUE),
  ('US','OR','Oregon',380,TRUE),
  ('US','PA','Pennsylvania',390,TRUE),
  ('US','RI','Rhode Island',400,TRUE),
  ('US','SC','South Carolina',410,TRUE),
  ('US','SD','South Dakota',420,TRUE),
  ('US','TN','Tennessee',430,TRUE),
  ('US','TX','Texas',440,TRUE),
  ('US','UT','Utah',450,TRUE),
  ('US','VT','Vermont',460,TRUE),
  ('US','VA','Virginia',470,TRUE),
  ('US','WA','Washington',480,TRUE),
  ('US','WV','West Virginia',490,TRUE),
  ('US','WI','Wisconsin',500,TRUE),
  ('US','WY','Wyoming',510,TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM cfg."State"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd
