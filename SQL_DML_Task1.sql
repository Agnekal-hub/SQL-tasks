-- 1. Choose your top-3 favorite movies and add them to 'film' table. Fill rental rates with 4.99, 9.99 and 19.99 
-- and rental durations with 1, 2 and 3 weeks respectively.
WITH
film_data AS
(	SELECT
		'12 Angry Men' AS title, 1957 AS release_year, 'english' AS language_name , 1 AS rental_duration , 4.99 AS rental_rate , CURRENT_DATE AS last_update  
    UNION ALL
    SELECT
    	'Pulp Fiction' AS title, 1994 AS release_year, 'english' AS language_name, 2 AS rental_duration , 9.99 AS rental_rate , CURRENT_DATE AS last_update
    UNION ALL
    SELECT 
    	'Fight Club' AS title, 1999 AS release_year, 'english' AS language_name, 3 AS rental_duration , 19.99 AS rental_rate , CURRENT_DATE AS last_update
    	)
  INSERT INTO public.film(title, release_year, language_id, rental_duration, rental_rate, last_update)
    SELECT fd.title, fd.release_year, max(l.language_id) as language_id , fd.rental_duration , fd.rental_rate, fd.last_update
    FROM film_data fd
        LEFT JOIN public."language" l 
            ON fd.language_name = lower("name")
    WHERE NOT EXISTS (SELECT * FROM public.film f WHERE f.title = fd.title AND f.release_year = fd.release_year)
    GROUP BY fd.title, fd.release_year, fd.rental_duration, fd.rental_rate, fd.last_update
    RETURNING film_id, title, release_year, rental_duration, rental_rate, last_update
    	
-- 2. Add actors who play leading roles in your favorite movies to 'actor' and 'film_actor' tables (6 or more actors in total).
    
WITH
actor_data AS
(	SELECT
		'Henry' AS first_name, 'Fonda' AS last_name, CURRENT_DATE AS last_update,  '12 Angry Men' AS title
    UNION ALL
    SELECT
    	'Martin' AS first_name, 'Balsam' AS last_name, CURRENT_DATE AS last_update,  '12 Angry Men' AS title
    UNION ALL
    SELECT
 		'John' AS first_name, 'Travolta' AS last_name, CURRENT_DATE AS last_update,  'Pulp Fiction' AS title
    UNION ALL
    SELECT
    	'Uma' AS first_name, 'Thurman' AS last_name, CURRENT_DATE AS last_update,  'Pulp Fiction' AS title
    UNION ALL	
     SELECT
    	'Brad' AS first_name, 'Pitt' AS last_name, CURRENT_DATE AS last_update,  'Fight Club' AS title
    UNION ALL	
     SELECT
    	'Edward' AS first_name, 'Norton' AS last_name, CURRENT_DATE AS last_update,  'Fight Club' AS title
  ),
new_actor AS (
    INSERT INTO public.actor(first_name, last_name, last_update)
    SELECT ad.first_name, ad.last_name, ad.last_update
    FROM actor_data ad
    WHERE NOT EXISTS (SELECT * FROM public.actor a WHERE a.first_name = ad.first_name AND a.last_name = ad.last_name)
    RETURNING  actor_id, first_name , last_name 
  )
INSERT INTO film_actor(actor_id ,film_id, last_update)
SELECT
  		 na.actor_id, f.film_id, ad.last_update
FROM
    actor_data ad
    LEFT JOIN public.film f
        ON ad.title = f.title
    LEFT JOIN new_actor na
        ON ad.first_name = na.first_name and ad.last_name = na.last_name
    LEFT JOIN public.actor a 
        ON a.first_name = ad.first_name and a.last_name = ad.last_name
 WHERE
    NOT EXISTS 
    (
        SELECT * FROM public.film_actor fa 
        WHERE fa.actor_id = coalesce(na.actor_id, a.actor_id)
    )
 RETURNING actor_id, film_id
 
-- 3.Add your favorite movies to any store's inventory. 
 WITH 
 	new_inventory AS (
 	SELECT '12 Angry Men' AS title, 1 AS store_id , CURRENT_DATE AS last_update
 	UNION ALL
 	SELECT 'Pulp Fiction' AS title, 1 AS store_id , CURRENT_DATE AS last_update
 	UNION ALL
 	SELECT 'Fight Club' AS title, 2 AS store_id , CURRENT_DATE AS last_update)
INSERT INTO inventory (film_id , store_id , last_update)
	SELECT f.film_id, s.store_id, ni.last_update
	FROM new_inventory ni
	LEFT JOIN film f ON f.title = ni.title
	LEFT JOIN store s  ON s.store_id = ni.store_id
	WHERE
    NOT EXISTS 
    (
        SELECT * FROM public.inventory i 
        WHERE i.film_id = f.film_id AND i.store_id = s.store_id)
	RETURNING inventory_id, film_id , store_id, last_update 

	
-- 4. Alter any existing customer in the database who has at least 43 rental and 43 payment records. 
--Change his/her personal data to yours (first name,last name, address, etc.). 
--Do not perform any updates on 'address' table, as it can impact multiple records with the same address. 
--Change customer's create_date value to current_date

UPDATE customer c
SET first_name = 'Agne',
    last_name = 'Kalantaite',
    email = 'agne.kalantaite',
    create_date= current_date                   --create_date update
WHERE c.customer_id IN (WITH payments_select AS (SELECT  p.customer_id,
                                                COUNT(p.payment_id) AS payments_number
                                                FROM payment p
                                                GROUP BY p.customer_id
                                                HAVING COUNT(p.payment_id)>=43),
                            rentals_select AS (SELECT  r.customer_id,
                                                COUNT(r.rental_id) AS rentals_number
                                                FROM rental r
                                                GROUP BY r.customer_id
                                                HAVING COUNT(r.rental_id)>=43)
                        SELECT payments_select.customer_id
                        FROM payments_select
                        INNER JOIN rentals_select
                        ON payments_select.customer_id=rentals_select.customer_id
                        LIMIT 1); 
                       
-- 5.Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
DELETE
FROM payment p 
WHERE p.customer_id IN (SELECT c.customer_id 
                        FROM customer c
                        WHERE UPPER(c.first_name) = 'AGNE' AND UPPER(c.last_name) = 'KALANTAITE');

DELETE
FROM rental r 
WHERE r.customer_id IN (SELECT c.customer_id 
                        FROM customer c
                        WHERE UPPER(c.first_name) = 'AGNE' AND UPPER(c.last_name) = 'KALANTAITE');

  
--6.Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
 
 WITH
rent_and_pay_data AS
(	SELECT
		'2017-03-24 22:54:38.000 +0300' AS rental_date, '12 Angry Men' AS title, 'Kalantaite' AS c_last_name  , '2017-03-25 22:54:33.000 +0300' AS return_date , 
		'Rainbow' AS s_last_name , '2017-03-24 23:00:00+02' AS payment_date
    UNION ALL
    SELECT
    	'2017-03-24 22:54:39.000 +0300' AS rental_date, 'Fight Club' AS title, 'Kalantaite' AS c_last_name , '2017-03-25 22:54:37.000 +0300' AS return_date , 
    	'Rainbow' AS s_last_name , '2017-03-24 23:01:00+02' AS payment_date
    UNION ALL
    SELECT 
    	'2017-03-24 22:55:33.000 +0300' AS rental_date, 'Pulp Fiction' AS title, 'Kalantaite' AS c_last_name , '2017-03-25 22:54:39.000 +0300' AS return_date , 
    	'Rainbow' AS s_last_name,  '2017-03-24 23:02:00+02'
    	),
new_rent AS(
  		INSERT INTO public.rental (rental_date , inventory_id, customer_id , return_date , staff_id)
 		SELECT rapd.rental_date::timestamptz, i.inventory_id, c.customer_id, rapd.return_date::timestamptz, s.staff_id
  		FROM rent_and_pay_data rapd
  		LEFT JOIN rental r ON r.rental_date::timestamptz = rapd.rental_date::timestamptz
  		LEFT JOIN film f ON upper(f.title) = upper(rapd.title)
  		LEFT JOIN inventory i ON i.film_id  = f.film_id
  		LEFT JOIN customer c ON upper(c.last_name) = upper(rapd.c_last_name) 
  		LEFT JOIN staff s ON upper(s.last_name) = upper(rapd.s_last_name)
		WHERE NOT EXISTS (SELECT * FROM public.rental r  WHERE r.rental_date::timestamptz = rapd.rental_date::timestamptz)
 RETURNING *),
 payment_amount AS (
 		SELECT f.title, f.rental_rate AS amount
 		FROM film f
 		LEFT JOIN rent_and_pay_data rapd ON f.title = rapd.title)
 INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
 SELECT nr.customer_id, nr.staff_id, nr.rental_id, pa.amount,  rapd.payment_date::timestamptz
 FROM rent_and_pay_data rapd
 LEFT JOIN payment_amount pa ON pa.title = rapd.title
 LEFT JOIN new_rent nr ON nr.rental_date::timestamptz = rapd.rental_date::timestamptz 
 LEFT JOIN rental r ON nr.rental_id = r.rental_id 
 WHERE NOT EXISTS (SELECT * FROM public.payment p  WHERE p.rental_id = r.rental_id)
 RETURNING *;