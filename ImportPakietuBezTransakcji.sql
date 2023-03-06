--Przed uruchomieniem tegu skryptu wykonujemy import spraw z aplikacji. Import wywala siê przy próbie dostêpu do pliku skopiowanego przez aplikacjê,
--nazwa tego pliku jest inna ni¿ podawaliœmy przy imporcie. Wygl¹da np. tak: "79129980-2ded-4af2-a11c-3eb1d31e092e.xls". Nazwê tê nale¿y wpisaæ 
--ze œcie¿k¹ do poni¿szego skryptu. Wpisujemy tak¿e UKO_ID. Kontrahent i sprawa handlowa musz¹ byæ za³o¿one przed importem z aplikacji. Dla
--przypomnienia - import uruchamiamy na konkretnej sprawie handlowej.
--W skrypcie mo¿na by jeszcze zmieniæ co nieco. Np. 
--- nie zak³adaæ nowych spraw dla porêczycieli i wspó³d³u¿ników tylko dopisaæ ich do zak³adki 
--  D³u¿nicy na sprawie d³u¿nika g³ównego. - nieaktualne, nie robiæ tego
--- Pomin¹æ dopisanie akcji alert - nowa sprawa - windykacja nie chce jej.
--- Uwaga: wygl¹da na to, ¿e koszty zakupione musz¹ byæ w Excelu w kolumnie "op³aty dodatkowe"
-----------------------------------------------------------------------------------------------------------------------------------------------------



use dm_logic_bps
declare

	@p_import_filepath varchar(max),
	@p_additionalParamasXML XML,
	@p_out_isError int 



	set @p_additionalParamasXML=N'<Parameters><uko_id>303</uko_id></Parameters>' ---- UKO_ID
	set @p_import_filepath=N'D:\BS\ImportNowegoPakietu_5022.xls'        ---- SCIE¯KA DO PLIKU



SET ANSI_NULLS ON
SET ANSI_WARNINGS ON


declare @ErrorMessage NVARCHAR(4000)
declare @ErrorSeverity INT
declare @ErrorState INT 


BEGIN

--declare @ErrorMessage NVARCHAR(4000)
--declare @ErrorSeverity INT
--declare @ErrorState INT 

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON


/*
DECLARE
@p_import_filepath varchar(max),
@p_additionalParamasXML XML,
@p_out_isError int
*/
--SET @p_additionalParamasXML=Null
--declare @p_import_filepath varchar(max),
--@p_additionalParamasXML XML,
--@p_out_isError  int

declare 
 @v_prefix varchar(50)
,@v_uko_id int
,@data_eksportu datetime -- data kiedy plik zostal wyeksportwany w banku
,@v_xml_out xml
,@v_xml_in xml
,@v_errors_in xml
,@v_hDoc int
,@v_debug int
,@v_now datetime
,@Now DateTime
,@error int
,@STATUS1 varchar(20)
,@v_ignore int
,@v_data_obslugi_od date
,@execCMD varchar(max)
,@p_errors_out XML

set @error = 0
set @v_now=GETDATE()

--ustawienia konfiguracyjne
set @v_uko_id=SUBSTRING ( cast(@p_additionalParamasXML as varchar(4000)) ,  CHARINDEX('<Parameters><uko_id>',cast(@p_additionalParamasXML as varchar(4000)))+20 ,charindex('</uko_id></Parameters>',cast(@p_additionalParamasXML as varchar(4000)))-21)
set @v_debug=0
set @v_data_obslugi_od = null

-----------------------
--wprowadzanie danych
-----------------------

---------------------------TABLICE LOKALNE	
IF object_id('tempdb..#ImportExcelGlowny') IS NOT NULL
	begin
		drop table #ImportExcelGlowny
		print 'usunieto #ImportExcelGlowny'
	end
IF object_id('tempdb..#ImportExcelRole') IS NOT NULL
	begin
		drop table #ImportExcelRole
		print 'usunieto #ImportExcelRole'
	end
IF object_id('tempdb..#ImportExcelRole2') IS NOT NULL
begin
	drop table #ImportExcelRole2
	print 'usunieto #ImportExcelRole2'
end

Create table #ImportExcelGlowny
(
ex_nazwisko	nvarchar	(510)	collate polish_ci_as ,
ex_imie	nvarchar	(510)	collate polish_ci_as,
ex_firma	nvarchar	(510)	collate polish_ci_as,
ex_nip	nvarchar	(510)	collate polish_ci_as,
ex_pesel	nvarchar	(510)	collate polish_ci_as,
ex_regon	nvarchar	(510)	collate polish_ci_as,
ex_uwagi_dl	nvarchar	(510)	collate polish_ci_as,
ex_dl_numer	int		,
ex_telefony	nvarchar	(510)	collate polish_ci_as,
ex_mail	nvarchar	(510)	collate polish_ci_as,
ex_ulica_zm	nvarchar	(510)	collate polish_ci_as,
ex_nr_domu_zm	nvarchar	(510)	collate polish_ci_as,
ex_nr_lokalu_zm	nvarchar	(510)	collate polish_ci_as,
ex_kod_zm	nvarchar	(510)	collate polish_ci_as,
ex_miejscowosc_zm	nvarchar	(510)	collate polish_ci_as,
ex_ulica_ko	nvarchar	(510)	collate polish_ci_as,
ex_nr_domu_ko	nvarchar	(510)	collate polish_ci_as,
ex_nr_lokalu_ko	nvarchar	(510)	collate polish_ci_as,
ex_kod_ko	nvarchar	(510)	collate polish_ci_as,
ex_miejscowosc_ko	nvarchar	(510)	collate polish_ci_as,
ex_wi_numer	nvarchar	(510)	collate polish_ci_as,
ex_wi_data_umowy	datetime		,
ex_do_nr	nvarchar	(510)	collate polish_ci_as,
ex_do_tytul	nvarchar	(510)	collate polish_ci_as,
ex_data_wystawienia	datetime		,
ex_data_wymagalnosci	datetime		,
ex_data_naliczania_odsetek	datetime		,
ex_kwota_wystawiona	decimal(18,2)	,
[LACZNA KWOTA]	decimal(18,2)	,
ex_kwota_wymagana	decimal(18,2)	,
ex_odsetki_umowne	decimal(18,2)	,
ex_odsetki_ustawowe	decimal(18,2)	,
ex_odsetki_karne	decimal(18,2)	,
ex_oplata_dodatkowa	decimal(18,2)	,
ex_do_uwagi	nvarchar	(510)	collate polish_ci_as,
ex_rb_nr	nvarchar	(510)	collate polish_ci_as,
[NR sprawy z systemu importowego]	nvarchar	(510)	collate polish_ci_as,
[Data Przedawnienia]	nvarchar	(510)	collate polish_ci_as,
[Atrybut 2]	nvarchar	(510)	collate polish_ci_as,
[Atrybut 3]	nvarchar	(510)	collate polish_ci_as,
Windykator	nvarchar	(510)	collate polish_ci_as,
[Nr d³u¿nika z systemu kontrahenta] nvarchar	(510)	collate polish_ci_as,
[Numer Sprawy Symfonia] nvarchar	(510) collate polish_ci_as,
[Cena zakupu]	decimal(18,2),
[Planowany odzysk]	decimal(18,2),
[Data wypowiedzenia umowy kredytowej] datetime
)

Create table #ImportExcelRole
(
ex_nazwisko	nvarchar	(510)	collate polish_ci_as,
ex_imie	nvarchar	(510)	collate polish_ci_as,
ex_firma	nvarchar	(510)	collate polish_ci_as,
ex_nip	nvarchar	(510)	collate polish_ci_as,
ex_pesel	nvarchar	(510)	collate polish_ci_as,
ex_regon	nvarchar	(510)	collate polish_ci_as,
ex_uwagi_dl	nvarchar	(510)	collate polish_ci_as,
ex_dl_numer	int		,
ex_telefony	nvarchar	(510)	collate polish_ci_as,
ex_mail	nvarchar	(510)	collate polish_ci_as,
ex_ulica_zm	nvarchar	(510)	collate polish_ci_as,
ex_nr_domu_zm	nvarchar	(510)	collate polish_ci_as,
ex_nr_lokalu_zm	nvarchar	(510)	collate polish_ci_as,
ex_kod_zm	nvarchar	(510)	collate polish_ci_as,
ex_miejscowosc_zm	nvarchar	(510)	collate polish_ci_as,
ex_ulica_ko	nvarchar	(510)	collate polish_ci_as,
ex_nr_domu_ko	nvarchar	(510)	collate polish_ci_as,
ex_nr_lokalu_ko	nvarchar	(510)	collate polish_ci_as,
ex_kod_ko	nvarchar	(510)	collate polish_ci_as,
ex_miejscowosc_ko	nvarchar	(510)	collate polish_ci_as,
ex_rb_nr	nvarchar	(510)	collate polish_ci_as,
ROLA	nvarchar	(510)	collate polish_ci_as,
[NR sprawy z systemu importowego]	nvarchar	(510)	collate polish_ci_as,
[Data Przedawnienia]	nvarchar	(510)	collate polish_ci_as,
[Atrybut 2]	nvarchar	(510)	collate polish_ci_as,
[Atrybut 3]	nvarchar	(510)	collate polish_ci_as,
[Nr d³u¿nika z systemu kontrahenta] nvarchar	(510)	collate polish_ci_as,
[Numer Sprawy Symfonia] nvarchar	(510) collate polish_ci_as
)


---------------------------------------------------------------------------------------------------------------------------------
set @execCMD ='
Insert into #ImportExcelGlowny
SELECT Nazwisko as [ex_nazwisko], Imiê as [ex_imie], [Nazwa firmy] as [ex_firma], NIP as [ex_nip], PESEL as [ex_pesel], Regon as [ex_regon], Uwagi as [ex_uwagi_dl], null as [ex_dl_numer], [telefon (telefony po przecinku)] as [ex_telefony], [e-mail] as [ex_mail], 
[ulica zameld] as [ex_ulica_zm],[nr domu zameld] as [ex_nr_domu_zm], [nr mieszkania zameld] as [ex_nr_lokalu_zm], [kod pocztowy zameld] as [ex_kod_zm], [miasto zameld] as [ex_miejscowosc_zm],
[ulica koresp] as [ex_ulica_ko], [nr domu koresp] as [ex_nr_domu_ko], [nr mieszkania koresp] as [ex_nr_lokalu_ko],
[kod pocztowy koresp] as [ex_kod_ko], [miasto koresp] as [ex_miejscowosc_ko], [numer umowy (wierzytelnosc)] as [ex_wi_numer], [data umowy (wierzytelnosc)] as [ex_wi_data_umowy],
[nr dokumentu] as [ex_do_nr], tytu³em as [ex_do_tytul], [data wystawienia] as [ex_data_wystawienia],
[data wymagalnoœci] as [ex_data_wymagalnosci], [data naliczania odsetek] as [ex_data_naliczania_odsetek], cast([kwota wystawiona] as money) as [ex_kwota_wystawiona], 
cast([£¥CZNA KWOTA] as money) as [LACZNA KWOTA], cast([kwota wymagana] as money) as [ex_kwota_wymagana], cast([odsetki umowne] as money) as [ex_odsetki_umowne], cast([odsetki ustawowe] as money) as [ex_odsetki_ustawowe], cast([odsetki karne] as money) as [ex_odsetki_karne],
cast([op³aty dodatkowe] as money) as [ex_oplata_dodatkowa], [dokument uwagi] as [ex_do_uwagi], [numer rachunku bankowego] as [ex_rb_nr],
[NR sprawy z systemu importowego] as [NR sprawy z systemu importowego],[Data Przedawnienia] as [Data Przedawnienia],[Atrybut 2] as [Atrybut 2],[Atrybut 3] as [Atrybut 3],
[Windykator] as [Windykator], [Nr d³u¿nika z systemu kontrahenta] as [Nr d³u¿nika z systemu kontrahenta], [Numer Sprawy Symfonia] as [Numer Sprawy Symfonia], [Cena zakupu] as [Cena zakupu], [Planowany odzysk] as [Planowany odzysk],
[Data wypowiedzenia umowy kredytowej] as [Data wypowiedzenia umowy kredytowej]

FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 8.0; Database='+@p_import_filepath+''', ''SELECT * FROM [Import$]'');'

exec(@execCMD);
---------------------------------------------------------------------------------------------------------------------------------
                                                                 /*WCZYTANIE ARKUSZY*/
---------------------------------------------------------------------------------------------------------------------------------
set @execCMD ='
Insert into #ImportExcelRole
SELECT Nazwisko as [ex_nazwisko], Imiê as [ex_imie], [Nazwa firmy] as [ex_firma], NIP as [ex_nip], PESEL as [ex_pesel], Regon as [ex_regon], Uwagi as [ex_uwagi_dl], null as [ex_dl_numer], [telefon (telefony po przecinku)] as [ex_telefony], [e-mail] as [ex_mail], 
[ulica zameld] as [ex_ulica_zm],[nr domu zameld] as [ex_nr_domu_zm], [nr mieszkania zameld] as [ex_nr_lokalu_zm], [kod pocztowy zameld] as [ex_kod_zm], [miasto zameld] as [ex_miejscowosc_zm],
[ulica koresp] as [ex_ulica_ko], [nr domu koresp] as [ex_nr_domu_ko], [nr mieszkania koresp] as [ex_nr_lokalu_ko],
[kod pocztowy koresp] as [ex_kod_ko], [miasto koresp] as [ex_miejscowosc_ko], [numer rachunku bankowego] as [ex_rb_nr], [ROLA],
[NR sprawy z systemu importowego] as [NR sprawy z systemu importowego],
[Data Przedawnienia] as [Data Przedawnienia],[Atrybut 2] as [Atrybut 2],[Atrybut 3] as [Atrybut 3], [Nr d³u¿nika z systemu kontrahenta] as [Nr d³u¿nika z systemu kontrahenta], [Numer Sprawy Symfonia] as [Numer Sprawy Symfonia]

FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''Excel 8.0; Database='+@p_import_filepath+''', ''SELECT * FROM [Role$]'');'
exec (@execCMD);
---------------------------------------------------------------------------------------------------------------------------------
delete from #ImportExcelRole where ex_rb_nr is null


set @Now = getdate() 
set @v_uko_id=SUBSTRING ( cast(@p_additionalParamasXML as varchar(4000)) collate Polish_CI_AS ,  CHARINDEX('<Parameters><uko_id>',cast(@p_additionalParamasXML as varchar(4000)) collate Polish_CI_AS)+20 ,charindex('</uko_id></Parameters>',cast(@p_additionalParamasXML as varchar(4000)) collate Polish_CI_AS)-21) collate Polish_CI_AS
set @v_debug=0
set @v_data_obslugi_od = NULL

if  (object_id(N'tempdb..#importExcel2') is not null)
drop table #importExcel2

select 
	row_number() OVER(PARTITION BY ex_rb_nr ORDER BY ex_nazwisko collate Polish_CI_AS, ex_imie collate Polish_CI_AS, ex_firma collate Polish_CI_AS, ex_nip collate Polish_CI_AS, ex_pesel collate Polish_CI_AS,ex_regon collate Polish_CI_AS,ex_dl_numer) As Solidarny
	,cast(row_number() OVER(ORDER BY ex_nazwisko collate Polish_CI_AS, ex_imie collate Polish_CI_AS, ex_firma collate Polish_CI_AS, ex_nip collate Polish_CI_AS, ex_pesel collate Polish_CI_AS,ex_regon collate Polish_CI_AS,ex_dl_numer) as VarChar(max)) collate Polish_CI_AS  as ex_nr_wiersza,
	[ex_nazwisko] collate Polish_CI_AS as [ex_nazwisko],[ex_imie] collate Polish_CI_AS as [ex_imie],[ex_firma] collate Polish_CI_AS as [ex_firma],
	[ex_nip] collate Polish_CI_AS as [ex_nip],[ex_pesel] collate Polish_CI_AS as [ex_pesel],[ex_regon] collate Polish_CI_AS as ex_regon,
	[ex_uwagi_dl] collate Polish_CI_AS as [ex_uwagi_dl],null as [ex_dl_numer],[ex_telefony],[ex_mail],
	[ex_ulica_zm] collate Polish_CI_AS as [ex_ulica_zm],[ex_nr_domu_zm] collate Polish_CI_AS as [ex_nr_domu_zm],[ex_nr_lokalu_zm] collate Polish_CI_AS as [ex_nr_lokalu_zm],
	[ex_kod_zm] collate Polish_CI_AS as [ex_kod_zm],[ex_miejscowosc_zm] collate Polish_CI_AS as [ex_miejscowosc_zm],
	[ex_ulica_ko] collate Polish_CI_AS as [ex_ulica_ko],[ex_nr_domu_ko] collate Polish_CI_AS as [ex_nr_domu_ko],[ex_nr_lokalu_ko] collate Polish_CI_AS as [ex_nr_lokalu_ko],[ex_kod_ko] collate Polish_CI_AS as [ex_kod_ko],[ex_miejscowosc_ko] collate Polish_CI_AS as [ex_miejscowosc_ko],
	case when ([ex_wi_numer] collate Polish_CI_AS like '') or ([ex_wi_numer] collate Polish_CI_AS is null) then 'Import Excel' else [ex_wi_numer] collate Polish_CI_AS end  collate Polish_CI_AS as [ex_wi_numer] ,
	nullif(CONVERT(date, replace([ex_wi_data_umowy] ,'-','/'), 103),'') as [ex_wi_data_umowy],
	isnull([ex_do_nr],'') collate Polish_CI_AS as [ex_do_nr], isnull([ex_do_tytul],'') collate Polish_CI_AS as [ex_do_tytul],
	nullif(CONVERT(date, replace([ex_data_wystawienia],'-','/'), 103),'') as ex_do_data_wystawienia,
	nullif(CONVERT(date, replace([ex_data_wymagalnosci],'-','/'), 103),'') as ex_ksd_data_wymagalnosci,
	nullif(convert(datetime,[ex_data_naliczania_odsetek]),'') as [ex_data_naliczania_odsetek],
	case when ([ex_kwota_wystawiona] is null) then 0 else [ex_kwota_wystawiona] end as ex_do_saldo_poczatkowe,
	case when ([ex_kwota_wymagana] is null) then 0 else [ex_kwota_wymagana] end  as ex_kapital,
	case when ([ex_odsetki_umowne] is null)  then 0 else [ex_odsetki_umowne] end as ex_odsetki_umowne,
	case when ([ex_odsetki_ustawowe] is null) then 0 else [ex_odsetki_ustawowe] end as ex_odsetki_ustawowe,
	case when ([ex_odsetki_karne] is null) then 0 else [ex_odsetki_karne] end as ex_odsetki_karne,
	case when ([ex_oplata_dodatkowa] is null) then 0 else [ex_oplata_dodatkowa] end as ex_koszty,
	[ex_do_uwagi],[ex_rb_nr] collate Polish_CI_AS as [ex_rb_nr],
	[NR sprawy z systemu importowego]  collate Polish_CI_AS as [NR sprawy z systemu importowego],
	[Data Przedawnienia]  collate Polish_CI_AS as [Data Przedawnienia],
	[Atrybut 2]  collate Polish_CI_AS as [Atrybut 2],
	[Atrybut 3]  collate Polish_CI_AS as [Atrybut 3],
	[Windykator] collate Polish_CI_AS as [Windykator],
	[Nr d³u¿nika z systemu kontrahenta] collate Polish_CI_AS as [Nr d³u¿nika z systemu kontrahenta],
	[Numer Sprawy Symfonia] collate Polish_CI_AS as [Numer Sprawy Symfonia],
	case when ([Cena zakupu] is null) then 0 else [Cena zakupu] end as [Cena zakupu],
	case when ([Planowany odzysk] is null) then 0 else [Planowany odzysk] end as [Planowany odzysk],
	nullif(CONVERT(date, replace([Data wypowiedzenia umowy kredytowej],'-','/'), 103),'') as [Data wypowiedzenia umowy kredytowej]
	
into #importExcel2
from #ImportExcelGlowny
where  
(ex_nazwisko collate Polish_CI_AS	is null	or 
ex_imie collate Polish_CI_AS	is null	or 
ex_firma collate Polish_CI_AS is null	or 
ex_nip collate Polish_CI_AS	is null	or 
ex_pesel collate Polish_CI_AS is null	or 
ex_regon collate Polish_CI_AS	is null	or 
ex_uwagi_dl collate Polish_CI_AS	is null	or 
ex_dl_numer is null	or 
ex_telefony collate Polish_CI_AS	is null	or
 ex_mail collate Polish_CI_AS	is null	or 
 ex_ulica_zm collate Polish_CI_AS	is null	or 
 ex_nr_domu_zm collate Polish_CI_AS	is null	or 
ex_nr_lokalu_zm collate Polish_CI_AS	is null	or 
ex_kod_zm collate Polish_CI_AS	is null	or 
ex_miejscowosc_zm collate Polish_CI_AS is null	or 
ex_ulica_ko collate Polish_CI_AS	is null	or 
ex_nr_domu_ko collate Polish_CI_AS	is null	or 
ex_nr_lokalu_ko collate Polish_CI_AS	is null	or 
ex_kod_ko collate Polish_CI_AS	is null	or 
ex_miejscowosc_ko collate Polish_CI_AS	is null	or 
ex_wi_numer collate Polish_CI_AS	is null	or 
ex_wi_data_umowy is null	or 
ex_do_nr collate Polish_CI_AS	is null	or 
ex_do_tytul collate Polish_CI_AS	is null	or 
ex_data_wystawienia 	is null	or 
ex_data_wymagalnosci 	is null	or 
ex_data_naliczania_odsetek 	is null	or 
ex_kwota_wystawiona 	is null	or 
[LACZNA KWOTA] 	is null	or 
ex_kwota_wymagana 	is null	or 
ex_odsetki_umowne 	is null	or 
ex_odsetki_ustawowe 	is null	or 
ex_odsetki_karne  is null or 
ex_oplata_dodatkowa 	is null	or 
ex_do_uwagi collate Polish_CI_AS	is null	or 
ex_rb_nr collate Polish_CI_AS	is null	or 
[NR sprawy z systemu importowego] collate Polish_CI_AS	is null	or 
[Data Przedawnienia] collate Polish_CI_AS	is null	or 
[Atrybut 2] collate Polish_CI_AS	is null	or 
[Atrybut 3] collate Polish_CI_AS	is null	or 
Windykator collate Polish_CI_AS	is null	or 
[Numer Sprawy Symfonia] collate Polish_CI_AS is null or 
[Nr d³u¿nika z systemu kontrahenta] collate Polish_CI_AS is not null or 
[Cena zakupu] is not null or
[Planowany odzysk] is not null or
[Data wypowiedzenia umowy kredytowej] is not null
)

-----------------------
--wprowadzanie danych
-----------------------
set @v_xml_out='<root>'+(
select
		import_pk_key collate Polish_CI_AS import_pk_key
		,dl_dx_id
		,dl_dt_id
		,dl_pl_id
		,dl_imie
		,dl_nazwisko
		,dl_nazwisko_rodowe
		,dl_numer_dowodu
		,dl_numer_paszportu
		,dl_pesel
		,dl_firma
		,dl_firma_skrot
		,dl_krs
		,dl_nip 
		,dl_regon
		,dl_bank
		,dl_konto_bankowe_nr
		,ROW_NUMBER() OVER(ORDER BY dl_pesel) dl_numer
		,dl_import_info
		from (
		select distinct ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate Polish_CI_AS import_pk_key 
		,1 dl_dx_id
		,1 dl_dt_id 
		,4 dl_pl_id
		,LTRIM(RTRIM( isnull([ex_imie],'')))collate Polish_CI_AS as dl_imie
		,ltrim(rtrim(isnull([ex_nazwisko], '')))collate Polish_CI_AS dl_nazwisko
		,null dl_nazwisko_rodowe
		,null dl_numer_dowodu
		,null dl_numer_paszportu
		,ex_pesel collate Polish_CI_AS dl_pesel
		,ex_firma collate Polish_CI_AS dl_firma
		,null dl_firma_skrot
		,Null dl_krs 
		,ex_nip collate Polish_CI_AS dl_nip 
		,ex_regon collate Polish_CI_AS dl_regon
		,null dl_bank
		,ex_rb_nr collate Polish_CI_AS dl_konto_bankowe_nr
		,isnull(ex_dl_numer,'')  dl_numer
		,isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_firma,'')+isnull(ex_nip,'')+isnull(ex_pesel,'')+isnull(ex_regon,'') collate Polish_CI_AS dl_import_info
		from #importExcel2
		--	left join dluznik on
		--		isnull(ex_nazwisko,'') = isnull(dl_nazwisko,'') collate Polish_CI_AS and
		--		isnull(ex_imie,'') = isnull(dl_imie,'') collate Polish_CI_AS and
		--		isnull(ex_firma,'') = isnull(dl_firma,'') collate Polish_CI_AS and
		--		isnull(ex_nip,'') = isnull(dl_nip,'') collate Polish_CI_AS and
		--		isnull(ex_pesel,'') collate SQL_Latin1_General_CP1_CI_AS = isnull(dl_pesel,'') and
		--		isnull(ex_regon,'') = isnull(dl_regon,'') collate Polish_CI_AS		
		where isnull(ex_firma, '') collate Polish_CI_AS = ''
		UNION ALL
		select distinct ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate Polish_CI_AS import_pk_key
		,1 dl_dx_id
		,case when LTRIM(RTRIM( isnull([ex_imie],''))) collate Polish_CI_AS <>'' then 2 else 3 end dl_dt_id 
		,4 dl_pl_id
		,LTRIM(RTRIM( isnull([ex_imie],''))) collate Polish_CI_AS as dl_imie
		,ltrim(rtrim(isnull([ex_nazwisko], ''))) collate Polish_CI_AS dl_nazwisko
		,null dl_nazwisko_rodowe
		,null dl_numer_dowodu
		,null dl_numer_paszportu
		,ex_pesel collate Polish_CI_AS dl_pesel
		,ex_firma collate Polish_CI_AS dl_firma
		,null dl_firma_skrot
		,Null dl_krs 
		,ex_nip collate Polish_CI_AS dl_nip 
		,ex_regon collate Polish_CI_AS dl_regon
		,null dl_bank
		,ex_rb_nr collate Polish_CI_AS dl_konto_bankowe_nr
		,isnull(ex_dl_numer,'') dl_numer
		,isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_firma,'')+isnull(ex_nip,'')+isnull(ex_pesel,'')+isnull(ex_regon,'') collate Polish_CI_AS dl_import_info
		from #importExcel2
			--left join dluznik on
			--	isnull(ex_nazwisko,'') = isnull(dl_nazwisko,'') collate Polish_CI_AS and
			--	isnull(ex_imie,'') = isnull(dl_imie,'') collate Polish_CI_AS and
			--	isnull(ex_firma,'') = isnull(dl_firma,'') collate Polish_CI_AS and
			--	isnull(ex_nip,'') = isnull(dl_nip,'') collate Polish_CI_AS and
			--	isnull(ex_pesel,'') collate SQL_Latin1_General_CP1_CI_AS = isnull(dl_pesel,'') and
			--	isnull(ex_regon,'') = isnull(dl_regon,'') collate Polish_CI_AS		
		where isnull(ex_firma, '') collate Polish_CI_AS <> ''		
		) dluznik
for XML AUTO)+'</root>'
----Aktualizacja tabeli dluznicy

set @execCMD='<Parameters><Kontrakt>'+cast(@v_uko_id as varchar(max))+'</Kontrakt></Parameters>'
exec [p_BPS_import_tool_dluznik] @v_xml_out, @execCMD, @v_xml_in out, @v_errors_in out


-- Konwersja XML'a otrzymanego z procedury [p_BPS_import_tool_dluznik] - Lista zaimportowanych dluznikow.
--select @v_xml_in
exec sp_xml_preparedocument @v_hDoc OUTPUT, @v_xml_in

if OBJECT_ID('tempdb..#imported_dluznik') is not null drop table #imported_dluznik
create table #imported_dluznik 
	(imp_id int
	,import_pk_key varchar(max) collate Polish_CI_AS 
	)

insert into #imported_dluznik
	select 
	imp_id 
	,import_pk_key 
	FROM OPENXML(@v_hDoc, '/root/imported',1)
	WITH 
	( imp_id int
	,import_pk_key varchar(max)
	)





---- ATRYBUTY DLUZNIKA---

	-- Tabela #atrybut_wartosc_inserted w uzywam merge zeby wyciagnac id atrybutu.
		IF object_id('tempdb..#atrybut_wartosc_insertedDL') IS NOT NULL
			begin 
				drop table #atrybut_wartosc_insertedDL
				print 'usunieto tabele #atrybut_wartosc_insertedDL'
			end
	
		create table #atrybut_wartosc_insertedDL
			(
				[atw_id] [int] NOT NULL,
				[atw_att_id] [int] NOT NULL,
				[atw_wartosc] [varchar](max) NULL,
				import_pk_key [varchar](max)  collate Polish_CI_AS  NULL
			)

		IF object_id('tempdb..#atrybut_wartosc_insertedDL') IS NOT NULL
			begin 
				print 'utworzono tabele #atrybut_wartosc_insertedDL'
			end

Begin
		MERGE [dbo].[atrybut_wartosc]  AS target
			USING 
				(
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '')  collate polish_ci_ai as import_pk_key,
						7 as [atw_att_id]
					   ,isnull([ex_uwagi_dl],'') as [atw_wartosc]
					from  #importExcel2
					
					Union all
					
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '')  collate polish_ci_ai as import_pk_key,
						9 as [atw_att_id]
					   ,isnull([Nr d³u¿nika z systemu kontrahenta],'') as [atw_wartosc]
					from  #importExcel2
					
		  		   
			 )
			AS source (import_pk_key,[atw_att_id],[atw_wartosc])
			ON (1=0)
			WHEN NOT MATCHED THEN 
			INSERT 
			(
					[atw_att_id]
				   ,[atw_wartosc]
			) 
			VALUES
			(   
					[atw_att_id]
				   ,[atw_wartosc]
			)
		  Output   
				    inserted.[atw_id]
				   ,inserted.[atw_att_id]
				   ,inserted.[atw_wartosc]
				   ,source.import_pk_key 
		  INTO  #atrybut_wartosc_insertedDL;
										
		print 'Liczba wierszy zaimportowana do tabeli atrybut_wartosc: ' +cast(@@Rowcount as varchar(max))

		insert into dbo.atrybut_dluznik (
										   [atdl_atw_id]
										  ,[atdl_dl_id]
										 )
		
		select 
			[atw_id] as [atdl_atw_id]
			,imported_dluznik.imp_id as [atdl_dl_id]
			from #atrybut_wartosc_insertedDL
			join #imported_dluznik imported_dluznik on imported_dluznik.import_pk_key= #atrybut_wartosc_insertedDL.import_pk_key   collate polish_ci_ai

end






---------------------------
--rachunki bankowe
---------------------------
begin

if OBJECT_ID('tempdb..#rachunek_bankowy_uko') is not null drop table #rachunek_bankowy_uko
create table #rachunek_bankowy_uko 
	(tmp_rb_id int)
	
	insert into #rachunek_bankowy_uko
	select sp_rb_id from v_sprawa_uko join sprawa on v_sprawa_uko.sp_id=sprawa.sp_id where uko_id=@v_uko_id
	
	--usun z powyzszego rb, ktore maja powtarzajace sie numery - inaczej merge nie przejdzie, a poza tym nie wiadomo z ktorym polaczyc sp
	delete #rachunek_bankowy_uko
	where tmp_rb_id in (
		select rb_id
		from rachunek_bankowy
		where rb_nr in (
			select rb_nr
			from rachunek_bankowy
			group by rb_nr
			having COUNT(1)>1
		)
	)
if OBJECT_ID('tempdb..#imported_rachunek') is not null drop table #imported_rachunek
	create table #imported_rachunek 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS 
	);	

	select '1'

MERGE rachunek_bankowy AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+isnull(ex_wi_numer ,'')import_pk_key
		,ltrim(rtrim(ex_rb_nr)) rb_nr
		,'bank' rb_bank
	from #importExcel2
	where isnull(ex_wi_numer,'')<>''
	) 
	 AS source 
		(import_pk_key, rb_nr, rb_bank)
	ON (1=0
		--source.rb_nr=target.rb_nr  collate polish_ci_ai
		--AND target.rb_id in (select tmp_rb_id from #rachunek_bankowy_uko)
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(rb_nr, rb_bank) 
		VALUES 
		(rb_nr, rb_bank)
	OUTPUT source.import_pk_key, inserted.rb_id
	--,$action
	INTO #imported_rachunek (import_pk_key, imp_id);

--zabezpieczenie przed dublami;
	delete #imported_rachunek where import_pk_key in (select import_pk_key from #imported_rachunek group by import_pk_key having COUNT(1)>1);
end

select '1'
---------------------
--sprawa
---------------------


declare @max_sp_numer int
select @max_sp_numer=MAX(cast(sp_numer as int))
from sprawa 
where isnumeric(sp_numer)=1
set @max_sp_numer=isnull(@max_sp_numer,0);

 if OBJECT_ID('tempdb..#sprawa_uko') is not null drop table #sprawa_uko 
 create table #sprawa_uko  
 (tmp_sp_id int)  
   
 insert into #sprawa_uko  
 select sp_id from v_sprawa_uko where uko_id=@v_uko_id
 
  if OBJECT_ID('tempdb..#imported_sprawa') is not null drop table #imported_sprawa 
 create table #imported_sprawa   
 (  
 imp_id int,  
 import_pk_key varchar(max)   collate Polish_CI_AS 
 ); 
 
begin



MERGE sprawa AS target  
 USING (  
  select import_pk_key
		, @max_sp_numer+ROW_NUMBER() over (order  by import_pk_key) sp_numer
		, sp_import_info
		, sp_rb_id
		, null sp_numer_migracja
		, data_obslugi_od sp_data_obslugi_od
		, null as sp_data_obslugi_do
		, null as sp_komentarz
from (
	select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai import_pk_key
	, imp_id sp_rb_id
	, @v_data_obslugi_od as data_obslugi_od 
	, 'Import z Excel - ' + Convert(VarChar(20),GETDATE(),110) sp_import_info
	from #importExcel2
	inner join #imported_rachunek on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer =import_pk_key collate polish_ci_ai
	where ISNULL(ex_wi_numer,'')<>'' and solidarny=1
	)dane_wew
 )   
  AS source   
  (import_pk_key, sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )  
 ON  (  
  --source.sp_import_info collate polish_ci_ai=target.sp_import_info collate polish_ci_ai  
  --AND target.sp_id in (select tmp_sp_id from #sprawa_uko)  
  1=0
  
  )  
 WHEN NOT MATCHED THEN   
  INSERT   
  (sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )   
  VALUES   
  (sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )  
 OUTPUT source.import_pk_key, inserted.sp_id  
 INTO #imported_sprawa (import_pk_key, imp_id);  

end

--drop table #sprawy
--wychwycenie spraw
 if OBJECT_ID('tempdb..#sprawyWindykatorzy') is not null drop table #sprawyWindykatorzy 
select sp_id,sp_numer,us_id,Windykator
into #sprawyWindykatorzy
from sprawa
join #imported_sprawa imported_sprawa on imported_sprawa.imp_id=sprawa.sp_id
join (select distinct 
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer as import_pk_key, 
						Windykator 
						from #importExcel2
				)Windyk on imported_sprawa.import_pk_key=Windyk.import_pk_key collate Polish_CI_AS
				
join ge_user on Windykator=us_login collate Polish_CI_AS


---- PREWINDYKACJA

		IF object_id('tempdb..#akcja_inserted_PREW') IS NOT NULL
			begin 
				drop table #akcja_inserted_PREW
				print 'usuniêto tabelê #akcja_inserted_PREW'
			end   

		CREATE TABLE #akcja_inserted_PREW
				(
					[ak_id] [int],
					[ak_akt_id] [int],
					[ak_sp_id] [int],
					[ak_kolejnosc] [int],
					[ak_interwal] [int],
					[ak_zakonczono] [datetime],
					[ak_sc_id] [int],
					[ak_pr_id] [int],
					[ak_publiczna] [bit]
				)
;
		merge akcja as target 
		USING 
			(
				select 
					'10000' as [ak_akt_id]	-- Prewindykacja
					,imp_id as [ak_sp_id]
					,'0' as [ak_kolejnosc]
					,'0' as [ak_interwal]
					,getdate() as [ak_zakonczono]
					,NULL as [ak_sc_id]
					,NULL as [ak_pr_id]
					,'1' as [ak_publiczna]
				from #imported_sprawa

			) 
		as source 
		On (0=1)
		when not matched then
		Insert (
				   [ak_akt_id]
				  ,[ak_sp_id]
				  ,[ak_kolejnosc]
				  ,[ak_interwal]
				  ,[ak_zakonczono]
				  ,[ak_sc_id]
				  ,[ak_pr_id]
				  ,[ak_publiczna]
			  )
		values (
				   [ak_akt_id]
				  ,[ak_sp_id]
				  ,[ak_kolejnosc]
				  ,[ak_interwal]
				  ,[ak_zakonczono]
				  ,[ak_sc_id]
				  ,[ak_pr_id]
				  ,[ak_publiczna]
			  )
		OUTPUT	   inserted.[ak_id]
				  ,inserted.[ak_akt_id]
				  ,inserted.[ak_sp_id]
				  ,inserted.[ak_kolejnosc]
				  ,inserted.[ak_interwal]
				  ,inserted.[ak_zakonczono]
				  ,inserted.[ak_sc_id]
				  ,inserted.[ak_pr_id]
				  ,inserted.[ak_publiczna]
		INTO #akcja_inserted_PREW;	     

print 'Liczba wierszy zaimportowana do tabeli akcja: ' +cast(@@Rowcount as varchar(max))	

		insert into rezultat
					(
						 [re_ak_id]
						,[re_ret_id]
						,[re_data_planowana]
						,[re_us_id_planujacy]
						,[re_data_wykonania]
						,[re_us_id_wykonujacy]
						,[re_konczy]
						,[re_komentarz]
					)
		select
			 ak_id as [re_ak_id]
			,null as [re_ret_id]
			,getdate() as [re_data_planowana]
			,'5' as [re_us_id_planujacy]
			,getdate() as [re_data_wykonania]
			,'5' as [re_us_id_wykonujacy]
			,'0' as [re_konczy]
			,'' as [re_komentarz]
		 from  #akcja_inserted_PREW

print 'Liczba wierszy zaimportowana do tabeli rezultat : ' +cast(@@Rowcount as varchar(max))	

;









 --update 
update spr
set spr.sp_pr_id=us_id
from sprawa spr
join #sprawyWindykatorzy on #sprawyWindykatorzy.sp_id=spr.sp_id


-- operator

INSERT INTO [operator]
           ([op_sp_id]
           ,[op_us_id]
           ,[op_opt_id]
           ,[op_data_od]
           ,[op_data_do]
                 )
select 
sp_id,
us_id,
1,
getdate(),
null
from #sprawyWindykatorzy


---- ATRYBUTY SPRAWY---

	-- Tabela #atrybut_wartosc_inserted w uzywam merge zeby wyciagnac id atrybutu.
		IF object_id('tempdb..#atrybut_wartosc_inserted') IS NOT NULL
			begin 
				drop table #atrybut_wartosc_inserted
				print 'usunieto tabele #atrybut_wartosc_inserted'
			end
	
		create table #atrybut_wartosc_inserted
			(
				[atw_id] [int] NOT NULL,
				[atw_att_id] [int] NOT NULL,
				[atw_wartosc] [varchar](max) NULL,
				import_pk_key [varchar](max) collate Polish_CI_AS  NULL
			)

		IF object_id('tempdb..#atrybut_wartosc_inserted') IS NOT NULL
			begin 
				print 'utworzono tabele #atrybut_wartosc_inserted'
			end

Begin
		MERGE [dbo].[atrybut_wartosc]  AS target
			USING 
				(
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai as import_pk_key,
						6 as [atw_att_id]
					   ,isnull([NR sprawy z systemu importowego],'') as [atw_wartosc]
					from  #importExcel2
		   UNION ALL
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai as import_pk_key,
						3 as [atw_att_id]
					   ,isnull([Data Przedawnienia],'') as [atw_wartosc]
					from  #importExcel2
		   UNION ALL
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai as import_pk_key,
						4 as [atw_att_id]
					   ,isnull([Atrybut 2],'') as [atw_wartosc]
					from  #importExcel2
		   UNION ALL
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai as import_pk_key,
						5 as [atw_att_id]
					   ,isnull([Atrybut 3],'') as [atw_wartosc]
					from  #importExcel2
		  UNION ALL
					Select distinct
						ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai as import_pk_key,
						8 as [atw_att_id]
					   ,isnull([Numer Sprawy Symfonia],'') as [atw_wartosc]
					from  #importExcel2
		   
			 )
			AS source (import_pk_key,[atw_att_id],[atw_wartosc])
			ON (1=0)
			WHEN NOT MATCHED THEN 
			INSERT 
			(
					[atw_att_id]
				   ,[atw_wartosc]
			) 
			VALUES
			(   
					[atw_att_id]
				   ,[atw_wartosc]
			)
		  Output   
				    inserted.[atw_id]
				   ,inserted.[atw_att_id]
				   ,inserted.[atw_wartosc]
				   ,source.import_pk_key 
		  INTO  #atrybut_wartosc_inserted;
										
		print 'Liczba wierszy zaimportowana do tabeli atrybut_wartosc: ' +cast(@@Rowcount as varchar(max))

		insert into dbo.atrybut_sprawa (
										   [atsp_atw_id]
										  ,[atsp_sp_id]
										 )
		
		select 
			[atw_id] as [atsp_atw_id]
			,imported_sprawa.imp_id as [atsp_sp_id]
			from #atrybut_wartosc_inserted
			join #imported_sprawa imported_sprawa on imported_sprawa.import_pk_key= #atrybut_wartosc_inserted.import_pk_key   collate polish_ci_ai

end


---------------------
--sprawa_rola
---------------------
PRINT 'sprawa_rola'

begin

MERGE sprawa_rola AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai import_pk_key
		,spr_sp_id spr_sp_id
		,spr_dl_id spr_dl_id
		,1 as  spr_sprt_id
		,null spr_kwota_poreczenia_do
		,null spr_data_od
		,null spr_data_do
	from (
		select distinct
			ex_rb_nr
			,imported_sprawa.imp_id spr_sp_id
			,imported_dluznik.imp_id spr_dl_id
			,ex_wi_numer
			,ex_nr_wiersza
		from #importExcel2
		join #imported_sprawa imported_sprawa on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai =imported_sprawa.import_pk_key
		join #imported_dluznik imported_dluznik on (ltrim(rtrim(ex_rb_nr))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '')) collate polish_ci_ai = imported_dluznik.import_pk_key
)dane_wew
	) 
	 AS source 
		(import_pk_key, spr_sp_id, spr_dl_id, spr_sprt_id, spr_kwota_poreczenia_do, spr_data_od, spr_data_do )
	ON (1=0
		--source.spr_sp_id=target.spr_sp_id
		--and source.spr_dl_id=target.spr_dl_id
		--and source.spr_sprt_id=target.spr_sprt_id
		--dziedziczy weryfikacje uko z p_import_tool_sprawa
	)
	WHEN MATCHED THEN 
		UPDATE SET 
		@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(spr_sp_id, spr_dl_id, spr_sprt_id, spr_kwota_poreczenia_do, spr_data_od, spr_data_do ) 
		VALUES 
		(spr_sp_id, spr_dl_id, spr_sprt_id, isnull(spr_kwota_poreczenia_do,0), isnull(spr_data_od,'1900-01-01'), isnull(spr_data_do ,'2100-01-01'))
;

end
------------------------
--wierzytelnosc
------------------------

	IF object_id('tempdb..#imported_wierzytelnosc') IS NOT NULL drop table #imported_wierzytelnosc
PRINT 'wierzytelnosc'
	create table #imported_wierzytelnosc 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS ,
	[Cena zakupu] varchar(max),
	[Planowany odzysk] varchar(max),
	[Data wypowiedzenia umowy kredytowej] datetime,
	wi_numer varchar(max)
	);	

	IF object_id('tempdb..#wierzytelnosc_uko') IS NOT NULL drop table #wierzytelnosc_uko
	create table #wierzytelnosc_uko
	(tmp_wi_id int)
	
	insert into #wierzytelnosc_uko
	select wi_id 
	from wierzytelnosc 
	join dokument on do_wi_id=wi_id
	where do_uko_id=@v_uko_id

Begin	
	MERGE wierzytelnosc AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai import_pk_key
,cast(ex_wi_numer as varchar(max)) wi_numer
,cast([ex_wi_numer] as varchar(max)) wi_tytul
,1 wi_wt_id
,(select top 1 uko_ko_id_wierzyciel_pierwotny from umowa_kontrahent where uko_id = @v_uko_id) wi_ko_id_wierzyciel_pierwotny
,convert(datetime,ex_wi_data_umowy,120) wi_data_umowy, [Cena zakupu], [Planowany odzysk],convert(varchar(10),[Data wypowiedzenia umowy kredytowej],110)
from #importExcel2  
where solidarny=1
	) 
	 AS source 
		(import_pk_key, wi_numer, wi_tytul, wi_wt_id, wi_ko_id_wierzyciel_pierwotny, wi_data_umowy,[Cena zakupu], [Planowany odzysk], 
		 [Data wypowiedzenia umowy kredytowej])
	ON (1=0
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1 
	WHEN NOT MATCHED THEN 
		INSERT 
		(wi_numer, wi_tytul, wi_wt_id, wi_ko_id_wierzyciel_pierwotny,wi_data_umowy ) 
		VALUES 
		(wi_numer, wi_tytul, wi_wt_id, wi_ko_id_wierzyciel_pierwotny,wi_data_umowy )
	OUTPUT source.import_pk_key, inserted.wi_id, source.[Cena zakupu], source.[Planowany odzysk], source.[Data wypowiedzenia umowy kredytowej],source.wi_numer
	--,$action
	INTO #imported_wierzytelnosc (import_pk_key, imp_id, [Cena zakupu], [Planowany odzysk],[Data wypowiedzenia umowy kredytowej],wi_numer);
	
	

		-- Tabela #atrybut_wartosc_inserted_WI w uzywam merge zeby wyciagnac id atrybutu.
		IF object_id('tempdb..#atrybut_wartosc_inserted_WI') IS NOT NULL
			begin 
				drop table #atrybut_wartosc_inserted_WI
				print 'usunieto tabele #atrybut_wartosc_inserted_WI'
			end
	
		create table #atrybut_wartosc_inserted_WI
			(
				[atw_id] [int] NOT NULL,
				[atw_att_id] [int] NOT NULL,
				[atw_wartosc] [varchar](max) NULL,
				wi_id int
			)

		IF object_id('tempdb..#atrybut_wartosc_inserted_WI') IS NOT NULL
			begin 
				print 'utworzono tabele #atrybut_wartosc_inserted_WI'
			end;
		MERGE [dbo].[atrybut_wartosc]  AS target
			USING 
				( 
					Select
						10 as [atw_att_id],
					    cast([Cena zakupu] as varchar(100)) as [atw_wartosc],
					    imp_id
				--	    [atw_att_id]
					from  #imported_wierzytelnosc
					
					UNION ALL
					
					Select
						11 as [atw_att_id],
					    cast([Planowany odzysk] as varchar(100)) as [atw_wartosc],
					    imp_id
				--	    [atw_att_id]
					from  #imported_wierzytelnosc
					
					UNION ALL
					
					Select
						12 as [atw_att_id],
					    convert(varchar(10),[Data wypowiedzenia umowy kredytowej],110) as [atw_wartosc],
					    imp_id
				--	    [atw_att_id]
					from  #imported_wierzytelnosc
			
		   
			 )
			AS source
			ON (1=0)
			WHEN NOT MATCHED THEN 
			INSERT 
			(
					[atw_att_id]
				   ,[atw_wartosc]
			) VALUES
			(   
					[atw_att_id]
				   ,[atw_wartosc]
			)
		  Output    inserted.[atw_id]
				   ,inserted.[atw_att_id]
				   ,inserted.[atw_wartosc]
				   ,source.imp_id
		  INTO  #atrybut_wartosc_inserted_WI;





INSERT INTO [atrybut_wierzytelnosc]
           ([atwi_atw_id]
           ,[atwi_wi_id])

select 
[atw_id],
wi_id
FROM #atrybut_wartosc_inserted_WI




end







-----------------------------------
--wierzytelnosc_rola
-----------------------------------
PRINT 'wierzytelnosc_rola'

IF object_id('tempdb..#imported_wierzytelnosc_rola') IS NOT NULL drop table #imported_wierzytelnosc_rola
create table #imported_wierzytelnosc_rola 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS 
	);	

begin

MERGE wierzytelnosc_rola AS target
	USING (
		select distinct isnull(ltrim(rtrim(ex_rb_nr)),'')+'.'+isnull(ex_wi_numer,'') collate polish_ci_ai import_pk_key
			,imported_wierzytelnosc.imp_id wir_wi_id
			,imported_sprawa.imp_id wir_sp_id
			,1 wir_wirt_id
			,null wir_kwota_poreczenia_do
			,null wir_data_od
			,null wir_data_do
			from #importExcel2
			join #imported_sprawa imported_sprawa on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai = imported_sprawa.import_pk_key
			join #imported_wierzytelnosc imported_wierzytelnosc on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai =imported_wierzytelnosc.import_pk_key
			where solidarny=1
	) 
	 AS source 
		(import_pk_key,wir_wi_id, wir_sp_id, wir_wirt_id, wir_kwota_poreczenia_do, wir_data_od, wir_data_do )
	ON (1=0
		--checksum( cast(source.wir_kwota_poreczenia_do as varchar(max)), convert(varchar,isnull(source.wir_data_od,'1900-01-01'),112), convert(varchar,isnull(source.wir_data_do,'2100-01-01'),112))
		--=checksum( cast(target.wir_kwota_poreczenia_do as varchar(max))
		--, convert(varchar,isnull(target.wir_data_od,'1900-01-01'),112), convert(varchar,isnull(target.wir_data_do,'2100-01-01'),112)
		--)
		--dziedziczy weryfikacje uko z p_import_tool_wierzytelnosc i p_import_tool_sprawa
		--source.wir_sp_id=target.wir_sp_id
		--and source.wir_wi_id=target.wir_wi_id
		--and source.wir_wirt_id=target.wir_wirt_id
		--and (source.wir_kwota_poreczenia_do=target.wir_kwota_poreczenia_do or source.wir_kwota_poreczenia_do is null)
		
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(wir_sp_id, wir_wi_id, wir_wirt_id, wir_kwota_poreczenia_do, wir_data_od, wir_data_do ) 
		VALUES 
		(wir_sp_id, wir_wi_id, wir_wirt_id, isnull(wir_kwota_poreczenia_do,0), isnull(wir_data_od,'1900-01-01'), isnull(wir_data_do ,'2100-01-01'))
	OUTPUT source.import_pk_key, inserted.wir_wi_id
	INTO #imported_wierzytelnosc_rola (import_pk_key, imp_id);

end

------------------------
--dokument
------------------------
IF object_id('tempdb..#imported_dokument') IS NOT NULL drop table #imported_dokument
PRINT 'dokument'
create table #imported_dokument 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS ,
	do_data_wystawienia datetime
	);	

IF object_id('tempdb..#dokument_uko') IS NOT NULL drop table #dokument_uko	
create table #dokument_uko
	(tmp_do_id int)
	
	insert into #dokument_uko
	select do_id from dokument where do_uko_id=@v_uko_id
	
	
			
Begin

MERGE dokument AS target
	USING (
		select  ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imp_id [do_wi_id]
, @v_uko_id [do_uko_id]
, 1 [do_dot_id]
, wi_numer [do_tytul]
, row_number() over(partition by imp_id order by (select 0)) [do_numer]
, ex_do_data_wystawienia [do_data_wystawienia]
, null [do_data_cesji] 
, ex_do_saldo_poczatkowe [do_saldo_poczatkowe]
, ex_do_uwagi collate Polish_CI_AS
+
case when ltrim(rtrim(isnull(ex_do_tytul,''))) collate Polish_CI_AS <> ltrim(rtrim(isnull(wi_numer,''))) collate Polish_CI_AS then ', '+ltrim(rtrim(isnull(ex_do_tytul,''))) collate Polish_CI_AS else '' end
+
case when ltrim(rtrim(isnull(ex_do_nr,''))) collate Polish_CI_AS <> ltrim(rtrim(isnull(wi_numer,''))) collate Polish_CI_AS and ltrim(rtrim(isnull(ex_do_nr,''))) collate Polish_CI_AS <>ltrim(rtrim(isnull(ex_do_tytul,''))) collate Polish_CI_AS then ', '+ltrim(rtrim(isnull(ex_do_tytul,''))) collate Polish_CI_AS else '' end

 as do_uwagi
from #importExcel2
join #imported_wierzytelnosc on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer collate polish_ci_ai=import_pk_key
--where  --solidarny=1
	) 
	 AS source 
		(import_pk_key, [do_wi_id], [do_uko_id], [do_dot_id], [do_tytul], [do_numer], [do_data_wystawienia], [do_data_cesji], [do_saldo_poczatkowe],do_uwagi )
	ON (1=0
		--checksum(
		--	cast(source.[do_wi_id] as varchar(max))
		--	, cast(source.[do_uko_id] as varchar(max))
		--	, cast(source.[do_dot_id] as varchar(max))
		--	, cast(source.[do_tytul] collate polish_ci_ai as varchar(max))
		--	, cast(source.[do_numer] collate polish_ci_ai as varchar(max))
		--	, convert(varchar,source.[do_data_wystawienia],112)
		--	, convert(varchar,source.[do_data_cesji],112)
		--	, cast(source.[do_saldo_poczatkowe] as varchar(max))
		--)=checksum(
		--	cast(target.[do_wi_id] as varchar(max))
		--	, cast(target.[do_uko_id] as varchar(max))
		--	, cast(target.[do_dot_id] as varchar(max))
		--	, cast(target.[do_tytul] collate polish_ci_ai as varchar(max))
		--	, cast(target.[do_numer] collate polish_ci_ai as varchar(max))
		--	, convert(varchar,target.[do_data_wystawienia],112)
		--	, convert(varchar,target.[do_data_cesji],112)
		--	, cast(cast(target.[do_saldo_poczatkowe] as decimal(18,2)) as varchar(max))
		--)
		--and source.[do_wi_id]=target.[do_wi_id]
		--and source.[do_dot_id]=target.[do_dot_id]
		--and source.[do_numer] collate polish_ci_ai=target.[do_numer] collate polish_ci_ai
		--and target.do_id in (select tmp_do_id from #dokument_uko)--zabezpieczenie uko
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		([do_wi_id], [do_uko_id], [do_dot_id], [do_tytul], [do_numer], [do_data_wystawienia], [do_data_cesji], [do_saldo_poczatkowe],do_uwagi ) 
		VALUES 
		([do_wi_id], [do_uko_id], [do_dot_id], [do_tytul], [do_numer], [do_data_wystawienia], [do_data_cesji], [do_saldo_poczatkowe],do_uwagi )
	OUTPUT source.import_pk_key, inserted.do_id, inserted.do_data_wystawienia
	--,$action
	INTO #imported_dokument (import_pk_key, imp_id, do_data_wystawienia);
	
		--zabezpieczenie przed dublami;
	--delete #imported_dokument where import_pk_key in (select import_pk_key from #imported_dokument group by import_pk_key having COUNT(1)>1);
	
End

--------------------------------------
--ksiegowanie - obciazenie
--------------------------------------
PRINT 'ksiegowanie'
IF object_id('tempdb..#imported_ksiegowanie') IS NOT NULL drop table #imported_ksiegowanie

create table #imported_ksiegowanie 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS 
	);	

begin





MERGE ksiegowanie AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imp_id [ks_do_id]
,convert(varchar,getdate(),120) [ks_data_ksiegowania]
,do_data_wystawienia [ks_data_operacji]
,1 [ks_zamkniete]
,1 [ks_pierwotne]
,null as [ks_korekta]
,1 [ks_kst_id]
from #importExcel2 join #imported_dokument on  ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=import_pk_key
--where  solidarny=1
	) 
	 AS source 
		(import_pk_key, [ks_do_id], [ks_data_ksiegowania], [ks_data_operacji], [ks_zamkniete], [ks_pierwotne], [ks_korekta], [ks_kst_id] )
	ON ( 1=0
		--checksum( 
		--	cast(source.[ks_do_id] as varchar(max))
		--	, convert(varchar,source.[ks_data_ksiegowania],112)
		--	, convert(varchar,source.[ks_data_operacji],112)
		--	, cast(source.[ks_zamkniete] as varchar(max))
		--	, cast(source.[ks_pierwotne] as varchar(max))
		--	, cast(source.[ks_korekta] as varchar(max))
		--	, cast(source.[ks_kst_id] as varchar(max))
		--)
		--=checksum(
		--	cast(target.[ks_do_id] as varchar(max))
		--	, convert(varchar,target.[ks_data_ksiegowania],112)
		--	, convert(varchar,target.[ks_data_operacji],112)
		--	, cast(target.[ks_zamkniete] as varchar(max))
		--	, cast(target.[ks_pierwotne] as varchar(max))
		--	, cast(target.[ks_korekta] as varchar(max))
		--	, cast(target.[ks_kst_id] as varchar(max))
		--)--dziedziczy weryfikacje uko z p_import_tool_dokument
		--and source.[ks_do_id]=target.[ks_do_id]
		--and source.[ks_kst_id]=target.[ks_kst_id]
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		([ks_do_id], [ks_data_ksiegowania], [ks_data_operacji], [ks_zamkniete], [ks_pierwotne], [ks_korekta], [ks_kst_id] ) 
		VALUES 
		([ks_do_id], [ks_data_ksiegowania], [ks_data_operacji], [ks_zamkniete], [ks_pierwotne], [ks_korekta], [ks_kst_id] )
	OUTPUT source.import_pk_key, inserted.ks_id
	--,$action
	INTO #imported_ksiegowanie (import_pk_key, imp_id);

	set @p_errors_out ='<root>'+(select import_pk_key, 'Nie mo¿na jednoznacznie rozpoznaæ ksiêgowania' error from #imported_ksiegowanie error group by import_pk_key having COUNT(1)>1 for XML AUTO)+'</root>'

	--zabezpieczenie przed dublami;
	--delete #imported_ksiegowanie where import_pk_key in (select import_pk_key from #imported_ksiegowanie group by import_pk_key having COUNT(1)>1);
	
	end
	
----------------------------------------------
--ksiegowanie_dekret - obci¹¿enie
----------------------------------------------
PRINT 'ksiegowanie_dekret'
Begin

--kapital
	MERGE ksiegowanie_dekret AS target
	USING (
		
select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and (cast(replace(ex_kapital,',','.') as decimal(18,2)))<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital, ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON (1=0
		--checksum( 
		--	cast(source.ksd_kwota_kapital as varchar(max))
		--	, convert(varchar,source.ksd_data_wymagalnosci,112)
		--	, convert(varchar,source.ksd_data_naliczania_odsetek,112)
		--)
		--=checksum(
		--	cast(target.ksd_kwota_wn as varchar(max))
		--	, convert(varchar,target.ksd_data_wymagalnosci,112)
		--	, convert(varchar,target.ksd_data_naliczania_odsetek,112)
		--)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
		--and source.ksd_ks_id=target.ksd_ks_id
		--and source.ksd_do_id=target.ksd_do_id
		--and target.ksd_ksk_id=2
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 2, ksd_do_id, ksd_kwota_kapital, 0, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	;--OUTPUT source.import_pk_key, inserted.ksd_id
	--,$action
	--INTO #imported (import_pk_key, imp_id);	


--koszt

	MERGE ksiegowanie_dekret AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and cast(replace(ex_koszty,',','.') as decimal(18,2))<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital,  ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON ( 1=0 )
	--	checksum( 
	--		cast(source.ksd_kwota_koszt as varchar(max))
	--		, convert(varchar,source.ksd_data_wymagalnosci,112)
	--		, convert(varchar,source.ksd_data_naliczania_odsetek,112)
	--	)
	--	=checksum(
	--		cast(target.ksd_kwota_wn as varchar(max))
	--		, convert(varchar,target.ksd_data_wymagalnosci,112)
	--		, convert(varchar,target.ksd_data_naliczania_odsetek,112)
	--	)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
	--	and source.ksd_ks_id=target.ksd_ks_id
	--	and source.ksd_do_id=target.ksd_do_id
	--	and target.ksd_ksk_id=10
	--)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 10, ksd_do_id, ksd_kwota_koszt, 0, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek );
	--OUTPUT source.import_pk_key, inserted.ksd_id
	--,$action
	--INTO #imported (import_pk_key, imp_id);




--odsetki karne

	MERGE ksiegowanie_dekret AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital, ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON (1=0
		--checksum( 
		--	cast(source.ksd_kwota_odsetki_karne as varchar(max))
		--	, convert(varchar,source.ksd_data_wymagalnosci,112)
		--	, convert(varchar,source.ksd_data_naliczania_odsetek,112)
		--)
		--=checksum(
		--	cast(target.ksd_kwota_wn as varchar(max))
		--	, convert(varchar,target.ksd_data_wymagalnosci,112)
		--	, convert(varchar,target.ksd_data_naliczania_odsetek,112)
		--)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
		--and source.ksd_ks_id=target.ksd_ks_id
		--and source.ksd_do_id=target.ksd_do_id
		--and target.ksd_ksk_id=5
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 5, ksd_do_id, ksd_kwota_odsetki_karne, 0, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek );
	--OUTPUT source.import_pk_key, inserted.ksd_id
	--INTO #imported (import_pk_key, imp_id);


--odsetki umowne
	MERGE ksiegowanie_dekret AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and ex_odsetki_umowne<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital, ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON (1=0
		--checksum( 
		--	cast(source.ksd_kwota_odsetki_umowne as varchar(max))
		--	, convert(varchar,source.ksd_data_wymagalnosci,112)
		--	, convert(varchar,source.ksd_data_naliczania_odsetek,112)
		--)
		--=checksum(
		--	cast(target.ksd_kwota_wn as varchar(max))
		--	, convert(varchar,target.ksd_data_wymagalnosci,112)
		--	, convert(varchar,target.ksd_data_naliczania_odsetek,112)
		--)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
		--and target.ksd_ksk_id=6
		--and source.ksd_ks_id=target.ksd_ks_id
		--and source.ksd_do_id=target.ksd_do_id
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 6, ksd_do_id, ksd_kwota_odsetki_umowne, 0, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
;



--odsetki ustawowe
	MERGE ksiegowanie_dekret AS target
	USING (
			select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and ex_odsetki_ustawowe<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital,  ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON (1=0
		--checksum( 
		--	cast(source.ksd_kwota_odsetki_ustawowe as varchar(max))
		--	, convert(varchar,source.ksd_data_wymagalnosci,112)
		--	, convert(varchar,source.ksd_data_naliczania_odsetek,112)
		--)
		--=checksum(
		--	cast(target.ksd_kwota_wn as varchar(max))
		--	, convert(varchar,target.ksd_data_wymagalnosci,112)
		--	, convert(varchar,target.ksd_data_naliczania_odsetek,112)
		--)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
		--and target.ksd_ksk_id=8
		--and source.ksd_ks_id=target.ksd_ks_id
		--and source.ksd_do_id=target.ksd_do_id
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 8, ksd_do_id, ksd_kwota_odsetki_ustawowe, 0, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	;


	
--konto techniczne
	MERGE ksiegowanie_dekret AS target
	USING (
		select distinct ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai import_pk_key
, imported_ksiegowanie.imp_id ksd_ks_id
, imported_dokument.imp_id ksd_do_id
, cast(replace(ex_kapital,',','.') as decimal(18,2)) ksd_kwota_kapital
, cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))  ksd_kwota_odsetki_karne
, ex_odsetki_umowne ksd_kwota_odsetki_umowne
, ex_odsetki_ustawowe ksd_kwota_odsetki_ustawowe
, cast(replace(ex_koszty,',','.') as decimal(18,2)) ksd_kwota_koszt
, 0 ksd_kwota_koszty_procesowe
, 0 ksd_kwota_koszty_zastepstwa
, convert(datetime,ex_ksd_data_wymagalnosci) ksd_data_wymagalnosci
, isnull(convert(datetime,ex_data_naliczania_odsetek),convert(datetime,ex_ksd_data_wymagalnosci)+1) ksd_data_naliczania_odsetek
from #importExcel2
join #imported_ksiegowanie imported_ksiegowanie on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_ksiegowanie.import_pk_key
join #imported_dokument imported_dokument on ltrim(rtrim(ex_rb_nr))+'.'+ex_wi_numer+'.'+ex_do_tytul+'.'+ex_do_nr+ cast(ex_nr_wiersza as varchar) collate polish_ci_ai=imported_dokument.import_pk_key
--where  solidarny=1
		and (ex_odsetki_ustawowe+ex_odsetki_umowne+cast(replace(ex_odsetki_karne,',','.') as decimal(18,2))+cast(replace(ex_kapital,',','.') as decimal(18,2))+cast(replace(ex_odsetki_karne,',','.') as decimal(18,2)))<>0
	) 
	 AS source 
		(import_pk_key, ksd_ks_id, ksd_do_id, ksd_kwota_kapital, ksd_kwota_odsetki_karne, ksd_kwota_odsetki_umowne, ksd_kwota_odsetki_ustawowe,ksd_kwota_koszt, ksd_kwota_koszty_procesowe, ksd_kwota_koszty_zastepstwa, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	ON (1=0
		--checksum( 
		--	cast(isnull(source.ksd_kwota_kapital,0) + isnull(source.ksd_kwota_koszt,0) + isnull(source.ksd_kwota_odsetki_karne,0) + isnull(source.ksd_kwota_odsetki_umowne,0) + isnull(source.ksd_kwota_odsetki_ustawowe,0) + isnull(source.ksd_kwota_koszty_procesowe,0) + isnull(source.ksd_kwota_koszty_zastepstwa,0) as varchar(max))
		--	, convert(varchar,source.ksd_data_wymagalnosci,112)
		--	, convert(varchar,source.ksd_data_naliczania_odsetek,112)
		--)
		--=checksum(
		--	cast(target.ksd_kwota_ma as varchar(max))
		--	, convert(varchar,target.ksd_data_wymagalnosci,112)
		--	, convert(varchar,target.ksd_data_naliczania_odsetek,112)
		--)--dziedziczy weryfikacje uko z p_import_tool_ksiegowanie
		--and source.ksd_ks_id=target.ksd_ks_id
		--and source.ksd_do_id=target.ksd_do_id
		--and target.ksd_ksk_id=1
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(ksd_ks_id, ksd_ksk_id, ksd_do_id, ksd_kwota_wn, ksd_kwota_ma, ksd_data_wymagalnosci, ksd_data_naliczania_odsetek ) 
		VALUES 
		(ksd_ks_id, 1, ksd_do_id, 0, isnull(ksd_kwota_kapital,0) + isnull(source.ksd_kwota_koszt,0) + isnull(ksd_kwota_odsetki_karne,0) + isnull(ksd_kwota_odsetki_umowne,0) + isnull(ksd_kwota_odsetki_ustawowe,0) + isnull(ksd_kwota_koszty_procesowe,0) + isnull(ksd_kwota_koszty_zastepstwa,0)+ isnull(source.ksd_kwota_koszty_zastepstwa,0), ksd_data_wymagalnosci, ksd_data_naliczania_odsetek )
	;--OUTPUT source.import_pk_key, inserted.ksd_id
	--INTO #imported (import_pk_key, imp_id);


End

---- Poreczyciele i Wspó³pozwani

select 
	row_number() OVER(PARTITION BY ex_rb_nr ORDER BY ex_nazwisko collate Polish_CI_AS, ex_imie collate Polish_CI_AS, ex_firma collate Polish_CI_AS,  ex_nip collate Polish_CI_AS, ex_pesel collate Polish_CI_AS ,ex_regon collate Polish_CI_AS,ex_dl_numer)   As Solidarny
	,cast(row_number() OVER(ORDER BY ex_nazwisko collate Polish_CI_AS, ex_imie collate Polish_CI_AS, ex_firma collate Polish_CI_AS, ex_nip collate Polish_CI_AS, ex_pesel collate Polish_CI_AS,ex_regon collate Polish_CI_AS,ex_dl_numer) as VarChar(max))    as ex_nr_wiersza,
	[ex_nazwisko] collate Polish_CI_AS as [ex_nazwisko],[ex_imie] collate Polish_CI_AS as [ex_imie],[ex_firma] collate Polish_CI_AS as [ex_firma],
	[ex_nip] collate Polish_CI_AS as [ex_nip],[ex_pesel] collate Polish_CI_AS as [ex_pesel],[ex_regon] collate Polish_CI_AS as ex_regon,
	[ex_uwagi_dl] collate Polish_CI_AS as [ex_uwagi_dl],null as [ex_dl_numer],[ex_telefony] collate Polish_CI_AS as [ex_telefony],[ex_mail] collate Polish_CI_AS as [ex_mail],
	[ex_ulica_zm] collate Polish_CI_AS as [ex_ulica_zm],[ex_nr_domu_zm] collate Polish_CI_AS as [ex_nr_domu_zm],[ex_nr_lokalu_zm] collate Polish_CI_AS as [ex_nr_lokalu_zm],
	[ex_kod_zm] collate Polish_CI_AS as [ex_kod_zm],[ex_miejscowosc_zm] collate Polish_CI_AS as [ex_miejscowosc_zm],
	[ex_ulica_ko] collate Polish_CI_AS as [ex_ulica_ko],[ex_nr_domu_ko] collate Polish_CI_AS as [ex_nr_domu_ko],[ex_nr_lokalu_ko] collate Polish_CI_AS as [ex_nr_lokalu_ko],[ex_kod_ko] collate Polish_CI_AS as [ex_kod_ko],[ex_miejscowosc_ko] collate Polish_CI_AS as [ex_miejscowosc_ko],
	[ex_rb_nr] collate Polish_CI_AS as [ex_rb_nr], ROLA collate Polish_CI_AS as Rola,
	[NR sprawy z systemu importowego]  collate Polish_CI_AS as [NR sprawy z systemu importowego],
	[Data Przedawnienia]  collate Polish_CI_AS as [Data Przedawnienia],
	[Atrybut 2]  collate Polish_CI_AS as [Atrybut 2],
	[Atrybut 3]  collate Polish_CI_AS as [Atrybut 3],
	[Nr d³u¿nika z systemu kontrahenta] collate Polish_CI_AS as [Nr d³u¿nika z systemu kontrahenta],
	[Numer Sprawy Symfonia] collate Polish_CI_AS as [Numer Sprawy Symfonia]
	
into #importExcelRole2 
from #ImportExcelRole 
where 

(ex_nazwisko collate Polish_CI_AS	is not null	or 
ex_imie collate Polish_CI_AS	is not null	or 
ex_firma collate Polish_CI_AS is not null	or 
ex_nip collate Polish_CI_AS	is not null	or 
ex_pesel collate Polish_CI_AS is not null	or 
ex_regon collate Polish_CI_AS	is not null	or 
ex_uwagi_dl collate Polish_CI_AS	is not null	or 
ex_dl_numer	is not null	or 
ex_telefony collate Polish_CI_AS	is not null	or 
ex_mail collate Polish_CI_AS	is not null	or 
ex_ulica_zm collate Polish_CI_AS	is not null	or 
ex_nr_domu_zm collate Polish_CI_AS	is not null	or 
ex_nr_lokalu_zm collate Polish_CI_AS	is not null	or 
ex_kod_zm collate Polish_CI_AS	is not null	or 
ex_miejscowosc_zm collate Polish_CI_AS is not null	or 
ex_ulica_ko collate Polish_CI_AS	is not null	or 
ex_nr_domu_ko collate Polish_CI_AS	is not null	or 
ex_nr_lokalu_ko collate Polish_CI_AS	is not null	or 
ex_kod_ko collate Polish_CI_AS	is not null	or 
ex_miejscowosc_ko collate Polish_CI_AS is not null	or 
ex_rb_nr collate Polish_CI_AS	is not null	or 
[NR sprawy z systemu importowego] collate Polish_CI_AS	is not null	or 
[Data Przedawnienia]	is not null	or 
[Atrybut 2] collate Polish_CI_AS	is not null	or 
[Atrybut 3] collate Polish_CI_AS	is not null or 
[Numer Sprawy Symfonia] collate Polish_CI_AS is not null or 
[Nr d³u¿nika z systemu kontrahenta] collate Polish_CI_AS  is not null)	
--- Czasem excel wczytuje puste wiersze (Gdy ktos cos w nie wpisal a pozniej skasowal)

IF exists (select top 1 * from #importExcelRole2)

BEGIN
print 'Istniej¹ Porêczyciele/Wspó³pozwani'

set @v_xml_out='<root>'+(
select
		import_pk_key  collate Polish_CI_AS import_pk_key
		,dl_dx_id
		,dl_dt_id
		,dl_pl_id
		,dl_imie
		,dl_nazwisko
		,dl_nazwisko_rodowe
		,dl_numer_dowodu
		,dl_numer_paszportu
		,dl_pesel
		,dl_firma
		,dl_firma_skrot
		,dl_krs
		,dl_nip 
		,dl_regon
		,dl_bank
		,dl_konto_bankowe_nr
		,ROW_NUMBER() OVER(ORDER BY dl_pesel collate Polish_CI_AS) dl_numer
		,dl_import_info
		from (
		select distinct ltrim(rtrim([ex_rb_nr])) collate Polish_CI_AS +'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_imie],''))) collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_firma],''))) collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_ulica_zm],''))) collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) collate Polish_CI_AS + '.' + isnull([ex_pesel], '') collate Polish_CI_AS  + isnull([ex_regon], '') collate Polish_CI_AS +'.'+ isnull([ex_nip], '') collate Polish_CI_AS import_pk_key
		,1 dl_dx_id
		,case when LTRIM(RTRIM( isnull([ex_imie],''))) collate Polish_CI_AS <> '' and isnull(ex_firma, '') collate Polish_CI_AS <> '' then 2
			  when LTRIM(RTRIM( isnull([ex_imie],''))) collate Polish_CI_AS = '' and isnull(ex_firma, '') collate Polish_CI_AS <> '' then 3
			  else 1 end dl_dt_id 
		,4 dl_pl_id
		,LTRIM(RTRIM( isnull([ex_imie],''))) collate Polish_CI_AS as dl_imie
		,ltrim(rtrim(isnull([ex_nazwisko], ''))) collate Polish_CI_AS dl_nazwisko
		,null dl_nazwisko_rodowe
		,null dl_numer_dowodu
		,null dl_numer_paszportu
		,ex_pesel collate Polish_CI_AS dl_pesel
		,ex_firma collate Polish_CI_AS dl_firma
		,null dl_firma_skrot
		,Null dl_krs 
		,ex_nip collate Polish_CI_AS dl_nip 
		,ex_regon collate Polish_CI_AS dl_regon
		,null dl_bank
		,ex_rb_nr collate Polish_CI_AS dl_konto_bankowe_nr
		,isnull(ex_dl_numer,'') dl_numer
		,isnull(ex_nazwisko,'') collate Polish_CI_AS +isnull(ex_imie,'') collate Polish_CI_AS +isnull(ex_firma,'') collate Polish_CI_AS +isnull(ex_nip,'') collate Polish_CI_AS +isnull(ex_pesel,'') collate Polish_CI_AS +isnull(ex_regon,'') collate Polish_CI_AS dl_import_info
		from #importExcelRole2
			--left join dluznik on
			--	isnull(ex_nazwisko,'') = isnull(dl_nazwisko,'') collate Polish_CI_AS and
			--	isnull(ex_imie,'') = isnull(dl_imie,'') collate Polish_CI_AS and
			--	isnull(ex_firma,'') = isnull(dl_firma,'') collate Polish_CI_AS and
			--	isnull(ex_nip,'') = isnull(dl_nip,'') collate Polish_CI_AS and
			--	isnull(ex_pesel,'') = isnull(dl_pesel,'') collate Polish_CI_AS and
			--	isnull(ex_regon,'') = isnull(dl_regon,'') collate Polish_CI_AS		
		--where isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_firma,'')+isnull(ex_nip,'')+isnull(ex_pesel,'')+isnull(ex_regon,'') <> '' collate Polish_CI_AS
		) dluznik
for XML AUTO)+'</root>'
----Aktualizacja tabeli dluznicy
set @execCMD='<Parameters><Kontrakt>'+cast(@v_uko_id as varchar(max))+'</Kontrakt></Parameters>'
exec [p_import_tool_dluznik_Poreczyciel_Wspolpozwany] @v_xml_out, @execCMD, @v_xml_in out, @v_errors_in out


-- Konwersja XML'a otrzymanego z procedury [p_BPS_import_tool_dluznik] - Lista zaimportowanych dluznikow.
--select @v_xml_in
exec sp_xml_preparedocument @v_hDoc OUTPUT, @v_xml_in

create table #imported_dluznik_Poreczyciel_Wspolpozwany
	(imp_id int
	,import_pk_key varchar(max) collate Polish_CI_AS 
	)

insert into #imported_dluznik_Poreczyciel_Wspolpozwany
	select 
	imp_id 
	,import_pk_key 
	FROM OPENXML(@v_hDoc, '/root/imported',1)
	WITH 
	( imp_id int
	,import_pk_key varchar(max)
	)
	
	
---- ATRYBUTY DLUZNIKA---

	-- Tabela #atrybut_wartosc_inserted w uzywam merge zeby wyciagnac id atrybutu.
		IF object_id('tempdb..#atrybut_wartosc_insertedDL2') IS NOT NULL
			begin 
				drop table #atrybut_wartosc_insertedDL2
				print 'usunieto tabele #atrybut_wartosc_insertedDL2'
			end
	
		create table #atrybut_wartosc_insertedDL2
			(
				[atw_id] [int] NOT NULL,
				[atw_att_id] [int] NOT NULL,
				[atw_wartosc] [varchar](max) NULL,
				import_pk_key [varchar](max) collate Polish_CI_AS  NULL
			)

		IF object_id('tempdb..#atrybut_wartosc_insertedDL2') IS NOT NULL
			begin 
				print 'utworzono tabele #atrybut_wartosc_insertedDL2'
			end

Begin
		MERGE [dbo].[atrybut_wartosc]  AS target
			USING 
				(
					Select distinct
						ltrim(rtrim(ex_rb_nr))collate Polish_CI_AS +'.'+ltrim(rtrim(isnull([ex_nazwisko], '')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_imie],'')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_firma],'')))collate Polish_CI_AS+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))collate Polish_CI_AS+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],'')))collate Polish_CI_AS + '.' + isnull([ex_pesel], '')collate Polish_CI_AS+ isnull([ex_regon], '')collate Polish_CI_AS+'.'+ isnull([ex_nip], '')collate Polish_CI_AS import_pk_key,
						7 as [atw_att_id]
					   ,isnull([ex_uwagi_dl],'') as [atw_wartosc]
					from  #importExcelRole2
					
					Union all
					
					Select distinct
						ltrim(rtrim(ex_rb_nr))collate Polish_CI_AS+'.'+ltrim(rtrim(isnull([ex_nazwisko], '')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_imie],'')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_firma],'')))collate Polish_CI_AS+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))collate Polish_CI_AS+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],'')))collate Polish_CI_AS + '.' + isnull([ex_pesel], '')collate Polish_CI_AS+ isnull([ex_regon], '')collate Polish_CI_AS+'.'+ isnull([ex_nip], '')collate Polish_CI_AS  as import_pk_key,
						9 as [atw_att_id]
					   ,isnull([Nr d³u¿nika z systemu kontrahenta],'') as [atw_wartosc]
					from  #importExcelRole2
		  		   
			 )
			AS source (import_pk_key,[atw_att_id],[atw_wartosc])
			ON (1=0)
			WHEN NOT MATCHED THEN 
			INSERT 
			(
					[atw_att_id]
				   ,[atw_wartosc]
			) 
			VALUES
			(   
					[atw_att_id]
				   ,[atw_wartosc]
			)
		  Output   
				    inserted.[atw_id]
				   ,inserted.[atw_att_id]
				   ,inserted.[atw_wartosc]
				   ,source.import_pk_key 
		  INTO  #atrybut_wartosc_insertedDL2;
										
		print 'Liczba wierszy zaimportowana do tabeli atrybut_wartosc: ' +cast(@@Rowcount as varchar(max))

		insert into dbo.atrybut_dluznik (
										   [atdl_atw_id]
										  ,[atdl_dl_id]
										 )
		
		select 
			[atw_id] as [atdl_atw_id]
			,imported_dluznik.imp_id as [atdl_dl_id]
			from #atrybut_wartosc_insertedDL2
			join #imported_dluznik imported_dluznik on imported_dluznik.import_pk_key= #atrybut_wartosc_insertedDL2.import_pk_key   collate polish_ci_ai

end	
	
	
----------------------------------------------------------------
--rachunki bankowe z Sufixami dla Porêczycieli i Wspó³pozwanych.
----------------------------------------------------------------

begin


create table #rachunek_bankowy_uko_wspolpozwani_poreczyciele
	(tmp_rb_id int)
	
	insert into #rachunek_bankowy_uko_wspolpozwani_poreczyciele
	select sp_rb_id from v_sprawa_uko join sprawa on v_sprawa_uko.sp_id=sprawa.sp_id where uko_id=@v_uko_id
	
	--usun z powyzszego rb, ktore maja powtarzajace sie numery - inaczej merge nie przejdzie, a poza tym nie wiadomo z ktorym polaczyc sp
	delete #rachunek_bankowy_uko_wspolpozwani_poreczyciele
	where tmp_rb_id in (
		select rb_id
		from rachunek_bankowy
		where rb_nr in (
			select rb_nr
			from rachunek_bankowy
			group by rb_nr
			having COUNT(1)>1
		)
	)

	create table #imported_rachunek_Poreczyciel_Wspolpozwany 
	(
	imp_id int,
	import_pk_key varchar(max) collate Polish_CI_AS 
	);	

Begin

MERGE rachunek_bankowy AS target
	USING (
				select import_pk_key,
				       rb_nr+ cast(rank() over(partition by ROLA order by RN) as varchar(max))
				       ,'bank' rb_bank
				       
				       from (	
					
					select ltrim(rtrim([ex_rb_nr]))collate Polish_CI_AS+'.'+ltrim(rtrim(isnull([ex_nazwisko], '')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_imie],'')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_firma],'')))collate Polish_CI_AS+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))collate Polish_CI_AS + '.' + ltrim(rtrim(isnull([ex_ulica_ko],'')))collate Polish_CI_AS + '.' + isnull([ex_pesel], '')collate Polish_CI_AS + isnull([ex_regon], '')collate Polish_CI_AS +'.'+ isnull([ex_nip], '')collate Polish_CI_AS import_pk_key
					,ltrim(rtrim(ex_rb_nr)) collate Polish_CI_AS +'_'+Rola rb_nr  
					,'bank' rb_bank 
					,ROLA 
					,row_number() over(order by ex_rb_nr) RN
				from #importExcelRole2)Z
	--where isnull(ex_wi_numer,'')<>''
	) 
	 AS source 
		(import_pk_key, rb_nr, rb_bank)
	ON (1=0
		--source.rb_nr=target.rb_nr  collate polish_ci_ai
		--AND target.rb_id in (select tmp_rb_id from #rachunek_bankowy_uko)
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(rb_nr, rb_bank) 
		VALUES 
		(rb_nr, rb_bank)
	OUTPUT source.import_pk_key, inserted.rb_id
	--,$action
	INTO #imported_rachunek_Poreczyciel_Wspolpozwany (import_pk_key, imp_id);

--zabezpieczenie przed dublami;
	delete #imported_rachunek_Poreczyciel_Wspolpozwany where import_pk_key in (select import_pk_key from #imported_rachunek_Poreczyciel_Wspolpozwany group by import_pk_key having COUNT(1)>1);
end



-------------------------------------------
--sprawa dla Porêczycieli i Wspó³pozwanych.
-------------------------------------------


--declare @max_sp_numer int
select @max_sp_numer=MAX(cast(sp_numer as int))
from sprawa 
where isnumeric(sp_numer)=1
set @max_sp_numer=isnull(@max_sp_numer,0);

  
delete from #sprawa_uko
   
 insert into #sprawa_uko  
 select sp_id from v_sprawa_uko where uko_id=@v_uko_id
 
 create table #imported_sprawa_Poreczyciele_Wspolpozwani   
 (  
 imp_id int,  
 import_pk_key varchar(max)  collate Polish_CI_AS  
 ); 
 
begin



MERGE sprawa AS target  
 USING (  
  select import_pk_key
		, @max_sp_numer+ROW_NUMBER() over (order  by import_pk_key) sp_numer
		, sp_import_info
		, sp_rb_id
		, null sp_numer_migracja
		, data_obslugi_od sp_data_obslugi_od
		, null as sp_data_obslugi_do
		, null as sp_komentarz
from (
	select distinct ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate polish_ci_ai import_pk_key
	, imp_id sp_rb_id
	, @v_data_obslugi_od as data_obslugi_od 
	, 'Import z Excel - ' + Convert(VarChar(20),GETDATE(),110) +'Wsp/Por' sp_import_info
	from #importExcelRole2
	inner join #imported_rachunek_Poreczyciel_Wspolpozwany on (ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '')) =import_pk_key collate polish_ci_ai
	--where --ISNULL(ex_wi_numer,'')<>'' and 
	
	)dane_wew
 )   
  AS source   
  (import_pk_key, sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )  
 ON  (  
  --source.sp_import_info collate polish_ci_ai=target.sp_import_info collate polish_ci_ai  
  --AND target.sp_id in (select tmp_sp_id from #sprawa_uko)  
  1=0
  
  )  
 WHEN NOT MATCHED THEN   
  INSERT   
  (sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )   
  VALUES   
  (sp_numer, sp_import_info, sp_rb_id, sp_numer_migracja, sp_data_obslugi_od, sp_data_obslugi_do, sp_komentarz )  
 OUTPUT source.import_pk_key, inserted.sp_id  
 INTO #imported_sprawa_Poreczyciele_Wspolpozwani (import_pk_key, imp_id);  

end







select sp_id,sp_numer,us_id,Windykator
into #sprawyWindykatorzy2
from sprawa
join #imported_sprawa_Poreczyciele_Wspolpozwani imported_sprawa on imported_sprawa.imp_id=sprawa.sp_id 
join (select distinct 
						ltrim(rtrim(ex_rb_nr)) as import_pk_key
						 
						from #importExcel2
				)Windyk on substring(imported_sprawa.import_pk_key,0,27)=Windyk.import_pk_key collate Polish_CI_AS
join (select distinct 
						ltrim(rtrim(ex_rb_nr)) as import_pk_key, 
						Windykator 
						from #importExcel2
				)Windyk2 on Windyk.import_pk_key=Windyk2.import_pk_key collate Polish_CI_AS
				
join ge_user on Windykator=us_login collate Polish_CI_AS

 --update 
update spr
set spr.sp_pr_id=us_id
from sprawa spr
join #sprawyWindykatorzy2 on #sprawyWindykatorzy2.sp_id=spr.sp_id


-- operator

INSERT INTO [operator]
           ([op_sp_id]
           ,[op_us_id]
           ,[op_opt_id]
           ,[op_data_od]
           ,[op_data_do]
                 )
select 
sp_id,
us_id,
1,
getdate(),
null
from #sprawyWindykatorzy2



---- ATRYBUTY---

	-- Tabela #atrybut_wartosc_inserted w uzywam merge zeby wyciagnac id atrybutu.
		IF object_id('tempdb..#atrybut_wartosc_inserted2') IS NOT NULL
			begin 
				drop table #atrybut_wartosc_inserted2
				print 'usunieto tabele #atrybut_wartosc_inserted'
			end
	
		create table #atrybut_wartosc_inserted2
			(
				[atw_id] [int] NOT NULL,
				[atw_att_id] [int] NOT NULL,
				[atw_wartosc] [varchar](max) NULL,
				import_pk_key [varchar](max) collate Polish_CI_AS  NULL
			)

		IF object_id('tempdb..#atrybut_wartosc_inserted2') IS NOT NULL
			begin 
				print 'utworzono tabele #atrybut_wartosc_inserted2'
			end

Begin
		MERGE [dbo].[atrybut_wartosc]  AS target
			USING 
				(
					Select distinct
						imported_sprawa.import_pk_key collate polish_ci_ai as import_pk_key,
						6 as [atw_att_id]
					   ,isnull([NR sprawy z systemu importowego],'') as [atw_wartosc]
					from  #importExcelRole2
					join #imported_sprawa imported_sprawa on substring(imported_sprawa.import_pk_key,0,27)=#importExcelRole2.ex_rb_nr collate polish_ci_ai
		   UNION ALL
					Select distinct
						imported_sprawa.import_pk_key collate polish_ci_ai as import_pk_key,
						3 as [atw_att_id]
					   ,isnull([Data Przedawnienia],'') as [atw_wartosc]
					from  #importExcelRole2
					join #imported_sprawa imported_sprawa on substring(imported_sprawa.import_pk_key,0,27)=#importExcelRole2.ex_rb_nr collate polish_ci_ai
		   UNION ALL
					Select distinct
						imported_sprawa.import_pk_key collate polish_ci_ai as import_pk_key,
						4 as [atw_att_id]
					   ,isnull([Atrybut 2],'') as [atw_wartosc]
					from  #importExcelRole2
					join #imported_sprawa imported_sprawa on substring(imported_sprawa.import_pk_key,0,27)=#importExcelRole2.ex_rb_nr collate polish_ci_ai
		   UNION ALL
					Select distinct
						imported_sprawa.import_pk_key collate polish_ci_ai as import_pk_key,
						5 as [atw_att_id]
					   ,isnull([Atrybut 3],'') as [atw_wartosc]
					from  #importExcelRole2
					join #imported_sprawa imported_sprawa on substring(imported_sprawa.import_pk_key,0,27)=#importExcelRole2.ex_rb_nr collate polish_ci_ai
		    UNION ALL
					Select distinct
						imported_sprawa.import_pk_key collate polish_ci_ai as import_pk_key,
						8 as [atw_att_id]
					   ,isnull([Numer Sprawy Symfonia],'') as [atw_wartosc]
					from  #importExcelRole2
					join #imported_sprawa imported_sprawa on substring(imported_sprawa.import_pk_key,0,27)=#importExcelRole2.ex_rb_nr collate polish_ci_ai
			 )
			AS source (import_pk_key,[atw_att_id],[atw_wartosc])
			ON (1=0)
			WHEN NOT MATCHED THEN 
			INSERT 
			(
					[atw_att_id]
				   ,[atw_wartosc]
			) 
			VALUES
			(   
					[atw_att_id]
				   ,[atw_wartosc]
			)
		  Output   
				    inserted.[atw_id]
				   ,inserted.[atw_att_id]
				   ,inserted.[atw_wartosc]
				   ,source.import_pk_key 
		  INTO  #atrybut_wartosc_inserted2;
										
		print 'Liczba wierszy zaimportowana do tabeli atrybut_wartosc: ' +cast(@@Rowcount as varchar(max))

		insert into dbo.atrybut_sprawa (
										   [atsp_atw_id]
										  ,[atsp_sp_id]
										 )
		
		select 
			[atw_id] as [atsp_atw_id]
			,imported_sprawa.imp_id as [atsp_sp_id]
			from #atrybut_wartosc_inserted2
			join #imported_sprawa_Poreczyciele_Wspolpozwani imported_sprawa on imported_sprawa.import_pk_key= #atrybut_wartosc_inserted2.import_pk_key   collate polish_ci_ai

end


------------------------------------------------
--sprawa_rola dla Porêczycieli i Wspó³pozwanych.
------------------------------------------------

begin

MERGE sprawa_rola AS target
	USING (
		select distinct import_pk_key
		,spr_sp_id spr_sp_id
		,spr_dl_id spr_dl_id
		,1 as spr_sprt_id
		,null spr_kwota_poreczenia_do
		,null spr_data_od
		,null spr_data_do
	from (
		select distinct
		ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate polish_ci_ai as import_pk_key
		,ex_rb_nr
			,imported_sprawa.imp_id spr_sp_id
			,imported_dluznik.imp_id spr_dl_id
		from #importExcelRole2
		join #imported_sprawa_Poreczyciele_Wspolpozwani imported_sprawa on ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate polish_ci_ai  =imported_sprawa.import_pk_key
		join #imported_dluznik_Poreczyciel_Wspolpozwany imported_dluznik on (ltrim(rtrim(ex_rb_nr))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '')) collate polish_ci_ai = imported_dluznik.import_pk_key
)dane_wew
	) 
	 AS source 
		(import_pk_key, spr_sp_id, spr_dl_id, spr_sprt_id, spr_kwota_poreczenia_do, spr_data_od, spr_data_do )
	ON (1=0
		--source.spr_sp_id=target.spr_sp_id
		--and source.spr_dl_id=target.spr_dl_id
		--and source.spr_sprt_id=target.spr_sprt_id
		--dziedziczy weryfikacje uko z p_import_tool_sprawa
	)
	WHEN MATCHED THEN 
		UPDATE SET 
		@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(spr_sp_id, spr_dl_id, spr_sprt_id, spr_kwota_poreczenia_do, spr_data_od, spr_data_do ) 
		VALUES 
		(spr_sp_id, spr_dl_id, spr_sprt_id, isnull(spr_kwota_poreczenia_do,0), isnull(spr_data_od,'1900-01-01'), isnull(spr_data_do ,'2100-01-01'))
;


end


-------------------------------------------------------
--wierzytelnosc_rola dla Porêczycieli i Wspó³pozwanych.
-------------------------------------------------------

Begin

MERGE wierzytelnosc_rola AS target
	USING (
		
select 
imported_wierzytelnosc.import_pk_key,
imported_wierzytelnosc.imp_id as wi_id,
imported_sprawa_Poreczyciele_Wspolpozwani.imp_id as sp_id,
case when Rola ='W' then 3 when Rola='P' then 2 
when Rola='S' then 4 
when Rola='G' then 7 
when Rola='R' then 5
end as wir_wirt_id
,null wir_kwota_poreczenia_do
,null wir_data_od
,null wir_data_do
from #imported_wierzytelnosc imported_wierzytelnosc 
join #imported_dluznik_Poreczyciel_Wspolpozwany imported_dluznik_Poreczyciel_Wspolpozwany on substring(imported_dluznik_Poreczyciel_Wspolpozwany.import_pk_key,0,27)=substring(imported_wierzytelnosc.import_pk_key,0,27)
join #imported_sprawa_Poreczyciele_Wspolpozwani imported_sprawa_Poreczyciele_Wspolpozwani on imported_sprawa_Poreczyciele_Wspolpozwani.import_pk_key=imported_dluznik_Poreczyciel_Wspolpozwany.import_pk_key
join #importExcelRole2 on imported_dluznik_Poreczyciel_Wspolpozwany.import_pk_key=ltrim(rtrim([ex_rb_nr]))+'.'+ltrim(rtrim(isnull([ex_nazwisko], ''))) + '.' + ltrim(rtrim(isnull([ex_imie],''))) + '.' + ltrim(rtrim(isnull([ex_firma],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_zm],'')))+ '.' + ltrim(rtrim(isnull([ex_ulica_ko],''))) + '.' + isnull([ex_pesel], '')+ isnull([ex_regon], '')+'.'+ isnull([ex_nip], '') collate Polish_CI_AI

	) 
	 AS source 
		(import_pk_key,wir_wi_id, wir_sp_id, wir_wirt_id, wir_kwota_poreczenia_do, wir_data_od, wir_data_do )
	ON (1=0
		--checksum( cast(source.wir_kwota_poreczenia_do as varchar(max)), convert(varchar,isnull(source.wir_data_od,'1900-01-01'),112), convert(varchar,isnull(source.wir_data_do,'2100-01-01'),112))
		--=checksum( cast(target.wir_kwota_poreczenia_do as varchar(max))
		--, convert(varchar,isnull(target.wir_data_od,'1900-01-01'),112), convert(varchar,isnull(target.wir_data_do,'2100-01-01'),112)
		--)
		--dziedziczy weryfikacje uko z p_import_tool_wierzytelnosc i p_import_tool_sprawa
		--source.wir_sp_id=target.wir_sp_id
		--and source.wir_wi_id=target.wir_wi_id
		--and source.wir_wirt_id=target.wir_wirt_id
		--and (source.wir_kwota_poreczenia_do=target.wir_kwota_poreczenia_do or source.wir_kwota_poreczenia_do is null)
		
	)
	--WHEN MATCHED THEN 
	--	UPDATE SET 
	--	@v_ignore=1
	WHEN NOT MATCHED THEN 
		INSERT 
		(wir_sp_id, wir_wi_id, wir_wirt_id, wir_kwota_poreczenia_do, wir_data_od, wir_data_do ) 
		VALUES 
		(wir_sp_id, wir_wi_id, wir_wirt_id, isnull(wir_kwota_poreczenia_do,0), isnull(wir_data_od,'1900-01-01'), isnull(wir_data_do ,'2100-01-01'))
	OUTPUT source.import_pk_key, inserted.wir_wi_id
	INTO #imported_wierzytelnosc_rola (import_pk_key, imp_id);

end

print 'Koniec dodawania Wspó³pozwanych/ Porêczycieli'
--- 
END

-- ID d³u¿nika jako dl_numer
Update dluznik
set dl_numer=dl_id
where dl_numer is null or dl_numer=''


UPDATE dluznik
set dl_nazwa=LTRIM(RTRIM(LTRIM(RTRIM(isnull(dl.dl_imie,'')))+ ' ' + LTRIM(RTRIM(isnull(dl.dl_nazwisko,''))) + ' ' +LTRIM(RTRIM(isnull(dl.dl_firma,'')))))
from dluznik dl


select sp_numer, do_id, do_numer, ROW_NUMBER() over(partition by sp_id order by do_data_wystawienia,do_id) nr into ##upd1 
from dokument 
join wierzytelnosc_rola on wir_wi_id=do_wi_id 
join sprawa on wir_sp_id=sp_id
where do_uko_id<>276

delete from ##upd1 where do_id not in (
select distinct do_id from dokument 
join wierzytelnosc on do_wi_id=wi_id 
where (isnumeric(do_numer)=1 and do_numer<>wi_tytul collate polish_ci_as) or (do_numer='' or do_numer is null) 

)


select * into ##upd2 from ##upd1
where do_id in (
select distinct do_id from dokument join wierzytelnosc on do_wi_id=wi_id where (isnumeric(do_numer)=1 and do_numer<>wi_tytul collate polish_ci_as) or (do_numer='' or do_numer is null) )
and cast(isnull(do_numer,-1) as int)<>nr



update do
set do_numer=nr
from dokument do 
join ##upd2 upd on upd.do_id=do.do_id
where upd.do_id in (
select distinct do_id from dokument join wierzytelnosc on do_wi_id=wi_id where (isnumeric(do_numer)=1 and do_numer<>wi_tytul collate polish_ci_as) or (do_numer='' or do_numer is null) )
and cast(isnull(do.do_numer,-1) as int)<>nr

drop table ##upd1
drop table ##upd2

--exec p_sprawa_info
	--drop table #sprawa
	





	--cache
	create table #sprawa
	(t_sp_id int)

	insert into #sprawa
	select imp_id from #imported_sprawa

	--exec dbo.p_widoki_przygotuj_dane
	--exec dbo.p_sprawa_info
	--exec p_sprawa_info
	drop table #sprawa

exec dbo.p_sprawa_powiazana_przeladuj	


--END TRY
--BEGIN CATCH
--	SELECT 
--		ERROR_NUMBER() AS ErrorNumber
--		,ERROR_SEVERITY() AS ErrorSeverity
--		,ERROR_STATE() AS ErrorState
--		,ERROR_PROCEDURE() AS ErrorProcedure
--		,ERROR_LINE() AS ErrorLine
--		,ERROR_MESSAGE() AS ErrorMessage;

--	IF @@TRANCOUNT > 0
--		begin
--		--	set @p_out_isError=1
--			ROLLBACK TRANSACTION;
--		end
--END CATCH



END
END

exec p_sprawa_info
exec P_widoki_przygotuj_dane

set @p_out_isError=0





