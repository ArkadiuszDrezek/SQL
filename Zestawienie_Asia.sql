--opis - dodatkowe info
;with powiadomienia_dlugi_info as (
select
s.sp_numer,
s.sp_id,
CAST(re_data_wykonania as date) data_wyslania,
ak_id,
akt_nazwa
from sprawa s
join dm_logic_bps.dbo.Raport_6_widok_pom1_a v on s.sp_id=v.sp_id and pakiet<>5010
join akcja on ak_sp_id=s.sp_id and ak_akt_id=1350
join akcja_typ on ak_akt_id=akt_id
join (select max(re_id) max_re_id, re_ak_id from rezultat group by re_ak_id) as max_rez on max_rez.re_ak_id=ak_id
join rezultat r2 on max_rez.max_re_id=r2.re_id
),
wszystkie_pisma as (
select
s.sp_numer,
s.sp_id,
CAST(re_data_wykonania as date) data_wyslania,
ak_id,
akt_nazwa,
pwsz_sciezka
from sprawa s
join dm_logic_bps.dbo.Raport_6_widok_pom1_a v on s.sp_id=v.sp_id and pakiet<>5010
join akcja on ak_sp_id=s.sp_id and ak_akt_id in (
 178
,1243
,1259
,1315
,1357
,1392
,1453
)
join akcja_typ on ak_akt_id=akt_id
join pismo_wychodzace_szablon on pwsz_akt_id=akt_id
join akcja_pismo on apis_ak_id=ak_id
join akcja_pismo_wychodzace on apis_apisw_id=apisw_id
join akcja_pismo_plik on app_apis_id=apis_id
join (select max(re_id) max_re_id, re_ak_id from rezultat group by re_ak_id) as max_rez on max_rez.re_ak_id=ak_id
join rezultat r2 on max_rez.max_re_id=r2.re_id
)

select distinct pdi.sp_numer as nr_sprawy, pdi.akt_nazwa as powiadomienie_dlugi_info, pdi.data_wyslania as data_wyslania_powiadomienia, wp.akt_nazwa as nazwa_pisma, wp.pwsz_sciezka, wp.data_wyslania as data_wyslania_pisma from powiadomienia_dlugi_info pdi
join wszystkie_pisma wp on pdi.sp_id=wp.sp_id and wp.ak_id>pdi.ak_id

