SELECT MIN (salary_from) AS MIN_salary_from, 
       AVG (salary_from)::numeric(8,2) AS AVG_salary_from,
       MAX (salary_from) AS MAX_salary_from,
       MIN (salary_to) AS MIN_salary_to,
       AVG (salary_to)::numeric(8,2) AS AVG_salary_to,
       MAX (salary_to) AS MAX_salary_to
FROM public.parcing_table;
-- Средняя заработная плата в нижних порогах зарабтной платы 
-- составляет 109 525, а в верхних порогах - 153 846,7. Мини
-- -мальная оплата труда в нижнем пороге заработной платы 
-- составляет 50 рублей, что скорее всего является ошибкой данных
-- максимальная  - 497 500 рублей

SELECT employer, COUNT (*) AS count_name_employer
FROM public.parcing_table
GROUP BY employer
ORDER BY count_name_employer DESC
LIMIT 10;
-- Самой крупной компанией - работадателем выступает СБЕР,
-- который явлется крупным банком на террритории РФ. Такое
-- количество свидетельствует о большей потребности кадров
-- в области аналитиков данных в финансовой сфере. На 2 и 3 месте
-- расположились компании обеспечивающие e-commerce. Спрос на аналитиков 
-- весьма высокий.




SELECT area, count(*) AS count_name_area
FROM public.parcing_table
GROUP BY area
ORDER BY count_name_area DESC
LIMIT 10;
-- Больше всего аналитиков требуется в крупных городах страны. 
-- Это, скорее всего, связано с большим количеством организаций
-- расположенных именно в крупных городах. Лидерами является Москва
-- и Санкт-Петербург. При этом Москва демонстрирует безоговорочное
-- лидерство в этом списке, что свидетельствует о том, что офисы 
-- большинства компаний расположены в Москве.



SELECT employment, COUNT (*) AS count_employment
FROM public.parcing_table
GROUP BY employment 
ORDER BY count_employment DESC;
-- Осноной тип занятости: полная занятость. Это свидетельствует 
-- о том, что в большинстве случаев компании ищут специалистов 
-- на постоянную основу в штат.




SELECT schedule, count(*) AS count_schedule
FROM public.parcing_table
GROUP BY schedule
ORDER BY count_schedule DESC;
-- 1441 предложение работы требует полного рабочего дня, 310 - удаленная работа

SELECT COUNT(*)
FROM public.parcing_table
WHERE name LIKE '%Аналитик данных%' OR 
	  name LIKE '%Системный аналитик%'
-- Всего позиций аналитиков данных и системных аналитокв - 1157
	  
	  
SELECT experience, COUNT(*) AS count_experience, 100*COUNT(*)::NUMERIC/1157 AS percent_experience
FROM public.parcing_table
WHERE name LIKE '%Аналитик данных%' OR name LIKE '%Системный аналитик%'
GROUP BY experience 
ORDER BY count_experience;
-- Больше всего вакансий среди аналитиков данных и системных
-- аналитиков находятся в грейде Junior+(1-3 years). Их объем
-- составляет 65% от всех вакансий. На втором месте по популярности
-- расположен грейд Middle (3-6 years). Меньше всего вакансий 
-- для аналитиков данных и системных аналитиков высшего уровня 
-- Senior. Многие фирмы ищут себе аналитиков младшего класса
-- для выполнения большого объема нетрудных задач, с которыми
-- сталкиваются постоянно.



SELECT employer, employment, schedule, COUNT(*) AS count_name, AVG(salary_from) AS AVG_salary_from, AVG (salary_to) AS AVG_salary_to
FROM public.parcing_table
WHERE name LIKE '%Аналитик данных%' OR name LIKE '%Системный аналитик%'
GROUP BY employer, employment, schedule
ORDER BY count_name DESC;


SELECT key_skills_1, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY key_skills_1 
ORDER BY skills DESC 
LIMIT 5

-- Во многих объявлениях не указаны ключевые навыки для работы.
-- Однако, самыми популярными навыками являются "Анализ данных"
-- - 312 вакансий, а также знание SQL.

SELECT key_skills_2, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY key_skills_2 
ORDER BY skills DESC 
LIMIT 5

-- Вторым ключевым навыком чаще всего указывают SQL - 318 позиций
-- при этом много вакансий, у которых в объявлении второй ключевой
-- навык уже не указывается - 641 позиция. На втором месте по популярности 
-- располагается Python - 142

SELECT key_skills_3, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY key_skills_3 
ORDER BY skills DESC 
LIMIT 5

-- SQL также популярно встречается в третьем ключевом навыке. На
-- втором месте также расположился Python - 130. Прослеживается 
-- тенденция увеличения пустых значений - 753

SELECT key_skills_4, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY key_skills_4 
ORDER BY skills DESC 
LIMIT 5

-- В четвертом ключевом навыке чаще всего указывают Python - 113
-- и SQL - 61. Количество пустых значений в 4-ом ключевом навыке
-- составило - 864.

-- Таким образом, можно сделать вывод, что самыми популярными
-- кдючевыми навыками являются SQL, Анализ данных, Python. 
-- Чаще всего первым ключевым навыком выбирают Анализ данных.
-- Однако, в остальных он встречается реже. Популярнее всего на
-- 2-4 ключевом навыке указывают SQL и Python.

SELECT soft_skills_1, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY soft_skills_1 
ORDER BY skills DESC 
LIMIT 5

-- На первом мягком навыке чаще всего указывают знание документации
-- - 234 позиции. На втором - коммуникация (181 позиция). Однако,
-- в большинстве вакансий не указан первый мягкий навык.

SELECT soft_skills_2, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY soft_skills_2 
ORDER BY skills DESC 
LIMIT 5

-- В качестве второго мягкого навыка чаще всего указываются 
-- знание документации - 46 случаев, и аналитическое мышление
-- - 32 случая. Также увеличичвается количество вакансий,
-- в которых не указываютя мягкие навыки

SELECT soft_skills_3, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY soft_skills_3 
ORDER BY skills DESC 
LIMIT 5


-- На третьем месте чаще вскго указывают аналитическое мышление.
-- Количество пустых значений - 1779

SELECT soft_skills_4, COUNT(*) AS skills
FROM public.parcing_table
GROUP BY soft_skills_4 
ORDER BY skills DESC 
LIMIT 5


-- Таким образом, чаще всего в качестве мягких навыков указывают 
-- знание документации, развитые способности к коммуникации и
-- аналитическое мышление. В отличии от ключевых навыков,
-- мягким навыкам компании-работадатели уделяют меньшее внимание,
-- этому свидетелсьвтует большее количество незаполненных
-- полей: в 1213 вакансиях не указаны мягкие навыки, в то время как
-- ключевые не указаны в 383 случаях.