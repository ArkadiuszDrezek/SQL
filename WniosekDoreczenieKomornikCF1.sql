select * from akcja_typ where akt_nazwa = 'Wniosek o doreczenie komornik CF1'


if OBJECT_ID('tempdb..#MAILE27') is not null drop table #MAILE27

select ROW_NUMBER() over(order by (select 0)) rn,* INTO #MAILE27 from (
select distinct us_email,sp_numer, ak_id, US_DEPARTMENT, sprawa.sp_id, sp_pr_id
from dm_data_bps.dbo.sprawa 
join dm_data_bps.dbo.operator on op_sp_id=sp_id
join dm_data_bps.dbo.ge_user on op_us_id=us_id 
join dm_data_bps.dbo.akcja on ak_sp_id=sp_id and ak_akt_id=1317
join dm_data_bps..rezultat on re_ak_id=ak_id and DATEADD(dd, 90, cast(re_data_wykonania as date)) = CAST(getdate() as date) 
left join CFBPS_Raporty_kontrolne.dbo.Wysylka_komunikatow_do_pracownikow w on w.akt_id_476_ak_id = ak_id
join dm_logic_bps..cache_sprawa_info v on v.sp_id=sprawa.sp_id
where (op_data_do is null or op_data_do='2100-01-01 00:00:00.000') and op_opt_id=1
and MAIL_ID is null
and sprawa_zamknieta=0
)W 

insert into CFBPS_Raporty_kontrolne.dbo.Wysylka_komunikatow_do_pracownikow (akt_id_1317_ak_id)
select ak_id
from #MAILE27

declare @licz27 int=1
declare @max27 int=(select COUNT(1) from #MAILE27)
declare @tresc27 varchar(2100)
declare @temat27 varchar(2100)
declare @adresat27 varchar(2100)
declare @dw_adresat27 varchar(2100)

while @licz27<=@max27

BEGIN

	set @adresat27 = (select US_EMAIL from #MAILE27 where rn=@licz27)

	set @dw_adresat27 = (
	select top 1 case when uko_ko_id = 149 and sp_pr_id in (220,115,270) then 'martyna.ksepka@cfsa.pl'
	when uko_ko_id<>149 and ak_akt_id=990 then 'aneta.bielinska@cfsa.pl'
	when uko_ko_id = 149 and sp_pr_id in (252,221,265) then 'joanna.klapec@cfsa.pl' 
	when uko_ko_id<>149 and ak_akt_id=934 then 'adam.gryziak@cfsa.pl' end 										
	from #MAILE27 
	join dm_data_bps.dbo.wierzytelnosc_rola on wir_sp_id=sp_id 
	join dm_data_bps.dbo.wierzytelnosc on wir_wi_id=wi_id 
	join dm_data_bps.dbo.dokument on do_wi_id=wi_id 
	join dm_data_bps.dbo.umowa_kontrahent on do_uko_id=uko_id
	left join dm_data_bps.dbo.akcja on ak_sp_id=sp_id and ak_akt_id in (990,934) 
	where RN=@licz27
	) 

	set @temat27='Wniosek o dorêczenie komornik CF1 - WERYFIKACJA'

	set @tresc27 ='Proszê o weryfikacjê czy komornik dorêczy³ korespondencjê w sprawie nr '+(select sp_numer from #MAILE27 where rn=@licz27)

	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'SQLProfile',
	@recipients = @adresat27,
	@copy_recipients = @dw_adresat27,
	@body = @tresc27,
	@subject = @temat27

	set @licz27=@licz27+1

END


