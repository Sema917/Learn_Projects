SELECT COUNT(id)
FROM donorsearch.user_anon_data

SELECT region, COUNT(DISTINCT id) AS count_users
FROM donorsearch.user_anon_data
GROUP BY region 
ORDER BY COUNT(DISTINCT id) DESC
limit 10

-- В список регионов России с наибольшем количеством зарегистрированных
-- доноров входит Москва - 37819, Санкт-Петербург - 13137,
-- Татарстан(Казань) - 6610 и  Новосибирская область 
-- (Новосибирск) - 3310.
-- Также присутствует регион Украины - Киевская область (Киев) - 3541.
-- При этом, приблизительно 38% (100574) доноров не указали 
-- в анкете свой регион проживания.

SELECT DATE_TRUNC('MONTH', donation_date) AS month_donation,
	   COUNT(id)
FROM donorsearch.donation_anon 
WHERE donation_date::timestamp >='2022-01-01 00:00:00' AND 
	  donation_date::timestamp <='2023-12-01 00:00:00'
GROUP BY DATE_TRUNC('MONTH',donation_date)
ORDER BY month_donation
-- По данным за 2022 и 2023 тенденция роста количества доноров отсутствует.
-- В динамике общего количества донаций в разбиве по месяцам сложно
-- за эт и два года сложно отследить повторяющийся характер. 
-- В 2022 году в мае произошло снижение количества донаций, возможно
-- причиной этому явилась вспышка оспа оспы обезьян в нерахактерных
-- для этого вирусах странах. 
-- В 2023 году можно заметить тенденцию снижения количества донаций
-- которая началась с апреля 2023 года. Низкое значение количества
-- донаций в ноябре скорее всего связано с тем, что данные 
-- представлены не за полный месяц.


SELECT user_id,count_donation
FROM (SELECT user_id, COUNT(id) AS count_donation
	  FROM donorsearch.donation_anon 
	  WHERE donation_status = 'Принята'
	  GROUP BY user_id
	  ORDER BY count_donation DESC) as list_user
LIMIT 20
-- В том 20 вошли следующие пользователи системы 235391
-- 273317
-- 211970
-- 201521
-- 132946
-- 216353
-- 53912
-- 233686
-- 204073
-- 267054
-- 229012
-- 221198
-- 165291
-- 142345
-- 253080
-- 234212
-- 122493
-- 246984
-- 182697
-- 135223
-- В верхушке топа - пользователь совершивший 361 донацию (с подверждением)
-- На 20 месте пользователь со 163 донациями.

WITH 
donor_activity AS (SELECT uan.id,
						  uan.confirmed_donations,
						  COALESCE (uab.user_bonus_count,0) AS count_bonus
				   FROM donorsearch.user_anon_data AS uan
				   LEFT JOIN donorsearch.user_anon_bonus AS uab on uab.user_id=uan.id)
SELECT 
CASE 
	WHEN count_bonus > 0 THEN 'Получили бонусы'
	ELSE 'Не получили бонусы' END AS status_bonus,
	COUNT(id),
	AVG(confirmed_donations)
FROM donor_activity 
GROUP BY status_bonus

-- 21108 пользователей получили и воспользовались бонусами
-- при этом 256 491 - бонусы не получили. Можно отметить
-- положительное влияние системы бонусов на количество донаций
-- т.к. среднее значение донаций на пользователя 
-- у первой группы пользователей составляет почти 14, 
-- в то время как у другой группы 0,52

SELECT 
CASE WHEN autho_vk = TRUE THEN 'Вконтакте'
	 WHEN autho_ok = TRUE THEN 'Одноклассники'
	 WHEN autho_tg = TRUE THEN 'Телеграм'
	 WHEN autho_yandex = TRUE THEN 'Яндекс ID'
	 WHEN autho_google = TRUE THEN 'Google-аккаунт'
	 ELSE 'Без авторизации через соцсети' END AS соцсеть,
	 COUNT (id),
	 AVG (confirmed_donations)
FROM donorsearch.user_anon_data
GROUP BY соцсеть

-- соцсеть                      |count |avg                   |
-------------------------------+------+----------------------+
-- Google-аккаунт               | 14292|1.07850545759865659110|
-- Без авторизации через соцсети|113266|0.70709656913813500962|
-- Вконтакте                    |127254|0.91232495638643971899|
-- Одноклассники                |  6410|0.55678627145085803432|
-- Телеграм                     |   481|    1.1746361746361746|
-- Яндекс ID                    |  4133|    1.7280425840793612|

-- Самая популярная социальная площадка, через которую осуществлялись
-- переходы на ресурс и последующая регистрация - Вконтакте.
-- При этом более активные доноры переходят на сайт из Яндекса и
-- Телеграма. Меньше всего переходов произведено именно из Телеграма.
-- Большое количество доноров зарегистрировались через ВК. Это связано
-- с тем, что Вконтакте счиатется одной из самых популярных социальных
-- сетей. При этом, ВК предоставляет большие возможности для 
-- проведения рекламных акций, благодаря которым доноры начали регистрацию на сервисе.

WITH donor_activity AS
(SELECT user_id,
		COUNT(*) AS total_count,
		(MAX(donation_date) - MIN(donation_date)) AS activity_days,
		((MAX(donation_date) - MIN(donation_date))/COUNT(*)-1) AS days_between,
		EXTRACT (YEAR FROM MIN(donation_date)) AS first_year,
		EXTRACT (YEAR FROM AGE(CURRENT_DATE, MIN(donation_date))) AS years_since
 FROM donorsearch.donation_anon
 GROUP BY user_id
 HAVING COUNT(*)>1
)
SELECT first_year,
CASE 
	WHEN total_count BETWEEN 2 AND 3 THEN '2-3 донации'
	WHEN total_count BETWEEN 4 AND 5 THEN '4-5 донаций'
	ELSE '6 и более донаций' 
	END AS groups_of_donor,
	COUNT (user_id),
	AVG (total_count),
	AVG (activity_days),
	AVG (days_between),
	AVG (years_since)
FROM donor_activity
GROUP BY first_year, groups_of_donor
ORDER BY first_year, groups_of_donor

-- Ошибки в данных при заполнении или переносе
-- В 2022 и 2023 году многие доноры соверешили повторну сдачу по сравнению с предыдущими
-- годами. Однако в 20223 году количество доноров сдавшиз кровь более
-- 3 раз в разы меньше чем в предыдущие года. При этом показатели
-- среднего количества донаций также уменьшаются.

WITH donation_actual
AS ( SELECT user_id,
			donation_date
	FROM donorsearch.donation_anon),
	donation_planing as
( select user_id, donation_date, donation_type
from donorsearch.donation_plan),
plan_actual as
(select dp.user_id, dp.donation_date, dp.donation_type,
case 
	when da.donation_date is not null then 1 
	else 0
end as completed
from donation_planing as dp
left join donation_actual as da on dp.user_id=da.user_id and dp.donation_date = da.donation_date
)
select donation_type, count(user_id), SUM(completed),
ROUND ((SUM(completed)/COUNT(user_id)::numeric *100),2)
from plan_actual
group by donation_type

-- donation_type|count|sum |round|
-- -------------+-----+----+-----+
-- Безвозмездно |24362|5280|21.67|
-- Платно       | 3470| 459|13.23|
