Este script está estruturado para ser executado em ordem no SQL Editor do Supabase ou como um arquivo de migração.

1. Instruções para Execução

    Copie todo o conteúdo do bloco de código abaixo.

    Abra o SQL Editor no seu projeto Supabase.

    Execute o script na íntegra.

2. Script de Criação

```sql

--------------------------------------
-- 1. CONFIGURAÇÃO DE SEGURANÇA E ROLES
--------------------------------------
-- Set the search path to public for convenience
SET search_path = public;

-- Garante que o usuário 'authenticated' (role padrão do Supabase) possa usar o schema public
GRANT USAGE ON SCHEMA public TO authenticated;

--------------------------------------
-- 2. SEQUÊNCIAS (Para IDs auto-incrementáveis)
--------------------------------------

CREATE SEQUENCE IF NOT EXISTS doctor_access_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS doctors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS patient_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS patients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--------------------------------------
-- 3. CRIAÇÃO DE TABELAS (e constraints iniciais)
--------------------------------------

-- users é criado primeiro pois é FK de doctors e patients
CREATE TABLE IF NOT EXISTS public.users (
    id uuid NOT NULL,
    name character varying NOT NULL,
    birth_date date,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT users_pkey PRIMARY KEY (id),
    -- FK para a tabela auth.users do Supabase
    CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.doctors (
    id integer NOT NULL DEFAULT nextval('doctors_id_seq'::regclass),
    user_id uuid NOT NULL UNIQUE,
    crm character varying,
    CONSTRAINT doctors_pkey PRIMARY KEY (id),
    CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

CREATE TABLE IF NOT EXISTS public.patients (
    id integer NOT NULL DEFAULT nextval('patients_id_seq'::regclass),
    user_id uuid NOT NULL UNIQUE,
    CONSTRAINT patients_pkey PRIMARY KEY (id),
    CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

CREATE TABLE IF NOT EXISTS public.tests (
    id integer NOT NULL DEFAULT nextval('tests_id_seq'::regclass),
    name character varying NOT NULL,
    average_score double precision,
    average_time double precision,
    CONSTRAINT tests_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.doctor_access (
    id integer NOT NULL DEFAULT nextval('doctor_access_id_seq'::regclass),
    doctor_id integer NOT NULL,
    patient_id integer NOT NULL,
    confirmed boolean DEFAULT false,
    confirmation_token character varying UNIQUE,
    token_expires_at timestamp with time zone,
    CONSTRAINT doctor_access_pkey PRIMARY KEY (id),
    CONSTRAINT doctor_access_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id),
    CONSTRAINT doctor_access_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id)
);

CREATE TABLE IF NOT EXISTS public.patient_tests (
    id integer NOT NULL DEFAULT nextval('patient_tests_id_seq'::regclass),
    patient_id integer,
    test_id integer,
    score double precision,
    time_spent double precision,
    test_date timestamp with time zone,
    average_time real,
    doctor_id uuid, -- NOTE: Esta FK aponta para auth.users, não public.doctors, como é o caso de user_id
    CONSTRAINT patient_tests_pkey PRIMARY KEY (id),
    CONSTRAINT patient_tests_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
    CONSTRAINT patient_tests_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.tests(id),
    CONSTRAINT patient_tests_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES auth.users(id)
);


--------------------------------------
-- 4. INSERTS DE DADOS INICIAIS
--------------------------------------

INSERT INTO public.tests (name, average_score, average_time) VALUES
('Stroop Test', 65.0, NULL),
('Trail Making Test', NULL, 66.0),
('Teste de Memória Verbal', 80.0, NULL)
ON CONFLICT (id) DO NOTHING;


--------------------------------------
-- 5. FUNÇÕES E TRIGGERS
--------------------------------------

-- 5.1. FUNÇÃO: Criar usuário automaticamente ao registrar no auth
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger AS $$
DECLARE
    crm_value text;
BEGIN
    -- Pega o CRM do metadado (pode ser null)
    crm_value := new.raw_user_meta_data ->> 'crm';

    -- 1. Cria o usuário na tabela users
    INSERT INTO public.users (id, name, birth_date)
    VALUES (
        new.id, 
        new.raw_user_meta_data ->> 'name', 
        to_date(new.raw_user_meta_data ->> 'birth_date', 'YYYY-MM-DD')
    );

    -- 2. Decide se cria paciente ou médico baseado na presença do CRM
    IF crm_value IS NOT NULL AND length(trim(crm_value)) > 0 THEN
        -- É médico - insere na tabela doctors
        INSERT INTO public.doctors (user_id, crm) 
        VALUES (new.id, crm_value);
    ELSE
        -- É paciente - insere na tabela patients 
        INSERT INTO public.patients (user_id) 
        VALUES (new.id);
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- TRIGGER: Executar handle_new_auth_user após inserção em auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE PROCEDURE public.handle_new_auth_user();

-- 5.2. FUNÇÃO RPC: Buscar usuário por email
CREATE OR REPLACE FUNCTION public.search_user_by_email(user_email TEXT)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    birth_date DATE,
    email VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u.birth_date,
        au.email
    FROM public.users u
    INNER JOIN auth.users au ON u.id = au.id
    WHERE au.email = user_email
    AND EXISTS (SELECT 1 FROM public.patients p WHERE p.user_id = u.id);
END;
$$;

-- 5.3. FUNÇÃO RPC: Listar pacientes de um médico
CREATE OR REPLACE FUNCTION public.get_doctor_patients(doctor_user_id UUID)
RETURNS TABLE (
    patient_id INT,
    user_id UUID,
    name VARCHAR,
    birth_date DATE,
    email VARCHAR,
    confirmed BOOLEAN,
    confirmation_token VARCHAR,
    token_expires_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as patient_id,
        p.user_id,
        u.name,
        u.birth_date,
        au.email,
        da.confirmed,
        da.confirmation_token,
        da.token_expires_at
    FROM public.doctor_access da
    INNER JOIN public.doctors d ON da.doctor_id = d.id
    INNER JOIN public.patients p ON da.patient_id = p.id
    INNER JOIN public.users u ON p.user_id = u.id
    INNER JOIN auth.users au ON u.id = au.id
    WHERE d.user_id = doctor_user_id;
END;
$$;

-- 5.4. FUNÇÃO RPC: Confirmar acesso do médico aos dados do paciente
CREATE OR REPLACE FUNCTION public.confirm_patient_access(token VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    access_record RECORD;
BEGIN
    -- Buscar registro pelo token
    SELECT * INTO access_record
    FROM public.doctor_access
    WHERE confirmation_token = token
    AND token_expires_at > NOW()
    AND confirmed = FALSE;

    -- Se não encontrou ou expirado
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Confirmar acesso
    UPDATE public.doctor_access
    SET confirmed = TRUE,
        confirmation_token = NULL,
        token_expires_at = NULL
    WHERE id = access_record.id;

    RETURN TRUE;
END;
$$;

-- 5.5. FUNÇÃO RPC: Deletar conta do usuário (cascata)
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Pega o ID do usuário autenticado
    user_uuid := auth.uid();
    
    IF user_uuid IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'Não autenticado');
    END IF;

    -- Deletar da tabela users (cascata vai deletar o resto)
    DELETE FROM public.users WHERE id = user_uuid;
    
    -- Deletar do auth.users
    DELETE FROM auth.users WHERE id = user_uuid;
    
    RETURN json_build_object('success', true);
END;
$$;


--------------------------------------
-- 6. POLICIES DE SEGURANÇA EM NÍVEL DE LINHA (RLS)
--------------------------------------

-- ATENÇÃO: Habilita RLS em todas as tabelas relevantes antes de aplicar policies
ALTER TABLE public.doctor_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 6.1. doctor_access Policies
DROP POLICY IF EXISTS "Doctor can see own access records" ON public.doctor_access;
CREATE POLICY "Doctor can see own access records" ON public.doctor_access FOR ALL TO PUBLIC USING ((EXISTS ( SELECT 1 FROM doctors WHERE ((doctors.id = doctor_access.doctor_id) AND (doctors.user_id = auth.uid())))));

DROP POLICY IF EXISTS "Patient can see doctor access to self" ON public.doctor_access;
CREATE POLICY "Patient can see doctor access to self" ON public.doctor_access FOR ALL TO PUBLIC USING ((EXISTS ( SELECT 1 FROM (patients JOIN users ON ((patients.user_id = users.id))) WHERE ((patients.id = doctor_access.patient_id) AND (users.id = auth.uid())))));

DROP POLICY IF EXISTS "doctor_can_insert_access" ON public.doctor_access;
CREATE POLICY "doctor_can_insert_access" ON public.doctor_access FOR INSERT TO PUBLIC WITH CHECK ((EXISTS ( SELECT 1 FROM doctors WHERE ((doctors.id = doctor_access.doctor_id) AND (doctors.user_id = auth.uid())))));

DROP POLICY IF EXISTS "doctor_can_update_access" ON public.doctor_access;
CREATE POLICY "doctor_can_update_access" ON public.doctor_access FOR UPDATE TO PUBLIC USING ((EXISTS ( SELECT 1 FROM doctors WHERE ((doctors.id = doctor_access.doctor_id) AND (doctors.user_id = auth.uid())))));

-- 6.2. doctors Policies
DROP POLICY IF EXISTS "Doctor can see own doctor profile" ON public.doctors;
CREATE POLICY "Doctor can see own doctor profile" ON public.doctors FOR ALL TO PUBLIC USING ((user_id = auth.uid()));

-- 6.3. patient_tests Policies
DROP POLICY IF EXISTS "Doctor with access can see patient's tests" ON public.patient_tests;
CREATE POLICY "Doctor with access can see patient's tests" ON public.patient_tests FOR ALL TO PUBLIC USING ((EXISTS ( SELECT 1 FROM (doctor_access JOIN doctors ON ((doctors.id = doctor_access.doctor_id))) WHERE ((doctor_access.patient_id = patient_tests.patient_id) AND (doctors.user_id = auth.uid()) AND doctor_access.confirmed = true))));

DROP POLICY IF EXISTS "Patient can see own test results" ON public.patient_tests;
CREATE POLICY "Patient can see own test results" ON public.patient_tests FOR ALL TO PUBLIC USING ((EXISTS ( SELECT 1 FROM (patients JOIN users ON ((users.id = patients.user_id))) WHERE ((patients.id = patient_tests.patient_id) AND (users.id = auth.uid())))));

-- 6.4. patients Policies
DROP POLICY IF EXISTS "Patient can see own profile" ON public.patients;
CREATE POLICY "Patient can see own profile" ON public.patients FOR ALL TO PUBLIC USING ((EXISTS ( SELECT 1 FROM users WHERE ((users.id = auth.uid()) AND (users.id = patients.user_id)))));

DROP POLICY IF EXISTS "doctor_can_insert_patients" ON public.patients;
CREATE POLICY "doctor_can_insert_patients" ON public.patients FOR INSERT TO PUBLIC WITH CHECK (true);

DROP POLICY IF EXISTS "doctor_can_search_all_patients" ON public.patients;
CREATE POLICY "doctor_can_search_all_patients" ON public.patients FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1 FROM doctors WHERE (doctors.user_id = auth.uid()))));

-- 6.5. tests Policies
DROP POLICY IF EXISTS "Authenticated users can select tests" ON public.tests;
CREATE POLICY "Authenticated users can select tests" ON public.tests FOR SELECT TO PUBLIC USING ((auth.role() = 'authenticated'::text));

DROP POLICY IF EXISTS "Enable read access for all users" ON public.tests;
CREATE POLICY "Enable read access for all users" ON public.tests FOR SELECT TO PUBLIC USING (true);

-- 6.6. users Policies
DROP POLICY IF EXISTS "allow_user_insert" ON public.users;
CREATE POLICY "allow_user_insert" ON public.users FOR INSERT TO PUBLIC WITH CHECK (true);

DROP POLICY IF EXISTS "doctor_can_read_users" ON public.users;
CREATE POLICY "doctor_can_read_users" ON public.users FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1 FROM doctors WHERE (doctors.user_id = auth.uid()))));

DROP POLICY IF EXISTS "users_insert" ON public.users;
CREATE POLICY "users_insert" ON public.users FOR INSERT TO PUBLIC WITH CHECK ((auth.uid() = id));

DROP POLICY IF EXISTS "users_select" ON public.users;
CREATE POLICY "users_select" ON public.users FOR SELECT TO PUBLIC USING ((id = auth.uid()));

-- 6.7. Default Policy: Pacientes
DROP POLICY IF EXISTS "Patients can select all tests" ON public.tests;
CREATE POLICY "Patients can select all tests" ON public.tests FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1 FROM patients WHERE (patients.user_id = auth.uid()))));

```