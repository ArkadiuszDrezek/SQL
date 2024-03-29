USE [dm_logic_bps]
GO
/****** Object:  StoredProcedure [dbo].[pobierzSprawe]    Script Date: 2023-03-21 12:52:10 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[pobierzSprawe]
(
	@p_sprawa_id int
)
------------------------------------------------------------------------------------------------------------
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
declare @ko_nazwa varchar(1000)=('Wierzyciel: '+(select ko_firma from kontrahent join umowa_kontrahent k on uko_ko_id=ko_id join v_sprawa_info v on v.uko_id=k.uko_id and sp_id=@p_sprawa_id))
declare @uko int = (select uko_id from v_sprawa_info where sp_id=@p_sprawa_id)
declare @kontakt varchar(1000) = 'Nie można otworzyć sprawy z powodu braku uprawnień. '+char(10)+isnull(@ko_nazwa,'')+' '+char(10)
set @kontakt = @kontakt+ isnull('Sprawę obsługuje: '+(select upper(Us_name)+' '+upper(Us_Surname) +char(10)+isnull('Telefon: '+Us_Phone,'') collate polish_ci_as from ge_user join sprawa on sp_pr_id=us_id where sp_id=@p_sprawa_id),'')
------------------------------------------------------------------------------------------------------------
if (
	not exists (select top 1 ukop_user from GE_UKOPERMISSION where SUSER_NAME()=ukop_user and @uko=ukop_uko) 
	and SUSER_NAME() <> 'admin' 
	and suser_name() <> 'pnowinowski'
	and suser_name() <> 'kczajka'
--	and suser_name() <> 'pbagnicki'
--	and suser_name() <> 'jcieminska'
	and suser_name() <> 'bborowiecka'
	and suser_name() <> 'adrezek'
	and suser_name() <> 'mrzadkowski'
	and suser_name() <> 'kkazimierska'
	and @uko is not null
	and not exists (select top 1 '1' from sprawa join operator on op_sp_id=sp_id join ge_user on us_id=op_us_id where isnull(op_data_do,'2100-01-01')>getdate() and op_opt_id=3 and sp_id=@p_sprawa_id and SUSER_NAME()=US_LOGIN) 
	and (select sp_pr_id from sprawa where sp_id=@p_sprawa_id) not in (select us_id from ge_user where us_login=suser_name() and us_id in (38,18) )
	and (select replace(sp_pr_id,'38','18') from sprawa where sp_id=@p_sprawa_id) not in (select replace(us_id,'38','18') from ge_user where us_login=suser_name() and us_id in (38,18))
	) 
	or
	((@p_sprawa_id = 179996) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek') and us_login = suser_name()) ) or				--14.02.2019 [PN] #RM1880
	((@p_sprawa_id = 180297) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','ebartosiak', 'agryziak') and us_login = suser_name())) or --27.06.2019 [PN]
	((@p_sprawa_id = 180298) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','abielinska','wokraglinska') and us_login = suser_name())) or	--14.02.2019 [PN]--16.03.2020 [mw]
	((@p_sprawa_id = 180299) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','abielinska') and us_login = suser_name())) or	--14.02.2019 [PN]
	((@p_sprawa_id = 180300) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','mzapadka','mwierzbicka') and us_login = suser_name())) or	--03.07.2019 [PN] - na zlecenie Martyny Zapadki,08.10.2020 [AD] dodaję Marię Wierzbicką Zadanie #7022 RM
	((@p_sprawa_id = 180301) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','mtarlaga') and us_login = suser_name())) or	--14.02.2019 [PN]
	((@p_sprawa_id = 180302) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek','rpiekarski') and us_login = suser_name())) or	--14.02.2019 [PN]
	((@p_sprawa_id = 180303) and not exists (select top 1 1 from ge_user where us_login in ('bborowiecka','pszynalski','pnowinowski','adrezek','mwlodek') and us_login = suser_name()))					--14.02.2019 [PN]

begin
	insert into sprawa_blokada_archiwum 
	select (select max(spb_id) from sprawa_blokada_archiwum)+ ROW_NUMBER() over(order by (select 0)), @p_sprawa_id, isnull((select us_id from ge_user where us_login=SUSER_NAME()),-1),getdate(),NULL,1

	INSERT INTO [zdarzenie]
			   ([z_zt_id]
			   ,[z_us_id]
			   ,[z_user_name]
			   ,[z_data]
			   ,[z_adres_ip]
			   ,[z_stacja_robocza])
           
	select 3, isnull((select us_id from ge_user where us_login=SUSER_NAME()),5),
	isnull((select us_name from ge_user where us_login=SUSER_NAME()),-1), GETDATE(),
	cast(CONNECTIONPROPERTY('client_net_address') as varchar),''   
	if not exists (select top 1 sprp_sp_id_s from [dm_data_bps].[dbo].[GE_sprpermission] where sprp_sp_id_s=@p_sprawa_id)  /*MW dopuszczenie do spraw sprzedanych*/
	  begin        
	     raiserror(@kontakt ,16,10)
	  end
end
------------------------------------------------------------------------------------------------------------
begin
	INSERT INTO [dbo].[zdarzenie]
			   ([z_zt_id]
			   ,[z_us_id]
			   ,[z_user_name]
			   ,[z_data]
			   ,[z_adres_ip]
			   ,[z_stacja_robocza])
           
	select 2, isnull((select us_id from ge_user where us_login=SUSER_NAME()),5),
	isnull((select us_name from ge_user where us_login=SUSER_NAME()),-1), GETDATE(),

	cast(CONNECTIONPROPERTY('client_net_address') as varchar),''    

	select sprawa_etap_typ.*,vsp.*, s.sp_numer collate Polish_CI_AI +' '+isnull(dl_imie,'')+' '+isnull(dl_nazwisko,'')+' '+isnull(dl_firma,'') collate Polish_CI_AI as nazwa_sprawy  from [v_sprawa_info] vsp
	left join sprawa s ON s.sp_id = vsp.sp_id
	left join v_sprawa_rola ON spr_sp_id = s.sp_id
	left join dluznik ON dl_id = spr_dl_id
	left join sprawa_etap_typ on spet_id=etap_id
	where vsp.sp_id  = @p_sprawa_id

end
------------------------------------------------------------------------------------------------------------
