cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis 
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS 
cdis 
cdis    This software and its documentation are in the public domain and 
cdis    are furnished "as is."  The United States government, its 
cdis    instrumentalities, officers, employees, and agents make no 
cdis    warranty, express or implied, as to the usefulness of the software 
cdis    and documentation for any purpose.  They assume no responsibility 
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis    
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making 
cdis    the modifications.  If significant modifications or enhancements 
cdis    are made to this software, the FSL Software Policy Manager  
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
c
c
	program laps_sfc
c
	include 'lapsparms.cmn'
	character laps_domain*9
c
	laps_domain = 'nest7grid'
	call get_laps_config(laps_domain,istatus)
	if(istatus .ne. 1) then
	   write(6,*) 'LAPS_SFC: ERROR getting domain dimensions'
	   stop
	endif
c
	call laps_sfc_sub(nx_l_cmn,ny_l_cmn,nk_laps,maxstns_cmn,
     &                    laps_cycle_time_cmn,grid_spacing_m_cmn,
     &                    laps_domain)
c
	end
c
c
	subroutine laps_sfc_sub(ni,nj,nk,mxstn,laps_cycle_time,
     &                          grid_spacing,laps_domain)
c
c
c*****************************************************************************
c
c	Driver program for the LAPS variational surface analysis.  This 
c	program gets the correct time and passes it to the routines (former
c	programs) that get the mesonet, SAO, and VAS data; grid and quality
c	control it; and perform the variational analysis.
c
c
c	History:
c		P. Stamus	03-09-90  Original version.
c				03-22-90  Check for BATCH or INTERACTIVE.
c				03-29-90  Added check for old VAS data.
c				04-06-90  Pass del,gam,ak to mdat for hdr.
c				04-11-90  Pass lat/lon & topo to routines
c				12-10-90  Change to RT_DEV for lat/lon, topo.
c				11-08-91  Changes for new grids.
c				10-15-92  Add Steve's get_laps_config call.
c				01-06-93  New version...new lso and lvd stuff.
c				04-19-93  Common for fnorm (Barnes routine)
c				08-05-93  Replace fnorm with fnorm2. 
c                               12-08-93  Change to format in 'systime.dat'.
c                               03-04-94  Change static file read (read to rd)
c                               07-20-94  Add include file.
c                               02-03-95  Background reads here...then pass.
c                               07-20-95  Bag fnorm2 for new Barnes wt method.
c                               08-08-95  Add code for verify routine.
c                               03-22-96  Fixes for 30 min cycle.
c                               04-10-96  More 30 min...bkgwts file.
c                               11-07-96  Use 3d sfc wind for bkg, adj wts.
c                               12-13-96  More porting changes...common for
c                                         sfc data, LGS grids. Bag stations.in
c                               03-26-97  Add ability to do interactive runs.
c                                         (Removes need for 'laps_sfci')
c                                         Remove equivs.
c                               09-11-97  Changes for dynamic LAPS.
c                               01-20-98  Move wt calcs to correct place.
c	                        07-11-98  New background calls.  Still temp fix
c                                           until can remove weight code (new 
c                                           spline doesn't use).
c                               09-24-98  Carry background flags for each var.
c                                           Rm ceil QC check.
c                               09-30-98  Housekeeping.
c                               12-02-98  Remove status check for LT1.
c                               07-07-99  General upgrades and cleanup.  Change
c                                           read_surface_obs to read_surface_data.
c                                           Rm *4 from all declarations.
c                               09-19-99  Check T/Td bkgs until LGB can do it.
c
c
c       Notes:
c
c       1. Running 'laps_sfc.x' makes the analysis use the time from 
c          '../sched/systime.dat'.  Running 'laps_sfc.x -i' allows the
c          user to enter the desired start time.
c
c       2. The background weights for the station pressure (wt_stnp) are
c          not currently used.  They are included because they might be in
c          the future.
c
c*****************************************************************************
c
	include 'laps_sfc.inc'
c
	real lat(ni,nj), lon(ni,nj), topo(ni,nj)
	real x1a(ni), x2a(nj), y2a(ni,nj)
	real grid_spacing
c
	integer*4 i4time
	integer jstatus(20)		! 20 is standard for prodgen drivers
	integer narg, iargc
c
	character atime*24, filename*9, filename_last*9
	character infile_last*256
	character dir_s*256,ext_s*31,units*10,comment*125,var_s*3
	character laps_domain*9
c
c.....  Stuff for backgrounds.
c
	real u_bk(ni,nj), v_bk(ni,nj), t_bk(ni,nj), td_bk(ni,nj)
	real wt_u(ni,nj), wt_v(ni,nj), wt_t(ni,nj), wt_td(ni,nj)
	real rp_bk(ni,nj), mslp_bk(ni,nj), stnp_bk(ni,nj)
	real wt_rp(ni,nj), wt_mslp(ni,nj), wt_stnp(ni,nj)
	real vis_bk(ni,nj), wt_vis(ni,nj)
	real wt(ni,nj)
c
	integer back_t, back_td, back_rp, back_uv, back_vis, back_sp
	integer back_mp
	character var_req*4, ext_bk*31, back*9
c
c..... Stuff for the sfc data and other station info (LSO +)
c
	real lat_s(mxstn), lon_s(mxstn), elev_s(mxstn)
	real t_s(mxstn), t_ea(mxstn), max24t(mxstn), min24t(mxstn)
        real td_s(mxstn), td_ea(mxstn), rh(mxstn), rh_ea(mxstn)

        real dd_s(mxstn), ddg_s(mxstn), dd_ea(mxstn)
        real ff_s(mxstn), ffg_s(mxstn), ff_ea(mxstn)

        real alt_s(mxstn), alt_ea(mxstn), delp(mxstn)
	real pstn_s(mxstn), pmsl_s(mxstn), p_ea(mxstn)

	real store_hgt(mxstn,5) 

        real vis_s(mxstn), vis_ea(mxstn)
        real solar_s(mxstn), solar_ea(mxstn)

        real sfct(mxstn), sfct_ea(mxstn)
        real sfcm(mxstn), sfcm_ea(mxstn)
        real pcp1(mxstn), pcp3(mxstn), pcp6(mxstn), pcp24(mxstn)
        real snow(mxstn), snow_ea(mxstn), pcp_ea(mxstn)

	real rii(mxstn), rjj(mxstn)
c
	integer kloud_s(mxstn), obstime(mxstn)
        integer wmoid(mxstn), delpch(mxstn)
	integer ii(mxstn), jj(mxstn)
c
	character atime_s*24
	character store_amt(mxstn,5)*4
        character stations(mxstn)*20, provider(mxstn)*11
        character reptype(mxstn)*6, autostntype(mxstn)*6
        character wx_s(mxstn)*25 
c
c.....  Work arrays for the QC routine.
c
        integer rely(26,mxstn), ivals1(mxstn)
	character stn3(mxstn)*3
c
c.....  Stuff for intermediate grids (old LGS file)
c
	real u1(ni,nj), v1(ni,nj)
	real t1(ni,nj), td1(ni,nj), tb81(ni,nj)
	real rp1(ni,nj), sp1(ni,nj), mslp1(ni,nj)
	real vis1(ni,nj), elev1(ni,nj)
c
c
c*************************************************************
c.....	Start here.  First see if this is an interactive run.
c*************************************************************
c
	narg = iargc()
cc	print *,' narg = ', narg
c
c.....  Now get the analysis time from the scheduler or the user.
c
	if(narg .eq. 0) then
c
	   ihours = 1	! default # of hrs back for time-tendencies
c
	   call get_systime(i4time,filename,istatus)
c
	else
c
 970	   write(6,973)
 973	   format(' Enter input filename (yydddhhmm): ',$)
	   read(5,972) filename
 972	   format(a)
c
 974	   write(6,975)
 975	   format(
     &    ' Hours to go back for time-tendencies (1..6)[1]: ',$)
	   read(5,976) ihours
 976	   format(i1)
	   if(ihours .eq. 0) then
	      print *, ' Will skip backgrounds.'
	   elseif(ihours.lt.1 .or. ihours.gt.6) then
	      print *, ' ERROR: Hrs out of bounds.  Try again.'
	      go to 974
	   endif
	   call i4time_fname_lp(filename,i4time,status)
c
	endif
c
c
500	dt = ihours * laps_cycle_time    ! multiples of time to get bkgs.
	i4time_last = i4time - ifix( dt )
	call cv_i4tim_asc_lp(i4time, atime, status)	   ! get the atime
	call make_fnam_lp(i4time_last,filename_last,istatus)  ! make earlier filename	
c
        del = 1.e6
	gam = .0008
	ak = 1.e-6
c
c.....	Get the LAPS lat/lon and topo data here so we can pass them to the 
c.....	routines that need them.
c
cc	dir_s = '../static/' 
	call get_directory('static', dir_s, len)
	ext_s = laps_domain
	var_s = 'LAT'
        call rd_laps_static(dir_s,ext_s,ni,nj,1,var_s,units,comment,
     &                      lat ,grid_spacing,istatus)
	var_s = 'LON'
        call rd_laps_static(dir_s,ext_s,ni,nj,1,var_s,units,comment,
     &                      lon ,grid_spacing,istatus)
	var_s = 'AVG'
        call rd_laps_static(dir_s,ext_s,ni,nj,1,var_s,units,comment,
     &                      topo ,grid_spacing,istatus)
c
c.....  Read in the obs and calculate a weight based on distance to each
c.....  station.
c
c.....	READ IN THE SURFACE OBS:  dd/ff in deg/kt, t and td in F, elev in m,
c.....	                          and the pressure variable. cld hts are msl.
c
c 	infile1 = '../lapsprd/lso/'//filename//'.lso' 
cc	call get_directory('lso',infile1,len)
cc	infile1 = infile1(1:len) // filename(1:9) // '.lso'
c
	write(6,305) filename(1:9)
 305	format(' Getting surface data at: ',a9)
c
        call read_surface_data(i4time,atime_s,n_obs_g,n_obs_b,obstime,
     &    wmoid,stations,provider,wx_s,reptype,autostntype,lat_s,lon_s,
     &    elev_s,t_s,td_s,rh,dd_s,ff_s,ddg_s,ffg_s,alt_s,pstn_s,pmsl_s,
     &    delpch,delp,vis_s,solar_s,sfct,sfcm,pcp1,pcp3,pcp6,pcp24,snow,
     &    kloud_s,max24t,min24t,t_ea,td_ea,rh_ea,dd_ea,ff_ea,alt_ea,
     &    p_ea,vis_ea,solar_ea,sfct_ea,sfcm_ea,pcp_ea,snow_ea,store_amt,
     &    store_hgt,mxstn,istatus)
c
	if(istatus.ne.1 .or. n_obs_b.eq.0) then	  !surface obs not available
	  jstatus(1) = 0
	  stop 'No sfc obs from LSO'
	endif
c
	print *,' '
	write(6,320) atime_s,n_obs_g,n_obs_b
320	format(' LSO data vaild time: ',a24,' Num obs: ',2i6)
c
	if(n_obs_b .lt. 1) then
	   jstatus(1) = -2
	   print *,' Insufficient number of surface observations'
	   print *,' for a clean analysis.  Stopping.'
	   stop 
	endif
	print *,' '
c
c.....  Copy 3 characters of the station name to another array for use
c.....  in the qc_data routine.  This can be removed once the QC is changed
c.....  to the stand-alone Kalman.  Blank out the array first.
c
	do i=1,mxstn
	   stn3(i)(1:3) = '   '
	enddo !i
c
	do i=1,n_obs_b
	   stn3(i)(1:3) = stations(i)(2:4)
	enddo !i
c
c.....	Find the i,j location of each station, then calculate the
c.....  background weights (based on station density).
c
	call find_ij(lat_s,lon_s,lat,lon,n_obs_b,mxstn,
     &               ni,nj,ii,jj,rii,rjj)
c
        do ista=1,n_obs_b
           write(6,999) ista,stations(ista)(1:5), reptype(ista)(1:6), 
     &                  autostntype(ista)(1:6), rii(ista), rjj(ista)
        enddo !ista
 999    format(i4,': ',a5,2x,a6,2x,a6,' is at i,j: ',f5.1,',',f5.1)
c
        call zero(wt, ni,nj)
	call bkgwts(lat,lon,topo,n_obs_b,lat_s,lon_s,elev_s,
     &              rii,rjj,wt,ni,nj,mxstn)
c
c.....  Zero the weights then get the background data.  Try for a RAMS 
c.....  forecast first, then the surface winds from the 3d analysis, then
c.....  a previous LAPS analysis.  If RAMS or the 3d wind are missing just 
c.....  use LAPS.  If both LAPS and RAMS are missing, print a warning.
c
        call zero(wt_u, ni,nj)
        call zero(wt_v, ni,nj)
        call zero(wt_t, ni,nj)
        call zero(wt_td, ni,nj)
        call zero(wt_rp, ni,nj)
        call zero(wt_mslp, ni,nj)
        call zero(wt_stnp, ni,nj)
        call zero(wt_vis, ni,nj)
c
	back_t = 0
	back_td = 0
	back_rp = 0
	back_sp = 0
	back_mp = 0
	back_uv = 0
	back_vis = 0
c
	if(ihours .eq. 0) then     ! skip the backgrounds
	   ilaps_bk = 0
	   print *,' Skipping backgrounds...'
	   go to 600
	endif
c
c.....  Get the backgrounds.  Convert units while we're here.
c
	call get_bkgwind_sfc(i4time,ext_bk,ibkg_time,u_bk,v_bk,
     &            laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call move(wt, wt_u, ni,nj)
	   call move(wt, wt_v, ni,nj)
	   call conv_ms2kt(u_bk,u_bk,ni,nj)
	   call conv_ms2kt(v_bk,v_bk,ni,nj)
	   back_uv = 1
	else
	   print *,'     No background available'
	   call zero(u_bk,ni,nj)
	   call zero(v_bk,ni,nj)
	endif
c
	print *,' '
	print *,' Getting temperature background....'
	var_req = 'TEMP'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,t_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   ilaps_bk = 1
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call conv_k2f(t_bk,t_bk,ni,nj) ! conv K to deg F
	   call move(wt, wt_t, ni,nj)
	   back_t = 1
	else
	   print *,'     No background available'
	   call zero(t_bk,ni,nj)
	endif
c
	print *,' '
	print *,' Getting MSL pressure background....'
	var_req = 'MSLP'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,mslp_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call multcon(mslp_bk,0.01,ni,nj) ! conv Pa to mb
	   call move(wt, wt_mslp, ni,nj)
	   back_mp = 1
	else
	   print *,'     No background available'
	   call zero(mslp_bk,ni,nj)
	endif
c
	print *,' '
	print *,' Getting station pressure background....'
	var_req = 'SFCP'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,stnp_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call move(wt, wt_stnp, ni,nj)
	   call multcon(stnp_bk,0.01,ni,nj) ! conv Pa to mb
	   back_sp = 1
	else
	   print *,'     No background available'
	   call zero(stnp_bk,ni,nj)
	endif
c
	print *,' '
	print *,' Getting visibility background....'
	var_req = 'VISB'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,vis_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call move(wt, wt_vis, ni,nj)
	   call conv_m2miles(vis_bk,vis_bk,ni,nj)
	   call visg2log(vis_bk,ni,nj,badflag) ! conv miles to log(miles)
	   back_vis = 1
	else
	   print *,'     No background available'
	   call zero(vis_bk,ni,nj)
	endif
c
	print *,' '
	print *,' Getting dew point temperature background....'
	var_req = 'DEWP'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,td_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call move(wt, wt_td, ni,nj)
	   call conv_k2f(td_bk,td_bk,ni,nj) ! conv K to deg F
	   back_td = 1
	else
	   print *,'     No background available'
	   call zero(td_bk,ni,nj)
	endif
	print *,' '
c
	print *,' '
	print *,' Getting reduced pressure background....'
	var_req = 'REDP'
	call get_background_sfc(i4time,var_req,ext_bk,ibkg_time,rp_bk,
     &          laps_cycle_time,ni,nj,istatus)
	if(istatus .eq. 1) then
	   call make_fnam_lp(ibkg_time,back,istatus)
	   write(6,951) ext_bk(1:6), back
	   call move(wt, wt_rp, ni,nj)
	   call multcon(rp_bk,0.01,ni,nj) ! conv Pa to mb
	   back_rp = 1
	else
	   print *,'     No background available'
	   call zero(rp_bk, ni,nj)
	endif
c
 951	format(3x,'Using background from ',a6,' at ',a9)
c
c.....  Adjust wts for winds; if above 2500 m, increase wt by order of mag
c.....  so background winds will have more influence.
c
	do j=1,nj
	do i=1,ni
	   if(topo(i,j) .gt. 2500.) then
	      wt_u(i,j) = wt_u(i,j) * 10.
	      wt_v(i,j) = wt_v(i,j) * 10.
	   endif
	enddo !i
	enddo !j
c
 600	continue
c
c.....	QC the surface data.
c
	if(iskip .gt. 0) then  !check QC flag
	   print *, ' **  omit qc of data  **  '
	   goto 521
	endif
	call get_directory('lso', infile_last, len)
	infile_last = infile_last(1:len) // filename_last // '.lso'
c
	call qcdata(filename,infile_last,rely,ivals1,mxstn,
     &     t_s, td_s, dd_s, ff_s, ddg_s, ffg_s, pstn_s, pmsl_s, alt_s, 
     &     vis_s, stn3, rii, rjj, ii, jj, n_obs_b, n_sao_b, n_sao_g,
     &     istatus)
c
	if(istatus .eq. 1) then
	   jstatus(2) = 1
	elseif(istatus .eq. 0) then
	   jstatus(2) = 0
	   print *, ' +++ No data for QC routine. +++'
	   go to 521
	else
	   print *,
     &        ' +++ ERROR.  Problem in QC routine. +++'
	   jstatus(2) = -2
	   go to 521
	endif
c
c.....	Check each of the primary analysis variables.
c
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 121
	  if(rely(7,nn) .lt. 0) then	! temperature
	   print *, 'QC: Bad T at ',stations(mm),' with value ',t_s(mm)
	    t_s(mm) = badflag
	  endif
 121	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 122
	  if(rely(8,nn) .lt. 0) then	! dewpt
	   print *, 'QC: Bad TD at ',stations(mm),' with value ',td_s(mm)
	    td_s(mm) = badflag
	  endif
 122	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 123
	  if(rely(9,nn) .lt. 0) then	! wind direction
	   print *, 'QC: Bad DIR at ',stations(mm),' with value ',dd_s(mm)
	    dd_s(mm) = badflag
	  endif
 123	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 124
	  if(rely(10,nn) .lt. 0) then	! wind speed
	   print *, 'QC: Bad SPD at ',stations(mm),' with value ',ff_s(mm)
	    ff_s(mm) = badflag
	  endif
 124	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 126
	 if(rely(15,nn) .lt. 0) then	! altimeter 
	  print *, 'QC: Bad ALT at ',stations(mm),' with value ',alt_s(mm)
	    alt_s(mm) = badflag
	  endif
 126	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 128
	 if(rely(25,nn) .lt. 0) then	! visibility 
	  print *, 'QC: Bad VIS at ',stations(mm),' with value ',vis_s(mm)
	    vis_s(mm) = badflag
	  endif
 128	enddo  !mm
 521	continue                          
c
c.....  QC the backgrounds.  If Td > T, set Td = T...temporary fix until LGB
c.....  can do this....
c
	do j=1,nj
	do i=1,ni
	   if(td_bk(i,j) .gt. t_bk(i,j)) td_bk(i,j) = t_bk(i,j)
	enddo !i
	enddo !j
c
c.....  Set up arrays for the verify routine.
c
	do i=1,ni
	   x1a(i) = float(i)
	enddo !i
	do j=1,nj
	   x2a(j) = float(j)
	enddo !j
c
c
cx....	Now call MDATLAPS to put the data on the grid.
c
	call mdat_laps(i4time,atime,ni,nj,mxstn,laps_cycle_time,lat,
     &     lon,topo,x1a,x2a,
     &     y2a, lon_s, elev_s, t_s, td_s, dd_s, ff_s, pstn_s, pmsl_s, 
     &     alt_s, vis_s, stations, rii, rjj, ii, jj, n_obs_b, n_sao_g,
     &     u_bk, v_bk, t_bk, td_bk, rp_bk, mslp_bk, stnp_bk, vis_bk,
     &     wt_u, wt_v, wt_rp, wt_mslp, ilaps_bk, 
     &     u1, v1, rp1, t1, td1, sp1, tb81, mslp1, vis1, elev1,
     &     back_t,back_td,back_uv,back_sp,back_rp,back_mp,back_vis,
     &     jstatus) 
c
	if(jstatus(1) .ne. 1) then
	   print *,' From MDAT_LAPS:  Error Return.  Stop.'
	   stop 
	endif
c
c
c.....	Call LAPSVANL to do the actual variational analysis, and calculate
c.....	derived variables, etc.  The output file goes to the lapsprd 
c.....	directory (machine dependent) and has the extension '.lsx'.
c
	call laps_vanl(i4time,filename,ni,nj,nk,mxstn,laps_cycle_time,
     &     dt,del,gam,ak,lat,lon,topo,grid_spacing, laps_domain,
     &     lat_s, lon_s, elev_s, t_s, td_s, ff_s, pstn_s, pmsl_s,
     &     vis_s, stations, n_obs_b, n_sao_b, n_sao_g,
     &     u_bk, v_bk, t_bk, td_bk, rp_bk, mslp_bk, stnp_bk, vis_bk, 
     &     wt_u, wt_v, wt_t, wt_td, wt_rp, wt_mslp, wt_vis, ilaps_bk, 
     &     back_t,back_td,back_uv,back_sp,back_rp,back_mp,back_vis,
     &     u1, v1, rp1, t1, td1, sp1, tb81, mslp1, vis1, elev1,
     &     x1a,x2a,y2a,ii,jj,jstatus)
c
	if(jstatus(3) .ne. 1) then
	  print *,' From LAPS_VANL: Error Return.' 
	endif
c
c.....	That's about it...let's go home.
c
	print *,' End of LAPS Surface Analysis'
	return
	end

