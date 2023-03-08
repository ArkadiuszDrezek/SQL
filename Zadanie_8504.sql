drop table if exists #sp_id 

;with zwroty_korespondencji_zgony as (
select
COUNT(ak_id) over (partition by ak_sp_id order by (select 1)) as ilosc_rezultatow,
sp_numer,
ak_sp_id as sp_id
from dm_data_bps..sprawa
join dm_data_bps..akcja on ak_sp_id=sp_id and ak_akt_id=329	
join dm_data_bps..rezultat on re_ak_id=ak_id and re_ret_id=70 
)

select 
distinct sp_id into #sp_id 
from zwroty_korespondencji_zgony 
where ilosc_rezultatow>=2
and not exists (
select 1 from dm_data_bps..akcja a where a.ak_akt_id in (324,1349) and a.ak_sp_id=sp_id
)

drop table if exists #ak_id
create table #ak_id (ak_id int)

merge dm_data_bps..akcja as target using (
select sp_id from #sp_id
) as source on 1=0
when not matched then insert
([ak_akt_id], [ak_sp_id], [ak_kolejnosc], [ak_interwal], [ak_zakonczono], [ak_pr_id], [ak_publiczna])
values (1349, sp_id, 0,0,getdate(),5,1)
output inserted.ak_id into #ak_id;

insert into dm_data_bps..rezultat
([re_ak_id],[re_data_planowana], [re_us_id_planujacy], [re_data_wykonania], [re_us_id_wykonujacy], [re_konczy])
select ak_id, GETDATE(), 5, GETDATE(), 5, 1 from #ak_id


