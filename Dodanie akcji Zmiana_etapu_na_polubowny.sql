drop table if exists #sp_id
select
s.sp_id into #sp_id
from sprawa as s
join dm_logic_bps.dbo.Raport_6_widok_pom1_a v on s.sp_id=v.sp_id and pakiet=5022

drop table if exists #ak_id
create table #ak_id (ak_id int)

merge akcja as target using (
select sp_id from #sp_id
) as source on 1=0
when not matched then insert
([ak_akt_id], [ak_sp_id], [ak_kolejnosc], [ak_interwal], [ak_zakonczono],[ak_pr_id], [ak_publiczna])
values (10002, sp_id, 0,0,getdate(), 5, 1)
output inserted.ak_id into #ak_id;

insert into rezultat
([re_ak_id],[re_data_planowana], [re_us_id_planujacy], [re_data_wykonania], [re_us_id_wykonujacy], [re_konczy])
select ak_id, GETDATE(), 5, GETDATE() ,5 ,1 from #ak_id
