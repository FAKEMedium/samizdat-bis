--
-- PostgreSQL database dump
--


-- Dumped from database version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)


--
-- Name: bis; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS bis;




--
-- Name: checks; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.checks (
    id integer NOT NULL,
    run_id integer,
    domain_id integer,
    record_type character varying(10) NOT NULL,
    record_value character varying(500),
    ip_address inet,
    country_code character(2),
    asn integer,
    as_name character varying(500),
    hosting_provider character varying(500),
    is_compliant boolean DEFAULT false,
    checked_at timestamp without time zone DEFAULT now()
);


--
-- Name: checks_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.checks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checks_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.checks_id_seq OWNED BY bis.checks.id;


--
-- Name: domain_descriptions; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.domain_descriptions (
    id integer NOT NULL,
    domain_id integer NOT NULL,
    languageid integer NOT NULL,
    title character varying(500),
    description text
);


--
-- Name: domain_descriptions_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.domain_descriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domain_descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.domain_descriptions_id_seq OWNED BY bis.domain_descriptions.id;


--
-- Name: domain_tags; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.domain_tags (
    domain_id integer NOT NULL,
    tag_id integer NOT NULL
);


--
-- Name: domains; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.domains (
    id integer NOT NULL,
    domain character varying(255) NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.domains_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.domains_id_seq OWNED BY bis.domains.id;


--
-- Name: runs; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.runs (
    id integer NOT NULL,
    started_at timestamp without time zone DEFAULT now(),
    completed_at timestamp without time zone,
    domains_checked integer DEFAULT 0,
    status character varying(50) DEFAULT 'running'::character varying,
    notes text
);


--
-- Name: scores; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.scores (
    id integer NOT NULL,
    run_id integer,
    domain_id integer,
    score integer,
    total_checks integer DEFAULT 0,
    compliant_checks integer DEFAULT 0,
    a_compliant boolean DEFAULT false,
    aaaa_compliant boolean,
    mx_compliant boolean,
    ns_compliant boolean DEFAULT false,
    has_bis_badge boolean DEFAULT false,
    primary_provider character varying(500),
    notes text,
    calculated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT scores_score_check CHECK (((score >= 0) AND (score <= 100)))
);


--
-- Name: latest_scores; Type: VIEW; Schema: bis; Owner: -
--

CREATE VIEW bis.latest_scores AS
 SELECT s.id,
    s.run_id,
    s.domain_id,
    s.score,
    s.total_checks,
    s.compliant_checks,
    s.a_compliant,
    s.aaaa_compliant,
    s.mx_compliant,
    s.ns_compliant,
    s.has_bis_badge,
    s.primary_provider,
    s.notes,
    s.calculated_at,
    d.domain,
    r.started_at AS check_date
   FROM ((bis.scores s
     JOIN bis.domains d ON ((s.domain_id = d.id)))
     JOIN bis.runs r ON ((s.run_id = r.id)))
  WHERE (r.id = ( SELECT max(runs.id) AS max
           FROM bis.runs
          WHERE ((runs.status)::text = 'completed'::text)))
  ORDER BY s.score DESC;


--
-- Name: provider_names; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.provider_names (
    id integer NOT NULL,
    provider_id integer NOT NULL,
    languageid integer NOT NULL,
    key character varying(100) NOT NULL,
    name character varying(200) NOT NULL,
    notes text
);


--
-- Name: provider_names_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.provider_names_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provider_names_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.provider_names_id_seq OWNED BY bis.provider_names.id;


--
-- Name: providers; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.providers (
    id integer NOT NULL,
    country_code character(2) NOT NULL,
    is_swedish boolean DEFAULT false,
    cloud_act_applies boolean DEFAULT false,
    asn_list integer[],
    as_name_patterns text[],
    ip_ranges cidr[],
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: provider_stats; Type: VIEW; Schema: bis; Owner: -
--

CREATE VIEW bis.provider_stats AS
 SELECT c.hosting_provider,
    pn.name AS provider_name,
    bp.country_code,
    bp.is_swedish,
    bp.cloud_act_applies,
    count(DISTINCT c.domain_id) AS domain_count,
    count(*) AS total_records
   FROM ((bis.checks c
     LEFT JOIN bis.provider_names pn ON ((((c.hosting_provider)::text = (pn.key)::text) AND (pn.languageid = ( SELECT languages.languageid
           FROM public.languages
          WHERE ((languages.code)::text = 'en'::text)
         LIMIT 1)))))
     LEFT JOIN bis.providers bp ON ((pn.provider_id = bp.id)))
  WHERE (c.run_id = ( SELECT max(runs.id) AS max
           FROM bis.runs
          WHERE ((runs.status)::text = 'completed'::text)))
  GROUP BY c.hosting_provider, pn.name, bp.country_code, bp.is_swedish, bp.cloud_act_applies
  ORDER BY (count(DISTINCT c.domain_id)) DESC;


--
-- Name: providers_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: providers_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.providers_id_seq OWNED BY bis.providers.id;


--
-- Name: runs_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: runs_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.runs_id_seq OWNED BY bis.runs.id;


--
-- Name: scores_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.scores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scores_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.scores_id_seq OWNED BY bis.scores.id;


--
-- Name: tag_names; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.tag_names (
    id integer NOT NULL,
    tag_id integer NOT NULL,
    languageid integer NOT NULL,
    key character varying(100) NOT NULL,
    display_name character varying(200) NOT NULL,
    description text
);


--
-- Name: tags; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.tags (
    id integer NOT NULL,
    color character varying(7) DEFAULT '#0066cc'::character varying,
    priority integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: sector_stats; Type: VIEW; Schema: bis; Owner: -
--

CREATE VIEW bis.sector_stats AS
 SELECT tn.key AS sector,
    tn.display_name,
    count(DISTINCT d.id) AS total_domains,
    count(DISTINCT
        CASE
            WHEN s.has_bis_badge THEN d.id
            ELSE NULL::integer
        END) AS compliant_domains,
    round(avg(s.score), 2) AS avg_score,
    round(((100.0 * (count(DISTINCT
        CASE
            WHEN s.has_bis_badge THEN d.id
            ELSE NULL::integer
        END))::numeric) / (NULLIF(count(DISTINCT d.id), 0))::numeric), 2) AS compliance_rate
   FROM ((((bis.tags t
     JOIN bis.tag_names tn ON (((t.id = tn.tag_id) AND (tn.languageid = ( SELECT languages.languageid
           FROM public.languages
          WHERE ((languages.code)::text = 'en'::text)
         LIMIT 1)))))
     JOIN bis.domain_tags dt ON ((t.id = dt.tag_id)))
     JOIN bis.domains d ON ((dt.domain_id = d.id)))
     JOIN bis.scores s ON ((d.id = s.domain_id)))
  WHERE ((s.run_id = ( SELECT max(runs.id) AS max
           FROM bis.runs
          WHERE ((runs.status)::text = 'completed'::text))) AND (d.active = true))
  GROUP BY tn.key, tn.display_name, t.priority
  ORDER BY t.priority DESC;


--
-- Name: statistics; Type: TABLE; Schema: bis; Owner: -
--

CREATE TABLE bis.statistics (
    id integer NOT NULL,
    run_id integer,
    total_domains integer DEFAULT 0,
    compliant_domains integer DEFAULT 0,
    compliance_rate numeric(5,2),
    a_compliance_rate numeric(5,2),
    mx_compliance_rate numeric(5,2),
    ns_compliance_rate numeric(5,2),
    avg_score numeric(5,2),
    calculated_at timestamp without time zone DEFAULT now()
);


--
-- Name: statistics_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.statistics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.statistics_id_seq OWNED BY bis.statistics.id;


--
-- Name: tag_names_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.tag_names_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.tag_names_id_seq OWNED BY bis.tag_names.id;


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: bis; Owner: -
--

CREATE SEQUENCE bis.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: bis; Owner: -
--

ALTER SEQUENCE bis.tags_id_seq OWNED BY bis.tags.id;


--
-- Name: checks id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.checks ALTER COLUMN id SET DEFAULT nextval('bis.checks_id_seq'::regclass);


--
-- Name: domain_descriptions id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_descriptions ALTER COLUMN id SET DEFAULT nextval('bis.domain_descriptions_id_seq'::regclass);


--
-- Name: domains id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domains ALTER COLUMN id SET DEFAULT nextval('bis.domains_id_seq'::regclass);


--
-- Name: provider_names id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.provider_names ALTER COLUMN id SET DEFAULT nextval('bis.provider_names_id_seq'::regclass);


--
-- Name: providers id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.providers ALTER COLUMN id SET DEFAULT nextval('bis.providers_id_seq'::regclass);


--
-- Name: runs id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.runs ALTER COLUMN id SET DEFAULT nextval('bis.runs_id_seq'::regclass);


--
-- Name: scores id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.scores ALTER COLUMN id SET DEFAULT nextval('bis.scores_id_seq'::regclass);


--
-- Name: statistics id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.statistics ALTER COLUMN id SET DEFAULT nextval('bis.statistics_id_seq'::regclass);


--
-- Name: tag_names id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tag_names ALTER COLUMN id SET DEFAULT nextval('bis.tag_names_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tags ALTER COLUMN id SET DEFAULT nextval('bis.tags_id_seq'::regclass);


--
-- Name: checks checks_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.checks
    ADD CONSTRAINT checks_pkey PRIMARY KEY (id);


--
-- Name: domain_descriptions domain_descriptions_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_descriptions
    ADD CONSTRAINT domain_descriptions_pkey PRIMARY KEY (id);


--
-- Name: domain_descriptions domain_descriptions_unique; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_descriptions
    ADD CONSTRAINT domain_descriptions_unique UNIQUE (domain_id, languageid);


--
-- Name: domain_tags domain_tags_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_tags
    ADD CONSTRAINT domain_tags_pkey PRIMARY KEY (domain_id, tag_id);


--
-- Name: domains domains_domain_key; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domains
    ADD CONSTRAINT domains_domain_key UNIQUE (domain);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: provider_names provider_names_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.provider_names
    ADD CONSTRAINT provider_names_pkey PRIMARY KEY (id);


--
-- Name: provider_names provider_names_unique; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.provider_names
    ADD CONSTRAINT provider_names_unique UNIQUE (provider_id, languageid);


--
-- Name: providers providers_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.providers
    ADD CONSTRAINT providers_pkey PRIMARY KEY (id);


--
-- Name: runs runs_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.runs
    ADD CONSTRAINT runs_pkey PRIMARY KEY (id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: scores scores_run_id_domain_id_key; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.scores
    ADD CONSTRAINT scores_run_id_domain_id_key UNIQUE (run_id, domain_id);


--
-- Name: statistics statistics_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.statistics
    ADD CONSTRAINT statistics_pkey PRIMARY KEY (id);


--
-- Name: statistics statistics_run_id_key; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.statistics
    ADD CONSTRAINT statistics_run_id_key UNIQUE (run_id);


--
-- Name: tag_names tag_names_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tag_names
    ADD CONSTRAINT tag_names_pkey PRIMARY KEY (id);


--
-- Name: tag_names tag_names_unique; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tag_names
    ADD CONSTRAINT tag_names_unique UNIQUE (tag_id, languageid);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: idx_checks_compliant; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_checks_compliant ON bis.checks USING btree (is_compliant);


--
-- Name: idx_checks_domain; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_checks_domain ON bis.checks USING btree (domain_id);


--
-- Name: idx_checks_provider; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_checks_provider ON bis.checks USING btree (hosting_provider);


--
-- Name: idx_checks_run; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_checks_run ON bis.checks USING btree (run_id);


--
-- Name: idx_checks_type; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_checks_type ON bis.checks USING btree (record_type);


--
-- Name: idx_domain_descriptions_domain; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domain_descriptions_domain ON bis.domain_descriptions USING btree (domain_id);


--
-- Name: idx_domain_descriptions_lang; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domain_descriptions_lang ON bis.domain_descriptions USING btree (languageid);


--
-- Name: idx_domain_tags_domain; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domain_tags_domain ON bis.domain_tags USING btree (domain_id);


--
-- Name: idx_domain_tags_tag; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domain_tags_tag ON bis.domain_tags USING btree (tag_id);


--
-- Name: idx_domains_active; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domains_active ON bis.domains USING btree (active);


--
-- Name: idx_domains_domain; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_domains_domain ON bis.domains USING btree (domain);


--
-- Name: idx_provider_names_key; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_provider_names_key ON bis.provider_names USING btree (key);


--
-- Name: idx_provider_names_lang; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_provider_names_lang ON bis.provider_names USING btree (languageid);


--
-- Name: idx_provider_names_provider; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_provider_names_provider ON bis.provider_names USING btree (provider_id);


--
-- Name: idx_providers_swedish; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_providers_swedish ON bis.providers USING btree (is_swedish);


--
-- Name: idx_runs_started; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_runs_started ON bis.runs USING btree (started_at DESC);


--
-- Name: idx_scores_badge; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_scores_badge ON bis.scores USING btree (has_bis_badge);


--
-- Name: idx_scores_domain; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_scores_domain ON bis.scores USING btree (domain_id);


--
-- Name: idx_scores_run; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_scores_run ON bis.scores USING btree (run_id);


--
-- Name: idx_scores_score; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_scores_score ON bis.scores USING btree (score DESC);


--
-- Name: idx_statistics_run; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_statistics_run ON bis.statistics USING btree (run_id);


--
-- Name: idx_tag_names_key; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_tag_names_key ON bis.tag_names USING btree (key);


--
-- Name: idx_tag_names_lang; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_tag_names_lang ON bis.tag_names USING btree (languageid);


--
-- Name: idx_tag_names_tag; Type: INDEX; Schema: bis; Owner: -
--

CREATE INDEX idx_tag_names_tag ON bis.tag_names USING btree (tag_id);


--
-- Name: checks checks_domain_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.checks
    ADD CONSTRAINT checks_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES bis.domains(id) ON DELETE CASCADE;


--
-- Name: checks checks_run_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.checks
    ADD CONSTRAINT checks_run_id_fkey FOREIGN KEY (run_id) REFERENCES bis.runs(id) ON DELETE CASCADE;


--
-- Name: domain_descriptions domain_descriptions_domain_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_descriptions
    ADD CONSTRAINT domain_descriptions_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES bis.domains(id) ON DELETE CASCADE;


--
-- Name: domain_descriptions domain_descriptions_languageid_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_descriptions
    ADD CONSTRAINT domain_descriptions_languageid_fkey FOREIGN KEY (languageid) REFERENCES public.languages(languageid) ON DELETE CASCADE;


--
-- Name: domain_tags domain_tags_domain_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_tags
    ADD CONSTRAINT domain_tags_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES bis.domains(id) ON DELETE CASCADE;


--
-- Name: domain_tags domain_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.domain_tags
    ADD CONSTRAINT domain_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES bis.tags(id) ON DELETE CASCADE;


--
-- Name: provider_names provider_names_languageid_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.provider_names
    ADD CONSTRAINT provider_names_languageid_fkey FOREIGN KEY (languageid) REFERENCES public.languages(languageid) ON DELETE CASCADE;


--
-- Name: provider_names provider_names_provider_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.provider_names
    ADD CONSTRAINT provider_names_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES bis.providers(id) ON DELETE CASCADE;


--
-- Name: scores scores_domain_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.scores
    ADD CONSTRAINT scores_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES bis.domains(id) ON DELETE CASCADE;


--
-- Name: scores scores_run_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.scores
    ADD CONSTRAINT scores_run_id_fkey FOREIGN KEY (run_id) REFERENCES bis.runs(id) ON DELETE CASCADE;


--
-- Name: statistics statistics_run_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.statistics
    ADD CONSTRAINT statistics_run_id_fkey FOREIGN KEY (run_id) REFERENCES bis.runs(id) ON DELETE CASCADE;


--
-- Name: tag_names tag_names_languageid_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tag_names
    ADD CONSTRAINT tag_names_languageid_fkey FOREIGN KEY (languageid) REFERENCES public.languages(languageid) ON DELETE CASCADE;


--
-- Name: tag_names tag_names_tag_id_fkey; Type: FK CONSTRAINT; Schema: bis; Owner: -
--

ALTER TABLE ONLY bis.tag_names
    ADD CONSTRAINT tag_names_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES bis.tags(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
