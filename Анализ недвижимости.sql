/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Семин Андрей Геннадьевич
 * Дата: 17.12.2024
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ) 
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ), 
info_with_category AS (
SELECT *,
CASE 
	WHEN city.city = 'Санкт-Петербург' THEN 'Санкт-петербург'
	ELSE 'ЛенОбл'
	END AS region, 
CASE
	WHEN advertisement.days_exposition BETWEEN 0 AND 30 THEN 'до месяца'
	WHEN advertisement.days_exposition BETWEEN 31 AND 90 THEN 'до трех месяцев'
	WHEN advertisement.days_exposition BETWEEN 91 AND 180 THEN 'до полугода'
	WHEN advertisement.days_exposition > 180 THEN 'более полугода'
	WHEN advertisement.days_exposition IS NULL THEN 'не сданы (проданы)'
END AS category,
advertisement.last_price::NUMERIC/flats.total_area AS price_for_one
FROM real_estate.flats
LEFT JOIN real_estate.city AS city USING (city_id)
LEFT JOIN real_estate.advertisement AS advertisement USING (id)
LEFT JOIN real_estate."type" AS "type" USING (type_id)
WHERE id IN (SELECT * FROM filtered_id) AND "type" = 'город' 
)
SELECT 
region, category, COUNT (id) AS count_advertisement,
ROUND (COUNT (id)::NUMERIC / (SELECT COUNT (id) FROM info_with_category)*100,2) AS percentage_of_advertisement,
ROUND (AVG (price_for_one::NUMERIC),2) AS avg_price_for_one,
ROUND (AVG (total_area::NUMERIC),2) AS avg_total_area,
PERCENTILE_DISC (0.5) WITHIN GROUP (ORDER BY rooms) AS mediana_rooms,
MODE () WITHIN GROUP (ORDER BY rooms) AS mode_rooms,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS mediana_balcony,
MODE () WITHIN GROUP (ORDER BY balcony) AS mode_balcony,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS mediana_floor,
MODE () WITHIN GROUP (ORDER BY floor) AS moda_floor,
ROUND (SUM (is_apartment)::NUMERIC /COUNT(id)*100,2) AS percentage_apartement,
ROUND (SUM (open_plan)::NUMERIC / COUNT (id)*100,2) AS percentage_open_plan,
ROUND (AVG (airports_nearest::NUMERIC),2) AS avg_airports,
ROUND (AVG (parks_around3000::NUMERIC),2) AS avg_parks,
ROUND (AVG (ponds_around3000::NUMERIC),2) AS avg_ponds
FROM info_with_category
GROUP BY region, category
-- Результат: 
-- region         |category          |count_advertisement|percentage_of_advertisement|avg_price_for_one|avg_total_area|mediana_rooms|mode_rooms|mediana_balcony|mode_balcony|mediana_floor|moda_floor|percentage_apartement|percentage_open_plan|avg_airports|avg_parks|avg_ponds|
-- ---------------+------------------+-------------------+---------------------------+-----------------+--------------+-------------+----------+---------------+------------+-------------+----------+---------------------+--------------------+------------+---------+---------+
-- ЛенОбл         |более полугода    |                890|                       5.56|         68297.22|         55.41|            2|         2|            1.0|         0.0|            3|         1|                 0.11|                0.00|    35185.07|     0.77|     1.12|
-- ЛенОбл         |до месяца         |                397|                       2.48|         73275.25|         48.72|            2|         1|            1.0|         1.0|            4|         4|                 0.50|                0.50|    33464.65|     0.84|     0.91|
-- ЛенОбл         |до полугода       |                556|                       3.47|         69846.39|         51.83|            2|         2|            1.0|         0.0|            3|         2|                 0.18|                0.18|    33673.42|     0.89|     1.04|
-- ЛенОбл         |до трех месяцев   |                917|                       5.73|         67573.43|         50.88|            2|         2|            1.0|         0.0|            3|         2|                 0.11|                0.22|    36665.09|     0.84|     1.17|
-- ЛенОбл         |не сданы (проданы)|                461|                       2.88|         73625.63|         57.87|            2|         1|            1.0|         1.0|            3|         1|                 0.43|                0.00|    31996.45|     0.77|     0.96|
-- Санкт-петербург|более полугода    |               3581|                      22.36|        115457.22|         66.15|            2|         2|            1.0|         0.0|            5|         2|                 0.20|                0.11|    27469.61|     0.68|     0.87|
-- Санкт-петербург|до месяца         |               2168|                      13.54|        110568.88|         54.38|            2|         1|            1.0|         2.0|            5|         2|                 0.32|                0.23|    27427.76|     0.56|     0.72|
-- Санкт-петербург|до полугода       |               2254|                      14.08|        111938.92|         60.55|            2|         2|            1.0|         0.0|            5|         3|                 0.18|                0.18|    28146.66|     0.60|     0.75|
-- Санкт-петербург|до трех месяцев   |               3236|                      20.21|        111573.24|         56.71|            2|         1|            1.0|         0.0|            5|         2|                 0.09|                0.56|    28073.12|     0.58|     0.77|
-- Санкт-петербург|не сданы (проданы)|               1554|                       9.70|        134632.92|         72.03|            2|         3|            2.0|         1.0|            5|         2|                 0.64|                0.00|    27621.74|     0.70|     0.87|
-- Большая часть объявлений представлена в городе Санкт-Петербург (12793 из 16014), остальные - в городах Ленинградской области.
-- Сегменты объявлений поделены на 5 категорий (до месяца, до трех месяцев, до полугода, более полугода и не сданы (проданы).
-- 13.54% квартир в Санкт-Петербурге  (2.48% в городах Ленинградской области) продаются в течении первого месяца после размещения объявления.
-- К причинам этих сделок можно отнести следующие факторы: 
-- по сравнению с другими сделками средняя стоимость квадратного метра в объявлениях составляет 110568,88 - самая низкая цена за метр 
-- по сравнению с другими сегментами (для Ленинградской области 73275,25 - самая высокая цена среди проданных квартир - возможно из-за расположения квартир);
-- общая площадь квартир в Санкт-Петербурге в среднем составляет 54.38 квадратных метра при медианных значениях количества комнат - 2
-- (для Ленинградской области - 48.72 при медианных значениях комнат - 2), при этом мода транслирует, что большинство приобретаемых квартир в этом
-- сегменте - однокомнатные.
-- 20.21% квартир в Санкт-петербурге (5.73% в городах Ленинградской области) продаются в течении от двух до трех месяцев.
-- Как и в первом случае к причинам можно отнести:
-- средняя площадь квартир данного сегмента ниже, чем у сегментов с большей длительностью активности объявлений (56.71 - Санкт-петербург, 
-- 50.88 - города Ленинградской области), при этом для этого сегмента чаще всего представлены однокомнатные квартиры в Санкт-петербурге и 2-х комнатные в Ленинградской области.
-- средняя цена за квадратный метр: для Санкт-Петербурга - 111573.24, для городов Ленинградской области - 67573.43 - самая низкая цена за квадратный метр. 
-- Третий сегмент - до полугода: 14,08% - Санкт-петербург, 3.47% - города Ленинградской области.
-- Четвертый сегмент - свыше полугода: 22.36% - Санкт-Петербург, 5.56% - города Ленинградской области.
-- В перечисленных сегментах можно выделить те же причины, что и в предыдущих.
-- Вывод: сегментация рынка недвижимости по активности объявлений зависит от площади и количества комнат в квартирах, а также от цены
-- за один квадратный метр. В Санкт-Петербурге главной причиной можно выделить цену за квадратный метр, а также количество комнат.
-- Быстрее всего снимаются объявления однокомнатных квартир с более низкой ценой за квадрат, на второе место можно вынести однушки с большой ценой за квадрат,
--  третье - двухкомнатные квартиры с чуть большей ценой, четвертое - двушки с большой ценой за квадрат. О зависимости
-- активности объявления от стоимости за один квадратный метр также можно говорить рассматривая сегмент "не сданы (проданы)", у которого
-- самая высокая средняя цена.
-- В Ленинградской области наоборот, приобретение квартиры больше зависит от ее площади и количества комнат, а не от стоимости за квадратный метр.
-- При этом, цена за квадратный метр также является важной причиной приобретения, это заметно между всеми сегментами активности объявлений кроме "до месяца".
-- Еще одной особенностью можно выделить то, что часто встречаемое количество балконов в квартирах в Санкт-Петербурге составляет 0, при этом
-- быстрее всего проданы квартиры, в которых часто встречаются два балкона. В сегмент "не сданы (проданы) часто встречаемое количество комнат составлений 3 в отличии от остальных сегментов.
--  В Ленинградской области наоборот, в сегменте "не сданы (проданы)" также как и "до месяца" часто встречаются квартиры с одним балконом.
-- Это может говорить о том, что покупатели заинтересованы в балконе, однако в первую очередь ориентируются на стоимость.
-- Отличаются также и этажность: медиана для Санкт-Петербурга в зависимости от сегмент расположена на 5 этаже, при моде 2-3 этаж,
-- в Ленинградской области - медиана варьируется от 3 до 4 в зависимости от сегмента, а мода - 1 - 4. В Ленинградской области - мода 
-- этажа у быстрых объявлений - 4, в остальных - 1-2. 
-- Также, главным отличием между квартирами в Санкт-Петербурге и другими городами Ленинградской области является количество парков и прудов
-- на расстоянии 3 км от дома - в Ленинградской области количество парков и водоемов выше. 
-- Маленькое количество квартир выполнены в формате апартаментов и студий, однако можно заметить, что в Санкт-Петербурге 
-- апартаменты и квартиры студии представлены в большем количестве в сегменте "до месяца" и "до трех месяцев". Больше всего апартаментов
-- в Санкт-Петербурге находятся в сегменте "Не сданы (проданы)". В Ленинградской области также как в Санкт-Петербурге большинство апартаментов
-- и студий представлены в сегменте "до месяца", а также большое количество аппртаментов находятся в сегменте "не сданы (проданы)".

-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ), 
-- Выведем объявления без выбросов:
info_with_months AS (
SELECT *,
EXTRACT (MONTH FROM first_day_exposition) AS first_month_exposition,
EXTRACT (MONTH FROM first_day_exposition + days_exposition * INTERVAL '1 day') AS last_month_exposition, 
EXTRACT (YEAR FROM first_day_exposition) AS YEAR,
last_price::NUMERIC	/ total_area AS price_for_one
FROM real_estate.flats AS flats
LEFT JOIN real_estate.advertisement AS advertisement USING (id)
LEFT JOIN real_estate."type" AS "type" USING (type_id)
WHERE id IN (SELECT * FROM filtered_id) AND "type"='город'
),
count_advertisement AS 
(
 SELECT YEAR,first_month_exposition, ROUND(AVG (price_for_one::NUMERIC),2) AS avg_price,
 ROUND (AVG (total_area::NUMERIC),2) AS avg_area,
 COUNT (id) AS count_advertisement, 
 RANK () OVER (ORDER BY COUNT(id) DESC ) AS rank_advertisement
 FROM info_with_months
 GROUP BY YEAR, first_month_exposition
),
count_sale AS 
(
 SELECT YEAR, last_month_exposition, 
 ROUND(AVG (price_for_one::NUMERIC),2) AS avg_price_sale,
 ROUND (AVG (total_area::NUMERIC),2) AS avg_area_sale,
 COUNT (id) AS count_sale, 
 RANK () OVER (ORDER BY COUNT(id) DESC ) AS rank_sale
 FROM info_with_months
 WHERE last_month_exposition IS NOT NULL
 GROUP BY YEAR, last_month_exposition
)
SELECT cs.YEAR, last_month_exposition, avg_price, avg_area, count_advertisement, rank_advertisement, avg_price_sale, avg_area_sale,count_sale,
 rank_sale 
FROM count_advertisement AS ca
FULL JOIN count_sale AS cs ON ca.first_month_exposition = cs.last_month_exposition AND ca.YEAR = cs.YEAR
WHERE cs.YEAR BETWEEN 2015 AND 2018
ORDER BY avg_price DESC
-- Результат:
-- year|last_month_exposition|avg_price|avg_area|count_advertisement|rank_advertisement|avg_price_sale|avg_area_sale|count_sale|rank_sale|
-- ----+---------------------+---------+--------+-------------------+------------------+--------------+-------------+----------+---------+
-- 2018|                    2|102430.07|   58.84|                836|                 1|     104425.64|        58.73|       389|       15|
-- 2017|                   11|102761.66|   59.22|                828|                 2|     100735.81|        56.32|       563|        4|
-- 2017|                    9|106289.78|   59.91|                711|                 3|     102154.85|        57.71|       448|       11|
-- 2018|                    3|103785.76|   57.24|                626|                 4|     101096.28|        55.71|       500|        9|
-- 2017|                   10|102890.65|   58.66|                620|                 5|     104121.05|        58.34|       576|        3|
-- 2018|                   10|104251.27|   57.57|                607|                 7|     106044.35|        55.85|       516|        8|
-- 2017|                   12|102109.19|   57.13|                594|                 8|     105020.84|        59.81|       581|        2|
-- 2018|                    7|103002.37|   59.27|                560|                 9|     103850.84|        56.40|       225|       27|
-- 2017|                    8|106169.35|   59.10|                534|                11|     100430.96|        57.26|       398|       14|
-- 2018|                   11|109855.55|   59.11|                521|                12|     108687.30|        55.04|       533|        6|
-- 2018|                    8|108857.25|   57.96|                507|                13|      98590.31|        54.02|       370|       18|
-- 2017|                    6| 99304.36|   58.39|                486|                14|      99715.59|        58.06|       343|       21|
-- 2017|                    4|100852.35|   60.55|                480|                15|      99954.42|        59.98|       358|       20|
-- 2018|                    9|109665.59|   59.96|                472|                16|     104741.77|        56.03|       476|       10|
-- 2017|                    5| 98660.07|   57.56|                420|                17|     100043.91|        58.66|       319|       23|
-- 2017|                    7|107210.53|   61.37|                416|                18|      98915.35|        58.00|       382|       17|
-- 2018|                    1|103545.49|   56.99|                396|                19|     108473.10|        56.61|       334|       22|
-- 2016|                    6|108220.43|   60.49|                354|                21|      99002.83|        61.04|       190|       29|
-- 2018|                    6|108097.68|   56.19|                317|                22|     112099.84|        61.42|       172|       31|
-- 2016|                    5|105875.09|   61.47|                314|                23|      89402.57|        57.39|        80|       41|
-- 2016|                    4| 97103.20|   60.82|                308|                24|     101890.04|        59.44|        88|       40|
-- 2017|                    2|104497.86|   61.65|                303|                25|     104268.46|        62.19|       522|        7|
-- 2016|                    3|101912.77|   60.32|                253|                27|     109876.73|        64.60|       112|       35|
-- 2018|                   12|111381.83|   60.09|                221|                28|     108332.48|        56.94|       434|       12|
-- 2017|                    1|109099.26|   57.97|                206|                29|      99232.64|        54.94|       681|        1|
-- 2018|                    4|115889.13|   60.01|                195|                30|     103456.00|        57.68|       540|        5|
-- 2016|                    2|101287.32|   61.36|                177|                31|     100964.12|        64.22|        92|       38|
-- 2017|                    3| 97835.51|   64.85|                151|                32|     114785.23|        63.64|       406|       13|
-- 2015|                   11|101657.05|   63.90|                119|                33|      97991.80|        61.01|        63|       46|
-- 2015|                   12|107946.74|   63.92|                119|                33|      98516.88|        67.07|        54|       47|
-- 2015|                   10|108039.27|   68.20|                117|                35|     104507.04|        65.56|        89|       39|
-- 2018|                    5|108089.92|   55.84|                108|                36|     100833.03|        56.13|       292|       24|
-- 2016|                    7|100671.26|   57.66|                107|                37|     104004.76|        57.63|       365|       19|
-- 2016|                   11|102999.81|   59.89|                101|                38|     100101.97|        62.57|       142|       33|
-- 2016|                    9|102538.59|   65.29|                 95|                39|     103687.41|        57.56|       234|       26|
-- 2016|                   10|105679.98|   65.66|                 93|                40|      99876.17|        65.92|       179|       30|
-- 2016|                   12|101956.62|   60.32|                 90|                41|     100136.78|        61.80|       106|       36|
-- 2015|                    3|102158.82|   70.28|                 89|                42|      93591.73|        70.39|        53|       48|
-- 2016|                    1|101319.71|   62.22|                 88|                43|     113855.42|        64.16|       143|       32|
-- 2015|                    8|108284.31|   66.78|                 67|                45|     102482.75|        61.59|       105|       37|
-- 2015|                    6|111028.65|   57.37|                 67|                45|      94587.01|        61.31|        66|       45|
-- 2015|                    7|106137.56|   68.73|                 66|                47|     104590.31|        66.01|       136|       34|
-- 2015|                    9|113758.43|   75.40|                 63|                48|     111917.93|        64.78|        80|       41|
-- 2016|                    8| 97626.84|   57.96|                 58|                49|     100495.80|        58.21|       264|       25|
-- 2015|                    2|110657.66|   66.99|                 53|                50|     100705.13|        62.98|        45|       49|
-- 2015|                    5|100830.76|   65.89|                 49|                51|     110247.00|        63.89|        38|       51|
-- 2015|                    1|124299.84|   77.74|                 45|                52|     126443.07|        74.24|        67|       44|
-- 2015|                    4|101905.31|   62.43|                 38|                53|     111194.77|        71.12|        45|       49|
-- Сезонность влияет! По полученным данным самыми активными годами по публикации объявлений является 2017 и 2018 года, менее активный - 2015.
-- Можно выделить топ месяцев, в которые больше всего публикуют объявления о продаже квартиры: Февраль 2018 (836 объявления); Ноябрь 2017 (828 объявлений)
-- Март 2018 (626 объявлений), Октябрь 2017 (620 объявлений), Октябрь 2018 и т.д. 
-- При этом, высокая активность покупателей выпадает на следующие месяцы: Январь 2017 (681 покупка), Декабрь 2017 (581 покупка), Октябрь 2017 (576 покупок), 
-- Ноябрь 2017 (563 покупки), Апрель 2018 (540 покупок), Ноябрь 2018 (533 покупки), Февраль 2017 (522 покупки) и т.д. Меньше всего покупок происходило в 2015 году. 
-- Самыми неактивными месяцами с точки зрения приобретения квартир можно выделить:Май, Июнь, Июль, Август
-- Таким образом, можно заметить, что пользователи активнее всего размещают объявления в 1 и 4 квартилах. Активность покупателей также выпадает на 1 и 4 квартиль, тем самым, почти совпадая с продавцами (Ноябрь, Декабрь, Октябрь, Январь, Февраль).
-- Совпадения присутствует и в менее популярные месяцы: Август, Июнь, Июль, Май, Апрель
-- Сезонность также влияет на среднюю стоимость одного квадратного метра: 
-- - минимальная цена представлена в Феврале, Марте, Ноябре;
-- - максимальная цена - Сентябрь, Июнь, Август, Январь.
-- Вероятнее всего, на среднюю цену влияет не только сезонность, но и количество размещаемых объявлений. Так как основные пики размещения объявлений
-- выпадают на период Октябрь - Март, в которые размещается большинство объявлений - пользователи уменьшают цену, чтобы быстрее продать жилье.
-- Говорить о влиянии сезонности на среднее значение площади продаваемых квартир сложно, требуется дополнительная проверка о статистической значимости полученных значений.



-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
filtered_id_lenobl AS 
(
SELECT *, last_price::NUMERIC/total_area AS price_for_one
FROM real_estate.flats AS flats
LEFT JOIN real_estate.city AS city USING (city_id)
LEFT JOIN real_estate.advertisement AS advertisement USING (id)
WHERE id IN (SELECT * FROM filtered_id) AND city <> 'Санкт-Петербург'
),
count_advertisement AS 
(
SELECT city, COUNT (id) AS count_advertisement,
DENSE_RANK () OVER (ORDER BY COUNT (id) DESC) AS rank
FROM filtered_id_lenobl
GROUP BY city
),
all_information AS 
(
SELECT city, RANK, count(id) AS count_advertisement,
ROUND ((count(days_exposition)::NUMERIC / count (id))*100,2) AS percentage_of_advertisement,
ROUND (AVG (price_for_one::NUMERIC),2) AS avg_price,
ROUND(AVG (total_area::NUMERIC),2) AS avg_area,
ROUND (AVG (days_exposition::NUMERIC),2) AS duration
FROM filtered_id_lenobl AS fil
LEFT JOIN count_advertisement AS ca USING (city)
LEFT JOIN real_estate."type" AS "type" USING (type_id)
GROUP BY city, rank
ORDER BY rank
)
SELECT SUM(count_advertisement)
FROM all_information

-- Результат:
-- city           |rank|count_advertisement|percentage_of_advertisement|avg_price|avg_area|duration|
-- ---------------+----+-------------------+---------------------------+---------+--------+--------+
-- Мурино         |   1|                568|                      93.66| 85968.38|   43.86|  149.21|
-- Кудрово        |   2|                463|                      93.74| 95420.47|   46.20|  160.63|
-- Шушары         |   3|                404|                      92.57| 78831.93|   53.93|  152.04|
-- Всеволожск     |   4|                356|                      85.67| 69052.79|   55.83|  190.11|
-- Парголово      |   5|                311|                      92.60| 90272.96|   51.34|  156.21|
-- Пушкин         |   6|                278|                      83.09|104158.94|   59.74|  196.57|
-- Гатчина        |   7|                228|                      89.04| 69004.74|   51.02|  188.11|
-- Колпино        |   8|                227|                      92.07| 75211.73|   52.55|  147.01|
-- Выборг         |   9|                192|                      87.50| 58669.99|   56.76|  182.33|
-- Петергоф       |  10|                154|                      88.31| 85412.48|   51.77|  196.57|
-- Сестрорецк     |  11|                149|                      89.93|103848.09|   62.45|  214.81|
-- Красное Село   |  12|                136|                      89.71| 71972.28|   53.20|  205.81|
-- Новое Девяткино|  13|                120|                      88.33| 76879.07|   50.52|  175.65|
-- Сертолово      |  14|                117|                      86.32| 69566.26|   53.62|  173.58|
-- Бугры          |  15|                104|                      87.50| 80968.41|   47.35|  155.90|
-- Наиболее активно объявления о недвижимости публикуют в следующих городах Ленинградской области:
-- Мурино, Кудрово, Всеволожск, Шушары (свше 350). Суммарно они составляют почти 28.32% от всех объявлений 
-- недвижимости в Ленинградской области. 
-- Самая высокая доля снимаемых публикаций представлена в:  Мурино, Кудрово, Шушары, Парголово, Колпино (свыше 90%)
-- Присутствует зависимость средней стоимости и времени активности объявлений от населенного пункта.
-- Быстрее всего объявления снимались в населенном пункте "Колпино", медленнее всего  в "Сестрорецк". При этом, средняя стоимость одного квадратного
-- метра меньше всего в "Выборге". Также заметно, что самые большие значения средней стоимости за одни квадратный метр и площади квартир 
-- представлены в населенных пунктах "Пушкин" и "Сестрорецк".
-- Средняя площадь продаваемых квартир ниже всего в Мурино и Кудрово. При этом, сроки их продажи не находятся на первых местах, но попадают в топ-5, что может
-- говорить о привлекательности этих населенных пунктов, учитывая что стоимость одного квадратного метра также входит в ТОП-5 по убыванию значений.
-- В данных присутствует вариация, для более детального изучения следует также рассмотреть тип населенного пункта.
-- Результат с указанием типа:
-- city           |type   |rank|count_advertisement|percentage_of_advertisement|avg_price|avg_area|duration|
-- ---------------+-------+----+-------------------+---------------------------+---------+--------+--------+
-- Мурино         |город  |   1|                 32|                       0.00| 92178.59|   47.03|        |
-- Мурино         |посёлок|   1|                536|                      99.25| 85597.62|   43.67|  149.21|
-- Кудрово        |город  |   2|                169|                      82.84|100098.48|   46.17|  114.44|
-- Кудрово        |деревня|   2|                294|                     100.00| 92731.41|   46.21|  182.63|
-- Шушары         |посёлок|   3|                404|                      92.57| 78831.93|   53.93|  152.04|
-- Всеволожск     |город  |   4|                356|                      85.67| 69052.79|   55.83|  190.11|
-- Парголово      |посёлок|   5|                311|                      92.60| 90272.96|   51.34|  156.21|
-- Пушкин         |город  |   6|                278|                      83.09|104158.94|   59.74|  196.57|
-- Гатчина        |город  |   7|                228|                      89.04| 69004.74|   51.02|  188.11|
-- Колпино        |город  |   8|                227|                      92.07| 75211.73|   52.55|  147.01|
-- Выборг         |город  |   9|                192|                      87.50| 58669.99|   56.76|  182.33|
-- Петергоф       |город  |  10|                154|                      88.31| 85412.48|   51.77|  196.57|
-- Сестрорецк     |город  |  11|                149|                      89.93|103848.09|   62.45|  214.81|
-- Красное Село   |город  |  12|                136|                      89.71| 71972.28|   53.20|  205.81|
-- Новое Девяткино|деревня|  13|                120|                      88.33| 76879.07|   50.52|  175.65|
-- Сертолово      |город  |  14|                117|                      86.32| 69566.26|   53.62|  173.58|
-- Бугры          |посёлок|  15|                104|                      87.50| 80968.41|   47.35|  155.90|
-- При указании типа населенного пункта, значения изменились (несколько поселков и деревень впоследствии приняли другой статус), в связи с
-- чем объявления разделились. Особенно заметны изменения в Кудрово и Мурино, после того, как деревня приобрела статус города, снизились показатели
-- продаж квартир, при этом сильно увеличилась стоимость за один квадратный метр, и время продажи квартиры. 
-- Вероятнее всего, ценообразование и актуальность квартир в городе зависит от его расположения и статуса. Однако, однозначно можно говорить о том,
-- Мурино, Кудрово, Шушары, Парлогово, Сестрорецк, Колпино пользуются популярностью среди покупателей с точки зрения
-- доли проданных квартир/домов, а также сроков их продажи.