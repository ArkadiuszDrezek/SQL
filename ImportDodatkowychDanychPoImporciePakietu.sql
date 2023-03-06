drop table if exists #ImportExcelGlowny
select W.* into #ImportExcelGlowny FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 8.0; Database=D:\BS\ImportNowegoPakietu_5022.xls', 'SELECT * FROM [Role$]')W

--DODANIE S¥DÓw
drop table #Sady
SELECT ROW_NUMBER() OVER (
		PARTITION BY sp_id ORDER BY sp_id
		) AS RN
	,COUNT(sp_id) over (partition by sp_id order by (select 0)) as SumaPartycja
	,sp_numer
	,sp_id
	,[in_id s¹du]
	,val as in_id

into #Sady

FROM #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id
CROSS APPLY (
	SELECT val
	FROM dm_logic_bps.dbo.fnSplitStringVarchar([in_id s¹du], ';')
	) x

 if exists (select 1 from #Sady where in_id is not null)

 begin
		--dodanie nieaktywnych s¹dów
		merge dm_data_bps.dbo.sprawa_instytucja as target using (
		select sp_id,rtrim(ltrim(in_id)) in_id from #Sady where RN<=SumaPartycja-1 and in_id<>''
		) as source on 1=0
		when not matched then insert
		([spi_sp_id], [spi_in_id], [spi_data_od], [spi_data_do], [spi_pr_id_aktywacja],[spi_pr_id_deaktywacja])
		values (sp_id,in_id,getdate()-2,getdate()-1,5,5);

		--dodanie aktywnych s¹dów
		merge dm_data_bps.dbo.sprawa_instytucja as target using (
		select sp_id,in_id from #Sady where RN=SumaPartycja and in_id<>''
		) as source on 1=0
		when not matched then insert
		([spi_sp_id], [spi_in_id], [spi_data_od], [spi_data_do], [spi_pr_id_aktywacja])
		values (sp_id,in_id,getdate(),'2100-01-01',5);
 end


--DODANIE KOMORNIKÓW
drop table if exists #Komornicy
SELECT ROW_NUMBER() OVER (
		PARTITION BY sp_id ORDER BY sp_id
		) AS RN
	,COUNT(sp_id) over (partition by sp_id order by (select 0)) as SumaPartycja
	,sp_numer
	,sp_id
	,[in_id komornika]
	,val as in_id

into #Komornicy

FROM #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id
CROSS APPLY (
	SELECT val
	FROM dm_logic_bps.dbo.fnSplitString([in_id komornika], ';')
	) x

if exists (select 1 from #Komornicy where in_id is not null)

begin
		--dodanie nieaktywnych komorników
		merge dm_data_bps.dbo.sprawa_instytucja as target using (
		select sp_id,in_id from #Komornicy where RN<=SumaPartycja-1
		) as source on 1=0
		when not matched then insert
		([spi_sp_id], [spi_in_id], [spi_data_od], [spi_data_do], [spi_pr_id_aktywacja],[spi_pr_id_deaktywacja])
		values (sp_id,in_id,getdate()-2,getdate()-1,5,5);

		--dodanie aktywnych komorników
		merge dm_data_bps.dbo.sprawa_instytucja as target using (
		select sp_id,in_id from #Komornicy where RN=SumaPartycja and in_id<>0
		) as source on 1=0
		when not matched then insert
		([spi_sp_id], [spi_in_id], [spi_data_od], [spi_data_do], [spi_pr_id_aktywacja])
		values (sp_id,in_id,getdate(),'2100-01-01',5);
end

--DODANIE SYGNATUR S¥DOWYCH
drop table #SygnaturySadowe
SELECT ROW_NUMBER() OVER (
		PARTITION BY sp_id ORDER BY sp_id
		) AS RN
	,COUNT(sp_id) over (partition by sp_id order by (select 0)) as SumaPartycja
	,sp_numer
	,sp_id
	,[Sygnatura s¹dowa]
	,val as syg_numer

into #SygnaturySadowe

FROM #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id
CROSS APPLY (
	SELECT val 
	FROM dm_logic_bps.dbo.fnSplitStringVarchar([Sygnatura s¹dowa], ',')
	) x
	
if exists (select 1 from #SygnaturySadowe where syg_numer is not null)

begin
		--dodanie nieaktynwych sygnatur
		merge dm_data_bps.dbo.sygnatura as target using (
		select sp_id,syg_numer from #SygnaturySadowe where RN<=SumaPartycja-1
		) as source on 1=0
		when not matched then insert
		([syg_sp_id], [syg_numer], [syg_data_od], [syg_data_do], [syg_sadowa])
		values (sp_id,syg_numer,getdate()-2,getdate()-1,1);

		--dodanie aktywnych sygnatur
		merge dm_data_bps.dbo.sygnatura as target using (
		select sp_id,syg_numer from #SygnaturySadowe where RN=SumaPartycja and syg_numer<>''
		) as source on 1=0
		when not matched then insert
		([syg_sp_id], [syg_numer], [syg_data_od], [syg_data_do], [syg_sadowa])
		values (sp_id,syg_numer,getdate(),'2100-01-01',1);
end

--DODANIE SYGNATUR KOMORNICZYCH
drop table #SygnaturyKomornicze

SELECT ROW_NUMBER() OVER (
		PARTITION BY sp_id ORDER BY sp_id
		) AS RN
	,COUNT(sp_id) over (partition by sp_id order by (select 0)) as SumaPartycja
	,sp_numer
	,sp_id
	,[Sygnatura komornicza]
	,val as syg_numer

into #SygnaturyKomornicze

FROM #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id
CROSS APPLY (
	SELECT val
	FROM dm_logic_bps.dbo.fnSplitStringVarchar([Sygnatura komornicza], ',')
	) x

if exists (select 1 from #SygnaturyKomornicze where syg_numer is not null)

begin
		--dodanie nieaktynwych sygnatur
		merge dm_data_bps.dbo.sygnatura as target using (
		select sp_id,syg_numer from #SygnaturyKomornicze where RN<=SumaPartycja-1
		) as source on 1=0
		when not matched then insert
		([syg_sp_id], [syg_numer], [syg_data_od], [syg_data_do], [syg_komornicza])
		values (sp_id,syg_numer,getdate()-2,getdate()-1,1);

		--dodanie aktywnych sygnatur
		merge dm_data_bps.dbo.sygnatura as target using (
		select sp_id,syg_numer from #SygnaturyKomornicze where RN=SumaPartycja and syg_numer<>''
		) as source on 1=0
		when not matched then insert
		([syg_sp_id], [syg_numer], [syg_data_od], [syg_data_do], [syg_komornicza])
		values (sp_id,syg_numer,getdate(),'2100-01-01',1);
end

--DODANIE AKCJI "D£U¯NIK MA NIERUCHOMOSC"
select * from #ImportExcelGlowny

drop table if exists #DMN
SELECT 
	sp_numer
	,sp_id
	,LTRIM(RTRIM(isnull(Imiê, '') + ' ' + isnull(Nazwisko, '') + ' ' + isnull([Nazwa firmy], ''))) AS dluznik_nazwa
	,val as KW

into #DMN

FROM #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id
CROSS APPLY (
	SELECT val
	FROM dm_logic_bps.dbo.fnSplitStringVarchar([DMN KW], ';')
	) x

create table #MergeLog (ak_id int,KW varchar(max),dluznik_nazwa varchar(max))

merge dm_data_bps.dbo.akcja as target using (
select sp_id, KW,dluznik_nazwa from #DMN
) as source on 1=0
when not matched then insert
([ak_akt_id], [ak_sp_id], [ak_kolejnosc], [ak_interwal], [ak_zakonczono], [ak_pr_id], [ak_publiczna])
values (375,sp_id,1,1,getdate(),5,1)
output inserted.ak_id,source.KW,source.dluznik_nazwa into #MergeLog;

insert into dm_data_bps.dbo.rezultat
([re_ak_id], [re_ret_id], [re_data_planowana], [re_us_id_planujacy], [re_data_wykonania], [re_us_id_wykonujacy], [re_konczy], [re_komentarz])
select ak_id,case when ISNULL(KW,'')<>'' then 341 else 596 end,GETDATE(),5,GETDATE(),5,1, case when ISNULL(KW,'')<>'' then 'D£U¯NIK: '+UPPER(dluznik_nazwa)+', nr KW: '+KW
else 'D£U¯NIK: '+UPPER(dluznik_nazwa)+'BRAK NIERUCHOMOŒCI' end from #MergeLog

insert into dm_data_bps.dbo.atrybut_akcji
(atak_ak_id,atak_atakt_id,atak_wartosc)
select ak_id,57,KW from #MergeLog where ISNULL(KW,'')<>''

--DODANIE AKCJI "WP£ATY PRZED CESJ¥"
drop table if exists #WPC
select 
sp_id
,[WPC rezultat]
,[WPC data ostatniej wp³aty]
,[WPC kwota ostatniej wp³aty]
,[WPC suma wp³at]
,[WPC liczba wp³at] 

into #WPC

from #ImportExcelGlowny
INNER JOIN dm_data_bps.dbo.rachunek_bankowy ON rb_nr = [numer rachunku bankowego] collate Polish_CI_AS
INNER JOIN dm_data_bps.dbo.sprawa ON sp_rb_id = rb_id

if exists (select 1 from #WPC where wpc_liczba_wplat is not null)

begin
		drop table if exists #WPC_MergeLog
		create table #WPC_MergeLog (
		 ak_id int
		,wpc_rezultat varchar(50)
		,wpc_data_ostatniej_wplaty date
		,wpc_kwota_ostatniej_wplaty decimal(18,2)
		,wpc_suma_wplat decimal(18,2)
		,wpc_liczba_wplat int 
		)

		merge dm_data_bps.dbo.akcja as target using (
		select * from #WPC
		) as source on 1=0
		when not matched then insert
		(ak_akt_id, ak_sp_id, ak_kolejnosc, ak_interwal, ak_zakonczono, ak_pr_id, ak_publiczna)
		values (1043,sp_id,0,0,getdate(),5,1)
		output inserted.ak_id,source.[WPC rezultat], source.[WPC data ostatniej wp³aty], source.[WPC kwota ostatniej wp³aty], source.[WPC suma wp³at], source.[WPC liczba wp³at] into #WPC_MergeLog;

		insert into dm_data_bps.dbo.rezultat
		(re_ak_id, re_ret_id, re_data_planowana, re_us_id_planujacy, re_data_wykonania, re_us_id_wykonujacy, re_konczy)
		select ak_id,case when wpc_rezultat='by³y wp³aty' then  519 when wpc_rezultat='brak wp³at' then 518 when wpc_rezultat='brak informacji' then 516 end,getdate(),5,getdate(),5,1 from #WPC_MergeLog

		insert into atrybut_akcji
		(atak_atakt_id,atak_ak_id,atak_wartosc)
		select 100,ak_id, format(wpc_suma_wplat,'G','pl-pl') from #WPC_MergeLog where wpc_suma_wplat is not null

		insert into atrybut_akcji
		(atak_atakt_id,atak_ak_id,atak_wartosc)
		select 101,ak_id, wpc_liczba_wplat from #WPC_MergeLog where wpc_liczba_wplat is not null

		insert into atrybut_akcji
		(atak_atakt_id,atak_ak_id,atak_wartosc)
		select 102,ak_id, wpc_data_ostatniej_wplaty from #WPC_MergeLog where wpc_data_ostatniej_wplaty is not null

		insert into atrybut_akcji
		(atak_atakt_id,atak_ak_id,atak_wartosc)
		select 103,ak_id, format(wpc_kwota_ostatniej_wplaty,'G','pl-pl') from #WPC_MergeLog where wpc_kwota_ostatniej_wplaty is not null
end





select * from #ImportExcelGlowny



