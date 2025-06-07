/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Семин Андрей Геннадьевич
 * Дата:  28.11.2024г.
*/

-- Часть 1. Исследовательский анализ данных

-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
WITH data_users AS (SELECT COUNT (DISTINCT id) AS count_users,
(SELECT COUNT (DISTINCT id)
FROM fantasy.users
WHERE payer = 1) AS count_users_pay
FROM fantasy.users)
SELECT *, ROUND(count_users_pay/count_users::NUMERIC,2) AS share_users_pay
FROM data_users

--Результат:
--count_users|count_users_pay|share_users_pay|
-------------+---------------+---------------+
--      22214|           3929|           0.18|
-- Игроки, купившие внутриигровую валюту "райские лепестки" 
-- составляют небольшую долю 0.18 (18% от всех игроков). 
-- Одним из вариантов получения большой прибыли от игры 
-- может быть введение новых акций и на приобретение 
-- внутриигровой валюты, а также маркетинговую кампанию 
-- внутри приложения.

WITH country_count_users AS (SELECT location, 
COUNT (DISTINCT id) AS count_users
FROM fantasy.users AS users
LEFT JOIN fantasy.country AS country USING (loc_id)
GROUP BY location),
country_count_user_pay AS (SELECT location, 
COUNT (DISTINCT id) AS count_users_pay
FROM fantasy.users AS users
LEFT JOIN fantasy.country AS country USING (loc_id)
WHERE payer = 1
GROUP BY location)
SELECT ccu.location, count_users, count_users_pay,
ROUND(count_users_pay/count_users::NUMERIC,2) AS share_users_pay
FROM country_count_users AS ccu
JOIN country_count_user_pay AS ccup USING (location)

-- Результат
-- location     |count_users|count_users_pay|share_users_pay|
-- -------------+-----------+---------------+---------------+
-- China        |        752|            117|           0.16|
-- Japan        |       1539|            263|           0.17|
-- Russia       |        328|             55|           0.17|
-- South Korea  |        538|            110|           0.20|
-- United States|      19057|           3384|           0.18|
-- По результатам запроса видно, что страной большинства игроков 
-- является US (Объединенные Штаты). В восточных страных игра не
-- настолько пока что не настолько популярна. При этом доля 
-- платящих игроков не сильно отличается между странами. 
-- Самая маленькая доля в Китае - 0.16 (16% от всех игроков),
-- Самая большая доля Южной Кореи - 0.2 (20% от всех игроков).
-- Воможно стоит усилить маркетинговую кампанию на популяризацию
-- игры в перечисленных странах.


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

WITH count_user_race AS 
(SELECT race, COUNT (id) AS count_users
FROM fantasy.users AS users
LEFT JOIN fantasy.race AS race USING (race_id)
GROUP BY race
),
count_user_race_pay AS 
(SELECT race, COUNT (id) AS count_users_pay
FROM fantasy.users AS users
LEFT JOIN fantasy.race AS race USING (race_id)
WHERE payer = 1
GROUP BY race
)
SELECT cur.race, count_users_pay, count_users,
ROUND (count_users_pay/count_users::NUMERIC, 2) AS share_users_race
FROM count_user_race AS cur
JOIN count_user_race_pay AS curp USING (race)
ORDER BY hare_users_race DESC

-- Результат (при сортировке по доле платящих пользоваетлей):
-- race    |count_users_pay|count_users|share_users_race|
-- --------+---------------+-----------+----------------+
-- Demon   |            238|       1229|            0.19|
-- Orc     |            636|       3619|            0.18|
-- Northman|            626|       3562|            0.18|
-- Hobbit  |            659|       3648|            0.18|
-- Human   |           1114|       6328|            0.18|
-- Elf     |            427|       2501|            0.17|
-- Angel   |            229|       1327|            0.17|
-- По результатам запроса количество платящих игроков не зависит
-- от расы. Доля платящих игроков от общего количества в разрезе
-- рас варьируется от 0.17 до 0.19 (от 17% до 19% игроков). При 
-- этом, самая большая доля платящих игроков играют за расу "Демон".
-- Результат (при сортировке по количеству игроков в разрезе расы):
-- race    |count_users_pay|count_users|share_users_race|
-- --------+---------------+-----------+----------------+
-- Human   |           1114|       6328|            0.18|
-- Hobbit  |            659|       3648|            0.18|
-- Orc     |            636|       3619|            0.18|
-- Northman|            626|       3562|            0.18|
-- Elf     |            427|       2501|            0.17|
-- Angel   |            229|       1327|            0.17|
-- Demon   |            238|       1229|            0.19|
-- Самым популярной расой является "Человек" - 6328 игроков,
-- самой непопулряной - "Демон" (1129 игроков). Возможно, это 
-- связано с уникальными характеристиками и навыками рас.
WITH count_user_class AS 
(SELECT class, COUNT (id) AS count_users
FROM fantasy.users AS users
LEFT JOIN fantasy.classes AS classes USING (class_id)
GROUP BY class
),
count_user_class_pay AS 
(SELECT class, COUNT (id) AS count_users_pay
FROM fantasy.users AS users
LEFT JOIN fantasy.classes AS classes USING (class_id)
WHERE payer = 1
GROUP BY class
)
SELECT cuc.class, count_users_pay, count_users,
ROUND (count_users_pay/count_users::NUMERIC, 2) AS share_users_class
FROM count_user_class AS cuc
JOIN count_user_class_pay AS cucp USING (class)
ORDER BY share_users_class DESC
LIMIT 7
-- Результат: 
-- class      |count_users_pay|count_users|share_users_class|
-- -----------+---------------+-----------+-----------------+
-- Engineer   |             12|         52|             0.23|
-- Necromancer|             63|        311|             0.20|
-- Monk       |            212|       1084|             0.20|
-- Bard       |            182|        954|             0.19|
-- Paladin    |            586|       3333|             0.18|
-- Archer     |            114|        641|             0.18|
-- Healer     |            335|       1832|             0.18|
-- На основе полученных результатов заметно, что в отличии от рас
-- размах значения доли платящих игроков в разрезе больше от 0.15
-- до 0.23 (от 15% до 23% от игроков). При этом, самая большая
-- доля платящих игроков отслеживается в классе "Инженер", который 
-- является самым непопулярным классом. Возможно, существует 
-- зависимость между популярностью класса и необходимостью "донатить"
-- для прохождения игры.
-- Самыми популярными классами среди игроков являются Рыцарь, 
-- Паладин и Хиллер. Однако, их популярность не зависит от
-- зависит от необходимости вносить внеигровую валюту для 
-- прохождения игры. Возможно, популярность этих классов
-- обусловлена форматом игры и уникальными умениями классов,
-- которые необходимы для игры в команде.
-- class      |count_users_pay|count_users|share_users_class|
-- -----------+---------------+-----------+-----------------+
-- Knight     |           1185|       6686|             0.18|
-- Paladin    |            586|       3333|             0.18|
-- Healer     |            335|       1832|             0.18|

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT COUNT (*) AS total_count,
SUM (amount) AS total_amount,
MIN (amount) AS min_amount,
MAX (amount) AS max_amount,
AVG (amount) AS avg_amount,
PERCENTILE_DISC (0.5) WITHIN GROUP (ORDER BY amount) 
AS median_amount,
STDDEV (amount) AS stddev_amount
FROM fantasy.events
-- Результат:
-- total_count|total_amount|min_amount|max_amount|avg_amount       |
-- -----------+------------+----------+----------+-----------------+
--     1307678|   686615040|       0.0|  486615.1|525.6919663589833|
-- 
-- median_amount|stddev_amount    |
-- -------------+-----------------+
--         74.86|2517.345444427788|
-- Общее количество внутриигровых покупок составило свыше 1,3 млн.
-- При этом их стоимость превысила 686,615 млн. Минимальная 
-- стоимость покупки составила 0. Это означает, что были покупки,
-- которые не принесли выручки разработчикам. Самая дорогая покупка
-- - 486615,1 райских лепестков. Разница между средним значением
-- стоимости одного заказа (приблизительно 525,69 райских лепестков)
-- и медианой (74,86 райских лепестка) подтверждает наличие большого
-- размаха в данных стоимости. Стандартное отклонение составило
-- 2517,35 райских лепестков. Таким образом, возможно найденное
-- максимальное значение может оказаться выбросом, который не входит 
-- в доверительный интервал. Стоит проверить значения самых дорогих
-- покупок.

SELECT item_code, amount
FROM fantasy.events
ORDER BY amount DESC 
LIMIT 10
-- Результат: 
-- item_code|amount   |
-- ---------+---------+
--      6010| 486615.1|
--      6010|449183.16|
--      6010| 374319.3|
--      6010| 374246.8|
--      6010| 366832.9|
--      6010|239564.34|
--      6010|230842.72|
--      6010|224591.56|
--      6010|224591.56|
--      6010|224591.56|
-- Полученые результаты демонстрирует, что в игре присутствует
-- эпический предмет, цена которого значительно отличается
-- от других и выходит за рамки стандартного среднего отклонения.
-- Возможно это очень редкий предмет.

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT COUNT (transaction_id) AS total_transaction_0,
COUNT (transaction_id)::NUMERIC/(SELECT COUNT (transaction_id)
FROM fantasy.events) AS share_of_total_transaction
FROM fantasy.events
WHERE amount = 0
-- Результат:
-- total_transaction_0|share_of_total_transaction|
-- -------------------+--------------------------+
--                 907|    0.00069359582404842782|
-- В таблице "events" присутствуют покупки, стоимость
-- которых составила 0. Таких покупок зафиксировано 907. 
-- В разрезе всех транзакций доля таких покупок составила
-- 0.00069 - менее 0.1% (0.069%). 
-- При детальном изучении можно также проверить зависимость 
-- между датой и временем совершенных покупок: возможно все 
-- "нулевые" покупки были совершены в один период времени из-за
-- технической неполадки. А также, сопоставить количество 
-- покупок с id-номерами продавцов. Возможно, один или несколько
-- продавцов продают (передают) предметы без денег.
-- Также следует проверить, зависимость таких покупок от пользователя
-- возможно все покупки совершены небольшим количеством пользо-
-- вателей.

SELECT seller_id, COUNT (transaction_id) AS total_transaction_0,
COUNT (transaction_id)::NUMERIC/(SELECT COUNT (transaction_id)
FROM fantasy.events) AS share_of_total_transaction
FROM fantasy.events
WHERE amount = 0
GROUP BY seller_id
ORDER BY total_transaction_0 DESC
LIMIT 5
-- Результат:
-- seller_id|total_transaction_0|share_of_total_transaction|
-- ---------+-------------------+--------------------------+
--          |                849|    0.00064924239759329131|
-- 888986   |                  8|0.000006117713993811932295|
-- 888991   |                  8|0.000006117713993811932295|
-- 888993   |                  7|0.000005352999744585440758|
-- 888990   |                  4|0.000003058856996905966148|
-- 849 "нулевых" покупок совершены не у продавца (отсутсвует 
-- ID продавца), а из внутриигрового магазина. Вероятнее всего
-- это предметы, которые были предложены пользователям в рамках
-- акции (подарка). Для этого следует проверить как такие покупки
-- распределены по номерам товаров

SELECT game_items, COUNT (transaction_id) AS total_transaction_0,
COUNT (transaction_id)::NUMERIC/(SELECT COUNT (transaction_id)
FROM fantasy.events) AS share_of_total_transaction
FROM fantasy.events AS events
LEFT JOIN fantasy.items AS items USING (item_code)
WHERE amount = 0
GROUP BY game_items
-- Результат:
-- game_items     |total_transaction_0|share_of_total_transaction|
-- ---------------+-------------------+--------------------------+
-- Book of Legends|                907|    0.00069359582404842782|
-- Таким образом, все "нулевые" покупки состояли из "Book of Legends"
-- при этом 849 из них были приобретены в игровом магазине.

SELECT id, COUNT (transaction_id) AS total_transaction_0,
ROUND(COUNT (transaction_id)::NUMERIC/(SELECT COUNT (transaction_id)
FROM fantasy.events WHERE amount = 0),4) AS share_of_total_transaction_0
FROM fantasy.events
WHERE amount = 0
GROUP BY id
ORDER BY total_transaction_0 DESC
-- Результат:
-- id        |total_transaction_0|share_of_total_transaction_0|
-- ----------+-------------------+--------------------------+
-- 12-1058351|                810|                    0.8931|
-- 42-0460342|                  6|                    0.0066|
-- 06-2087517|                  6|                    0.0066|
-- 10-9330719|                  5|                    0.0055|
-- 72-8559492|                  3|                    0.0033|
-- 01-0074905|                  3|                    0.0033|
-- 91-5947409|                  2|                    0.0022|
-- 68-7223575|                  2|                    0.0022|
-- 98-9613732|                  2|                    0.0022|
-- 43-1868563|                  2|                    0.0022|
-- 05-4786250|                  2|                    0.0022|
-- 35-9222579|                  2|                    0.0022|
-- 60-9357143|                  2|                    0.0022|
-- 06-5381730|                  2|                    0.0022|
-- 18-8964800|                  1|                    0.0011|
-- 19-4544004|                  1|                    0.0011|
-- Почти все "нулевые" покупки были совершены одним пользователем
-- (89,3% от всех "нулевых"). Учитывая большое число покупок,
-- вероятнее всего это тестовый пользователь. Однако,
-- также присутвуют и другие игроки (суммарно 71 пользователь исключая 
-- тестового), которые совершали бесплатные покупки. 

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
WITH info_users AS
(SELECT id, COUNT (transaction_id) AS total_count,
SUM (amount) AS total_amount, payer
FROM fantasy.events AS events
FULL JOIN fantasy.users AS users USING (id)
WHERE amount <> 0
GROUP BY id, payer)
SELECT 
CASE 
	WHEN payer = 0
	THEN 'Неплатящие игроки'
	WHEN payer = 1
	THEN 'Платящие игроки'
	ELSE 'Пустые значения'
END AS status_user,
COUNT (id) AS total_users,
ROUND (AVG (total_count)::NUMERIC ,2) AS avg_count_user,
ROUND (AVG (total_amount)::NUMERIC ,2) AS avg_amount_user
FROM info_users
GROUP BY payer
-- Результат:
-- status_user      |total_users|avg_count_user|avg_amount_user|
-- -----------------+-----------+--------------+---------------+
-- Неплатящие игроки|      18285|         60.55|       48627.45|
-- Платящие игроки  |       3929|         51.02|       55467.74|
-- Количество платящих игроков составляет приблизительно 18% от
-- общего числа игроков. Среднее количество не "нулевых" 
-- заказов на одного игрока в группе неплатящих игроков больше,
-- чем в группе платящих игроков. Однако, средняя сумма
-- потраченных лепестков выше у платящих игроков. Возможно,
-- платящие игроки приобретают предметы лучшего качества, тем
-- самым реже совершая покупки, в отличии от неплатящих.

-- 2.4: Популярные эпические предметы:
WITH total_count_item AS (SELECT game_items, items.item_code,
COUNT (events.item_code) AS total_count_item,
ROUND (COUNT (events.item_code)::NUMERIC / (SELECT COUNT (transaction_id) 
FROM fantasy.events WHERE amount <> 0),3) AS share_total_items
FROM fantasy.events AS events
FULL JOIN fantasy.items AS items USING (item_code)
WHERE amount <> 0
GROUP BY game_items, items.item_code
),
item_by_user AS 
(SELECT items.item_code, 
ROUND (COUNT (DISTINCT id)::NUMERIC/
(SELECT COUNT (DISTINCT id) FROM fantasy.events WHERE amount <> 0),4) AS share_user_buy
FROM fantasy.items AS items
LEFT JOIN fantasy.events AS events USING (item_code)
WHERE amount <> 0
GROUP BY item_code
)
SELECT game_items, total_count_item,
share_total_items, share_user_buy
FROM total_count_item AS tci
JOIN item_by_user AS ibu USING (item_code)
ORDER BY total_count_item DESC
LIMIT 20;

-- Результат: 
-- game_items            |total_count_item|share_total_items|share_user_buy|
-- ----------------------+----------------+-----------------+--------------+
-- Book of Legends       |         1004516|            0.769|        0.8841|
-- Bag of Holding        |          271875|            0.208|        0.8677|
-- Necklace of Wisdom    |           13828|            0.011|        0.1180|
-- Gems of Insight       |            3833|            0.003|        0.0671|
-- Treasure Map          |            3084|            0.002|        0.0546|
-- Amulet of Protection  |            1078|            0.001|        0.0323|
-- Silver Flask          |             795|            0.001|        0.0459|
-- Strength Elixir       |             580|            0.000|        0.0240|
-- Glowing Pendant       |             563|            0.000|        0.0257|
-- Gauntlets of Might    |             514|            0.000|        0.0204|
-- Sea Serpent Scale     |             458|            0.000|        0.0043|
-- Ring of Wisdom        |             379|            0.000|        0.0225|
-- Potion of Speed       |             375|            0.000|        0.0167|
-- Magic Ornament        |             282|            0.000|        0.0082|
-- Ring of Invisibility  |             252|            0.000|        0.0133|
-- Magical Lantern       |             247|            0.000|        0.0074|
-- Herbs for Potions     |             241|            0.000|        0.0107|
-- Potion of Acceleration|             230|            0.000|        0.0131|
-- Feather of Writing    |             222|            0.000|        0.0112|
-- Time Artifact         |             168|            0.000|        0.0107|
-- Представлен список ТОП-20 предметов, которые пользователи 
-- преобриетают больше всего. Самый популярный эпический
-- предмет это "Book of Legends" - почти 77% транзакций
-- из всех. На втором месте по популярности покупок расположен
-- предмет "Bag of Holding" (приблизительно 20,8%). При этом,
-- доля пользователей, которые хотя бы раз приобрели 
-- предмет для этих двух предметов, приблизительно равна, и 
-- составляет 88,4% и 86,8% соответственно. Стоит также отметить,
-- что транзакции связанные с покупкой одного из этих предметов
-- составляет приблизительно 0.977 (97,7%) от всех не нулевых транзакций.
-- Также, если посмотреть все записи, будет заметно, что
-- часть предметов приобреталась намного реже или вовсе не 
-- покупались. Возможно, команде разработчиков стоит пересмотреть
-- показатели и характеристики эпических предметов.


-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
WITH info_users AS
( 
SELECT id, race, COUNT (transaction_id) AS total_count,
SUM (amount) AS total_amount
FROM fantasy.events AS events
LEFT JOIN fantasy.users AS users USING (id)
LEFT JOIN fantasy.race AS race USING (race_id)
WHERE amount <> 0
GROUP BY id, race
),
race_info AS 
(
SELECT race, AVG (total_count) AS avg_buy_users,
AVG (total_amount) AS avg_total_amount_users
FROM info_users
GROUP BY race
),
avg_by_race AS 
( SELECT race, 
ROUND (SUM (amount::NUMERIC)/COUNT (transaction_id), 4) AS avg_amount_users
FROM fantasy.events AS events
LEFT JOIN fantasy.users AS users USING (id)
LEFT JOIN fantasy.race AS race USING (race_id)
WHERE amount <> 0
GROUP BY race
),
user_by_race AS
(
SELECT race, 
COUNT (users.id) AS total_user_count
FROM fantasy.race AS race
RIGHT JOIN fantasy.users AS users USING (race_id)
GROUP BY race
),
userbuy_by_race AS 
(
SELECT race, COUNT (DISTINCT events.id) AS buy_user_count
FROM fantasy.events AS events
LEFT JOIN fantasy.users AS users USING (id)
LEFT JOIN fantasy.race AS race USING (race_id)
WHERE amount <> 0
GROUP BY race
),
userpay_by_race AS 
(
SELECT race, COUNT (id) AS pay_user_count
FROM fantasy.users AS users
LEFT JOIN fantasy.race AS race USING (race_id)
WHERE payer = 1 AND id IN (SELECT DISTINCT id 
FROM fantasy.events WHERE amount <> 0) 
GROUP BY race
),
race_x_user AS 
(
SELECT race, total_user_count,
buy_user_count, ROUND (buy_user_count::NUMERIC/total_user_count,2)
AS share_buy_users,
ROUND (pay_user_count::NUMERIC/buy_user_count,2) AS share_pay_users
FROM user_by_race AS ubr
JOIN userbuy_by_race AS ebbr USING (race)
JOIN userpay_by_race AS upbr USING (race)
)
SELECT race, total_user_count, buy_user_count, share_buy_users,
share_pay_users, avg_buy_users, avg_amount_users, avg_total_amount_users
FROM race_x_user AS rxu
JOIN race_info AS ri USING (race)
JOIN avg_by_race AS abr USING (race)
ORDER BY avg_total_amount_users DESC
-- Результат:
-- race    |total_user_count|buy_user_count|share_buy_users|share_pay_users|avg_buy_users       |avg_amount_users|avg_total_amount_users|
-- --------+----------------+--------------+---------------+---------------+--------------------+----------------+----------------------+
-- Northman|            3562|          2229|           0.63|           0.18| 82.1018393898609242|        761.5013|    62520.659329105394|
-- Elf     |            2501|          1543|           0.62|           0.16| 78.7906675307841866|        682.3348|     53761.65357472614|
-- Human   |            6328|          3921|           0.62|           0.18|121.4021933180311145|        403.1308|     48941.00985064767|
-- Angel   |            1327|           820|           0.62|           0.17|106.8048780487804878|        455.6782|    48668.653708467544|
-- Hobbit  |            3648|          2266|           0.62|           0.18| 86.1288614298323036|        552.9032|     47620.92312036146|
-- Orc     |            3619|          2276|           0.63|           0.17| 81.7381370826010545|        510.9003|     41760.04062863972|
-- Demon   |            1229|           737|           0.60|           0.20| 77.8697421981004071|        529.0551|    41197.379648772156|
-- Доля людей, которые приобретают эпические предметы для всех рас,
-- приблизительно одинакова (от 60% - Демон до 63% - Орк и Северянин). 
-- Тоже можно сказать о доле в отношении игроков, которые
-- хотя бы раз приобретали эпический предмет. Исключением является
-- раса "Демон". В ней доля немного выше, чем в остальных расах и
-- составляет 0.20 (20%), а в расе "Эльф" наоборот ниже остальных - 0.16
-- (16%). Это может говорить о том, что игрокам - демонам приходится
-- чаще покупать эпические предметы за внеигровую валюту, а эльфам
-- реже. Больше всего эпических предметов 
-- приобретают игроки расы "Люди" и "Ангелы" (в среднем свыше 100
-- эпических предмета на игрока), что говорит о возможной сложности
-- игры за них и необходимости приобретать больше предметов
-- для прохождения игры. Средняя стоимость одной покупки
-- для игроков в разбивке по расам расположена в интервале от 
-- (403,1 - Человек до 761,5 - Северянин). Возможно, именно
-- по этой причине, за расу "Человек" играет больше пользователей:
-- среднее количество транзакций на одного пользователя больше,
-- но средняя сумма транзакций ниже (следует проверить, как часто  
-- пользователи этой расы покупают эпические предметы). Возмонжо,
-- покупка предметов носит периодическую низкую активность малыми суммами. 
-- По результатам запроса заметно, что
-- среднее значение всех затрат игроков в разрезе рас больше
-- всего у "Северянин" - 62520,  меньше всего у "Демон" - 41197.
-- При этом все расы можно поделить на 3 группы по сумме общих затрат:
-- Северянин и Эльф - высокий уровень общих затрат;
-- Человек, Ангел и Хоббит - средний уровень затрат;
-- Орк и Демон - низкий уровень затрат.
-- Таким образом, можно сделать вывод, что игра за разные расы 
-- сложнее и требует разного уровня общих затрат на эпические 
-- предметы.  



-- Задача 2: Частота покупок
WITH events_date AS
(
SELECT transaction_id, id, date::date + time::time AS date,
item_code, amount, seller_id
FROM fantasy.events),
events_with_lag_value AS
(
SELECT *,
EXTRACT (DAY FROM date - LAG (date) OVER (PARTITION BY id ORDER BY date))
AS lag_date
FROM events_date
),
user_events AS
(
SELECT events.id, payer, COUNT (transaction_id) AS total_count,
AVG (lag_date) AS avg_day_between
FROM events_with_lag_value AS events
LEFT JOIN fantasy.users AS users USING (id)
WHERE amount <> 0
GROUP BY events.id, payer
HAVING COUNT (transaction_id) >=25
),
users_by_group AS 
(
SELECT *,
NTILE (3) OVER (ORDER BY avg_day_between) AS ranks
FROM user_events
),
info_by_ranks_pay AS
(
SELECT ranks, COUNT (id) AS count_userpay
FROM users_by_group
WHERE payer = 1
GROUP BY ranks
),
count_users AS 
(
SELECT ranks, COUNT (id) AS total_count_user
FROM users_by_group
GROUP BY ranks
),
rank_x_user AS 
(
SELECT ranks, total_count_user, count_userpay,
ROUND(count_userpay::NUMERIC/total_count_user,2) AS share_userpay
FROM info_by_ranks_pay AS ibrp
JOIN count_users AS cu USING (ranks)
GROUP BY ranks, total_count_user, count_userpay
),
info_by_ranks AS
(
SELECT ranks, AVG (total_count) AS avg_total_count,
AVG (avg_day_between) AS avg_day_between_users
FROM users_by_group
GROUP BY ranks
)
SELECT 
CASE
	WHEN ranks = 1
	THEN 'Высокая частота'
	WHEN ranks = 2
	THEN 'Умеренная частота'
	WHEN ranks = 3
	THEN 'Низкая частота'
END AS group_of_users,
total_count_user,
count_userpay,
share_userpay,
avg_total_count,
avg_day_between_users
FROM info_by_ranks AS ibr
JOIN rank_x_user AS rxu USING (ranks)
ORDER BY ranks
-- Результат
-- group_of_users   |total_count_user|count_userpay|share_userpay|avg_total_count     |avg_day_between_users     |
-- -----------------+----------------+-------------+-------------+--------------------+--------------------------+
-- Высокая частота  |            2572|          473|         0.18|390.6617418351477449|2.892042406129937768317659|
-- Умеренная частота|            2572|          450|         0.17| 58.7947122861586314|        7.0952505644287412|
-- Низкая частота   |            2572|          434|         0.17| 33.6461897356143079|       12.8349328527763528|
-- По результатам запроса видно, что доля платящих игроков в сформированных
-- группах не сильно отличается между группами - от 0.17 до 0.18
-- (17% - 18%), но большее значение в группе в высокой активностью.  При этом видно, что 
-- среднее значение покупок пользователей, попавших в группу с
-- высокой частотой заказа, сильно отличается от других групп и 
-- составляет 390, при значениях в других группах 58 и 33 
-- соответственно. При этом, средняя частота покупок составляет
-- почти 3 дня для игроков из группы высокой частоты.

-- 3. Общий вывод
-- В результате анализа данных можно сделать вывод о том, что
-- приобретение эпических предметов является важной составляющей
-- игры, которая положительно влияет на характеристику
-- персонажей (большая часть игроков - приблизительно 62%) 
-- совершают внутриигровые покупки. 
-- Платящие игроки в среднем приобретают меньше предметов, чем
-- неплатящие, однако общая сумма затрат на покупку предметов
-- у них выше. Возможно, платящие игроки сразу покупают
-- предметы, которые имеют большую цену и лучшие характеристики.
-- Наблюдается небольшая зависимость количества приобретения 
-- эпических предметов и общие затраты на их покупку от расы.
-- Также заметно, что большая доля платящих игроков - демоны.
-- В остальных случаях группа платящих игроков распределяется
-- почти равномерно.
-- Стоит обратить внимание на большое количество предметов,
-- которые не пользуются популярностью среди игроков и вовсе 
-- не приобретались. Также стоит обратить внимание на предмет
-- "Book of Legends": есть покупки предмета, которые
-- были "нулевыми", и при этом самые дорогие покупки также
-- связаны с приобретением этого предмета. Отделу маркетинга 
-- также стоит продумать рекламную кампанию для популяризации
-- игры в других странах, игроки из которых присутствуют в 
-- выгрузке.





