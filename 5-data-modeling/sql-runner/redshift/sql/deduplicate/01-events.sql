-- Copyright (c) 2013-2015 Snowplow Analytics Ltd. All rights reserved.
--
-- This program is licensed to you under the Apache License Version 2.0,
-- and you may not use this file except in compliance with the Apache License Version 2.0.
-- You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the Apache License Version 2.0 is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
--
-- Authors: Christophe Bogaert
-- Copyright: Copyright (c) 2015 Snowplow Analytics Ltd
-- License: Apache License Version 2.0
--
-- Data Model: deduplicate
-- Version: 0.1
--
-- Deduplicate events:
-- (a) create a list of duplicated events
-- (b) insert those events into a separate table and deduplicate identical ones (i.e. natural duplicates)
-- (c) create a list of events that were deduplicated
-- (d) move those events back into atomic.events, insert the others into the duplicates table

DROP TABLE IF EXISTS atomic.tmp_ids_1;
DROP TABLE IF EXISTS atomic.tmp_ids_2;
DROP TABLE IF EXISTS atomic.tmp_events;

-- (a) create a list of duplicated events

CREATE TABLE atomic.tmp_ids_1
  DISTKEY (event_id)
  SORTKEY (event_id)
AS (SELECT event_id FROM (SELECT event_id, COUNT(*) AS count FROM atomic.events GROUP BY 1) WHERE count > 1);

-- (b) insert those events into a separate table and deduplicate identical ones (i.e. natural duplicates)

CREATE TABLE atomic.tmp_events
  DISTKEY (event_id)
  SORTKEY (event_id)
AS (

  SELECT * FROM atomic.events
  WHERE event_id IN (SELECT event_id FROM atomic.tmp_ids_1)
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9,
  10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
  30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
  40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
  50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
  70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
  90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
  100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
  110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
  120, 121, 122, 123, 124, 125

);

-- (c) create a list of events that were deduplicated

CREATE TABLE atomic.tmp_ids_2
  DISTKEY (event_id)
  SORTKEY (event_id)
AS (SELECT event_id FROM (SELECT event_id, COUNT(*) AS count FROM atomic.tmp_events GROUP BY 1) WHERE count = 1);

-- (d) move those events back into atomic.events, insert the others into the duplicates table

BEGIN;

DELETE FROM atomic.events WHERE event_id IN (SELECT event_id FROM atomic.tmp_ids_1);

INSERT INTO atomic.events (
  SELECT * FROM atomic.tmp_events
  WHERE event_id IN (SELECT event_id FROM atomic.tmp_ids_2)
    AND event_id NOT IN (SELECT event_id FROM atomic.duplicated_events)
);

INSERT INTO atomic.duplicated_events (
  SELECT * FROM atomic.tmp_events
  WHERE event_id NOT IN (SELECT event_id FROM atomic.tmp_ids_2)
    OR event_id IN (SELECT event_id FROM atomic.duplicated_events)
);

COMMIT;

DROP TABLE IF EXISTS atomic.tmp_ids_1;
DROP TABLE IF EXISTS atomic.tmp_ids_2;
DROP TABLE IF EXISTS atomic.tmp_events;
