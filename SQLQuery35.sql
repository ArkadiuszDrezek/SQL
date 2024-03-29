USE [CFBPS_Raporty_kontrolne]
GO
/****** Object:  StoredProcedure [dbo].[p_imsig_dane_zaimportuj]    Script Date: 2023-03-22 14:40:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Arkadiusz Drężek
-- Create date: 2019-11-20
-- Description:	Import danych z Internetowego Monitora Sądowego i Gospodarczego
-- =============================================
ALTER procedure [dbo].[p_imsig_dane_zaimportuj]
as

--tworzę tablę z danymi z iMSiG
if OBJECT_ID('temp..#iMSiG') is not null drop table #iMSiG

select
top 1 with ties 
 s.sp_id
,s.sp_numer as 'Nr sprawy'
,s.sp_pr_id
,isnull(STUFF(a.x.query('for $s in  entity/info/cleaned_name return <x>{concat(",",$s)}</x>').value('.','varchar(max)'),1,1,''),'') as 'Nazwa podmiotu' /*ogłoszenie może dotyczyć więcej niż jednej osoby dlatego w takich przypadkach pobieram wszystkie i wymieniam po przecinku*/
,isnull(STUFF(a.x.query('for $s in distinct-values(entity/info/legal_form) return <x>{concat(",",$s)}</x>').value('.','varchar(max)'),1,1,''),'') as 'Forma prawna' /*jeżeli forma prawna dla kilku osób jest taka sama to bierz unikat*/
,isnull(STUFF(a.x.query('for $s in distinct-values(entity/info/ownership_type) return <x>{concat(",",$s)}</x>').value('.','varchar(max)'),1,1,''),'') as 'Forma własności' /*jeżeli forma własności dla kilku osób jest taka sama to bierz unikat*/
,isnull(STUFF(a.x.query('for $s in entity/info/commencement_date return <x>{concat(",",$s)}</x>').value('.','varchar(max)'),1,1,''),'') as 'Data rozpoczęcia działalności lub data urodzenia' /*jeżeli ogłoszenie dotyczy więcej niż jednej osoby to wymieniam po przecinku*/

,isnull(STUFF(a.x.query('for $s in entity/address
                         return

												 if ($s/flat_number="")
												 then
                            <x>{concat(", ",($s/zip_code/text())[1]," "
                                           ,($s/town/text())[1]," "
                                           ,($s/street/text())[1]," "
                                           ,($s/house_number/text())[1]
                                       )}</x>
																			 
												 else
														<x>{concat(", ",($s/zip_code/text())[1]," "
																				,($s/town/text())[1]," "
																				,($s/street/text())[1]," "
																				,($s/house_number/text())[1],"/"
																				,($s/flat_number/text())[1]
																				)}</x>		 
												')
              .query('for $a in distinct-values(/x/text()) return $a').value('.','varchar(max)'),1,2,''),'')  as Adres --dla każdego root'a (ogłoszenia) może być kilka węzłów entity a każdy węzeł entity może zawierać kilka adresów, wymieniam więc wszystkie po przecinku i zostawiam tylko unikaty

,isnull(a.x.value('(proceeding/court_name)[1]','varchar(max)'),'') as 'Nazwa sądu'
,isnull(a.x.value('(proceeding/court_department)[1]','varchar(max)'),'') as 'Nazwa wydziału'
,isnull(STUFF(a.x.query('for $s in proceeding/signatures return <x>{concat(",",$s)}</x>').value('.','varchar(max)'),1,1,''),'') as 'Sygnatura' /*dla każdego ogłoszenia może być więcej niż jedna sygnatura więc pobieram wszystkie i wymieniam po przecinku*/
,isnull(a.x.value('(proceeding/commissioner_name)[1]','varchar(max)'),'') as 'Sędzia komisarz'
,isnull(a.x.value('(proceeding/commissioner_deputy_name)[1]','varchar(max)'),'') as 'Zastępca sędziego komisarza'
,isnull(a.x.value('(proceeding/administrator_name)[1]','varchar(max)'),'') as 'Nadzorca w postępowaniu'
,isnull(a.x.value('(proceeding/administrator_function)[1]','varchar(max)'),'') as 'Funkcja nadzorcy'

,isnull(a.x.value('(order/order_date)[1]','date'),'') as 'Data wydania postanowienia'
,isnull(a.x.value('(order/expiration_period)[1]','varchar(20)'),'') as 'Okres do działania (w dniach)'
,isnull(a.x.value('(order/expiration_date)[1]','date'),'') as 'Koniec okresu do działania'

,isnull(a.x.value('(msig_entry/chapter)[1]','varchar(max)'),'') as 'Rozdział MSiG'
,isnull(a.x.value('(msig_entry/section)[1]','varchar(max)'),'') as 'Sekcja MSiG'
,isnull(a.x.value('(msig_entry/signature)[1]','varchar(max)'),'') as 'Sygnatura ogłoszenia'
,isnull(a.x.value('(msig_entry/issue_date)[1]','date'),'') as 'Data publikacji ogłoszenia w MSiG'

,isnull(a.x.value('(content/text)[1]','varchar(max)'),'') as 'Treść ogłoszenia'

into #iMSiG

from ANALIZY.dbo.IMSIG_service_out as imsig
join dm_data_bps.dbo.dluznik on case when imsig_dl_nip_in is not null and imsig_dl_nip_in=dl_nip collate Polish_CI_AI then 1 when imsig_dl_nip_in is null and imsig_dl_regon_in is not null and imsig_dl_regon_in=dl_regon collate Polish_CI_AI then 1 when imsig_dl_nip_in is null and imsig_dl_regon_in is null and imsig_dl_pesel_in is not null and imsig_dl_pesel_in=dl_pesel collate Polish_CI_AI then 1 when imsig_dl_nip_in is null and imsig_dl_regon_in is null and imsig_dl_pesel_in is null and imsig_dl_krs_in is not null and imsig_dl_krs_in=dl_krs collate Polish_CI_AI then 1 else 0 end=1
join dm_data_bps.dbo.sprawa_rola on spr_dl_id=dl_id
join dm_data_bps.dbo.sprawa as s on spr_sp_id=s.sp_id
join dm_data_bps.dbo.cache_sprawa_info as csi on s.sp_id=csi.sp_id and sprawa_zamknieta=0
and etap_id not in (30,27,32,33,28,31,29,3)--wykluczam monitoring
cross apply imsig_xml_content.nodes('/root/Row') as a(x)
where not exists (
select 1 from 
dm_data_bps.dbo.akcja
join dm_data_bps.dbo.atrybut_akcji on atak_ak_id=ak_id
where atak_atakt_id=203 and ak_akt_id in (1268,1269,1270,1271,1272,1273,1274,1275,1276) and ak_sp_id=s.sp_id and atak_wartosc=isnull(a.x.value('(msig_entry/signature)[1]','varchar(max)'),'')
) --wykluczam ogłoszenia, które zostały już zaimportowane, sygnatura ogłoszenia jest równoznaczna z ID ogłoszenia
order by ROW_NUMBER() over (partition by isnull(a.x.value('(msig_entry/signature)[1]','varchar(max)'),''),s.sp_id order by s.sp_id)--partycjonuję po sygnaturze ogłoszenia i sprawie

--dodanie akcji z danymi z iMSiG
--====================================================================================================================--
if exists (select 1 from #iMSiG)

begin

		if OBJECT_ID('temp..#MergeLog') is not null drop table #MergeLog

		create table #MergeLog (
		ak_id int,
		[Nazwa sadu] varchar(max),
		[Data rozpoczecia dzialalnosci lub data urodzenia] varchar(255),
		FormaPrawna varchar(max),
		[Nazwa podmiotu] varchar(max),
		FormaWlasnosci varchar(max),
		Adres varchar(max),
		[Nazwa wydzialu] varchar(max),
		[Sygnatura upadlosciowa] varchar(max),
		[Sedzia komisarz] varchar(max),
		[Zastepca sedziego komisarza] varchar(max),
		[Nadzorca w postepowaniu] varchar(max),
		[Funkcja nadzorcy] varchar(max),
		[Data wydania postanowienia] date,
		[Okres do dzialania (w dniach)] int,
		[Koniec okresu do dzialania] date,
		[Rozdzial iMSiG] varchar(max),
		[Sygnatura ogloszenia] varchar(max),
		[Data publikacji ogloszenia w iMSig] date,
		[Tresc ogloszenia] varchar(max)
		)

		merge dm_data_bps.dbo.akcja as target using (
		select * from #iMSiG
		) as source on 1=0
		when not matched then insert
		([ak_akt_id], [ak_sp_id], [ak_kolejnosc], [ak_interwal], [ak_zakonczono], [ak_pr_id], [ak_publiczna])
		values (case when [Sekcja MSig]=1 then 1268 when [Sekcja MSig]=2 then 1269 when  [Sekcja MSig]=3 then 1270 when [Sekcja MSig]=4 then 1271 when [Sekcja MSig]=5 then 1272 when [Sekcja MSig]=6 then 1273 when [Sekcja MSig]=7 then 1274 when [Sekcja MSig]=8 then 1275 when [Sekcja MSig]=9 then 1276 else 1276  end,sp_id,0,0,getdate(),5,1)
		output inserted.ak_id, source.[Nazwa sądu], source.[Data rozpoczęcia działalności lub data urodzenia],source.[Forma prawna],source.[Nazwa podmiotu],source.[Forma własności],source.Adres,source.[Nazwa wydziału],source.[Sygnatura],source.[Sędzia komisarz],source.[Zastępca sędziego komisarza],source.[Nadzorca w postępowaniu],source.[Funkcja nadzorcy],source.[Data wydania postanowienia],source.[Okres do działania (w dniach)],source.[Koniec okresu do działania],source.[Rozdział MSiG],source.[Sygnatura ogłoszenia],source.[Data publikacji ogłoszenia w MSiG],source.[Treść ogłoszenia] into #MergeLog;

		insert into dm_data_bps.dbo.rezultat
		([re_ak_id], [re_data_planowana], [re_us_id_planujacy], [re_data_wykonania], [re_us_id_wykonujacy], [re_konczy], [re_komentarz])
		select ak_id,GETDATE(),5,GETDATE(),5,1,[Tresc ogloszenia] from #MergeLog

		--dodanie atrybutu "Nazwa sadu"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,65,[Nazwa sadu] from #MergeLog

		--dodanie atrybutu "Data rozpoczecia dzialalnosci lub data urodzenia"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,205,[Data rozpoczecia dzialalnosci lub data urodzenia] from #MergeLog where [Data rozpoczecia dzialalnosci lub data urodzenia]<>'1900-01-01'

		--dodanie atrybutu "FormaPrawna"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,188,FormaPrawna from #MergeLog

		--dodanie atrybutu "Nazwa podmiotu"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,189,[Nazwa podmiotu] from #MergeLog

		--dodanie atrybutu "FormaWlasnosci"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,190,FormaWlasnosci from #MergeLog

		--dodanie atrybutu "Adres"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,191,Adres from #MergeLog

		--dodanie atrybutu "Nazwa wydzialu"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,192,[Nazwa wydzialu] from #MergeLog

		--dodanie atrybutu "Sygnatura upadlosciowa"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,193,[Sygnatura upadlosciowa] from #MergeLog

		--dodanie atrybutu "Sedzia komisarz"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,194,[Sedzia komisarz] from #MergeLog

		--dodanie atrybutu "Zastepca sedziego komisarza"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,195,[Zastepca sedziego komisarza] from #MergeLog

		--dodanie atrybutu "Nadzorca w postepowaniu"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,196,[Nadzorca w postepowaniu] from #MergeLog

		--dodanie atrybutu "Funkcja nadzorcy"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,197,[Funkcja nadzorcy] from #MergeLog

		--dodanie atrybutu "Data wydania postanowienia"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,198,[Data wydania postanowienia] from #MergeLog where [Data wydania postanowienia]<>'1900-01-01'

		--dodanie atrybutu "Okres do dzialania (w dniach)"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,199,[Okres do dzialania (w dniach)] from #MergeLog

		--dodanie atrybutu "Koniec okresu do dzialania"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,200,[Koniec okresu do dzialania] from #MergeLog

		--dodanie atrybutu "Rozdzial iMSiG"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,201,case when [Rozdzial iMSiG]=0 then 'Ogłoszenie wymagane przez prawo upadłościowe' when [Rozdzial iMSiG]=1 then 'Ogłoszenie wymagane przez prawo restrukturyzacyjne' end from #MergeLog

		--dodanie atrybutu "Sygnatura ogloszenia"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,203,[Sygnatura ogloszenia] from #MergeLog

		--dodanie atrybutu "Data publikacji ogloszenia w iMSig"
		insert into dm_data_bps.dbo.atrybut_akcji
		(atak_ak_id,atak_atakt_id,atak_wartosc)
		select ak_id,204,[Data publikacji ogloszenia w iMSig] from #MergeLog

		--dodanie alertu
--====================================================================================================================--
		if OBJECT_ID('temp..#AMergeLog') is not null drop table #AMergeLog

		create table #AMergeLog (
		ak_id int,
		[Sekcja MSiG] int,
		[Koniec okresu do działania] date
		)

		merge dm_data_bps.dbo.akcja as target using (
		select sp_id,[Sekcja MSiG],[Koniec okresu do działania] from #iMSiG
		) as source on 1=0
		when not matched then insert
		([ak_akt_id], [ak_sp_id], [ak_kolejnosc], [ak_interwal], [ak_pr_id], [ak_publiczna])
		values (27,sp_id,0,0,-1,1)
		output inserted.ak_id,source.[Sekcja MSiG],source.[Koniec okresu do działania] into #AMergeLog;

		insert into dm_data_bps.dbo.rezultat
		([re_ak_id],re_ret_id,[re_data_planowana], [re_us_id_planujacy], [re_data_wykonania], [re_us_id_wykonujacy], [re_konczy], [re_komentarz])
		select ak_id,2,case when DATEADD(dd,-5,ISNULL([Koniec okresu do działania],'1900-01-01'))<CAST(getdate() as date) then GETDATE() else DATEADD(dd,-5,[Koniec okresu do działania]) end,5,GETDATE(),5,1,'iMSiG - '+case when [Sekcja MSiG]=1 then 'POSTANOWIENIE O OGŁOSZENIU UPADŁOŚCI' when [Sekcja MSiG]=2 then 'OBWIESZCZENIE O ZATWIERDZENIU UKŁADU' when [Sekcja MSiG]=3 then 'OGŁOSZENIE O SPORZĄDZENIU I PRZEKAZANIU SĘDZIEMU KOMISARZOWI LISTY WIERZYTELNOŚCI' when [Sekcja MSiG]=4 then 'OGŁOSZENIE O MOŻLIWOŚCI PRZEGLĄDANIA PLANU PODZIAŁU' when [Sekcja MSiG]=5 then 'POSTANOWIENIE O UMORZENIU POSTĘPOWANIA UPADŁOŚCIOWEGO' when [Sekcja MSiG]=6 then 'POSTANOWIENIE O ZAKOŃCZENIU POSTĘPOWANIA UPADŁOŚCIOWEGO - ZWERYFIKUJ CZY DYSPONUJEMY WYCIĄGIEM Z PRAWOMOCNEJ LISTY WIERZYTELNOŚCI' when [Sekcja MSiG]=7 then 'OGŁOSZENIE O ZŁOŻENIU OŚWIADCZENIA O WSZCZĘCIU POSTĘPOWANIA NAPRAWCZEGO' when [Sekcja MSiG]=8 then 'OGŁOSZENIE O TERMINIE ROZPRAWY ZATWIERDZAJĄCEJ UKŁAD' when ([Sekcja MSiG]=9 or isnull([Sekcja MSiG],'')='') then 'INNE OBWIESZCZENIE' end collate Polish_CS_AS  
		 from #AMergeLog

		--wysyłka maila do windykatorów
--====================================================================================================================--
		if OBJECT_ID('tempdb..#mail') is not null drop table #mail

		select 
		ROW_NUMBER() over (order by sp_id) as RN
		,sp_id
		,[Nr sprawy]
		,sp_pr_id
		,[Nazwa podmiotu]
		,[Sekcja MSiG]
		,[Koniec okresu do działania] 
		into #mail 
		from #iMSiG

		declare @licz int=1
		declare @max int=(select COUNT(1) from #mail)
		declare @tresc varchar(max)
		declare @temat varchar(max)
		declare @adresat varchar(max)
		declare @dw_adresat varchar(max)

		while @licz<=@max

				begin

						set @adresat = (
						select top 1 case when sp_pr_id in (204,207) or (uko_ko_id<>149 and ak_akt_id=990) then 'wioleta.okraglinska@cfsa.pl' else 
						isnull(us_email,'aneta.bielinska@cfsa.pl;martyna.ksepka@cfsa.pl;adam.gryziak@cfsa.pl') end 					
						from #mail 
						join dm_data_bps.dbo.wierzytelnosc_rola on wir_sp_id=sp_id 
						join dm_data_bps.dbo.wierzytelnosc on wir_wi_id=wi_id 
						join dm_data_bps.dbo.dokument on do_wi_id=wi_id 
						join dm_data_bps.dbo.umowa_kontrahent on do_uko_id=uko_id
						join dm_data_bps.dbo.GE_USER on sp_pr_id=US_ID 
						left join dm_data_bps.dbo.akcja on ak_sp_id=sp_id and ak_akt_id in (990,934) 	
						where RN=@licz
						)--na prośbę Wioli zmieniam aby wszystkie maile w sprawach jej zespołu trafiały do niej, 2020-02-19 [AD]

						set @dw_adresat = (
						select top 1 case when uko_ko_id = 149 and sp_pr_id in (233,220) then 'martyna.ksepka@cfsa.pl'
						/*when uko_ko_id<>149 and ak_akt_id=990 then 'aneta.bielinska@cfsa.pl'*/
						when uko_ko_id = 149 and sp_pr_id in (217,215,219,246) then 'joanna.klapec@cfsa.pl' --dodaję warunek na Zespół Asi 2020-10-08 [AD]
						when uko_ko_id<>149 and ak_akt_id=934 then 'adam.gryziak@cfsa.pl' end 										
						from #mail 
						join dm_data_bps.dbo.wierzytelnosc_rola on wir_sp_id=sp_id 
						join dm_data_bps.dbo.wierzytelnosc on wir_wi_id=wi_id 
						join dm_data_bps.dbo.dokument on do_wi_id=wi_id 
						join dm_data_bps.dbo.umowa_kontrahent on do_uko_id=uko_id
						left join dm_data_bps.dbo.akcja on ak_sp_id=sp_id and ak_akt_id in (990,934) 
						where RN=@licz
						) --na prośbę Anety, wykluczam ją z DW 2019-12-19, AD

						set @temat = (
						select 'W Twojej sprawie '+[Nr sprawy]+' dodano dane z Internetowego Monitora Sądowego i Gospodarczego' 			
						from #mail 
						where RN=@licz
						)
		
						set @tresc = (
						select 'W Twojej sprawie '+[Nr sprawy]+ case when [Sekcja MSiG] = 1 then ' wydano postanowienie o ogłoszeniu upadłości' when [Sekcja MSiG]=2 then ' wydano obwieszczenie o zatwierdzeniu układu' when [Sekcja MSiG]=3 then ' wydano ogłoszenie o sporządzeniu i przekazaniu sędziemu komisarzowi listy wierzytelności' when [Sekcja MSiG]=4 then ' wydano ogłoszenie o możliwości przeglądania planu podziału' when [Sekcja MSiG]=5 then ' wydano postanowienie o umorzeniu postępowania upadłościowego' when [Sekcja MSiG]=6 then ' wydano postanowienie o zakończeniu postępowania upadłościowego, zweryfikuj czy dysponujemy wyciągiem z prawomocnej listy wierzytelności' when [Sekcja MSiG]=7 then ' wydano ogłoszenie o złożeniu oświadczenia o wszczęciu postępowanie naprawczego' when [Sekcja MSiG]=8 then ' wydano ogłoszenie o terminie rozprawy zatwierdzającej układ' when ([Sekcja MSiG]=9 or [Sekcja MSiG]='') then ' wydano ogłoszenie dotyczące Twojego dłużnika' else ' wydano ogłoszenie dotyczące Twojego dłużnika' end collate Polish_CS_AS +', dotyczy: '+(select [Nazwa podmiotu] from #mail where RN=@licz)+case when [Koniec okresu do działania]='1900-01-01' then '' else + ', koniec okresu do działania: '+cast([Koniec okresu do działania] as varchar) end  
						from #mail 
						where RN=@licz
						)

						EXEC msdb.dbo.sp_send_dbmail
						@profile_name = 'SQLProfile',
						@recipients = @adresat,
						@copy_recipients = @dw_adresat,
						@body = @tresc,
						@subject = @temat,
						@importance = 'High'

						set @licz=@licz+1
				end
end

