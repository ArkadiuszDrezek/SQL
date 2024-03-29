USE [CFBPS_Raporty_kontrolne]
GO
/****** Object:  StoredProcedure [dbo].[P_PAKIETY_URAWNIENIA]    Script Date: 2023-03-21 13:27:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure 
[dbo].[P_PAKIETY_URAWNIENIA]

as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

set ansi_warnings on
set nocount on
BEGIN

------ Uprawnienia do umów

--Zmiana 2023-03-23

Merge dm_data_bps.dbo.GE_UKOPERMISSION as target
using(

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'INNE' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc between 800 and 834
		) t
		where us_blocked=0 and GrupaSprawZlec=1

		UNION ALL

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'INNE2' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc =835
		) t
		where us_blocked=0 and GrupaSprawZlec2=1

		UNION ALL

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, v.uko_id, atw_wartosc, 'BANK' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.umowa_kontrahent u on u.uko_id=v.uko_id
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and u.uko_id in (229,236,237)
		) t
		where us_blocked=0 and GrupaSprawBank=1

		UNION ALL

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, v.uko_id, atw_wartosc, 'MONITORING' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.umowa_kontrahent u on u.uko_id=v.uko_id
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and u.uko_id = 113
		) t
		where us_blocked=0 and GrupaSprawMonitoring=1

		Union all

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'FUNDUSZ' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc between 1000 and 3999
		) t
		where us_blocked=0 and GrupaSprawFundusz=1

		Union all

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'FUNDUSZ2' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc between 4000 and 4999
		) t
		where us_blocked=0 and GrupaSprawFundusz2=1

		Union all

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'FUNDUSZ3' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc between 5000 and 5999
		) t
		where us_blocked=0 and GrupaSprawFundusz3=1

		Union all

		select distinct us_login, uko_id
		from dm_logic_bps.dbo.ge_user
		left join [CFBPS_Raporty_kontrolne].[dbo].[Upowaznieni_do_pdos] upo on upo.[login w DM]=us_login
		cross apply (
		select sp_numer, uko_id, atw_wartosc, 'WŁASNE' as grupa from dm_logic_bps.dbo.v_sprawa_info v
		join dm_logic_bps.dbo.sprawa s on s.sp_id=v.sp_id
		join dm_logic_bps.dbo.atrybut_sprawa on atsp_sp_id=s.sp_id
		join dm_logic_bps.dbo.atrybut_wartosc on atw_id=atsp_atw_id
		where typ='Handlowa' and atw_att_id=1
		and atw_wartosc<1000 and atw_wartosc not between 800 and 900 and uko_id not in (113,229,236,237)
		) t
		where us_blocked=0 and GrupaSprawwłasne=1

) W
on target.[UKOP_USER]=W.us_login collate Polish_CI_AI
and target.[UKOP_UKO]=w.uko_id --collate Polish_CI_AI
when not matched by target then 
insert ([UKOP_USER],[UKOP_UKO])
values (W.us_login,w.uko_id)
when not matched by source then delete
;
--- tabela wjątków - sprawa zamknięte i kupione przez nas - mają zapisane w nowej sprawie (atrybut0 numer starej

delete from [dm_data_bps].[dbo].[GE_SPRPERMISSION]
insert into [dm_data_bps].[dbo].[GE_SPRPERMISSION] ( 
       [sprp_user]
      ,[sprp_sp_numer]
      ,[sprp_sp_id]
      ,[sprp_sp_numer_s]
      ,[sprp_sp_id_s]
)
select us_login,s.sp_numer,s.sp_id,atw_wartosc,s1.sp_id  
from [dm_data_bps].[dbo].sprawa s
join [dm_data_bps].[dbo].atrybut_sprawa aa on s.sp_id=aa.atsp_sp_id
join [dm_data_bps].[dbo].atrybut_wartosc aw on aw.atw_id=aa.atsp_atw_id and atw_att_id=17
join [dm_data_bps].[dbo].sprawa s1 on s1.sp_numer=atw_wartosc collate Polish_CI_AI
join [dm_data_bps].[dbo].GE_USER on US_ID=s.sp_pr_id

/*
MERGE [dm_data_bps].[dbo].[GE_SPRPERMISSION] AS ak
	USING ( select us_login,s.sp_numer,s.sp_id,atw_wartosc,s1.sp_id as sp_id2 
              from [dm_data_bps].[dbo].sprawa s
              join [dm_data_bps].[dbo].atrybut_sprawa aa on s.sp_id=aa.atsp_sp_id
              join [dm_data_bps].[dbo].atrybut_wartosc aw on aw.atw_id=aa.atsp_atw_id and atw_att_id=17
              join [dm_data_bps].[dbo].sprawa s1 on s1.sp_numer=atw_wartosc collate Polish_CI_AI
              join [dm_data_bps].[dbo].GE_USER on US_ID=s.sp_pr_id
			) AS mig_ak
	ON (mig_ak.us_login = ak.sprp_user collate Polish_CI_AI
	    and mig_ak.sp_numer = ak.sprp_sp_numer collate Polish_CI_AI
	    and mig_ak.sp_id = ak.sprp_sp_id 
	    and mig_ak.atw_wartosc = ak.sprp_sp_numer_s collate Polish_CI_AI
		and mig_ak.sp_id = ak. sprp_sp_id_s 
		)
	WHEN NOT MATCHED THEN   
		INSERT (sprp_user, sprp_sp_numer,sprp_sp_id,sprp_sp_numer_s,sprp_sp_id_s, aud_data,aud_login)   
		VALUES (
			mig_ak.us_login, 
			mig_ak.sp_numer,
			mig_ak.sp_id,
			mig_ak.atw_wartosc,  
			mig_ak.sp_id,
			getdate(),
			'GRUPABPS\marek.wlodek'  
			)                      
; */
-----------------------------------------------------------[PN] 23.10.2019 - Uprawnienia indywidualne dla Michala Francuza
DELETE dm_logic_bps..GE_UKOPERMISSION WHERE UKOP_USER = 'mfrancuz'
INSERT INTO dm_logic_bps..GE_UKOPERMISSION
SELECT
	'mfrancuz',
	uko.uko_id,
	GETDATE(),
	suser_name()
FROM dm_logic_bps..sprawa s
join dm_logic_bps..cache_sprawa_info csi on csi.sp_id = s.sp_id
join dm_logic_bps..umowa_kontrahent uko on uko.uko_id = csi.uko_id
join dm_logic_bps..kontrahent ko on ko.ko_id = uko.uko_ko_id
join dm_logic_bps..atrybut_sprawa ats on ats.atsp_sp_id = s.sp_id
join dm_logic_bps..atrybut_wartosc atw on atsp_atw_id = atw_id
--join dm_logic_bps..GE_UKOPERMISSION on ukop_uko = uko.uko_id
WHERE atw_att_id = 1
--and UKOP_USER = 'mfrancuz'
AND atw_wartosc in ( 1050, 4001, 4002, 4003, 4004, 4005, 4006, 4007, 4008, 4009, 4010, 4011, 4012, 4013, 4014)
-----------------------------------------------------------

-----------------------------------------------------------[AD] 2020-04-07 - Uprawnienia indywidualne dla Lucyny Jędrzejczyk
DELETE dm_logic_bps..GE_UKOPERMISSION WHERE UKOP_USER = 'ljedrzejczyk'
INSERT INTO dm_logic_bps..GE_UKOPERMISSION (UKOP_USER,UKOP_UKO)
SELECT
	'ljedrzejczyk',
	uko_id

from dm_data_bps..umowa_kontrahent
-----------------------------------------------------------
--=========================================================
--dostęp tymczasowy dostęp do pakietów funduszowych (na przykładzie Asi Kłapeć) dla Anety i Wioli. 2021-08-05 [AD]
--=========================================================
drop table if exists #uprawnienia
select 
UKOP_UKO 
into #uprawnienia 
from dm_logic_bps..GE_UKOPERMISSION
where UKOP_USER='jklapec'

insert into dm_logic_bps..GE_UKOPERMISSION
(UKOP_USER,UKOP_UKO)
select 'abielinska',upr1.ukop_uko from #uprawnienia upr1
where not exists (select 1 from dm_data_bps..GE_UKOPERMISSION upr2 where upr1.UKOP_UKO=upr2.UKOP_UKO and upr2.UKOP_USER='abielinska')
union
select 'wokraglinska',ukop_uko from #uprawnienia upr1
where not exists (select 1 from dm_data_bps..GE_UKOPERMISSION upr2 where upr1.UKOP_UKO=upr2.UKOP_UKO and upr2.UKOP_USER='wokraglinska')

drop table if exists #sprzedane_BEST
select 
distinct do_uko_id into #sprzedane_BEST
from dm_data_bps..akcja
join dm_data_bps..rezultat on re_ak_id=ak_id and ak_akt_id=47 and re_ret_id=406
join dm_data_bps..wierzytelnosc_rola on wir_sp_id=ak_sp_id
join dm_data_bps..wierzytelnosc on wir_wi_id=wi_id
join dm_data_bps..dokument on do_wi_id=wi_id

insert into dm_data_bps.dbo.GE_UKOPERMISSION
(UKOP_USER, UKOP_UKO)
select 'lpolrolnik', do_uko_id from #sprzedane_BEST

END




 
