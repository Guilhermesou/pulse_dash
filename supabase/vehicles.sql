-- =============================================================================
-- Auto DB — Schema normalizado v2.0 | Pronto para produção no Supabase
-- =============================================================================

-- =============================================================================
-- FUNÇÃO UTILITÁRIA: atualiza updated_at automaticamente
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- MARCAS
-- =============================================================================
CREATE TABLE makes (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,
  slug       TEXT NOT NULL UNIQUE,
  country    TEXT,
  logo_url   TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_makes_updated_at
  BEFORE UPDATE ON makes FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- MODELOS
-- =============================================================================
CREATE TABLE models (
  id         SERIAL PRIMARY KEY,
  make_id    INT NOT NULL REFERENCES makes(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  slug       TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(make_id, name)
);

CREATE TRIGGER trg_models_updated_at
  BEFORE UPDATE ON models FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- GERAÇÕES
-- Representa a arquitetura/carroceria de uma geração.
-- Dimensões, Cd, porta-malas, portas ficam aqui.
-- Suspensão, freios e pneus variam por versão → ficam em vehicles.
-- =============================================================================
CREATE TABLE generations (
  id         SERIAL PRIMARY KEY,
  model_id   INT NOT NULL REFERENCES models(id) ON DELETE CASCADE,
  code       TEXT,
  year_from  INT,
  year_to    INT,

  body_type  TEXT,
  doors      SMALLINT CHECK (doors BETWEEN 2 AND 5),
  seats      SMALLINT CHECK (seats BETWEEN 1 AND 9),

  length_mm      INT,
  width_mm       INT,
  height_mm      INT,
  wheelbase_mm   INT,
  front_track_mm INT,
  rear_track_mm  INT,

  drag_coefficient DECIMAL(4,3),
  frontal_area_m2  DECIMAL(4,2),

  trunk_volume_l     INT,
  trunk_volume_max_l INT,

  image_url  TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_gen_years CHECK (year_from IS NULL OR year_to IS NULL OR year_from <= year_to)
);

CREATE TRIGGER trg_generations_updated_at
  BEFORE UPDATE ON generations FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- MOTORES — reutilizável entre múltiplos veículos
-- =============================================================================
CREATE TABLE engines (
  id                  SERIAL PRIMARY KEY,
  code                TEXT NOT NULL UNIQUE,
  commercial_name     TEXT,
  configuration       TEXT,
  displacement_cc     INT,
  bore_mm             DECIMAL(5,2),
  stroke_mm           DECIMAL(5,2),
  compression_ratio   DECIMAL(5,2),
  valvetrain          TEXT,
  valves_per_cylinder SMALLINT,
  fuel_system         TEXT,
  fuel_type           TEXT,
  turbocharged        BOOLEAN NOT NULL DEFAULT false,
  supercharged        BOOLEAN NOT NULL DEFAULT false,
  position            TEXT NOT NULL DEFAULT 'Dianteiro',
  orientation         TEXT NOT NULL DEFAULT 'Transversal',
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_engines_updated_at
  BEFORE UPDATE ON engines FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- CÂMBIOS — reutilizável entre múltiplos veículos
-- =============================================================================
CREATE TABLE transmissions (
  id                SERIAL PRIMARY KEY,
  code              TEXT NOT NULL UNIQUE,
  commercial_name   TEXT,
  type              TEXT NOT NULL CHECK (type IN ('Manual','DSG','Automático','CVT','PDK','e-CVT')),
  gear_count        SMALLINT,
  gear_ratios       JSONB,
  final_drive_ratio DECIMAL(6,3),
  manufacturer      TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_transmissions_updated_at
  BEFORE UPDATE ON transmissions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- VEÍCULOS — cada linha = uma variante específica
-- =============================================================================
CREATE TABLE vehicles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  generation_id   INT NOT NULL REFERENCES generations(id) ON DELETE CASCADE,
  engine_id       INT REFERENCES engines(id),
  transmission_id INT REFERENCES transmissions(id),

  slug       TEXT NOT NULL UNIQUE,
  trim       TEXT,
  year_from  INT,
  year_to    INT,
  drive_type TEXT CHECK (drive_type IN ('FWD','RWD','AWD','4WD')),

  power_hp   INT  CHECK (power_hp > 0),
  power_rpm  INT,
  torque_nm  INT  CHECK (torque_nm >= 0),
  torque_rpm INT,

  zero_to_100_s DECIMAL(4,1),
  top_speed_kmh INT,

  consumption_urban_l100km    DECIMAL(4,1),
  consumption_highway_l100km  DECIMAL(4,1),
  consumption_combined_l100km DECIMAL(4,1),
  co2_g_per_km  INT,
  euro_standard TEXT,

  curb_weight_kg  INT,
  gross_weight_kg INT,
  tank_capacity_l INT,

  tire_width        SMALLINT,
  tire_aspect       SMALLINT,
  wheel_diameter_in SMALLINT,
  optional_tire     TEXT,

  front_suspension TEXT,
  rear_suspension  TEXT,

  front_brakes            TEXT,
  rear_brakes             TEXT,
  front_brake_diameter_mm INT,
  rear_brake_diameter_mm  INT,

  featured   BOOLEAN NOT NULL DEFAULT false,
  views      INT     NOT NULL DEFAULT 0,
  likes      INT     NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_veh_years   CHECK (year_from IS NULL OR year_to IS NULL OR year_from <= year_to),
  CONSTRAINT chk_veh_weights CHECK (gross_weight_kg IS NULL OR curb_weight_kg IS NULL OR gross_weight_kg >= curb_weight_kg)
);

CREATE TRIGGER trg_vehicles_updated_at
  BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- IMAGENS
-- =============================================================================
CREATE TABLE vehicle_images (
  id         SERIAL PRIMARY KEY,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,
  caption    TEXT,
  is_primary BOOLEAN  NOT NULL DEFAULT false,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- TAGS
-- =============================================================================
CREATE TABLE tags (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE
);

CREATE TABLE vehicle_tags (
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  tag_id     INT  NOT NULL REFERENCES tags(id)     ON DELETE CASCADE,
  PRIMARY KEY (vehicle_id, tag_id)
);

-- =============================================================================
-- LOG DE COMPARAÇÕES
-- =============================================================================
CREATE TABLE comparison_logs (
  id          BIGSERIAL PRIMARY KEY,
  vehicle_ids UUID[]      NOT NULL,
  session_id  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- ÍNDICES
-- =============================================================================
CREATE INDEX idx_models_make            ON models(make_id);
CREATE INDEX idx_generations_model      ON generations(model_id);
CREATE INDEX idx_vehicles_generation    ON vehicles(generation_id);
CREATE INDEX idx_vehicles_engine        ON vehicles(engine_id);
CREATE INDEX idx_vehicles_transmission  ON vehicles(transmission_id);
CREATE INDEX idx_vehicles_slug          ON vehicles(slug);
CREATE INDEX idx_vehicles_power         ON vehicles(power_hp);
CREATE INDEX idx_vehicles_0to100        ON vehicles(zero_to_100_s);
CREATE INDEX idx_vehicles_drive_type    ON vehicles(drive_type);
CREATE INDEX idx_vehicles_featured      ON vehicles(featured) WHERE featured = true;
CREATE INDEX idx_engines_fuel_type      ON engines(fuel_type);
CREATE INDEX idx_engines_code           ON engines(code);
CREATE INDEX idx_vehicle_images_vehicle ON vehicle_images(vehicle_id);
CREATE INDEX idx_vehicle_tags_vehicle   ON vehicle_tags(vehicle_id);
CREATE INDEX idx_vehicle_tags_tag       ON vehicle_tags(tag_id);
CREATE INDEX idx_comparison_logs_ts     ON comparison_logs(created_at);

-- =============================================================================
-- VIEW — estrutura plana para Flutter + site
-- =============================================================================
CREATE OR REPLACE VIEW vehicles_view AS
SELECT
  v.id,
  v.slug,
  v.featured,
  v.views,
  v.likes,

  mk.id      AS make_id,
  mk.name    AS make,
  mk.slug    AS make_slug,
  mk.country AS make_country,
  mk.logo_url,

  mo.id   AS model_id,
  mo.name AS model,
  mo.slug AS model_slug,

  g.id                 AS generation_id,
  g.code               AS generation,
  g.body_type,
  g.doors,
  g.seats,
  g.length_mm,
  g.width_mm,
  g.height_mm,
  g.wheelbase_mm,
  g.front_track_mm,
  g.rear_track_mm,
  g.drag_coefficient,
  g.frontal_area_m2,
  g.trunk_volume_l,
  g.trunk_volume_max_l,
  g.image_url          AS generation_image_url,

  COALESCE(v.year_from, g.year_from) AS year_from,
  COALESCE(v.year_to,   g.year_to)   AS year_to,
  v.trim,
  v.drive_type,

  e.id                AS engine_id,
  e.code              AS engine_code,
  e.commercial_name   AS engine_name,
  e.configuration     AS engine_configuration,
  e.displacement_cc,
  e.bore_mm,
  e.stroke_mm,
  e.compression_ratio,
  e.valvetrain,
  e.valves_per_cylinder,
  e.fuel_system,
  e.fuel_type,
  e.turbocharged,
  e.supercharged,
  e.position          AS engine_position,
  e.orientation       AS engine_orientation,

  v.power_hp,
  v.power_rpm,
  v.torque_nm,
  v.torque_rpm,

  t.id                AS transmission_id,
  t.code              AS transmission_code,
  t.commercial_name   AS transmission_name,
  t.type              AS transmission_type,
  t.gear_count,
  t.gear_ratios,
  t.final_drive_ratio,
  t.manufacturer      AS transmission_manufacturer,

  v.zero_to_100_s,
  v.top_speed_kmh,

  v.consumption_urban_l100km,
  v.consumption_highway_l100km,
  v.consumption_combined_l100km,
  v.co2_g_per_km,
  v.euro_standard,

  v.curb_weight_kg,
  v.gross_weight_kg,
  v.tank_capacity_l,

  v.tire_width,
  v.tire_aspect,
  v.wheel_diameter_in,
  v.optional_tire,

  v.front_suspension,
  v.rear_suspension,
  v.front_brakes,
  v.rear_brakes,
  v.front_brake_diameter_mm,
  v.rear_brake_diameter_mm,

  v.created_at,
  v.updated_at

FROM vehicles v
JOIN generations  g  ON v.generation_id   = g.id
JOIN models       mo ON g.model_id         = mo.id
JOIN makes        mk ON mo.make_id         = mk.id
LEFT JOIN engines       e ON v.engine_id       = e.id
LEFT JOIN transmissions t ON v.transmission_id = t.id;

-- =============================================================================
-- RLS
-- =============================================================================
ALTER TABLE makes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE models          ENABLE ROW LEVEL SECURITY;
ALTER TABLE generations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE engines         ENABLE ROW LEVEL SECURITY;
ALTER TABLE transmissions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_images  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags            ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_tags    ENABLE ROW LEVEL SECURITY;
ALTER TABLE comparison_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read" ON makes          FOR SELECT USING (true);
CREATE POLICY "public_read" ON models         FOR SELECT USING (true);
CREATE POLICY "public_read" ON generations    FOR SELECT USING (true);
CREATE POLICY "public_read" ON engines        FOR SELECT USING (true);
CREATE POLICY "public_read" ON transmissions  FOR SELECT USING (true);
CREATE POLICY "public_read" ON vehicles       FOR SELECT USING (true);
CREATE POLICY "public_read" ON vehicle_images FOR SELECT USING (true);
CREATE POLICY "public_read" ON tags           FOR SELECT USING (true);
CREATE POLICY "public_read" ON vehicle_tags   FOR SELECT USING (true);

CREATE POLICY "auth_write" ON makes          FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON models         FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON generations    FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON engines        FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON transmissions  FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON vehicles       FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON vehicle_images FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON tags           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_write" ON vehicle_tags   FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "anon_insert" ON comparison_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "auth_read"   ON comparison_logs FOR SELECT USING (auth.role() = 'authenticated');

-- =============================================================================
-- HELPERS (funções temporárias para seed)
-- =============================================================================
CREATE OR REPLACE FUNCTION _gen_id(p_make TEXT, p_model TEXT, p_gen TEXT)
RETURNS INT LANGUAGE SQL STABLE AS $$
  SELECT g.id FROM generations g
  JOIN models m ON g.model_id = m.id
  JOIN makes mk ON m.make_id  = mk.id
  WHERE mk.name = p_make AND m.name = p_model AND g.code = p_gen LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION _eng_id(p_code TEXT)
RETURNS INT LANGUAGE SQL STABLE AS $$
  SELECT id FROM engines WHERE code = p_code LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION _trn_id(p_code TEXT)
RETURNS INT LANGUAGE SQL STABLE AS $$
  SELECT id FROM transmissions WHERE code = p_code LIMIT 1;
$$;


-- =============================================================================
-- SEED — TAGS
-- =============================================================================
INSERT INTO tags (name, slug) VALUES
  ('Hot Hatch',    'hot-hatch'),
  ('Track Day',    'track-day'),
  ('AWD',          'awd'),
  ('Turbo',        'turbo'),
  ('Clássico',     'classico'),
  ('Flex',         'flex'),
  ('Econômico',    'economico'),
  ('Sports Sedan', 'sports-sedan'),
  ('Japonês',      'japones'),
  ('Alemão',       'alemao');

-- =============================================================================
-- LIMPEZA DOS HELPERS
-- =============================================================================
DROP FUNCTION IF EXISTS _gen_id(TEXT,TEXT,TEXT);
DROP FUNCTION IF EXISTS _eng_id(TEXT);
DROP FUNCTION IF EXISTS _trn_id(TEXT);




-- ==========================================================
-- 1. CRIAÇÃO DA ESTRUTURA (DDL)
-- ==========================================================

BEGIN;

-- Criar tabela de Marcas (Makes)
CREATE TABLE IF NOT EXISTS makes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Criar tabela de Modelos (Models)
CREATE TABLE IF NOT EXISTS models (
    id SERIAL PRIMARY KEY,
    make_id INTEGER REFERENCES makes(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL
);

-- Criar tabela de Gerações (Generations)
CREATE TABLE IF NOT EXISTS generations (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL
);

-- Criar tabela de Veículos (Vehicles)
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    generation_id INTEGER REFERENCES generations(id) ON DELETE CASCADE,
    trim VARCHAR(150) NOT NULL,
    year_from INTEGER,
    drive_type VARCHAR(20), -- FWD, AWD, RWD
    power_hp INTEGER,
    torque_nm INTEGER,
    zero_to_100_s DECIMAL(4,1),
    top_speed_kmh INTEGER,
    curb_weight_kg INTEGER,
    tank_capacity_l INTEGER,
    featured BOOLEAN DEFAULT false
);

-- ==========================================================
-- 2. SEED DE MARCAS (MAKES)
-- ==========================================================

INSERT INTO makes (name) VALUES 
('Volkswagen'), ('Chevrolet'), ('Hyundai'), ('Fiat'), 
('Renault'), ('Toyota'), ('Honda'), ('Nissan'), ('Jeep')
ON CONFLICT (name) DO NOTHING;

-- ==========================================================
-- 3. SEED DE MODELOS (MODELS)
-- ==========================================================

INSERT INTO models (make_id, name)
SELECT id, 'Gol' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Up!' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Polo' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Virtus' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'T-Cross' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Nivus' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Jetta' FROM makes WHERE name = 'Volkswagen' UNION ALL
SELECT id, 'Onix' FROM makes WHERE name = 'Chevrolet' UNION ALL
SELECT id, 'Tracker' FROM makes WHERE name = 'Chevrolet' UNION ALL
SELECT id, 'HB20' FROM makes WHERE name = 'Hyundai' UNION ALL
SELECT id, 'Creta' FROM makes WHERE name = 'Hyundai' UNION ALL
SELECT id, 'Argo' FROM makes WHERE name = 'Fiat' UNION ALL
SELECT id, 'Cronos' FROM makes WHERE name = 'Fiat' UNION ALL
SELECT id, 'Pulse' FROM makes WHERE name = 'Fiat' UNION ALL
SELECT id, 'Fastback' FROM makes WHERE name = 'Fiat' UNION ALL
SELECT id, 'Kwid' FROM makes WHERE name = 'Renault' UNION ALL
SELECT id, 'Sandero' FROM makes WHERE name = 'Renault' UNION ALL
SELECT id, 'Corolla' FROM makes WHERE name = 'Toyota' UNION ALL
SELECT id, 'City' FROM makes WHERE name = 'Honda' UNION ALL
SELECT id, 'Civic' FROM makes WHERE name = 'Honda' UNION ALL
SELECT id, 'Versa' FROM makes WHERE name = 'Nissan' UNION ALL
SELECT id, 'Kicks' FROM makes WHERE name = 'Nissan' UNION ALL
SELECT id, 'Compass' FROM makes WHERE name = 'Jeep' UNION ALL
SELECT id, 'Renegade' FROM makes WHERE name = 'Jeep';

-- ==========================================================
-- 4. SEED DE GERAÇÕES (GENERATIONS)
-- ==========================================================
-- (Simplificado: Criando uma geração padrão para cada modelo para o seed funcionar)

INSERT INTO generations (model_id, name)
SELECT id, 'Atual/Última' FROM models;

-- ==========================================================
-- 5. SEED DE VEÍCULOS (DATA)
-- ==========================================================

-- HATCHS
INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Gol 1.0 MPI', 2022, 'FWD', 84, 101, 13.5, 170, 950, 55, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Gol' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Gol 1.6 MSI', 2022, 'FWD', 104, 153, 10.5, 184, 1018, 55, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Gol' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Up! MPI', 2020, 'FWD', 82, 101, 13.0, 165, 930, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Up!' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Up! TSI', 2020, 'FWD', 105, 165, 9.1, 184, 951, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Up!' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Polo MPI', 2024, 'FWD', 84, 101, 13.4, 170, 1084, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Polo' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Polo TSI', 2024, 'FWD', 116, 165, 10.0, 192, 1115, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Polo' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Polo GTS', 2024, 'FWD', 150, 250, 8.3, 207, 1271, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Polo' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Onix 1.0', 2024, 'FWD', 82, 104, 13.2, 167, 1034, 44, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Onix' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Onix 1.0 Turbo', 2024, 'FWD', 116, 160, 10.1, 187, 1087, 44, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Onix' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'HB20 1.0', 2024, 'FWD', 80, 102, 14.0, 161, 989, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='HB20' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'HB20 1.0 Turbo', 2024, 'FWD', 120, 172, 10.7, 190, 1055, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='HB20' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Argo 1.0', 2024, 'FWD', 75, 107, 14.2, 162, 1070, 48, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Argo' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Argo 1.3 CVT', 2024, 'FWD', 107, 134, 11.8, 177, 1135, 48, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Argo' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Kwid 1.0', 2024, 'FWD', 71, 98, 13.5, 156, 818, 38, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Kwid' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Sandero 1.0', 2021, 'FWD', 82, 105, 13.0, 166, 1000, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Sandero' LIMIT 1;

-- SEDANS
INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Virtus TSI', 2024, 'FWD', 116, 165, 10.2, 193, 1170, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Virtus' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Virtus Exclusive 250 TSI', 2024, 'FWD', 150, 250, 8.7, 210, 1238, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Virtus' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Corolla GLi 2.0', 2024, 'FWD', 175, 210, 9.6, 195, 1380, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Corolla' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Corolla XEi 2.0', 2024, 'FWD', 175, 210, 9.2, 199, 1390, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Corolla' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'City Touring', 2024, 'FWD', 126, 152, 10.5, 190, 1155, 40, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='City' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Versa Exclusive', 2024, 'FWD', 113, 154, 10.9, 180, 1136, 41, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Versa' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Cronos 1.3 CVT', 2024, 'FWD', 107, 134, 11.5, 176, 1145, 48, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Cronos' LIMIT 1;

-- SUVs
INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'T-Cross 200 TSI', 2024, 'FWD', 128, 200, 10.1, 193, 1230, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='T-Cross' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'T-Cross Highline', 2024, 'FWD', 150, 250, 8.6, 202, 1276, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='T-Cross' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Nivus Comfortline', 2024, 'FWD', 128, 200, 10.0, 189, 1199, 52, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Nivus' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Tracker 1.0 Turbo', 2024, 'FWD', 116, 160, 10.7, 177, 1269, 44, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Tracker' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Tracker 1.2 Turbo', 2024, 'FWD', 133, 210, 9.7, 185, 1275, 44, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Tracker' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Compass Sport T270', 2024, 'FWD', 185, 270, 8.8, 206, 1546, 60, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Compass' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Compass Longitude Diesel 4x4', 2021, 'AWD', 170, 350, 10.3, 190, 1675, 60, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Compass' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Renegade 1.3 Turbo', 2024, 'FWD', 185, 270, 8.7, 210, 1490, 55, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Renegade' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Creta Comfort 1.0 Turbo', 2024, 'FWD', 120, 172, 11.0, 180, 1270, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Creta' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Creta Ultimate 1.6 Turbo', 2024, 'FWD', 193, 265, 7.8, 210, 1345, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Creta' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Kicks Sense', 2024, 'FWD', 113, 154, 11.8, 175, 1142, 41, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Kicks' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Pulse Drive Turbo 200', 2024, 'FWD', 130, 200, 9.4, 189, 1234, 47, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Pulse' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Pulse Abarth', 2024, 'FWD', 185, 270, 7.6, 215, 1290, 47, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Pulse' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Fastback Turbo 200', 2024, 'FWD', 130, 200, 9.4, 196, 1260, 47, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Fastback' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Fastback Abarth', 2024, 'FWD', 185, 270, 7.8, 220, 1330, 47, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Fastback' LIMIT 1;

-- EXTRAS
INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Jetta GLI', 2024, 'FWD', 231, 350, 6.7, 249, 1430, 50, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Jetta' LIMIT 1;

INSERT INTO vehicles (generation_id, trim, year_from, drive_type, power_hp, torque_nm, zero_to_100_s, top_speed_kmh, curb_weight_kg, tank_capacity_l, featured)
SELECT g.id, 'Civic Touring Turbo', 2021, 'FWD', 173, 220, 8.6, 215, 1312, 56, true FROM generations g JOIN models m ON m.id=g.model_id WHERE m.name='Civic' LIMIT 1;

COMMIT;