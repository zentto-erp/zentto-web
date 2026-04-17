-- +goose Up

-- ESPAÑA — Funciones validacion NIF/NIE/CIF/IBAN
-- Fuente: Real Decreto 1065/2007 (NIF/CIF), IBAN spec ISO 13616.

-- ─── fn_validate_nif_es — Valida DNI (8 digitos + letra control) ─────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.fn_validate_nif_es(p_nif VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  v_letters CONSTANT TEXT := 'TRWAGMYFPDXBNJZSQVHLCKE';
  v_nif     VARCHAR;
  v_num     INTEGER;
  v_letter  CHAR(1);
  v_expected CHAR(1);
BEGIN
  IF p_nif IS NULL THEN RETURN FALSE; END IF;
  v_nif := UPPER(TRIM(p_nif));

  -- Formato: 8 digitos + 1 letra
  IF v_nif !~ '^[0-9]{8}[A-Z]$' THEN
    RETURN FALSE;
  END IF;

  v_num := SUBSTRING(v_nif FROM 1 FOR 8)::INTEGER;
  v_letter := SUBSTRING(v_nif FROM 9 FOR 1);
  v_expected := SUBSTRING(v_letters FROM (v_num % 23) + 1 FOR 1);

  RETURN v_letter = v_expected;
END;
$$;
-- +goose StatementEnd

-- ─── fn_validate_nie_es — Valida NIE (X/Y/Z + 7 digitos + letra) ─────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.fn_validate_nie_es(p_nie VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  v_letters CONSTANT TEXT := 'TRWAGMYFPDXBNJZSQVHLCKE';
  v_nie     VARCHAR;
  v_prefix  CHAR(1);
  v_prefix_num INTEGER;
  v_num     INTEGER;
  v_letter  CHAR(1);
  v_expected CHAR(1);
BEGIN
  IF p_nie IS NULL THEN RETURN FALSE; END IF;
  v_nie := UPPER(TRIM(p_nie));

  -- Formato: X/Y/Z + 7 digitos + 1 letra
  IF v_nie !~ '^[XYZ][0-9]{7}[A-Z]$' THEN
    RETURN FALSE;
  END IF;

  v_prefix := SUBSTRING(v_nie FROM 1 FOR 1);
  v_prefix_num := CASE v_prefix WHEN 'X' THEN 0 WHEN 'Y' THEN 1 WHEN 'Z' THEN 2 END;
  v_num := (v_prefix_num::TEXT || SUBSTRING(v_nie FROM 2 FOR 7))::INTEGER;
  v_letter := SUBSTRING(v_nie FROM 9 FOR 1);
  v_expected := SUBSTRING(v_letters FROM (v_num % 23) + 1 FOR 1);

  RETURN v_letter = v_expected;
END;
$$;
-- +goose StatementEnd

-- ─── fn_validate_cif_es — Valida CIF empresas espanolas ──────────────
-- Algoritmo oficial CIF (letra organizacion + 7 digitos + control)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.fn_validate_cif_es(p_cif VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  v_cif         VARCHAR;
  v_letter      CHAR(1);
  v_digits      VARCHAR(7);
  v_control     CHAR(1);
  v_sum_even    INTEGER := 0;
  v_sum_odd     INTEGER := 0;
  v_total       INTEGER;
  v_calc        INTEGER;
  v_expected_d  CHAR(1);
  v_expected_l  CHAR(1);
  v_letters_map CONSTANT TEXT := 'JABCDEFGHI';
  i INTEGER;
  v_digit INTEGER;
  v_double INTEGER;
BEGIN
  IF p_cif IS NULL THEN RETURN FALSE; END IF;
  v_cif := UPPER(TRIM(p_cif));

  -- Formato: letra + 7 digitos + (digito o letra)
  IF v_cif !~ '^[ABCDEFGHJNPQRSUVW][0-9]{7}[0-9A-J]$' THEN
    RETURN FALSE;
  END IF;

  v_letter := SUBSTRING(v_cif FROM 1 FOR 1);
  v_digits := SUBSTRING(v_cif FROM 2 FOR 7);
  v_control := SUBSTRING(v_cif FROM 9 FOR 1);

  -- Calculo del digito de control
  FOR i IN 1..7 LOOP
    v_digit := SUBSTRING(v_digits FROM i FOR 1)::INTEGER;
    IF i % 2 = 1 THEN
      -- Posiciones impares: multiplicar por 2 y sumar digitos
      v_double := v_digit * 2;
      v_sum_odd := v_sum_odd + (v_double / 10) + (v_double % 10);
    ELSE
      -- Posiciones pares: sumar directo
      v_sum_even := v_sum_even + v_digit;
    END IF;
  END LOOP;

  v_total := v_sum_even + v_sum_odd;
  v_calc := (10 - (v_total % 10)) % 10;

  -- Si la letra es P, Q, R, S, N, W: control es letra (J-indexed map)
  -- Si es A, B, E, H: control es digito
  -- Resto (C, D, F, G, J, U, V): puede ser digito o letra
  IF v_letter IN ('P','Q','R','S','N','W') THEN
    v_expected_l := SUBSTRING(v_letters_map FROM v_calc + 1 FOR 1);
    RETURN v_control = v_expected_l;
  ELSIF v_letter IN ('A','B','E','H') THEN
    v_expected_d := v_calc::TEXT;
    RETURN v_control = v_expected_d;
  ELSE
    -- Flexibilidad: acepta ambos
    v_expected_d := v_calc::TEXT;
    v_expected_l := SUBSTRING(v_letters_map FROM v_calc + 1 FOR 1);
    RETURN v_control = v_expected_d OR v_control = v_expected_l;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── fn_validate_iban_es — Valida IBAN espanol (ES + 22 chars) ──────
-- Algoritmo ISO 13616 MOD-97 check
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.fn_validate_iban_es(p_iban VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  v_iban   VARCHAR;
  v_moved  VARCHAR;
  v_numeric VARCHAR := '';
  i INTEGER;
  c CHAR(1);
  v_code INTEGER;
  v_check NUMERIC;
BEGIN
  IF p_iban IS NULL THEN RETURN FALSE; END IF;
  v_iban := UPPER(REGEXP_REPLACE(TRIM(p_iban), '\s', '', 'g'));

  -- IBAN ES: 24 caracteres (ES + 2 control + 20 BBAN)
  IF v_iban !~ '^ES[0-9]{22}$' THEN
    RETURN FALSE;
  END IF;

  -- Mover primeros 4 chars al final
  v_moved := SUBSTRING(v_iban FROM 5) || SUBSTRING(v_iban FROM 1 FOR 4);

  -- Convertir letras a numeros (A=10, B=11, ... Z=35)
  FOR i IN 1..LENGTH(v_moved) LOOP
    c := SUBSTRING(v_moved FROM i FOR 1);
    IF c BETWEEN '0' AND '9' THEN
      v_numeric := v_numeric || c;
    ELSE
      v_code := ASCII(c) - ASCII('A') + 10;
      v_numeric := v_numeric || v_code::TEXT;
    END IF;
  END LOOP;

  -- MOD 97 debe dar 1
  v_check := v_numeric::NUMERIC % 97;
  RETURN v_check = 1;
END;
$$;
-- +goose StatementEnd

-- ─── Tests inline (verificacion funcional) ───────────────────────────
-- SELECT fn_validate_nif_es('12345678Z');  -- debe dar TRUE (12345678 % 23 = 14, letra E... wait no)
-- Actualmente 12345678 % 23 = 14 → T. Usa test real:
-- SELECT fn_validate_nif_es('00000000T');  -- 0 % 23 = 0 → T → TRUE
-- SELECT fn_validate_cif_es('A58818501'); -- Banco Santander, TRUE
-- SELECT fn_validate_iban_es('ES9121000418450200051332'); -- CaixaBank, TRUE

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.fn_validate_nif_es(VARCHAR);
DROP FUNCTION IF EXISTS public.fn_validate_nie_es(VARCHAR);
DROP FUNCTION IF EXISTS public.fn_validate_cif_es(VARCHAR);
DROP FUNCTION IF EXISTS public.fn_validate_iban_es(VARCHAR);
-- +goose StatementEnd
