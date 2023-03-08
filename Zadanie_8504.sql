;with zwroty_korespondencji_zgony as (
select
COUNT(ak_id) over (partition by ak_sp_id order by (select 1)) as ilosc_rezultatow,
sp_numer,
ak_sp_id as sp_id,
ak_id,
re_komentarz
from sprawa
join akcja on ak_sp_id=sp_id and ak_akt_id=329	
join rezultat on re_ak_id=ak_id and re_ret_id=70 
)

select * from zwroty_korespondencji_zgony where ilosc_rezultatow>=2
and not exists (
select 1 from akcja a where a.ak_akt_id in (324,1349) and a.ak_sp_id=sp_id
)
