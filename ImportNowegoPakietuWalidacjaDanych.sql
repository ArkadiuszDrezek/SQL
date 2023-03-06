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
 --- Czasem excel wczytuje puste wiersze (ktos cos w nich wpisal a pozniej skasowal)


if  (object_id(N'tempdb..#walidacja') is not null)
drop table #walidacja

create table #walidacja
(
[Dane identyfikacyjne] varchar(max), 
[Opis b³edu] varchar(max)
);
-- sprawdz czy plik o podanej nazwie nie byl juz poprawnie wgrany
	if exists
	( 
	select * from import
	 inner join
				(
				select imp_filename  from import where @p_import_filepath  like '%'+imp_guid_filename+'%'
				) tab on tab.imp_filename = import.imp_filename
				where imp_imps_id = 2
				)
	BEGIN
		insert into #walidacja
			select  '1','Taki plik zosta³ ju¿ wgrany'		
	END

--- WALIDACJA NA ETAPIE CZY DANE FINANSOWE SA TYPU DECIMAL

insert into #walidacja
	select [ex_rb_nr], 'b³êdnie wprowadzona kwota kapita³u' from #ImportExcelGlowny
	where
		(
		(ex_kwota_wymagana is null and [LACZNA KWOTA] is null))	-- jeœli ex_kapital nie bêdzie liczb¹ zostanie zaci¹gniêty jako null. Wówczas suma wartosci w kolumnie Laczna Kwota tez bêdzie null.

insert into #walidacja
	select [ex_rb_nr], 'b³êdnie wprowadzona kwota odsetek umownych' from #ImportExcelGlowny
	where
		(
		(ex_odsetki_umowne is null and [LACZNA KWOTA] is null))	-- jeœli ex_kapital nie bêdzie liczb¹ zostanie zaci¹gniêty jako null. Wówczas suma wartosci w kolumnie Laczna Kwota tez bêdzie null.

insert into #walidacja
select [ex_rb_nr], 'b³êdnie wprowadzona kwota odsetek ustawowych' from #ImportExcelGlowny
	where
		(
		([ex_odsetki_ustawowe] is null and [LACZNA KWOTA] is null))	-- jeœli ex_kapital nie bêdzie liczb¹ zostanie zaci¹gniêty jako null. Wówczas suma wartosci w kolumnie Laczna Kwota tez bêdzie null.

insert into #walidacja
select [ex_rb_nr], 'b³êdnie wprowadzona kwota odsetek karnych' from #ImportExcelGlowny
	where
		(
		([ex_odsetki_karne] is null and [LACZNA KWOTA] is null))	-- jeœli ex_kapital nie bêdzie liczb¹ zostanie zaci¹gniêty jako null. Wówczas suma wartosci w kolumnie Laczna Kwota tez bêdzie null.
insert into #walidacja
	select [ex_rb_nr], 'b³êdnie wprowadzona kwota kosztów' from #ImportExcelGlowny
	where
		(
		([ex_oplata_dodatkowa] is null and [LACZNA KWOTA] is null))	-- jeœli ex_kapital nie bêdzie liczb¹ zostanie zaci¹gniêty jako null. Wówczas suma wartosci w kolumnie Laczna Kwota tez bêdzie null.
				

	/*
-- Sprawdzenie  NRB	
	insert into #walidacja
	select ex_pesel, 'brak lub b³êdny numer rachunku bankowego' from #importExcel2
	where	
		(([ex_rb_nr] is null or [ex_rb_nr] like '' or Len([ex_rb_nr])<>26 )) -- DOPISAÆ inne warunki sprawdzajace.


-- NRB musi byc unikalne dla ca³ej bazy
	insert into #walidacja
	select distinct [ex_rb_nr], 'Taki numer NRB ju¿ istnieje w bazie' from #importExcel2
	join (select rb_nr from sprawa s join rachunek_bankowy on sp_rb_id=rb_id
						join cache_sprawa_info i on s.sp_id=i.sp_id
		)BAZA on BAZA.rb_nr=[ex_rb_nr] collate polish_ci_as
		
	*/	
-- Czy wspolne dane dla dokumentów w ramach 1 wierzytelnoœci

insert into #walidacja
select Y.[ex_rb_nr], 'istniej¹ ró¿ne dane dla dokumentów z 1 wierzytelnosci' from(

		select ex_wi_numer, COUNT([ex_rb_nr]) Ile
		from #importExcel2
		group by ex_wi_numer
		having COUNT(ex_wi_numer)>1
)Z
join (select [ex_rb_nr],ex_wi_numer, COUNT(ex_wi_numer) Ile2
		from #importExcel2
		
		group by ex_nazwisko,ex_imie,ex_firma,ex_nip,ex_pesel,ex_regon,ex_uwagi_dl,ex_dl_numer,ex_telefony,ex_mail,ex_ulica_zm,ex_nr_domu_zm,ex_nr_lokalu_zm,
				ex_kod_zm,ex_miejscowosc_zm,ex_ulica_ko,ex_nr_domu_ko,ex_nr_lokalu_ko,ex_kod_ko,ex_miejscowosc_ko,ex_wi_numer,ex_wi_data_umowy,ex_rb_nr,[NR sprawy z systemu importowego],
				[Data Przedawnienia],[Atrybut 2],[Atrybut 3],Windykator, [Nr d³u¿nika z systemu kontrahenta], [Numer Sprawy Symfonia]
		having COUNT(ex_wi_numer)>1
		)Y on Z.ex_wi_numer=Y.ex_wi_numer and Z.ex_wi_numer<>'brak' and Z.ex_wi_numer<> 'Umowa o kredyt'
where Z.Ile<>Y.Ile2

	
	
--sprawdzenie czy jest nazwa dluznika
	insert into #walidacja
	select [ex_rb_nr], 'brak danych d³u¿nika' from #importExcel2
	where	
		((ex_nazwisko is null or ex_nazwisko like '') and
		(ex_imie is null or ex_imie like '') and
		(ex_firma is null or ex_firma like ''))
		
--sprawdzenie czy s¹ numery dokumentów gdy jest wiêcej ni¿ 1 dokument w 1 wierzytelnosci

insert into #walidacja
select distinct [ex_rb_nr], 'brak numeru dokumentu' from #importExcel2
	where ex_wi_numer in (
							select ex_wi_numer from(
							select ex_wi_numer, COUNT(ex_wi_numer) Ile
							from #importExcel2
							group by ex_wi_numer
							having COUNT(ex_wi_numer)>1)Z) and ex_wi_numer is null

--- Sprawdzenie czy nie istnieje rola bez dluznika g³ównego
insert into #walidacja
select [ex_rb_nr], 'istnieje rola bez dluznika g³ównego' from #ImportExcelRole where [ex_rb_nr] not in (select distinct [ex_rb_nr] from #ImportExcelGlowny)

-- Sprawdze nie czy D³u¿nik nie wystêpuje wiêcej ni¿ raz w roli Wspo³pozwanego/Porêczyciela w 1 sprawie

 insert into #walidacja
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Wspo³pozwanego w 1 sprawie' from(
  select count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')) as ILE, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='W' and (isnull(ex_nazwisko,'')<>'' or isnull(ex_rb_nr,'')<>'' or isnull(ex_firma,'')<>'' or isnull(ex_pesel,'')<>'' or isnull(ROLA,'')<>'')
  and isnull(ex_pesel,'')<>'BRAK DANYCH' and isnull(ex_pesel,'')<>'BRAK'
  group by ex_rb_nr, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')
  having count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z
  union
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Wspo³pozwanego w 1 sprawie' from(
  select count( isnull(ex_pesel,'')+isnull(ROLA,'')+isnull(ex_firma,'')) as ILE, isnull(ex_pesel,'')+isnull(ROLA,'')+isnull(ex_pesel,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='W' and isnull(ex_pesel,'')<>'' and isnull(ex_pesel,'')<>'BRAK DANYCH'  and isnull(ex_pesel,'')<>'BRAK'
  group by ex_rb_nr, isnull(ex_pesel,'')+isnull(ROLA,'')+isnull(ex_pesel,'')
  having count( isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z
  
  insert into #walidacja
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Porêczyciela w 1 sprawie' from(
  select count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')) as ILE, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='P' and (isnull(ex_nazwisko,'')<>'' or isnull(ex_rb_nr,'')<>'' or isnull(ex_firma,'')<>'' or isnull(ex_pesel,'')<>'' or isnull(ROLA,'')<>'') and isnull(ex_pesel,'')<>'BRAK DANYCH'  and isnull(ex_pesel,'')<>'BRAK'
  group by ex_rb_nr, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')
  having count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z
  union
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Porêczyciela w 1 sprawie' from(
  select count( isnull(ex_pesel,'')+isnull(ROLA,'')) as ILE, isnull(ex_pesel,'')+isnull(ROLA,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='P' and isnull(ex_pesel,'')<>'' and isnull(ex_pesel,'')<>'BRAK DANYCH'  and isnull(ex_pesel,'')<>'BRAK'
  group by ex_rb_nr, isnull(ex_pesel,'')+isnull(ROLA,'')
  having count( isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z
  
 insert into #walidacja
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Spadkobiercy w 1 sprawie' from(
  select count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')) as ILE, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='S' and (isnull(ex_nazwisko,'')<>'' or isnull(ex_rb_nr,'')<>'' or isnull(ex_firma,'')<>'' or isnull(ex_pesel,'')<>'' or isnull(ROLA,'')<>'') and isnull(ex_pesel,'')<>'BRAK DANYCH'
  group by ex_rb_nr, isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,'')
  having count( isnull(ex_nazwisko,'')+isnull(ex_imie,'')+isnull(ex_rb_nr,'')+isnull(ex_firma,'')+isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z
  union
  select distinct  ex_rb_nr, 'D³u¿nik wystêpuje wiêcej ni¿ raz w roli Porêczyciela w 1 sprawie' from(
  select count( isnull(ex_pesel,'')+isnull(ROLA,'')) as ILE, isnull(ex_pesel,'')+isnull(ROLA,'') as Numer,ex_rb_nr from #ImportExcelRole
  Where ROLA='S' and isnull(ex_pesel,'')<>'' and isnull(ex_pesel,'')<>'BRAK DANYCH'
  group by ex_rb_nr, isnull(ex_pesel,'')+isnull(ROLA,'')
  having count( isnull(ex_pesel,'')+isnull(ROLA,''))>1
  )Z



-- Sprawdze nie czy D³u¿nik nie wystêpuje w dwóch rolach w 1 sprawie
 insert into #walidacja 
 select distinct Rb1,'D³u¿nik wystêpuje w dwóch rolach w 1 sprawie' from(
  select isnull(r1.ex_rb_nr,'') Rb1,
  isnull(R2.ex_rb_nr,'') Rb2
  
  from #ImportExcelRole R1
  join  #ImportExcelRole R2 on (isnull(r1.ex_nazwisko,'')+isnull(r1.ex_imie,'')+isnull(r1.ex_rb_nr,'')+isnull(r1.ex_firma,'')+isnull(r1.ex_pesel,'')) = (isnull(r2.ex_nazwisko,'')+isnull(r2.ex_imie,'')+isnull(r2.ex_rb_nr,'')+isnull(r2.ex_firma,'')+isnull(r2.ex_pesel,'')) and R2.Rola='W'
  where R1.ROLA='P'and (r1.ex_nazwisko is not null or r1.ex_rb_nr is not null or r1.ex_firma is not null or r1.ex_pesel is not null or r1.ROLA is not null)
 and (isnull(R2.ex_nazwisko,'')<>'' or isnull(R2.ex_rb_nr,'')<>'' or isnull(R2.ex_firma,'')<>'' or isnull(R2.ex_pesel,'')<>'' or isnull(R2.ROLA,'')<>'')
  and r1.ex_rb_nr is not null and R2.ex_rb_nr is not null
  )Z
  --union
  -- select distinct Rb1,'D³u¿nik wystêpuje w dwóch rolach w 1 sprawie' from(
  --select isnull(r1.ex_rb_nr,'') Rb1,
  --isnull(R2.ex_rb_nr,'') Rb2
  
  --from #ImportExcelRole R1
  --join  #ImportExcelRole R2 on r1.ex_pesel = r2.ex_pesel and R2.Rola='W'
  --where R1.ROLA='P' and isnull(R1.ex_pesel,'')<>'' and isnull(R2.ex_pesel,'')<>''
  --and r1.ex_rb_nr is not null and R2.ex_rb_nr is not null
  --)Z
  
--- Sprawdzanie czy dluznik sam sobie nie porêcza. 
  
 insert into #walidacja 
 select distinct ex_rb_nr, 'D³u¿nik jest Wspó³pozwanym/Porêczycielem w swojej sprawie g³ównej' from (
  select isnull(G.ex_rb_nr,'') as ex_rb_nr from #ImportExcelGlowny G
  join #ImportExcelRole R on isnull(G.ex_nazwisko,'')+isnull(G.ex_imie,'')+isnull(G.ex_rb_nr,'')+isnull(G.ex_firma,'')+isnull(G.ex_pesel,'')=
  isnull(R.ex_nazwisko,'')+isnull(R.ex_imie,'')+isnull(R.ex_rb_nr,'')+isnull(R.ex_firma,'')+isnull(R.ex_pesel,'')
  where (isnull(G.ex_nazwisko,'')<>'' or isnull(G.ex_rb_nr,'')<>''  or isnull(G.ex_firma,'')<>''  or isnull(G.ex_pesel,'')<>'' )
 and (isnull(R.ex_nazwisko,'')<>''  or isnull(R.ex_rb_nr,'')<>''  or isnull(R.ex_firma,'')<>''  or isnull(R.ex_pesel,'')<>'' )
 and isnull(R.ex_pesel,'')<>'BRAK DANYCH'
  )Z
  union 
  select isnull(G.ex_rb_nr,'') as  ex_rb_nr , 'D³u¿nik jest Wspó³pozwanym/Porêczycielem w swojej sprawie g³ównej' from #ImportExcelGlowny G
  join #ImportExcelRole R on isnull(G.ex_pesel,'')+isnull(G.ex_rb_nr,'')+isnull(G.ex_firma,'')=isnull(R.ex_pesel,'')+isnull(R.ex_rb_nr,'')+isnull(R.ex_firma,'')
  where isnull(G.ex_pesel,'')<>''    and isnull(G.ex_rb_nr,'')<>'' 
   and isnull(R.ex_pesel,'')<>'BRAK DANYCH'
  

--- Sprawdzanie numeru PESEL w 1 arkusz
--insert into #walidacja
--select ex_pesel, 'b³êdny PESEL d³u¿nika g³ównego' from #importExcel2 where (LEN(ex_pesel)<>11 or IsNumeric(ex_pesel)=0) and isnull(ex_pesel,'')<>''

--- Sprawdzanie numeru PESEL w 2 arkusz
--insert into #walidacja
--select ex_pesel, 'b³êdny PESEL w arkuszu z rolami' from #ImportExcelRole where (LEN(ex_pesel)<>11 or IsNumeric(ex_pesel)=0) and isnull(ex_pesel,'')<>''

--sprawdzenie czy sa dane wierzytelnosci
	insert into #walidacja
	select [ex_rb_nr], 'brak danych dotycz¹cych numeru wierzytelnoœci' from #importExcel2
	where
		(
		(ex_wi_numer is null or ex_wi_numer like ''))

	insert into #walidacja
	select [ex_rb_nr], 'brak danych dotycz¹cych daty umowy wierzytelnoœci' from #importExcel2
	where
		(
		(ex_wi_data_umowy is null or ex_wi_data_umowy like ''))	

	insert into #walidacja
	select [ex_rb_nr], 'brak danych dotycz¹cych daty wymagalnosci dokumentu' from #importExcel2
	where
		(
		(ex_ksd_data_wymagalnosci is null or ex_ksd_data_wymagalnosci like ''))	
	
	insert into #walidacja
	select [ex_rb_nr], 'brak danych dotycz¹cych kwoty kapita³u' from #importExcel2
	where
		(
		(ex_kapital is null or ex_kapital like ''))	
		
	insert into #walidacja
	select [ex_rb_nr], 'brak danych dotycz¹cych daty naliczania odsetek' from #importExcel2
	where
		(
		([ex_data_naliczania_odsetek] is null or [ex_data_naliczania_odsetek] like ''))		
			
---- sprawdz czy sa bledy
		if exists( select * from #walidacja)
		BEGIN
			select * from #walidacja order by [Opis b³edu]
			--drop table #importExcel2
			--drop table #importExcel
			return
		END

end
