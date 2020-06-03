-- 1 up
CREATE TABLE IF NOT EXISTS "Session" (
   id SERIAL PRIMARY KEY,
   password TEXT NOT NULL,
   files_limit INTEGER NOT NULL,
   files_current INTEGER NOT NULL,
   peers_limit INTEGER NOT NULL,
   peers_current INTEGER NOT NULL,
   peers_ws INTEGER NOT NULL,
   CHECK (files_current <= files_limit),
   CHECK (peers_current <= peers_limit),
   CHECK (files_limit >= 0),
   CHECK (files_current >= 0),
   CHECK (peers_limit >= 0),
   CHECK (peers_current >= 0),
   CHECK (peers_ws >= 0)
);

CREATE TABLE IF NOT EXISTS "Messages" (
   id SERIAL PRIMARY KEY,
   session_id INTEGER REFERENCES "Session"(id) ON DELETE CASCADE,
   text TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "Files" (
   id SERIAL PRIMARY KEY,
   session_id INTEGER REFERENCES "Session"(id),
   name TEXT NOT NULL,
   path TEXT NOT NULL
);

-- 1 down
DROP TABLE IF EXISTS "Messages" CASCADE;
DROP TABLE IF EXISTS "Files" CASCADE;
DROP TABLE IF EXISTS "Session" CASCADE;
