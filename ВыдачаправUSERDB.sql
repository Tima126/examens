-- ============================================================
-- СКРИПТ 3: Запускать в базе postgres
-- Права доступа: userN -> только BDN
-- ============================================================

-- BD1 -> user1
REVOKE CONNECT ON DATABASE "bd1" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd1" TO user1;

-- BD2 -> user2
REVOKE CONNECT ON DATABASE "bd2" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd2" TO user2;

-- BD3 -> user3
REVOKE CONNECT ON DATABASE "bd3" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd3" TO user3;

-- BD4 -> user4
REVOKE CONNECT ON DATABASE "bd4" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd4" TO user4;

-- BD5 -> user5
REVOKE CONNECT ON DATABASE "bd5" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd5" TO user5;

-- BD6 -> user6
REVOKE CONNECT ON DATABASE "bd6" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd6" TO user6;

-- BD7 -> user7
REVOKE CONNECT ON DATABASE "bd7" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd7" TO user7;

-- BD8 -> user8
REVOKE CONNECT ON DATABASE "bd8" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd8" TO user8;

-- BD9 -> user9
REVOKE CONNECT ON DATABASE "bd9" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd9" TO user9;

-- BD10 -> user10
REVOKE CONNECT ON DATABASE "bd10" FROM PUBLIC;
GRANT  CONNECT ON DATABASE "bd10" TO user10;

-- Проверка: кто к чему имеет доступ
SELECT d.datname,
       r.rolname,
       has_database_privilege(r.rolname, d.datname, 'CONNECT') AS can_connect
FROM pg_database d
CROSS JOIN pg_roles r
WHERE d.datname LIKE 'bd%'
  AND r.rolname LIKE 'user%'
ORDER BY d.datname, r.rolname;