-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Catálogo universal de países (ISO 3166-1): 195 países con prefijo telefónico,
-- ISO2/ISO3, emoji bandera y orden de visualización.
--
-- Regla: TODO selector de país en Zentto (registro, landing, ERP, verticales)
-- debe listar los 195 países. Prefijos telefónicos fuente única en BD.
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1) Extender cfg."Country" con columnas que faltaban ──────────────────────
ALTER TABLE cfg."Country"
    ADD COLUMN IF NOT EXISTS "Iso3"        VARCHAR(3)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PhonePrefix" VARCHAR(10) NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "FlagEmoji"   VARCHAR(8)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "SortOrder"   INTEGER     NOT NULL DEFAULT 100;

CREATE INDEX IF NOT EXISTS idx_country_iso3        ON cfg."Country" ("Iso3");
CREATE INDEX IF NOT EXISTS idx_country_phone       ON cfg."Country" ("PhonePrefix");
CREATE INDEX IF NOT EXISTS idx_country_active_sort ON cfg."Country" ("IsActive", "SortOrder", "CountryName");

-- ── 2) Seed de 195 países (ISO 3166-1)
-- CountryCode (ISO2), CountryName, Iso3, CurrencyCode, PhonePrefix, FlagEmoji,
-- TaxAuthorityCode='', FiscalIdName='', IsActive=TRUE, SortOrder=100
-- Los países ya existentes (VE, CO, MX, US, ES) se actualizan sin perder TaxAuthority/FiscalIdName.

INSERT INTO cfg."Country" ("CountryCode","CountryName","Iso3","CurrencyCode","PhonePrefix","FlagEmoji","TaxAuthorityCode","FiscalIdName","IsActive","SortOrder") VALUES
('AF','Afganistán','AFG','AFN','+93','🇦🇫','','',TRUE,100),
('AL','Albania','ALB','ALL','+355','🇦🇱','','',TRUE,100),
('DE','Alemania','DEU','EUR','+49','🇩🇪','','',TRUE,100),
('AD','Andorra','AND','EUR','+376','🇦🇩','','',TRUE,100),
('AO','Angola','AGO','AOA','+244','🇦🇴','','',TRUE,100),
('AI','Anguila','AIA','XCD','+1264','🇦🇮','','',TRUE,100),
('AG','Antigua y Barbuda','ATG','XCD','+1268','🇦🇬','','',TRUE,100),
('SA','Arabia Saudita','SAU','SAR','+966','🇸🇦','','',TRUE,100),
('DZ','Argelia','DZA','DZD','+213','🇩🇿','','',TRUE,100),
('AR','Argentina','ARG','ARS','+54','🇦🇷','AFIP','CUIT',TRUE,20),
('AM','Armenia','ARM','AMD','+374','🇦🇲','','',TRUE,100),
('AW','Aruba','ABW','AWG','+297','🇦🇼','','',TRUE,100),
('AU','Australia','AUS','AUD','+61','🇦🇺','','',TRUE,100),
('AT','Austria','AUT','EUR','+43','🇦🇹','','',TRUE,100),
('AZ','Azerbaiyán','AZE','AZN','+994','🇦🇿','','',TRUE,100),
('BS','Bahamas','BHS','BSD','+1242','🇧🇸','','',TRUE,100),
('BH','Baréin','BHR','BHD','+973','🇧🇭','','',TRUE,100),
('BD','Bangladés','BGD','BDT','+880','🇧🇩','','',TRUE,100),
('BB','Barbados','BRB','BBD','+1246','🇧🇧','','',TRUE,100),
('BE','Bélgica','BEL','EUR','+32','🇧🇪','','',TRUE,100),
('BZ','Belice','BLZ','BZD','+501','🇧🇿','','',TRUE,100),
('BJ','Benín','BEN','XOF','+229','🇧🇯','','',TRUE,100),
('BM','Bermudas','BMU','BMD','+1441','🇧🇲','','',TRUE,100),
('BY','Bielorrusia','BLR','BYN','+375','🇧🇾','','',TRUE,100),
('BO','Bolivia','BOL','BOB','+591','🇧🇴','','',TRUE,30),
('BA','Bosnia y Herzegovina','BIH','BAM','+387','🇧🇦','','',TRUE,100),
('BW','Botsuana','BWA','BWP','+267','🇧🇼','','',TRUE,100),
('BR','Brasil','BRA','BRL','+55','🇧🇷','RFB','CNPJ',TRUE,20),
('BN','Brunéi','BRN','BND','+673','🇧🇳','','',TRUE,100),
('BG','Bulgaria','BGR','BGN','+359','🇧🇬','','',TRUE,100),
('BF','Burkina Faso','BFA','XOF','+226','🇧🇫','','',TRUE,100),
('BI','Burundi','BDI','BIF','+257','🇧🇮','','',TRUE,100),
('BT','Bután','BTN','BTN','+975','🇧🇹','','',TRUE,100),
('CV','Cabo Verde','CPV','CVE','+238','🇨🇻','','',TRUE,100),
('KH','Camboya','KHM','KHR','+855','🇰🇭','','',TRUE,100),
('CM','Camerún','CMR','XAF','+237','🇨🇲','','',TRUE,100),
('CA','Canadá','CAN','CAD','+1','🇨🇦','','',TRUE,50),
('QA','Catar','QAT','QAR','+974','🇶🇦','','',TRUE,100),
('TD','Chad','TCD','XAF','+235','🇹🇩','','',TRUE,100),
('CL','Chile','CHL','CLP','+56','🇨🇱','SII','RUT',TRUE,20),
('CN','China','CHN','CNY','+86','🇨🇳','','',TRUE,40),
('CY','Chipre','CYP','EUR','+357','🇨🇾','','',TRUE,100),
('VA','Ciudad del Vaticano','VAT','EUR','+379','🇻🇦','','',TRUE,100),
('CO','Colombia','COL','COP','+57','🇨🇴','DIAN','NIT',TRUE,10),
('KM','Comoras','COM','KMF','+269','🇰🇲','','',TRUE,100),
('CG','Congo','COG','XAF','+242','🇨🇬','','',TRUE,100),
('CD','Congo (RDC)','COD','CDF','+243','🇨🇩','','',TRUE,100),
('KR','Corea del Sur','KOR','KRW','+82','🇰🇷','','',TRUE,100),
('KP','Corea del Norte','PRK','KPW','+850','🇰🇵','','',TRUE,100),
('CI','Costa de Marfil','CIV','XOF','+225','🇨🇮','','',TRUE,100),
('CR','Costa Rica','CRI','CRC','+506','🇨🇷','','',TRUE,30),
('HR','Croacia','HRV','EUR','+385','🇭🇷','','',TRUE,100),
('CU','Cuba','CUB','CUP','+53','🇨🇺','','',TRUE,100),
('CW','Curazao','CUW','ANG','+599','🇨🇼','','',TRUE,100),
('DK','Dinamarca','DNK','DKK','+45','🇩🇰','','',TRUE,100),
('DM','Dominica','DMA','XCD','+1767','🇩🇲','','',TRUE,100),
('EC','Ecuador','ECU','USD','+593','🇪🇨','SRI','RUC',TRUE,30),
('EG','Egipto','EGY','EGP','+20','🇪🇬','','',TRUE,100),
('SV','El Salvador','SLV','USD','+503','🇸🇻','','NIT',TRUE,30),
('AE','Emiratos Árabes Unidos','ARE','AED','+971','🇦🇪','','',TRUE,100),
('ER','Eritrea','ERI','ERN','+291','🇪🇷','','',TRUE,100),
('SK','Eslovaquia','SVK','EUR','+421','🇸🇰','','',TRUE,100),
('SI','Eslovenia','SVN','EUR','+386','🇸🇮','','',TRUE,100),
('ES','España','ESP','EUR','+34','🇪🇸','AEAT','NIF',TRUE,20),
('US','Estados Unidos','USA','USD','+1','🇺🇸','IRS','EIN',TRUE,10),
('EE','Estonia','EST','EUR','+372','🇪🇪','','',TRUE,100),
('ET','Etiopía','ETH','ETB','+251','🇪🇹','','',TRUE,100),
('PH','Filipinas','PHL','PHP','+63','🇵🇭','','',TRUE,100),
('FI','Finlandia','FIN','EUR','+358','🇫🇮','','',TRUE,100),
('FJ','Fiyi','FJI','FJD','+679','🇫🇯','','',TRUE,100),
('FR','Francia','FRA','EUR','+33','🇫🇷','','',TRUE,50),
('GA','Gabón','GAB','XAF','+241','🇬🇦','','',TRUE,100),
('GM','Gambia','GMB','GMD','+220','🇬🇲','','',TRUE,100),
('GE','Georgia','GEO','GEL','+995','🇬🇪','','',TRUE,100),
('GH','Ghana','GHA','GHS','+233','🇬🇭','','',TRUE,100),
('GI','Gibraltar','GIB','GIP','+350','🇬🇮','','',TRUE,100),
('GD','Granada','GRD','XCD','+1473','🇬🇩','','',TRUE,100),
('GR','Grecia','GRC','EUR','+30','🇬🇷','','',TRUE,100),
('GL','Groenlandia','GRL','DKK','+299','🇬🇱','','',TRUE,100),
('GP','Guadalupe','GLP','EUR','+590','🇬🇵','','',TRUE,100),
('GU','Guam','GUM','USD','+1671','🇬🇺','','',TRUE,100),
('GT','Guatemala','GTM','GTQ','+502','🇬🇹','','NIT',TRUE,30),
('GF','Guayana Francesa','GUF','EUR','+594','🇬🇫','','',TRUE,100),
('GG','Guernsey','GGY','GBP','+44','🇬🇬','','',TRUE,100),
('GN','Guinea','GIN','GNF','+224','🇬🇳','','',TRUE,100),
('GQ','Guinea Ecuatorial','GNQ','XAF','+240','🇬🇶','','',TRUE,100),
('GW','Guinea-Bisáu','GNB','XOF','+245','🇬🇼','','',TRUE,100),
('GY','Guyana','GUY','GYD','+592','🇬🇾','','',TRUE,100),
('HT','Haití','HTI','HTG','+509','🇭🇹','','',TRUE,100),
('HN','Honduras','HND','HNL','+504','🇭🇳','','RTN',TRUE,30),
('HK','Hong Kong','HKG','HKD','+852','🇭🇰','','',TRUE,100),
('HU','Hungría','HUN','HUF','+36','🇭🇺','','',TRUE,100),
('IN','India','IND','INR','+91','🇮🇳','','',TRUE,100),
('ID','Indonesia','IDN','IDR','+62','🇮🇩','','',TRUE,100),
('IQ','Irak','IRQ','IQD','+964','🇮🇶','','',TRUE,100),
('IR','Irán','IRN','IRR','+98','🇮🇷','','',TRUE,100),
('IE','Irlanda','IRL','EUR','+353','🇮🇪','','',TRUE,100),
('BV','Isla Bouvet','BVT','NOK','+47','🇧🇻','','',TRUE,100),
('IM','Isla de Man','IMN','GBP','+44','🇮🇲','','',TRUE,100),
('CX','Isla de Navidad','CXR','AUD','+61','🇨🇽','','',TRUE,100),
('NF','Isla Norfolk','NFK','AUD','+672','🇳🇫','','',TRUE,100),
('IS','Islandia','ISL','ISK','+354','🇮🇸','','',TRUE,100),
('KY','Islas Caimán','CYM','KYD','+1345','🇰🇾','','',TRUE,100),
('CC','Islas Cocos','CCK','AUD','+61','🇨🇨','','',TRUE,100),
('CK','Islas Cook','COK','NZD','+682','🇨🇰','','',TRUE,100),
('FO','Islas Feroe','FRO','DKK','+298','🇫🇴','','',TRUE,100),
('FK','Islas Malvinas','FLK','FKP','+500','🇫🇰','','',TRUE,100),
('MP','Islas Marianas del Norte','MNP','USD','+1670','🇲🇵','','',TRUE,100),
('MH','Islas Marshall','MHL','USD','+692','🇲🇭','','',TRUE,100),
('PN','Islas Pitcairn','PCN','NZD','+64','🇵🇳','','',TRUE,100),
('SB','Islas Salomón','SLB','SBD','+677','🇸🇧','','',TRUE,100),
('TC','Islas Turcas y Caicos','TCA','USD','+1649','🇹🇨','','',TRUE,100),
('VG','Islas Vírgenes Británicas','VGB','USD','+1284','🇻🇬','','',TRUE,100),
('VI','Islas Vírgenes de EE.UU.','VIR','USD','+1340','🇻🇮','','',TRUE,100),
('IL','Israel','ISR','ILS','+972','🇮🇱','','',TRUE,100),
('IT','Italia','ITA','EUR','+39','🇮🇹','','',TRUE,50),
('JM','Jamaica','JAM','JMD','+1876','🇯🇲','','',TRUE,100),
('JP','Japón','JPN','JPY','+81','🇯🇵','','',TRUE,50),
('JE','Jersey','JEY','GBP','+44','🇯🇪','','',TRUE,100),
('JO','Jordania','JOR','JOD','+962','🇯🇴','','',TRUE,100),
('KZ','Kazajistán','KAZ','KZT','+7','🇰🇿','','',TRUE,100),
('KE','Kenia','KEN','KES','+254','🇰🇪','','',TRUE,100),
('KG','Kirguistán','KGZ','KGS','+996','🇰🇬','','',TRUE,100),
('KI','Kiribati','KIR','AUD','+686','🇰🇮','','',TRUE,100),
('KW','Kuwait','KWT','KWD','+965','🇰🇼','','',TRUE,100),
('LA','Laos','LAO','LAK','+856','🇱🇦','','',TRUE,100),
('LS','Lesoto','LSO','LSL','+266','🇱🇸','','',TRUE,100),
('LV','Letonia','LVA','EUR','+371','🇱🇻','','',TRUE,100),
('LB','Líbano','LBN','LBP','+961','🇱🇧','','',TRUE,100),
('LR','Liberia','LBR','LRD','+231','🇱🇷','','',TRUE,100),
('LY','Libia','LBY','LYD','+218','🇱🇾','','',TRUE,100),
('LI','Liechtenstein','LIE','CHF','+423','🇱🇮','','',TRUE,100),
('LT','Lituania','LTU','EUR','+370','🇱🇹','','',TRUE,100),
('LU','Luxemburgo','LUX','EUR','+352','🇱🇺','','',TRUE,100),
('MO','Macao','MAC','MOP','+853','🇲🇴','','',TRUE,100),
('MK','Macedonia del Norte','MKD','MKD','+389','🇲🇰','','',TRUE,100),
('MG','Madagascar','MDG','MGA','+261','🇲🇬','','',TRUE,100),
('MY','Malasia','MYS','MYR','+60','🇲🇾','','',TRUE,100),
('MW','Malaui','MWI','MWK','+265','🇲🇼','','',TRUE,100),
('MV','Maldivas','MDV','MVR','+960','🇲🇻','','',TRUE,100),
('ML','Malí','MLI','XOF','+223','🇲🇱','','',TRUE,100),
('MT','Malta','MLT','EUR','+356','🇲🇹','','',TRUE,100),
('MA','Marruecos','MAR','MAD','+212','🇲🇦','','',TRUE,100),
('MQ','Martinica','MTQ','EUR','+596','🇲🇶','','',TRUE,100),
('MU','Mauricio','MUS','MUR','+230','🇲🇺','','',TRUE,100),
('MR','Mauritania','MRT','MRU','+222','🇲🇷','','',TRUE,100),
('YT','Mayotte','MYT','EUR','+262','🇾🇹','','',TRUE,100),
('MX','México','MEX','MXN','+52','🇲🇽','SAT','RFC',TRUE,10),
('FM','Micronesia','FSM','USD','+691','🇫🇲','','',TRUE,100),
('MD','Moldavia','MDA','MDL','+373','🇲🇩','','',TRUE,100),
('MC','Mónaco','MCO','EUR','+377','🇲🇨','','',TRUE,100),
('MN','Mongolia','MNG','MNT','+976','🇲🇳','','',TRUE,100),
('ME','Montenegro','MNE','EUR','+382','🇲🇪','','',TRUE,100),
('MS','Montserrat','MSR','XCD','+1664','🇲🇸','','',TRUE,100),
('MZ','Mozambique','MOZ','MZN','+258','🇲🇿','','',TRUE,100),
('MM','Birmania','MMR','MMK','+95','🇲🇲','','',TRUE,100),
('NA','Namibia','NAM','NAD','+264','🇳🇦','','',TRUE,100),
('NR','Nauru','NRU','AUD','+674','🇳🇷','','',TRUE,100),
('NP','Nepal','NPL','NPR','+977','🇳🇵','','',TRUE,100),
('NI','Nicaragua','NIC','NIO','+505','🇳🇮','','RUC',TRUE,30),
('NE','Níger','NER','XOF','+227','🇳🇪','','',TRUE,100),
('NG','Nigeria','NGA','NGN','+234','🇳🇬','','',TRUE,100),
('NU','Niue','NIU','NZD','+683','🇳🇺','','',TRUE,100),
('NO','Noruega','NOR','NOK','+47','🇳🇴','','',TRUE,100),
('NC','Nueva Caledonia','NCL','XPF','+687','🇳🇨','','',TRUE,100),
('NZ','Nueva Zelanda','NZL','NZD','+64','🇳🇿','','',TRUE,100),
('OM','Omán','OMN','OMR','+968','🇴🇲','','',TRUE,100),
('NL','Países Bajos','NLD','EUR','+31','🇳🇱','','',TRUE,50),
('PK','Pakistán','PAK','PKR','+92','🇵🇰','','',TRUE,100),
('PW','Palaos','PLW','USD','+680','🇵🇼','','',TRUE,100),
('PS','Palestina','PSE','ILS','+970','🇵🇸','','',TRUE,100),
('PA','Panamá','PAN','PAB','+507','🇵🇦','','RUC',TRUE,30),
('PG','Papúa Nueva Guinea','PNG','PGK','+675','🇵🇬','','',TRUE,100),
('PY','Paraguay','PRY','PYG','+595','🇵🇾','SET','RUC',TRUE,30),
('PE','Perú','PER','PEN','+51','🇵🇪','SUNAT','RUC',TRUE,20),
('PF','Polinesia Francesa','PYF','XPF','+689','🇵🇫','','',TRUE,100),
('PL','Polonia','POL','PLN','+48','🇵🇱','','',TRUE,100),
('PT','Portugal','PRT','EUR','+351','🇵🇹','','',TRUE,100),
('PR','Puerto Rico','PRI','USD','+1787','🇵🇷','','',TRUE,100),
('GB','Reino Unido','GBR','GBP','+44','🇬🇧','HMRC','VAT',TRUE,50),
('CF','República Centroafricana','CAF','XAF','+236','🇨🇫','','',TRUE,100),
('CZ','República Checa','CZE','CZK','+420','🇨🇿','','',TRUE,100),
('DO','República Dominicana','DOM','DOP','+1809','🇩🇴','','RNC',TRUE,30),
('RE','Reunión','REU','EUR','+262','🇷🇪','','',TRUE,100),
('RW','Ruanda','RWA','RWF','+250','🇷🇼','','',TRUE,100),
('RO','Rumania','ROU','RON','+40','🇷🇴','','',TRUE,100),
('RU','Rusia','RUS','RUB','+7','🇷🇺','','',TRUE,100),
('EH','Sahara Occidental','ESH','MAD','+212','🇪🇭','','',TRUE,100),
('WS','Samoa','WSM','WST','+685','🇼🇸','','',TRUE,100),
('AS','Samoa Americana','ASM','USD','+1684','🇦🇸','','',TRUE,100),
('BL','San Bartolomé','BLM','EUR','+590','🇧🇱','','',TRUE,100),
('KN','San Cristóbal y Nieves','KNA','XCD','+1869','🇰🇳','','',TRUE,100),
('SM','San Marino','SMR','EUR','+378','🇸🇲','','',TRUE,100),
('MF','San Martín (parte francesa)','MAF','EUR','+590','🇲🇫','','',TRUE,100),
('PM','San Pedro y Miquelón','SPM','EUR','+508','🇵🇲','','',TRUE,100),
('VC','San Vicente y las Granadinas','VCT','XCD','+1784','🇻🇨','','',TRUE,100),
('SH','Santa Elena','SHN','SHP','+290','🇸🇭','','',TRUE,100),
('LC','Santa Lucía','LCA','XCD','+1758','🇱🇨','','',TRUE,100),
('ST','Santo Tomé y Príncipe','STP','STN','+239','🇸🇹','','',TRUE,100),
('SN','Senegal','SEN','XOF','+221','🇸🇳','','',TRUE,100),
('RS','Serbia','SRB','RSD','+381','🇷🇸','','',TRUE,100),
('SC','Seychelles','SYC','SCR','+248','🇸🇨','','',TRUE,100),
('SL','Sierra Leona','SLE','SLL','+232','🇸🇱','','',TRUE,100),
('SG','Singapur','SGP','SGD','+65','🇸🇬','','',TRUE,100),
('SX','Sint Maarten','SXM','ANG','+1721','🇸🇽','','',TRUE,100),
('SY','Siria','SYR','SYP','+963','🇸🇾','','',TRUE,100),
('SO','Somalia','SOM','SOS','+252','🇸🇴','','',TRUE,100),
('LK','Sri Lanka','LKA','LKR','+94','🇱🇰','','',TRUE,100),
('ZA','Sudáfrica','ZAF','ZAR','+27','🇿🇦','','',TRUE,100),
('SD','Sudán','SDN','SDG','+249','🇸🇩','','',TRUE,100),
('SS','Sudán del Sur','SSD','SSP','+211','🇸🇸','','',TRUE,100),
('SE','Suecia','SWE','SEK','+46','🇸🇪','','',TRUE,100),
('CH','Suiza','CHE','CHF','+41','🇨🇭','','',TRUE,100),
('SR','Surinam','SUR','SRD','+597','🇸🇷','','',TRUE,100),
('SJ','Svalbard y Jan Mayen','SJM','NOK','+47','🇸🇯','','',TRUE,100),
('SZ','Suazilandia','SWZ','SZL','+268','🇸🇿','','',TRUE,100),
('TH','Tailandia','THA','THB','+66','🇹🇭','','',TRUE,100),
('TW','Taiwán','TWN','TWD','+886','🇹🇼','','',TRUE,100),
('TZ','Tanzania','TZA','TZS','+255','🇹🇿','','',TRUE,100),
('TJ','Tayikistán','TJK','TJS','+992','🇹🇯','','',TRUE,100),
('IO','Territorio Británico del Océano Índico','IOT','USD','+246','🇮🇴','','',TRUE,100),
('TF','Territorios Australes Franceses','ATF','EUR','+262','🇹🇫','','',TRUE,100),
('TL','Timor Oriental','TLS','USD','+670','🇹🇱','','',TRUE,100),
('TG','Togo','TGO','XOF','+228','🇹🇬','','',TRUE,100),
('TK','Tokelau','TKL','NZD','+690','🇹🇰','','',TRUE,100),
('TO','Tonga','TON','TOP','+676','🇹🇴','','',TRUE,100),
('TT','Trinidad y Tobago','TTO','TTD','+1868','🇹🇹','','',TRUE,100),
('TN','Túnez','TUN','TND','+216','🇹🇳','','',TRUE,100),
('TM','Turkmenistán','TKM','TMT','+993','🇹🇲','','',TRUE,100),
('TR','Turquía','TUR','TRY','+90','🇹🇷','','',TRUE,100),
('TV','Tuvalu','TUV','AUD','+688','🇹🇻','','',TRUE,100),
('UA','Ucrania','UKR','UAH','+380','🇺🇦','','',TRUE,100),
('UG','Uganda','UGA','UGX','+256','🇺🇬','','',TRUE,100),
('UY','Uruguay','URY','UYU','+598','🇺🇾','DGI','RUT',TRUE,20),
('UZ','Uzbekistán','UZB','UZS','+998','🇺🇿','','',TRUE,100),
('VU','Vanuatu','VUT','VUV','+678','🇻🇺','','',TRUE,100),
('VE','Venezuela','VEN','VES','+58','🇻🇪','SENIAT','RIF',TRUE,10),
('VN','Vietnam','VNM','VND','+84','🇻🇳','','',TRUE,100),
('WF','Wallis y Futuna','WLF','XPF','+681','🇼🇫','','',TRUE,100),
('YE','Yemen','YEM','YER','+967','🇾🇪','','',TRUE,100),
('DJ','Yibuti','DJI','DJF','+253','🇩🇯','','',TRUE,100),
('ZM','Zambia','ZMB','ZMW','+260','🇿🇲','','',TRUE,100),
('ZW','Zimbabue','ZWE','ZWL','+263','🇿🇼','','',TRUE,100)
ON CONFLICT ("CountryCode") DO UPDATE SET
    "CountryName" = EXCLUDED."CountryName",
    "Iso3"        = EXCLUDED."Iso3",
    "CurrencyCode" = CASE WHEN cfg."Country"."CurrencyCode" = '' OR cfg."Country"."CurrencyCode" IS NULL
                          THEN EXCLUDED."CurrencyCode" ELSE cfg."Country"."CurrencyCode" END,
    "PhonePrefix" = EXCLUDED."PhonePrefix",
    "FlagEmoji"   = EXCLUDED."FlagEmoji",
    "SortOrder"   = LEAST(cfg."Country"."SortOrder", EXCLUDED."SortOrder"),
    "UpdatedAt"   = NOW();

-- ── 3) Reemplazar usp_cfg_country_list para devolver columnas nuevas ─────────

DROP FUNCTION IF EXISTS public.usp_cfg_country_list(BOOLEAN);

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_cfg_country_list(
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "CountryCode"      CHARACTER,
    "CountryName"      VARCHAR,
    "Iso3"             VARCHAR,
    "CurrencyCode"     CHARACTER,
    "CurrencySymbol"   VARCHAR,
    "PhonePrefix"      VARCHAR,
    "FlagEmoji"        VARCHAR,
    "TaxAuthorityCode" VARCHAR,
    "FiscalIdName"     VARCHAR,
    "TimeZoneIana"     VARCHAR,
    "SortOrder"        INTEGER,
    "IsActive"         BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CountryCode",
        c."CountryName"::VARCHAR,
        c."Iso3"::VARCHAR,
        c."CurrencyCode",
        COALESCE(c."CurrencySymbol", '')::VARCHAR,
        c."PhonePrefix"::VARCHAR,
        c."FlagEmoji"::VARCHAR,
        c."TaxAuthorityCode"::VARCHAR,
        c."FiscalIdName"::VARCHAR,
        COALESCE(c."TimeZoneIana", '')::VARCHAR,
        c."SortOrder",
        c."IsActive"
    FROM cfg."Country" c
    WHERE (NOT p_active_only OR c."IsActive" = TRUE)
    ORDER BY c."SortOrder", c."CountryName";
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_cfg_country_list(BOOLEAN);

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_cfg_country_list(
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "CountryCode" CHARACTER,
    "CountryName" VARCHAR,
    "CurrencyCode" CHARACTER,
    "TaxAuthorityCode" VARCHAR,
    "FiscalIdName" VARCHAR,
    "IsActive" BOOLEAN,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CountryCode", c."CountryName"::VARCHAR, c."CurrencyCode",
           c."TaxAuthorityCode"::VARCHAR, c."FiscalIdName"::VARCHAR,
           c."IsActive", c."CreatedAt", c."UpdatedAt"
      FROM cfg."Country" c
     WHERE (NOT p_active_only OR c."IsActive" = TRUE)
     ORDER BY c."CountryName";
END;
$$;
-- +goose StatementEnd

ALTER TABLE cfg."Country"
    DROP COLUMN IF EXISTS "SortOrder",
    DROP COLUMN IF EXISTS "FlagEmoji",
    DROP COLUMN IF EXISTS "PhonePrefix",
    DROP COLUMN IF EXISTS "Iso3";
