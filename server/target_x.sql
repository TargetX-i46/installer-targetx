CREATE DATABASE target_x;

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: device; Type: TABLE; Schema: target_x; Owner: postgres
--

CREATE TABLE target_x.device (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_name character varying(20) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone NOT NULL,
    last_login timestamp without time zone
);


ALTER TABLE target_x.device OWNER TO postgres;

--
-- Name: device device_device_name_key; Type: CONSTRAINT; Schema: target_x; Owner: postgres
--

ALTER TABLE ONLY target_x.device
    ADD CONSTRAINT device_device_name_key UNIQUE (device_name);


--
-- Name: device device_pkey; Type: CONSTRAINT; Schema: target_x; Owner: postgres
--

ALTER TABLE ONLY target_x.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (id);


--
-- Name: TABLE device; Type: ACL; Schema: target_x; Owner: postgres
--

GRANT ALL ON TABLE target_x.device TO i46;


--
-- Name: device_key; Type: TABLE; Schema: target_x; Owner: postgres
--

CREATE TABLE target_x.device_key (
    id bigint NOT NULL,
    device_id uuid,
    seq integer,
    key_val character varying(255),
    response_val character varying(255)
);


ALTER TABLE target_x.device_key OWNER TO postgres;

--
-- Name: device_key_id_seq; Type: SEQUENCE; Schema: target_x; Owner: postgres
--

CREATE SEQUENCE target_x.device_key_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE target_x.device_key_id_seq OWNER TO postgres;

--
-- Name: device_key_id_seq; Type: SEQUENCE OWNED BY; Schema: target_x; Owner: postgres
--

ALTER SEQUENCE target_x.device_key_id_seq OWNED BY target_x.device_key.id;


--
-- Name: device_key id; Type: DEFAULT; Schema: target_x; Owner: postgres
--

ALTER TABLE ONLY target_x.device_key ALTER COLUMN id SET DEFAULT nextval('target_x.device_key_id_seq'::regclass);


--
-- Name: device_key device_key_pkey; Type: CONSTRAINT; Schema: target_x; Owner: postgres
--

ALTER TABLE ONLY target_x.device_key
    ADD CONSTRAINT device_key_pkey PRIMARY KEY (id);


--
-- Name: TABLE device_key; Type: ACL; Schema: target_x; Owner: postgres
--

GRANT ALL ON TABLE target_x.device_key TO i46;


--
-- Name: SEQUENCE device_key_id_seq; Type: ACL; Schema: target_x; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE target_x.device_key_id_seq TO i46;


--
-- Name: safe_key; Type: TABLE; Schema: target_x; Owner: postgres
--

CREATE TABLE target_x.safe_key (
    device_id uuid NOT NULL,
    disk_key character varying(255) NOT NULL,
    storage_key character varying(255) NOT NULL,
    encryption_key character varying(255) NOT NULL
);


ALTER TABLE target_x.safe_key OWNER TO postgres;

--
-- Name: safe_key safe_key_pkey; Type: CONSTRAINT; Schema: target_x; Owner: postgres
--

ALTER TABLE ONLY target_x.safe_key
    ADD CONSTRAINT safe_key_pkey PRIMARY KEY (device_id);


--
-- Name: TABLE safe_key; Type: ACL; Schema: target_x; Owner: postgres
--

GRANT ALL ON TABLE target_x.safe_key TO i46;


--
-- PostgreSQL database dump complete
--

