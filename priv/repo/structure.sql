--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.4

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

SET default_with_oids = false;

--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    session_id uuid NOT NULL,
    ip_address character varying(255) NOT NULL,
    joined_at timestamp(0) without time zone NOT NULL,
    readonly boolean NOT NULL,
    id uuid NOT NULL
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    entity_id uuid,
    "timestamp" timestamp(0) without time zone NOT NULL,
    params jsonb NOT NULL,
    generation integer
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid NOT NULL,
    host_last_ip character varying(255) NOT NULL,
    stoken character varying(255) NOT NULL,
    stoken_ro character varying(255) NOT NULL,
    created_at timestamp(0) without time zone NOT NULL,
    ws_url_fmt character varying(255),
    ssh_cmd_fmt character varying(255),
    disconnected_at timestamp(0) without time zone,
    closed boolean DEFAULT false
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    api_key character varying(255),
    verified boolean DEFAULT false,
    allow_mailing_list boolean DEFAULT false,
    created_at timestamp(0) without time zone,
    last_seen_at timestamp(0) without time zone
);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: clients_session_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clients_session_id_index ON public.clients USING btree (session_id);


--
-- Name: events_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_entity_id_index ON public.events USING btree (entity_id);


--
-- Name: events_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_type_index ON public.events USING btree (type);


--
-- Name: sessions_disconnected_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_disconnected_at_index ON public.sessions USING btree (disconnected_at);


--
-- Name: sessions_stoken_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_stoken_index ON public.sessions USING btree (stoken);


--
-- Name: sessions_stoken_ro_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_stoken_ro_index ON public.sessions USING btree (stoken_ro);


--
-- Name: users_api_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_api_key_index ON public.users USING btree (api_key);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_index ON public.users USING btree (username);


--
-- Name: clients clients_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20151010162127), (20151221142603), (20160121023039), (20160123063003), (20160304084101), (20160328175128), (20160406210826), (20190904041603), (20191005234200), (20191014044039), (20191108161753), (20191108174232), (20191110232601), (20191110232704), (20191111025821);

