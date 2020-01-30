--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.15
-- Dumped by pg_dump version 11.5 (Ubuntu 11.5-3.pgdg18.04+1)

-- Started on 2020-01-30 18:36:39 WET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 98536)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2530 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 291 (class 1255 OID 99879)
-- Name: atualiza_ps(json, integer, text); Type: FUNCTION; Schema: public; Owner: ptdw-2019-gr1
--

CREATE FUNCTION public.atualiza_ps(pedido json, log_id integer, email_utilizador text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	ps_id integer := (SELECT id FROM utilizador WHERE email ILIKE email_utilizador);
	tipo_ps_id integer := (SELECT id FROM tipos WHERE nome ILIKE '%Profissional%Saude%');
	tempo_atual timestamp := current_timestamp;
	u_s_id integer;
	u_s_ativo boolean;
	u_t_id integer;
	u_t_ativo boolean;
BEGIN
	-- unidades de saúde
	FOR u_s_id, u_s_ativo IN SELECT unidade_saude_id, ativo FROM utilizador_unidade_saude WHERE utilizador_id = ps_id LOOP
	
		IF pedido::jsonb -> 'edit_ps_health_unit' ? u_s_id::text = false THEN
		
			UPDATE utilizador_unidade_saude
			SET data_update = tempo_atual, ativo = false, log_utilizador_id = log_id
			WHERE utilizador_id = ps_id AND unidade_saude_id = u_s_id;
			
		ELSIF u_s_ativo = false THEN
		
			UPDATE utilizador_unidade_saude
			SET data_update = tempo_atual, ativo = true, log_utilizador_id = log_id
			WHERE utilizador_id = ps_id AND unidade_saude_id = u_s_id;
			
		END IF;
   
	END LOOP;

	FOR c IN 0..json_array_length(pedido->'edit_ps_health_unit') - 1 LOOP
	
		IF NOT EXISTS (SELECT * FROM utilizador_unidade_saude WHERE utilizador_id = ps_id AND unidade_saude_id = (pedido -> 'edit_ps_health_unit' ->>(c))::integer) THEN
			INSERT INTO utilizador_unidade_saude
			VALUES(DEFAULT, ps_id, (pedido -> 'edit_ps_health_unit' ->>(c))::integer, DEFAULT, NULL, TRUE, log_id);
		END IF;
		
	END LOOP;

		-- tipos de utilizador
		FOR u_t_id, u_t_ativo IN SELECT tipo_id, ativo FROM utilizador_tipo WHERE utilizador_id = ps_id LOOP

			IF u_t_id <> tipo_ps_id THEN
	
				IF (pedido::jsonb ? 'edit_ps_type' IS false OR pedido::jsonb -> 'edit_ps_type' ? u_t_id::text IS false) AND u_t_ativo = true THEN

		raise notice '1º if';
					UPDATE utilizador_tipo
					SET data_update = tempo_atual, ativo = false, log_utilizador_id = log_id
					WHERE utilizador_id = ps_id AND tipo_id = u_t_id;
			
				ELSIF pedido::jsonb -> 'edit_ps_type' ? u_t_id::text IS true AND u_t_ativo = false THEN
		raise notice '2º if';	
					UPDATE utilizador_tipo
					SET data_update = tempo_atual, ativo = true, log_utilizador_id = log_id
					WHERE utilizador_id = ps_id AND tipo_id = u_t_id;
			
				END IF;
			
			END IF;
   
		END LOOP;

	IF pedido::jsonb ? 'edit_ps_type' IS true THEN

		FOR c IN 0..json_array_length(pedido->'edit_ps_type') - 1 LOOP
	
			IF NOT EXISTS (SELECT * FROM utilizador_tipo WHERE utilizador_id = ps_id AND tipo_id = (pedido -> 'edit_ps_type' ->>(c))::integer) THEN
		
				INSERT INTO utilizador_tipo
				VALUES(DEFAULT, ps_id, (pedido -> 'edit_ps_type' ->>(c))::integer, DEFAULT, NULL, TRUE, log_id);
			
			END IF;
		
		END LOOP;
	
	END IF;

	IF pedido ->> 'edit_ps_function' IS NULL THEN

		UPDATE utilizador
		SET funcao_id = NULL, data_update = tempo_atual, log_utilizador_id = log_id
		WHERE id = ps_id;

	ELSIF NOT EXISTS (SELECT * FROM utilizador WHERE funcao_id = (pedido -> 'edit_ps_function' ->>(0))::integer AND id = ps_id) THEN
		
		UPDATE utilizador
		SET funcao_id = (pedido -> 'edit_ps_function' ->>(0))::integer, data_update = tempo_atual, log_utilizador_id = log_id
		WHERE id = ps_id;
		
	END IF;
END;
$$;


ALTER FUNCTION public.atualiza_ps(pedido json, log_id integer, email_utilizador text) OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 289 (class 1255 OID 98600)
-- Name: audit_trigger(); Type: FUNCTION; Schema: public; Owner: ptdw-2019-gr1
--

CREATE FUNCTION public.audit_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
	BEGIN
		IF TG_OP = 'INSERT' THEN
		INSERT INTO logs (tabela, operacao, utilizador_id, novo_registo)
		VALUES (TG_RELNAME, TG_OP, NEW.log_utilizador_id, row_to_json(NEW));
		RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
		INSERT INTO logs (tabela, operacao, utilizador_id, novo_registo, antigo_registo)
		VALUES (TG_RELNAME, TG_OP, NEW.log_utilizador_id, row_to_json(NEW), row_to_json(OLD));
		RETURN NEW;
	END IF;
END;
$$;


ALTER FUNCTION public.audit_trigger() OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 290 (class 1255 OID 99680)
-- Name: registo_ps(json, integer); Type: FUNCTION; Schema: public; Owner: ptdw-2019-gr1
--

CREATE FUNCTION public.registo_ps(pedido json, log_utilizador_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	ps_id integer;
	ps_tipo integer := (SELECT id FROM tipos WHERE nome ILIKE '%Profissional%Saude%');
BEGIN
	INSERT INTO utilizador VALUES(DEFAULT, pedido ->> 'ps_name', pedido ->> 'ps_password', CAST(pedido ->> 'ps_contact' AS integer), pedido ->> 'ps_email', NULL, CAST(pedido ->> 'ps_function' AS integer), 
	DEFAULT, NULL, NULL, TRUE, log_utilizador_id) RETURNING id INTO ps_id;

	FOR c IN 0..json_array_length(pedido->'ps_health_unit') - 1 LOOP
		INSERT INTO utilizador_unidade_saude
		VALUES(DEFAULT, ps_id, (pedido -> 'ps_health_unit' ->>(c))::integer, DEFAULT, NULL, TRUE, log_utilizador_id);
	END LOOP;

	INSERT INTO utilizador_tipo VALUES(DEFAULT, ps_id, ps_tipo, DEFAULT, NULL, TRUE, log_utilizador_id);

	IF pedido::jsonb ? 'ps_type' IS true THEN

		FOR c IN 0..json_array_length(pedido->'ps_type') - 1 LOOP
			INSERT INTO utilizador_tipo
			VALUES(DEFAULT, ps_id, (pedido -> 'ps_type' ->>(c))::integer, DEFAULT, NULL, TRUE, log_utilizador_id);
		END LOOP;
		
	END IF;
END;
$$;


ALTER FUNCTION public.registo_ps(pedido json, log_utilizador_id integer) OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 263 (class 1255 OID 98523)
-- Name: strip_all_triggers(); Type: FUNCTION; Schema: public; Owner: ptdw-2019-gr1
--

CREATE FUNCTION public.strip_all_triggers() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$ DECLARE
    triggNameRecord RECORD;
    triggTableRecord RECORD;
BEGIN
    FOR triggNameRecord IN select distinct(trigger_name) from information_schema.triggers where trigger_schema = 'public' LOOP
        FOR triggTableRecord IN SELECT distinct(event_object_table) from information_schema.triggers where trigger_name = triggNameRecord.trigger_name LOOP
            RAISE NOTICE 'Dropping trigger: % on table: %', triggNameRecord.trigger_name, triggTableRecord.event_object_table;
            EXECUTE 'DROP TRIGGER ' || triggNameRecord.trigger_name || ' ON ' || triggTableRecord.event_object_table || ';';
        END LOOP;
    END LOOP;

    RETURN 'done';
END;
$$;


ALTER FUNCTION public.strip_all_triggers() OWNER TO "ptdw-2019-gr1";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 216 (class 1259 OID 104396)
-- Name: alerta; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.alerta (
    id bigint NOT NULL,
    resolvido boolean NOT NULL,
    comentario text,
    descricao_alerta_id integer NOT NULL,
    paciente_id integer NOT NULL,
    tipo_alerta_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.alerta OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 215 (class 1259 OID 104394)
-- Name: alerta_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.alerta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alerta_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2531 (class 0 OID 0)
-- Dependencies: 215
-- Name: alerta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.alerta_id_seq OWNED BY public.alerta.id;


--
-- TOC entry 208 (class 1259 OID 104355)
-- Name: descricao_alerta; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.descricao_alerta (
    id bigint NOT NULL,
    mensagem text NOT NULL
);


ALTER TABLE public.descricao_alerta OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 207 (class 1259 OID 104353)
-- Name: descricao_alerta_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.descricao_alerta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.descricao_alerta_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2532 (class 0 OID 0)
-- Dependencies: 207
-- Name: descricao_alerta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.descricao_alerta_id_seq OWNED BY public.descricao_alerta.id;


--
-- TOC entry 210 (class 1259 OID 104366)
-- Name: doenca; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.doenca (
    id bigint NOT NULL,
    nome text NOT NULL,
    descricao text
);


ALTER TABLE public.doenca OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 209 (class 1259 OID 104364)
-- Name: doenca_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.doenca_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.doenca_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2533 (class 0 OID 0)
-- Dependencies: 209
-- Name: doenca_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.doenca_id_seq OWNED BY public.doenca.id;


--
-- TOC entry 212 (class 1259 OID 104377)
-- Name: doenca_paciente; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.doenca_paciente (
    id bigint NOT NULL,
    doenca_id integer NOT NULL,
    paciente_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.doenca_paciente OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 211 (class 1259 OID 104375)
-- Name: doenca_paciente_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.doenca_paciente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.doenca_paciente_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2534 (class 0 OID 0)
-- Dependencies: 211
-- Name: doenca_paciente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.doenca_paciente_id_seq OWNED BY public.doenca_paciente.id;


--
-- TOC entry 198 (class 1259 OID 104302)
-- Name: equipamentos; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.equipamentos (
    id bigint NOT NULL,
    nome text NOT NULL,
    access_token character varying(255),
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean DEFAULT true NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.equipamentos OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 197 (class 1259 OID 104300)
-- Name: equipamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.equipamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipamentos_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2535 (class 0 OID 0)
-- Dependencies: 197
-- Name: equipamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.equipamentos_id_seq OWNED BY public.equipamentos.id;


--
-- TOC entry 192 (class 1259 OID 104263)
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 191 (class 1259 OID 104261)
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.failed_jobs_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2536 (class 0 OID 0)
-- Dependencies: 191
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- TOC entry 234 (class 1259 OID 104487)
-- Name: funcao; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.funcao (
    id bigint NOT NULL,
    nome text NOT NULL
);


ALTER TABLE public.funcao OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 233 (class 1259 OID 104485)
-- Name: funcao_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.funcao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.funcao_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2537 (class 0 OID 0)
-- Dependencies: 233
-- Name: funcao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.funcao_id_seq OWNED BY public.funcao.id;


--
-- TOC entry 222 (class 1259 OID 104429)
-- Name: historico_configuracoes; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.historico_configuracoes (
    id bigint NOT NULL,
    emg_min double precision,
    emg_max double precision,
    bpm_min integer,
    bpm_max integer,
    paciente_id integer NOT NULL,
    equipamento_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    esta_associado boolean DEFAULT false NOT NULL
);


ALTER TABLE public.historico_configuracoes OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 221 (class 1259 OID 104427)
-- Name: historico_configuracoes_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.historico_configuracoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.historico_configuracoes_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2538 (class 0 OID 0)
-- Dependencies: 221
-- Name: historico_configuracoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.historico_configuracoes_id_seq OWNED BY public.historico_configuracoes.id;


--
-- TOC entry 230 (class 1259 OID 104468)
-- Name: historico_valores; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.historico_valores (
    id bigint NOT NULL,
    emg double precision NOT NULL,
    bc integer NOT NULL,
    paciente_id integer NOT NULL,
    equipamento_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.historico_valores OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 218 (class 1259 OID 104407)
-- Name: paciente; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.paciente (
    id bigint NOT NULL,
    nome text NOT NULL,
    sexo character(1) NOT NULL,
    data_nascimento date NOT NULL,
    data_diagnostico date NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean NOT NULL,
    log_utilizador_id integer NOT NULL,
    unidade_saude_id integer
);


ALTER TABLE public.paciente OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 239 (class 1259 OID 104747)
-- Name: historico_pacientes; Type: VIEW; Schema: public; Owner: ptdw-2019-gr1
--

CREATE VIEW public.historico_pacientes AS
 SELECT h.paciente_id,
    p.nome,
    jsonb_agg(DISTINCT e.nome ORDER BY e.nome) AS equipamento,
    round((avg(h.emg))::numeric, 2) AS valor_emg,
    round(avg(h.bc), 2) AS valor_bc
   FROM ((public.historico_valores h
     JOIN public.equipamentos e ON ((e.id = h.equipamento_id)))
     JOIN public.paciente p ON ((p.id = h.paciente_id)))
  GROUP BY h.paciente_id, p.nome
  ORDER BY p.nome;


ALTER TABLE public.historico_pacientes OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 232 (class 1259 OID 104476)
-- Name: unidade_saude; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.unidade_saude (
    id bigint NOT NULL,
    nome text NOT NULL,
    morada text NOT NULL,
    telefone integer NOT NULL,
    email text NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.unidade_saude OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 237 (class 1259 OID 104619)
-- Name: historico_unidades_saude; Type: VIEW; Schema: public; Owner: ptdw-2019-gr1
--

CREATE VIEW public.historico_unidades_saude AS
 SELECT h.paciente_id,
    p.nome,
    jsonb_agg(DISTINCT e.nome ORDER BY e.nome) AS equipamento,
    u.id AS u_s_id,
    u.nome AS u_s_nome,
    h.emg,
    h.bc
   FROM (((public.historico_valores h
     JOIN public.equipamentos e ON ((e.id = h.equipamento_id)))
     JOIN public.paciente p ON ((p.id = h.paciente_id)))
     LEFT JOIN public.unidade_saude u ON ((u.id = p.unidade_saude_id)))
  GROUP BY h.paciente_id, p.nome, u.id, u.nome, h.emg, h.bc
  ORDER BY p.nome;


ALTER TABLE public.historico_unidades_saude OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 229 (class 1259 OID 104466)
-- Name: historico_valores_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.historico_valores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.historico_valores_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2539 (class 0 OID 0)
-- Dependencies: 229
-- Name: historico_valores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.historico_valores_id_seq OWNED BY public.historico_valores.id;


--
-- TOC entry 214 (class 1259 OID 104385)
-- Name: lembrete; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.lembrete (
    id bigint NOT NULL,
    nome text NOT NULL,
    descricao text,
    paciente_id integer NOT NULL,
    alerta timestamp(0) without time zone NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    log_utilizador_id integer NOT NULL,
    ativo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.lembrete OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 213 (class 1259 OID 104383)
-- Name: lembrete_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.lembrete_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lembrete_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2540 (class 0 OID 0)
-- Dependencies: 213
-- Name: lembrete_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.lembrete_id_seq OWNED BY public.lembrete.id;


--
-- TOC entry 194 (class 1259 OID 104275)
-- Name: tipos; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.tipos (
    id bigint NOT NULL,
    nome character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.tipos OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 189 (class 1259 OID 104243)
-- Name: utilizador; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.utilizador (
    id bigint NOT NULL,
    nome character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    contacto integer,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    funcao_id integer,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    remember_token character varying(100),
    ativo boolean NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.utilizador OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 196 (class 1259 OID 104283)
-- Name: utilizador_tipo; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.utilizador_tipo (
    id bigint NOT NULL,
    utilizador_id integer NOT NULL,
    tipo_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean DEFAULT true NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.utilizador_tipo OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 236 (class 1259 OID 104498)
-- Name: utilizador_unidade_saude; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.utilizador_unidade_saude (
    id bigint NOT NULL,
    utilizador_id integer NOT NULL,
    unidade_saude_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.utilizador_unidade_saude OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 238 (class 1259 OID 104719)
-- Name: lista_ps; Type: VIEW; Schema: public; Owner: ptdw-2019-gr1
--

CREATE VIEW public.lista_ps AS
 SELECT lista.nome,
    lista.email,
    lista.contacto,
    lista.funcao,
    lista.tipos,
    lista.unidades_saude,
    lista.data_registo
   FROM ( SELECT u.nome,
            u.email,
            u.contacto,
            to_json(array_agg(DISTINCT f.*)) AS funcao,
            to_json(array_agg(DISTINCT t.*)) AS tipos,
            to_json(array_agg(DISTINCT unidade.*)) AS unidades_saude,
            u.data_registo
           FROM (((((public.utilizador u
             JOIN public.utilizador_tipo u_t ON ((u_t.utilizador_id = u.id)))
             JOIN public.tipos t ON ((u_t.tipo_id = t.id)))
             JOIN public.utilizador_unidade_saude u_unidade ON ((u_unidade.utilizador_id = u.id)))
             JOIN public.unidade_saude unidade ON ((u_unidade.unidade_saude_id = unidade.id)))
             LEFT JOIN public.funcao f ON ((u.funcao_id = f.id)))
          WHERE ((u.ativo = true) AND (u_t.ativo = true) AND (u_unidade.ativo = true))
          GROUP BY u.nome, u.email, u.contacto, f.id, f.nome, u.data_registo
          ORDER BY u.nome) lista
  WHERE ((lista.tipos)::text ~~* '%Profissional%Saude%'::text);


ALTER TABLE public.lista_ps OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 200 (class 1259 OID 104314)
-- Name: logs; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.logs (
    id bigint NOT NULL,
    tabela text NOT NULL,
    operacao text NOT NULL,
    utilizador_id integer NOT NULL,
    novo_registo text,
    antigo_registo text,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.logs OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 199 (class 1259 OID 104312)
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2541 (class 0 OID 0)
-- Dependencies: 199
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- TOC entry 187 (class 1259 OID 104235)
-- Name: migrations; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 186 (class 1259 OID 104233)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migrations_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2542 (class 0 OID 0)
-- Dependencies: 186
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 202 (class 1259 OID 104325)
-- Name: musculo; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.musculo (
    id bigint NOT NULL,
    nome text NOT NULL,
    descricao text
);


ALTER TABLE public.musculo OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 201 (class 1259 OID 104323)
-- Name: musculo_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.musculo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.musculo_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2543 (class 0 OID 0)
-- Dependencies: 201
-- Name: musculo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.musculo_id_seq OWNED BY public.musculo.id;


--
-- TOC entry 220 (class 1259 OID 104418)
-- Name: nota; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.nota (
    id bigint NOT NULL,
    nome text NOT NULL,
    descricao text,
    paciente_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    log_utilizador_id integer NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    criado_por integer NOT NULL
);


ALTER TABLE public.nota OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 219 (class 1259 OID 104416)
-- Name: nota_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.nota_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.nota_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2544 (class 0 OID 0)
-- Dependencies: 219
-- Name: nota_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.nota_id_seq OWNED BY public.nota.id;


--
-- TOC entry 217 (class 1259 OID 104405)
-- Name: paciente_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.paciente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.paciente_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2545 (class 0 OID 0)
-- Dependencies: 217
-- Name: paciente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.paciente_id_seq OWNED BY public.paciente.id;


--
-- TOC entry 204 (class 1259 OID 104336)
-- Name: paciente_musculo; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.paciente_musculo (
    id bigint NOT NULL,
    paciente_id integer NOT NULL,
    musculo_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.paciente_musculo OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 203 (class 1259 OID 104334)
-- Name: paciente_musculo_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.paciente_musculo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.paciente_musculo_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2546 (class 0 OID 0)
-- Dependencies: 203
-- Name: paciente_musculo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.paciente_musculo_id_seq OWNED BY public.paciente_musculo.id;


--
-- TOC entry 224 (class 1259 OID 104438)
-- Name: paciente_utilizador; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.paciente_utilizador (
    id bigint NOT NULL,
    paciente_id integer NOT NULL,
    utilizador_id integer NOT NULL,
    relacao_paciente_id integer,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL,
    data_update timestamp(0) without time zone,
    ativo boolean NOT NULL,
    log_utilizador_id integer NOT NULL
);


ALTER TABLE public.paciente_utilizador OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 223 (class 1259 OID 104436)
-- Name: paciente_utilizador_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.paciente_utilizador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.paciente_utilizador_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2547 (class 0 OID 0)
-- Dependencies: 223
-- Name: paciente_utilizador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.paciente_utilizador_id_seq OWNED BY public.paciente_utilizador.id;


--
-- TOC entry 190 (class 1259 OID 104254)
-- Name: password_resets; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.password_resets (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_resets OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 228 (class 1259 OID 104457)
-- Name: pedido_ajuda; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.pedido_ajuda (
    id bigint NOT NULL,
    nome text NOT NULL,
    descricao text,
    resolvido boolean NOT NULL,
    paciente_id integer NOT NULL,
    utilizador_id integer NOT NULL,
    data_registo timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pedido_ajuda OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 227 (class 1259 OID 104455)
-- Name: pedido_ajuda_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.pedido_ajuda_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pedido_ajuda_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2548 (class 0 OID 0)
-- Dependencies: 227
-- Name: pedido_ajuda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.pedido_ajuda_id_seq OWNED BY public.pedido_ajuda.id;


--
-- TOC entry 226 (class 1259 OID 104446)
-- Name: relacao_paciente; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.relacao_paciente (
    id bigint NOT NULL,
    nome text NOT NULL
);


ALTER TABLE public.relacao_paciente OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 225 (class 1259 OID 104444)
-- Name: relacao_paciente_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.relacao_paciente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relacao_paciente_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2549 (class 0 OID 0)
-- Dependencies: 225
-- Name: relacao_paciente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.relacao_paciente_id_seq OWNED BY public.relacao_paciente.id;


--
-- TOC entry 206 (class 1259 OID 104344)
-- Name: tipo_alerta; Type: TABLE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TABLE public.tipo_alerta (
    id bigint NOT NULL,
    nome text NOT NULL
);


ALTER TABLE public.tipo_alerta OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 205 (class 1259 OID 104342)
-- Name: tipo_alerta_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.tipo_alerta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipo_alerta_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2550 (class 0 OID 0)
-- Dependencies: 205
-- Name: tipo_alerta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.tipo_alerta_id_seq OWNED BY public.tipo_alerta.id;


--
-- TOC entry 193 (class 1259 OID 104273)
-- Name: tipos_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.tipos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2551 (class 0 OID 0)
-- Dependencies: 193
-- Name: tipos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.tipos_id_seq OWNED BY public.tipos.id;


--
-- TOC entry 231 (class 1259 OID 104474)
-- Name: unidade_saude_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.unidade_saude_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.unidade_saude_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2552 (class 0 OID 0)
-- Dependencies: 231
-- Name: unidade_saude_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.unidade_saude_id_seq OWNED BY public.unidade_saude.id;


--
-- TOC entry 188 (class 1259 OID 104241)
-- Name: utilizador_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.utilizador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.utilizador_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2553 (class 0 OID 0)
-- Dependencies: 188
-- Name: utilizador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.utilizador_id_seq OWNED BY public.utilizador.id;


--
-- TOC entry 195 (class 1259 OID 104281)
-- Name: utilizador_tipo_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.utilizador_tipo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.utilizador_tipo_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2554 (class 0 OID 0)
-- Dependencies: 195
-- Name: utilizador_tipo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.utilizador_tipo_id_seq OWNED BY public.utilizador_tipo.id;


--
-- TOC entry 235 (class 1259 OID 104496)
-- Name: utilizador_unidade_saude_id_seq; Type: SEQUENCE; Schema: public; Owner: ptdw-2019-gr1
--

CREATE SEQUENCE public.utilizador_unidade_saude_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.utilizador_unidade_saude_id_seq OWNER TO "ptdw-2019-gr1";

--
-- TOC entry 2555 (class 0 OID 0)
-- Dependencies: 235
-- Name: utilizador_unidade_saude_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ptdw-2019-gr1
--

ALTER SEQUENCE public.utilizador_unidade_saude_id_seq OWNED BY public.utilizador_unidade_saude.id;


--
-- TOC entry 2248 (class 2604 OID 104399)
-- Name: alerta id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.alerta ALTER COLUMN id SET DEFAULT nextval('public.alerta_id_seq'::regclass);


--
-- TOC entry 2241 (class 2604 OID 104358)
-- Name: descricao_alerta id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.descricao_alerta ALTER COLUMN id SET DEFAULT nextval('public.descricao_alerta_id_seq'::regclass);


--
-- TOC entry 2242 (class 2604 OID 104369)
-- Name: doenca id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca ALTER COLUMN id SET DEFAULT nextval('public.doenca_id_seq'::regclass);


--
-- TOC entry 2244 (class 2604 OID 104380)
-- Name: doenca_paciente id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca_paciente ALTER COLUMN id SET DEFAULT nextval('public.doenca_paciente_id_seq'::regclass);


--
-- TOC entry 2233 (class 2604 OID 104305)
-- Name: equipamentos id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.equipamentos ALTER COLUMN id SET DEFAULT nextval('public.equipamentos_id_seq'::regclass);


--
-- TOC entry 2226 (class 2604 OID 104266)
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- TOC entry 2267 (class 2604 OID 104490)
-- Name: funcao id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.funcao ALTER COLUMN id SET DEFAULT nextval('public.funcao_id_seq'::regclass);


--
-- TOC entry 2256 (class 2604 OID 104432)
-- Name: historico_configuracoes id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_configuracoes ALTER COLUMN id SET DEFAULT nextval('public.historico_configuracoes_id_seq'::regclass);


--
-- TOC entry 2264 (class 2604 OID 104471)
-- Name: historico_valores id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_valores ALTER COLUMN id SET DEFAULT nextval('public.historico_valores_id_seq'::regclass);


--
-- TOC entry 2246 (class 2604 OID 104388)
-- Name: lembrete id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.lembrete ALTER COLUMN id SET DEFAULT nextval('public.lembrete_id_seq'::regclass);


--
-- TOC entry 2236 (class 2604 OID 104317)
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- TOC entry 2223 (class 2604 OID 104238)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 2237 (class 2604 OID 104328)
-- Name: musculo id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.musculo ALTER COLUMN id SET DEFAULT nextval('public.musculo_id_seq'::regclass);


--
-- TOC entry 2253 (class 2604 OID 104421)
-- Name: nota id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.nota ALTER COLUMN id SET DEFAULT nextval('public.nota_id_seq'::regclass);


--
-- TOC entry 2251 (class 2604 OID 104410)
-- Name: paciente id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente ALTER COLUMN id SET DEFAULT nextval('public.paciente_id_seq'::regclass);


--
-- TOC entry 2239 (class 2604 OID 104339)
-- Name: paciente_musculo id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_musculo ALTER COLUMN id SET DEFAULT nextval('public.paciente_musculo_id_seq'::regclass);


--
-- TOC entry 2259 (class 2604 OID 104441)
-- Name: paciente_utilizador id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_utilizador ALTER COLUMN id SET DEFAULT nextval('public.paciente_utilizador_id_seq'::regclass);


--
-- TOC entry 2262 (class 2604 OID 104460)
-- Name: pedido_ajuda id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.pedido_ajuda ALTER COLUMN id SET DEFAULT nextval('public.pedido_ajuda_id_seq'::regclass);


--
-- TOC entry 2260 (class 2604 OID 104449)
-- Name: relacao_paciente id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.relacao_paciente ALTER COLUMN id SET DEFAULT nextval('public.relacao_paciente_id_seq'::regclass);


--
-- TOC entry 2240 (class 2604 OID 104347)
-- Name: tipo_alerta id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.tipo_alerta ALTER COLUMN id SET DEFAULT nextval('public.tipo_alerta_id_seq'::regclass);


--
-- TOC entry 2228 (class 2604 OID 104278)
-- Name: tipos id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.tipos ALTER COLUMN id SET DEFAULT nextval('public.tipos_id_seq'::regclass);


--
-- TOC entry 2265 (class 2604 OID 104479)
-- Name: unidade_saude id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.unidade_saude ALTER COLUMN id SET DEFAULT nextval('public.unidade_saude_id_seq'::regclass);


--
-- TOC entry 2224 (class 2604 OID 104246)
-- Name: utilizador id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador ALTER COLUMN id SET DEFAULT nextval('public.utilizador_id_seq'::regclass);


--
-- TOC entry 2229 (class 2604 OID 104286)
-- Name: utilizador_tipo id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_tipo ALTER COLUMN id SET DEFAULT nextval('public.utilizador_tipo_id_seq'::regclass);


--
-- TOC entry 2268 (class 2604 OID 104501)
-- Name: utilizador_unidade_saude id; Type: DEFAULT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_unidade_saude ALTER COLUMN id SET DEFAULT nextval('public.utilizador_unidade_saude_id_seq'::regclass);


--
-- TOC entry 2504 (class 0 OID 104396)
-- Dependencies: 216
-- Data for Name: alerta; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.alerta (id, resolvido, comentario, descricao_alerta_id, paciente_id, tipo_alerta_id, data_registo) FROM stdin;
5	t	paciente queria água	1	1	1	2020-01-01 00:01:00
13	f	\N	1	24	1	2020-01-23 18:37:00
14	f	\N	2	24	2	2020-01-23 18:37:00
15	f	\N	1	24	1	2020-01-23 18:38:00
16	f	\N	2	24	2	2020-01-23 18:38:00
\.


--
-- TOC entry 2496 (class 0 OID 104355)
-- Dependencies: 208
-- Data for Name: descricao_alerta; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.descricao_alerta (id, mensagem) FROM stdin;
1	Chamou
2	Chamou de URGÊNCIA
\.


--
-- TOC entry 2498 (class 0 OID 104366)
-- Dependencies: 210
-- Data for Name: doenca; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.doenca (id, nome, descricao) FROM stdin;
1	ELA	\N
2	Paralisia Cerebral	\N
\.


--
-- TOC entry 2500 (class 0 OID 104377)
-- Dependencies: 212
-- Data for Name: doenca_paciente; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.doenca_paciente (id, doenca_id, paciente_id, data_registo) FROM stdin;
3	2	1	2020-01-22 22:38:29
5	1	3	2020-01-22 22:39:15
6	2	3	2020-01-22 22:39:15
8	2	2	2020-01-22 22:47:40
9	1	20	2020-01-22 22:49:13
10	2	20	2020-01-22 22:49:13
11	2	21	2020-01-22 23:01:33
12	1	22	2020-01-22 23:10:09
26	1	19	2020-01-22 23:59:28
36	1	23	2020-01-23 15:37:51
39	1	24	2020-01-23 16:38:42
40	2	24	2020-01-23 16:38:42
42	1	26	2020-01-23 17:33:46
44	1	25	2020-01-23 17:37:39
45	2	27	2020-01-23 17:37:58
46	1	28	2020-01-23 18:09:09
\.


--
-- TOC entry 2486 (class 0 OID 104302)
-- Dependencies: 198
-- Data for Name: equipamentos; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.equipamentos (id, nome, access_token, data_registo, data_update, ativo, log_utilizador_id) FROM stdin;
1	007	239203912910832024242849284	2020-01-12 04:54:42	2020-01-20 17:01:34	f	2
17	E65	PA6VKYZhkU6OFhWbP1m7	2020-01-24 01:19:22	\N	t	1
5	E5	32423534502305920395	2020-01-12 04:57:52	2020-01-24 09:46:01	t	67
11	E6	pOX9G0LCu5gpwhvjPKI5	2020-01-12 15:56:29	2020-01-22 19:41:43	t	1
12	E7	JKmu9sTIqCFjmHfptgq8	2020-01-12 16:30:12	2020-01-22 19:42:03	t	1
13	E200	YmFRogpVdizBBKMjgoi4	2020-01-23 02:28:08	\N	t	1
14	E100	XEMrVNvKByZA6AxtG1Rx	2020-01-23 02:28:57	\N	t	1
15	E15	pecmOSbZ3t3XNRdaIMjP	2020-01-23 02:30:08	\N	t	1
16	E12	2YWXZ4GHbl4D3GpoguLk	2020-01-23 02:33:14	\N	t	1
3	E3	565757574645645465757575754224	2020-01-12 04:57:10	2020-01-23 18:09:16	f	2
4	E4	12910292039240394039	2020-01-12 04:57:38	2020-01-23 18:32:38	t	1
\.


--
-- TOC entry 2480 (class 0 OID 104263)
-- Dependencies: 192
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.failed_jobs (id, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- TOC entry 2522 (class 0 OID 104487)
-- Dependencies: 234
-- Data for Name: funcao; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.funcao (id, nome) FROM stdin;
1	Médico
3	Oftalmologista
4	Farmacêutico
2	Fisioterapeuta
\.


--
-- TOC entry 2510 (class 0 OID 104429)
-- Dependencies: 222
-- Data for Name: historico_configuracoes; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.historico_configuracoes (id, emg_min, emg_max, bpm_min, bpm_max, paciente_id, equipamento_id, data_registo, esta_associado) FROM stdin;
2	1	1	1	1	1	1	2020-01-20 16:40:35	f
3	\N	\N	\N	\N	1	3	2020-01-20 19:10:31	f
4	\N	\N	\N	\N	1	3	2020-01-20 19:10:49	f
5	\N	\N	\N	\N	1	3	2020-01-20 19:12:09	f
6	45	70	23	29	1	3	2020-01-22 11:50:04	f
7	\N	\N	\N	\N	4	3	2020-01-22 14:10:39	f
17	\N	\N	\N	\N	2	3	2020-01-22 23:32:55	f
20	\N	\N	\N	\N	1	3	2020-01-23 13:36:50	f
21	\N	\N	\N	\N	3	3	2020-01-23 13:37:52	f
25	\N	\N	\N	\N	21	3	2020-01-23 13:43:00	t
26	\N	\N	\N	\N	24	4	2020-01-23 16:56:41	f
27	1	1	1	1	24	4	2020-01-23 16:59:26	f
28	\N	\N	\N	\N	24	4	2020-01-23 17:33:01	f
29	10	70	70	80	24	4	2020-01-23 17:56:39	f
35	\N	\N	\N	\N	25	4	2020-01-23 18:28:59	f
36	\N	\N	\N	\N	24	4	2020-01-23 18:32:38	t
38	\N	\N	\N	\N	28	5	2020-01-23 23:15:20	f
40	\N	\N	\N	\N	28	5	2020-01-24 09:28:01	f
41	20	60	50	80	28	5	2020-01-24 09:28:54	f
42	\N	\N	\N	\N	28	5	2020-01-24 09:46:02	f
43	20	50	50	80	28	5	2020-01-24 09:46:44	t
\.


--
-- TOC entry 2518 (class 0 OID 104468)
-- Dependencies: 230
-- Data for Name: historico_valores; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.historico_valores (id, emg, bc, paciente_id, equipamento_id, data_registo) FROM stdin;
21024	34.5	77	1	3	2017-10-19 15:00:00
21029	35.2299999999999969	68	1	5	2017-10-19 15:20:00
21025	47.5	60	1	5	2017-10-19 15:01:01
21026	46.2999999999999972	40	1	3	2017-10-19 15:01:02
21027	30.2300000000000004	65	1	5	2017-10-19 15:01:03
21028	33.2299999999999969	66	1	5	2017-10-19 15:01:04
21030	40.2100000000000009	50	2	3	2018-12-13 13:00:01
21031	33.2100000000000009	70	2	5	2018-12-13 14:00:40
21032	40.240000000000002	56	2	5	2018-12-13 15:00:40
21033	25.1000000000000014	68	2	3	2018-12-13 18:00:40
21034	750.94183349609375	64	3	12	2019-03-07 15:41:47
21035	914.14813232421875	600	3	5	2018-09-05 02:35:34
21036	934.1456298828125	589	3	12	2018-12-21 15:14:46
21037	239.914443969726562	222	3	11	2019-03-10 02:28:09
21038	568.27593994140625	801	3	3	2019-01-18 19:39:51
21039	482.6268310546875	295	3	11	2018-10-23 23:18:01
21040	812.703857421875	449	3	5	2018-11-08 18:05:10
21041	235.793609619140625	453	3	1	2018-09-14 12:56:30
21042	932.80975341796875	161	3	11	2018-09-12 03:23:00
21043	183.493927001953125	28	3	1	2019-01-18 05:42:34
21044	196.248275756835938	830	3	12	2019-03-14 09:48:12
21045	165.21661376953125	376	3	12	2018-09-15 02:16:53
21046	500.044586181640625	807	3	11	2018-11-08 10:06:22
21047	831.80401611328125	1009	3	11	2018-10-17 09:18:48
21048	831.45660400390625	653	3	4	2018-11-27 08:54:11
21049	417.16168212890625	616	3	5	2019-02-22 18:50:11
21050	129.750152587890625	835	3	5	2019-01-23 20:23:17
21051	645.07037353515625	737	3	12	2019-01-24 09:25:21
21052	139.45654296875	356	3	5	2018-09-26 01:06:17
21053	844.65716552734375	435	3	5	2018-10-01 04:18:10
21054	334.533233642578125	416	3	11	2019-02-16 19:05:01
21055	208.87493896484375	89	3	5	2019-01-23 15:56:17
21056	302.531951904296875	748	3	12	2018-11-03 01:35:53
21057	250.937469482421875	596	3	1	2018-11-29 15:13:56
21058	747.57635498046875	435	3	1	2018-09-07 21:09:29
21059	897.895263671875	71	3	12	2019-01-09 02:57:16
21060	588.6900634765625	311	3	4	2019-03-15 16:13:48
21061	878.88494873046875	545	3	1	2018-10-02 21:02:52
21062	759.3184814453125	586	3	1	2018-12-16 13:04:03
21063	190.979660034179688	513	3	1	2019-02-08 19:59:31
21064	545.6500244140625	935	3	1	2018-10-02 08:02:33
21065	242.230377197265625	192	3	5	2018-10-03 20:16:22
21066	846.29541015625	245	3	12	2018-12-25 08:42:46
21067	421.9381103515625	736	3	4	2019-03-22 22:18:10
21068	249.969772338867188	193	3	3	2018-11-30 02:24:20
21069	101.655921936035156	292	3	1	2018-12-05 02:25:50
21070	735.8447265625	721	3	12	2019-03-22 01:55:34
21071	535.45361328125	162	3	11	2019-02-10 16:03:56
21072	335.175994873046875	553	3	11	2018-11-21 04:10:53
21073	603.25665283203125	176	3	11	2018-12-31 03:38:51
21074	124.849479675292969	920	3	11	2018-09-04 09:24:08
21075	217.707290649414062	771	3	3	2019-03-08 08:39:40
21076	753.22039794921875	861	3	3	2019-02-03 05:44:27
21077	641.423828125	643	3	11	2018-11-09 04:41:55
21078	719.88671875	123	3	11	2019-02-22 16:47:36
21079	273.42218017578125	325	3	4	2019-03-18 03:21:36
21080	624.15606689453125	484	3	4	2018-09-30 21:46:51
21081	895.76885986328125	585	3	3	2019-01-20 03:16:17
21082	831.01959228515625	902	3	4	2019-03-21 04:46:15
21083	311.372650146484375	79	3	1	2019-02-20 14:38:45
21084	963.79608154296875	914	3	11	2019-01-05 06:25:49
21085	828.55194091796875	81	3	11	2018-11-27 03:04:43
21086	915.96441650390625	447	3	11	2019-02-09 22:36:46
21087	37.6864242553710938	666	3	12	2019-02-10 06:39:46
21088	68.8060836791992188	734	3	5	2018-10-04 10:20:43
21089	688.487060546875	891	3	1	2018-09-17 02:39:22
21090	77.7987518310546875	246	3	3	2018-09-10 18:47:19
21091	593.79315185546875	837	3	4	2019-01-10 02:35:44
21092	533.46356201171875	411	3	4	2018-10-06 10:28:46
21093	880.65704345703125	435	3	1	2018-11-06 16:58:38
21094	623.4393310546875	288	3	1	2019-02-20 17:49:58
21095	202.643600463867188	970	3	4	2018-10-20 14:30:54
21096	803.7811279296875	471	3	11	2018-12-05 01:01:48
21097	511.150543212890625	336	3	5	2019-02-13 05:48:07
21098	936.33502197265625	118	3	12	2018-12-12 06:58:38
21099	382.538787841796875	864	3	1	2018-09-16 19:18:03
21100	248.55633544921875	794	3	1	2018-09-15 05:46:07
21101	199.49542236328125	463	3	12	2019-02-18 06:20:25
21102	257.624267578125	702	3	11	2018-11-28 00:38:08
21103	765.944091796875	207	3	3	2019-02-05 11:17:29
21104	570.62335205078125	959	3	11	2019-03-07 11:56:22
21105	385.54425048828125	134	3	1	2018-10-31 02:16:08
21106	848.61181640625	525	3	3	2019-02-04 02:33:00
21107	133.734329223632812	360	3	3	2018-10-21 19:10:25
21108	62.9677505493164062	377	3	1	2018-09-14 16:12:33
21109	364.881256103515625	95	3	3	2018-09-23 18:01:08
21110	31.0306339263916016	656	3	12	2018-11-20 15:32:43
21111	978.51934814453125	266	3	11	2018-12-17 17:09:27
21112	806.46087646484375	573	3	12	2019-01-24 16:19:01
21113	812.55322265625	979	3	12	2018-09-19 17:19:40
21114	310.42822265625	63	3	1	2018-11-17 15:04:42
21115	507.04998779296875	576	3	11	2019-01-10 07:37:04
21116	565.66424560546875	757	3	5	2019-01-05 19:43:57
21117	683.9156494140625	561	3	3	2018-10-27 03:18:25
21118	407.61090087890625	972	3	4	2019-02-10 13:10:33
21119	550.126220703125	228	3	5	2018-10-15 17:26:19
21120	853.37884521484375	893	3	1	2018-09-20 22:14:24
21121	643.01446533203125	775	3	3	2018-12-09 10:28:23
21122	300.4666748046875	636	3	5	2018-10-13 22:20:37
21123	857.24554443359375	241	3	11	2018-11-20 11:21:31
21124	24.5894584655761719	110	3	11	2018-12-14 03:43:29
21125	155.788848876953125	372	3	12	2019-03-10 01:07:12
21126	940.709716796875	745	3	1	2019-03-21 16:12:56
21127	911.14276123046875	814	3	5	2019-02-24 04:09:50
21128	249.083709716796875	831	3	4	2018-11-16 19:02:05
21129	700.4381103515625	305	3	4	2019-03-20 14:02:42
21130	995.5933837890625	445	3	1	2018-10-23 12:32:32
21131	601.92236328125	470	3	1	2018-11-11 11:17:59
21132	553.511962890625	236	3	4	2018-11-20 13:01:34
21133	79.0562286376953125	252	3	11	2019-02-03 16:48:07
21134	66.4872970581054688	56	3	5	2018-12-09 21:51:30
21135	962.18267822265625	229	3	5	2019-01-07 21:19:39
21136	776.246826171875	527	3	11	2019-02-15 08:51:45
21137	320.2369384765625	435	3	12	2019-01-24 03:04:52
21138	632.82818603515625	453	3	11	2019-02-05 20:38:11
21139	332.37518310546875	758	3	4	2018-12-22 03:28:22
21140	788.3919677734375	560	3	4	2018-09-17 19:52:28
21141	84.558563232421875	305	3	12	2019-02-14 07:11:23
21142	925.52154541015625	610	3	12	2018-11-27 17:58:17
21143	163.733245849609375	279	3	4	2018-10-05 20:21:51
21144	567.95782470703125	48	3	4	2019-01-23 13:09:09
21145	384.694305419921875	806	3	4	2018-10-30 01:24:39
21146	1010.2054443359375	159	3	5	2018-12-09 08:59:54
21147	907.9344482421875	656	3	3	2018-12-06 23:21:51
21148	601.483154296875	90	3	12	2018-09-10 00:33:06
21149	501.843353271484375	68	3	1	2018-12-05 17:15:33
21150	466.853118896484375	888	3	3	2018-11-11 09:53:23
21151	217.669296264648438	423	3	5	2019-02-05 17:37:11
21152	426.52288818359375	653	3	1	2018-10-14 23:40:54
21153	412.75103759765625	134	3	3	2018-10-29 22:29:04
21154	328.73492431640625	760	3	4	2019-01-10 22:44:33
21155	398.3922119140625	869	3	11	2018-10-08 00:54:29
21156	174.621963500976562	134	3	5	2018-10-04 12:00:32
21157	398.450653076171875	863	3	5	2018-12-10 07:50:24
21158	347.27197265625	932	3	1	2018-10-01 19:24:00
21159	343.079437255859375	652	3	3	2019-02-09 03:57:29
21160	551.17529296875	491	3	12	2019-02-18 22:56:20
21161	194.036407470703125	279	3	12	2019-03-08 05:56:54
21162	877.8931884765625	40	3	12	2019-01-15 07:05:24
21163	210.913818359375	294	3	11	2019-02-06 22:46:45
21164	1014.5489501953125	93	3	3	2018-11-05 10:43:04
21165	849.24810791015625	457	3	3	2019-01-02 00:22:52
21166	753.21160888671875	633	3	1	2018-12-11 18:21:14
21167	929.86749267578125	457	3	5	2018-11-03 18:54:26
21168	697.3226318359375	476	3	11	2018-11-13 10:31:19
21169	1009.33160400390625	927	3	4	2019-01-12 16:36:01
21170	423.961700439453125	513	3	3	2019-01-03 08:51:12
21171	56.6435623168945312	944	3	12	2018-09-05 08:07:00
21172	662.03204345703125	733	3	11	2019-03-18 08:59:36
21173	131.600433349609375	643	3	12	2018-10-18 09:14:59
21174	736.61676025390625	561	3	3	2018-10-25 14:48:57
21175	48.7932243347167969	50	3	5	2018-12-18 15:57:18
21176	837.47686767578125	78	3	5	2018-10-04 16:59:29
21177	646.22503662109375	599	3	11	2018-12-24 23:13:44
21178	102.776824951171875	331	3	11	2018-09-08 22:18:59
21179	268.23577880859375	833	3	5	2019-01-17 09:43:12
21180	887.5660400390625	398	3	5	2018-11-26 20:48:50
21181	494.24517822265625	594	3	5	2018-10-19 15:53:24
21182	995.64697265625	476	3	12	2019-03-22 23:14:40
21183	457.86358642578125	642	3	5	2018-11-01 08:21:44
21184	157.598281860351562	618	3	4	2018-11-02 22:44:19
21185	645.66717529296875	678	3	1	2018-11-07 01:55:17
21186	808.14208984375	160	3	3	2019-01-19 01:55:32
21187	136.482940673828125	499	3	5	2018-09-27 20:15:01
21188	505.914276123046875	560	3	11	2018-12-20 08:25:49
21189	594.02423095703125	229	3	3	2019-01-26 21:33:22
21190	468.922454833984375	310	3	3	2019-01-22 02:23:58
21191	640.29168701171875	696	3	11	2019-03-12 20:35:11
21192	697.23089599609375	540	3	4	2018-12-18 05:37:19
21193	792.98193359375	512	3	3	2018-09-15 09:59:24
21194	143.141860961914062	537	3	11	2018-10-31 20:16:04
21195	152.429443359375	292	3	1	2018-11-28 01:38:19
21196	241.119491577148438	759	3	5	2019-02-09 04:09:27
21197	434.465911865234375	183	3	11	2019-03-02 02:55:14
21198	435.24530029296875	469	3	5	2019-02-16 00:58:28
21199	960.61102294921875	297	3	12	2018-11-04 18:03:50
21200	392.366546630859375	89	3	12	2019-02-04 10:42:23
21201	133.688232421875	121	3	5	2018-11-21 11:45:13
21202	483.084991455078125	852	3	1	2018-11-18 02:07:31
21203	941.15814208984375	612	3	4	2018-11-16 00:42:51
21204	452.344512939453125	823	3	12	2018-11-04 11:32:47
21205	658.1856689453125	808	3	12	2019-01-28 20:28:37
21206	911.08770751953125	347	3	11	2018-11-02 06:18:57
21207	588.58575439453125	850	3	5	2018-12-01 09:01:15
21208	808.39056396484375	90	3	12	2018-10-23 18:15:17
21209	667.903076171875	861	3	1	2018-10-19 20:00:42
21210	224.576019287109375	638	3	3	2018-12-06 04:47:39
21211	357.97381591796875	676	3	12	2019-01-04 07:20:07
21212	1006.9259033203125	832	3	11	2018-12-18 20:46:38
21213	252.9840087890625	378	3	5	2019-03-16 01:46:46
21214	819.717041015625	438	3	3	2018-11-10 15:52:10
21215	302.8778076171875	741	3	3	2019-03-04 09:04:19
21216	426.39471435546875	348	3	4	2018-11-12 08:22:10
21217	1009.09716796875	796	3	1	2019-01-21 12:24:38
21218	633.169189453125	249	3	5	2018-09-07 20:30:08
21219	57.6166038513183594	804	3	4	2018-11-25 19:52:47
21220	360.679534912109375	216	3	4	2018-10-27 22:46:55
21221	188.964584350585938	678	3	4	2019-02-07 10:53:52
21222	916.0089111328125	773	3	4	2018-10-12 09:41:51
21223	475.1795654296875	429	3	4	2019-01-12 10:33:30
21224	683.789306640625	91	3	1	2019-01-06 10:14:09
21225	919.26605224609375	230	3	1	2019-01-03 11:43:41
21226	838.375	636	3	5	2019-03-21 10:25:50
21227	91.5768966674804688	839	3	3	2018-10-07 07:57:53
21228	451.518707275390625	977	3	5	2018-11-18 14:44:32
21229	130.41680908203125	1016	3	3	2018-12-03 20:33:58
21230	457.718292236328125	761	3	1	2019-03-05 22:23:32
21231	165.628997802734375	238	3	5	2018-12-11 18:34:34
21232	751.134521484375	389	3	5	2018-09-07 22:43:23
21233	120.531204223632812	625	3	11	2019-01-15 11:53:35
21234	23.48492431640625	202	3	12	2019-01-26 16:45:24
21235	21.4079647064208984	53	3	11	2018-09-26 06:24:19
21236	192.20819091796875	245	3	11	2018-12-21 22:41:52
21237	785.60308837890625	862	3	12	2018-11-21 16:54:24
21238	274.91546630859375	641	3	4	2018-10-05 03:51:11
21239	800.61865234375	484	3	5	2018-10-17 03:48:36
21240	447.0631103515625	642	3	3	2018-12-22 01:10:57
21241	139.740982055664062	73	3	12	2019-02-19 04:38:57
21242	708.10113525390625	31	3	5	2019-01-23 13:35:00
21243	629.62030029296875	325	3	4	2018-10-13 05:46:20
21244	961.910888671875	646	3	11	2019-03-21 04:37:18
21245	991.50604248046875	504	3	11	2018-09-24 16:25:35
21246	689.73138427734375	179	3	3	2018-10-16 04:24:00
21247	288.823394775390625	206	3	12	2018-09-09 03:38:59
21248	122.958648681640625	555	3	1	2018-09-19 00:36:01
21249	762.64642333984375	798	3	1	2018-10-04 02:27:41
21250	594.9610595703125	254	3	4	2019-03-10 14:48:14
21251	786.31707763671875	383	3	1	2018-09-23 03:20:00
21252	544.2586669921875	911	3	1	2019-03-14 15:20:32
21253	483.815704345703125	537	3	11	2018-11-15 22:22:13
21254	188.858596801757812	849	3	1	2019-03-22 17:57:42
21255	992.67047119140625	967	3	4	2018-10-21 22:34:01
21256	945.97662353515625	947	3	11	2018-11-06 21:47:06
21257	430.020294189453125	488	3	11	2019-01-20 00:37:53
21258	796.58270263671875	376	3	3	2019-01-03 01:30:24
21259	557.73779296875	514	3	11	2018-10-18 07:01:04
21260	505.847198486328125	871	3	4	2018-09-15 03:58:53
21261	68.1727523803710938	377	3	11	2019-01-23 23:34:34
21262	260.8919677734375	770	3	11	2018-12-03 15:31:57
21263	975.13909912109375	144	3	5	2019-03-14 04:22:59
21264	630.1724853515625	433	3	1	2018-12-01 21:53:07
21265	935.771484375	748	3	3	2018-11-25 02:58:56
21266	178.53900146484375	544	3	1	2019-03-04 16:59:52
21267	335.362518310546875	277	3	1	2018-09-20 10:18:15
21268	993.96282958984375	578	3	5	2018-10-28 12:27:22
21269	304.20135498046875	586	3	1	2018-10-14 15:28:51
21270	370.542327880859375	835	3	5	2018-09-05 06:45:32
21271	79.6349334716796875	598	3	12	2019-01-05 04:54:42
21272	163.49365234375	176	3	4	2018-11-16 02:28:08
21273	66.7368240356445312	739	3	1	2018-09-11 11:59:08
21274	722.81402587890625	305	3	5	2019-03-02 07:22:39
21275	886.67694091796875	839	3	1	2018-09-08 22:05:55
21276	683.75250244140625	633	3	1	2018-10-29 00:25:54
21277	864.4146728515625	359	3	5	2018-11-10 12:25:53
21278	487.06939697265625	742	3	5	2018-09-29 06:16:42
21279	877.580810546875	673	3	4	2019-03-15 23:24:11
21280	901.3419189453125	202	3	4	2019-01-25 10:34:57
21281	165.528549194335938	363	3	5	2019-01-03 03:06:52
21282	578.9747314453125	291	3	4	2018-12-23 04:51:05
21283	511.69683837890625	262	3	4	2019-02-15 05:02:09
21284	246.281341552734375	831	3	11	2018-11-26 11:01:30
21285	687.37481689453125	597	3	5	2018-09-15 08:08:22
21286	53.3983383178710938	413	3	1	2019-02-25 01:44:45
21287	974.23193359375	449	3	4	2018-09-11 06:32:11
21288	837.4893798828125	68	3	3	2018-12-02 10:00:01
21289	876.38616943359375	547	3	11	2019-02-25 03:48:26
21290	528.9166259765625	992	3	3	2019-01-20 09:47:34
21291	117.167716979980469	738	3	3	2018-10-20 05:22:33
21292	343.86956787109375	220	3	5	2018-12-09 17:20:53
21293	513.39239501953125	536	3	11	2018-09-05 05:45:34
21294	966.9412841796875	543	3	1	2018-12-24 19:53:06
21295	520.075439453125	129	3	1	2019-02-22 04:59:51
21296	975.094970703125	718	3	5	2019-01-31 19:44:45
21297	538.81787109375	753	3	11	2019-03-02 23:52:05
21298	716.895263671875	131	3	1	2019-01-16 14:47:15
21299	601.88800048828125	834	3	4	2018-12-17 03:38:08
21300	213.526779174804688	460	3	1	2019-01-20 19:35:48
21301	621.84649658203125	767	3	11	2019-03-10 08:10:10
21302	678.16015625	662	3	4	2018-10-29 16:49:57
21303	401.980743408203125	24	3	12	2019-02-09 09:50:33
21304	929.89666748046875	565	3	3	2019-02-24 08:35:18
21305	594.41131591796875	611	3	11	2018-09-21 00:06:57
21306	220.0960693359375	976	3	1	2018-10-14 20:30:02
21307	237.79559326171875	865	3	3	2018-12-19 14:26:50
21308	906.8370361328125	699	3	5	2018-10-07 01:20:34
21309	471.872772216796875	922	3	4	2019-02-01 08:10:47
21310	980.2666015625	392	3	12	2018-11-19 10:10:39
21311	182.558975219726562	457	3	12	2018-10-14 00:54:02
21312	76.3248062133789062	63	3	5	2018-10-31 10:14:17
21313	378.93182373046875	819	3	1	2019-02-14 23:24:56
21314	683.96875	217	3	12	2019-01-25 13:06:38
21315	682.385009765625	310	3	11	2019-02-01 15:29:07
21316	390.395660400390625	812	3	11	2019-01-12 22:18:25
21317	526.21429443359375	849	3	4	2019-01-16 13:31:15
21318	310.006561279296875	555	3	4	2018-09-27 06:18:46
21319	21.1602878570556641	824	3	3	2018-09-27 00:08:15
21320	753.2025146484375	817	3	1	2019-01-09 03:34:39
21321	47.7676124572753906	914	3	5	2019-01-27 02:43:22
21322	697.53558349609375	38	3	11	2019-01-19 00:47:20
21323	190.330047607421875	329	3	1	2019-02-08 13:03:48
21324	205.93316650390625	571	3	12	2019-03-22 10:20:40
21325	457.17242431640625	922	3	4	2018-09-11 03:17:32
21326	935.097412109375	104	3	1	2018-11-06 06:31:38
21327	486.673309326171875	274	3	4	2019-03-03 07:09:17
21328	953.927734375	89	3	4	2019-02-25 11:17:53
21329	622.80902099609375	641	3	3	2019-02-27 11:17:18
21330	987.310791015625	323	3	1	2018-10-14 20:09:47
21331	449.137603759765625	746	3	1	2018-09-19 15:35:58
21332	160.122787475585938	165	3	12	2018-11-17 08:41:28
21333	497.34552001953125	458	3	11	2019-02-17 04:10:08
21334	545.44354248046875	640	3	4	2018-09-18 07:30:58
21335	791.06390380859375	67	3	12	2018-10-06 19:49:18
21336	593.04571533203125	939	3	3	2018-10-15 16:55:01
21337	689.25042724609375	455	3	11	2019-01-15 03:00:17
21338	31.2754993438720703	935	3	1	2019-02-28 10:22:10
21339	201.057952880859375	670	3	11	2018-11-10 12:43:01
21340	175.103683471679688	351	3	3	2019-02-06 03:14:18
21341	47.9083023071289062	846	3	11	2019-02-06 12:42:22
21342	1004.8797607421875	312	3	4	2018-11-02 18:27:48
21343	923.30206298828125	140	3	12	2019-03-02 01:13:27
21344	417.756805419921875	868	3	1	2018-09-08 11:31:40
21345	715.71466064453125	409	3	3	2018-10-13 01:52:39
21346	28.792083740234375	196	3	12	2018-10-20 05:13:29
21347	320.660064697265625	1014	3	3	2019-01-24 18:49:28
21348	852.76702880859375	127	3	5	2018-12-24 17:31:22
21349	323.56884765625	452	3	3	2018-10-27 22:28:37
21350	592.4713134765625	454	3	4	2019-01-10 13:07:35
21351	158.857345581054688	97	3	11	2018-09-23 18:53:31
21352	245.4102783203125	840	3	11	2019-02-08 06:14:54
21353	524.0987548828125	72	3	5	2018-10-08 23:19:05
21354	512.6893310546875	413	3	4	2019-03-07 08:26:02
21355	859.04248046875	822	3	5	2019-02-18 18:51:25
21356	641.61669921875	109	3	11	2018-12-07 09:10:10
21357	934.4150390625	898	3	12	2019-01-19 20:48:34
21358	666.6458740234375	191	3	12	2019-03-07 11:51:17
21359	313.79156494140625	445	3	3	2019-03-20 00:52:28
21360	167.575729370117188	586	3	4	2018-09-17 00:17:10
21361	318.28558349609375	288	3	5	2019-02-08 02:02:49
21362	724.22003173828125	293	3	12	2018-09-06 11:51:12
21363	365.267608642578125	911	3	12	2019-02-18 09:43:06
21364	598.00140380859375	560	3	3	2018-12-05 08:20:48
21365	948.7900390625	400	3	12	2018-12-03 19:28:57
21366	890.0545654296875	70	3	1	2018-12-08 21:13:43
21367	103.451614379882812	566	3	12	2018-10-13 11:37:50
21368	551.131591796875	674	3	4	2019-01-08 05:01:39
21369	500.84161376953125	771	3	4	2019-01-11 00:30:14
21370	377.68475341796875	968	3	4	2018-09-11 01:29:12
21371	665.802734375	313	3	5	2018-10-13 07:57:22
21372	887.71484375	421	3	12	2019-01-11 21:08:25
21373	744.3934326171875	990	3	4	2019-03-07 02:37:06
21374	410.805572509765625	22	3	12	2018-11-24 14:22:55
21375	223.829818725585938	361	3	11	2019-01-24 08:54:43
21376	822.10418701171875	103	3	12	2018-12-02 16:03:02
21377	713.81280517578125	653	3	3	2018-10-06 23:41:03
21378	956.864013671875	996	3	1	2019-02-23 17:24:26
21379	234.157745361328125	927	3	4	2018-11-18 17:19:16
21380	773.21392822265625	819	3	1	2019-01-13 23:50:21
21381	806.9605712890625	551	3	12	2018-10-25 07:35:17
21382	731.25103759765625	767	3	4	2019-01-28 21:28:04
21383	806.1971435546875	84	3	5	2018-10-08 16:54:16
21384	550.59393310546875	484	3	3	2019-01-11 11:45:49
21385	31.5786495208740234	330	3	12	2019-01-25 20:50:52
21386	951.52679443359375	618	3	1	2019-03-08 02:42:50
21387	197.027175903320312	118	3	1	2018-09-12 18:16:24
21388	731.2125244140625	908	3	3	2018-10-25 23:14:12
21389	543.49639892578125	856	3	12	2018-11-15 19:35:09
21390	516.137939453125	441	3	5	2018-12-16 11:43:55
21391	494.093780517578125	676	3	3	2018-12-13 09:54:19
21392	565.540283203125	979	3	3	2018-10-28 06:52:52
21393	44.3209648132324219	260	3	4	2018-11-26 15:50:38
21394	431.798095703125	211	3	1	2018-10-22 07:57:28
21395	584.9326171875	745	3	12	2019-01-05 03:45:30
21396	460.159271240234375	405	3	1	2018-09-10 00:51:25
21397	572.30426025390625	762	3	4	2019-02-05 00:45:30
21398	206.967025756835938	945	3	1	2019-03-20 18:06:41
21399	1019.39373779296875	331	3	4	2019-02-09 05:48:14
21400	665.98309326171875	800	3	12	2019-03-19 10:51:32
21401	242.319259643554688	537	3	1	2018-11-24 04:49:32
21402	341.668975830078125	759	3	4	2018-09-05 13:18:12
21403	839.050537109375	930	3	5	2018-10-31 22:16:30
21404	537.97808837890625	712	3	1	2019-03-18 18:04:42
21405	221.697113037109375	266	3	4	2019-01-05 00:42:23
21406	99.3203048706054688	96	3	3	2018-09-09 18:47:15
21407	396.041412353515625	303	3	3	2018-12-29 14:45:45
21408	970.0885009765625	424	3	11	2019-02-03 11:18:08
21409	348.5770263671875	579	3	3	2018-09-16 21:25:53
21410	980.06524658203125	615	3	1	2019-02-19 12:12:58
21411	753.39031982421875	395	3	3	2019-02-12 05:53:51
21412	722.39666748046875	122	3	3	2018-10-06 15:15:22
21413	929.71728515625	493	3	4	2018-12-24 06:20:07
21414	47.7852630615234375	425	3	4	2018-10-03 01:41:30
21415	741.54254150390625	698	3	4	2019-02-02 04:10:24
21416	786.9910888671875	373	3	5	2018-12-18 10:53:37
21417	212.087570190429688	276	3	1	2018-10-29 17:46:46
21418	727.38153076171875	1002	3	5	2018-09-20 00:53:01
21419	561.756591796875	519	3	12	2019-03-13 19:22:44
21420	127.774383544921875	35	3	3	2018-11-16 01:16:59
21421	522.54840087890625	809	3	1	2018-10-10 13:37:37
21422	817.661865234375	993	3	3	2018-12-12 04:43:25
21423	81.3537521362304688	360	3	12	2019-01-06 03:56:11
21424	48.7762069702148438	691	3	4	2018-10-26 02:15:03
21425	701.881103515625	970	3	1	2019-03-10 13:41:00
21426	731.7806396484375	362	3	3	2018-11-25 01:36:50
21427	336.644927978515625	592	3	4	2019-02-06 19:17:06
21428	400.770111083984375	177	3	12	2018-11-04 02:32:56
21429	266.4449462890625	997	3	12	2019-03-11 04:09:07
21430	284.78582763671875	46	3	12	2018-11-30 00:25:42
21431	890.42974853515625	569	3	5	2019-02-07 19:20:00
21432	341.4283447265625	361	3	1	2018-11-25 05:57:04
21433	554.7322998046875	610	3	11	2019-03-13 00:23:16
21434	781.12548828125	134	3	5	2018-09-10 03:38:14
21435	430.94036865234375	779	3	3	2019-02-02 08:53:48
21436	967.04876708984375	340	3	5	2018-10-11 17:20:42
21437	236.55157470703125	448	3	5	2018-09-15 14:15:47
21438	540.31658935546875	942	3	5	2018-10-13 08:02:28
21439	828.18927001953125	200	3	11	2019-03-05 21:12:31
21440	755.4949951171875	572	3	12	2018-09-17 01:41:53
21441	77.893951416015625	273	3	3	2018-11-04 19:45:50
21442	599.4317626953125	32	3	4	2018-12-27 01:52:37
21443	836.52264404296875	598	3	5	2018-10-09 23:24:10
21444	75.0037689208984375	94	3	4	2019-01-26 00:18:58
21445	317.11669921875	281	3	3	2018-09-14 13:27:46
21446	833.30963134765625	839	3	12	2019-01-14 05:32:39
21447	688.5687255859375	919	3	4	2019-03-15 22:15:47
21448	241.380996704101562	91	3	12	2018-11-29 18:02:24
21449	565.40472412109375	687	3	5	2018-10-18 04:47:52
21450	210.242095947265625	618	3	1	2018-09-14 09:09:58
21451	33.3513374328613281	609	3	12	2019-01-16 12:21:58
21452	383.9183349609375	746	3	12	2018-12-26 15:52:20
21453	170.962387084960938	657	3	3	2018-09-29 20:31:10
21454	450.722930908203125	305	3	4	2018-10-01 06:40:02
21455	652.69696044921875	972	3	5	2018-12-12 04:38:51
21456	42.3616447448730469	854	3	1	2018-09-29 07:14:27
21457	164.54595947265625	350	3	4	2018-10-22 16:40:27
21458	406.135833740234375	840	3	12	2019-02-08 19:54:07
21459	556.43646240234375	48	3	3	2018-09-22 12:09:51
21460	573.4261474609375	454	3	11	2019-02-19 05:19:38
21461	532.638671875	406	3	1	2018-09-10 02:57:09
21462	307.504364013671875	357	3	4	2019-01-12 20:38:46
21463	1009.54974365234375	546	3	11	2019-03-19 13:10:12
21464	245.935867309570312	110	3	1	2019-03-16 11:11:54
21465	610.95135498046875	751	3	3	2019-01-29 00:50:23
21466	105.981170654296875	589	3	4	2018-11-07 15:59:53
21467	28.78167724609375	996	3	11	2018-11-01 06:31:27
21468	758.11834716796875	109	3	5	2018-12-07 01:47:59
21469	301.2991943359375	612	3	1	2018-11-02 05:49:47
21470	997.22265625	511	3	11	2019-01-19 05:09:33
21471	372.041046142578125	391	3	4	2018-11-20 11:40:56
21472	171.054931640625	452	3	1	2019-03-02 05:13:51
21473	298.54193115234375	348	3	12	2018-09-30 00:41:41
21474	181.662734985351562	745	3	11	2018-11-08 13:39:42
21475	707.48895263671875	91	3	11	2018-11-10 05:13:23
21476	233.998931884765625	680	3	5	2018-12-01 01:49:50
21477	531.1475830078125	971	3	12	2018-11-02 17:10:13
21478	216.92767333984375	99	3	3	2018-11-22 19:18:17
21479	645.49102783203125	451	3	4	2018-11-26 20:05:48
21480	875.7353515625	678	3	3	2018-12-02 16:34:04
21481	490.471099853515625	781	3	4	2018-12-01 21:46:02
21482	873.6519775390625	623	3	11	2018-10-14 15:44:38
21483	563.2115478515625	211	3	4	2018-09-27 20:10:30
21484	471.633453369140625	570	3	1	2019-01-22 19:40:33
21485	615.38751220703125	827	3	1	2018-11-03 22:14:29
21486	573.2564697265625	198	3	11	2018-10-24 09:38:41
21487	429.764068603515625	187	3	12	2018-12-24 09:32:00
21488	476.054840087890625	802	3	5	2018-12-05 09:41:39
21489	381.742523193359375	123	3	5	2018-12-04 10:21:37
21490	790.19854736328125	987	3	12	2018-10-03 23:05:35
21491	730.17718505859375	583	3	12	2019-02-28 01:14:41
21492	280.003753662109375	418	3	1	2018-09-23 03:59:59
21493	333.317230224609375	652	3	1	2018-12-25 03:36:36
21494	838.36492919921875	802	3	12	2018-11-11 10:17:56
21495	823.02001953125	359	3	4	2019-02-22 03:24:31
21496	920.60064697265625	245	3	12	2018-10-12 15:37:11
21497	991.22607421875	638	3	12	2018-12-05 16:18:08
21498	659.7320556640625	207	3	11	2018-11-25 01:25:47
21499	975.88739013671875	35	3	1	2018-11-11 07:41:28
21500	621.36444091796875	56	3	12	2018-09-06 23:37:18
21501	483.81512451171875	766	3	12	2018-10-14 08:56:02
21502	228.465667724609375	829	3	3	2019-01-25 08:29:38
21503	638.5120849609375	22	3	4	2019-03-09 00:11:07
21504	816.2462158203125	33	3	5	2019-01-25 04:46:31
21505	546.27752685546875	633	3	5	2019-02-17 08:29:22
21506	91.2475128173828125	189	3	1	2018-09-26 14:25:55
21507	901.506591796875	678	3	1	2018-12-26 06:22:47
21508	79.3473281860351562	463	3	4	2018-12-07 23:38:09
21509	110.25408935546875	124	3	4	2018-12-08 16:19:45
21510	425.456298828125	240	3	5	2019-02-26 14:16:52
21511	226.303359985351562	69	3	12	2019-01-05 09:06:13
21512	341.39312744140625	28	3	1	2018-10-14 12:15:09
21513	917.31805419921875	90	3	11	2018-11-04 05:24:20
21514	444.82806396484375	835	3	11	2018-11-03 05:55:55
21515	242.887771606445312	909	3	11	2018-11-05 19:07:15
21516	902.0025634765625	124	3	4	2019-01-07 11:34:36
21517	430.5860595703125	599	3	12	2018-12-16 08:55:25
21518	311.320892333984375	242	3	3	2018-11-25 09:19:54
21519	745.811767578125	994	3	5	2019-01-28 00:46:19
21520	806.8271484375	30	3	5	2019-02-12 22:16:10
21521	864.84625244140625	778	3	1	2018-12-04 15:27:21
21522	31.3996791839599609	151	3	5	2018-12-14 00:08:49
21523	208.551239013671875	975	3	12	2019-02-22 09:06:11
21524	619.69317626953125	175	3	3	2018-10-20 11:17:29
21525	509.660675048828125	870	3	12	2018-11-30 02:09:03
21526	954.76580810546875	778	3	4	2018-11-01 21:01:21
21527	273.493072509765625	344	3	12	2018-12-27 19:15:18
21528	529.46136474609375	983	3	3	2018-12-14 17:13:42
21529	228.741989135742188	280	3	1	2018-09-28 21:26:22
21530	339.3092041015625	912	3	4	2018-09-07 08:07:25
21531	530.1864013671875	907	3	11	2019-02-22 20:50:57
21532	320.082000732421875	670	3	11	2018-09-30 01:30:53
21533	930.2139892578125	1018	3	12	2019-03-13 02:32:37
21534	46.7587394714355469	492	3	11	2018-12-21 18:15:03
21535	440.7919921875	960	3	12	2018-10-20 15:07:26
21536	946.5546875	223	3	1	2019-01-02 08:30:56
21537	160.182144165039062	735	3	3	2018-11-29 08:09:39
21538	367.147918701171875	326	3	12	2018-09-14 05:42:03
21539	230.663192749023438	894	3	5	2019-02-18 09:20:02
21540	1018.3116455078125	711	3	12	2018-11-27 14:09:45
21541	870.9810791015625	352	3	5	2018-10-17 08:39:59
21542	614.47021484375	600	3	11	2019-02-08 06:42:47
21543	40.2108001708984375	879	3	5	2019-02-24 01:28:38
21544	952.00457763671875	876	3	3	2019-02-15 01:43:09
21545	240.618972778320312	244	3	1	2019-02-28 17:50:49
21546	549.90814208984375	287	3	12	2018-10-09 21:38:42
21547	21.1168117523193359	709	3	4	2018-11-11 17:02:35
21548	746.72314453125	978	3	3	2019-01-17 11:01:36
21549	728.9078369140625	186	3	1	2019-01-17 02:42:39
21550	420.190277099609375	162	3	5	2018-10-05 05:00:32
21551	370.34393310546875	811	3	3	2018-09-16 05:00:39
21552	287.092864990234375	594	3	12	2018-11-25 12:15:19
21553	526.242919921875	867	3	3	2018-10-16 06:01:37
21554	463.34149169921875	764	3	4	2019-03-01 01:29:44
21555	864.7210693359375	95	3	4	2018-10-31 06:09:06
21556	750.57318115234375	800	3	1	2018-11-13 08:31:17
21557	602.66937255859375	632	3	12	2019-01-13 06:29:32
21558	222.2603759765625	249	3	5	2018-09-19 03:30:36
21559	661.29510498046875	56	3	11	2018-09-14 18:51:11
21560	152.45977783203125	205	3	1	2018-12-23 12:14:55
21561	706.3997802734375	165	3	11	2018-12-18 06:43:33
21562	932.72821044921875	493	3	4	2019-01-28 22:33:33
21563	677.09832763671875	943	3	11	2019-02-28 01:23:24
21564	21.1995201110839844	21	3	1	2018-12-19 09:45:17
21565	208.298248291015625	892	3	3	2019-01-04 22:22:21
21566	640.40679931640625	263	3	4	2018-12-21 20:01:22
21567	370.937042236328125	124	3	12	2019-02-20 06:50:16
21568	234.384475708007812	911	3	5	2018-10-20 09:21:29
21569	72.41973876953125	198	3	4	2019-03-18 11:47:05
21570	58.5882568359375	419	3	3	2019-01-08 03:15:10
21571	529.4896240234375	360	3	3	2018-12-03 06:50:45
21572	135.873870849609375	717	3	12	2018-09-27 01:18:52
21573	256.848541259765625	286	3	12	2018-10-22 23:53:43
21574	83.7333145141601562	160	3	4	2019-01-14 05:53:26
21575	386.204681396484375	455	3	5	2019-02-17 15:50:30
21576	834.88165283203125	579	3	11	2019-01-24 07:18:28
21577	881.73779296875	323	3	4	2018-11-19 01:03:25
21578	521.7540283203125	500	3	1	2018-11-22 01:50:06
21579	211.08685302734375	452	3	4	2018-11-14 16:30:06
21580	924.7001953125	493	3	3	2019-02-22 03:21:12
21581	178.109375	426	3	12	2019-03-08 08:56:07
21582	142.196060180664062	831	3	4	2019-01-02 23:42:45
21583	215.757781982421875	236	3	1	2018-12-29 00:54:17
21584	306.20867919921875	769	3	4	2019-03-11 21:33:18
21585	473.595855712890625	574	3	3	2019-03-15 17:53:25
21586	753.4915771484375	39	3	1	2018-09-15 21:31:53
21587	310.8826904296875	409	3	5	2018-11-20 05:51:43
21588	410.789642333984375	723	3	12	2018-09-15 12:10:53
21589	820.70697021484375	92	3	11	2018-11-06 20:04:53
21590	871.8470458984375	1014	3	12	2018-11-14 11:23:12
21591	30.8083629608154297	384	3	4	2018-12-08 20:57:11
21592	893.58441162109375	140	3	1	2018-11-13 09:54:55
21593	576.0555419921875	620	3	3	2018-10-10 07:59:14
21594	145.911361694335938	431	3	1	2018-10-31 14:30:03
21595	960.177734375	143	3	1	2019-02-17 06:21:58
21596	697.0909423828125	84	3	11	2019-03-18 04:36:54
21597	200.896377563476562	775	3	3	2018-10-02 11:31:48
21598	838.329345703125	985	3	1	2018-10-29 01:24:44
21599	632.9749755859375	892	3	4	2019-03-01 15:13:14
21600	75.6516189575195312	499	3	12	2019-02-11 12:01:28
21601	611.1435546875	899	3	12	2018-09-22 13:19:56
21602	775.5562744140625	647	3	5	2018-11-17 08:48:08
21603	151.649459838867188	781	3	4	2019-02-21 13:55:40
21604	287.488525390625	310	3	5	2019-01-03 05:53:34
21605	111.693450927734375	162	3	12	2018-12-12 06:44:34
21606	389.77862548828125	42	3	11	2019-03-15 09:35:27
21607	796.80181884765625	285	3	11	2018-10-17 02:37:56
21608	952.57806396484375	477	3	3	2018-09-11 14:34:39
21609	232.705108642578125	241	3	4	2019-01-20 12:59:13
21610	670.15185546875	626	3	4	2018-10-01 05:37:09
21611	607.1722412109375	579	3	3	2018-12-18 06:27:19
21612	793.13189697265625	454	3	11	2018-09-25 18:18:46
21613	529.0732421875	545	3	4	2018-10-19 11:59:34
21614	607.5411376953125	302	3	4	2018-11-17 09:48:01
21615	741.13092041015625	662	3	5	2019-03-19 05:51:50
21616	303.80657958984375	189	3	1	2019-01-09 11:14:02
21617	742.00079345703125	873	3	12	2019-03-06 13:33:17
21618	741.24017333984375	793	3	1	2018-12-17 07:21:35
21619	479.3507080078125	798	3	11	2018-09-29 17:28:17
21620	292.3763427734375	440	3	12	2019-02-20 22:11:04
21621	801.34368896484375	697	3	4	2018-10-13 11:25:22
21622	491.39019775390625	677	3	3	2019-03-07 15:11:06
21623	22.3746452331542969	800	3	1	2019-02-07 01:20:18
21624	712.29345703125	939	3	3	2018-10-11 19:40:48
21625	92.9650421142578125	523	3	3	2018-11-10 04:50:49
21626	114.119453430175781	411	3	5	2018-11-12 15:17:30
21627	623.84356689453125	306	3	3	2019-01-13 21:28:40
21628	241.397705078125	586	3	5	2019-01-06 23:26:32
21629	258.200042724609375	610	3	3	2019-02-08 15:48:40
21630	203.7734375	726	3	11	2019-02-01 00:13:15
21631	915.12335205078125	829	3	12	2019-03-08 15:46:52
21632	607.564453125	976	3	4	2018-12-05 02:43:29
21633	686.03656005859375	966	3	11	2018-09-12 09:00:15
21634	424.08837890625	932	3	11	2018-12-13 01:06:18
21635	251.22174072265625	978	3	5	2019-03-17 09:45:23
21636	896.59173583984375	839	3	5	2018-12-24 04:28:26
21637	446.33453369140625	499	3	11	2018-11-11 03:58:33
21638	311.715911865234375	286	3	5	2019-01-03 21:33:08
21639	775.3837890625	296	3	5	2019-03-16 14:14:23
21640	616.0797119140625	925	3	1	2019-01-07 01:47:59
21641	399.03912353515625	454	3	4	2018-09-18 03:13:39
21642	573.99822998046875	365	3	1	2019-03-08 18:05:58
21643	464.187469482421875	677	3	11	2018-11-10 08:49:23
21644	766.6878662109375	120	3	3	2019-01-24 05:19:11
21645	231.03436279296875	818	3	11	2018-11-02 20:13:34
21646	974.080810546875	382	3	12	2018-12-26 05:17:37
21647	847.85516357421875	233	3	4	2019-01-18 07:06:05
21648	89.5423507690429688	984	3	12	2018-10-13 06:23:05
21649	973.47540283203125	423	3	4	2018-10-16 08:59:02
21650	208.869644165039062	127	3	11	2018-10-03 23:46:23
21651	41.4356727600097656	22	3	3	2019-02-04 19:16:14
21652	265.177154541015625	982	3	4	2019-02-10 08:01:44
21653	715.8302001953125	296	3	11	2019-01-19 11:54:40
21654	709.41009521484375	785	3	11	2019-01-26 21:02:17
21655	866.737548828125	688	3	11	2018-09-09 20:32:14
21656	357.44439697265625	908	3	5	2019-01-18 01:37:18
21657	304.34576416015625	690	3	1	2019-01-17 18:40:22
21658	470.101165771484375	496	3	5	2019-03-08 01:50:08
21659	456.424591064453125	296	3	4	2019-03-17 12:42:32
21660	907.70751953125	154	3	5	2019-02-20 23:57:34
21661	480.7373046875	406	3	5	2018-09-21 05:21:35
21662	565.97528076171875	945	3	11	2018-12-27 18:25:29
21663	673.3079833984375	986	3	4	2018-10-13 12:03:38
21664	941.17425537109375	805	3	5	2018-11-16 07:38:59
21665	617.67822265625	1018	3	11	2018-12-01 18:51:44
21666	634.18646240234375	706	3	4	2018-10-19 05:22:27
21667	446.93939208984375	832	3	12	2018-11-22 23:40:58
21668	716.2381591796875	510	3	11	2018-10-08 12:08:46
21669	916.8109130859375	343	3	3	2019-01-13 19:39:30
21670	353.928253173828125	81	3	3	2019-01-06 16:14:06
21671	829.363525390625	625	3	4	2018-11-23 19:15:02
21672	83.8444061279296875	86	3	5	2018-11-26 13:30:10
21673	334.855316162109375	88	3	12	2018-09-06 18:16:04
21674	648.16986083984375	642	3	12	2018-11-01 13:34:04
21675	695.1055908203125	869	3	11	2019-03-20 20:11:07
21676	293.6202392578125	166	3	11	2018-10-04 19:21:07
21677	692.17669677734375	547	3	1	2019-03-18 18:13:35
21678	180.993255615234375	377	3	1	2019-03-22 18:35:51
21679	480.91265869140625	585	3	11	2018-12-11 09:41:05
21680	99.5711135864257812	338	3	5	2018-10-28 03:57:46
21681	425.330078125	278	3	3	2018-09-18 06:15:54
21682	127.252326965332031	314	3	3	2018-09-06 10:54:39
21683	389.917388916015625	849	3	3	2018-09-28 12:55:01
21684	536.07928466796875	309	3	5	2018-12-21 00:00:46
21685	496.767852783203125	41	3	5	2019-01-24 07:25:08
21686	615.89776611328125	643	3	11	2018-10-15 08:36:19
21687	318.93634033203125	135	3	4	2018-10-01 04:43:17
21688	554.49700927734375	545	3	11	2019-01-18 11:39:23
21689	460.7506103515625	141	3	12	2018-10-23 22:20:57
21690	652.5059814453125	515	3	3	2018-09-15 02:56:23
21691	96.75775146484375	608	3	1	2018-09-30 10:00:46
21692	806.44769287109375	797	3	11	2018-12-10 11:01:13
21693	980.176025390625	134	3	4	2018-12-19 13:05:53
21694	756.2049560546875	979	3	3	2019-01-24 03:14:53
21695	758.56524658203125	626	3	1	2018-12-30 03:39:18
21696	99.9262237548828125	902	3	5	2019-03-21 16:39:04
21697	154.540985107421875	714	3	1	2019-02-26 06:15:24
21698	731.87384033203125	1017	3	4	2019-02-13 12:57:23
21699	159.441864013671875	446	3	11	2019-02-21 05:42:39
21700	478.27197265625	497	3	5	2019-01-10 14:26:51
21701	539.16717529296875	274	3	4	2018-12-13 17:47:15
21702	853.58331298828125	450	3	12	2018-09-13 16:46:22
21703	397.47259521484375	68	3	12	2018-10-25 18:44:59
21704	637.44232177734375	690	3	1	2018-10-01 09:11:55
21705	86.6964569091796875	430	3	12	2018-10-04 05:32:58
21706	432.827362060546875	471	3	1	2019-03-16 10:01:53
21707	289.296630859375	761	3	5	2018-09-22 11:10:13
21708	743.0592041015625	371	3	3	2018-10-27 03:06:49
21709	589.28759765625	505	3	1	2018-12-01 19:38:46
21710	590.83062744140625	949	3	11	2018-10-13 22:49:35
21711	269.36236572265625	912	3	11	2019-02-28 04:25:53
21712	779.03863525390625	245	3	4	2018-12-02 11:16:58
21713	322.925079345703125	675	3	5	2018-10-08 19:32:49
21714	299.25238037109375	266	3	11	2018-11-13 22:16:00
21715	809.51751708984375	390	3	3	2019-01-18 09:50:07
21716	302.35186767578125	693	3	4	2018-12-12 21:06:25
21717	828.7996826171875	665	3	4	2018-12-04 11:55:08
21718	296.089385986328125	197	3	5	2018-12-25 16:15:36
21719	147.797454833984375	936	3	1	2018-11-30 20:54:03
21720	411.226715087890625	615	3	12	2018-11-22 07:21:28
21721	58.5167388916015625	725	3	12	2019-02-12 16:19:37
21722	467.2550048828125	180	3	3	2018-12-24 06:18:02
21723	999.415283203125	886	3	4	2018-10-30 20:30:37
21724	677.263916015625	666	3	4	2018-10-25 22:56:28
21725	42.6516914367675781	486	3	1	2019-02-07 12:22:56
21726	633.05279541015625	652	3	1	2018-12-22 17:01:25
21727	792.4393310546875	356	3	5	2018-10-16 22:15:12
21728	80.9138336181640625	1006	3	5	2018-09-12 17:25:42
21729	949.26971435546875	541	3	3	2019-03-01 09:58:30
21730	212.154739379882812	807	3	5	2018-09-29 06:53:09
21731	816.70904541015625	695	3	12	2019-03-06 05:33:02
21732	393.743865966796875	604	3	11	2019-02-27 12:47:46
21733	115.130012512207031	543	3	4	2018-09-16 10:10:58
21734	452.0294189453125	429	3	11	2019-03-13 07:52:42
21735	109.657829284667969	755	3	12	2019-02-24 02:35:19
21736	383.471923828125	211	3	12	2019-02-19 16:14:55
21737	797.5250244140625	718	3	4	2019-01-15 23:18:51
21738	452.98663330078125	763	3	12	2018-12-11 20:55:22
21739	155.34051513671875	95	3	4	2018-11-27 22:03:28
21740	97.7285919189453125	806	3	3	2018-12-31 10:01:54
21741	804.03656005859375	234	3	1	2018-10-16 16:37:44
21742	211.198532104492188	640	3	12	2018-12-17 07:34:50
21743	265.830078125	641	3	11	2019-03-21 03:30:41
21744	907.86651611328125	216	3	3	2018-10-09 11:59:43
21745	246.7952880859375	297	3	1	2019-01-08 04:13:18
21746	695.930908203125	341	3	5	2018-12-02 06:41:58
21747	27.0680770874023438	313	3	4	2018-12-22 23:36:29
21748	892.527099609375	545	3	1	2018-11-16 17:03:59
21749	709.56256103515625	542	3	12	2018-10-31 03:10:14
21750	998.483154296875	816	3	11	2019-03-10 14:48:26
21751	677.83746337890625	958	3	12	2018-10-10 12:25:11
21752	864.11431884765625	606	3	1	2018-09-23 03:35:16
21753	968.35760498046875	287	3	5	2019-01-02 05:11:55
21754	957.0899658203125	501	3	3	2019-02-02 10:23:43
21755	512.7113037109375	815	3	4	2019-01-22 21:17:49
21756	582.79522705078125	480	3	3	2018-10-08 10:17:37
21757	457.2880859375	722	3	5	2019-01-04 12:04:21
21758	311.542999267578125	515	3	11	2019-02-02 04:31:09
21759	312.55084228515625	763	3	11	2018-11-13 08:08:30
21760	642.46978759765625	638	3	11	2019-01-26 19:51:03
21761	608.12115478515625	260	3	12	2019-01-26 09:33:14
21762	242.522476196289062	449	3	11	2018-12-07 17:20:44
21763	372.18621826171875	180	3	4	2019-02-13 07:59:28
21764	806.4144287109375	774	3	12	2018-12-22 17:07:42
21765	81.5639495849609375	297	3	3	2019-03-14 13:20:58
21766	661.346923828125	726	3	4	2018-12-03 20:59:35
21767	318.090240478515625	81	3	11	2019-03-08 13:53:10
21768	434.994537353515625	59	3	5	2019-02-03 12:13:34
21769	848.91546630859375	968	3	3	2018-11-25 03:58:43
21770	752.4835205078125	810	3	3	2019-02-05 22:51:31
21771	731.36920166015625	120	3	3	2018-10-10 23:37:58
21772	27.7783851623535156	663	3	5	2018-09-27 09:46:57
21773	363.85076904296875	901	3	3	2019-01-21 15:15:53
21774	124.539779663085938	473	3	4	2018-09-13 20:42:12
21775	518.70849609375	310	3	4	2018-11-01 18:45:38
21776	426.549774169921875	173	3	5	2018-10-12 11:23:46
21777	877.12030029296875	301	3	12	2018-10-30 19:45:43
21778	496.01397705078125	936	3	4	2018-12-12 18:14:02
21779	62.6574935913085938	730	3	1	2019-01-31 16:24:56
21780	96.0259780883789062	345	3	11	2019-02-08 04:05:58
21781	268.72357177734375	332	3	1	2019-01-28 12:19:09
21782	387.77117919921875	672	3	4	2018-10-18 13:04:07
21783	96.1003265380859375	328	3	4	2018-10-17 07:36:29
21784	806.676025390625	864	3	11	2018-10-16 05:29:09
21785	649.35443115234375	776	3	3	2019-03-18 07:00:33
21786	688.13531494140625	104	3	12	2019-03-02 12:13:20
21787	105.45758056640625	137	3	3	2018-11-15 15:11:54
21788	960.314697265625	548	3	11	2019-03-18 21:12:25
21789	256.04498291015625	921	3	11	2018-10-27 23:08:33
21790	522.46575927734375	546	3	5	2018-10-22 00:19:01
21791	343.355987548828125	283	3	1	2018-10-28 09:05:31
21792	990.83367919921875	932	3	1	2019-02-07 05:01:41
21793	271.89019775390625	377	3	4	2018-12-16 12:01:50
21794	279.83648681640625	421	3	1	2018-10-19 06:36:56
21795	43.3919715881347656	530	3	1	2018-10-24 01:18:57
21796	415.529388427734375	833	3	5	2018-12-02 10:16:50
21797	34.7883567810058594	852	3	3	2018-09-19 07:34:30
21798	1000.58294677734375	1001	3	4	2018-10-24 12:39:26
21799	787.9803466796875	608	3	5	2018-09-13 17:54:10
21800	145.160064697265625	945	3	1	2018-10-14 00:30:35
21801	694.091064453125	213	3	11	2018-12-13 19:31:43
21802	978.7568359375	216	3	11	2019-01-23 02:09:00
21803	782.22698974609375	769	3	4	2019-02-02 22:16:48
21804	632.3687744140625	472	3	5	2019-02-08 17:28:49
21805	1011.40673828125	388	3	5	2018-09-10 20:41:35
21806	443.30126953125	745	3	12	2019-03-02 02:18:15
21807	178.002655029296875	566	3	12	2018-11-12 11:17:34
21808	611.28717041015625	846	3	12	2018-12-25 05:24:23
21809	267.41754150390625	689	3	11	2018-10-02 09:24:27
21810	88.3859634399414062	416	3	11	2019-03-22 10:09:30
21811	401.362945556640625	819	3	11	2018-11-23 00:00:56
21812	417.88677978515625	200	3	4	2018-09-14 13:28:02
21813	38.9910774230957031	535	3	3	2018-11-19 13:03:53
21814	964.42498779296875	718	3	4	2019-01-03 05:36:40
21815	788.360107421875	755	3	3	2018-12-16 20:59:31
21816	435.916259765625	166	3	3	2019-03-13 23:19:48
21817	931.491943359375	411	3	1	2018-10-03 16:05:50
21818	172.781097412109375	694	3	1	2018-09-10 06:16:17
21819	399.552001953125	316	3	12	2018-11-23 17:57:32
21820	946.984130859375	942	3	3	2018-11-24 22:51:49
21821	726.6380615234375	923	3	12	2019-03-19 08:46:06
21822	682.12066650390625	417	3	5	2018-11-24 11:58:07
21823	101.548110961914062	509	3	12	2019-02-04 01:28:03
21824	964.9241943359375	1008	3	1	2018-10-27 03:21:03
21825	488.850921630859375	672	3	3	2019-01-08 01:13:48
21826	983.8009033203125	961	3	3	2018-09-19 08:17:19
21827	980.33843994140625	792	3	3	2019-02-01 18:18:21
21828	980.36041259765625	786	3	3	2018-11-11 18:54:29
21829	577.155517578125	189	3	4	2018-09-05 01:15:44
21830	616.3818359375	319	3	3	2018-12-27 13:21:42
21831	277.16650390625	524	3	11	2018-12-16 15:56:13
21832	873.62744140625	802	3	4	2019-02-20 12:09:49
21833	554.31390380859375	385	3	5	2018-12-06 23:48:18
21834	391.5885009765625	494	3	5	2018-12-25 11:19:33
21835	598.29156494140625	99	3	4	2018-11-29 21:50:24
21836	755.2633056640625	26	3	11	2018-09-12 10:12:01
21837	325.2882080078125	1005	3	5	2019-02-11 16:31:10
21838	82.4579391479492188	403	3	5	2019-02-08 17:54:57
21839	451.38775634765625	75	3	3	2018-12-26 21:33:32
21840	642.5350341796875	441	3	12	2019-03-11 20:05:53
21841	624.21551513671875	456	3	4	2019-02-20 08:27:47
21842	476.470794677734375	90	3	1	2019-02-10 17:20:21
21843	913.7886962890625	515	3	4	2018-09-09 01:23:51
21844	605.35589599609375	521	3	1	2018-09-08 14:02:21
21845	215.473983764648438	621	3	4	2019-01-12 09:11:23
21846	666.0079345703125	991	3	11	2019-02-16 22:49:04
21847	36.153472900390625	313	3	3	2019-01-07 17:37:02
21848	131.09869384765625	515	3	12	2019-01-19 03:48:02
21849	516.18341064453125	877	3	1	2018-11-02 09:13:49
21850	224.50054931640625	884	3	5	2018-09-10 23:41:35
21851	839.31610107421875	827	3	12	2018-10-05 10:03:18
21852	306.539703369140625	563	3	4	2018-10-20 09:48:48
21853	976.6661376953125	395	3	1	2018-11-25 23:55:28
21854	171.981613159179688	353	3	12	2018-11-02 10:45:02
21855	614.58526611328125	366	3	11	2019-01-07 04:46:13
21856	469.954071044921875	999	3	1	2018-12-31 08:58:07
21857	543.47906494140625	87	3	3	2019-03-15 18:12:38
21858	574.7962646484375	465	3	11	2019-02-12 01:18:52
21859	756.93463134765625	659	3	1	2019-02-23 07:03:53
21860	614.1004638671875	433	3	5	2018-10-26 19:26:59
21861	510.002227783203125	118	3	5	2019-02-25 17:07:31
21862	254.926345825195312	114	3	11	2018-11-11 08:43:52
21863	463.156829833984375	268	3	12	2018-11-24 11:45:17
21864	390.666839599609375	416	3	12	2018-09-19 22:52:23
21865	676.60882568359375	633	3	12	2019-02-26 00:00:02
21866	598.7603759765625	451	3	11	2019-03-09 23:36:46
21867	570.5113525390625	282	3	3	2019-03-04 08:58:30
21868	925.32550048828125	415	3	11	2018-09-28 01:26:41
21869	360.99981689453125	221	3	11	2018-09-12 14:49:24
21870	793.92626953125	139	3	5	2019-03-22 06:04:03
21871	537.62615966796875	303	3	1	2018-09-27 23:42:43
21872	503.22265625	834	3	11	2018-12-30 11:48:00
21873	503.94342041015625	341	3	5	2018-12-09 09:28:55
21874	775.22796630859375	442	3	11	2018-10-09 23:37:30
21875	1015.76690673828125	116	3	4	2019-02-20 02:11:42
21876	441.829193115234375	157	3	12	2019-02-03 17:29:32
21877	979.5692138671875	398	3	5	2019-01-04 21:44:55
21878	184.59588623046875	72	3	11	2019-02-15 13:58:35
21879	34.860626220703125	218	3	12	2019-01-25 01:44:28
21880	644.422607421875	639	3	5	2018-11-18 00:40:42
21881	335.44110107421875	517	3	11	2019-02-23 01:07:36
21882	335.31561279296875	137	3	1	2019-03-18 14:51:43
21883	779.4283447265625	259	3	11	2019-02-12 14:37:43
21884	989.38397216796875	990	3	4	2019-01-18 21:53:47
21885	701.25665283203125	432	3	11	2018-10-29 10:10:46
21886	616.71002197265625	469	3	11	2019-03-13 01:30:54
21887	289.781036376953125	69	3	11	2019-01-30 20:31:15
21888	325.683319091796875	76	3	1	2018-11-10 03:34:54
21889	857.85791015625	82	3	1	2019-02-24 10:44:55
21890	401.139801025390625	183	3	1	2018-12-25 05:27:44
21891	539.90478515625	941	3	4	2019-01-31 07:52:51
21892	269.0831298828125	1019	3	3	2019-01-28 11:53:12
21893	164.46234130859375	434	3	5	2018-10-05 02:18:26
21894	543.81744384765625	916	3	4	2018-10-13 20:40:06
21895	565.2332763671875	242	3	3	2018-11-26 06:29:49
21896	146.62933349609375	520	3	12	2019-01-30 05:11:00
21897	158.787322998046875	503	3	3	2019-02-28 01:19:51
21898	427.726837158203125	381	3	5	2018-12-14 04:30:17
21899	635.029052734375	767	3	4	2018-11-10 16:25:53
21900	94.1079483032226562	939	3	1	2018-11-03 20:00:55
21901	452.381439208984375	850	3	11	2019-03-12 20:50:26
21902	961.03204345703125	839	3	5	2019-02-07 12:03:09
21903	209.195999145507812	678	3	12	2019-02-05 02:26:08
21904	168.995513916015625	279	3	3	2019-02-23 09:28:02
21905	655.61224365234375	667	3	5	2018-09-12 16:35:20
21906	965.9088134765625	649	3	1	2019-03-05 20:30:52
21907	285.057281494140625	632	3	11	2018-11-04 02:16:57
21908	711.8875732421875	752	3	3	2018-10-24 08:43:23
21909	925.55859375	350	3	1	2018-10-10 08:26:01
21910	699.014892578125	339	3	11	2018-11-13 09:45:52
21911	320.924346923828125	465	3	12	2018-09-04 04:55:40
21912	61.1226348876953125	875	3	3	2018-09-11 03:52:39
21913	562.93157958984375	288	3	1	2018-09-15 20:28:17
21914	971.80401611328125	998	3	3	2018-09-27 22:09:18
21915	60.9533882141113281	1001	3	12	2018-10-04 09:16:26
21916	649.60601806640625	649	3	3	2018-11-30 21:16:08
21917	841.2845458984375	390	3	11	2018-10-30 00:59:54
21918	903.87017822265625	881	3	5	2019-02-23 21:23:11
21919	189.455276489257812	76	3	11	2018-11-11 14:53:08
21920	210.042098999023438	788	3	12	2019-02-19 22:22:20
21921	459.105621337890625	41	3	12	2019-03-17 08:38:42
21922	996.173095703125	537	3	4	2018-12-30 11:32:04
21923	58.9665946960449219	288	3	12	2018-09-21 15:16:33
21924	256.2198486328125	827	3	4	2018-11-07 02:45:34
21925	832.0264892578125	560	3	12	2018-11-14 12:24:26
21926	738.2086181640625	154	3	3	2018-09-26 21:53:08
21927	989.14569091796875	498	3	11	2018-11-16 05:58:15
21928	125.791259765625	790	3	11	2018-10-17 11:47:37
21929	489.49371337890625	765	3	4	2019-01-15 16:47:03
21930	591.4630126953125	683	3	5	2018-09-10 19:53:26
21931	814.0831298828125	352	3	1	2018-10-29 05:56:37
21932	950.250732421875	908	3	3	2019-03-08 11:40:30
21933	542.837890625	45	3	5	2019-02-14 21:39:55
21934	789.850341796875	783	3	5	2018-12-07 00:51:22
21935	825.84014892578125	142	3	1	2018-12-22 20:29:33
21936	902.23944091796875	881	3	4	2018-11-19 09:25:33
21937	264.3270263671875	171	3	11	2018-11-07 06:54:48
21938	1008.3447265625	768	3	4	2019-02-11 20:05:20
21939	155.585739135742188	940	3	5	2018-12-28 17:07:09
21940	666.86761474609375	330	3	1	2019-03-15 15:24:01
21941	830.5054931640625	62	3	3	2018-11-09 12:58:23
21942	653.23052978515625	927	3	12	2018-10-26 22:04:19
21943	594.50592041015625	109	3	1	2019-03-04 10:01:05
21944	755.04998779296875	296	3	12	2019-01-16 19:07:00
21945	477.923248291015625	99	3	1	2019-01-06 00:59:32
21946	191.37261962890625	953	3	5	2018-10-07 22:53:16
21947	911.8365478515625	343	3	12	2018-11-12 18:05:07
21948	562.74658203125	630	3	11	2018-12-03 23:16:44
21949	538.9676513671875	331	3	12	2019-01-01 18:05:34
21950	469.079498291015625	688	3	3	2019-01-04 14:43:17
21951	567.04205322265625	581	3	3	2019-02-20 15:00:37
21952	331.25189208984375	332	3	1	2019-02-16 00:44:26
21953	969.2069091796875	152	3	3	2018-09-25 23:02:32
21954	515.3992919921875	723	3	11	2018-11-30 22:24:54
21955	192.807022094726562	290	3	11	2018-10-14 18:06:40
21956	367.49591064453125	185	3	1	2018-10-27 18:45:30
21957	503.695953369140625	788	3	1	2019-03-04 22:10:20
21958	696.96636962890625	507	3	4	2019-01-27 14:28:29
21959	65.3605499267578125	426	3	1	2018-12-26 10:52:02
21960	988.63177490234375	708	3	11	2018-11-30 21:54:37
21961	728.1968994140625	880	3	4	2018-12-28 06:47:44
21962	931.2781982421875	825	3	11	2018-09-09 11:10:28
21963	28.3150577545166016	286	3	12	2018-12-01 12:34:20
21964	723.7247314453125	535	3	12	2019-03-17 13:07:42
21965	675.86773681640625	990	3	5	2018-10-06 17:25:09
21966	965.0218505859375	504	3	1	2018-10-08 11:28:27
21967	309.7633056640625	943	3	12	2018-11-19 04:47:21
21968	627.3887939453125	929	3	4	2019-01-20 13:15:50
21969	231.830718994140625	376	3	3	2018-10-12 22:09:26
21970	420.2197265625	730	3	1	2019-01-09 03:27:57
21971	700.6636962890625	1005	3	3	2018-12-13 04:43:21
21972	787.762451171875	24	3	5	2018-10-17 20:55:57
21973	175.947860717773438	929	3	1	2019-03-04 11:00:37
21974	541.2633056640625	815	3	11	2018-10-02 16:54:48
21975	528.0198974609375	938	3	4	2019-03-08 03:41:28
21976	712.39031982421875	887	3	4	2018-10-13 06:00:24
21977	290.41302490234375	102	3	12	2018-10-02 08:03:12
21978	700.29376220703125	663	3	5	2018-10-26 13:01:35
21979	383.564361572265625	841	3	5	2018-09-05 20:05:37
21980	97.009521484375	46	3	12	2019-01-28 15:34:43
21981	966.05645751953125	421	3	4	2019-02-24 14:56:34
21982	596.0765380859375	157	3	1	2018-12-20 18:16:51
21983	949.45947265625	502	3	3	2018-11-14 14:55:41
21984	780.533203125	810	3	12	2018-12-04 01:27:20
21985	282.3533935546875	289	3	4	2019-02-05 21:26:57
21986	303.474578857421875	530	3	3	2018-11-23 17:02:48
21987	552.1673583984375	53	3	1	2018-12-08 16:04:24
21988	691.19635009765625	779	3	4	2019-03-17 06:47:37
21989	172.674758911132812	355	3	11	2018-12-02 00:05:34
21990	829.9757080078125	553	3	11	2018-11-30 20:26:07
21991	708.5941162109375	93	3	12	2018-12-14 06:18:03
21992	501.359375	267	3	1	2018-11-09 23:27:29
21993	438.068511962890625	833	3	1	2019-03-22 09:34:21
21994	864.56439208984375	913	3	4	2018-11-02 19:38:40
21995	746.30352783203125	632	3	1	2018-11-20 00:10:51
21996	97.215240478515625	1009	3	1	2019-02-11 00:25:26
21997	375.6259765625	1020	3	3	2019-03-15 20:41:04
21998	397.712432861328125	565	3	4	2019-02-16 06:13:01
21999	564.947509765625	831	3	12	2018-09-10 18:14:59
22000	655.0904541015625	777	3	4	2018-10-17 07:19:19
22001	244.256515502929688	137	3	12	2018-11-02 08:20:12
22002	231.80682373046875	954	3	3	2018-10-23 07:29:00
22003	104.249305725097656	505	3	12	2018-12-22 17:09:38
22004	229.25128173828125	354	3	4	2019-01-27 13:47:42
22005	937.996826171875	985	3	5	2019-02-26 12:55:59
22006	591.1739501953125	212	3	4	2018-12-29 15:37:21
22007	869.2010498046875	741	3	11	2018-12-28 21:05:49
22008	1015.37994384765625	909	3	1	2018-09-07 16:19:29
22009	778.8265380859375	384	3	3	2018-11-07 08:16:34
22010	69.9293441772460938	234	3	3	2019-01-08 21:51:13
22011	402.19818115234375	80	3	12	2019-01-05 13:36:53
22012	495.877105712890625	512	3	3	2019-03-20 21:16:02
22013	411.442413330078125	979	3	3	2019-01-09 05:14:00
22014	308.81011962890625	106	3	11	2018-11-16 11:09:45
22015	561.44970703125	581	3	3	2018-12-26 04:26:53
22016	71.9421234130859375	113	3	11	2018-10-21 07:55:58
22017	432.673828125	109	3	3	2018-09-06 02:23:24
22018	933.248046875	507	3	11	2019-01-01 12:16:43
22019	509.99932861328125	134	3	1	2018-10-15 01:44:12
22020	210.739410400390625	509	3	11	2018-11-01 08:07:40
22021	677.33563232421875	276	3	4	2018-11-03 02:19:44
22022	436.77679443359375	460	3	1	2018-10-03 15:03:21
22023	648.99407958984375	628	3	12	2019-01-06 02:55:05
22024	266.105743408203125	858	3	11	2018-12-25 06:27:48
22025	724.09588623046875	257	3	1	2018-11-30 15:48:38
22026	898.75006103515625	470	3	1	2018-10-07 03:29:02
22027	237.36822509765625	847	3	3	2018-10-17 05:12:28
22028	740.66748046875	506	3	3	2019-01-18 10:11:58
22029	822.85137939453125	763	3	3	2019-01-15 17:50:03
22030	929.5689697265625	305	3	3	2018-09-10 17:30:40
22031	86.9686431884765625	741	3	11	2019-03-19 05:19:48
22032	727.6331787109375	640	3	5	2019-02-09 00:59:43
22033	615.55242919921875	871	3	3	2019-03-07 05:30:40
22034	851.64654541015625	757	3	4	2019-02-21 08:22:47
22035	107.609626770019531	310	4	4	2018-11-09 01:03:48
22036	281.85699462890625	307	4	11	2018-11-03 21:59:13
22037	667.606201171875	855	4	12	2018-12-28 10:26:42
22038	25.1351394653320312	645	4	4	2018-10-26 01:35:35
22039	1005.83050537109375	51	4	5	2018-09-13 18:12:22
22040	51.4397850036621094	454	4	4	2019-03-07 08:33:39
22041	656.1639404296875	545	4	1	2019-03-03 15:49:25
22042	560.5185546875	512	4	3	2018-10-26 04:42:54
22043	513.2099609375	823	4	5	2019-01-26 06:52:10
22044	691.7344970703125	543	4	12	2019-03-14 21:48:41
22045	625.52569580078125	874	4	11	2018-12-04 09:14:55
22046	58.0974311828613281	768	4	11	2018-10-11 07:00:31
22047	831.06201171875	479	4	3	2019-01-20 00:50:37
22048	633.4466552734375	583	4	11	2019-01-25 18:16:31
22049	461.45013427734375	316	4	5	2019-02-13 22:51:22
22050	261.685211181640625	229	4	5	2018-09-19 11:53:47
22051	315.911651611328125	213	4	1	2019-03-05 02:13:53
22052	406.61090087890625	344	4	1	2018-10-03 15:47:19
22053	863.28955078125	108	4	5	2018-09-26 03:30:57
22054	316.2125244140625	188	4	4	2019-03-17 05:49:39
22055	410.61944580078125	939	4	12	2018-12-04 07:33:40
22056	100.668472290039062	173	4	4	2019-01-30 08:33:58
22057	760.8858642578125	734	4	11	2019-03-23 02:09:57
22058	864.0423583984375	78	4	5	2018-11-10 02:00:41
22059	491.38128662109375	365	4	3	2019-03-02 23:28:58
22060	552.101806640625	394	4	1	2019-02-21 12:40:37
22062	48.8299999999999983	61	24	4	2020-01-23 17:04:46
22063	46.3999999999999986	64	24	4	2020-01-23 17:04:47
22064	41.9399999999999977	65	24	4	2020-01-23 17:04:48
22065	49.2800000000000011	65	24	4	2020-01-23 17:04:50
22066	46.1799999999999997	64	24	4	2020-01-23 17:43:06
22067	48.1700000000000017	63	24	4	2020-01-23 17:43:07
22068	48.990000000000002	63	24	4	2020-01-23 17:43:08
22069	46.6499999999999986	63	24	4	2020-01-23 17:43:09
22070	45.3999999999999986	68	24	4	2020-01-23 17:43:10
22071	40.5600000000000023	69	24	4	2020-01-23 17:43:11
22072	48.6899999999999977	64	24	4	2020-01-23 17:43:12
22073	43.6599999999999966	63	24	4	2020-01-23 17:43:13
22074	49.5499999999999972	68	24	4	2020-01-23 17:43:14
22075	44.6799999999999997	68	24	4	2020-01-23 17:43:15
22076	48.759999999999998	69	24	4	2020-01-23 17:43:16
22077	48.0700000000000003	67	24	4	2020-01-23 17:43:17
22078	49.9399999999999977	64	24	4	2020-01-23 17:43:18
22079	47.6300000000000026	67	24	4	2020-01-23 17:43:19
22080	43.9399999999999977	61	24	4	2020-01-23 17:43:20
22081	44.2100000000000009	61	24	4	2020-01-23 17:43:21
22082	43.8200000000000003	67	24	4	2020-01-23 17:43:22
22083	46	63	24	4	2020-01-23 17:43:23
22084	44.0799999999999983	63	24	4	2020-01-23 17:43:26
22085	40.7800000000000011	62	24	4	2020-01-23 17:43:27
22086	42.2299999999999969	67	24	4	2020-01-23 17:43:28
22087	42.5	61	24	4	2020-01-23 17:43:29
22088	44.8900000000000006	61	24	4	2020-01-23 17:43:30
22089	47.1300000000000026	68	24	4	2020-01-23 17:43:31
22090	47.9200000000000017	67	24	4	2020-01-23 17:43:32
22091	49.1599999999999966	70	24	4	2020-01-23 17:43:33
22092	46.9099999999999966	60	24	4	2020-01-23 17:43:34
22093	47.7199999999999989	62	24	4	2020-01-23 17:43:35
22094	47.1300000000000026	62	24	4	2020-01-23 17:43:36
22095	49.5799999999999983	61	24	4	2020-01-23 17:43:37
22096	45.1000000000000014	66	24	4	2020-01-23 17:43:38
22097	45.7800000000000011	63	24	4	2020-01-23 17:43:39
22098	44.6799999999999997	68	24	4	2020-01-23 17:43:41
22099	43.9099999999999966	61	24	4	2020-01-23 17:43:42
22100	47.6700000000000017	66	24	4	2020-01-23 17:43:43
22101	48.740000000000002	60	24	4	2020-01-23 17:43:44
22102	45.75	70	24	4	2020-01-23 17:43:45
22103	49.0799999999999983	65	24	4	2020-01-23 17:43:46
22104	41.7999999999999972	64	24	4	2020-01-23 17:43:47
22105	40.4600000000000009	61	24	4	2020-01-23 17:43:49
22106	44.9500000000000028	61	24	4	2020-01-23 17:43:50
22107	49.1499999999999986	68	24	4	2020-01-23 17:43:51
22108	44.9500000000000028	62	24	4	2020-01-23 17:43:52
22109	43.1599999999999966	61	24	4	2020-01-23 17:43:53
22110	46.6300000000000026	64	24	4	2020-01-23 17:43:54
22111	47.1000000000000014	68	24	4	2020-01-23 17:43:55
22112	43.3800000000000026	64	24	4	2020-01-23 17:43:56
22113	45.6799999999999997	60	24	4	2020-01-23 17:43:57
22114	47.3200000000000003	62	24	4	2020-01-23 17:43:58
22115	43.759999999999998	65	24	4	2020-01-23 17:43:59
22116	47.6000000000000014	64	24	4	2020-01-23 17:44:00
22117	41.8800000000000026	67	24	4	2020-01-23 17:44:01
22118	41.2000000000000028	70	24	4	2020-01-23 17:44:02
22119	48.4699999999999989	63	24	4	2020-01-23 17:49:34
22120	48.3400000000000034	60	24	4	2020-01-23 17:49:36
22121	44.9600000000000009	68	24	4	2020-01-23 17:49:37
22122	44.3400000000000034	63	24	4	2020-01-23 17:49:38
22123	43.1300000000000026	70	24	4	2020-01-23 17:49:39
22124	40.1199999999999974	70	24	4	2020-01-23 17:49:40
22125	47.5700000000000003	67	24	4	2020-01-23 17:49:41
22126	40.1099999999999994	67	24	4	2020-01-23 17:49:42
22127	48.9500000000000028	63	24	4	2020-01-23 17:49:43
22128	42.6499999999999986	66	24	4	2020-01-23 17:49:44
22129	47.75	63	24	4	2020-01-23 17:49:45
22130	40.5399999999999991	64	24	4	2020-01-23 17:49:46
22131	47.5600000000000023	62	24	4	2020-01-23 17:49:47
22132	40.490000000000002	69	24	4	2020-01-23 17:49:48
22133	43.6499999999999986	69	24	4	2020-01-23 17:49:49
22134	48.9799999999999969	70	24	4	2020-01-23 17:49:50
22135	48.4600000000000009	64	24	4	2020-01-23 17:49:51
22136	49.0200000000000031	66	24	4	2020-01-23 17:49:52
22137	43.1099999999999994	66	24	4	2020-01-23 17:49:53
22138	45.1300000000000026	68	24	4	2020-01-23 17:49:54
22139	43.9799999999999969	67	24	4	2020-01-23 17:49:55
22140	41.7800000000000011	67	24	4	2020-01-23 17:49:56
22141	41.1199999999999974	65	24	4	2020-01-23 17:49:57
22142	49.5799999999999983	70	24	4	2020-01-23 17:49:58
22143	46.7800000000000011	60	24	4	2020-01-23 17:51:11
22144	42.0499999999999972	64	24	4	2020-01-23 17:51:12
22145	47.9799999999999969	68	24	4	2020-01-23 17:51:13
22146	42.1099999999999994	70	24	4	2020-01-23 17:51:14
22147	44.7700000000000031	65	24	4	2020-01-23 17:51:16
22148	44.4399999999999977	61	24	4	2020-01-23 17:51:17
22149	48.2000000000000028	63	24	4	2020-01-23 17:51:18
22150	46.240000000000002	61	24	4	2020-01-23 17:51:19
22151	40.7199999999999989	63	24	4	2020-01-23 17:51:20
22152	46.6499999999999986	63	24	4	2020-01-23 17:51:21
22153	40.509999999999998	63	24	4	2020-01-23 17:51:22
22154	43.5900000000000034	60	24	4	2020-01-23 17:51:23
22155	46.6899999999999977	60	24	4	2020-01-23 17:51:24
22156	42.0700000000000003	60	24	4	2020-01-23 17:51:25
22157	49.4299999999999997	61	24	4	2020-01-23 17:51:26
22158	43.0900000000000034	61	24	4	2020-01-23 17:51:27
22159	43.4600000000000009	62	24	4	2020-01-23 17:51:28
22160	44.3400000000000034	62	24	4	2020-01-23 17:51:29
22161	45.7100000000000009	64	24	4	2020-01-23 17:51:30
22162	46.5900000000000034	60	24	4	2020-01-23 17:51:32
22163	44.0900000000000034	70	24	4	2020-01-23 17:51:33
22164	43.1099999999999994	70	24	4	2020-01-23 17:51:34
22165	43.8299999999999983	68	24	4	2020-01-23 17:51:35
22166	49.990000000000002	61	24	4	2020-01-23 17:54:03
22167	49.1499999999999986	63	24	4	2020-01-23 17:54:04
22168	47.4299999999999997	69	24	4	2020-01-23 17:54:05
22169	47.25	64	24	4	2020-01-23 17:54:06
22170	45.990000000000002	66	24	4	2020-01-23 17:54:07
22171	43.3599999999999994	60	24	4	2020-01-23 17:54:08
22172	47.8400000000000034	65	24	4	2020-01-23 17:54:09
22173	47.9600000000000009	62	24	4	2020-01-23 17:54:10
22174	48.2999999999999972	61	24	4	2020-01-23 17:54:11
22175	47.8900000000000006	68	24	4	2020-01-23 17:54:12
22176	45.5300000000000011	60	24	4	2020-01-23 17:54:13
22177	46.259999999999998	62	24	4	2020-01-23 17:54:14
22178	48.3900000000000006	69	24	4	2020-01-23 17:54:15
22179	49.3800000000000026	68	24	4	2020-01-23 17:54:16
22180	40.8500000000000014	65	24	4	2020-01-23 17:54:18
22181	49.1799999999999997	64	24	4	2020-01-23 17:56:21
22182	43.9299999999999997	68	24	4	2020-01-23 17:56:22
22183	43.7100000000000009	62	24	4	2020-01-23 17:56:23
22184	43.9699999999999989	70	24	4	2020-01-23 17:56:24
22185	48.7000000000000028	70	24	4	2020-01-23 17:56:25
22186	47.0700000000000003	64	24	4	2020-01-23 17:56:26
22187	43.7700000000000031	69	24	4	2020-01-23 17:56:27
22188	46.0300000000000011	62	24	4	2020-01-23 17:56:28
22189	46.25	65	24	4	2020-01-23 17:56:29
22190	48.4299999999999997	67	24	4	2020-01-23 17:56:30
22191	45.9799999999999969	62	24	4	2020-01-23 17:56:31
22192	43.2199999999999989	60	24	4	2020-01-23 17:56:32
22193	42.3100000000000023	69	24	4	2020-01-23 17:56:33
22194	41.0799999999999983	63	24	4	2020-01-23 17:56:34
22195	45.6899999999999977	70	24	4	2020-01-23 17:56:35
22196	43.7999999999999972	60	24	4	2020-01-23 17:56:36
22197	41.4099999999999966	67	24	4	2020-01-23 17:56:37
22198	49.5700000000000003	62	24	4	2020-01-23 17:56:38
22199	49.2800000000000011	62	24	4	2020-01-23 17:56:39
22200	49.9299999999999997	63	24	4	2020-01-23 17:56:41
22201	47.8200000000000003	64	24	4	2020-01-23 17:56:42
22202	48.3100000000000023	65	24	4	2020-01-23 17:56:43
22203	42.7299999999999969	67	24	4	2020-01-23 17:56:44
22204	40.6899999999999977	60	24	4	2020-01-23 17:56:45
22205	42.8999999999999986	65	24	4	2020-01-23 17:56:46
22206	44.5700000000000003	66	24	4	2020-01-23 17:56:47
22207	42.7199999999999989	62	24	4	2020-01-23 17:56:48
22208	47.9399999999999977	65	24	4	2020-01-23 17:56:49
22209	49.1899999999999977	62	24	4	2020-01-23 17:56:50
22210	49.25	60	24	4	2020-01-23 17:56:51
22211	44.740000000000002	63	24	4	2020-01-23 17:56:52
22212	43	67	24	4	2020-01-23 17:56:53
22213	44.740000000000002	62	24	4	2020-01-23 17:56:54
22214	45.9699999999999989	65	24	4	2020-01-23 17:56:55
22215	41.1799999999999997	69	24	4	2020-01-23 17:56:56
22216	42.4099999999999966	62	24	4	2020-01-23 17:56:57
22217	43.1499999999999986	62	24	4	2020-01-23 17:56:58
22218	48.75	65	24	4	2020-01-23 17:56:59
22219	42.7999999999999972	66	24	4	2020-01-23 17:57:00
22220	40.8699999999999974	70	24	4	2020-01-23 17:57:02
22221	44.759999999999998	69	24	4	2020-01-23 17:57:03
22222	42.1400000000000006	65	24	4	2020-01-23 17:57:04
22223	45	70	24	4	2020-01-23 17:57:05
22224	48.1499999999999986	67	24	4	2020-01-23 17:57:06
22225	48.9200000000000017	66	24	4	2020-01-23 17:57:07
22226	47.0700000000000003	66	24	4	2020-01-23 17:57:08
22227	45.0600000000000023	64	24	4	2020-01-23 17:57:09
22228	40.9200000000000017	64	24	4	2020-01-23 17:57:10
22229	47.1400000000000006	63	24	4	2020-01-23 17:57:11
22230	49.9799999999999969	67	24	4	2020-01-23 17:57:12
22231	44.4799999999999969	66	24	4	2020-01-23 17:57:13
22232	41.7999999999999972	63	24	4	2020-01-23 17:57:14
22233	47.3999999999999986	60	24	4	2020-01-23 17:57:15
22234	41.7000000000000028	69	24	4	2020-01-23 17:57:16
22235	45.9099999999999966	67	24	4	2020-01-23 17:57:17
22236	43.8299999999999983	61	24	4	2020-01-23 17:57:18
22237	42.8100000000000023	68	24	4	2020-01-23 17:57:19
22238	40.0499999999999972	64	24	4	2020-01-23 17:57:20
22239	43.759999999999998	61	24	4	2020-01-23 17:57:21
22240	47.3299999999999983	70	24	4	2020-01-23 17:57:22
22241	41.6599999999999966	66	24	4	2020-01-23 17:57:23
22242	41.9299999999999997	61	24	4	2020-01-23 17:57:24
22243	41	65	24	4	2020-01-23 17:57:25
22244	44.1899999999999977	62	24	4	2020-01-23 17:57:27
22245	47.7899999999999991	69	24	4	2020-01-23 17:57:28
22246	44.009999999999998	61	24	4	2020-01-23 17:57:29
22247	48.1199999999999974	61	24	4	2020-01-23 17:57:30
22248	46.6199999999999974	60	24	4	2020-01-23 17:57:31
22249	41.8200000000000003	63	24	4	2020-01-23 17:57:32
22250	45.3900000000000006	60	24	4	2020-01-23 17:57:33
22251	44.0900000000000034	66	24	4	2020-01-23 17:57:34
22252	41.8100000000000023	62	24	4	2020-01-23 17:57:35
22253	40.6899999999999977	69	24	4	2020-01-23 17:57:36
22254	49.3800000000000026	68	24	4	2020-01-23 17:57:37
22255	49.7999999999999972	69	24	4	2020-01-23 17:57:38
22256	45.9099999999999966	70	24	4	2020-01-23 17:57:39
22257	40.6599999999999966	68	24	4	2020-01-23 17:57:40
22258	41.6199999999999974	64	24	4	2020-01-23 17:57:41
22259	48.0300000000000011	66	24	4	2020-01-23 17:57:42
22260	43.3699999999999974	69	24	4	2020-01-23 17:57:43
22261	48.1599999999999966	64	24	4	2020-01-23 17:57:44
22262	42.9500000000000028	63	24	4	2020-01-23 17:57:45
22263	43.7199999999999989	60	24	4	2020-01-23 17:57:47
22264	40.5900000000000034	66	24	4	2020-01-23 17:57:48
22265	47.1700000000000017	62	24	4	2020-01-23 17:57:49
22266	45.5499999999999972	70	24	4	2020-01-23 17:57:50
22267	47.0900000000000034	64	24	4	2020-01-23 17:57:51
22268	45	64	24	4	2020-01-23 17:57:52
22269	49.5300000000000011	66	24	4	2020-01-23 17:57:53
22270	48.7100000000000009	64	24	4	2020-01-23 17:57:54
22271	43.7100000000000009	62	24	4	2020-01-23 17:57:55
22272	47.6000000000000014	61	24	4	2020-01-23 18:05:09
22273	49.0900000000000034	60	24	4	2020-01-23 18:05:10
22274	41.5700000000000003	65	24	4	2020-01-23 18:05:11
22275	43.75	65	24	4	2020-01-23 18:05:12
22276	44.9099999999999966	64	24	4	2020-01-23 18:05:13
22277	46.5600000000000023	62	24	4	2020-01-23 18:05:14
22278	49.9799999999999969	69	24	4	2020-01-23 18:05:15
22279	42.0300000000000011	68	24	4	2020-01-23 18:05:16
22280	41.2199999999999989	63	24	4	2020-01-23 18:05:17
22281	40.1000000000000014	60	24	4	2020-01-23 18:05:18
22282	45.6599999999999966	69	24	4	2020-01-23 18:05:19
22283	44.3500000000000014	62	24	4	2020-01-23 18:05:20
22284	45.8800000000000026	69	24	4	2020-01-23 18:05:21
22285	46.0799999999999983	63	24	4	2020-01-23 18:05:22
22286	41.5799999999999983	62	24	4	2020-01-23 18:05:23
22287	46.4299999999999997	60	24	4	2020-01-23 18:05:24
22288	40.7199999999999989	63	24	4	2020-01-23 18:05:25
22289	44.0200000000000031	66	24	4	2020-01-23 18:05:26
22290	40.8699999999999974	63	24	4	2020-01-23 18:05:27
22291	49.9600000000000009	63	24	4	2020-01-23 18:05:28
22292	47.8500000000000014	63	24	4	2020-01-23 18:05:29
22293	47.4600000000000009	64	24	4	2020-01-23 18:05:30
22294	40.9600000000000009	61	24	4	2020-01-23 18:05:32
22295	48.9200000000000017	64	28	5	2020-01-24 09:28:16
22296	44.5600000000000023	67	28	5	2020-01-24 09:28:17
22297	42.4600000000000009	70	28	5	2020-01-24 09:28:18
22298	44.9200000000000017	61	28	5	2020-01-24 09:28:19
22299	47.0900000000000034	67	28	5	2020-01-24 09:28:20
22300	43.990000000000002	68	28	5	2020-01-24 09:28:21
22301	40.1000000000000014	63	28	5	2020-01-24 09:28:22
22302	44.2899999999999991	61	28	5	2020-01-24 09:28:23
22303	44.1000000000000014	68	28	5	2020-01-24 09:28:24
22304	48.1400000000000006	68	28	5	2020-01-24 09:28:25
22305	48.0799999999999983	64	28	5	2020-01-24 09:28:26
22306	41.25	62	28	5	2020-01-24 09:28:27
22307	45.7199999999999989	70	28	5	2020-01-24 09:28:28
22308	41.2899999999999991	65	28	5	2020-01-24 09:28:29
22309	48.009999999999998	65	28	5	2020-01-24 09:28:30
22310	44.6400000000000006	60	28	5	2020-01-24 09:28:31
22311	41.7700000000000031	64	28	5	2020-01-24 09:28:32
22312	49.2800000000000011	61	28	5	2020-01-24 09:28:33
22313	49.8299999999999983	68	28	5	2020-01-24 09:28:34
22314	46.6400000000000006	63	28	5	2020-01-24 09:28:35
22315	41.0399999999999991	62	28	5	2020-01-24 09:28:37
22316	44.3100000000000023	65	28	5	2020-01-24 09:28:38
22317	44.0900000000000034	68	28	5	2020-01-24 09:28:39
22318	47.1799999999999997	60	28	5	2020-01-24 09:28:40
22319	48.4799999999999969	70	28	5	2020-01-24 09:28:41
22320	47.5300000000000011	70	28	5	2020-01-24 09:28:42
22321	46.5	67	28	5	2020-01-24 09:28:43
22322	46.4399999999999977	65	28	5	2020-01-24 09:28:44
22323	47.6099999999999994	64	28	5	2020-01-24 09:28:45
22324	42.0600000000000023	69	28	5	2020-01-24 09:28:46
22325	44.0600000000000023	68	28	5	2020-01-24 09:28:47
22326	49.7000000000000028	61	28	5	2020-01-24 09:28:48
22327	47.9799999999999969	61	28	5	2020-01-24 09:28:49
22328	41.8100000000000023	69	28	5	2020-01-24 09:28:50
22329	48.0300000000000011	61	28	5	2020-01-24 09:28:51
22330	46.9699999999999989	64	28	5	2020-01-24 09:28:52
22331	47.0700000000000003	60	28	5	2020-01-24 09:28:53
22332	45.9200000000000017	67	28	5	2020-01-24 09:28:54
22333	47.1099999999999994	68	28	5	2020-01-24 09:28:55
22334	48.990000000000002	60	28	5	2020-01-24 09:28:56
22335	46.1499999999999986	65	28	5	2020-01-24 09:28:57
22336	42.5300000000000011	69	28	5	2020-01-24 09:28:58
22337	49.6199999999999974	65	28	5	2020-01-24 09:28:59
22338	44.5900000000000034	60	28	5	2020-01-24 09:29:00
22339	43.2100000000000009	62	28	5	2020-01-24 09:29:01
22340	44.509999999999998	67	28	5	2020-01-24 09:29:03
22341	40.759999999999998	65	28	5	2020-01-24 09:29:04
22342	45.7000000000000028	68	28	5	2020-01-24 09:29:05
22343	42.1300000000000026	67	28	5	2020-01-24 09:29:06
22344	45.740000000000002	67	28	5	2020-01-24 09:29:07
22345	43.6000000000000014	68	28	5	2020-01-24 09:29:08
22346	44.9399999999999977	60	28	5	2020-01-24 09:29:09
22347	40.0900000000000034	66	28	5	2020-01-24 09:29:10
22348	45.2899999999999991	63	28	5	2020-01-24 09:29:11
22349	44.3299999999999983	63	28	5	2020-01-24 09:29:12
22350	48.7299999999999969	69	28	5	2020-01-24 09:29:13
22351	44.2000000000000028	62	28	5	2020-01-24 09:29:14
22352	40.740000000000002	65	28	5	2020-01-24 09:29:15
22353	49.2899999999999991	65	28	5	2020-01-24 09:29:16
22354	41.9500000000000028	68	28	5	2020-01-24 09:29:17
22355	46.990000000000002	66	28	5	2020-01-24 09:29:18
22356	47.2999999999999972	68	28	5	2020-01-24 09:46:13
22357	40.2199999999999989	67	28	5	2020-01-24 09:46:14
22358	47.009999999999998	66	28	5	2020-01-24 09:46:15
22359	49.1700000000000017	66	28	5	2020-01-24 09:46:16
22360	46.8800000000000026	65	28	5	2020-01-24 09:46:17
22361	40.1899999999999977	66	28	5	2020-01-24 09:46:18
22362	42.5499999999999972	64	28	5	2020-01-24 09:46:19
22363	49.9299999999999997	64	28	5	2020-01-24 09:46:20
22364	43.9099999999999966	60	28	5	2020-01-24 09:46:21
22365	49.6599999999999966	60	28	5	2020-01-24 09:46:22
22366	43.5799999999999983	63	28	5	2020-01-24 09:46:23
22367	44.8900000000000006	68	28	5	2020-01-24 09:46:24
22368	47.1799999999999997	69	28	5	2020-01-24 09:46:25
22369	43.1099999999999994	61	28	5	2020-01-24 09:46:27
22370	40.8400000000000034	69	28	5	2020-01-24 09:46:28
22371	43.7999999999999972	70	28	5	2020-01-24 09:46:29
22372	46.5799999999999983	60	28	5	2020-01-24 09:46:30
22373	42.2000000000000028	67	28	5	2020-01-24 09:46:31
22374	43.6000000000000014	68	28	5	2020-01-24 09:46:32
22375	48.759999999999998	70	28	5	2020-01-24 09:46:33
22376	45.0499999999999972	60	28	5	2020-01-24 09:46:34
22377	43.3599999999999994	65	28	5	2020-01-24 09:46:35
22378	44.4399999999999977	69	28	5	2020-01-24 09:46:36
22379	44.4099999999999966	64	28	5	2020-01-24 09:46:37
22380	48.6499999999999986	67	28	5	2020-01-24 09:46:38
22381	46.0200000000000031	61	28	5	2020-01-24 09:46:39
22382	41.4799999999999969	61	28	5	2020-01-24 09:46:40
22383	48.4200000000000017	67	28	5	2020-01-24 09:46:41
22384	47.9500000000000028	67	28	5	2020-01-24 09:46:42
22385	45.5200000000000031	66	28	5	2020-01-24 09:46:43
22386	47.990000000000002	60	28	5	2020-01-24 09:46:44
22387	46.9399999999999977	62	28	5	2020-01-24 09:46:45
22388	43.3299999999999983	63	28	5	2020-01-24 09:46:46
22389	43.0700000000000003	67	28	5	2020-01-24 09:46:47
22390	44.009999999999998	61	28	5	2020-01-24 09:46:48
22391	50	63	28	5	2020-01-24 09:46:49
22392	43.2999999999999972	62	28	5	2020-01-24 09:46:50
22393	40.6599999999999966	67	28	5	2020-01-24 09:46:51
22394	49.4099999999999966	63	28	5	2020-01-24 09:46:53
22395	45.259999999999998	62	28	5	2020-01-24 09:46:54
22396	41.509999999999998	62	28	5	2020-01-24 09:46:55
22397	43.5700000000000003	60	28	5	2020-01-24 09:46:56
22398	48.8400000000000034	67	28	5	2020-01-24 09:46:57
22399	43.9699999999999989	70	28	5	2020-01-24 09:46:58
22400	42.2299999999999969	63	28	5	2020-01-24 09:46:59
22401	47.25	69	28	5	2020-01-24 09:47:00
22402	40.1799999999999997	69	28	5	2020-01-24 09:47:01
22403	47.9600000000000009	65	28	5	2020-01-24 09:47:02
22404	46.6499999999999986	64	28	5	2020-01-24 09:47:03
22405	40.9500000000000028	64	28	5	2020-01-24 09:47:04
22406	46.6599999999999966	68	28	5	2020-01-24 09:47:05
22407	40.3400000000000034	65	28	5	2020-01-24 09:47:06
22408	45.3800000000000026	63	28	5	2020-01-24 09:47:07
22409	45.9299999999999997	69	28	5	2020-01-24 09:47:08
22410	43.8900000000000006	67	28	5	2020-01-24 09:47:09
22411	42.5499999999999972	67	28	5	2020-01-24 09:47:10
22412	42.0499999999999972	64	28	5	2020-01-24 09:47:11
22413	48.9200000000000017	64	28	5	2020-01-24 09:47:12
22414	46.9099999999999966	63	28	5	2020-01-24 09:47:13
22415	41.5799999999999983	60	28	5	2020-01-24 09:47:14
22416	42.7199999999999989	63	28	5	2020-01-24 09:47:15
22417	43.1700000000000017	64	28	5	2020-01-24 09:47:16
22418	46.6700000000000017	70	28	5	2020-01-24 09:47:17
22419	48.8400000000000034	69	28	5	2020-01-24 09:47:18
22420	41.7100000000000009	67	28	5	2020-01-24 09:47:20
22421	45.1300000000000026	70	28	5	2020-01-24 09:47:21
22422	45.6400000000000006	68	28	5	2020-01-24 09:47:22
22423	42.8999999999999986	63	28	5	2020-01-24 09:47:23
22424	49.6099999999999994	70	28	5	2020-01-24 09:47:24
22425	42.7700000000000031	68	28	5	2020-01-24 09:47:25
22426	46.4699999999999989	60	28	5	2020-01-24 09:47:26
22427	47.4299999999999997	61	28	5	2020-01-24 09:47:27
22428	49.4500000000000028	66	28	5	2020-01-24 09:47:28
22429	41.0700000000000003	67	28	5	2020-01-24 09:47:29
22430	40.2700000000000031	61	28	5	2020-01-24 09:47:30
22431	40.2100000000000009	67	28	5	2020-01-24 09:47:31
22432	49.8999999999999986	61	28	5	2020-01-24 09:47:32
22433	49.4799999999999969	66	28	5	2020-01-24 09:47:33
22434	40.6799999999999997	60	28	5	2020-01-24 09:47:34
22435	47.5499999999999972	61	28	5	2020-01-24 09:47:35
22436	48.1899999999999977	63	28	5	2020-01-24 09:47:36
22437	47.5399999999999991	63	28	5	2020-01-24 09:47:37
22438	45.6499999999999986	70	28	5	2020-01-24 09:47:38
\.


--
-- TOC entry 2502 (class 0 OID 104385)
-- Dependencies: 214
-- Data for Name: lembrete; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.lembrete (id, nome, descricao, paciente_id, alerta, data_registo, log_utilizador_id, ativo) FROM stdin;
6	Alerta 1	\N	20	2020-01-29 12:34:00	2020-01-23 21:28:32	2	t
8	Alerta 1	\N	21	2020-01-29 11:23:00	2020-01-23 21:35:17	2	t
10	Alerta 1	\N	21	2020-01-29 11:23:00	2020-01-23 21:36:09	2	t
12	Alerta 1	\N	21	2020-01-29 03:45:00	2020-01-23 21:42:25	2	t
14	Alerta 1	\N	21	2020-01-30 03:23:00	2020-01-23 21:43:25	2	t
16	Alerta 2	\N	28	2020-01-31 12:36:00	2020-01-23 21:45:19	2	t
18	Alerta 3	\N	28	2020-02-07 12:22:00	2020-01-23 22:02:28	2	t
20	Alerta 4	\N	28	2020-01-30 09:23:00	2020-01-23 22:03:35	2	t
21	Alerta 4	\N	28	2020-01-30 09:23:00	2020-01-23 22:03:40	2	t
22	Alerta 4	\N	28	2020-01-30 09:23:00	2020-01-23 22:04:17	2	t
\.


--
-- TOC entry 2488 (class 0 OID 104314)
-- Dependencies: 200
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.logs (id, tabela, operacao, utilizador_id, novo_registo, antigo_registo, data_registo) FROM stdin;
4	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:44","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":null,"data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:21:44
5	utilizador	UPDATE	2	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":null,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":null,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":null,"data_registo":null,"data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:21:55
6	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$IDjMagvs8R14KxESm0BtfOClZCwuTxcDj1.due5ucv3WaAGKDVPxa","contacto":null,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$IDjMagvs8R14KxESm0BtfOClZCwuTxcDj1.due5ucv3WaAGKDVPxa","contacto":null,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":null,"data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:22:01
7	utilizador_tipo	UPDATE	2	{"id":1,"utilizador_id":1,"tipo_id":1,"data_registo":"2020-01-12T02:23:01","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"utilizador_id":1,"tipo_id":1,"data_registo":null,"data_update":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:23:01
8	utilizador_tipo	UPDATE	2	{"id":2,"utilizador_id":1,"tipo_id":2,"data_registo":"2020-01-12T02:23:07","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":2,"utilizador_id":1,"tipo_id":2,"data_registo":null,"data_update":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:23:07
9	utilizador_tipo	UPDATE	2	{"id":3,"utilizador_id":1,"tipo_id":3,"data_registo":"2020-01-12T02:23:12","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"utilizador_id":1,"tipo_id":3,"data_registo":null,"data_update":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:23:12
10	utilizador_tipo	UPDATE	2	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":"2020-01-12T02:23:15","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":null,"data_update":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:23:15
11	utilizador_tipo	UPDATE	2	{"id":5,"utilizador_id":3,"tipo_id":3,"data_registo":"2020-01-12T02:23:19","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":5,"utilizador_id":3,"tipo_id":3,"data_registo":null,"data_update":null,"ativo":true,"log_utilizador_id":null}	2020-01-12 02:23:19
12	unidade_saude	INSERT	1	{"id":4,"nome":"T7agox","morada":"Rua esquerda","telefone":918291829,"email":"t7agox@ua.pt","data_registo":"2020-01-12T02:27:02","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 02:27:02
13	unidade_saude	INSERT	1	{"id":5,"nome":"O meu pai tem bigode","morada":"Rua direita","telefone":192839291,"email":"pai@hotmail.com","data_registo":"2020-01-12T02:28:13","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 02:28:13
14	unidade_saude	INSERT	1	{"id":6,"nome":"Fiz amor","morada":"Rua 123","telefone":918291029,"email":"fiz_amor@hotmail.com","data_registo":"2020-01-12T02:29:08","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 02:29:08
15	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:44","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 02:29:37
16	unidade_saude	UPDATE	1	{"id":6,"nome":"Fiz amor","morada":"Rua 456","telefone":918291029,"email":"fiz_amor@hotmail.com","data_registo":"2020-01-12T02:29:08","data_update":"2020-01-12T02:29:55","ativo":true,"log_utilizador_id":1}	{"id":6,"nome":"Fiz amor","morada":"Rua 123","telefone":918291029,"email":"fiz_amor@hotmail.com","data_registo":"2020-01-12T02:29:08","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 02:29:55
17	unidade_saude	INSERT	1	{"id":7,"nome":"O Manzarras","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 02:31:45
18	unidade_saude	UPDATE	1	{"id":7,"nome":"O Manzarras","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":"2020-01-12T02:32:08","ativo":false,"log_utilizador_id":1}	{"id":7,"nome":"O Manzarras","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 02:32:08
19	unidade_saude	INSERT	1	{"id":8,"nome":"Pim Pam Pum","morada":"Rua da Bosta","telefone":918291918,"email":"pim@ua.pt","data_registo":"2020-01-12T02:34:12","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 02:34:12
20	utilizador	INSERT	2	{"id":4,"nome":"Graça","password":"466","contacto":917283827,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:09:49","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:09:49
21	utilizador_unidade_saude	INSERT	2	{"id":1,"utilizador_id":4,"unidade_saude_id":6,"data_registo":"2020-01-12T03:09:49","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:09:49
22	utilizador_unidade_saude	INSERT	2	{"id":2,"utilizador_id":4,"unidade_saude_id":5,"data_registo":"2020-01-12T03:09:49","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:09:49
23	utilizador_tipo	INSERT	2	{"id":6,"utilizador_id":4,"tipo_id":2,"data_registo":"2020-01-12T03:09:49","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:09:49
24	utilizador_tipo	INSERT	2	{"id":7,"utilizador_id":4,"tipo_id":1,"data_registo":"2020-01-12T03:09:49","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:09:49
25	utilizador	INSERT	1	{"id":5,"nome":"Graça","password":"456","contacto":917283827,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:16:03","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:16:03
26	utilizador_unidade_saude	INSERT	1	{"id":3,"utilizador_id":5,"unidade_saude_id":5,"data_registo":"2020-01-12T03:16:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:16:03
27	utilizador_unidade_saude	INSERT	1	{"id":4,"utilizador_id":5,"unidade_saude_id":8,"data_registo":"2020-01-12T03:16:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:16:03
28	utilizador_tipo	INSERT	1	{"id":8,"utilizador_id":5,"tipo_id":2,"data_registo":"2020-01-12T03:16:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:16:03
29	utilizador_tipo	INSERT	1	{"id":9,"utilizador_id":5,"tipo_id":3,"data_registo":"2020-01-12T03:16:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:16:03
30	utilizador	INSERT	1	{"id":6,"nome":"Action Man","password":"4567","contacto":917283825,"email":"action@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:19:06","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:19:06
31	utilizador_unidade_saude	INSERT	1	{"id":5,"utilizador_id":6,"unidade_saude_id":6,"data_registo":"2020-01-12T03:19:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:19:06
32	utilizador_unidade_saude	INSERT	1	{"id":6,"utilizador_id":6,"unidade_saude_id":5,"data_registo":"2020-01-12T03:19:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:19:06
33	utilizador_tipo	INSERT	1	{"id":10,"utilizador_id":6,"tipo_id":2,"data_registo":"2020-01-12T03:19:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:19:06
34	utilizador_tipo	INSERT	1	{"id":11,"utilizador_id":6,"tipo_id":3,"data_registo":"2020-01-12T03:19:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:19:06
35	utilizador	INSERT	1	{"id":7,"nome":"Graça","password":"$2y$10$eNAkF5AQvKqAJNINaIULl.j2GFaX2qIB9EuHa7iO3f7rJRHNX1N8q","contacto":917283822,"email":"pimmm@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:21:27","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
36	utilizador_unidade_saude	INSERT	1	{"id":7,"utilizador_id":7,"unidade_saude_id":5,"data_registo":"2020-01-12T03:21:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
37	utilizador_unidade_saude	INSERT	1	{"id":8,"utilizador_id":7,"unidade_saude_id":8,"data_registo":"2020-01-12T03:21:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
38	utilizador_unidade_saude	INSERT	1	{"id":9,"utilizador_id":7,"unidade_saude_id":4,"data_registo":"2020-01-12T03:21:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
39	utilizador_tipo	INSERT	1	{"id":12,"utilizador_id":7,"tipo_id":2,"data_registo":"2020-01-12T03:21:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
40	utilizador_tipo	INSERT	1	{"id":13,"utilizador_id":7,"tipo_id":3,"data_registo":"2020-01-12T03:21:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:21:27
41	utilizador_unidade_saude	INSERT	2	{"id":13,"utilizador_id":1,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:24:17
42	utilizador_unidade_saude	INSERT	4	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":null,"ativo":true,"log_utilizador_id":4}	\N	2020-01-12 03:24:31
43	utilizador_unidade_saude	UPDATE	2	{"id":13,"utilizador_id":2,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":13,"utilizador_id":1,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 03:24:37
44	utilizador_unidade_saude	INSERT	2	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:24:52
45	utilizador	INSERT	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:25:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:25:35
46	utilizador_unidade_saude	INSERT	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:25:35
47	utilizador_unidade_saude	INSERT	1	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:25:35
48	utilizador_tipo	INSERT	1	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:25:35
49	utilizador_tipo	INSERT	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:25:35
50	utilizador	UPDATE	2	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":null,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 03:32:53
51	utilizador	INSERT	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
52	utilizador_unidade_saude	INSERT	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
53	utilizador_unidade_saude	INSERT	1	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
54	utilizador_unidade_saude	INSERT	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
55	utilizador_tipo	INSERT	1	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
56	utilizador_tipo	INSERT	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:33:35
57	utilizador	INSERT	1	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:16
58	utilizador_unidade_saude	INSERT	1	{"id":22,"utilizador_id":10,"unidade_saude_id":6,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:16
59	utilizador_unidade_saude	INSERT	1	{"id":23,"utilizador_id":10,"unidade_saude_id":5,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:16
60	utilizador_tipo	INSERT	1	{"id":18,"utilizador_id":10,"tipo_id":2,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:16
61	utilizador_tipo	INSERT	1	{"id":19,"utilizador_id":10,"tipo_id":1,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:16
62	utilizador	INSERT	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:58
63	utilizador_unidade_saude	INSERT	1	{"id":24,"utilizador_id":11,"unidade_saude_id":4,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:58
64	utilizador_tipo	INSERT	1	{"id":20,"utilizador_id":11,"tipo_id":2,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:58
65	utilizador_tipo	INSERT	1	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:34:58
66	utilizador	UPDATE	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:37:48","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:37:48
67	utilizador	UPDATE	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:38:00","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:37:48","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:38:00
68	utilizador_unidade_saude	INSERT	2	{"id":26,"utilizador_id":11,"unidade_saude_id":6,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:56:37
69	utilizador_unidade_saude	INSERT	2	{"id":27,"utilizador_id":11,"unidade_saude_id":5,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:56:37
70	utilizador_tipo	INSERT	2	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 03:56:37
71	utilizador	UPDATE	2	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:56:37","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:38:00","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:56:37
72	utilizador_unidade_saude	UPDATE	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:34","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:34
73	utilizador_unidade_saude	INSERT	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:57:34
74	utilizador_tipo	INSERT	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:57:34
75	utilizador	UPDATE	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:34","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:25:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:34
76	utilizador_unidade_saude	UPDATE	1	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:57
77	utilizador_unidade_saude	UPDATE	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","ativo":true,"log_utilizador_id":1}	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:34","ativo":false,"log_utilizador_id":1}	2020-01-12 03:57:57
78	utilizador_unidade_saude	UPDATE	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:57
194	equipamentos	INSERT	4	{"id":1,"nome":"007","access_token":"erfrefergergerg","data_registo":"2020-01-12T04:54:42","data_update":null,"ativo":true,"log_utilizador_id":4}	\N	2020-01-12 04:54:42
79	utilizador_tipo	UPDATE	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:57
80	utilizador	UPDATE	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:34","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:57:57
81	utilizador_unidade_saude	UPDATE	1	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":"2020-01-12T03:58:16","ativo":false,"log_utilizador_id":1}	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-12 03:58:16
82	utilizador_unidade_saude	UPDATE	1	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":"2020-01-12T03:58:16","ativo":false,"log_utilizador_id":1}	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 03:58:16
83	utilizador_unidade_saude	INSERT	1	{"id":29,"utilizador_id":2,"unidade_saude_id":8,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:58:16
84	utilizador_tipo	INSERT	1	{"id":24,"utilizador_id":2,"tipo_id":1,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:58:16
85	utilizador_tipo	INSERT	1	{"id":25,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 03:58:16
86	utilizador	UPDATE	1	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T02:21:55","data_update":"2020-01-12T03:58:16","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:21:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 03:58:16
87	utilizador	UPDATE	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:58:54
88	utilizador_unidade_saude	UPDATE	1	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	2020-01-12 03:58:54
89	utilizador_unidade_saude	UPDATE	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:57:57","ativo":true,"log_utilizador_id":1}	2020-01-12 03:58:54
90	utilizador_unidade_saude	UPDATE	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	2020-01-12 03:58:54
91	utilizador_tipo	UPDATE	1	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:58:54
92	utilizador_tipo	UPDATE	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:58:54
93	utilizador_tipo	UPDATE	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:57:57","ativo":false,"log_utilizador_id":1}	2020-01-12 03:58:54
94	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:01
95	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:02
96	utilizador_unidade_saude	UPDATE	1	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:02
97	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:02
98	utilizador_tipo	UPDATE	1	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:02
99	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 03:59:02
100	utilizador	UPDATE	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T03:56:37","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:16:12
101	utilizador_unidade_saude	UPDATE	1	{"id":24,"utilizador_id":11,"unidade_saude_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":24,"utilizador_id":11,"unidade_saude_id":4,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:16:12
102	utilizador_unidade_saude	UPDATE	1	{"id":26,"utilizador_id":11,"unidade_saude_id":6,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":26,"utilizador_id":11,"unidade_saude_id":6,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:16:12
103	utilizador_unidade_saude	UPDATE	1	{"id":27,"utilizador_id":11,"unidade_saude_id":5,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":27,"utilizador_id":11,"unidade_saude_id":5,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:16:12
104	utilizador_tipo	UPDATE	1	{"id":20,"utilizador_id":11,"tipo_id":2,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":20,"utilizador_id":11,"tipo_id":2,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:16:12
105	utilizador_tipo	UPDATE	1	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:16:12
106	utilizador_tipo	UPDATE	1	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:16:12
107	utilizador	INSERT	1	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
108	utilizador_unidade_saude	INSERT	1	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
109	utilizador_unidade_saude	INSERT	1	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
110	utilizador_unidade_saude	INSERT	1	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
111	utilizador_tipo	INSERT	1	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
112	utilizador_tipo	INSERT	1	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
113	utilizador_tipo	INSERT	1	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 04:17:42
114	utilizador	UPDATE	1	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:17:51
115	utilizador_unidade_saude	UPDATE	1	{"id":22,"utilizador_id":10,"unidade_saude_id":6,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	{"id":22,"utilizador_id":10,"unidade_saude_id":6,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:17:51
116	utilizador_unidade_saude	UPDATE	1	{"id":23,"utilizador_id":10,"unidade_saude_id":5,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	{"id":23,"utilizador_id":10,"unidade_saude_id":5,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:17:51
117	utilizador_tipo	UPDATE	1	{"id":18,"utilizador_id":10,"tipo_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	{"id":18,"utilizador_id":10,"tipo_id":2,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:17:52
118	utilizador_tipo	UPDATE	1	{"id":19,"utilizador_id":10,"tipo_id":1,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":10,"tipo_id":1,"data_registo":"2020-01-12T03:34:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:17:52
138	utilizador_unidade_saude	UPDATE	1	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
119	utilizador	UPDATE	1	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T02:21:55","data_update":"2020-01-12T04:27:41","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T02:21:55","data_update":"2020-01-12T03:58:16","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:27:42
120	utilizador_unidade_saude	UPDATE	1	{"id":13,"utilizador_id":2,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":13,"utilizador_id":2,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:27:42
121	utilizador_unidade_saude	UPDATE	1	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":"2020-01-12T03:58:16","ativo":false,"log_utilizador_id":1}	2020-01-12 04:27:42
122	utilizador_unidade_saude	UPDATE	1	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":"2020-01-12T03:58:16","ativo":false,"log_utilizador_id":1}	2020-01-12 04:27:42
123	utilizador_unidade_saude	UPDATE	1	{"id":29,"utilizador_id":2,"unidade_saude_id":8,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":29,"utilizador_id":2,"unidade_saude_id":8,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:27:42
124	utilizador_tipo	UPDATE	1	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":"2020-01-12T02:23:15","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":"2020-01-12T02:23:15","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:27:42
125	utilizador_tipo	UPDATE	1	{"id":24,"utilizador_id":2,"tipo_id":1,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":24,"utilizador_id":2,"tipo_id":1,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:27:42
126	utilizador_tipo	UPDATE	1	{"id":25,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	{"id":25,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-12T03:58:16","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:27:42
127	utilizador	UPDATE	1	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
128	utilizador_unidade_saude	UPDATE	1	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
129	utilizador_unidade_saude	UPDATE	1	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
130	utilizador_unidade_saude	UPDATE	1	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
131	utilizador_tipo	UPDATE	1	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
132	utilizador_tipo	UPDATE	1	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
133	utilizador_tipo	UPDATE	1	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:33:43
134	utilizador_unidade_saude	UPDATE	1	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
135	utilizador_unidade_saude	UPDATE	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
136	utilizador_unidade_saude	UPDATE	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:53","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
137	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
139	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
140	utilizador_unidade_saude	UPDATE	1	{"id":24,"utilizador_id":11,"unidade_saude_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":24,"utilizador_id":11,"unidade_saude_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
141	utilizador_unidade_saude	UPDATE	1	{"id":26,"utilizador_id":11,"unidade_saude_id":6,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":26,"utilizador_id":11,"unidade_saude_id":6,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
142	utilizador_unidade_saude	UPDATE	1	{"id":27,"utilizador_id":11,"unidade_saude_id":5,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":27,"utilizador_id":11,"unidade_saude_id":5,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
143	utilizador_unidade_saude	UPDATE	1	{"id":22,"utilizador_id":10,"unidade_saude_id":6,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":true,"log_utilizador_id":1}	{"id":22,"utilizador_id":10,"unidade_saude_id":6,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
144	utilizador_unidade_saude	UPDATE	1	{"id":23,"utilizador_id":10,"unidade_saude_id":5,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":true,"log_utilizador_id":1}	{"id":23,"utilizador_id":10,"unidade_saude_id":5,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
145	utilizador_unidade_saude	UPDATE	1	{"id":13,"utilizador_id":2,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":13,"utilizador_id":2,"unidade_saude_id":4,"data_registo":"2020-01-12T03:24:17","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
146	utilizador_unidade_saude	UPDATE	1	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":15,"utilizador_id":2,"unidade_saude_id":5,"data_registo":"2020-01-12T03:24:31","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
147	utilizador_unidade_saude	UPDATE	1	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":16,"utilizador_id":2,"unidade_saude_id":6,"data_registo":"2020-01-12T03:24:52","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
148	utilizador_unidade_saude	UPDATE	1	{"id":29,"utilizador_id":2,"unidade_saude_id":8,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":29,"utilizador_id":2,"unidade_saude_id":8,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
149	utilizador_unidade_saude	UPDATE	1	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
150	utilizador_unidade_saude	UPDATE	1	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
151	utilizador_unidade_saude	UPDATE	1	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:26
152	utilizador_tipo	UPDATE	2	{"id":1,"utilizador_id":1,"tipo_id":1,"data_registo":"2020-01-12T02:23:01","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"utilizador_id":1,"tipo_id":1,"data_registo":"2020-01-12T02:23:01","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:35
153	utilizador_tipo	UPDATE	2	{"id":2,"utilizador_id":1,"tipo_id":2,"data_registo":"2020-01-12T02:23:07","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":2,"utilizador_id":1,"tipo_id":2,"data_registo":"2020-01-12T02:23:07","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:35
154	utilizador_tipo	UPDATE	2	{"id":3,"utilizador_id":1,"tipo_id":3,"data_registo":"2020-01-12T02:23:12","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"utilizador_id":1,"tipo_id":3,"data_registo":"2020-01-12T02:23:12","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:35
155	utilizador_tipo	UPDATE	2	{"id":5,"utilizador_id":3,"tipo_id":3,"data_registo":"2020-01-12T02:23:19","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":5,"utilizador_id":3,"tipo_id":3,"data_registo":"2020-01-12T02:23:19","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:35
156	utilizador_tipo	UPDATE	1	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
157	utilizador_tipo	UPDATE	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
158	utilizador_tipo	UPDATE	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:54","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
192	paciente	INSERT	6	{"id":3,"nome":"Pi Pi","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	\N	2020-01-12 04:53:34
159	utilizador_tipo	UPDATE	1	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
160	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
161	utilizador_tipo	UPDATE	1	{"id":20,"utilizador_id":11,"tipo_id":2,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":20,"utilizador_id":11,"tipo_id":2,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
162	utilizador_tipo	UPDATE	1	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
163	utilizador_tipo	UPDATE	1	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
164	utilizador_tipo	UPDATE	1	{"id":18,"utilizador_id":10,"tipo_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":true,"log_utilizador_id":1}	{"id":18,"utilizador_id":10,"tipo_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
165	utilizador_tipo	UPDATE	1	{"id":19,"utilizador_id":10,"tipo_id":1,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":true,"log_utilizador_id":1}	{"id":19,"utilizador_id":10,"tipo_id":1,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
166	utilizador_tipo	UPDATE	1	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":"2020-01-12T02:23:15","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":4,"utilizador_id":2,"tipo_id":2,"data_registo":"2020-01-12T02:23:15","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
167	utilizador_tipo	UPDATE	1	{"id":24,"utilizador_id":2,"tipo_id":1,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":24,"utilizador_id":2,"tipo_id":1,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
168	utilizador_tipo	UPDATE	1	{"id":25,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":true,"log_utilizador_id":1}	{"id":25,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-12T03:58:16","data_update":"2020-01-12T04:27:41","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
169	utilizador_tipo	UPDATE	1	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
170	utilizador_tipo	UPDATE	1	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
171	utilizador_tipo	UPDATE	1	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:35
172	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$IDjMagvs8R14KxESm0BtfOClZCwuTxcDj1.due5ucv3WaAGKDVPxa","contacto":null,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$IDjMagvs8R14KxESm0BtfOClZCwuTxcDj1.due5ucv3WaAGKDVPxa","contacto":null,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:41
173	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-12 04:34:41
174	utilizador	UPDATE	1	{"id":7,"nome":"Graça","password":"$2y$10$eNAkF5AQvKqAJNINaIULl.j2GFaX2qIB9EuHa7iO3f7rJRHNX1N8q","contacto":917283822,"email":"pimmm@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:21:27","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":7,"nome":"Graça","password":"$2y$10$eNAkF5AQvKqAJNINaIULl.j2GFaX2qIB9EuHa7iO3f7rJRHNX1N8q","contacto":917283822,"email":"pimmm@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:21:27","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:34:41
175	utilizador	UPDATE	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
193	paciente	INSERT	7	{"id":4,"nome":"Chiu","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":true,"log_utilizador_id":7}	\N	2020-01-12 04:54:02
640	utilizador_tipo	INSERT	1	{"id":62,"utilizador_id":45,"tipo_id":3,"data_registo":"2020-01-23T02:06:28","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:06:28
176	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
177	utilizador	UPDATE	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
178	utilizador	UPDATE	1	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
179	utilizador	UPDATE	1	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T02:21:55","data_update":"2020-01-12T04:27:41","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":2,"nome":"psaude","password":"$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6","contacto":918201921,"email":"psaude@psaude.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T02:21:55","data_update":"2020-01-12T04:27:41","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
180	utilizador	UPDATE	1	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-12 04:34:41
181	utilizador_unidade_saude	UPDATE	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:03","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:03
182	utilizador_tipo	UPDATE	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:03","ativo":false,"log_utilizador_id":1}	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:03
183	utilizador	UPDATE	1	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:16
184	utilizador_unidade_saude	UPDATE	1	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":8,"unidade_saude_id":8,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:03","ativo":false,"log_utilizador_id":1}	2020-01-12 04:35:16
185	utilizador_unidade_saude	UPDATE	1	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":18,"utilizador_id":8,"unidade_saude_id":5,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:16
186	utilizador_unidade_saude	UPDATE	1	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":8,"unidade_saude_id":6,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:53","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:16
187	utilizador_tipo	UPDATE	1	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:17
188	utilizador_tipo	UPDATE	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T03:58:54","ativo":true,"log_utilizador_id":1}	2020-01-12 04:35:17
189	utilizador_tipo	UPDATE	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:03","ativo":false,"log_utilizador_id":1}	2020-01-12 04:35:17
190	paciente	INSERT	2	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-09-12","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 04:48:35
191	paciente	INSERT	4	{"id":2,"nome":"Maria Leal","sexo":"f","data_nascimento":"2001-02-15","data_diagnostico":"2011-05-15","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	\N	2020-01-12 04:49:05
195	equipamentos	INSERT	4	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":null,"ativo":true,"log_utilizador_id":4}	\N	2020-01-12 04:57:10
196	equipamentos	UPDATE	4	{"id":1,"nome":"007","access_token":"239203912910832024242849284","data_registo":"2020-01-12T04:54:42","data_update":null,"ativo":true,"log_utilizador_id":4}	{"id":1,"nome":"007","access_token":"erfrefergergerg","data_registo":"2020-01-12T04:54:42","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-12 04:57:21
197	equipamentos	INSERT	2	{"id":4,"nome":"Já Funfa","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 04:57:38
198	equipamentos	INSERT	3	{"id":5,"nome":"Mentiroso","access_token":"324235345023059203950235235236346","data_registo":"2020-01-12T04:57:52","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-12 04:57:52
199	paciente_utilizador	INSERT	3	{"id":1,"paciente_id":1,"utilizador_id":3,"relacao_paciente_id":2,"data_registo":"2020-01-12T05:04:47","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-12 05:04:47
200	paciente_utilizador	INSERT	3	{"id":2,"paciente_id":2,"utilizador_id":7,"relacao_paciente_id":3,"data_registo":"2020-01-12T05:05:06","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-12 05:05:06
201	paciente_utilizador	INSERT	1	{"id":3,"paciente_id":1,"utilizador_id":8,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 05:05:20
202	paciente_utilizador	INSERT	3	{"id":4,"paciente_id":3,"utilizador_id":10,"relacao_paciente_id":2,"data_registo":"2020-01-12T05:05:40","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-12 05:05:40
203	paciente_utilizador	INSERT	2	{"id":6,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-12T05:06:11","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 05:06:11
204	equipamentos	INSERT	1	{"id":11,"nome":"test","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-12 15:56:29
205	equipamentos	UPDATE	1	{"id":11,"nome":"aahahahhaha","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"test","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 15:58:45
206	equipamentos	UPDATE	2	{"id":11,"nome":"kkkkk","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":"2020-01-12T16:10:16","ativo":true,"log_utilizador_id":2}	{"id":11,"nome":"aahahahhaha","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-12 16:10:17
207	equipamentos	INSERT	2	{"id":12,"nome":"so mais um","access_token":"JKmu9sTIqCFjmHfptgq8","data_registo":"2020-01-12T16:30:12","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-12 16:30:12
208	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$iCDO8qEwDoLV1v0m0q7PLu/StwkBqkRuluMPGyAbqia8s8JYOFBxa","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$IDjMagvs8R14KxESm0BtfOClZCwuTxcDj1.due5ucv3WaAGKDVPxa","contacto":null,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-14 16:50:54
209	utilizador	UPDATE	2	{"id":3,"nome":"Cuidador","password":"$2y$10$y1Hbva413V8F36IMRmoIEuFC4TBnXJWaO1lmIAPq7BigUPtLSkO/W","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$iCDO8qEwDoLV1v0m0q7PLu/StwkBqkRuluMPGyAbqia8s8JYOFBxa","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-14 16:51:05
210	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"Cuidador","password":"$2y$10$y1Hbva413V8F36IMRmoIEuFC4TBnXJWaO1lmIAPq7BigUPtLSkO/W","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-14 18:21:39
211	utilizador	INSERT	1	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"uiui@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-15T15:16:45","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-15 15:16:45
212	utilizador_unidade_saude	INSERT	1	{"id":33,"utilizador_id":13,"unidade_saude_id":6,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-15 15:16:45
213	utilizador_tipo	INSERT	1	{"id":29,"utilizador_id":13,"tipo_id":2,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-15 15:16:45
214	utilizador_tipo	INSERT	1	{"id":30,"utilizador_id":13,"tipo_id":1,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-15 15:16:45
215	utilizador_tipo	INSERT	1	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-15 15:16:45
216	utilizador	INSERT	1	{"id":14,"nome":"psaude","password":"1202392","contacto":null,"email":"pimmmm@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-18T00:48:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 00:48:38
217	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-18 00:57:28
667	utilizador_tipo	INSERT	1	{"id":68,"utilizador_id":48,"tipo_id":3,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
218	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-18 00:57:48
219	paciente_utilizador	INSERT	3	{"id":7,"paciente_id":4,"utilizador_id":1,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-18 01:06:50
220	paciente_utilizador	UPDATE	3	{"id":7,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	{"id":7,"paciente_id":4,"utilizador_id":1,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	2020-01-18 01:14:44
221	paciente_utilizador	UPDATE	3	{"id":7,"paciente_id":3,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	{"id":7,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	2020-01-18 01:15:26
222	utilizador	INSERT	1	{"id":15,"nome":"sdvsdvdsv","password":"$2y$10$QhW3eZHOisryOQmJkgVDxeI/0xjHpEpo0.h.R6HzkvPYGBOZT5Q.K","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T15:51:43","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 15:51:43
223	utilizador	INSERT	1	{"id":16,"nome":"sdvsdvdsv","password":"$2y$10$jRHOGOCkWWHKwdqSwRUuHOZKy5zW5Oc2jWlYkmYyF0dEFa73UvfYS","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T15:57:45","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 15:57:45
224	utilizador	INSERT	1	{"id":17,"nome":"sdvsdvdsv","password":"$2y$10$sFo9DrDJtHctLoH3fCh14ui8yMp/WF/j6iYh6YfY1KAXR3J5J02lq","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:02:22","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:02:22
225	utilizador	INSERT	1	{"id":18,"nome":"sdvsdvdsv","password":"$2y$10$ySznWBAlAyukaO1wY1HbeO.2tBXhIIV79BNTq7JSNfannF5rQ8LBW","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:02:52","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:02:52
226	utilizador	INSERT	1	{"id":19,"nome":"sdvsdvdsv","password":"$2y$10$TzwGPmdyvFeou1vljgz6ZeEPGuBFnSvj1joGBDkt.y5yi2WjSpnzu","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:04:24","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:04:24
227	utilizador	INSERT	1	{"id":20,"nome":"sdvsdvdsv","password":"$2y$10$jBNIuKeD1ot13hTgijo1nuEEI4BeGNpp0wfjzqejdaDDLsZj0kj9O","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:06:06","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:06:06
228	utilizador	INSERT	1	{"id":21,"nome":"sdvsdvdsv","password":"$2y$10$U5OH3StHqaEiigWoZ2aRIe/MVT8WIjeKP0dIDsHTNztb0IPd/1fqa","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:09:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:09:37
229	utilizador_tipo	INSERT	1	{"id":32,"utilizador_id":21,"tipo_id":3,"data_registo":"2020-01-18T16:09:37","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:09:37
230	utilizador	INSERT	1	{"id":22,"nome":"sdvsdvdsv","password":"$2y$10$rSyHDajSDB7XYC.HC9q.Rub5adWI3uTythXgbh4ggGsGJUcXIuIrW","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:13:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:13:55
231	utilizador	INSERT	1	{"id":23,"nome":"sdvsdvdsv","password":"$2y$10$zCX.hKfoxlOqcyZjobjnXujsr4w16qVdzvcS8hdJbJQui4NaEaHYi","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:20:43","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:20:43
232	utilizador_tipo	INSERT	1	{"id":33,"utilizador_id":23,"tipo_id":3,"data_registo":"2020-01-18T16:20:43","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:20:43
233	utilizador	INSERT	1	{"id":24,"nome":"sdvsdvdsv","password":"$2y$10$MwLLQZZYhGqPUAFrMJAmB.I2R8bJ15UiC/Su3SHrRJnWpxYRacKG.","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:22:07","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:22:07
234	utilizador_tipo	INSERT	1	{"id":34,"utilizador_id":24,"tipo_id":3,"data_registo":"2020-01-18T16:22:07","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:22:07
235	utilizador	INSERT	1	{"id":25,"nome":"sdvsdvdsv","password":"$2y$10$1msJKuEi5CMwY1cXO6d9UOYwn33frusj3P5W4DSvwmybFr8vmyr86","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:37:19","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:37:19
236	utilizador_tipo	INSERT	1	{"id":35,"utilizador_id":25,"tipo_id":3,"data_registo":"2020-01-18T16:37:19","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:37:19
237	utilizador	INSERT	1	{"id":26,"nome":"sdvsdvdsv","password":"$2y$10$Ct3S4ZlrE9RxrCQ4z.s3mey/lz3RLvLKEIUOZ.v32VNLfRJ/cwlrq","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:47:42","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:47:42
238	utilizador_tipo	INSERT	1	{"id":36,"utilizador_id":26,"tipo_id":3,"data_registo":"2020-01-18T16:47:42","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:47:42
239	utilizador	INSERT	1	{"id":27,"nome":"sdvsdvdsv","password":"$2y$10$yc0hW8pGObu9Wj94iPAgT.bI2rE9wn294VdCURZ2C6/2z3MgtQgMe","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:49:28","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:49:28
240	utilizador_tipo	INSERT	1	{"id":37,"utilizador_id":27,"tipo_id":3,"data_registo":"2020-01-18T16:49:28","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:49:28
241	paciente_utilizador	INSERT	1	{"id":8,"paciente_id":2,"utilizador_id":27,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:55:33","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:55:33
242	utilizador	INSERT	1	{"id":28,"nome":"sdvsdvdsv","password":"$2y$10$0Vcc0O8zr4rgYR1D.Q0.9.mTUtDd5oVZsLQcDYzCDQFLnFPQVad3u","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:56:47","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:56:47
243	utilizador_tipo	INSERT	1	{"id":38,"utilizador_id":28,"tipo_id":3,"data_registo":"2020-01-18T16:56:47","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:56:47
244	paciente_utilizador	INSERT	1	{"id":9,"paciente_id":4,"utilizador_id":28,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:56:47","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:56:47
245	paciente_utilizador	INSERT	1	{"id":10,"paciente_id":2,"utilizador_id":28,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:56:47","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:56:47
246	paciente_utilizador	INSERT	1	{"id":11,"paciente_id":3,"utilizador_id":28,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:56:47","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:56:47
247	utilizador	INSERT	1	{"id":29,"nome":"sdvsdvdsv","password":"$2y$10$T3dOQYkAUz1.rx1j/pO4A.dBdUQi/skR0fjEs/jVvDkkES3OjSLR.","contacto":912839392,"email":"vkoefek@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-18T16:58:39","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:58:39
248	utilizador_tipo	INSERT	1	{"id":39,"utilizador_id":29,"tipo_id":3,"data_registo":"2020-01-18T16:58:39","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:58:39
249	paciente_utilizador	INSERT	1	{"id":12,"paciente_id":3,"utilizador_id":29,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:58:39","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-18 16:58:39
250	utilizador	UPDATE	1	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"uiui@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-18T18:39:23","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"uiui@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-15T15:16:45","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-18 18:39:23
251	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:48","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	2020-01-18 18:39:48
252	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:56","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:48","ativo":false,"log_utilizador_id":1}	2020-01-18 18:39:56
253	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-18 18:39:56
254	utilizador	UPDATE	1	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T02:10:22","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 02:10:22
255	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:10:38","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:56","ativo":false,"log_utilizador_id":1}	2020-01-19 02:10:38
256	utilizador_tipo	INSERT	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 02:10:38
257	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:10:52","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:10:38","ativo":false,"log_utilizador_id":1}	2020-01-19 02:10:52
258	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:10:52","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 02:10:52
265	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:34:59","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:10:52","ativo":false,"log_utilizador_id":1}	2020-01-19 02:34:59
266	utilizador	UPDATE	2	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:34:59","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-18T18:39:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 02:34:59
267	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:37:02","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:34:59","ativo":false,"log_utilizador_id":2}	2020-01-19 02:37:02
268	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:38:25","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:37:02","ativo":false,"log_utilizador_id":1}	2020-01-19 02:38:25
269	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:38:25","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:10:52","ativo":false,"log_utilizador_id":1}	2020-01-19 02:38:25
270	utilizador_tipo	UPDATE	1	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-19T02:41:12","ativo":false,"log_utilizador_id":1}	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 02:41:12
271	utilizador_tipo	UPDATE	1	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-19T02:41:25","ativo":true,"log_utilizador_id":1}	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-19T02:41:12","ativo":false,"log_utilizador_id":1}	2020-01-19 02:41:25
272	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:14","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:38:25","ativo":false,"log_utilizador_id":1}	2020-01-19 02:44:14
273	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:44:14","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:38:25","ativo":true,"log_utilizador_id":1}	2020-01-19 02:44:14
274	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:22","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:14","ativo":false,"log_utilizador_id":1}	2020-01-19 02:44:22
275	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:35","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:22","ativo":false,"log_utilizador_id":1}	2020-01-19 02:44:35
276	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:50:48","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:44:35","ativo":false,"log_utilizador_id":1}	2020-01-19 02:50:48
277	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:50:48","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:44:14","ativo":false,"log_utilizador_id":1}	2020-01-19 02:50:48
278	utilizador_tipo	UPDATE	1	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":true,"log_utilizador_id":1}	{"id":14,"utilizador_id":8,"tipo_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	2020-01-19 02:52:23
279	utilizador_tipo	UPDATE	1	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":true,"log_utilizador_id":1}	{"id":15,"utilizador_id":8,"tipo_id":1,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	2020-01-19 02:52:25
280	utilizador_tipo	UPDATE	1	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:16","ativo":true,"log_utilizador_id":1}	{"id":23,"utilizador_id":8,"tipo_id":3,"data_registo":"2020-01-12T03:57:34","data_update":"2020-01-12T04:35:16","ativo":false,"log_utilizador_id":1}	2020-01-19 02:52:27
509	paciente_utilizador	INSERT	31	{"id":19,"paciente_id":4,"utilizador_id":36,"relacao_paciente_id":null,"data_registo":"2020-01-22T12:34:28","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:34:28
281	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:55:06","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:50:48","ativo":false,"log_utilizador_id":1}	2020-01-19 02:55:06
282	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:55:06","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:50:48","ativo":true,"log_utilizador_id":1}	2020-01-19 02:55:06
283	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:56:06","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:55:06","ativo":false,"log_utilizador_id":1}	2020-01-19 02:56:06
284	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:56:06","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:55:06","ativo":false,"log_utilizador_id":1}	2020-01-19 02:56:06
285	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:12:57","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:56:06","ativo":false,"log_utilizador_id":1}	2020-01-19 03:12:57
286	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:12:57","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	2020-01-19 03:12:57
287	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:13:10","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:12:57","ativo":false,"log_utilizador_id":1}	2020-01-19 03:13:10
288	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:13:10","ativo":true,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:12:57","ativo":false,"log_utilizador_id":1}	2020-01-19 03:13:10
289	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:02","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:13:10","ativo":false,"log_utilizador_id":1}	2020-01-19 03:14:02
290	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:14:02","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T02:56:06","ativo":true,"log_utilizador_id":1}	2020-01-19 03:14:02
291	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:20","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:02","ativo":false,"log_utilizador_id":1}	2020-01-19 03:14:20
292	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:14:20","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:14:02","ativo":false,"log_utilizador_id":1}	2020-01-19 03:14:20
293	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:47","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:20","ativo":false,"log_utilizador_id":1}	2020-01-19 03:14:47
294	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:15:37","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:14:47","ativo":false,"log_utilizador_id":1}	2020-01-19 03:15:37
295	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:15:51","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:15:37","ativo":false,"log_utilizador_id":1}	2020-01-19 03:15:51
296	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:15:51","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:14:20","ativo":true,"log_utilizador_id":1}	2020-01-19 03:15:51
297	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:16:12","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:15:51","ativo":false,"log_utilizador_id":1}	2020-01-19 03:16:12
298	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:16:12","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:15:51","ativo":false,"log_utilizador_id":1}	2020-01-19 03:16:12
299	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:17:40","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:16:12","ativo":false,"log_utilizador_id":1}	2020-01-19 03:17:40
300	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:17:40","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:16:12","ativo":true,"log_utilizador_id":1}	2020-01-19 03:17:40
301	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:17:42","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:17:40","ativo":false,"log_utilizador_id":1}	2020-01-19 03:17:42
302	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:17:42","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:17:40","ativo":false,"log_utilizador_id":1}	2020-01-19 03:17:42
303	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:18:02","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:17:42","ativo":false,"log_utilizador_id":1}	2020-01-19 03:18:02
304	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:18:02","ativo":false,"log_utilizador_id":1}	2020-01-19 03:21:55
305	utilizador	UPDATE	2	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T02:34:59","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 03:21:55
306	utilizador	UPDATE	2	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 03:25:58
307	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","ativo":false,"log_utilizador_id":2}	2020-01-19 03:26:35
308	utilizador	UPDATE	2	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:21:55","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 03:26:35
309	utilizador	UPDATE	2	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 03:29:52
310	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:12","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","ativo":false,"log_utilizador_id":2}	2020-01-19 03:31:12
311	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:45","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:12","ativo":false,"log_utilizador_id":2}	2020-01-19 03:31:45
312	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:31:45","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:17:42","ativo":true,"log_utilizador_id":1}	2020-01-19 03:31:45
313	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:57","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:45","ativo":false,"log_utilizador_id":2}	2020-01-19 03:31:57
314	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:31:57","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:31:45","ativo":false,"log_utilizador_id":2}	2020-01-19 03:31:57
315	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:32:28","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:31:57","ativo":false,"log_utilizador_id":2}	2020-01-19 03:32:28
316	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:32:28","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:31:57","ativo":true,"log_utilizador_id":2}	2020-01-19 03:32:28
320	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:32:28","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:32:28","ativo":false,"log_utilizador_id":2}	2020-01-19 03:36:32
322	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:37:39","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:32:28","ativo":false,"log_utilizador_id":2}	2020-01-19 03:37:39
324	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:21","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:37:39","ativo":false,"log_utilizador_id":2}	2020-01-19 03:39:21
325	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:41","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:21","ativo":false,"log_utilizador_id":2}	2020-01-19 03:39:41
326	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:41","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:13:10","ativo":true,"log_utilizador_id":1}	2020-01-19 03:39:41
327	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:44:07","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:41","ativo":false,"log_utilizador_id":2}	2020-01-19 03:44:07
328	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:44:07","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:32:28","ativo":true,"log_utilizador_id":2}	2020-01-19 03:44:07
329	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:44:07","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:39:41","ativo":false,"log_utilizador_id":2}	2020-01-19 03:44:07
331	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:46:44","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:44:07","ativo":false,"log_utilizador_id":2}	2020-01-19 03:46:44
332	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:02","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:46:44","ativo":false,"log_utilizador_id":2}	2020-01-19 03:47:02
333	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:02","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:44:07","ativo":true,"log_utilizador_id":2}	2020-01-19 03:47:02
334	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:21","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:02","ativo":false,"log_utilizador_id":2}	2020-01-19 03:47:21
335	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:47:21","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:44:07","ativo":true,"log_utilizador_id":2}	2020-01-19 03:47:21
336	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:58","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:21","ativo":false,"log_utilizador_id":2}	2020-01-19 03:47:58
337	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:58","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:02","ativo":false,"log_utilizador_id":2}	2020-01-19 03:47:58
338	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:47:58","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:47:21","ativo":false,"log_utilizador_id":2}	2020-01-19 03:47:58
339	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:49:37","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:58","ativo":false,"log_utilizador_id":2}	2020-01-19 03:49:37
340	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:49:37","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:47:58","ativo":false,"log_utilizador_id":2}	2020-01-19 03:49:37
341	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:49:53","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:49:37","ativo":false,"log_utilizador_id":2}	2020-01-19 03:49:53
330	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:44:07","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:44:07","ativo":false,"log_utilizador_id":2}	2020-01-19 03:46:33
342	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:49:53","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:49:37","ativo":true,"log_utilizador_id":2}	2020-01-19 03:49:53
343	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:13","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:49:53","ativo":false,"log_utilizador_id":2}	2020-01-19 03:50:13
344	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:13","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:47:58","ativo":true,"log_utilizador_id":2}	2020-01-19 03:50:13
345	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:39","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:13","ativo":false,"log_utilizador_id":2}	2020-01-19 03:50:39
346	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:50:39","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:49:53","ativo":false,"log_utilizador_id":2}	2020-01-19 03:50:39
347	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:39","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:13","ativo":false,"log_utilizador_id":2}	2020-01-19 03:50:39
348	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:50:39","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:50:39","ativo":false,"log_utilizador_id":2}	2020-01-19 03:53:39
349	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:01","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:39","ativo":false,"log_utilizador_id":2}	2020-01-19 03:54:01
350	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:54:01","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:50:39","ativo":true,"log_utilizador_id":2}	2020-01-19 03:54:01
351	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:34","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:01","ativo":false,"log_utilizador_id":2}	2020-01-19 03:54:34
352	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:34","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:50:39","ativo":true,"log_utilizador_id":2}	2020-01-19 03:54:34
353	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:55:16","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:34","ativo":false,"log_utilizador_id":2}	2020-01-19 03:55:16
354	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:55:16","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:54:01","ativo":false,"log_utilizador_id":2}	2020-01-19 03:55:16
355	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:55:16","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:54:34","ativo":false,"log_utilizador_id":2}	2020-01-19 03:55:16
356	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:15","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:55:16","ativo":false,"log_utilizador_id":2}	2020-01-19 04:00:15
357	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:15","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:55:16","ativo":true,"log_utilizador_id":2}	2020-01-19 04:00:15
358	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:32","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:15","ativo":false,"log_utilizador_id":2}	2020-01-19 04:00:32
359	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:32","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:15","ativo":false,"log_utilizador_id":2}	2020-01-19 04:00:32
360	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:50","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:32","ativo":false,"log_utilizador_id":2}	2020-01-19 04:00:50
361	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:00:50","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T03:55:16","ativo":true,"log_utilizador_id":2}	2020-01-19 04:00:50
510	paciente_utilizador	INSERT	31	{"id":20,"paciente_id":3,"utilizador_id":36,"relacao_paciente_id":null,"data_registo":"2020-01-22T12:34:29","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:34:29
362	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:01","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:50","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:01
363	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:01","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:00:32","ativo":true,"log_utilizador_id":2}	2020-01-19 04:01:01
364	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:21","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:01","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:21
365	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:01:21","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:00:50","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:21
366	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:38","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:21","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:38
367	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:38","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:01","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:38
368	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:38","ativo":false,"log_utilizador_id":2}	2020-01-19 04:01:53
369	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:01:21","ativo":true,"log_utilizador_id":2}	2020-01-19 04:01:53
370	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:38","ativo":true,"log_utilizador_id":2}	2020-01-19 04:01:53
371	utilizador_unidade_saude	UPDATE	2	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:02:04","ativo":false,"log_utilizador_id":2}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	2020-01-19 04:02:04
372	utilizador_tipo	UPDATE	2	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:02:04","ativo":true,"log_utilizador_id":2}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	2020-01-19 04:02:04
373	utilizador_tipo	UPDATE	2	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:02:04","ativo":true,"log_utilizador_id":2}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:01:53","ativo":false,"log_utilizador_id":2}	2020-01-19 04:02:04
374	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:11:07","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:02:04","ativo":false,"log_utilizador_id":2}	2020-01-19 04:11:07
375	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:13:11","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:11:07","ativo":false,"log_utilizador_id":1}	2020-01-19 04:13:11
376	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:13:41","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:13:11","ativo":false,"log_utilizador_id":1}	2020-01-19 04:13:41
377	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:14:17","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:13:41","ativo":false,"log_utilizador_id":1}	2020-01-19 04:14:17
378	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:08","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:14:17","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:08
379	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:08:08","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T04:02:04","ativo":true,"log_utilizador_id":2}	2020-01-19 05:08:08
380	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:16","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:08","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:16
381	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:16","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T04:02:04","ativo":true,"log_utilizador_id":2}	2020-01-19 05:08:16
382	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:24","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:16","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:24
383	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:08:24","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:08:08","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:24
384	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:24","ativo":true,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:16","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:24
385	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:32","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:24","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:32
386	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:32","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	2020-01-19 05:08:32
387	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:32","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:39
388	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:32","ativo":false,"log_utilizador_id":1}	2020-01-19 05:08:39
389	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T03:26:35","remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 05:08:39
390	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:09:04","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","ativo":false,"log_utilizador_id":1}	2020-01-19 05:09:04
391	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:09:04","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","ativo":false,"log_utilizador_id":1}	2020-01-19 05:09:04
392	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:11:52","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:09:04","ativo":false,"log_utilizador_id":1}	2020-01-19 05:11:52
393	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:11:52","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:09:04","ativo":false,"log_utilizador_id":1}	2020-01-19 05:11:52
394	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:11:52","ativo":false,"log_utilizador_id":1}	2020-01-19 05:39:56
395	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:11:52","ativo":false,"log_utilizador_id":1}	2020-01-19 05:39:56
396	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:39","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:39:56
397	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","ativo":false,"log_utilizador_id":1}	2020-01-19 05:40:08
398	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","ativo":false,"log_utilizador_id":1}	2020-01-19 05:40:08
399	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:08:24","ativo":true,"log_utilizador_id":1}	2020-01-19 05:40:08
511	paciente_utilizador	INSERT	31	{"id":21,"paciente_id":1,"utilizador_id":36,"relacao_paciente_id":null,"data_registo":"2020-01-22T12:34:29","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:34:29
400	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	2020-01-19 05:40:16
401	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	2020-01-19 05:40:16
402	utilizador_tipo	UPDATE	1	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":false,"log_utilizador_id":1}	{"id":17,"utilizador_id":9,"tipo_id":1,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:08:24","ativo":true,"log_utilizador_id":1}	2020-01-19 05:40:16
403	utilizador	INSERT	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 05:41:01
404	utilizador_unidade_saude	INSERT	1	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 05:41:01
405	utilizador_unidade_saude	INSERT	1	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 05:41:01
406	utilizador_tipo	INSERT	1	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 05:41:01
407	utilizador	UPDATE	1	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":12,"nome":"TesteRegisto","password":"$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG","contacto":917283829,"email":"registo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
408	utilizador_unidade_saude	UPDATE	1	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
409	utilizador_unidade_saude	UPDATE	1	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
410	utilizador_unidade_saude	UPDATE	1	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
411	utilizador_tipo	UPDATE	1	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
412	utilizador_tipo	UPDATE	1	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
413	utilizador_tipo	UPDATE	1	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-12T04:33:42","ativo":true,"log_utilizador_id":1}	2020-01-19 05:41:53
414	paciente_utilizador	UPDATE	2	{"id":6,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-12T05:06:11","data_update":null,"ativo":false,"log_utilizador_id":2}	{"id":6,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-12T05:06:11","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 05:44:19
415	paciente_utilizador	UPDATE	3	{"id":7,"paciente_id":3,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":false,"log_utilizador_id":3}	{"id":7,"paciente_id":3,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	2020-01-19 05:44:21
416	utilizador_tipo	UPDATE	1	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":26,"utilizador_id":12,"tipo_id":2,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:01
417	utilizador_tipo	UPDATE	1	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":27,"utilizador_id":12,"tipo_id":1,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:05
418	utilizador_tipo	UPDATE	1	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":28,"utilizador_id":12,"tipo_id":3,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:06
419	utilizador_unidade_saude	UPDATE	1	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":30,"utilizador_id":12,"unidade_saude_id":6,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:15
420	utilizador_unidade_saude	UPDATE	1	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":31,"utilizador_id":12,"unidade_saude_id":5,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:17
421	utilizador_unidade_saude	UPDATE	1	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":true,"log_utilizador_id":1}	{"id":32,"utilizador_id":12,"unidade_saude_id":8,"data_registo":"2020-01-12T04:17:42","data_update":"2020-01-19T05:41:53","ativo":false,"log_utilizador_id":1}	2020-01-19 05:50:18
422	paciente_utilizador	UPDATE	2	{"id":6,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-12T05:06:11","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":6,"paciente_id":4,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-12T05:06:11","data_update":null,"ativo":false,"log_utilizador_id":2}	2020-01-19 05:50:34
423	paciente_utilizador	UPDATE	3	{"id":7,"paciente_id":3,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":true,"log_utilizador_id":3}	{"id":7,"paciente_id":3,"utilizador_id":12,"relacao_paciente_id":4,"data_registo":"2020-01-18T01:06:50","data_update":null,"ativo":false,"log_utilizador_id":3}	2020-01-19 05:50:36
424	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:50:45","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:50:46
425	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:52:43","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:50:45","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 05:52:43
426	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:54:52","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:52:43","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 05:54:52
427	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:54:52","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 05:56:50
428	utilizador_unidade_saude	UPDATE	1	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:56:50
429	utilizador_unidade_saude	UPDATE	1	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:56:50
430	utilizador_tipo	UPDATE	1	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 05:56:50
431	utilizador_tipo	UPDATE	1	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T15:14:38","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":11,"tipo_id":3,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	2020-01-19 15:14:38
432	utilizador_tipo	UPDATE	1	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-19T15:14:38","ativo":false,"log_utilizador_id":1}	{"id":22,"utilizador_id":11,"tipo_id":1,"data_registo":"2020-01-12T03:56:37","data_update":"2020-01-12T04:16:11","ativo":true,"log_utilizador_id":1}	2020-01-19 15:14:38
433	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 15:15:21
434	utilizador_tipo	UPDATE	1	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	2020-01-19 15:15:38
435	utilizador_unidade_saude	UPDATE	1	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	2020-01-19 15:15:53
436	utilizador_unidade_saude	UPDATE	1	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":false,"log_utilizador_id":1}	2020-01-19 15:15:55
437	paciente_utilizador	UPDATE	1	{"id":12,"paciente_id":3,"utilizador_id":29,"relacao_paciente_id":4,"data_registo":"2020-01-18T16:58:39","data_update":null,"ativo":true,"log_utilizador_id":1}	{"id":12,"paciente_id":3,"utilizador_id":29,"relacao_paciente_id":null,"data_registo":"2020-01-18T16:58:39","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 15:16:15
438	paciente_utilizador	INSERT	3	{"id":13,"paciente_id":1,"utilizador_id":30,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:16:29","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-19 15:16:29
439	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 15:16:58
440	paciente_utilizador	UPDATE	1	{"id":13,"paciente_id":1,"utilizador_id":30,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:16:29","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	{"id":13,"paciente_id":1,"utilizador_id":30,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:16:29","data_update":null,"ativo":true,"log_utilizador_id":3}	2020-01-19 15:16:58
441	utilizador_unidade_saude	UPDATE	1	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	2020-01-19 15:16:58
442	utilizador_unidade_saude	UPDATE	1	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	2020-01-19 15:16:58
443	utilizador_tipo	UPDATE	1	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T05:56:50","ativo":true,"log_utilizador_id":1}	2020-01-19 15:16:59
444	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":true,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":false,"log_utilizador_id":1}	2020-01-19 15:18:49
445	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":true,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":false,"log_utilizador_id":1}	2020-01-19 15:18:53
446	utilizador_unidade_saude	UPDATE	1	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":false,"log_utilizador_id":1}	{"id":20,"utilizador_id":9,"unidade_saude_id":5,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:02
447	paciente_utilizador	UPDATE	1	{"id":3,"paciente_id":1,"utilizador_id":9,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":null,"ativo":true,"log_utilizador_id":1}	{"id":3,"paciente_id":1,"utilizador_id":8,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:24
448	paciente_utilizador	INSERT	2	{"id":14,"paciente_id":2,"utilizador_id":9,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:19:44","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-19 15:19:44
449	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:39:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:58
450	paciente_utilizador	UPDATE	1	{"id":3,"paciente_id":1,"utilizador_id":9,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	{"id":3,"paciente_id":1,"utilizador_id":9,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:58
451	paciente_utilizador	UPDATE	1	{"id":14,"paciente_id":2,"utilizador_id":9,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:19:44","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	{"id":14,"paciente_id":2,"utilizador_id":9,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:19:44","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-19 15:19:58
452	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:58
453	utilizador_unidade_saude	UPDATE	1	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	{"id":21,"utilizador_id":9,"unidade_saude_id":8,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T05:40:16","ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:58
454	utilizador_tipo	UPDATE	1	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:57","ativo":false,"log_utilizador_id":1}	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-12T03:59:01","ativo":true,"log_utilizador_id":1}	2020-01-19 15:19:58
476	equipamentos	UPDATE	1	{"id":3,"nome":"Gaybriel","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T18:56:43","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-20 18:56:44
455	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:01
456	utilizador	UPDATE	1	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:05
457	utilizador_tipo	UPDATE	1	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:57","ativo":true,"log_utilizador_id":1}	{"id":16,"utilizador_id":9,"tipo_id":2,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:57","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:13
458	utilizador_tipo	UPDATE	1	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:40:08","ativo":true,"log_utilizador_id":1}	{"id":40,"utilizador_id":9,"tipo_id":3,"data_registo":"2020-01-19T02:10:38","data_update":"2020-01-19T05:40:08","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:27
459	utilizador_tipo	UPDATE	1	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":true,"log_utilizador_id":1}	{"id":41,"utilizador_id":30,"tipo_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:32
460	utilizador_unidade_saude	UPDATE	1	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":true,"log_utilizador_id":1}	{"id":34,"utilizador_id":30,"unidade_saude_id":5,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:37
461	utilizador_unidade_saude	UPDATE	1	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":true,"log_utilizador_id":1}	{"id":35,"utilizador_id":30,"unidade_saude_id":8,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:42
462	utilizador_unidade_saude	UPDATE	1	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","ativo":true,"log_utilizador_id":1}	{"id":19,"utilizador_id":9,"unidade_saude_id":6,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:46
463	paciente_utilizador	UPDATE	1	{"id":14,"paciente_id":2,"utilizador_id":9,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:19:44","data_update":"2020-01-19T15:19:56","ativo":true,"log_utilizador_id":1}	{"id":14,"paciente_id":2,"utilizador_id":9,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:19:44","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	2020-01-19 15:22:58
464	paciente_utilizador	UPDATE	1	{"id":3,"paciente_id":1,"utilizador_id":9,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":"2020-01-19T15:19:56","ativo":true,"log_utilizador_id":1}	{"id":3,"paciente_id":1,"utilizador_id":9,"relacao_paciente_id":1,"data_registo":"2020-01-12T05:05:20","data_update":"2020-01-19T15:19:56","ativo":false,"log_utilizador_id":1}	2020-01-19 15:23:03
465	paciente_utilizador	UPDATE	1	{"id":13,"paciente_id":1,"utilizador_id":30,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:16:29","data_update":"2020-01-19T15:16:57","ativo":true,"log_utilizador_id":1}	{"id":13,"paciente_id":1,"utilizador_id":30,"relacao_paciente_id":3,"data_registo":"2020-01-19T15:16:29","data_update":"2020-01-19T15:16:57","ativo":false,"log_utilizador_id":1}	2020-01-19 15:23:08
466	utilizador	INSERT	1	{"id":31,"nome":"Graça","password":"$2y$10$KZMo6euLJm6NMb7HBoVQCugiGdm1pxhkmNUTN/2Ao8KiYf72391V.","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 15:24:11
467	utilizador_unidade_saude	INSERT	1	{"id":36,"utilizador_id":31,"unidade_saude_id":6,"data_registo":"2020-01-19T15:24:11","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 15:24:11
468	utilizador_unidade_saude	INSERT	1	{"id":37,"utilizador_id":31,"unidade_saude_id":5,"data_registo":"2020-01-19T15:24:11","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 15:24:11
469	utilizador_tipo	INSERT	1	{"id":42,"utilizador_id":31,"tipo_id":2,"data_registo":"2020-01-19T15:24:11","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 15:24:11
470	utilizador	INSERT	1	{"id":32,"nome":"PacienteMaravilha","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"pacientemara@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 18:31:21
471	utilizador_tipo	INSERT	1	{"id":43,"utilizador_id":32,"tipo_id":3,"data_registo":"2020-01-19T18:31:21","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 18:31:21
472	paciente_utilizador	INSERT	1	{"id":15,"paciente_id":2,"utilizador_id":32,"relacao_paciente_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 18:31:21
473	paciente_utilizador	INSERT	1	{"id":16,"paciente_id":3,"utilizador_id":32,"relacao_paciente_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-19 18:31:21
474	equipamentos	UPDATE	2	{"id":1,"nome":"007","access_token":"239203912910832024242849284","data_registo":"2020-01-12T04:54:42","data_update":"2020-01-20T17:01:34","ativo":false,"log_utilizador_id":2}	{"id":1,"nome":"007","access_token":"239203912910832024242849284","data_registo":"2020-01-12T04:54:42","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-20 17:01:35
475	unidade_saude	INSERT	1	{"id":9,"nome":"alibaba","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-20 18:22:26
477	equipamentos	UPDATE	1	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T18:57:27","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"Gaybriel","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T18:56:43","ativo":true,"log_utilizador_id":1}	2020-01-20 18:57:27
478	equipamentos	UPDATE	1	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:10:31","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T18:57:27","ativo":true,"log_utilizador_id":1}	2020-01-20 19:10:31
479	equipamentos	UPDATE	1	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:10:48","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:10:31","ativo":true,"log_utilizador_id":1}	2020-01-20 19:10:49
480	equipamentos	UPDATE	1	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:12:09","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:10:48","ativo":true,"log_utilizador_id":1}	2020-01-20 19:12:09
481	unidade_saude	UPDATE	2	{"id":9,"nome":"alibaba","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-20T20:23:49","ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"alibaba","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 20:23:49
482	unidade_saude	UPDATE	2	{"id":9,"nome":"alibaba es tu","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-20T20:24:00","ativo":true,"log_utilizador_id":2}	{"id":9,"nome":"alibaba","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-20T20:23:49","ativo":true,"log_utilizador_id":2}	2020-01-20 20:24:01
483	utilizador	UPDATE	1	{"id":8,"nome":"pessoa1","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":8,"nome":"Action Man","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-20 21:46:32
484	utilizador	UPDATE	1	{"id":8,"nome":"pessoa1","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"pessoa1@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":8,"nome":"pessoa1","password":"$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6","contacto":918291922,"email":"action@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:25:35","data_update":"2020-01-12T04:35:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-20 21:46:39
485	utilizador	UPDATE	1	{"id":9,"nome":"pessoa2","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"Chouriço","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:46:46
486	utilizador	UPDATE	1	{"id":10,"nome":"pessoa3","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":10,"nome":"Cocó Mole","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:46:54
487	utilizador	UPDATE	1	{"id":11,"nome":"pessoa4","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T02:10:22","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"Cocó Duro","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T02:10:22","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:46:59
488	utilizador	UPDATE	1	{"id":32,"nome":"coisas","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"pacientemara@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":32,"nome":"PacienteMaravilha","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"pacientemara@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:47:19
489	utilizador	UPDATE	1	{"id":32,"nome":"coisas","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"coisas@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":32,"nome":"coisas","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"pacientemara@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:47:24
508	utilizador_tipo	INSERT	31	{"id":47,"utilizador_id":36,"tipo_id":3,"data_registo":"2020-01-22T12:34:28","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:34:28
490	utilizador	UPDATE	1	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"naosei@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-18T18:39:23","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"uiui@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-18T18:39:23","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:47:39
491	utilizador	UPDATE	1	{"id":11,"nome":"pessoa4","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"pessoa4@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T02:10:22","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"pessoa4","password":"$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa","contacto":928010291,"email":"cocoduro@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:34:58","data_update":"2020-01-19T02:10:22","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:47:47
492	utilizador	UPDATE	1	{"id":10,"nome":"pessoa3","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"pessoa3@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":10,"nome":"pessoa3","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"coco@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:47:57
493	utilizador	UPDATE	1	{"id":10,"nome":"pessoa3","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"pessoa3@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":10,"nome":"pessoa3","password":"$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K","contacto":910291831,"email":"pessoa3@miau.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-12T03:34:16","data_update":"2020-01-12T04:17:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:48:01
494	utilizador	UPDATE	1	{"id":9,"nome":"pessoa2","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"pessoa2@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"pessoa2","password":"$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2","contacto":918291023,"email":"chourico@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-12T03:33:35","data_update":"2020-01-19T15:19:56","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-20 21:48:17
495	paciente	UPDATE	6	{"id":3,"nome":"jose","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	{"id":3,"nome":"Pi Pi","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	2020-01-20 21:56:15
496	paciente	UPDATE	7	{"id":4,"nome":"Chico","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":true,"log_utilizador_id":7}	{"id":4,"nome":"Chiu","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":true,"log_utilizador_id":7}	2020-01-20 21:56:20
497	paciente	UPDATE	6	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	{"id":3,"nome":"jose","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	2020-01-20 21:56:24
498	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2001-02-15","data_diagnostico":"2011-05-15","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	{"id":2,"nome":"Maria Leal","sexo":"f","data_nascimento":"2001-02-15","data_diagnostico":"2011-05-15","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-20 21:56:28
499	utilizador	INSERT	2	{"id":33,"nome":"testCuida","password":"$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6","contacto":911114531,"email":"testCuida@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-20 21:58:12
500	utilizador_tipo	INSERT	2	{"id":44,"utilizador_id":33,"tipo_id":3,"data_registo":"2020-01-20T21:58:12","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-20 21:58:12
501	paciente_utilizador	INSERT	2	{"id":17,"paciente_id":4,"utilizador_id":33,"relacao_paciente_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-20 21:58:12
502	utilizador	INSERT	31	{"id":34,"nome":"melhor_cuidador","password":"$2y$10$WyROGAzjwdk6buYcli58SOO.we/PGPSzaimJZbInO7PJHbuF57GW6","contacto":912839396,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:28:31","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:28:31
503	utilizador_tipo	INSERT	31	{"id":45,"utilizador_id":34,"tipo_id":3,"data_registo":"2020-01-22T12:28:31","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:28:31
504	utilizador	INSERT	31	{"id":35,"nome":"melhor_cuidador","password":"$2y$10$NWM6s7rG3scWgFhFrw.a2uY1QJjkRQ8DJkb2TQM/UOoHRtR7XhfH.","contacto":912839395,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:32:48","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:32:48
505	utilizador_tipo	INSERT	31	{"id":46,"utilizador_id":35,"tipo_id":3,"data_registo":"2020-01-22T12:32:48","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:32:48
506	paciente_utilizador	INSERT	31	{"id":18,"paciente_id":2,"utilizador_id":35,"relacao_paciente_id":null,"data_registo":"2020-01-22T12:32:48","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:32:48
507	utilizador	INSERT	31	{"id":36,"nome":"melhor_cuidador","password":"$2y$10$W6hLjBFPy1ufnMdTFJOfxeThyq6AeQoU.SNXVrjXTQEYFY79tOU9m","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:34:28","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:34:28
512	utilizador	INSERT	31	{"id":37,"nome":"melhor_cuidador","password":"$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:43:56","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:43:56
513	utilizador_tipo	INSERT	31	{"id":48,"utilizador_id":37,"tipo_id":3,"data_registo":"2020-01-22T12:43:56","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-22 12:43:56
514	utilizador	UPDATE	1	{"id":14,"nome":"psaude","password":"1202392","contacto":923849382,"email":"pimmmm@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-18T00:48:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":14,"nome":"psaude","password":"1202392","contacto":null,"email":"pimmmm@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-18T00:48:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-22 13:14:32
515	equipamentos	UPDATE	2	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T14:10:39","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-20T19:12:09","ativo":true,"log_utilizador_id":1}	2020-01-22 14:10:39
516	utilizador	UPDATE	3	{"id":37,"nome":"melhor_cuidador","password":"$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:43:56","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":3}	{"id":37,"nome":"melhor_cuidador","password":"$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:43:56","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	2020-01-22 17:07:00
517	utilizador	UPDATE	2	{"id":37,"nome":"melhor_cuidador","password":"$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:43:56","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":37,"nome":"melhor_cuidador","password":"$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm","contacto":912839399,"email":"melhor_cuidador@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-22T12:43:56","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":3}	2020-01-22 17:07:08
518	utilizador	UPDATE	14	{"id":32,"nome":"coisas","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"coisas@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":14}	{"id":32,"nome":"coisas","password":"$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy","contacto":918291011,"email":"coisas@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-19T18:31:21","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-22 17:09:08
519	utilizador	UPDATE	14	{"id":33,"nome":"testCuida","password":"$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6","contacto":911114531,"email":"testCuida@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":14}	{"id":33,"nome":"testCuida","password":"$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6","contacto":911114531,"email":"testCuida@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 17:09:24
520	utilizador_unidade_saude	INSERT	2	{"id":39,"utilizador_id":14,"unidade_saude_id":6,"data_registo":"2020-01-22T17:10:20","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-22 17:10:20
521	unidade_saude	UPDATE	1	{"id":9,"nome":"US1","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"US1@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-22T19:38:16","ativo":true,"log_utilizador_id":1}	{"id":9,"nome":"alibaba es tu","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"alibaba@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-20T20:24:00","ativo":true,"log_utilizador_id":2}	2020-01-22 19:38:16
522	unidade_saude	UPDATE	1	{"id":6,"nome":"US2","morada":"Rua 456","telefone":918291029,"email":"US2@hotmail.com","data_registo":"2020-01-12T02:29:08","data_update":"2020-01-22T19:38:36","ativo":true,"log_utilizador_id":1}	{"id":6,"nome":"Fiz amor","morada":"Rua 456","telefone":918291029,"email":"fiz_amor@hotmail.com","data_registo":"2020-01-12T02:29:08","data_update":"2020-01-12T02:29:55","ativo":true,"log_utilizador_id":1}	2020-01-22 19:38:37
523	unidade_saude	UPDATE	1	{"id":4,"nome":"US3","morada":"Rua Engenheiro José Bastos Xavier","telefone":918291829,"email":"US3@ua.pt","data_registo":"2020-01-12T02:27:02","data_update":"2020-01-22T19:39:11","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"T7agox","morada":"Rua esquerda","telefone":918291829,"email":"t7agox@ua.pt","data_registo":"2020-01-12T02:27:02","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-22 19:39:11
524	unidade_saude	UPDATE	1	{"id":8,"nome":"US4","morada":"Rua de teste","telefone":918291918,"email":"US4@ua.pt","data_registo":"2020-01-12T02:34:12","data_update":"2020-01-22T19:39:38","ativo":true,"log_utilizador_id":1}	{"id":8,"nome":"Pim Pam Pum","morada":"Rua da Bosta","telefone":918291918,"email":"pim@ua.pt","data_registo":"2020-01-12T02:34:12","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-22 19:39:39
525	unidade_saude	UPDATE	1	{"id":5,"nome":"US5","morada":"Avenida","telefone":192839291,"email":"US5@hotmail.com","data_registo":"2020-01-12T02:28:13","data_update":"2020-01-22T19:40:11","ativo":true,"log_utilizador_id":1}	{"id":5,"nome":"O meu pai tem bigode","morada":"Rua direita","telefone":192839291,"email":"pai@hotmail.com","data_registo":"2020-01-12T02:28:13","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-22 19:40:11
526	equipamentos	UPDATE	1	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:40:41","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"James Bond","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T14:10:39","ativo":true,"log_utilizador_id":2}	2020-01-22 19:40:42
527	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-22T19:41:09","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"Já Funfa","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 19:41:09
638	utilizador_unidade_saude	INSERT	1	{"id":51,"utilizador_id":45,"unidade_saude_id":6,"data_registo":"2020-01-23T02:06:28","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:06:28
528	equipamentos	UPDATE	1	{"id":5,"nome":"E5","access_token":"324235345023059203950235235236346","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-22T19:41:31","ativo":true,"log_utilizador_id":1}	{"id":5,"nome":"Mentiroso","access_token":"324235345023059203950235235236346","data_registo":"2020-01-12T04:57:52","data_update":null,"ativo":true,"log_utilizador_id":3}	2020-01-22 19:41:32
529	equipamentos	UPDATE	1	{"id":11,"nome":"E6","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":"2020-01-22T19:41:43","ativo":true,"log_utilizador_id":1}	{"id":11,"nome":"kkkkk","access_token":"pOX9G0LCu5gpwhvjPKI5","data_registo":"2020-01-12T15:56:29","data_update":"2020-01-12T16:10:16","ativo":true,"log_utilizador_id":2}	2020-01-22 19:41:43
530	equipamentos	UPDATE	1	{"id":12,"nome":"E7","access_token":"JKmu9sTIqCFjmHfptgq8","data_registo":"2020-01-12T16:30:12","data_update":"2020-01-22T19:42:03","ativo":true,"log_utilizador_id":1}	{"id":12,"nome":"so mais um","access_token":"JKmu9sTIqCFjmHfptgq8","data_registo":"2020-01-12T16:30:12","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 19:42:04
531	equipamentos	UPDATE	1	{"id":3,"nome":"E32","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:48:53","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:40:41","ativo":true,"log_utilizador_id":1}	2020-01-22 19:48:54
532	equipamentos	UPDATE	1	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:48:59","ativo":true,"log_utilizador_id":1}	{"id":3,"nome":"E32","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:48:53","ativo":true,"log_utilizador_id":1}	2020-01-22 19:48:59
546	paciente	INSERT	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-22 20:30:05
547	paciente	UPDATE	2	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-12-09","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-09-12","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 22:38:29
548	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2001-02-15","data_diagnostico":"2011-05-15","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-22 22:38:48
549	paciente	UPDATE	6	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1995-02-20","data_diagnostico":"2003-10-17","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	2020-01-22 22:39:15
550	paciente	UPDATE	2	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-12-09","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":false,"log_utilizador_id":2}	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-12-09","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 22:39:59
551	paciente	UPDATE	6	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":false,"log_utilizador_id":6}	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":true,"log_utilizador_id":6}	2020-01-22 22:40:02
552	paciente	UPDATE	7	{"id":4,"nome":"Chico","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":false,"log_utilizador_id":7}	{"id":4,"nome":"Chico","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":true,"log_utilizador_id":7}	2020-01-22 22:40:04
553	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-22 22:43:44
554	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2020-01-08","data_diagnostico":"2020-01-17","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4}	2020-01-22 22:47:40
555	paciente	INSERT	2	{"id":20,"nome":"John Doe","sexo":"m","data_nascimento":"1970-06-17","data_diagnostico":"1970-11-26","data_registo":"2020-01-22T22:49:13","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-22 22:49:13
556	paciente	INSERT	2	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-22 23:01:33
557	paciente	INSERT	2	{"id":22,"nome":"John Doe Junior","sexo":"m","data_nascimento":"2011-02-16","data_diagnostico":"2020-01-08","data_registo":"2020-01-22T23:10:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-22 23:10:09
558	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:10:41","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T19:48:59","ativo":true,"log_utilizador_id":1}	2020-01-22 23:10:42
559	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:14:00
560	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:14:44","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:10:41","ativo":true,"log_utilizador_id":2}	2020-01-22 23:14:45
561	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:14:51","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:14:44","ativo":true,"log_utilizador_id":2}	2020-01-22 23:14:52
562	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:15","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:14:51","ativo":true,"log_utilizador_id":2}	2020-01-22 23:15:15
563	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:38","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:15","ativo":true,"log_utilizador_id":2}	2020-01-22 23:15:39
564	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:43","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:38","ativo":true,"log_utilizador_id":2}	2020-01-22 23:15:43
565	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:19:53
566	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:22:17
567	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:23:59
568	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:25:14
569	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:25:48
570	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:27:07
571	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:31:00","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:15:43","ativo":true,"log_utilizador_id":2}	2020-01-22 23:31:00
572	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:31:27","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:31:00","ativo":true,"log_utilizador_id":2}	2020-01-22 23:31:28
573	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:32:01
574	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:09","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:31:27","ativo":true,"log_utilizador_id":2}	2020-01-22 23:32:10
575	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:44","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:09","ativo":true,"log_utilizador_id":2}	2020-01-22 23:32:45
576	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:54","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:44","ativo":true,"log_utilizador_id":2}	2020-01-22 23:32:55
577	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:37:21
578	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:46:36
579	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:46:58
580	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:48:43","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:32:54","ativo":true,"log_utilizador_id":2}	2020-01-22 23:48:44
581	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:58:08
582	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:58:42
583	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-22 23:59:28
584	nota	INSERT	2	{"id":2,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:08:37","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:08:37
585	nota	INSERT	2	{"id":3,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:11:06","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:11:06
586	nota	INSERT	2	{"id":4,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:12:06","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:12:06
587	nota	INSERT	2	{"id":6,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:19:33","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:19:33
588	nota	INSERT	2	{"id":7,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:20:52","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:20:52
589	nota	INSERT	2	{"id":8,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:22:15","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:22:15
590	nota	UPDATE	2	{"id":7,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:20:52","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":7,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:20:52","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 00:27:23
591	nota	INSERT	2	{"id":9,"nome":"Nota X","descricao":"Info","paciente_id":19,"data_registo":"2020-01-23T00:30:18","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 00:30:18
639	utilizador_tipo	INSERT	1	{"id":61,"utilizador_id":45,"tipo_id":2,"data_registo":"2020-01-23T02:06:28","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:06:28
592	utilizador	INSERT	31	{"id":38,"nome":"Roberto Carlos","password":"$2y$10$u/7fK//8gG/R1g8/BNFeGekyDGIViSk4OsHe2ZWGK0D30opQ2TksC","contacto":918291823,"email":"roberto@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T01:13:55","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:13:55
593	utilizador_tipo	INSERT	31	{"id":49,"utilizador_id":38,"tipo_id":3,"data_registo":"2020-01-23T01:13:56","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:13:56
594	utilizador	INSERT	31	{"id":39,"nome":"Maria Albuquerque","password":"$2y$10$u8bntzZxsUTYxB/5UPeG9.Gi9ql0Kkql1KzUQk/ZlvKpDvh/czl5u","contacto":918291821,"email":"maria@hotmail.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T01:15:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:15:38
595	utilizador_tipo	INSERT	31	{"id":50,"utilizador_id":39,"tipo_id":3,"data_registo":"2020-01-23T01:15:38","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:15:38
596	paciente_utilizador	INSERT	31	{"id":22,"paciente_id":22,"utilizador_id":39,"relacao_paciente_id":null,"data_registo":"2020-01-23T01:15:38","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:15:38
597	paciente_utilizador	INSERT	31	{"id":23,"paciente_id":2,"utilizador_id":39,"relacao_paciente_id":null,"data_registo":"2020-01-23T01:15:38","data_update":null,"ativo":true,"log_utilizador_id":31}	\N	2020-01-23 01:15:38
598	utilizador_unidade_saude	INSERT	2	{"id":41,"utilizador_id":39,"unidade_saude_id":6,"data_registo":"2020-01-23T01:23:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 01:23:35
599	utilizador	UPDATE	1	{"id":31,"nome":"Graça","password":"$2y$10$UZOUBgymIque.1j66pOsz.FahPcU9x0yWeMkCA6yPGs6C8FhBgkO6","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":31,"nome":"Graça","password":"$2y$10$KZMo6euLJm6NMb7HBoVQCugiGdm1pxhkmNUTN/2Ao8KiYf72391V.","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:33:07
600	utilizador	UPDATE	1	{"id":31,"nome":"Graça","password":"$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":31,"nome":"Graça","password":"$2y$10$UZOUBgymIque.1j66pOsz.FahPcU9x0yWeMkCA6yPGs6C8FhBgkO6","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:33:24
601	utilizador	UPDATE	1	{"id":31,"nome":"Graça","password":"$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":31,"nome":"Graça","password":"$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:34:20
602	utilizador	UPDATE	1	{"id":31,"nome":"Graça","password":"$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":31,"nome":"Graça","password":"$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u","contacto":917283828,"email":"graca@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-19T15:24:11","data_update":null,"remember_token":null,"ativo":false,"log_utilizador_id":1}	2020-01-23 01:39:27
603	utilizador	INSERT	1	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T01:44:22","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:44:22
604	utilizador_unidade_saude	INSERT	1	{"id":42,"utilizador_id":40,"unidade_saude_id":6,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:44:22
605	utilizador_unidade_saude	INSERT	1	{"id":43,"utilizador_id":40,"unidade_saude_id":4,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:44:22
606	utilizador_tipo	INSERT	1	{"id":51,"utilizador_id":40,"tipo_id":2,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:44:22
607	utilizador_tipo	INSERT	1	{"id":52,"utilizador_id":40,"tipo_id":1,"data_registo":"2020-01-23T01:45:11","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:45:11
608	utilizador	UPDATE	1	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:45:11","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T01:44:22","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:45:11
609	utilizador_tipo	UPDATE	1	{"id":52,"utilizador_id":40,"tipo_id":1,"data_registo":"2020-01-23T01:45:11","data_update":"2020-01-23T01:45:22","ativo":false,"log_utilizador_id":1}	{"id":52,"utilizador_id":40,"tipo_id":1,"data_registo":"2020-01-23T01:45:11","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:45:22
610	utilizador_tipo	INSERT	1	{"id":53,"utilizador_id":40,"tipo_id":3,"data_registo":"2020-01-23T01:45:22","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:45:22
611	utilizador_unidade_saude	UPDATE	1	{"id":42,"utilizador_id":40,"unidade_saude_id":6,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:27","ativo":false,"log_utilizador_id":1}	{"id":42,"utilizador_id":40,"unidade_saude_id":6,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:27
612	utilizador_unidade_saude	UPDATE	1	{"id":43,"utilizador_id":40,"unidade_saude_id":4,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:27","ativo":false,"log_utilizador_id":1}	{"id":43,"utilizador_id":40,"unidade_saude_id":4,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:27
613	utilizador_unidade_saude	INSERT	1	{"id":44,"utilizador_id":40,"unidade_saude_id":9,"data_registo":"2020-01-23T01:55:27","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:55:27
614	utilizador	UPDATE	1	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:27","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:45:11","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:27
615	utilizador	UPDATE	1	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:39","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":40,"nome":"José Eduardo","password":"$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu","contacto":918291021,"email":"jose@hotmail.com","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:27","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:39
616	utilizador_unidade_saude	UPDATE	1	{"id":44,"utilizador_id":40,"unidade_saude_id":9,"data_registo":"2020-01-23T01:55:27","data_update":"2020-01-23T01:55:39","ativo":false,"log_utilizador_id":1}	{"id":44,"utilizador_id":40,"unidade_saude_id":9,"data_registo":"2020-01-23T01:55:27","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:40
617	utilizador_tipo	UPDATE	1	{"id":51,"utilizador_id":40,"tipo_id":2,"data_registo":"2020-01-23T01:44:22","data_update":"2020-01-23T01:55:39","ativo":false,"log_utilizador_id":1}	{"id":51,"utilizador_id":40,"tipo_id":2,"data_registo":"2020-01-23T01:44:22","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:40
618	utilizador_tipo	UPDATE	1	{"id":53,"utilizador_id":40,"tipo_id":3,"data_registo":"2020-01-23T01:45:22","data_update":"2020-01-23T01:55:39","ativo":false,"log_utilizador_id":1}	{"id":53,"utilizador_id":40,"tipo_id":3,"data_registo":"2020-01-23T01:45:22","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:55:40
619	utilizador	INSERT	1	{"id":41,"nome":"Miguel Alves","password":"$2y$10$V0kzu.60XnMXPEt92wYLe.RvGVuAJ7ivvTw2MAWYS4QUJFynB56gy","contacto":918291920,"email":"miguel@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T01:57:03","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:57:03
620	utilizador_unidade_saude	INSERT	1	{"id":45,"utilizador_id":41,"unidade_saude_id":5,"data_registo":"2020-01-23T01:57:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:57:03
621	utilizador_tipo	INSERT	1	{"id":54,"utilizador_id":41,"tipo_id":2,"data_registo":"2020-01-23T01:57:03","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:57:03
622	utilizador_tipo	INSERT	1	{"id":55,"utilizador_id":41,"tipo_id":1,"data_registo":"2020-01-23T01:57:17","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:57:17
623	utilizador_tipo	INSERT	1	{"id":56,"utilizador_id":41,"tipo_id":3,"data_registo":"2020-01-23T01:57:17","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:57:17
624	utilizador	UPDATE	1	{"id":41,"nome":"Miguel Alves","password":"$2y$10$V0kzu.60XnMXPEt92wYLe.RvGVuAJ7ivvTw2MAWYS4QUJFynB56gy","contacto":918291920,"email":"miguel@hotmail.com","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-23T01:57:03","data_update":"2020-01-23T01:57:17","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":41,"nome":"Miguel Alves","password":"$2y$10$V0kzu.60XnMXPEt92wYLe.RvGVuAJ7ivvTw2MAWYS4QUJFynB56gy","contacto":918291920,"email":"miguel@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T01:57:03","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 01:57:17
625	utilizador	INSERT	1	{"id":42,"nome":"Ivo Ruivo","password":"$2y$10$yqhCRvH7T2EH2MOqXehFO.SUwof0ZlnjRwzmbKZuxwaTZdMEcHpBK","contacto":917283853,"email":"ivo@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T01:58:00","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:58:00
626	utilizador_unidade_saude	INSERT	1	{"id":46,"utilizador_id":42,"unidade_saude_id":6,"data_registo":"2020-01-23T01:58:00","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:58:00
627	utilizador_unidade_saude	INSERT	1	{"id":47,"utilizador_id":42,"unidade_saude_id":4,"data_registo":"2020-01-23T01:58:00","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:58:00
628	utilizador_tipo	INSERT	1	{"id":57,"utilizador_id":42,"tipo_id":2,"data_registo":"2020-01-23T01:58:00","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 01:58:00
629	utilizador	INSERT	1	{"id":43,"nome":"Exemplo","password":"$2y$10$X9xXYnsWD3Ma50JXr.O7ZuX4h20hq6NrRjxMoujDGA2vi1TFDfS.a","contacto":918291829,"email":"exemplo@live.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T02:00:40","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:00:40
630	utilizador_unidade_saude	INSERT	1	{"id":48,"utilizador_id":43,"unidade_saude_id":6,"data_registo":"2020-01-23T02:00:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:00:40
631	utilizador_tipo	INSERT	1	{"id":58,"utilizador_id":43,"tipo_id":2,"data_registo":"2020-01-23T02:00:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:00:40
632	utilizador	INSERT	1	{"id":44,"nome":"Exemplo","password":"$2y$10$Tjyjpz8NpBEycajYFfIY8.p8ohc8A77DstazcwwRD.NweP6h77nLy","contacto":918291905,"email":"exemplo@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T02:05:51","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:05:51
633	utilizador_unidade_saude	INSERT	1	{"id":49,"utilizador_id":44,"unidade_saude_id":9,"data_registo":"2020-01-23T02:05:51","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:05:51
634	utilizador_unidade_saude	INSERT	1	{"id":50,"utilizador_id":44,"unidade_saude_id":6,"data_registo":"2020-01-23T02:05:51","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:05:51
635	utilizador_tipo	INSERT	1	{"id":59,"utilizador_id":44,"tipo_id":2,"data_registo":"2020-01-23T02:05:51","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:05:51
636	utilizador_tipo	INSERT	1	{"id":60,"utilizador_id":44,"tipo_id":1,"data_registo":"2020-01-23T02:05:51","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:05:51
637	utilizador	INSERT	1	{"id":45,"nome":"Exemplo2","password":"$2y$10$7SeEG6T6OGJKgVXOZ6.zQeClAu08BESf3x6ySMGkaDyEwjgw7SzN.","contacto":819281929,"email":"exemplo@live.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-23T02:06:28","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:06:28
641	utilizador	INSERT	1	{"id":46,"nome":"Exemplo3","password":"$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK","contacto":918010391,"email":"exemplo3@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T02:07:32","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
642	utilizador_unidade_saude	INSERT	1	{"id":52,"utilizador_id":46,"unidade_saude_id":6,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
643	utilizador_unidade_saude	INSERT	1	{"id":53,"utilizador_id":46,"unidade_saude_id":5,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
644	utilizador_tipo	INSERT	1	{"id":63,"utilizador_id":46,"tipo_id":2,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
645	utilizador_tipo	INSERT	1	{"id":64,"utilizador_id":46,"tipo_id":1,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
646	utilizador_tipo	INSERT	1	{"id":65,"utilizador_id":46,"tipo_id":3,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:07:32
647	utilizador_tipo	UPDATE	1	{"id":65,"utilizador_id":46,"tipo_id":3,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:07:48","ativo":false,"log_utilizador_id":1}	{"id":65,"utilizador_id":46,"tipo_id":3,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:07:48
648	utilizador_unidade_saude	UPDATE	1	{"id":52,"utilizador_id":46,"unidade_saude_id":6,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:02","ativo":false,"log_utilizador_id":1}	{"id":52,"utilizador_id":46,"unidade_saude_id":6,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:02
649	utilizador_tipo	UPDATE	1	{"id":64,"utilizador_id":46,"tipo_id":1,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:02","ativo":false,"log_utilizador_id":1}	{"id":64,"utilizador_id":46,"tipo_id":1,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:02
650	utilizador	UPDATE	1	{"id":46,"nome":"Exemplo3","password":"$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK","contacto":918010391,"email":"exemplo3@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:02","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":46,"nome":"Exemplo3","password":"$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK","contacto":918010391,"email":"exemplo3@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T02:07:32","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:02
651	utilizador	UPDATE	1	{"id":46,"nome":"Exemplo3","password":"$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK","contacto":918010391,"email":"exemplo3@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:09","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":46,"nome":"Exemplo3","password":"$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK","contacto":918010391,"email":"exemplo3@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:02","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:10
652	utilizador_unidade_saude	UPDATE	1	{"id":53,"utilizador_id":46,"unidade_saude_id":5,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:09","ativo":false,"log_utilizador_id":1}	{"id":53,"utilizador_id":46,"unidade_saude_id":5,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:10
653	utilizador_tipo	UPDATE	1	{"id":63,"utilizador_id":46,"tipo_id":2,"data_registo":"2020-01-23T02:07:32","data_update":"2020-01-23T02:08:09","ativo":false,"log_utilizador_id":1}	{"id":63,"utilizador_id":46,"tipo_id":2,"data_registo":"2020-01-23T02:07:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 02:08:10
654	equipamentos	INSERT	1	{"id":13,"nome":"E200","access_token":"YmFRogpVdizBBKMjgoi4","data_registo":"2020-01-23T02:28:08","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:28:08
655	equipamentos	INSERT	1	{"id":14,"nome":"E100","access_token":"XEMrVNvKByZA6AxtG1Rx","data_registo":"2020-01-23T02:28:57","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:28:57
656	equipamentos	INSERT	1	{"id":15,"nome":"E15","access_token":"pecmOSbZ3t3XNRdaIMjP","data_registo":"2020-01-23T02:30:08","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:30:08
657	equipamentos	INSERT	1	{"id":16,"nome":"E12","access_token":"2YWXZ4GHbl4D3GpoguLk","data_registo":"2020-01-23T02:33:14","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 02:33:14
658	utilizador	INSERT	2	{"id":47,"nome":"Maria Júlia","password":"$2y$10$yduf79llHutaypfX8clL2OOHgz1LLUIZnD31PeixhlFxZV7gaLTTO","contacto":233435322,"email":"maria@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T02:58:24","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 02:58:24
659	utilizador_tipo	INSERT	2	{"id":66,"utilizador_id":47,"tipo_id":3,"data_registo":"2020-01-23T02:58:24","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 02:58:24
660	paciente_utilizador	INSERT	2	{"id":24,"paciente_id":21,"utilizador_id":47,"relacao_paciente_id":null,"data_registo":"2020-01-23T02:58:24","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 02:58:24
661	paciente_utilizador	INSERT	2	{"id":25,"paciente_id":19,"utilizador_id":47,"relacao_paciente_id":null,"data_registo":"2020-01-23T02:58:24","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 02:58:24
662	utilizador	INSERT	1	{"id":48,"nome":"Monte Carlos","password":"$2y$10$.EX4e.Mkzas/pD8O5triM.GrSxOe.9mjCKvTgR5nHYXZcYATpIL8W","contacto":911192019,"email":"monte@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T03:06:40","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
663	utilizador_unidade_saude	INSERT	1	{"id":54,"utilizador_id":48,"unidade_saude_id":9,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
664	utilizador_unidade_saude	INSERT	1	{"id":55,"utilizador_id":48,"unidade_saude_id":6,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
665	utilizador_unidade_saude	INSERT	1	{"id":56,"utilizador_id":48,"unidade_saude_id":4,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
666	utilizador_tipo	INSERT	1	{"id":67,"utilizador_id":48,"tipo_id":2,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 03:06:40
668	utilizador	UPDATE	1	{"id":48,"nome":"Monte Carlos","password":"$2y$10$.EX4e.Mkzas/pD8O5triM.GrSxOe.9mjCKvTgR5nHYXZcYATpIL8W","contacto":911192019,"email":"monte@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":48,"nome":"Monte Carlos","password":"$2y$10$.EX4e.Mkzas/pD8O5triM.GrSxOe.9mjCKvTgR5nHYXZcYATpIL8W","contacto":911192019,"email":"monte@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T03:06:40","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
669	utilizador_unidade_saude	UPDATE	1	{"id":54,"utilizador_id":48,"unidade_saude_id":9,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","ativo":false,"log_utilizador_id":1}	{"id":54,"utilizador_id":48,"unidade_saude_id":9,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
670	utilizador_unidade_saude	UPDATE	1	{"id":55,"utilizador_id":48,"unidade_saude_id":6,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","ativo":false,"log_utilizador_id":1}	{"id":55,"utilizador_id":48,"unidade_saude_id":6,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
671	utilizador_unidade_saude	UPDATE	1	{"id":56,"utilizador_id":48,"unidade_saude_id":4,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","ativo":false,"log_utilizador_id":1}	{"id":56,"utilizador_id":48,"unidade_saude_id":4,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
672	utilizador_tipo	UPDATE	1	{"id":67,"utilizador_id":48,"tipo_id":2,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","ativo":false,"log_utilizador_id":1}	{"id":67,"utilizador_id":48,"tipo_id":2,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
673	utilizador_tipo	UPDATE	1	{"id":68,"utilizador_id":48,"tipo_id":3,"data_registo":"2020-01-23T03:06:40","data_update":"2020-01-23T03:09:27","ativo":false,"log_utilizador_id":1}	{"id":68,"utilizador_id":48,"tipo_id":3,"data_registo":"2020-01-23T03:06:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 03:09:28
674	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$s8ldO.7KWwThqn06W1lWTuBspr3eXdOmyyCyKBq5iAYov.Y/TcMGW","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 11:12:02
675	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":false,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 11:16:27
676	utilizador	UPDATE	2	{"id":1,"nome":"admin","password":"$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":1,"nome":"admin","password":"$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6","contacto":null,"email":"admin@admin.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:29:37","data_update":null,"remember_token":null,"ativo":false,"log_utilizador_id":2}	2020-01-23 11:16:38
677	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:23:35","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-22T23:48:43","ativo":true,"log_utilizador_id":2}	2020-01-23 12:23:35
678	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:29:43","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:23:35","ativo":true,"log_utilizador_id":2}	2020-01-23 12:29:44
679	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:38:19","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:29:43","ativo":true,"log_utilizador_id":2}	2020-01-23 12:38:19
680	nota	UPDATE	2	{"id":2,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:08:37","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":2,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:08:37","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:41
681	nota	UPDATE	2	{"id":3,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:11:06","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":3,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:11:06","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:43
682	nota	UPDATE	2	{"id":4,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:12:06","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":4,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:12:06","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:45
683	nota	UPDATE	2	{"id":6,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:19:33","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":6,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:19:33","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:46
684	nota	UPDATE	2	{"id":8,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:22:15","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":8,"nome":"Nota A","descricao":"Informações variadas","paciente_id":19,"data_registo":"2020-01-23T00:22:15","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:48
788	paciente_utilizador	INSERT	2	{"id":37,"paciente_id":21,"utilizador_id":53,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:37:12","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:12
685	nota	UPDATE	2	{"id":9,"nome":"Nota X","descricao":"Info","paciente_id":19,"data_registo":"2020-01-23T00:30:18","log_utilizador_id":2,"ativo":false,"criado_por":2}	{"id":9,"nome":"Nota X","descricao":"Info","paciente_id":19,"data_registo":"2020-01-23T00:30:18","log_utilizador_id":2,"ativo":true,"criado_por":2}	2020-01-23 13:25:49
686	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:27:02","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T12:38:19","ativo":true,"log_utilizador_id":2}	2020-01-23 13:27:03
687	nota	INSERT	2	{"id":10,"nome":"Nota A","descricao":"Informações relevantes","paciente_id":2,"data_registo":"2020-01-23T13:27:03","log_utilizador_id":2,"ativo":true,"criado_por":2}	\N	2020-01-23 13:27:03
688	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:27:51","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:27:02","ativo":true,"log_utilizador_id":2}	2020-01-23 13:27:52
689	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:32:46","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:27:51","ativo":true,"log_utilizador_id":2}	2020-01-23 13:32:47
690	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:33:09","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:32:46","ativo":true,"log_utilizador_id":2}	2020-01-23 13:33:09
691	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:36:50","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:33:09","ativo":true,"log_utilizador_id":2}	2020-01-23 13:36:50
692	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:37:51","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:36:50","ativo":true,"log_utilizador_id":2}	2020-01-23 13:37:52
693	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:41:23","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:37:51","ativo":true,"log_utilizador_id":2}	2020-01-23 13:41:24
694	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:41:33","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:41:23","ativo":true,"log_utilizador_id":2}	2020-01-23 13:41:34
695	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:42:28","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:41:33","ativo":true,"log_utilizador_id":2}	2020-01-23 13:42:29
696	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:42:59","ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:42:28","ativo":true,"log_utilizador_id":2}	2020-01-23 13:43:00
697	nota	INSERT	2	{"id":11,"nome":"Nota B","descricao":"Informações relvantes B","paciente_id":2,"data_registo":"2020-01-23T14:06:42","log_utilizador_id":2,"ativo":true,"criado_por":0}	\N	2020-01-23 14:06:42
698	nota	INSERT	2	{"id":12,"nome":"Nota C","descricao":"Informações relevantes C","paciente_id":19,"data_registo":"2020-01-23T14:12:25","log_utilizador_id":2,"ativo":true,"criado_por":0}	\N	2020-01-23 14:12:25
699	paciente	INSERT	2	{"id":23,"nome":"Luís Rodrigues","sexo":"m","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 15:31:36
700	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":23,"nome":"Luís Rodrigues","sexo":"m","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 15:34:12
701	paciente	UPDATE	2	{"id":23,"nome":"Luí","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 15:35:08
702	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":23,"nome":"Luí","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 15:35:40
703	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 15:36:01
704	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:37:23
705	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2019-10-07","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:37:51
706	nota	INSERT	2	{"id":13,"nome":"Mal estar","descricao":"Paciente com muitas dificuldades","paciente_id":23,"data_registo":"2020-01-23T15:38:56","log_utilizador_id":2,"ativo":true,"criado_por":0}	\N	2020-01-23 15:38:56
707	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:39:18
708	utilizador_unidade_saude	INSERT	2	{"id":57,"utilizador_id":29,"unidade_saude_id":5,"data_registo":"2020-01-23T15:50:10","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 15:50:10
709	utilizador_unidade_saude	INSERT	3	{"id":59,"utilizador_id":32,"unidade_saude_id":6,"data_registo":"2020-01-23T15:50:30","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 15:50:30
710	utilizador_unidade_saude	INSERT	3	{"id":60,"utilizador_id":33,"unidade_saude_id":9,"data_registo":"2020-01-23T15:50:50","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 15:50:50
711	utilizador_unidade_saude	INSERT	3	{"id":61,"utilizador_id":37,"unidade_saude_id":4,"data_registo":"2020-01-23T15:51:10","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 15:51:10
712	utilizador_unidade_saude	INSERT	3	{"id":62,"utilizador_id":47,"unidade_saude_id":9,"data_registo":"2020-01-23T15:51:33","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 15:51:33
713	utilizador_unidade_saude	INSERT	2	{"id":63,"utilizador_id":3,"unidade_saude_id":5,"data_registo":"2020-01-23T15:52:05","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 15:52:05
714	paciente	UPDATE	2	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-12-09","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":5}	{"id":1,"nome":"Roberto","sexo":"m","data_nascimento":"1999-10-10","data_diagnostico":"2010-12-09","data_registo":"2020-01-12T04:48:35","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:52:36
715	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2020-01-08","data_diagnostico":"2020-01-17","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4,"unidade_saude_id":8}	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2020-01-08","data_diagnostico":"2020-01-17","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4,"unidade_saude_id":null}	2020-01-23 15:52:44
716	paciente	UPDATE	6	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":false,"log_utilizador_id":6,"unidade_saude_id":6}	{"id":3,"nome":"Jose","sexo":"m","data_nascimento":"1970-01-01","data_diagnostico":"1970-01-01","data_registo":"2020-01-12T04:53:34","data_update":null,"ativo":false,"log_utilizador_id":6,"unidade_saude_id":null}	2020-01-23 15:52:46
717	paciente	UPDATE	7	{"id":4,"nome":"Chico","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":false,"log_utilizador_id":7,"unidade_saude_id":5}	{"id":4,"nome":"Chico","sexo":"f","data_nascimento":"2000-03-10","data_diagnostico":"2007-05-18","data_registo":"2020-01-12T04:54:02","data_update":null,"ativo":false,"log_utilizador_id":7,"unidade_saude_id":null}	2020-01-23 15:52:50
718	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":9}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:52:52
719	paciente	UPDATE	2	{"id":20,"nome":"John Doe","sexo":"m","data_nascimento":"1970-06-17","data_diagnostico":"1970-11-26","data_registo":"2020-01-22T22:49:13","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":9}	{"id":20,"nome":"John Doe","sexo":"m","data_nascimento":"1970-06-17","data_diagnostico":"1970-11-26","data_registo":"2020-01-22T22:49:13","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:52:54
720	paciente	UPDATE	2	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":4}	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:52:55
721	paciente	UPDATE	2	{"id":22,"nome":"John Doe Junior","sexo":"m","data_nascimento":"2011-02-16","data_diagnostico":"2020-01-08","data_registo":"2020-01-22T23:10:09","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":6}	{"id":22,"nome":"John Doe Junior","sexo":"m","data_nascimento":"2011-02-16","data_diagnostico":"2020-01-08","data_registo":"2020-01-22T23:10:09","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:52:58
722	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":4}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 15:53:02
723	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":4}	2020-01-23 16:21:40
789	utilizador_unidade_saude	INSERT	2	{"id":73,"utilizador_id":53,"unidade_saude_id":4,"data_registo":"2020-01-23T18:37:12","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:12
724	paciente	UPDATE	2	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":4}	2020-01-23 16:21:40
725	paciente	INSERT	2	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-06","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 16:38:07
726	paciente	UPDATE	2	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-06","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 16:38:42
727	utilizador_unidade_saude	INSERT	3	{"id":64,"utilizador_id":37,"unidade_saude_id":4,"data_registo":"2020-01-23T16:52:23","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 16:52:23
728	utilizador_unidade_saude	INSERT	2	{"id":65,"utilizador_id":48,"unidade_saude_id":9,"data_registo":"2020-01-23T16:52:34","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 16:52:34
729	utilizador_unidade_saude	INSERT	2	{"id":66,"utilizador_id":48,"unidade_saude_id":6,"data_registo":"2020-01-23T16:52:43","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 16:52:43
730	utilizador_unidade_saude	INSERT	5	{"id":67,"utilizador_id":48,"unidade_saude_id":4,"data_registo":"2020-01-23T16:52:53","data_update":null,"ativo":true,"log_utilizador_id":5}	\N	2020-01-23 16:52:53
731	paciente	UPDATE	2	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 16:53:26
732	nota	INSERT	2	{"id":14,"nome":"teste","descricao":"testeeee","paciente_id":22,"data_registo":"2020-01-23T16:53:59","log_utilizador_id":2,"ativo":true,"criado_por":0}	\N	2020-01-23 16:53:59
733	equipamentos	UPDATE	2	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T16:56:41","ativo":true,"log_utilizador_id":2}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-22T19:41:09","ativo":true,"log_utilizador_id":1}	2020-01-23 16:56:41
734	paciente_utilizador	INSERT	3	{"id":26,"paciente_id":22,"utilizador_id":37,"relacao_paciente_id":null,"data_registo":"2020-01-23T17:00:33","data_update":null,"ativo":true,"log_utilizador_id":3}	\N	2020-01-23 17:00:33
735	paciente_utilizador	INSERT	2	{"id":27,"paciente_id":4,"utilizador_id":48,"relacao_paciente_id":null,"data_registo":"2020-01-23T17:00:45","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 17:00:45
736	unidade_saude	UPDATE	1	{"id":7,"nome":"U6","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":"2020-01-12T02:32:08","ativo":false,"log_utilizador_id":1}	{"id":7,"nome":"O Manzarras","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":"2020-01-12T02:32:08","ativo":false,"log_utilizador_id":1}	2020-01-23 17:10:51
737	unidade_saude	UPDATE	1	{"id":7,"nome":"U6","morada":"Rua Torta","telefone":91829291,"email":"U6@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":"2020-01-12T02:32:08","ativo":false,"log_utilizador_id":1}	{"id":7,"nome":"U6","morada":"Rua Torta","telefone":91829291,"email":"manzarras@ua.pt","data_registo":"2020-01-12T02:31:45","data_update":"2020-01-12T02:32:08","ativo":false,"log_utilizador_id":1}	2020-01-23 17:11:23
738	paciente_utilizador	UPDATE	2	{"id":27,"paciente_id":4,"utilizador_id":2,"relacao_paciente_id":null,"data_registo":"2020-01-23T17:00:45","data_update":null,"ativo":true,"log_utilizador_id":2}	{"id":27,"paciente_id":4,"utilizador_id":48,"relacao_paciente_id":null,"data_registo":"2020-01-23T17:00:45","data_update":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 17:17:14
739	equipamentos	UPDATE	2	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T17:17:28","ativo":true,"log_utilizador_id":2}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T16:56:41","ativo":true,"log_utilizador_id":2}	2020-01-23 17:17:29
740	equipamentos	UPDATE	2	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T17:33:00","ativo":true,"log_utilizador_id":2}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T17:17:28","ativo":true,"log_utilizador_id":2}	2020-01-23 17:33:01
741	paciente	INSERT	2	{"id":25,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 17:33:31
742	paciente	INSERT	2	{"id":26,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:45","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 17:33:46
743	paciente	UPDATE	2	{"id":26,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:45","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":26,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:45","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 17:34:15
744	paciente	UPDATE	2	{"id":25,"nome":"Paciente2","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":25,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 17:34:24
790	utilizador	INSERT	2	{"id":54,"nome":"Filipa","password":"$2y$10$pVEsMxRfPyAPXV1XqysZGeuiYsIkCzPZ9pDpfw5KaknrT0lNdym26","contacto":918291928,"email":"filipa@hotmail.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:37:58","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:58
745	paciente	UPDATE	2	{"id":25,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	{"id":25,"nome":"Paciente2","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 17:37:39
746	paciente	INSERT	2	{"id":27,"nome":"paciente3","sexo":"m","data_nascimento":"2020-01-12","data_diagnostico":"2020-01-13","data_registo":"2020-01-23T17:37:58","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 17:37:58
747	utilizador_tipo	INSERT	2	{"id":69,"utilizador_id":2,"tipo_id":3,"data_registo":"2020-01-23T17:44:30","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 17:44:30
748	paciente	UPDATE	4	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2020-01-08","data_diagnostico":"2020-01-17","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":false,"log_utilizador_id":4,"unidade_saude_id":8}	{"id":2,"nome":"Maria","sexo":"f","data_nascimento":"2020-01-08","data_diagnostico":"2020-01-17","data_registo":"2020-01-12T04:49:05","data_update":null,"ativo":true,"log_utilizador_id":4,"unidade_saude_id":8}	2020-01-23 17:47:37
749	paciente	UPDATE	2	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":9}	{"id":19,"nome":"João Luís","sexo":"m","data_nascimento":"2020-01-01","data_diagnostico":"2020-01-15","data_registo":"2020-01-22T20:30:05","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":9}	2020-01-23 18:08:37
750	paciente	INSERT	2	{"id":28,"nome":"p4","sexo":"m","data_nascimento":"2020-01-13","data_diagnostico":"2020-01-16","data_registo":"2020-01-23T18:09:08","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	\N	2020-01-23 18:09:09
751	equipamentos	UPDATE	2	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T18:09:16","ativo":false,"log_utilizador_id":2}	{"id":3,"nome":"E3","access_token":"565757574645645465757575754224","data_registo":"2020-01-12T04:57:10","data_update":"2020-01-23T13:42:59","ativo":true,"log_utilizador_id":2}	2020-01-23 18:09:17
752	utilizador	UPDATE	2	{"id":3,"nome":"cuidador","password":"$2y$10$q.D7CcZEjPkGwsxJbbZTweWaA.OZ7K/YvcgPGt7UCY69GWZIujzhu","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	{"id":3,"nome":"cuidador","password":"$2y$10$BmkB16oBLFziteO/rqoYNO.wNJPTXoeRRPR0grsowu5KgPPQTGyjm","contacto":910000000,"email":"cuidador@cuidador.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-12T02:22:01","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	2020-01-23 18:11:45
753	utilizador	INSERT	2	{"id":49,"nome":"Maurício","password":"$2y$10$XNQRp4tS5ma4cYtsnKL84e1lgGRZSZBl6uDQERKdlttCN3JKb3Ueu","contacto":918291911,"email":"mauricio@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:15:04","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:15:04
754	utilizador_tipo	INSERT	2	{"id":70,"utilizador_id":49,"tipo_id":3,"data_registo":"2020-01-23T18:15:04","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:15:04
755	paciente_utilizador	INSERT	2	{"id":28,"paciente_id":20,"utilizador_id":49,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:15:04","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:15:04
756	unidade_saude	UPDATE	1	{"id":9,"nome":"US1","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"US1@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-23T18:15:46","ativo":false,"log_utilizador_id":1}	{"id":9,"nome":"US1","morada":"Rua Cidade Porto Novo, lote 225","telefone":918888888,"email":"US1@ua.pt","data_registo":"2020-01-20T18:22:26","data_update":"2020-01-22T19:38:16","ativo":true,"log_utilizador_id":1}	2020-01-23 18:15:47
757	paciente	UPDATE	2	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":4}	{"id":21,"nome":"Jane Doe","sexo":"f","data_nascimento":"2010-02-24","data_diagnostico":"2010-03-24","data_registo":"2020-01-22T23:01:33","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:22
758	paciente	UPDATE	2	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":5}	{"id":23,"nome":"Luís Rodrigues","sexo":"f","data_nascimento":"1997-01-27","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T15:31:36","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:25
759	paciente	UPDATE	2	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":6}	{"id":24,"nome":"pTest","sexo":"m","data_nascimento":"2019-12-29","data_diagnostico":"2020-01-15","data_registo":"2020-01-23T16:38:07","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:28
760	paciente	UPDATE	2	{"id":25,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":7}	{"id":25,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:31","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:36
761	paciente	UPDATE	2	{"id":26,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:45","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":9}	{"id":26,"nome":"Paciente1","sexo":"m","data_nascimento":"2020-01-05","data_diagnostico":"2020-01-10","data_registo":"2020-01-23T17:33:45","data_update":null,"ativo":false,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:38
762	paciente	UPDATE	2	{"id":27,"nome":"paciente3","sexo":"m","data_nascimento":"2020-01-12","data_diagnostico":"2020-01-13","data_registo":"2020-01-23T17:37:58","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":5}	{"id":27,"nome":"paciente3","sexo":"m","data_nascimento":"2020-01-12","data_diagnostico":"2020-01-13","data_registo":"2020-01-23T17:37:58","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:51
791	utilizador_tipo	INSERT	2	{"id":75,"utilizador_id":54,"tipo_id":3,"data_registo":"2020-01-23T18:37:59","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:59
763	paciente	UPDATE	2	{"id":28,"nome":"p4","sexo":"m","data_nascimento":"2020-01-13","data_diagnostico":"2020-01-16","data_registo":"2020-01-23T18:09:08","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":5}	{"id":28,"nome":"p4","sexo":"m","data_nascimento":"2020-01-13","data_diagnostico":"2020-01-16","data_registo":"2020-01-23T18:09:08","data_update":null,"ativo":true,"log_utilizador_id":2,"unidade_saude_id":null}	2020-01-23 18:23:53
764	utilizador	INSERT	2	{"id":50,"nome":"Maurício","password":"$2y$10$ZKNe.W/Cg.FXLjcWzKF/ZOpxVJY1Et9oWIxiuY3apXtV0x5ECUGxe","contacto":918291921,"email":"mauricio@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:24:36","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:24:36
765	utilizador_tipo	INSERT	2	{"id":71,"utilizador_id":50,"tipo_id":3,"data_registo":"2020-01-23T18:24:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:24:36
766	paciente_utilizador	INSERT	2	{"id":29,"paciente_id":20,"utilizador_id":50,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:24:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:24:36
767	paciente_utilizador	INSERT	2	{"id":30,"paciente_id":27,"utilizador_id":50,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:24:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:24:36
768	utilizador	INSERT	2	{"id":51,"nome":"Maurício","password":"$2y$10$bJqJjR7srj1naHSTu4GqI.k.MxpFrCWvK9I.nsTQZmQ3a9cs7K/Xi","contacto":918291812,"email":"mauricio@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:26:26","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:26
769	utilizador_tipo	INSERT	2	{"id":72,"utilizador_id":51,"tipo_id":3,"data_registo":"2020-01-23T18:26:26","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:26
770	paciente_utilizador	INSERT	2	{"id":31,"paciente_id":22,"utilizador_id":51,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:26:27","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:27
771	paciente_utilizador	INSERT	2	{"id":32,"paciente_id":25,"utilizador_id":51,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:26:27","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:27
772	utilizador_unidade_saude	INSERT	2	{"id":70,"utilizador_id":51,"unidade_saude_id":6,"data_registo":"2020-01-23T18:26:27","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:27
773	utilizador_unidade_saude	INSERT	2	{"id":71,"utilizador_id":51,"unidade_saude_id":7,"data_registo":"2020-01-23T18:26:27","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:26:27
774	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:30","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T17:33:00","ativo":true,"log_utilizador_id":2}	2020-01-23 18:28:30
775	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:34","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:30","ativo":true,"log_utilizador_id":1}	2020-01-23 18:28:34
776	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:37","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:34","ativo":true,"log_utilizador_id":1}	2020-01-23 18:28:38
777	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:58","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:37","ativo":true,"log_utilizador_id":1}	2020-01-23 18:28:59
778	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:30:23","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:28:58","ativo":true,"log_utilizador_id":1}	2020-01-23 18:30:23
779	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"12910292039240394039","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:30:23","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"129102920392403940394024920940294","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:30:23","ativo":true,"log_utilizador_id":1}	2020-01-23 18:31:01
780	equipamentos	UPDATE	1	{"id":4,"nome":"E4","access_token":"12910292039240394039","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:32:38","ativo":true,"log_utilizador_id":1}	{"id":4,"nome":"E4","access_token":"12910292039240394039","data_registo":"2020-01-12T04:57:38","data_update":"2020-01-23T18:30:23","ativo":true,"log_utilizador_id":1}	2020-01-23 18:32:38
781	utilizador	INSERT	2	{"id":52,"nome":"Maurício","password":"$2y$10$vACEjwA5nHf7Ghbczxuha.225w4.RvQZKrE6P4Ler6y4hGsmcw3hO","contacto":928192910,"email":"mauricio@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:36:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:36:35
782	utilizador_tipo	INSERT	2	{"id":73,"utilizador_id":52,"tipo_id":3,"data_registo":"2020-01-23T18:36:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:36:35
783	paciente_utilizador	INSERT	2	{"id":35,"paciente_id":21,"utilizador_id":52,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:36:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:36:35
784	utilizador_unidade_saude	INSERT	2	{"id":72,"utilizador_id":52,"unidade_saude_id":4,"data_registo":"2020-01-23T18:36:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:36:35
785	paciente_utilizador	INSERT	1	{"id":36,"paciente_id":24,"utilizador_id":3,"relacao_paciente_id":1,"data_registo":"0202-01-23T17:00:46","data_update":"0202-01-23T17:00:46","ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:36:38
786	utilizador	INSERT	2	{"id":53,"nome":"José José","password":"$2y$10$k3YYiZECZVXMuAAalnYeReJ095OGouVCWx4xxAR58W4thTs672bDa","contacto":123456789,"email":"josejose@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:37:11","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:11
787	utilizador_tipo	INSERT	2	{"id":74,"utilizador_id":53,"tipo_id":3,"data_registo":"2020-01-23T18:37:11","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:11
792	paciente_utilizador	INSERT	2	{"id":39,"paciente_id":28,"utilizador_id":54,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:37:59","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:59
793	paciente_utilizador	INSERT	2	{"id":40,"paciente_id":27,"utilizador_id":54,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:37:59","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:59
794	utilizador_unidade_saude	INSERT	2	{"id":74,"utilizador_id":54,"unidade_saude_id":5,"data_registo":"2020-01-23T18:37:59","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:37:59
795	equipamentos	UPDATE	2	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T18:45:14","ativo":true,"log_utilizador_id":2}	{"id":5,"nome":"E5","access_token":"324235345023059203950235235236346","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-22T19:41:31","ativo":true,"log_utilizador_id":1}	2020-01-23 18:45:14
796	equipamentos	UPDATE	2	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T18:45:24","ativo":true,"log_utilizador_id":2}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T18:45:14","ativo":true,"log_utilizador_id":2}	2020-01-23 18:45:24
797	utilizador	INSERT	2	{"id":55,"nome":"Rosa Mota","password":"$2y$10$2YE2Xrb.59WR5oP.smI8BOUJWQ2kpeAbBEuWyjbmjeyavSx4pm8ly","contacto":198291821,"email":"rosamota@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T18:49:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:35
798	utilizador_tipo	INSERT	2	{"id":76,"utilizador_id":55,"tipo_id":3,"data_registo":"2020-01-23T18:49:35","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:35
799	paciente_utilizador	INSERT	2	{"id":41,"paciente_id":21,"utilizador_id":55,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:49:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:36
800	paciente_utilizador	INSERT	2	{"id":42,"paciente_id":28,"utilizador_id":55,"relacao_paciente_id":null,"data_registo":"2020-01-23T18:49:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:36
801	utilizador_unidade_saude	INSERT	2	{"id":75,"utilizador_id":55,"unidade_saude_id":4,"data_registo":"2020-01-23T18:49:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:36
802	utilizador_unidade_saude	INSERT	2	{"id":76,"utilizador_id":55,"unidade_saude_id":5,"data_registo":"2020-01-23T18:49:36","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 18:49:36
803	utilizador	INSERT	1	{"id":56,"nome":"Luanda","password":"$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm","contacto":918291839,"email":"luanda@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T18:51:25","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:51:25
804	utilizador_unidade_saude	INSERT	1	{"id":77,"utilizador_id":56,"unidade_saude_id":6,"data_registo":"2020-01-23T18:51:25","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:51:25
805	utilizador_tipo	INSERT	1	{"id":77,"utilizador_id":56,"tipo_id":2,"data_registo":"2020-01-23T18:51:25","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:51:25
806	utilizador_unidade_saude	INSERT	1	{"id":78,"utilizador_id":56,"unidade_saude_id":4,"data_registo":"2020-01-23T18:51:58","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:51:58
807	utilizador_tipo	INSERT	1	{"id":78,"utilizador_id":56,"tipo_id":1,"data_registo":"2020-01-23T18:51:58","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:51:58
808	utilizador	UPDATE	1	{"id":56,"nome":"Luanda","password":"$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm","contacto":918291839,"email":"luanda@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:51:25","data_update":"2020-01-23T18:51:58","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":56,"nome":"Luanda","password":"$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm","contacto":918291839,"email":"luanda@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T18:51:25","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:51:58
809	utilizador_unidade_saude	INSERT	1	{"id":79,"utilizador_id":56,"unidade_saude_id":8,"data_registo":"2020-01-23T18:52:12","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:52:12
810	utilizador_tipo	UPDATE	1	{"id":78,"utilizador_id":56,"tipo_id":1,"data_registo":"2020-01-23T18:51:58","data_update":"2020-01-23T18:52:12","ativo":false,"log_utilizador_id":1}	{"id":78,"utilizador_id":56,"tipo_id":1,"data_registo":"2020-01-23T18:51:58","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:12
811	utilizador	UPDATE	1	{"id":56,"nome":"Luanda","password":"$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm","contacto":918291839,"email":"luanda@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:51:25","data_update":"2020-01-23T18:52:22","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":56,"nome":"Luanda","password":"$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm","contacto":918291839,"email":"luanda@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:51:25","data_update":"2020-01-23T18:51:58","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:23
812	utilizador_unidade_saude	UPDATE	1	{"id":77,"utilizador_id":56,"unidade_saude_id":6,"data_registo":"2020-01-23T18:51:25","data_update":"2020-01-23T18:52:22","ativo":false,"log_utilizador_id":1}	{"id":77,"utilizador_id":56,"unidade_saude_id":6,"data_registo":"2020-01-23T18:51:25","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:23
813	utilizador_unidade_saude	UPDATE	1	{"id":78,"utilizador_id":56,"unidade_saude_id":4,"data_registo":"2020-01-23T18:51:58","data_update":"2020-01-23T18:52:22","ativo":false,"log_utilizador_id":1}	{"id":78,"utilizador_id":56,"unidade_saude_id":4,"data_registo":"2020-01-23T18:51:58","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:23
814	utilizador_unidade_saude	UPDATE	1	{"id":79,"utilizador_id":56,"unidade_saude_id":8,"data_registo":"2020-01-23T18:52:12","data_update":"2020-01-23T18:52:22","ativo":false,"log_utilizador_id":1}	{"id":79,"utilizador_id":56,"unidade_saude_id":8,"data_registo":"2020-01-23T18:52:12","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:23
815	utilizador_tipo	UPDATE	1	{"id":77,"utilizador_id":56,"tipo_id":2,"data_registo":"2020-01-23T18:51:25","data_update":"2020-01-23T18:52:22","ativo":false,"log_utilizador_id":1}	{"id":77,"utilizador_id":56,"tipo_id":2,"data_registo":"2020-01-23T18:51:25","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 18:52:23
861	paciente_utilizador	INSERT	2	{"id":44,"paciente_id":28,"utilizador_id":60,"relacao_paciente_id":null,"data_registo":"2020-01-23T21:11:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
816	utilizador	INSERT	1	{"id":57,"nome":"Eugénio","password":"$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32","contacto":918930291,"email":"eugenio@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-23T18:54:06","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:54:06
817	utilizador_unidade_saude	INSERT	1	{"id":80,"utilizador_id":57,"unidade_saude_id":4,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:54:06
818	utilizador_tipo	INSERT	1	{"id":79,"utilizador_id":57,"tipo_id":2,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:54:06
819	utilizador_tipo	INSERT	1	{"id":80,"utilizador_id":57,"tipo_id":1,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:54:06
820	utilizador_tipo	INSERT	1	{"id":81,"utilizador_id":57,"tipo_id":3,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 18:54:06
821	utilizador_unidade_saude	INSERT	1	{"id":81,"utilizador_id":57,"unidade_saude_id":8,"data_registo":"2020-01-23T19:02:40","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 19:02:40
822	utilizador_tipo	UPDATE	1	{"id":81,"utilizador_id":57,"tipo_id":3,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:02:40","ativo":false,"log_utilizador_id":1}	{"id":81,"utilizador_id":57,"tipo_id":3,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:02:40
823	utilizador	UPDATE	1	{"id":57,"nome":"Eugénio","password":"$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32","contacto":918930291,"email":"eugenio@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:02:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":57,"nome":"Eugénio","password":"$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32","contacto":918930291,"email":"eugenio@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-23T18:54:06","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:02:51
824	utilizador_tipo	UPDATE	1	{"id":80,"utilizador_id":57,"tipo_id":1,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:03:06","ativo":false,"log_utilizador_id":1}	{"id":80,"utilizador_id":57,"tipo_id":1,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:03:06
825	utilizador	UPDATE	1	{"id":57,"nome":"Eugénio","password":"$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32","contacto":918930291,"email":"eugenio@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:03:17","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":57,"nome":"Eugénio","password":"$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32","contacto":918930291,"email":"eugenio@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:02:51","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:03:17
826	utilizador_unidade_saude	UPDATE	1	{"id":80,"utilizador_id":57,"unidade_saude_id":4,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:03:17","ativo":false,"log_utilizador_id":1}	{"id":80,"utilizador_id":57,"unidade_saude_id":4,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:03:17
827	utilizador_unidade_saude	UPDATE	1	{"id":81,"utilizador_id":57,"unidade_saude_id":8,"data_registo":"2020-01-23T19:02:40","data_update":"2020-01-23T19:03:17","ativo":false,"log_utilizador_id":1}	{"id":81,"utilizador_id":57,"unidade_saude_id":8,"data_registo":"2020-01-23T19:02:40","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:03:17
828	utilizador_tipo	UPDATE	1	{"id":79,"utilizador_id":57,"tipo_id":2,"data_registo":"2020-01-23T18:54:06","data_update":"2020-01-23T19:03:17","ativo":false,"log_utilizador_id":1}	{"id":79,"utilizador_id":57,"tipo_id":2,"data_registo":"2020-01-23T18:54:06","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 19:03:17
829	utilizador	INSERT	1	{"id":58,"nome":"Tiago Silva","password":"$2y$10$AoenQQy/hpa3Pmx..66d0OMuMAxb5m12a31cINJ01w8rkfRFiEIOu","contacto":910283929,"email":"tiago@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T20:10:20","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:10:20
830	utilizador_unidade_saude	INSERT	1	{"id":82,"utilizador_id":58,"unidade_saude_id":6,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:10:20
831	utilizador_unidade_saude	INSERT	1	{"id":83,"utilizador_id":58,"unidade_saude_id":4,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:10:20
832	utilizador_tipo	INSERT	1	{"id":82,"utilizador_id":58,"tipo_id":2,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:10:20
833	utilizador_tipo	INSERT	1	{"id":83,"utilizador_id":58,"tipo_id":1,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:10:20
834	utilizador	INSERT	1	{"id":59,"nome":"Maria Adelaide","password":"$2y$10$NmdDBtxtXZ7IFEadlEdsJuv4zyt/3f7fJ1h7oxkmWb7ph3bA1yF2a","contacto":928391929,"email":"maria_adelaide@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T20:21:32","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:21:32
835	utilizador_unidade_saude	INSERT	1	{"id":84,"utilizador_id":59,"unidade_saude_id":4,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:21:32
836	utilizador_tipo	INSERT	1	{"id":84,"utilizador_id":59,"tipo_id":2,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:21:32
837	utilizador_tipo	INSERT	1	{"id":85,"utilizador_id":59,"tipo_id":1,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:21:32
838	utilizador	UPDATE	1	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"naosei@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-23T20:23:39","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":13,"nome":"Ui ui","password":"$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe","contacto":923293028,"email":"naosei@hotmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-18T18:39:23","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:23:39
839	utilizador_unidade_saude	UPDATE	1	{"id":33,"utilizador_id":13,"unidade_saude_id":6,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-23T20:23:39","ativo":false,"log_utilizador_id":1}	{"id":33,"utilizador_id":13,"unidade_saude_id":6,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:23:39
840	utilizador_tipo	UPDATE	1	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-23T20:23:39","ativo":false,"log_utilizador_id":1}	{"id":31,"utilizador_id":13,"tipo_id":3,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-19T02:41:25","ativo":true,"log_utilizador_id":1}	2020-01-23 20:23:39
841	utilizador_tipo	UPDATE	1	{"id":29,"utilizador_id":13,"tipo_id":2,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-23T20:23:39","ativo":false,"log_utilizador_id":1}	{"id":29,"utilizador_id":13,"tipo_id":2,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:23:39
842	utilizador_tipo	UPDATE	1	{"id":30,"utilizador_id":13,"tipo_id":1,"data_registo":"2020-01-15T15:16:45","data_update":"2020-01-23T20:23:39","ativo":false,"log_utilizador_id":1}	{"id":30,"utilizador_id":13,"tipo_id":1,"data_registo":"2020-01-15T15:16:45","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:23:39
843	utilizador	UPDATE	1	{"id":59,"nome":"Maria Adelaide","password":"$2y$10$NmdDBtxtXZ7IFEadlEdsJuv4zyt/3f7fJ1h7oxkmWb7ph3bA1yF2a","contacto":928391929,"email":"maria_adelaide@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T20:21:32","data_update":"2020-01-23T20:31:52","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":59,"nome":"Maria Adelaide","password":"$2y$10$NmdDBtxtXZ7IFEadlEdsJuv4zyt/3f7fJ1h7oxkmWb7ph3bA1yF2a","contacto":928391929,"email":"maria_adelaide@hotmail.com","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-23T20:21:32","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:31:53
844	utilizador_unidade_saude	UPDATE	1	{"id":84,"utilizador_id":59,"unidade_saude_id":4,"data_registo":"2020-01-23T20:21:32","data_update":"2020-01-23T20:31:52","ativo":false,"log_utilizador_id":1}	{"id":84,"utilizador_id":59,"unidade_saude_id":4,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:31:53
845	utilizador_tipo	UPDATE	1	{"id":84,"utilizador_id":59,"tipo_id":2,"data_registo":"2020-01-23T20:21:32","data_update":"2020-01-23T20:31:52","ativo":false,"log_utilizador_id":1}	{"id":84,"utilizador_id":59,"tipo_id":2,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:31:53
846	utilizador_tipo	UPDATE	1	{"id":85,"utilizador_id":59,"tipo_id":1,"data_registo":"2020-01-23T20:21:32","data_update":"2020-01-23T20:31:52","ativo":false,"log_utilizador_id":1}	{"id":85,"utilizador_id":59,"tipo_id":1,"data_registo":"2020-01-23T20:21:32","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:31:53
847	utilizador	UPDATE	1	{"id":58,"nome":"Tiago Silva","password":"$2y$10$AoenQQy/hpa3Pmx..66d0OMuMAxb5m12a31cINJ01w8rkfRFiEIOu","contacto":910283929,"email":"tiago@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T20:10:20","data_update":"2020-01-23T20:34:16","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":58,"nome":"Tiago Silva","password":"$2y$10$AoenQQy/hpa3Pmx..66d0OMuMAxb5m12a31cINJ01w8rkfRFiEIOu","contacto":910283929,"email":"tiago@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-23T20:10:20","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:34:17
848	utilizador_unidade_saude	UPDATE	1	{"id":82,"utilizador_id":58,"unidade_saude_id":6,"data_registo":"2020-01-23T20:10:20","data_update":"2020-01-23T20:34:16","ativo":false,"log_utilizador_id":1}	{"id":82,"utilizador_id":58,"unidade_saude_id":6,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:34:17
849	utilizador_unidade_saude	UPDATE	1	{"id":83,"utilizador_id":58,"unidade_saude_id":4,"data_registo":"2020-01-23T20:10:20","data_update":"2020-01-23T20:34:16","ativo":false,"log_utilizador_id":1}	{"id":83,"utilizador_id":58,"unidade_saude_id":4,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:34:17
850	utilizador_tipo	UPDATE	1	{"id":82,"utilizador_id":58,"tipo_id":2,"data_registo":"2020-01-23T20:10:20","data_update":"2020-01-23T20:34:16","ativo":false,"log_utilizador_id":1}	{"id":82,"utilizador_id":58,"tipo_id":2,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:34:17
851	utilizador_tipo	UPDATE	1	{"id":83,"utilizador_id":58,"tipo_id":1,"data_registo":"2020-01-23T20:10:20","data_update":"2020-01-23T20:34:16","ativo":false,"log_utilizador_id":1}	{"id":83,"utilizador_id":58,"tipo_id":1,"data_registo":"2020-01-23T20:10:20","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:34:17
852	utilizador_tipo	INSERT	1	{"id":86,"utilizador_id":30,"tipo_id":3,"data_registo":"2020-01-23T20:35:10","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:35:10
853	utilizador	UPDATE	1	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":2,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-23T20:35:10","remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":30,"nome":"TesteMaravilha","password":"$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq","contacto":918291918,"email":"testemaravilha@ua.pt","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-19T05:41:01","data_update":"2020-01-19T15:16:57","remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:35:10
854	utilizador_unidade_saude	UPDATE	1	{"id":49,"utilizador_id":44,"unidade_saude_id":9,"data_registo":"2020-01-23T02:05:51","data_update":"2020-01-23T20:35:48","ativo":false,"log_utilizador_id":1}	{"id":49,"utilizador_id":44,"unidade_saude_id":9,"data_registo":"2020-01-23T02:05:51","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 20:35:48
855	utilizador_unidade_saude	INSERT	1	{"id":85,"utilizador_id":44,"unidade_saude_id":8,"data_registo":"2020-01-23T20:35:48","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:35:48
856	utilizador_tipo	INSERT	1	{"id":87,"utilizador_id":44,"tipo_id":3,"data_registo":"2020-01-23T20:35:48","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 20:35:48
857	nota	INSERT	2	{"id":15,"nome":"Nota A","descricao":"Informações relevantes","paciente_id":20,"data_registo":"2020-01-23T20:39:47","log_utilizador_id":2,"ativo":true,"criado_por":0}	\N	2020-01-23 20:39:47
858	utilizador	INSERT	2	{"id":60,"nome":"Roberto","password":"$2y$10$E0zZlG/uNryyVTJH7kYgGOh/SuQUisRKs8b4uKQ8TiZLf7LvpX3B2","contacto":928192983,"email":"roberto45@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T21:11:09","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
859	utilizador_tipo	INSERT	2	{"id":88,"utilizador_id":60,"tipo_id":3,"data_registo":"2020-01-23T21:11:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
860	paciente_utilizador	INSERT	2	{"id":43,"paciente_id":21,"utilizador_id":60,"relacao_paciente_id":null,"data_registo":"2020-01-23T21:11:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
862	utilizador_unidade_saude	INSERT	2	{"id":86,"utilizador_id":60,"unidade_saude_id":4,"data_registo":"2020-01-23T21:11:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
863	utilizador_unidade_saude	INSERT	2	{"id":87,"utilizador_id":60,"unidade_saude_id":5,"data_registo":"2020-01-23T21:11:09","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:09
864	utilizador	INSERT	2	{"id":61,"nome":"Telma Silva","password":"$2y$10$6hSc.NmWL1p9AEL1Gb0W8.TbrfY2LtNUJktudqQiLiM4iv/GpWXPa","contacto":912839380,"email":"telma_silva@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-23T21:11:47","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:47
865	utilizador_tipo	INSERT	2	{"id":89,"utilizador_id":61,"tipo_id":3,"data_registo":"2020-01-23T21:11:47","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:47
866	paciente_utilizador	INSERT	2	{"id":45,"paciente_id":27,"utilizador_id":61,"relacao_paciente_id":null,"data_registo":"2020-01-23T21:11:47","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:47
867	utilizador_unidade_saude	INSERT	2	{"id":88,"utilizador_id":61,"unidade_saude_id":5,"data_registo":"2020-01-23T21:11:47","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-23 21:11:47
868	lembrete	INSERT	2	{"id":6,"nome":"Alerta 1","descricao":null,"paciente_id":20,"alerta":"2020-01-29T12:34:00","data_registo":"2020-01-23T21:28:32","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:28:32
869	lembrete	INSERT	2	{"id":8,"nome":"Alerta 1","descricao":null,"paciente_id":21,"alerta":"2020-01-29T11:23:00","data_registo":"2020-01-23T21:35:17","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:35:17
870	lembrete	INSERT	2	{"id":10,"nome":"Alerta 1","descricao":null,"paciente_id":21,"alerta":"2020-01-29T11:23:00","data_registo":"2020-01-23T21:36:09","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:36:09
871	lembrete	INSERT	2	{"id":12,"nome":"Alerta 1","descricao":null,"paciente_id":21,"alerta":"2020-01-29T03:45:00","data_registo":"2020-01-23T21:42:25","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:42:25
872	lembrete	INSERT	2	{"id":14,"nome":"Alerta 1","descricao":null,"paciente_id":21,"alerta":"2020-01-30T03:23:00","data_registo":"2020-01-23T21:43:25","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:43:25
873	lembrete	INSERT	2	{"id":16,"nome":"Alerta 2","descricao":null,"paciente_id":28,"alerta":"2020-01-31T12:36:00","data_registo":"2020-01-23T21:45:19","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 21:45:19
874	lembrete	INSERT	2	{"id":18,"nome":"Alerta 3","descricao":null,"paciente_id":28,"alerta":"2020-02-07T12:22:00","data_registo":"2020-01-23T22:02:28","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 22:02:28
875	lembrete	INSERT	2	{"id":20,"nome":"Alerta 4","descricao":null,"paciente_id":28,"alerta":"2020-01-30T09:23:00","data_registo":"2020-01-23T22:03:35","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 22:03:35
876	lembrete	INSERT	2	{"id":21,"nome":"Alerta 4","descricao":null,"paciente_id":28,"alerta":"2020-01-30T09:23:00","data_registo":"2020-01-23T22:03:40","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 22:03:40
877	lembrete	INSERT	2	{"id":22,"nome":"Alerta 4","descricao":null,"paciente_id":28,"alerta":"2020-01-30T09:23:00","data_registo":"2020-01-23T22:04:17","log_utilizador_id":2,"ativo":true}	\N	2020-01-23 22:04:17
878	utilizador	UPDATE	14	{"id":33,"nome":"testCuida","password":"$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6","contacto":911114533,"email":"testCuida@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":14}	{"id":33,"nome":"testCuida","password":"$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6","contacto":911114531,"email":"testCuida@ua.pt","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-20T21:58:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":14}	2020-01-23 23:13:36
879	utilizador	INSERT	1	{"id":62,"nome":"test","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"test@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 23:14:38
880	utilizador_unidade_saude	INSERT	1	{"id":89,"utilizador_id":62,"unidade_saude_id":6,"data_registo":"2020-01-23T23:14:38","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 23:14:38
881	utilizador_tipo	INSERT	1	{"id":90,"utilizador_id":62,"tipo_id":2,"data_registo":"2020-01-23T23:14:38","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 23:14:38
882	utilizador_tipo	INSERT	1	{"id":91,"utilizador_id":62,"tipo_id":3,"data_registo":"2020-01-23T23:14:38","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-23 23:14:38
883	equipamentos	UPDATE	62	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T23:15:19","ativo":true,"log_utilizador_id":62}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T18:45:24","ativo":true,"log_utilizador_id":2}	2020-01-23 23:15:20
884	utilizador	UPDATE	1	{"id":62,"nome":"utilizador","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"test@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":62,"nome":"test","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"test@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 23:17:10
885	utilizador	UPDATE	1	{"id":62,"nome":"utilizador","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"utilizador@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":62,"nome":"utilizador","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"test@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 23:17:15
886	utilizador	UPDATE	1	{"id":62,"nome":"utilizador","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114532,"email":"utilizador@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	{"id":62,"nome":"utilizador","password":"$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa","contacto":911114531,"email":"utilizador@test.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-23T23:14:38","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-23 23:17:19
887	equipamentos	UPDATE	62	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T23:20:20","ativo":true,"log_utilizador_id":62}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T23:15:19","ativo":true,"log_utilizador_id":62}	2020-01-23 23:20:21
888	utilizador	INSERT	1	{"id":63,"nome":"Beto Silva","password":"$2y$10$D6PdDfLrXU64ZKqT/Lt89e05iUrgkcRL.JKDVsOOgCXpo97NYhD36","contacto":918291824,"email":"beto@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-24T01:16:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:16:12
889	utilizador_unidade_saude	INSERT	1	{"id":90,"utilizador_id":63,"unidade_saude_id":6,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:16:12
890	utilizador_unidade_saude	INSERT	1	{"id":91,"utilizador_id":63,"unidade_saude_id":4,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:16:12
891	utilizador_tipo	INSERT	1	{"id":92,"utilizador_id":63,"tipo_id":2,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:16:12
892	utilizador	UPDATE	1	{"id":63,"nome":"Beto Silva","password":"$2y$10$D6PdDfLrXU64ZKqT/Lt89e05iUrgkcRL.JKDVsOOgCXpo97NYhD36","contacto":918291824,"email":"beto@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-24T01:16:12","data_update":"2020-01-24T01:16:24","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":63,"nome":"Beto Silva","password":"$2y$10$D6PdDfLrXU64ZKqT/Lt89e05iUrgkcRL.JKDVsOOgCXpo97NYhD36","contacto":918291824,"email":"beto@ua.pt","email_verified_at":null,"funcao_id":1,"data_registo":"2020-01-24T01:16:12","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:16:25
893	utilizador_unidade_saude	UPDATE	1	{"id":90,"utilizador_id":63,"unidade_saude_id":6,"data_registo":"2020-01-24T01:16:12","data_update":"2020-01-24T01:16:24","ativo":false,"log_utilizador_id":1}	{"id":90,"utilizador_id":63,"unidade_saude_id":6,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:16:25
894	utilizador_unidade_saude	UPDATE	1	{"id":91,"utilizador_id":63,"unidade_saude_id":4,"data_registo":"2020-01-24T01:16:12","data_update":"2020-01-24T01:16:24","ativo":false,"log_utilizador_id":1}	{"id":91,"utilizador_id":63,"unidade_saude_id":4,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:16:25
895	utilizador_tipo	UPDATE	1	{"id":92,"utilizador_id":63,"tipo_id":2,"data_registo":"2020-01-24T01:16:12","data_update":"2020-01-24T01:16:24","ativo":false,"log_utilizador_id":1}	{"id":92,"utilizador_id":63,"tipo_id":2,"data_registo":"2020-01-24T01:16:12","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:16:25
896	utilizador	INSERT	1	{"id":64,"nome":"Angela","password":"$2y$10$byRtFa2v7rgzu2dvaz4JJOfbav/abfTTc52sFvi5jNIiBGNfX5qGy","contacto":917283854,"email":"angela@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-24T01:18:18","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
897	utilizador_unidade_saude	INSERT	1	{"id":92,"utilizador_id":64,"unidade_saude_id":6,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
898	utilizador_unidade_saude	INSERT	1	{"id":93,"utilizador_id":64,"unidade_saude_id":4,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
899	utilizador_unidade_saude	INSERT	1	{"id":94,"utilizador_id":64,"unidade_saude_id":8,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
900	utilizador_tipo	INSERT	1	{"id":93,"utilizador_id":64,"tipo_id":2,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
901	utilizador_tipo	INSERT	1	{"id":94,"utilizador_id":64,"tipo_id":1,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:18:18
902	utilizador	UPDATE	1	{"id":64,"nome":"Angela","password":"$2y$10$byRtFa2v7rgzu2dvaz4JJOfbav/abfTTc52sFvi5jNIiBGNfX5qGy","contacto":917283854,"email":"angela@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","remember_token":null,"ativo":false,"log_utilizador_id":1}	{"id":64,"nome":"Angela","password":"$2y$10$byRtFa2v7rgzu2dvaz4JJOfbav/abfTTc52sFvi5jNIiBGNfX5qGy","contacto":917283854,"email":"angela@ua.pt","email_verified_at":null,"funcao_id":3,"data_registo":"2020-01-24T01:18:18","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
903	utilizador_unidade_saude	UPDATE	1	{"id":92,"utilizador_id":64,"unidade_saude_id":6,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","ativo":false,"log_utilizador_id":1}	{"id":92,"utilizador_id":64,"unidade_saude_id":6,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
904	utilizador_unidade_saude	UPDATE	1	{"id":93,"utilizador_id":64,"unidade_saude_id":4,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","ativo":false,"log_utilizador_id":1}	{"id":93,"utilizador_id":64,"unidade_saude_id":4,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
905	utilizador_unidade_saude	UPDATE	1	{"id":94,"utilizador_id":64,"unidade_saude_id":8,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","ativo":false,"log_utilizador_id":1}	{"id":94,"utilizador_id":64,"unidade_saude_id":8,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
906	utilizador_tipo	UPDATE	1	{"id":93,"utilizador_id":64,"tipo_id":2,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","ativo":false,"log_utilizador_id":1}	{"id":93,"utilizador_id":64,"tipo_id":2,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
907	utilizador_tipo	UPDATE	1	{"id":94,"utilizador_id":64,"tipo_id":1,"data_registo":"2020-01-24T01:18:18","data_update":"2020-01-24T01:18:54","ativo":false,"log_utilizador_id":1}	{"id":94,"utilizador_id":64,"tipo_id":1,"data_registo":"2020-01-24T01:18:18","data_update":null,"ativo":true,"log_utilizador_id":1}	2020-01-24 01:18:54
908	equipamentos	INSERT	1	{"id":17,"nome":"E65","access_token":"PA6VKYZhkU6OFhWbP1m7","data_registo":"2020-01-24T01:19:22","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 01:19:22
909	utilizador	INSERT	2	{"id":65,"nome":"Filipa Marques","password":"$2y$10$tcvGOX23/heqUZk/bcF7tesj1SIEVbPrBYjUvWE8eXFABSjR4urIG","contacto":928192839,"email":"filipa_marques@hotmail.com","email_verified_at":null,"funcao_id":null,"data_registo":"2020-01-24T01:20:54","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-24 01:20:54
910	utilizador_tipo	INSERT	2	{"id":95,"utilizador_id":65,"tipo_id":3,"data_registo":"2020-01-24T01:20:54","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-24 01:20:54
911	paciente_utilizador	INSERT	2	{"id":46,"paciente_id":28,"utilizador_id":65,"relacao_paciente_id":null,"data_registo":"2020-01-24T01:20:54","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-24 01:20:54
912	utilizador_unidade_saude	INSERT	2	{"id":95,"utilizador_id":65,"unidade_saude_id":5,"data_registo":"2020-01-24T01:20:54","data_update":null,"ativo":true,"log_utilizador_id":2}	\N	2020-01-24 01:20:54
913	utilizador	INSERT	1	{"id":66,"nome":"psaude_01","password":"$2y$10$xk2UUrauHvFn5f/xxcaFj.FUSFcVh4QzmfLbuHNekj4H5rZPRTC.2","contacto":912345678,"email":"a@a.pe","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-24T09:26:35","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:26:35
914	utilizador_unidade_saude	INSERT	1	{"id":96,"utilizador_id":66,"unidade_saude_id":6,"data_registo":"2020-01-24T09:26:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:26:35
915	utilizador_tipo	INSERT	1	{"id":96,"utilizador_id":66,"tipo_id":2,"data_registo":"2020-01-24T09:26:35","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:26:35
916	equipamentos	UPDATE	66	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:27:50","ativo":true,"log_utilizador_id":66}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-23T23:20:20","ativo":true,"log_utilizador_id":62}	2020-01-24 09:27:51
917	equipamentos	UPDATE	66	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:28:00","ativo":true,"log_utilizador_id":66}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:27:50","ativo":true,"log_utilizador_id":66}	2020-01-24 09:28:01
918	equipamentos	UPDATE	66	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:29:40","ativo":false,"log_utilizador_id":66}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:28:00","ativo":true,"log_utilizador_id":66}	2020-01-24 09:29:40
919	equipamentos	UPDATE	66	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:29:40","ativo":true,"log_utilizador_id":66}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:29:40","ativo":false,"log_utilizador_id":66}	2020-01-24 09:30:12
920	equipamentos	UPDATE	66	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:30:24","ativo":true,"log_utilizador_id":66}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:29:40","ativo":true,"log_utilizador_id":66}	2020-01-24 09:30:25
921	utilizador	INSERT	1	{"id":67,"nome":"p_saude_04","password":"$2y$10$PknnCuoIl3GtDJtEpPBma.BXdSw2FLxsq9pcgQzApR/GKHo9UL.0K","contacto":912345670,"email":"psaud@gmail.com","email_verified_at":null,"funcao_id":4,"data_registo":"2020-01-24T09:45:14","data_update":null,"remember_token":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:45:14
922	utilizador_unidade_saude	INSERT	1	{"id":97,"utilizador_id":67,"unidade_saude_id":4,"data_registo":"2020-01-24T09:45:14","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:45:14
923	utilizador_tipo	INSERT	1	{"id":97,"utilizador_id":67,"tipo_id":2,"data_registo":"2020-01-24T09:45:14","data_update":null,"ativo":true,"log_utilizador_id":1}	\N	2020-01-24 09:45:14
924	equipamentos	UPDATE	67	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:46:01","ativo":true,"log_utilizador_id":67}	{"id":5,"nome":"E5","access_token":"32423534502305920395","data_registo":"2020-01-12T04:57:52","data_update":"2020-01-24T09:30:24","ativo":true,"log_utilizador_id":66}	2020-01-24 09:46:02
\.


--
-- TOC entry 2475 (class 0 OID 104235)
-- Dependencies: 187
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2014_10_12_000000_create_utilizador_table	1
2	2014_10_12_100000_create_password_resets_table	1
3	2019_08_19_000000_create_failed_jobs_table	1
4	2019_12_04_152526_create_tipos_table	1
5	2019_12_04_152600_create_utilizador__tipo_table	1
6	2019_12_04_195216_create_equipamentos_table	1
7	2019_12_15_155554_create_logs_table	1
8	2019_12_15_155641_create_musculo_table	1
9	2019_12_15_155700_create_paciente_musculo_table	1
10	2019_12_15_155723_create_tipo_alerta_table	1
11	2019_12_15_155741_create_descricao_alerta_table	1
12	2019_12_15_155753_create_doenca_table	1
13	2019_12_15_155804_create_doenca_paciente_table	1
14	2019_12_15_155818_create_lembrete_table	1
15	2019_12_15_155828_create_alerta_table	1
16	2019_12_15_155838_create_paciente_table	1
17	2019_12_15_155850_create_nota_table	1
18	2019_12_15_160101_create_historico_configuracoes_table	1
19	2019_12_15_160159_create_paciente_utilizador_table	1
20	2019_12_15_160217_create_relacao_paciente_table	1
21	2019_12_15_160232_create_pedido_ajuda_table	1
22	2019_12_15_160248_create_historico_valores_table	1
23	2019_12_15_160353_create_unidade_saude_table	1
24	2019_12_15_160405_create_funcao_table	1
25	2019_12_15_160433_create_utilizador_unidade_saude_table	1
26	2019_12_15_205102_fk_paciente_musculo	1
27	2019_12_15_205156_fk_lembrete	1
28	2019_12_15_205305_fk_doenca_paciente	1
29	2019_12_15_205356_fk_alerta	1
30	2019_12_15_205819_fk_paciente_utilizador	1
31	2019_12_15_210009_fk_pedido_ajuda	1
32	2019_12_15_210104_fk_historico_valores	1
33	2019_12_15_210239_fk_utilizador	1
34	2019_12_15_210506_fk_utilizador_unidade_saude	1
35	2019_12_30_162157_fk_nota	1
\.


--
-- TOC entry 2490 (class 0 OID 104325)
-- Dependencies: 202
-- Data for Name: musculo; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.musculo (id, nome, descricao) FROM stdin;
1	Bochecha Direita	\N
2	Bochecha Esquerda	\N
\.


--
-- TOC entry 2508 (class 0 OID 104418)
-- Dependencies: 220
-- Data for Name: nota; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.nota (id, nome, descricao, paciente_id, data_registo, log_utilizador_id, ativo, criado_por) FROM stdin;
7	Nota A	Informações variadas	19	2020-01-23 00:20:52	2	f	2
2	Nota A	Informações variadas	19	2020-01-23 00:08:37	2	f	2
3	Nota A	Informações variadas	19	2020-01-23 00:11:06	2	f	2
4	Nota A	Informações variadas	19	2020-01-23 00:12:06	2	f	2
6	Nota A	Informações variadas	19	2020-01-23 00:19:33	2	f	2
8	Nota A	Informações variadas	19	2020-01-23 00:22:15	2	f	2
9	Nota X	Info	19	2020-01-23 00:30:18	2	f	2
10	Nota A	Informações relevantes	2	2020-01-23 13:27:03	2	t	2
11	Nota B	Informações relvantes B	2	2020-01-23 14:06:42	2	t	0
12	Nota C	Informações relevantes C	19	2020-01-23 14:12:25	2	t	0
13	Mal estar	Paciente com muitas dificuldades	23	2020-01-23 15:38:56	2	t	0
14	teste	testeeee	22	2020-01-23 16:53:59	2	t	0
15	Nota A	Informações relevantes	20	2020-01-23 20:39:47	2	t	0
\.


--
-- TOC entry 2506 (class 0 OID 104407)
-- Dependencies: 218
-- Data for Name: paciente; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.paciente (id, nome, sexo, data_nascimento, data_diagnostico, data_registo, data_update, ativo, log_utilizador_id, unidade_saude_id) FROM stdin;
2	Maria	f	2020-01-08	2020-01-17	2020-01-12 04:49:05	\N	f	4	8
19	João Luís	m	2020-01-01	2020-01-15	2020-01-22 20:30:05	\N	f	2	9
21	Jane Doe	f	2010-02-24	2010-03-24	2020-01-22 23:01:33	\N	t	2	4
23	Luís Rodrigues	f	1997-01-27	2020-01-15	2020-01-23 15:31:36	\N	f	2	5
24	pTest	m	2019-12-29	2020-01-15	2020-01-23 16:38:07	\N	f	2	6
25	Paciente1	m	2020-01-05	2020-01-10	2020-01-23 17:33:31	\N	t	2	7
26	Paciente1	m	2020-01-05	2020-01-10	2020-01-23 17:33:45	\N	f	2	9
27	paciente3	m	2020-01-12	2020-01-13	2020-01-23 17:37:58	\N	t	2	5
28	p4	m	2020-01-13	2020-01-16	2020-01-23 18:09:08	\N	t	2	5
1	Roberto	m	1999-10-10	2010-12-09	2020-01-12 04:48:35	\N	f	2	5
3	Jose	m	1970-01-01	1970-01-01	2020-01-12 04:53:34	\N	f	6	6
4	Chico	f	2000-03-10	2007-05-18	2020-01-12 04:54:02	\N	f	7	5
20	John Doe	m	1970-06-17	1970-11-26	2020-01-22 22:49:13	\N	t	2	9
22	John Doe Junior	m	2011-02-16	2020-01-08	2020-01-22 23:10:09	\N	t	2	6
\.


--
-- TOC entry 2492 (class 0 OID 104336)
-- Dependencies: 204
-- Data for Name: paciente_musculo; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.paciente_musculo (id, paciente_id, musculo_id, data_registo) FROM stdin;
3	1	2	2020-01-22 22:38:29
5	3	2	2020-01-22 22:39:15
7	2	1	2020-01-22 22:47:40
8	20	1	2020-01-22 22:49:13
9	21	1	2020-01-22 23:01:33
10	22	2	2020-01-22 23:10:09
37	19	2	2020-01-22 23:59:28
38	19	1	2020-01-22 23:59:28
46	23	1	2020-01-23 15:37:51
48	24	1	2020-01-23 16:38:42
50	26	1	2020-01-23 17:33:46
52	25	1	2020-01-23 17:37:39
53	27	2	2020-01-23 17:37:58
54	28	2	2020-01-23 18:09:09
55	28	1	2020-01-23 18:09:09
\.


--
-- TOC entry 2512 (class 0 OID 104438)
-- Dependencies: 224
-- Data for Name: paciente_utilizador; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.paciente_utilizador (id, paciente_id, utilizador_id, relacao_paciente_id, data_registo, data_update, ativo, log_utilizador_id) FROM stdin;
2	2	7	3	2020-01-12 05:05:06	\N	t	3
4	3	10	2	2020-01-12 05:05:40	\N	t	3
6	4	12	4	2020-01-12 05:06:11	\N	t	2
7	3	12	4	2020-01-18 01:06:50	\N	t	3
12	3	29	4	2020-01-18 16:58:39	\N	t	1
14	2	9	3	2020-01-19 15:19:44	2020-01-19 15:19:56	t	1
3	1	9	1	2020-01-12 05:05:20	2020-01-19 15:19:56	t	1
13	1	30	3	2020-01-19 15:16:29	2020-01-19 15:16:57	t	1
15	2	32	\N	2020-01-19 18:31:21	\N	t	1
16	3	32	\N	2020-01-19 18:31:21	\N	t	1
17	4	33	\N	2020-01-20 21:58:12	\N	t	2
22	22	39	\N	2020-01-23 01:15:38	\N	t	31
23	2	39	\N	2020-01-23 01:15:38	\N	t	31
24	21	47	\N	2020-01-23 02:58:24	\N	t	2
25	19	47	\N	2020-01-23 02:58:24	\N	t	2
26	22	37	\N	2020-01-23 17:00:33	\N	t	3
27	4	2	\N	2020-01-23 17:00:45	\N	t	2
35	21	52	\N	2020-01-23 18:36:35	\N	t	2
36	24	3	1	0202-01-23 17:00:46	0202-01-23 17:00:46	t	1
37	21	53	\N	2020-01-23 18:37:12	\N	t	2
39	28	54	\N	2020-01-23 18:37:59	\N	t	2
40	27	54	\N	2020-01-23 18:37:59	\N	t	2
41	21	55	\N	2020-01-23 18:49:36	\N	t	2
42	28	55	\N	2020-01-23 18:49:36	\N	t	2
43	21	60	\N	2020-01-23 21:11:09	\N	t	2
44	28	60	\N	2020-01-23 21:11:09	\N	t	2
45	27	61	\N	2020-01-23 21:11:47	\N	t	2
46	28	65	\N	2020-01-24 01:20:54	\N	t	2
\.


--
-- TOC entry 2478 (class 0 OID 104254)
-- Dependencies: 190
-- Data for Name: password_resets; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.password_resets (email, token, created_at) FROM stdin;
\.


--
-- TOC entry 2516 (class 0 OID 104457)
-- Dependencies: 228
-- Data for Name: pedido_ajuda; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.pedido_ajuda (id, nome, descricao, resolvido, paciente_id, utilizador_id, data_registo) FROM stdin;
\.


--
-- TOC entry 2514 (class 0 OID 104446)
-- Dependencies: 226
-- Data for Name: relacao_paciente; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.relacao_paciente (id, nome) FROM stdin;
2	Mãe
1	Pai
3	Filho
4	Cunhado
5	Tio
6	Avó
\.


--
-- TOC entry 2494 (class 0 OID 104344)
-- Dependencies: 206
-- Data for Name: tipo_alerta; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.tipo_alerta (id, nome) FROM stdin;
1	Chamada
2	Urgência
\.


--
-- TOC entry 2482 (class 0 OID 104275)
-- Dependencies: 194
-- Data for Name: tipos; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.tipos (id, nome, created_at, updated_at) FROM stdin;
1	admin	\N	\N
2	profissional de saude	\N	\N
3	cuidador	\N	\N
\.


--
-- TOC entry 2520 (class 0 OID 104476)
-- Dependencies: 232
-- Data for Name: unidade_saude; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.unidade_saude (id, nome, morada, telefone, email, data_registo, data_update, ativo, log_utilizador_id) FROM stdin;
6	US2	Rua 456	918291029	US2@hotmail.com	2020-01-12 02:29:08	2020-01-22 19:38:36	t	1
4	US3	Rua Engenheiro José Bastos Xavier	918291829	US3@ua.pt	2020-01-12 02:27:02	2020-01-22 19:39:11	t	1
8	US4	Rua de teste	918291918	US4@ua.pt	2020-01-12 02:34:12	2020-01-22 19:39:38	t	1
5	US5	Avenida	192839291	US5@hotmail.com	2020-01-12 02:28:13	2020-01-22 19:40:11	t	1
7	U6	Rua Torta	91829291	U6@ua.pt	2020-01-12 02:31:45	2020-01-12 02:32:08	f	1
9	US1	Rua Cidade Porto Novo, lote 225	918888888	US1@ua.pt	2020-01-20 18:22:26	2020-01-23 18:15:46	f	1
\.


--
-- TOC entry 2477 (class 0 OID 104243)
-- Dependencies: 189
-- Data for Name: utilizador; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.utilizador (id, nome, password, contacto, email, email_verified_at, funcao_id, data_registo, data_update, remember_token, ativo, log_utilizador_id) FROM stdin;
55	Rosa Mota	$2y$10$2YE2Xrb.59WR5oP.smI8BOUJWQ2kpeAbBEuWyjbmjeyavSx4pm8ly	198291821	rosamota@ua.pt	\N	\N	2020-01-23 18:49:35	\N	\N	t	2
29	sdvsdvdsv	$2y$10$T3dOQYkAUz1.rx1j/pO4A.dBdUQi/skR0fjEs/jVvDkkES3OjSLR.	912839392	vkoefek@ua.pt	\N	\N	2020-01-18 16:58:39	\N	\N	t	1
31	Graça	$2y$10$EICKaf4VhEmTslNmPlzSXu01ouNGHkzWP/mithFaeBTMy88qMZp/u	917283828	graca@ua.pt	\N	3	2020-01-19 15:24:11	\N	\N	t	1
33	testCuida	$2y$10$iP9vuvp1ywpz5YXyR4M.o.OpFQ.wlWWUlZLwTXgdsRkI3AygNJKK6	911114533	testCuida@ua.pt	\N	\N	2020-01-20 21:58:12	\N	\N	t	14
56	Luanda	$2y$10$gDukXqVArUOJRobpo5fO/.KdScmmOsP0yPnhqymbXKkX.iac7.frm	918291839	luanda@hotmail.com	\N	4	2020-01-23 18:51:25	2020-01-23 18:52:22	\N	f	1
7	Graça	$2y$10$eNAkF5AQvKqAJNINaIULl.j2GFaX2qIB9EuHa7iO3f7rJRHNX1N8q	917283822	pimmm@ua.pt	\N	4	2020-01-12 03:21:27	\N	\N	t	1
40	José Eduardo	$2y$10$.AQAr.GNNcj2s1FHIzkYoelaApf8DGmEl6mma0ympmVc6iO83uzBu	918291021	jose@hotmail.com	\N	2	2020-01-23 01:44:22	2020-01-23 01:55:39	\N	f	1
2	psaude	$2y$10$JB9GcZ7DDtfrqPl4LzfX1ew/TIIGiW6wAlr1BoBWNmkhyFMIFeri6	918201921	psaude@psaude.com	\N	2	2020-01-12 02:21:55	2020-01-12 04:27:41	\N	t	1
41	Miguel Alves	$2y$10$V0kzu.60XnMXPEt92wYLe.RvGVuAJ7ivvTw2MAWYS4QUJFynB56gy	918291920	miguel@hotmail.com	\N	3	2020-01-23 01:57:03	2020-01-23 01:57:17	\N	t	1
42	Ivo Ruivo	$2y$10$yqhCRvH7T2EH2MOqXehFO.SUwof0ZlnjRwzmbKZuxwaTZdMEcHpBK	917283853	ivo@ua.pt	\N	1	2020-01-23 01:58:00	\N	\N	t	1
8	pessoa1	$2y$10$8KyMdGWWL45pS0kvW//S0uaNCLEqFSNUquszjaV7cJxVy/F/ZWjH6	918291922	pessoa1@ua.pt	\N	2	2020-01-12 03:25:35	2020-01-12 04:35:16	\N	f	1
44	Exemplo	$2y$10$Tjyjpz8NpBEycajYFfIY8.p8ohc8A77DstazcwwRD.NweP6h77nLy	918291905	exemplo@ua.pt	\N	2	2020-01-23 02:05:51	\N	\N	t	1
45	Exemplo2	$2y$10$7SeEG6T6OGJKgVXOZ6.zQeClAu08BESf3x6ySMGkaDyEwjgw7SzN.	819281929	exemplo@live.pt	\N	3	2020-01-23 02:06:28	\N	\N	t	1
12	TesteRegisto	$2y$10$Qb/tLCxQxy95REvhag0LfOX1Ym9WHYfE0wn7XdK0PGAeUF2EoswMG	917283829	registo@ua.pt	\N	2	2020-01-12 04:17:42	2020-01-19 05:41:53	\N	f	1
11	pessoa4	$2y$10$c91ySf3D6VmXjsgwc3vdaOTvlbwkDWo3rwQU260e2rT78aE9sIvSa	928010291	pessoa4@gmail.com	\N	4	2020-01-12 03:34:58	2020-01-19 02:10:22	\N	t	1
10	pessoa3	$2y$10$FWOzapfvkFZLe780ikqDMeANUdJ7ChnnyKAhcc2TOaEfOosQepu5K	910291831	pessoa3@ua.pt	\N	2	2020-01-12 03:34:16	2020-01-12 04:17:51	\N	t	1
46	Exemplo3	$2y$10$Y5IOW757Lbk7tvVUYc8JMuuzTJAD.M0mRgwhi9eS9PyYbi2Aka0uK	918010391	exemplo3@hotmail.com	\N	4	2020-01-23 02:07:32	2020-01-23 02:08:09	\N	f	1
9	pessoa2	$2y$10$.0GANN7jmYPK9LBaDF1Y1O/cff.Ecxmoki6ZFNT6MbFK3U1Sr4Dp2	918291023	pessoa2@ua.pt	\N	4	2020-01-12 03:33:35	2020-01-19 15:19:56	\N	t	1
14	psaude	1202392	923849382	pimmmm@ua.pt	\N	2	2020-01-18 00:48:38	\N	\N	t	1
47	Maria Júlia	$2y$10$yduf79llHutaypfX8clL2OOHgz1LLUIZnD31PeixhlFxZV7gaLTTO	233435322	maria@ua.pt	\N	\N	2020-01-23 02:58:24	\N	\N	t	2
37	melhor_cuidador	$2y$10$qAAcehKFZFmrQqyDKhW/q.x336.qM8.AH7XM0uZqBFJ0r7bWZHwbm	912839399	melhor_cuidador@ua.pt	\N	\N	2020-01-22 12:43:56	\N	\N	t	2
32	coisas	$2y$10$09yEfZhQo91Ccqm.0L5PHej0KnytSyxa.9Fvwei/0I68IfNqjOehy	918291011	coisas@ua.pt	\N	\N	2020-01-19 18:31:21	\N	\N	t	14
64	Angela	$2y$10$byRtFa2v7rgzu2dvaz4JJOfbav/abfTTc52sFvi5jNIiBGNfX5qGy	917283854	angela@ua.pt	\N	3	2020-01-24 01:18:18	2020-01-24 01:18:54	\N	f	1
38	Roberto Carlos	$2y$10$u/7fK//8gG/R1g8/BNFeGekyDGIViSk4OsHe2ZWGK0D30opQ2TksC	918291823	roberto@ua.pt	\N	\N	2020-01-23 01:13:55	\N	\N	t	31
39	Maria Albuquerque	$2y$10$u8bntzZxsUTYxB/5UPeG9.Gi9ql0Kkql1KzUQk/ZlvKpDvh/czl5u	918291821	maria@hotmail.com	\N	\N	2020-01-23 01:15:38	\N	\N	t	31
48	Monte Carlos	$2y$10$.EX4e.Mkzas/pD8O5triM.GrSxOe.9mjCKvTgR5nHYXZcYATpIL8W	911192019	monte@ua.pt	\N	2	2020-01-23 03:06:40	2020-01-23 03:09:27	\N	f	1
65	Filipa Marques	$2y$10$tcvGOX23/heqUZk/bcF7tesj1SIEVbPrBYjUvWE8eXFABSjR4urIG	928192839	filipa_marques@hotmail.com	\N	\N	2020-01-24 01:20:54	\N	\N	t	2
57	Eugénio	$2y$10$T7dRtqxziT/mlRy2KG.iE.ZT4pLAkPR9M0OAvZ1SrpKghcqGWzi32	918930291	eugenio@ua.pt	\N	4	2020-01-23 18:54:06	2020-01-23 19:03:17	\N	f	1
1	admin	$2y$10$tVWAXI.wHK9grr7DV9WZjeJM76N50nFm4dmUvavI7SE2RItEH5Wd6	\N	admin@admin.com	\N	\N	2020-01-12 02:29:37	\N	\N	t	2
3	cuidador	$2y$10$q.D7CcZEjPkGwsxJbbZTweWaA.OZ7K/YvcgPGt7UCY69GWZIujzhu	910000000	cuidador@cuidador.com	\N	\N	2020-01-12 02:22:01	\N	\N	t	2
52	Maurício	$2y$10$vACEjwA5nHf7Ghbczxuha.225w4.RvQZKrE6P4Ler6y4hGsmcw3hO	928192910	mauricio@ua.pt	\N	\N	2020-01-23 18:36:35	\N	\N	t	2
53	José José	$2y$10$k3YYiZECZVXMuAAalnYeReJ095OGouVCWx4xxAR58W4thTs672bDa	123456789	josejose@ua.pt	\N	\N	2020-01-23 18:37:11	\N	\N	t	2
54	Filipa	$2y$10$pVEsMxRfPyAPXV1XqysZGeuiYsIkCzPZ9pDpfw5KaknrT0lNdym26	918291928	filipa@hotmail.com	\N	\N	2020-01-23 18:37:58	\N	\N	t	2
13	Ui ui	$2y$10$GHJt9daZwAfz7k7gmZ42WOMwAm4vDyNuHmRMLiAO5Kemu3SuENyPe	923293028	naosei@hotmail.com	\N	4	2020-01-15 15:16:45	2020-01-23 20:23:39	\N	f	1
59	Maria Adelaide	$2y$10$NmdDBtxtXZ7IFEadlEdsJuv4zyt/3f7fJ1h7oxkmWb7ph3bA1yF2a	928391929	maria_adelaide@hotmail.com	\N	1	2020-01-23 20:21:32	2020-01-23 20:31:52	\N	f	1
58	Tiago Silva	$2y$10$AoenQQy/hpa3Pmx..66d0OMuMAxb5m12a31cINJ01w8rkfRFiEIOu	910283929	tiago@ua.pt	\N	2	2020-01-23 20:10:20	2020-01-23 20:34:16	\N	f	1
30	TesteMaravilha	$2y$10$ucXrtZoBAwwggdIsf3672u2MOO51iy2s.K4fr68214iT0tCXnNGpq	918291918	testemaravilha@ua.pt	\N	2	2020-01-19 05:41:01	2020-01-23 20:35:10	\N	t	1
60	Roberto	$2y$10$E0zZlG/uNryyVTJH7kYgGOh/SuQUisRKs8b4uKQ8TiZLf7LvpX3B2	928192983	roberto45@ua.pt	\N	\N	2020-01-23 21:11:09	\N	\N	t	2
61	Telma Silva	$2y$10$6hSc.NmWL1p9AEL1Gb0W8.TbrfY2LtNUJktudqQiLiM4iv/GpWXPa	912839380	telma_silva@ua.pt	\N	\N	2020-01-23 21:11:47	\N	\N	t	2
62	utilizador	$2y$10$Fat9cHM8GYN8O7iA670BTu4XQYROIPSL/KLFaHodMOwxqt/PgHifa	911114532	utilizador@test.com	\N	4	2020-01-23 23:14:38	\N	\N	t	1
63	Beto Silva	$2y$10$D6PdDfLrXU64ZKqT/Lt89e05iUrgkcRL.JKDVsOOgCXpo97NYhD36	918291824	beto@ua.pt	\N	1	2020-01-24 01:16:12	2020-01-24 01:16:24	\N	f	1
66	psaude_01	$2y$10$xk2UUrauHvFn5f/xxcaFj.FUSFcVh4QzmfLbuHNekj4H5rZPRTC.2	912345678	a@a.pe	\N	4	2020-01-24 09:26:35	\N	\N	t	1
67	p_saude_04	$2y$10$PknnCuoIl3GtDJtEpPBma.BXdSw2FLxsq9pcgQzApR/GKHo9UL.0K	912345670	psaud@gmail.com	\N	4	2020-01-24 09:45:14	\N	\N	t	1
\.


--
-- TOC entry 2484 (class 0 OID 104283)
-- Dependencies: 196
-- Data for Name: utilizador_tipo; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.utilizador_tipo (id, utilizador_id, tipo_id, data_registo, data_update, ativo, log_utilizador_id) FROM stdin;
89	61	3	2020-01-23 21:11:47	\N	t	2
90	62	2	2020-01-23 23:14:38	\N	t	1
91	62	3	2020-01-23 23:14:38	\N	t	1
92	63	2	2020-01-24 01:16:12	2020-01-24 01:16:24	f	1
17	9	1	2020-01-12 03:33:35	2020-01-19 05:40:16	f	1
39	29	3	2020-01-18 16:58:39	\N	t	1
93	64	2	2020-01-24 01:18:18	2020-01-24 01:18:54	f	1
26	12	2	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
94	64	1	2020-01-24 01:18:18	2020-01-24 01:18:54	f	1
27	12	1	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
28	12	3	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
14	8	2	2020-01-12 03:25:35	2020-01-12 04:35:16	t	1
15	8	1	2020-01-12 03:25:35	2020-01-12 04:35:16	t	1
23	8	3	2020-01-12 03:57:34	2020-01-12 04:35:16	t	1
95	65	3	2020-01-24 01:20:54	\N	t	2
21	11	3	2020-01-12 03:34:58	2020-01-19 15:14:38	f	1
22	11	1	2020-01-12 03:56:37	2020-01-19 15:14:38	f	1
96	66	2	2020-01-24 09:26:35	\N	t	1
97	67	2	2020-01-24 09:45:14	\N	t	1
16	9	2	2020-01-12 03:33:35	2020-01-19 15:19:57	t	1
40	9	3	2020-01-19 02:10:38	2020-01-19 05:40:08	t	1
41	30	2	2020-01-19 05:41:01	2020-01-19 15:16:57	t	1
42	31	2	2020-01-19 15:24:11	\N	t	1
43	32	3	2020-01-19 18:31:21	\N	t	1
1	1	1	2020-01-12 02:23:01	\N	t	2
5	3	3	2020-01-12 02:23:19	\N	t	2
44	33	3	2020-01-20 21:58:12	\N	t	2
20	11	2	2020-01-12 03:34:58	2020-01-12 04:16:11	t	1
18	10	2	2020-01-12 03:34:16	2020-01-12 04:17:51	t	1
19	10	1	2020-01-12 03:34:16	2020-01-12 04:17:51	t	1
4	2	2	2020-01-12 02:23:15	2020-01-12 04:27:41	t	1
48	37	3	2020-01-22 12:43:56	\N	t	31
49	38	3	2020-01-23 01:13:56	\N	t	31
50	39	3	2020-01-23 01:15:38	\N	t	31
52	40	1	2020-01-23 01:45:11	2020-01-23 01:45:22	f	1
51	40	2	2020-01-23 01:44:22	2020-01-23 01:55:39	f	1
53	40	3	2020-01-23 01:45:22	2020-01-23 01:55:39	f	1
54	41	2	2020-01-23 01:57:03	\N	t	1
55	41	1	2020-01-23 01:57:17	\N	t	1
56	41	3	2020-01-23 01:57:17	\N	t	1
57	42	2	2020-01-23 01:58:00	\N	t	1
59	44	2	2020-01-23 02:05:51	\N	t	1
60	44	1	2020-01-23 02:05:51	\N	t	1
61	45	2	2020-01-23 02:06:28	\N	t	1
62	45	3	2020-01-23 02:06:28	\N	t	1
65	46	3	2020-01-23 02:07:32	2020-01-23 02:07:48	f	1
64	46	1	2020-01-23 02:07:32	2020-01-23 02:08:02	f	1
63	46	2	2020-01-23 02:07:32	2020-01-23 02:08:09	f	1
66	47	3	2020-01-23 02:58:24	\N	t	2
67	48	2	2020-01-23 03:06:40	2020-01-23 03:09:27	f	1
68	48	3	2020-01-23 03:06:40	2020-01-23 03:09:27	f	1
69	2	3	2020-01-23 17:44:30	\N	t	2
73	52	3	2020-01-23 18:36:35	\N	t	2
74	53	3	2020-01-23 18:37:11	\N	t	2
75	54	3	2020-01-23 18:37:59	\N	t	2
76	55	3	2020-01-23 18:49:35	\N	t	2
78	56	1	2020-01-23 18:51:58	2020-01-23 18:52:12	f	1
77	56	2	2020-01-23 18:51:25	2020-01-23 18:52:22	f	1
81	57	3	2020-01-23 18:54:06	2020-01-23 19:02:40	f	1
80	57	1	2020-01-23 18:54:06	2020-01-23 19:03:06	f	1
79	57	2	2020-01-23 18:54:06	2020-01-23 19:03:17	f	1
31	13	3	2020-01-15 15:16:45	2020-01-23 20:23:39	f	1
29	13	2	2020-01-15 15:16:45	2020-01-23 20:23:39	f	1
30	13	1	2020-01-15 15:16:45	2020-01-23 20:23:39	f	1
84	59	2	2020-01-23 20:21:32	2020-01-23 20:31:52	f	1
85	59	1	2020-01-23 20:21:32	2020-01-23 20:31:52	f	1
82	58	2	2020-01-23 20:10:20	2020-01-23 20:34:16	f	1
83	58	1	2020-01-23 20:10:20	2020-01-23 20:34:16	f	1
86	30	3	2020-01-23 20:35:10	\N	t	1
87	44	3	2020-01-23 20:35:48	\N	t	1
88	60	3	2020-01-23 21:11:09	\N	t	2
\.


--
-- TOC entry 2524 (class 0 OID 104498)
-- Dependencies: 236
-- Data for Name: utilizador_unidade_saude; Type: TABLE DATA; Schema: public; Owner: ptdw-2019-gr1
--

COPY public.utilizador_unidade_saude (id, utilizador_id, unidade_saude_id, data_registo, data_update, ativo, log_utilizador_id) FROM stdin;
45	41	5	2020-01-23 01:57:03	\N	t	1
28	8	8	2020-01-12 03:57:34	2020-01-12 04:35:16	f	1
18	8	5	2020-01-12 03:25:35	2020-01-12 04:35:16	f	1
17	8	6	2020-01-12 03:25:35	2020-01-12 04:35:16	f	1
46	42	6	2020-01-23 01:58:00	\N	t	1
47	42	4	2020-01-23 01:58:00	\N	t	1
50	44	6	2020-01-23 02:05:51	\N	t	1
51	45	6	2020-01-23 02:06:28	\N	t	1
52	46	6	2020-01-23 02:07:32	2020-01-23 02:08:02	f	1
53	46	5	2020-01-23 02:07:32	2020-01-23 02:08:09	f	1
57	29	5	2020-01-23 15:50:10	\N	t	2
59	32	6	2020-01-23 15:50:30	\N	t	3
60	33	9	2020-01-23 15:50:50	\N	t	3
62	47	9	2020-01-23 15:51:33	\N	t	3
64	37	4	2020-01-23 16:52:23	\N	t	3
65	48	9	2020-01-23 16:52:34	\N	t	2
66	48	6	2020-01-23 16:52:43	\N	t	2
67	48	4	2020-01-23 16:52:53	\N	t	5
72	52	4	2020-01-23 18:36:35	\N	t	2
73	53	4	2020-01-23 18:37:12	\N	t	2
74	54	5	2020-01-23 18:37:59	\N	t	2
75	55	4	2020-01-23 18:49:36	\N	t	2
76	55	5	2020-01-23 18:49:36	\N	t	2
77	56	6	2020-01-23 18:51:25	2020-01-23 18:52:22	f	1
24	11	4	2020-01-12 03:34:58	2020-01-12 04:16:11	t	1
26	11	6	2020-01-12 03:56:37	2020-01-12 04:16:11	t	1
27	11	5	2020-01-12 03:56:37	2020-01-12 04:16:11	t	1
22	10	6	2020-01-12 03:34:16	2020-01-12 04:17:51	t	1
23	10	5	2020-01-12 03:34:16	2020-01-12 04:17:51	t	1
13	2	4	2020-01-12 03:24:17	2020-01-12 04:27:41	t	1
15	2	5	2020-01-12 03:24:31	2020-01-12 04:27:41	t	1
78	56	4	2020-01-23 18:51:58	2020-01-23 18:52:22	f	1
29	2	8	2020-01-12 03:58:16	2020-01-12 04:27:41	t	1
79	56	8	2020-01-23 18:52:12	2020-01-23 18:52:22	f	1
30	12	6	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
31	12	5	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
32	12	8	2020-01-12 04:17:42	2020-01-19 05:41:53	t	1
80	57	4	2020-01-23 18:54:06	2020-01-23 19:03:17	f	1
81	57	8	2020-01-23 19:02:40	2020-01-23 19:03:17	f	1
33	13	6	2020-01-15 15:16:45	2020-01-23 20:23:39	f	1
84	59	4	2020-01-23 20:21:32	2020-01-23 20:31:52	f	1
82	58	6	2020-01-23 20:10:20	2020-01-23 20:34:16	f	1
20	9	5	2020-01-12 03:33:35	2020-01-12 03:59:01	f	1
83	58	4	2020-01-23 20:10:20	2020-01-23 20:34:16	f	1
21	9	8	2020-01-12 03:33:35	2020-01-19 15:19:56	f	1
34	30	5	2020-01-19 05:41:01	2020-01-19 15:16:57	t	1
35	30	8	2020-01-19 05:41:01	2020-01-19 15:16:57	t	1
19	9	6	2020-01-12 03:33:35	2020-01-19 15:19:56	t	1
36	31	6	2020-01-19 15:24:11	\N	t	1
49	44	9	2020-01-23 02:05:51	2020-01-23 20:35:48	f	1
37	31	5	2020-01-19 15:24:11	\N	t	1
39	14	6	2020-01-22 17:10:20	\N	t	2
85	44	8	2020-01-23 20:35:48	\N	t	1
41	39	6	2020-01-23 01:23:35	\N	t	2
42	40	6	2020-01-23 01:44:22	2020-01-23 01:55:27	f	1
44	40	9	2020-01-23 01:55:27	2020-01-23 01:55:39	f	1
86	60	4	2020-01-23 21:11:09	\N	t	2
87	60	5	2020-01-23 21:11:09	\N	t	2
88	61	5	2020-01-23 21:11:47	\N	t	2
89	62	6	2020-01-23 23:14:38	\N	t	1
90	63	6	2020-01-24 01:16:12	2020-01-24 01:16:24	f	1
91	63	4	2020-01-24 01:16:12	2020-01-24 01:16:24	f	1
92	64	6	2020-01-24 01:18:18	2020-01-24 01:18:54	f	1
93	64	4	2020-01-24 01:18:18	2020-01-24 01:18:54	f	1
94	64	8	2020-01-24 01:18:18	2020-01-24 01:18:54	f	1
95	65	5	2020-01-24 01:20:54	\N	t	2
96	66	6	2020-01-24 09:26:35	\N	t	1
97	67	4	2020-01-24 09:45:14	\N	t	1
\.


--
-- TOC entry 2556 (class 0 OID 0)
-- Dependencies: 215
-- Name: alerta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.alerta_id_seq', 16, true);


--
-- TOC entry 2557 (class 0 OID 0)
-- Dependencies: 207
-- Name: descricao_alerta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.descricao_alerta_id_seq', 1, false);


--
-- TOC entry 2558 (class 0 OID 0)
-- Dependencies: 209
-- Name: doenca_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.doenca_id_seq', 2, true);


--
-- TOC entry 2559 (class 0 OID 0)
-- Dependencies: 211
-- Name: doenca_paciente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.doenca_paciente_id_seq', 46, true);


--
-- TOC entry 2560 (class 0 OID 0)
-- Dependencies: 197
-- Name: equipamentos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.equipamentos_id_seq', 17, true);


--
-- TOC entry 2561 (class 0 OID 0)
-- Dependencies: 191
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- TOC entry 2562 (class 0 OID 0)
-- Dependencies: 233
-- Name: funcao_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.funcao_id_seq', 4, true);


--
-- TOC entry 2563 (class 0 OID 0)
-- Dependencies: 221
-- Name: historico_configuracoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.historico_configuracoes_id_seq', 43, true);


--
-- TOC entry 2564 (class 0 OID 0)
-- Dependencies: 229
-- Name: historico_valores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.historico_valores_id_seq', 22438, true);


--
-- TOC entry 2565 (class 0 OID 0)
-- Dependencies: 213
-- Name: lembrete_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.lembrete_id_seq', 22, true);


--
-- TOC entry 2566 (class 0 OID 0)
-- Dependencies: 199
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.logs_id_seq', 924, true);


--
-- TOC entry 2567 (class 0 OID 0)
-- Dependencies: 186
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.migrations_id_seq', 35, true);


--
-- TOC entry 2568 (class 0 OID 0)
-- Dependencies: 201
-- Name: musculo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.musculo_id_seq', 2, true);


--
-- TOC entry 2569 (class 0 OID 0)
-- Dependencies: 219
-- Name: nota_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.nota_id_seq', 15, true);


--
-- TOC entry 2570 (class 0 OID 0)
-- Dependencies: 217
-- Name: paciente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.paciente_id_seq', 28, true);


--
-- TOC entry 2571 (class 0 OID 0)
-- Dependencies: 203
-- Name: paciente_musculo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.paciente_musculo_id_seq', 55, true);


--
-- TOC entry 2572 (class 0 OID 0)
-- Dependencies: 223
-- Name: paciente_utilizador_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.paciente_utilizador_id_seq', 46, true);


--
-- TOC entry 2573 (class 0 OID 0)
-- Dependencies: 227
-- Name: pedido_ajuda_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.pedido_ajuda_id_seq', 1, false);


--
-- TOC entry 2574 (class 0 OID 0)
-- Dependencies: 225
-- Name: relacao_paciente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.relacao_paciente_id_seq', 6, true);


--
-- TOC entry 2575 (class 0 OID 0)
-- Dependencies: 205
-- Name: tipo_alerta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.tipo_alerta_id_seq', 1, false);


--
-- TOC entry 2576 (class 0 OID 0)
-- Dependencies: 193
-- Name: tipos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.tipos_id_seq', 3, true);


--
-- TOC entry 2577 (class 0 OID 0)
-- Dependencies: 231
-- Name: unidade_saude_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.unidade_saude_id_seq', 9, true);


--
-- TOC entry 2578 (class 0 OID 0)
-- Dependencies: 188
-- Name: utilizador_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.utilizador_id_seq', 67, true);


--
-- TOC entry 2579 (class 0 OID 0)
-- Dependencies: 195
-- Name: utilizador_tipo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.utilizador_tipo_id_seq', 97, true);


--
-- TOC entry 2580 (class 0 OID 0)
-- Dependencies: 235
-- Name: utilizador_unidade_saude_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ptdw-2019-gr1
--

SELECT pg_catalog.setval('public.utilizador_unidade_saude_id_seq', 97, true);


--
-- TOC entry 2302 (class 2606 OID 104404)
-- Name: alerta alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.alerta
    ADD CONSTRAINT alerta_pkey PRIMARY KEY (id);


--
-- TOC entry 2294 (class 2606 OID 104363)
-- Name: descricao_alerta descricao_alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.descricao_alerta
    ADD CONSTRAINT descricao_alerta_pkey PRIMARY KEY (id);


--
-- TOC entry 2298 (class 2606 OID 104382)
-- Name: doenca_paciente doenca_paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca_paciente
    ADD CONSTRAINT doenca_paciente_pkey PRIMARY KEY (id);


--
-- TOC entry 2296 (class 2606 OID 104374)
-- Name: doenca doenca_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca
    ADD CONSTRAINT doenca_pkey PRIMARY KEY (id);


--
-- TOC entry 2284 (class 2606 OID 104311)
-- Name: equipamentos equipamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.equipamentos
    ADD CONSTRAINT equipamentos_pkey PRIMARY KEY (id);


--
-- TOC entry 2278 (class 2606 OID 104272)
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 2320 (class 2606 OID 104495)
-- Name: funcao funcao_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.funcao
    ADD CONSTRAINT funcao_pkey PRIMARY KEY (id);


--
-- TOC entry 2308 (class 2606 OID 104435)
-- Name: historico_configuracoes historico_configuracoes_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_configuracoes
    ADD CONSTRAINT historico_configuracoes_pkey PRIMARY KEY (id);


--
-- TOC entry 2316 (class 2606 OID 104473)
-- Name: historico_valores historico_valores_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_valores
    ADD CONSTRAINT historico_valores_pkey PRIMARY KEY (id);


--
-- TOC entry 2300 (class 2606 OID 104393)
-- Name: lembrete lembrete_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.lembrete
    ADD CONSTRAINT lembrete_pkey PRIMARY KEY (id);


--
-- TOC entry 2286 (class 2606 OID 104322)
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- TOC entry 2271 (class 2606 OID 104240)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 2288 (class 2606 OID 104333)
-- Name: musculo musculo_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.musculo
    ADD CONSTRAINT musculo_pkey PRIMARY KEY (id);


--
-- TOC entry 2306 (class 2606 OID 104426)
-- Name: nota nota_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.nota
    ADD CONSTRAINT nota_pkey PRIMARY KEY (id);


--
-- TOC entry 2290 (class 2606 OID 104341)
-- Name: paciente_musculo paciente_musculo_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_musculo
    ADD CONSTRAINT paciente_musculo_pkey PRIMARY KEY (id);


--
-- TOC entry 2304 (class 2606 OID 104415)
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (id);


--
-- TOC entry 2310 (class 2606 OID 104443)
-- Name: paciente_utilizador paciente_utilizador_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_utilizador
    ADD CONSTRAINT paciente_utilizador_pkey PRIMARY KEY (id);


--
-- TOC entry 2314 (class 2606 OID 104465)
-- Name: pedido_ajuda pedido_ajuda_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.pedido_ajuda
    ADD CONSTRAINT pedido_ajuda_pkey PRIMARY KEY (id);


--
-- TOC entry 2312 (class 2606 OID 104454)
-- Name: relacao_paciente relacao_paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.relacao_paciente
    ADD CONSTRAINT relacao_paciente_pkey PRIMARY KEY (id);


--
-- TOC entry 2292 (class 2606 OID 104352)
-- Name: tipo_alerta tipo_alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.tipo_alerta
    ADD CONSTRAINT tipo_alerta_pkey PRIMARY KEY (id);


--
-- TOC entry 2280 (class 2606 OID 104280)
-- Name: tipos tipos_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.tipos
    ADD CONSTRAINT tipos_pkey PRIMARY KEY (id);


--
-- TOC entry 2318 (class 2606 OID 104484)
-- Name: unidade_saude unidade_saude_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.unidade_saude
    ADD CONSTRAINT unidade_saude_pkey PRIMARY KEY (id);


--
-- TOC entry 2273 (class 2606 OID 104253)
-- Name: utilizador utilizador_email_unique; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador
    ADD CONSTRAINT utilizador_email_unique UNIQUE (email);


--
-- TOC entry 2275 (class 2606 OID 104251)
-- Name: utilizador utilizador_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador
    ADD CONSTRAINT utilizador_pkey PRIMARY KEY (id);


--
-- TOC entry 2282 (class 2606 OID 104289)
-- Name: utilizador_tipo utilizador_tipo_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_tipo
    ADD CONSTRAINT utilizador_tipo_pkey PRIMARY KEY (id);


--
-- TOC entry 2322 (class 2606 OID 104503)
-- Name: utilizador_unidade_saude utilizador_unidade_saude_pkey; Type: CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_unidade_saude
    ADD CONSTRAINT utilizador_unidade_saude_pkey PRIMARY KEY (id);


--
-- TOC entry 2276 (class 1259 OID 104260)
-- Name: password_resets_email_index; Type: INDEX; Schema: public; Owner: ptdw-2019-gr1
--

CREATE INDEX password_resets_email_index ON public.password_resets USING btree (email);


--
-- TOC entry 2347 (class 2620 OID 104600)
-- Name: equipamentos logs_equipamentos; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_equipamentos AFTER INSERT OR UPDATE ON public.equipamentos FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2348 (class 2620 OID 104608)
-- Name: lembrete logs_lembrete; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_lembrete AFTER INSERT OR UPDATE ON public.lembrete FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2350 (class 2620 OID 104607)
-- Name: nota logs_nota; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_nota AFTER INSERT OR UPDATE ON public.nota FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2349 (class 2620 OID 104601)
-- Name: paciente logs_paciente; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_paciente AFTER INSERT OR UPDATE ON public.paciente FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2351 (class 2620 OID 104602)
-- Name: paciente_utilizador logs_paciente_utilizador; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_paciente_utilizador AFTER INSERT OR UPDATE ON public.paciente_utilizador FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2352 (class 2620 OID 104606)
-- Name: unidade_saude logs_unidade_saude; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_unidade_saude AFTER INSERT OR UPDATE ON public.unidade_saude FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2345 (class 2620 OID 104603)
-- Name: utilizador logs_utilizador; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_utilizador AFTER INSERT OR UPDATE ON public.utilizador FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2346 (class 2620 OID 104604)
-- Name: utilizador_tipo logs_utilizador_tipo; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_utilizador_tipo AFTER INSERT OR UPDATE ON public.utilizador_tipo FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2353 (class 2620 OID 104605)
-- Name: utilizador_unidade_saude logs_utilizador_unidade_saude; Type: TRIGGER; Schema: public; Owner: ptdw-2019-gr1
--

CREATE TRIGGER logs_utilizador_unidade_saude AFTER INSERT OR UPDATE ON public.utilizador_unidade_saude FOR EACH ROW EXECUTE PROCEDURE public.audit_trigger();


--
-- TOC entry 2331 (class 2606 OID 104529)
-- Name: alerta alerta_descricao_alerta_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.alerta
    ADD CONSTRAINT alerta_descricao_alerta_id_foreign FOREIGN KEY (descricao_alerta_id) REFERENCES public.descricao_alerta(id);


--
-- TOC entry 2332 (class 2606 OID 104534)
-- Name: alerta alerta_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.alerta
    ADD CONSTRAINT alerta_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2333 (class 2606 OID 104539)
-- Name: alerta alerta_tipo_alerta_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.alerta
    ADD CONSTRAINT alerta_tipo_alerta_id_foreign FOREIGN KEY (tipo_alerta_id) REFERENCES public.tipo_alerta(id);


--
-- TOC entry 2329 (class 2606 OID 104524)
-- Name: doenca_paciente doenca_paciente_doenca_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca_paciente
    ADD CONSTRAINT doenca_paciente_doenca_id_foreign FOREIGN KEY (doenca_id) REFERENCES public.doenca(id);


--
-- TOC entry 2328 (class 2606 OID 104519)
-- Name: doenca_paciente doenca_paciente_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.doenca_paciente
    ADD CONSTRAINT doenca_paciente_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2342 (class 2606 OID 104574)
-- Name: historico_valores historico_valores_equipamento_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_valores
    ADD CONSTRAINT historico_valores_equipamento_id_foreign FOREIGN KEY (equipamento_id) REFERENCES public.equipamentos(id);


--
-- TOC entry 2341 (class 2606 OID 104569)
-- Name: historico_valores historico_valores_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.historico_valores
    ADD CONSTRAINT historico_valores_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2330 (class 2606 OID 104514)
-- Name: lembrete lembrete_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.lembrete
    ADD CONSTRAINT lembrete_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2335 (class 2606 OID 104594)
-- Name: nota nota_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.nota
    ADD CONSTRAINT nota_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2327 (class 2606 OID 104509)
-- Name: paciente_musculo paciente_musculo_musculo_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_musculo
    ADD CONSTRAINT paciente_musculo_musculo_id_foreign FOREIGN KEY (musculo_id) REFERENCES public.musculo(id);


--
-- TOC entry 2326 (class 2606 OID 104504)
-- Name: paciente_musculo paciente_musculo_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_musculo
    ADD CONSTRAINT paciente_musculo_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2334 (class 2606 OID 105179)
-- Name: paciente paciente_unidade_saude; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_unidade_saude FOREIGN KEY (unidade_saude_id) REFERENCES public.unidade_saude(id);


--
-- TOC entry 2336 (class 2606 OID 104544)
-- Name: paciente_utilizador paciente_utilizador_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_utilizador
    ADD CONSTRAINT paciente_utilizador_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2338 (class 2606 OID 104554)
-- Name: paciente_utilizador paciente_utilizador_relacao_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_utilizador
    ADD CONSTRAINT paciente_utilizador_relacao_paciente_id_foreign FOREIGN KEY (relacao_paciente_id) REFERENCES public.relacao_paciente(id);


--
-- TOC entry 2337 (class 2606 OID 104549)
-- Name: paciente_utilizador paciente_utilizador_utilizador_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.paciente_utilizador
    ADD CONSTRAINT paciente_utilizador_utilizador_id_foreign FOREIGN KEY (utilizador_id) REFERENCES public.utilizador(id);


--
-- TOC entry 2339 (class 2606 OID 104559)
-- Name: pedido_ajuda pedido_ajuda_paciente_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.pedido_ajuda
    ADD CONSTRAINT pedido_ajuda_paciente_id_foreign FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 2340 (class 2606 OID 104564)
-- Name: pedido_ajuda pedido_ajuda_utilizador_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.pedido_ajuda
    ADD CONSTRAINT pedido_ajuda_utilizador_id_foreign FOREIGN KEY (utilizador_id) REFERENCES public.utilizador(id);


--
-- TOC entry 2323 (class 2606 OID 104579)
-- Name: utilizador utilizador_funcao_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador
    ADD CONSTRAINT utilizador_funcao_id_foreign FOREIGN KEY (funcao_id) REFERENCES public.funcao(id);


--
-- TOC entry 2325 (class 2606 OID 104295)
-- Name: utilizador_tipo utilizador_tipo_tipo_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_tipo
    ADD CONSTRAINT utilizador_tipo_tipo_id_foreign FOREIGN KEY (tipo_id) REFERENCES public.tipos(id);


--
-- TOC entry 2324 (class 2606 OID 104290)
-- Name: utilizador_tipo utilizador_tipo_utilizador_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_tipo
    ADD CONSTRAINT utilizador_tipo_utilizador_id_foreign FOREIGN KEY (utilizador_id) REFERENCES public.utilizador(id);


--
-- TOC entry 2344 (class 2606 OID 104589)
-- Name: utilizador_unidade_saude utilizador_unidade_saude_unidade_saude_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_unidade_saude
    ADD CONSTRAINT utilizador_unidade_saude_unidade_saude_id_foreign FOREIGN KEY (unidade_saude_id) REFERENCES public.unidade_saude(id);


--
-- TOC entry 2343 (class 2606 OID 104584)
-- Name: utilizador_unidade_saude utilizador_unidade_saude_utilizador_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: ptdw-2019-gr1
--

ALTER TABLE ONLY public.utilizador_unidade_saude
    ADD CONSTRAINT utilizador_unidade_saude_utilizador_id_foreign FOREIGN KEY (utilizador_id) REFERENCES public.utilizador(id);


-- Completed on 2020-01-30 18:36:53 WET

--
-- PostgreSQL database dump complete
--

