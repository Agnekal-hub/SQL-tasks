CREATE DATABASE kindergarten_database;
CREATE SCHEMA IF NOT EXISTS kindergarten_data;

CREATE TABLE IF NOT EXISTS kindergarten_data.kindergarten (
		kindg_id serial NOT NULL ,
		kindg_name VARCHAR (50) NOT NULL,
		kindg_address VARCHAR (100) NOT NULL,
		CONSTRAINT kindergarten_pkey PRIMARY KEY (kindg_id));
	
CREATE TABLE IF NOT EXISTS kindergarten_data.kindergarten_group (
		group_id serial NOT NULL ,
		group_name VARCHAR(50) NOT NULL,
		kindg_id int2 NOT NULL,
		class_no VARCHAR (2) NOT NULL,
		max_capacity int2 NOT NULL,
		CONSTRAINT indergarten_group_pkey PRIMARY KEY (group_id),
		CONSTRAINT kindergarten_group_kindg_id_fkey FOREIGN KEY (kindg_id) REFERENCES kindergarten_data.kindergarten(kindg_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT CHK1_kindergarten_group CHECK (max_capacity <=10 ));

CREATE TABLE IF NOT EXISTS kindergarten_data.employee_role (
		role_name VARCHAR (50) NOT NULL ,
		description TEXT NOT NULL,
		CONSTRAINT employee_role_pkey PRIMARY KEY (role_name));

CREATE TABLE IF NOT EXISTS kindergarten_data.personal_info (
		personal_info_id serial NOT NULL ,
		email_address VARCHAR (100) NOT NULL,
		phone_number VARCHAR (15) NOT NULL,
		CONSTRAINT personal_info_pkey PRIMARY KEY (personal_info_id),
		CONSTRAINT CHK5_personal_info CHECK ( email_address LIKE '%@%'));
	
CREATE TABLE IF NOT EXISTS kindergarten_data.address (
		address_id serial NOT NULL ,
		zip_code VARCHAR (10) NOT NULL,
		street_name VARCHAR (50) NOT NULL,
		building_no VARCHAR (4) NOT NULL,
		district VARCHAR (50) NOT NULL,
		city VARCHAR (50) NOT NULL,
		CONSTRAINT address_pkey PRIMARY KEY (address_id),
		CONSTRAINT CHK2_address CHECK (City='Vilnius'));

CREATE TABLE IF NOT EXISTS kindergarten_data.employee (
		empl_id serial NOT NULL ,
		empl_fname VARCHAR (50) NOT NULL,
		empl_lname VARCHAR (50) NOT NULL,
		personal_info_id int2 NOT NULL,
		address_id int2 NOT NULL,
		kindg_id int2 NOT NULL,
		role_name VARCHAR (50) NOT NULL,
		CONSTRAINT employee_pkey PRIMARY KEY (empl_id),
		CONSTRAINT employee_personal_info_id_fkey FOREIGN KEY (personal_info_id) REFERENCES kindergarten_data.personal_info(personal_info_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT employee_address_id_fkey FOREIGN KEY (address_id) REFERENCES kindergarten_data.address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT employee_kindg_id_fkey FOREIGN KEY (kindg_id) REFERENCES kindergarten_data.kindergarten(kindg_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT employee_role_name_fkey FOREIGN KEY (role_name) REFERENCES kindergarten_data.employee_role(role_name) ON DELETE RESTRICT ON UPDATE CASCADE);
		
CREATE TABLE IF NOT EXISTS kindergarten_data.guardian (
		guard_id serial NOT NULL ,
		guard_relation VARCHAR (50) NOT NULL,
		guard_fname VARCHAR (50) NOT NULL,
		guard_lname VARCHAR (50) NOT NULL,
		personal_info_id int2 NOT NULL,
		CONSTRAINT guardian_pkey PRIMARY KEY (guard_id));
	
CREATE TABLE IF NOT EXISTS kindergarten_data.student (
		stud_id serial NOT NULL ,
		stud_fname VARCHAR (50) NOT NULL,
		stud_lname VARCHAR (50) NOT NULL,
		stud_date_of_birth DATE NOT NULL,
		address_id int2 NOT NULL,
		group_id int2 NOT NULL,
		date_of_join DATE NOT NULL,
		CONSTRAINT student_pkey PRIMARY KEY (stud_id),
		CONSTRAINT student_address_id_fkey FOREIGN KEY (address_id) REFERENCES kindergarten_data.address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT student_group_id_fkey FOREIGN KEY (group_id) REFERENCES kindergarten_data.kindergarten_group(group_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT CHK3_student CHECK (date_of_join > stud_date_of_birth),
		CONSTRAINT CHK4_student CHECK (stud_date_of_birth > '2015-01-01'));
	
CREATE TABLE IF NOT EXISTS kindergarten_data.student_guardian (
		guard_id int2 NOT NULL,
		stud_id int2 NOT NULL,
		CONSTRAINT student_guardian_pkey PRIMARY KEY (guard_id, stud_id),
		CONSTRAINT student_guardian_guard_id_fkey FOREIGN KEY (guard_id) REFERENCES kindergarten_data.guardian(guard_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT student_guardian_stud_id_fkey FOREIGN KEY (stud_id) REFERENCES kindergarten_data.student(stud_id) ON DELETE RESTRICT ON UPDATE CASCADE);

CREATE TABLE IF NOT EXISTS kindergarten_data.activity (
		activity_id serial NOT NULL ,
		activity_name VARCHAR (50) NOT NULL,
		empl_id int2,
		CONSTRAINT activity_pkey PRIMARY KEY (activity_id),
		CONSTRAINT activity_empl_id_fkey FOREIGN KEY (empl_id) REFERENCES kindergarten_data.employee(empl_id) ON DELETE RESTRICT ON UPDATE CASCADE);
	
CREATE TABLE IF NOT EXISTS kindergarten_data.student_activity (
		activity_id int2 NOT NULL,
		stud_id	int2 NOT NULL,	
		CONSTRAINT student_activity_pkey PRIMARY KEY (activity_id, stud_id),
		CONSTRAINT student_activity_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES kindergarten_data.activity(activity_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT student_activity_stud_id_fkey FOREIGN KEY (stud_id) REFERENCES kindergarten_data.student(stud_id) ON DELETE RESTRICT ON UPDATE CASCADE);
		
	
--1. Inserting data in kindergarten table
WITH new_kindg_data AS
	(SELECT 
		'Little Bears' AS kindg_name, 'Didzioji g. 5, Vilnius' AS kindg_address
    UNION ALL
    SELECT 
    	'Little Foxes' AS kindg_name, 'Mazoji g. 1, Vilnius' AS kindg_address)
INSERT INTO kindergarten_data.kindergarten(kindg_name, kindg_address)
    SELECT nkd.kindg_name, nkd.kindg_address
    FROM new_kindg_data nkd
    WHERE NOT EXISTS 
    	(SELECT * FROM kindergarten_data.kindergarten k WHERE k.kindg_name = nkd.kindg_name)
    RETURNING *;
   
  --2 Inserting employee_roles
WITH new_employee_role AS
	(SELECT 
		'Daycare teacher' AS role_name, 'Plan creative activities for students, aiding their intellectual development.' AS description
    UNION ALL
    SELECT 
    	'Nurse' AS role_name, 'Performing wound care, such AS cleaning and bandaging them.' AS description)
INSERT INTO kindergarten_data.employee_role (role_name, description)
    SELECT ner.role_name, ner.description
    FROM new_employee_role ner
    WHERE NOT EXISTS 
    	(SELECT * FROM kindergarten_data.employee_role er WHERE er.role_name = ner.role_name)
    RETURNING *;
   
 
  --3. Inserting in employee tables  
   WITH new_employee_data AS
		(SELECT 
			'Jonas' AS empl_fname, 'Jonaitis' AS empl_lname, 'jonas.jonaitis@gmail.com' AS email_address, '+370458111211' AS phone_number, '03265' AS zip_code,
			'Green street' AS street_name , '24' AS building_no , 'Lazdynai' AS district , 'Vilnius' AS city, 'Little Bears' AS kindg_name , 'Daycare teacher' AS role_name
    	UNION all
    	SELECT 
    		'Petras' AS empl_fname, 'Petraitis' AS empl_lname, 'petras.petraitis@gmail.com' AS email_address, '+3706145891254' AS phone_number, '03279' AS zip_code,
			'Blue street' AS street_name , '84' AS building_no , 'Naujininkai' AS district , 'Vilnius' AS city, 'Little Bears' AS kindg_name , 'Nurse' AS role_name),
	new_personal_info AS (
		INSERT INTO kindergarten_data.personal_info(email_address, phone_number)
    	SELECT npd.email_address, npd.phone_number
    	FROM new_employee_data npd
    	WHERE NOT EXISTS (SELECT * FROM kindergarten_data.personal_info pi1 WHERE pi1.email_address = npd.email_address)
    	RETURNING personal_info_id, email_address, phone_number),
    new_address AS(
    	INSERT INTO kindergarten_data.address(zip_code, street_name, building_no, district, city)
    	SELECT npd.zip_code, npd.street_name, npd.building_no, npd.district, npd.city
    	FROM new_employee_data npd
    	RETURNING address_id, zip_code, street_name, building_no, district, city)
INSERT INTO kindergarten_data.employee (empl_fname, empl_lname, personal_info_id, address_id , kindg_id, role_name)
    SELECT 
    	npd.empl_fname, npd.empl_lname, npi.personal_info_id, na.address_id, k.kindg_id , er.role_name
	FROM new_employee_data npd
	LEFT JOIN new_personal_info npi ON npd.email_address = npi.email_address
	LEFT JOIN new_address na ON npd.zip_code = na.zip_code
	LEFT JOIN kindergarten k  ON k.kindg_name =npd.kindg_name
	LEFT JOIN employee_role er ON er.role_name = npd.role_name
	WHERE NOT EXISTS (SELECT * FROM kindergarten_data.employee e WHERE e.empl_lname = npd.empl_lname AND e.empl_fname = npd.empl_fname)
	RETURNING *
 --4. Inserting in kindergarten_group table 
WITH new_kindergarten_group AS
	(SELECT 
		'Strawberries' AS group_name, 'Little Bears' AS kindg_name , '1a' AS class_no , 10 AS max_capacity
    UNION ALL
    SELECT 
    	'Blackberries' AS group_name, 'Little Foxes' AS kindg_name , '2a' AS class_no , 9 AS max_capacity),
	select_kindg_id2 AS (
    	SELECT k.kindg_id, nkg.kindg_name
    	FROM kindergarten k 
    	INNER JOIN new_kindergarten_group nkg ON k.kindg_name = nkg.kindg_name
    	WHERE k.kindg_name = nkg.kindg_name)
  INSERT INTO kindergarten_data.kindergarten_group (group_name , kindg_id , class_no , max_capacity)
  		SELECT nkg.group_name , ski2.kindg_id , nkg.class_no , nkg.max_capacity
  		FROM new_kindergarten_group nkg
  		INNER JOIN select_kindg_id2 ski2 ON ski2.kindg_name = nkg.kindg_name
 	WHERE NOT EXISTS 
    	(SELECT * FROM kindergarten_data.kindergarten_group kg  WHERE kg.group_name = nkg.group_name)
    RETURNING *;
  		
-- 5. Inserting new_student
WITH
new_student_guard_data AS
(
    SELECT 'Algis'  AS stud_fname, 'Algutis' AS stud_lname, '2017-03-25' AS stud_date_of_birth, '03277' AS zip_code,
			'Red street' AS street_name , '74' AS building_no , 'Lazdyneliai' AS district , 'Vilnius' AS city, 
			'Blackberries' AS group_name , '2020-03-25' AS date_of_join, 
			'Father' AS guard_relation , 'Marius' AS guard_fname, 'Mariukas' AS guard_lname , 'm.mariukas@gmail' AS email_address , '+30767788944' AS phone_number
    UNION ALL 
    SELECT 'Migle'  AS stud_fname, 'Miglute' AS stud_lname, '2016-03-25'  AS stud_date_of_birth, '03765' AS zip_code,
			'Green street' AS street_name , '24' AS building_no , 'Upes' AS district , 'Vilnius' AS city, 
			'Blackberries' AS group_name , '2021-03-25' AS date_of_join,
			'Mother' AS guard_relation , 'Maryte' AS guard_fname, 'Marytele' AS guard_lname , 'm.marytele@gmail' AS email_address , '+30767788887' AS phone_number
),
new_student_address AS
(
   INSERT INTO kindergarten_data.address(zip_code, street_name, building_no, district, city)
    	SELECT nsgd.zip_code, nsgd.street_name, nsgd.building_no, nsgd.district, nsgd.city
    	FROM new_student_guard_data nsgd
    	RETURNING address_id, zip_code, street_name, building_no, district, city),
select_new_student_group AS
(
    SELECT group_id, nsgd.group_name
    	FROM kindergarten_group kg 
    	INNER JOIN new_student_guard_data nsgd ON kg.group_name = nsgd.group_name
    	WHERE kg.group_name = nsgd.group_name),
 new_student AS 
 (
 	INSERT INTO kindergarten_data.student ( stud_fname , stud_lname, stud_date_of_birth, address_id, group_id, date_of_join)
 		SELECT nsgd.stud_fname, nsgd.stud_lname, nsgd.stud_date_of_birth::date , nsa.address_id , snsg.group_id , nsgd.date_of_join::date
 		FROM new_student_guard_data nsgd
 		LEFT JOIN new_student_address nsa ON nsa.zip_code = nsgd.zip_code
 		LEFT JOIN select_new_student_group snsg ON snsg.group_name = nsgd.group_name
 		RETURNING stud_id, stud_fname, stud_lname, stud_date_of_birth),
 new_guard_personal_info AS (
 		INSERT INTO kindergarten_data.personal_info(email_address, phone_number)
    	SELECT nsgd.email_address, nsgd.phone_number
    	FROM new_student_guard_data nsgd
    	WHERE NOT EXISTS (SELECT * FROM kindergarten_data.personal_info pi2 WHERE pi2.email_address = nsgd.email_address)
    	RETURNING personal_info_id, email_address, phone_number),
 new_guardian AS (
 		INSERT INTO kindergarten_data.guardian(guard_relation , guard_fname, guard_lname , personal_info_id)
 		SELECT nsgd.guard_relation , nsgd.guard_fname , nsgd.guard_lname, ngpi.personal_info_id
 		FROM new_student_guard_data nsgd
 		LEFT JOIN new_guard_personal_info ngpi ON ngpi.email_address = nsgd.email_address
 		RETURNING guard_id, guard_relation, guard_fname,  guard_lname)
INSERT INTO kindergarten_data.student_guardian(guard_id, stud_id)
SELECT
    coalesce(ng.guard_id, g.guard_id) AS guard_id,
    coalesce(ns.stud_id, s.stud_id) AS stud_id
FROM
    new_student_guard_data nsgd
    LEFT JOIN new_guardian ng
        ON nsgd.guard_fname = ng.guard_fname AND nsgd.guard_lname = ng.guard_lname
    LEFT JOIN new_student ns
        ON nsgd.stud_lname = ns.stud_lname
    LEFT JOIN kindergarten_data.guardian g
        ON g.guard_fname = nsgd.guard_fname AND g.guard_lname = nsgd.guard_lname
    LEFT JOIN kindergarten_data.student s
        ON s.stud_lname = nsgd.stud_lname
 RETURNING *
WHERE
    NOT EXISTS 
    (
        SELECT * FROM kindergarten_data.student_guardian sg  
        WHERE sg.guard_id = coalesce(ng.guard_id, g.guard_id) AND sg.stud_id = coalesce(ns.stud_id, s.stud_id)
    ) 	
    
--6. Inserting data in student activity table
WITH 
	new_student_activity_data AS
		( SELECT 'Algutis' AS stud_lname , 'Singing' AS activity_name , 'Jonaitis' AS empl_lname
		UNION ALL 
		SELECT 'Miglute' AS stud_lname , 'First_aid' AS activity_name , 'Petraitis' AS empl_lname),
new_activity AS (
			INSERT INTO kindergarten_data.activity(activity_name, empl_id)
			SELECT nsad.activity_name, e2.empl_id
			FROM new_student_activity_data nsad
			INNER JOIN employee e2  ON e2.empl_lname = nsad.empl_lname
    		WHERE e2.empl_lname = nsad.empl_lname
    		RETURNING activity_id, activity_name, empl_id),
new_activity_stud AS(
		SELECT stud_id , nsad.stud_lname
    	FROM student s
    	INNER JOIN new_student_activity_data nsad ON s.stud_lname = nsad.stud_lname
    	WHERE s.stud_lname = nsad.stud_lname)
INSERT INTO kindergarten_data.student_activity (activity_id, stud_id)
SELECT
    coalesce(nwa.activity_id, ac.activity_id) as activity_id,
    coalesce(nas.stud_id, s2.stud_id) as stud_id
FROM 
   	new_student_activity_data  nsad
    LEFT JOIN new_activity nwa
        ON nsad.activity_name = nwa.activity_name
    LEFT JOIN new_activity_stud nas
        ON nsad.stud_lname = nas.stud_lname
    LEFT JOIN kindergarten_data.activity ac
        ON ac.activity_name = nsad.activity_name
    LEFT JOIN kindergarten_data.student s2  
        ON s2.stud_lname = nsad.stud_lname
WHERE
  NOT EXISTS 
    (
        SELECT * FROM kindergarten_data.student_activity sa 
        WHERE sa.activity_id = coalesce(nwa.activity_id, ac.activity_id) and sa.stud_id = coalesce(nas.stud_id, s2.stud_id)
    );
 
ALTER TABLE kindergarten 
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE activity 
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE address 
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE employee  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE employee_role  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE guardian  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE kindergarten_group  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE personal_info  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE student_activity  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();

ALTER TABLE student_guardian  
ADD COLUMN record_ts timestamptz NOT NULL DEFAULT now();