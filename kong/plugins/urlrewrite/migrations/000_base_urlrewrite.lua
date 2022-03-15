return {
   postgres = {
       up = [[
           CREATE TABLE IF NOT EXISTS "urlrewrite_log_messages" (
             "id"         UUID                      PRIMARY KEY,
             "created_at" TIMESTAMP WITH TIME ZONE  DEFAULT (CURRENT_TIMESTAMP(0) AT TIME ZONE 'UTC'),
             "message"    JSONB
           );
       ]],
   },

   cassandra = {
       up = [[
         CREATE TABLE IF NOT EXISTS "urlrewrite_log_messages" (
           "id"           UUID  PRIMARY KEY,
           "created_at"   TIMESTAMP,
           "message"      TEXT
         );
       ]],
   },
}
