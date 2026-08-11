-- Minimal roles
CREATE ROLE aiaad_app WITH LOGIN PASSWORD 'aiaad_app_password';
CREATE ROLE temporal_app WITH LOGIN PASSWORD 'temporal_app_password';

-- Revoke default public connect access
REVOKE ALL PRIVILEGES ON DATABASE aiaad FROM PUBLIC;
REVOKE ALL PRIVILEGES ON DATABASE temporal FROM PUBLIC;
REVOKE ALL PRIVILEGES ON DATABASE temporal_visibility FROM PUBLIC;

-- Grant access to owners
GRANT ALL PRIVILEGES ON DATABASE aiaad TO aiaad_app;
ALTER DATABASE aiaad OWNER TO aiaad_app;

GRANT ALL PRIVILEGES ON DATABASE temporal TO temporal_app;
ALTER DATABASE temporal OWNER TO temporal_app;

GRANT ALL PRIVILEGES ON DATABASE temporal_visibility TO temporal_app;
ALTER DATABASE temporal_visibility OWNER TO temporal_app;
