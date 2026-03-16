-- ============================================
-- BrokerDB – Seed data
-- ============================================
USE BrokerDB;
GO

-- Roles
INSERT INTO Roles (name, description) VALUES
('admin',    'System administrator'),
('provider', 'Service provider / supplier'),
('customer', 'End customer / traveler');

-- Default admin user (password: Admin123!)
-- bcrypt hash for 'Admin123!'
INSERT INTO Users (email, password_hash, first_name, last_name, phone, status) VALUES
('admin@broker.com', '$2a$12$LJ3slKMvRGTnG4vYbRM6/.CVFtaOPOXxeQ6aICZm8YaYnFOmZVn.G', 'System', 'Admin', '+1234567890', 'active');

INSERT INTO UserRoles (user_id, role_id) VALUES (1, 1);

-- Countries
INSERT INTO Countries (code, name) VALUES
('USA', 'United States'), ('MEX', 'Mexico'), ('CAN', 'Canada'),
('ESP', 'Spain'), ('FRA', 'France'), ('ITA', 'Italy'),
('GBR', 'United Kingdom'), ('DEU', 'Germany'), ('BRA', 'Brazil'),
('ARG', 'Argentina'), ('COL', 'Colombia'), ('VEN', 'Venezuela'),
('CHL', 'Chile'), ('PER', 'Peru'), ('ECU', 'Ecuador'),
('PAN', 'Panama'), ('CRI', 'Costa Rica'), ('DOM', 'Dominican Republic'),
('CUB', 'Cuba'), ('JPN', 'Japan'), ('CHN', 'China'),
('AUS', 'Australia'), ('THA', 'Thailand'), ('IDN', 'Indonesia'),
('MYS', 'Malaysia'), ('PHL', 'Philippines'), ('IND', 'India'),
('ARE', 'United Arab Emirates'), ('EGY', 'Egypt'), ('ZAF', 'South Africa');

-- Currencies
INSERT INTO Currencies (code, name, symbol, exchange_rate) VALUES
('USD', 'US Dollar',      '$',  1.000000),
('EUR', 'Euro',            '€',  0.920000),
('GBP', 'British Pound',   '£',  0.790000),
('MXN', 'Mexican Peso',    '$',  17.150000),
('BRL', 'Brazilian Real',  'R$', 4.970000),
('COP', 'Colombian Peso',  '$',  3950.000000),
('ARS', 'Argentine Peso',  '$',  870.000000),
('VES', 'Venezuelan Bolívar','Bs', 36.500000),
('CAD', 'Canadian Dollar',  'C$', 1.360000),
('JPY', 'Japanese Yen',     '¥',  149.500000);

-- Amenities catalog
INSERT INTO Amenities (name, icon, category) VALUES
('WiFi',               'wifi',            'general'),
('Swimming Pool',      'pool',            'general'),
('Parking',            'local_parking',   'general'),
('Air Conditioning',   'ac_unit',         'room'),
('Breakfast Included', 'free_breakfast',  'general'),
('Gym / Fitness',      'fitness_center',  'general'),
('Spa',                'spa',             'general'),
('Restaurant',         'restaurant',      'general'),
('Bar / Lounge',       'local_bar',       'general'),
('Room Service',       'room_service',    'room'),
('Pet Friendly',       'pets',            'general'),
('Beach Access',       'beach_access',    'general'),
('Airport Shuttle',    'airport_shuttle', 'transport'),
('EV Charging',        'ev_station',      'transport'),
('24h Reception',      'support_agent',   'general'),
('Laundry Service',    'local_laundry_service', 'general'),
('Kitchen',            'kitchen',         'room'),
('TV / Cable',         'tv',              'room'),
('Safe Box',           'lock',            'safety'),
('Fire Extinguisher',  'fire_extinguisher','safety'),
('GPS Navigation',     'navigation',      'transport'),
('Child Seat',         'child_care',      'transport'),
('Life Jacket',        'sailing',         'safety'),
('Snorkeling Gear',    'scuba_diving',    'entertainment');

-- Commission Rules
INSERT INTO CommissionRules (provider_type, min_pct, max_pct, default_pct) VALUES
('hotel',      5.00, 25.00, 15.00),
('car_rental', 5.00, 20.00, 12.00),
('marina',     5.00, 20.00, 10.00),
('airline',    3.00, 15.00,  8.00),
('lodge',      5.00, 25.00, 15.00),
('tour',       5.00, 30.00, 18.00);

-- System Settings
INSERT INTO Settings ([key], value, category, description) VALUES
('platform_name',    'BrokerPlatform',      'general', 'Display name of the platform'),
('default_currency', 'USD',                  'general', 'Default currency for pricing'),
('tax_rate',         '16.00',                'billing', 'Default tax rate percentage'),
('booking_expiry_h', '24',                   'booking', 'Hours before a pending booking expires'),
('min_advance_days', '1',                    'booking', 'Minimum days in advance for booking'),
('max_advance_days', '365',                  'booking', 'Maximum days in advance for booking'),
('review_auto_approve', 'true',              'reviews', 'Auto-approve reviews or require moderation');

-- ─────────────────────────────────────────────
-- SAMPLE PROVIDERS
-- ─────────────────────────────────────────────
INSERT INTO Providers (name, type, tax_id, email, phone, address, city, state, country, description, rating, status, commission_pct, contact_person) VALUES
('Hotel Paraíso Caribe',   'hotel',      'J-12345678-9', 'info@paraisocaribe.com',  '+58-212-1234567', 'Av. Principal 123',      'Margarita',   'Nueva Esparta', 'VEN', 'Luxury beachfront hotel with all-inclusive options', 4.50, 'active', 15.00, 'Carlos Mendoza'),
('AutoRent Express',       'car_rental', 'J-98765432-1', 'rent@autorentexpress.com', '+1-305-5551234', '100 NW 1st Ave',          'Miami',       'FL',            'USA', 'Premium car rental fleet with latest models',       4.20, 'active', 12.00, 'John Smith'),
('Marina del Sol',         'marina',     'J-55566677-8', 'reservas@marinadelsol.com','+58-295-2631234', 'Puerto de Pampatar',      'Margarita',   'Nueva Esparta', 'VEN', 'Full-service marina with yacht charters',           4.70, 'active', 10.00, 'María García'),
('AeroConnect',            'airline',    'G-11122233-4', 'booking@aeroconnect.com',  '+1-800-5557890', '500 Airport Blvd',        'Fort Lauderdale','FL',         'USA', 'Regional airline connecting Caribbean islands',     4.00, 'active',  8.00, 'David Lee'),
('Posada La Montaña',      'lodge',      'V-77788899-0', 'reserva@posmontana.com',  '+58-274-4151234', 'Carretera Trasandina Km5','Mérida',      'Mérida',       'VEN', 'Cozy mountain lodge with panoramic Andes views',    4.80, 'active', 15.00, 'Ana Torres'),
('Caribbean Adventures',   'tour',       'J-44455566-7', 'info@caribadventures.com','+1-787-5554321', 'Calle Marina 50',         'San Juan',    'PR',            'USA', 'Guided tours, diving & snorkeling excursions',      4.60, 'active', 18.00, 'Luis Rivera');

-- ─────────────────────────────────────────────
-- SAMPLE PROPERTIES
-- ─────────────────────────────────────────────
INSERT INTO Properties (provider_id, name, type, description, address, city, country, latitude, longitude, max_guests, images, status) VALUES
(1, 'Suite Oceanview Deluxe',      'room',    'Spacious suite with ocean view, king bed, and private balcony', 'Playa El Agua',   'Margarita', 'VEN', 11.0800000, -63.8800000, 4, '["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b"]', 'active'),
(1, 'Habitación Estándar Doble',   'room',    'Comfortable double room with garden views',                     'Playa El Agua',   'Margarita', 'VEN', 11.0800000, -63.8800000, 2, '["https://images.unsplash.com/photo-1631049307264-da0ec9d70304"]', 'active'),
(2, 'Toyota Corolla 2025',         'vehicle', 'Sedan 4-door, automatic, A/C, GPS included',                    'MIA Airport',     'Miami',     'USA', 25.7950000, -80.2870000, 5, '["https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb"]', 'active'),
(2, 'Jeep Wrangler 4x4',          'vehicle', 'Off-road SUV, perfect for adventures',                          'MIA Airport',     'Miami',     'USA', 25.7950000, -80.2870000, 4, '["https://images.unsplash.com/photo-1519681393784-d120267933ba"]', 'active'),
(3, 'Yacht 42ft - Sea Dream',     'boat',    '42-foot luxury yacht with captain, up to 8 guests',             'Puerto Pampatar', 'Margarita', 'VEN', 11.0300000, -63.7900000, 8, '["https://images.unsplash.com/photo-1567899378494-47b22a2ae96a"]', 'active'),
(3, 'Speed Boat Tour',            'boat',    '20-foot speed boat for island hopping (half-day)',               'Puerto Pampatar', 'Margarita', 'VEN', 11.0300000, -63.7900000, 6, '["https://images.unsplash.com/photo-1544551763-46a013bb70d5"]', 'active'),
(4, 'FLL → SJU Direct Flight',    'flight',  'Fort Lauderdale to San Juan, daily departure 8:00 AM',          'FLL Airport',     'Fort Lauderdale','USA',26.0742000,-80.1506000, 180,'["https://images.unsplash.com/photo-1436491865332-7a61a109db05"]','active'),
(5, 'Cabaña VIP Montaña',         'unit',    'Private cabin with fireplace, hot tub, and mountain views',     'Km 5 Trasandina', 'Mérida',    'VEN',  8.5897000,-71.1561000, 4, '["https://images.unsplash.com/photo-1470770841497-7b3fe27bd6d0"]', 'active'),
(6, 'Snorkeling Full Day Tour',   'unit',    'Full day snorkeling with lunch and equipment included',         'Bahía de San Juan','San Juan','USA',  18.4655000,-66.1057000, 12,'["https://images.unsplash.com/photo-1544551763-77ef2d0cfc6c"]', 'active');

-- Property Rates
INSERT INTO PropertyRates (property_id, name, price_per_night, price_per_hour, currency) VALUES
(1, 'standard', 250.00, 0, 'USD'),
(1, 'weekend',  320.00, 0, 'USD'),
(2, 'standard', 120.00, 0, 'USD'),
(3, 'standard',  85.00, 0, 'USD'),
(4, 'standard', 110.00, 0, 'USD'),
(5, 'standard',   0.00, 150.00, 'USD'),  -- per hour for yacht
(6, 'standard',   0.00,  80.00, 'USD'),  -- per hour for speed boat
(7, 'standard', 289.00, 0, 'USD'),       -- flight
(8, 'standard', 180.00, 0, 'USD'),       -- cabin
(9, 'standard',  95.00, 0, 'USD');       -- tour per person

-- Property Amenities associations
INSERT INTO PropertyAmenities (property_id, amenity_id) VALUES
(1, 1), (1, 2), (1, 4), (1, 5), (1, 10), (1, 12),   -- Suite: wifi, pool, AC, breakfast, room service, beach
(2, 1), (2, 4), (2, 18),                               -- Standard room: wifi, AC, TV
(3, 3), (3, 4), (3, 21),                               -- Corolla: parking, AC, GPS
(4, 3), (4, 4), (4, 21),                               -- Jeep: parking, AC, GPS
(5, 23), (5, 24),                                       -- Yacht: life jacket, snorkel
(8, 1), (8, 4), (8, 17), (8, 18);                      -- Cabin: wifi, AC, kitchen, TV

-- Sample Customers
INSERT INTO Customers (first_name, last_name, email, phone, document_type, document_number, nationality, city, country, loyalty_points, status) VALUES
('Roberto',  'Martínez', 'roberto.m@gmail.com',  '+58-412-1234567', 'id_card',  'V-12345678', 'VEN', 'Caracas',    'VEN', 100, 'active'),
('Sarah',    'Johnson',  'sarah.j@outlook.com',  '+1-305-5559876',  'passport', 'US1234567',  'USA', 'Miami',      'USA', 250, 'active'),
('Pedro',    'Gómez',    'pedro.g@hotmail.com',   '+58-414-9876543', 'id_card',  'V-87654321', 'VEN', 'Margarita',  'VEN',  50, 'active');

-- Sample Promotions
INSERT INTO Promotions (provider_id, property_id, name, discount_pct, discount_amount, valid_from, valid_to, promo_code, usage_limit, times_used, status) VALUES
(1, 1, 'Early Bird Suite 30% Off',    30.00, 0, '2026-01-01', '2026-06-30', 'EARLYBIRD30', 100, 5,  'active'),
(2, NULL, 'Rent 3 Days Get 1 Free',    0.00, 85.00, '2026-02-01', '2026-04-30', 'RENT3GET1', 50, 12, 'active'),
(5, 8, 'Mountain Escape Weekend',      20.00, 0, '2026-03-01', '2026-05-31', 'MOUNTAIN20', 30, 0,  'active');

PRINT 'Seed data inserted successfully.';
GO
