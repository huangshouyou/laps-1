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
	subroutine mdat_laps(i4time_cur,atime,infile_o,dir_v,ext_v,
     &   outfile,outfile_q,ihr,del,gam,ak,lat,lon,east,west,anorth,
     &   south,topo,reflon,jstatus)
c
c*******************************************************************************
c
c	rewritten version of the mcginley mesodat program
c	-- rewritten again for the LAPS surface analysis...1-12-88
c
c	Changes:
c 	P.A. Stamus	06-27-88  Changed LAPS grid to new dimensions.
c			07-13-88  Restructured for new data formats
c				                  and MAPS first-guess.
c			07-26-88  Finished new stuff.
c			08-05-88  Rotate SAO winds to the projection.
c			08-23-88  Changes for laps library routines.
c			09-22-88  Make 1st guess optional.
c			10-11-88  Make filenames time dependent.
c-------------------------------------------------------------------------------
c			12-15-88  Rewritten.
c			01-09-89  Changed header, added meanpres calc.
c			03-29-89  Corrected for staggered grid. Removed
c					dependence on file for correct times.
c			04-12-89  Changed to do only 1 time per run.
c			05-12-89  Fixed i4time error.
c			06-01-89  New grid -- add nest6grid.
c			11-07-89  Add nummeso/sao to the output header.
c			--------------------------------------------------------
c			03-12-90  Subroutine version.
c			04-06-90  Pass in ihr,del,gam,ak for header.
c			04-11-90  Pass in LAPS lat/lon and topography.
c			04-16-90  Bag cloud stuff except ceiling.
c			04-17-90  Add MSL pressure.
c			06-18-90  New cloud check routine.
c			06-19-90  Add topo.
c			10-03-90  Changes for new vas data setup.
c			10-30-90  Put Barnes anl on boundaries.
c			02-15-91  Add solar radiation code.
c			05-01-91  Add Hartsough QC code.
c			11-01-91  Changes for new grids.
c			01-15-92  Add visibility analysis.
c			01-22-93  Changes for new LSO/LVD.
c			07-29-93  Changes for new barnes_wide routine.
c                       02-24-94  Remove ceiling ht stuff.
c                       04-14-94  Changes for CRAY port.
c                       07-20-94  Add include file.
c                       09-31-94  Change to LGA from LMA for bkgs.
c                       02-03-95  Move background calls to driver routine.
c                       02-24-95  Add code to check bkgs for bad winds.
c                       08-08-95  Changes for new verify code.
c                       03-22-96  Changes for 30 min cycle.
c                       10-09-96  Grid stn elevs for use in temp anl.
c                       11-18-96  Ck num obs.
c                       12-13-96  More porting changes...common for
c                                   sfc data, LGS grids. Bag stations.in
c
c	Notes:
c
c******************************************************************************
c
	include 'laps_sfc.inc'
c
c..... Stuff for the sfc data and other station info (LSO +)
c
	real*4 lat_s(mxstn), lon_s(mxstn), elev_s(mxstn)
	real*4 t_s(mxstn), td_s(mxstn), dd_s(mxstn), ff_s(mxstn)
	real*4 ddg_s(mxstn), ffg_s(mxstn)
	real*4 pstn_s(mxstn), pmsl_s(mxstn), alt_s(mxstn)
	real*4 cover_s(mxstn), hgt_ceil(mxstn), hgt_low(mxstn)
	real*4 solar_s(mxstn), store_hgt(mxstn,5), vis_s(mxstn)
	real*4 rii(mxstn), rjj(mxstn)
c
	integer*4 kloud_s(mxstn),idp3_s(mxstn),obstime(mxstn)
	integer*4 ii(mxstn), jj(mxstn)
c
	character infile_o*70
	character stn(mxstn)*3,obstype(mxstn)*8,wx_s(mxstn)*8
	character store_emv(mxstn,5)*1, store_amt(mxstn,5)*4
c
	common/LSO_sfc_obs/
     &     lat_s, lon_s, elev_s, t_s, td_s, dd_s, ff_s, ddg_s, 
     &     ffg_s, pstn_s, pmsl_s, alt_s, cover_s, hgt_ceil, 
     &     hgt_low, solar_s, store_hgt, vis_s, kloud_s, idp3_s, 
     &     obstime, stn, obstype, wx_s, store_emv, store_amt,
     &     rii, rjj, ii, jj, n_obs_b, n_sao_b, n_sao_g
c
c.....	Arrays for derived variables from OBS data
c
	real*4 uu(mxstn), vv(mxstn), pred_s(mxstn)
c
c.....	Stuff for satellite data.
c
	integer*4 lvl_v(1)
	character var_v(1)*3, units_v(1)*10, lvl_coord_v(1)*4
	character comment_v(1)*125, dir_v*50, ext_v*31
c
c.....  Stuff for intermediate grids (old LGS file)
c
	real*4 u1(ni,nj), v1(ni,nj)
	real*4 t1(ni,nj), td1(ni,nj), tb81(ni,nj)
	real*4 rp1(ni,nj), sp1(ni,nj), mslp1(ni,nj)
	real*4 vis1(ni,nj), elev1(ni,nj)
c
	common/LGS_grids/
     &     u1, v1, rp1, t1, td1, sp1, tb81, mslp1, vis1, elev1
c
c..... Other arrays for intermediate grids 
c
        real*4 wwu(ni,nj), wwv(ni,nj)
	real*4 wp(ni,nj), wsp(ni,nj), wmslp(ni,nj)
	real*4 wt(ni,nj), wtd(ni,nj), welev(ni,nj), wvis(ni,nj)
	real*4 dtb8(ni,nj)
c
	real*4 d1(ni,nj), d2(ni,nj), d3(ni,nj), d4(ni,nj)    ! work arrays
c
c..... LAPS Lat/lon grids.
c
	real*4 lat(ni,nj),lon(ni,nj), topo(ni,nj)
c
	real*4 lapse_t, lapse_td, lapse_temp
	real*4 t7(ni,nj), h7(ni,nj)
	real*4 t8(ni,nj), h8(ni,nj)
	character atime*24, outfile*70, outfile_q*70
	character infile_last*70,filename_last*9, atime_last*24
	integer*4 rely(26,mxstn), ivals1(mxstn)		! for the QC
c
c.....	Grids for the background fields...use if not enough sao data.
c
        real*4 u_bk(ni,nj), v_bk(ni,nj), t_bk(ni,nj), td_bk(ni,nj)
        real*4 wt_u(ni,nj), wt_v(ni,nj), wt_t(ni,nj), wt_td(ni,nj)
        real*4 rp_bk(ni,nj), mslp_bk(ni,nj), stnp_bk(ni,nj)
        real*4 wt_rp(ni,nj), wt_mslp(ni,nj), wt_stnp(ni,nj)
        real*4 vis_bk(ni,nj), wt_vis(ni,nj)
c
        common/backgrnd/
     &     u_bk, v_bk, t_bk, td_bk, rp_bk, mslp_bk, stnp_bk, vis_bk, 
     &     wt_u, wt_v, wt_t, wt_td, wt_rp, wt_mslp, wt_stnp, wt_vis, 
     &     ilaps_bk, irams_bk
c
c.....  Stuff for checking the background fields.
c
	real*4 interp_spd(mxstn), bk_speed(ni,nj)
	parameter(threshold = 2.)  ! factor for diff check
	parameter(spdt      = 20.) ! spd min for diff check
	character stn_mx*3, stn_mn*3, amax_stn_id*3
c       
	integer*4 jstatus(20)
c
c.....	START.  Set up constants.
c
	jstatus(1) = -1		! put something in the status
	jstatus(2) = -1
	imaps = 0
	ibt = 0
	imax = ni
	jmax = nj
	icnt = 0
	delt = 0.035
	zeros = 1.e-38
	rog = 0.286 / 9.8 * 6.5
c
c..... Set up the sides of the LAPS domain.
c
        yo = south
        xo = west
	xmult = float(imax - 1)/(east - west)
	ymult = float(jmax - 1)/(anorth - south)
c
c.....  Stuff for checking the background windspeed.
c
	if(ilaps_bk.ne.1 .and. irams_bk.ne.1) then
	   call constant(bk_speed,badflag, imax,jmax)
	else
	   call windspeed(u_bk,v_bk,bk_speed, imax,jmax)
	endif
c
c.....	QC the surface data.
c
c.....  New quality control procedures for surface data
c
	if(iskip .gt. 0) then  !check QC flag
	  print *, ' **  omit qc of data  **  '
	  goto 521
	endif
	i4time_last = i4time_cur - 3600
	call cv_i4tim_asc_lp(i4time_last,atime_last,istatus)
	call make_fnam_lp(i4time_last,filename_last,istatus)
        call get_directory('lso',infile_last,len)
        infile_last = infile_last(1:len)//filename_last//'.lso'
c	infile_last = 
c     &  '../lapsprd/lso/'//filename_last//'.lso'
c
	call qcdata(filename,infile_last,rely,ivals1,istatus)
c
	if(istatus .eq. 1) then
	  jstatus(2) = 1
	elseif(istatus .eq. 0) then
	  jstatus(2) = 0
	  print *, ' +++ No data for QC routine. +++'
	  go to 521
	else
	  print *,
     &    ' +++ ERROR.  Problem in QC routine. +++'
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
	    print *, 'QC: Bad T at ',stn(mm),' with value ',t_s(mm)
	    t_s(mm) = badflag
	  endif
 121	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 122
	  if(rely(8,nn) .lt. 0) then	! dewpt
	    print *, 'QC: Bad TD at ',stn(mm),' with value ',td_s(mm)
	    td_s(mm) = badflag
	  endif
 122	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 123
	  if(rely(9,nn) .lt. 0) then	! wind direction
	    print *, 'QC: Bad DIR at ',stn(mm),' with value ',dd_s(mm)
	    dd_s(mm) = badflag
	  endif
 123	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 124
	  if(rely(10,nn) .lt. 0) then	! wind speed
	    print *, 'QC: Bad SPD at ',stn(mm),' with value ',ff_s(mm)
	    ff_s(mm) = badflag
	  endif
 124	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 126
	  if(rely(15,nn) .lt. 0) then	! altimeter 
	    print *, 'QC: Bad ALT at ',stn(mm),' with value ',alt_s(mm)
	    alt_s(mm) = badflag
	  endif
 126	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 127
	  if(rely(17,nn) .lt. 0) then	! ceiling 
	   print *, 'QC: Bad CEIL at ',stn(mm),' with value ',hgt_ceil(mm)
	   hgt_ceil(mm) = badflag
	  endif
 127	enddo  !mm
	do mm=1,n_obs_b
	  nn = ivals1(mm)
	  if(nn .lt. 1) go to 128
	  if(rely(25,nn) .lt. 0) then	! visibility 
	    print *, 'QC: Bad VIS at ',stn(mm),' with value ',vis_s(mm)
	    vis_s(mm) = badflag
	  endif
 128	enddo  !mm
 521	continue                          
c
c.....	Rotate sao winds to the projection grid, then change dd,fff to u,v
c
	do i=1,n_obs_b
	  dd_rot = dd_s(i) + (reflon - lon_s(i))
          call decompwind_gm(dd_rot,ff_s(i),uu(i),vv(i),istatus)     
	  if(uu(i).lt.-150. .or. uu(i).gt.150.) uu(i) = badflag
	  if(vv(i).lt.-150. .or. vv(i).gt.150.) vv(i) = badflag
	enddo !i
c
c.....  Before continuing, use the SAO data to check the backgrounds.
c.....  Find the background at each station location, then compare
c.....  to the current observation.  If the difference is larger than the
c.....  threshold, zero out the background weights for that variable.
c
c
c.....  First find the max in the background wind speed field.
c
	print *,' '
	print *,' Checking background...'
	print *,' '
	if(ilaps_bk.ne.1 .and. irams_bk.ne.1) then
	   print *,' NO BACKGROUND FIELDS AVAILIBLE...SKIPPING...'
	   go to 415
	endif
c
	do j=1,jmax
	do i=1,imax
	   if(bk_speed(i,j) .gt. bksp_mx) then
	      bksp_mx = bk_speed(i,j)
	      ibksp = i
	      jbksp = j
	   endif
	enddo !i
	enddo !j
c
c.....  Find the 2nd derivative table for use by the splines later.
c
	call splie2(x1a,x2a,bk_speed,imax,jmax,y2a)
c
c.....  Now call the spline routine for each station in the grid.
c
	ithresh = 0
	ibkthresh = 0
	diff_mx = -1.e30
	diff_mn = 1.e30
	amax_stn = -1.e30
	do i=1,n_obs_b
	   if(ii(i).lt.1 .or. ii(i).gt.imax) go to 330
	   if(jj(i).lt.1 .or. jj(i).gt.jmax) go to 330
	   aii = float(ii(i))
	   ajj = float(jj(i))
	   call splin2(x1a,x2a,bk_speed,y2a,imax,jmax,aii,ajj,
     &                 interp_spd(i))
	   if(ff_s(i) .le. badflag) then
	      diff = badflag
	   else
	      diff = interp_spd(i) - ff_s(i)
	      if(ff_s(i) .lt. 1.) then
		 percent = -1.
	      else
	         percent = ( abs(diff) / ff_s(i) ) * 100.
	      endif
	   endif
	   write(6,400) 
     &         i,stn(i),ii(i),jj(i),interp_spd(i),ff_s(i),diff,percent
	   if(diff .eq. badflag) go to 330
	   diff = abs( diff )         ! only really care about magnitude
	   if(diff .gt. diff_mx) then
	      diff_mx = diff
	      stn_mx = stn(i)
	   endif
	   if(diff .lt. diff_mn) then
	      diff_mn = diff
	      stn_mn = stn(i)
	   endif
	   if(diff.gt.(threshold * ff_s(i)).and.ff_s(i).gt.spdt) then
	      ithresh = ithresh+1
	   endif
	   if(ff_s(i) .gt. amax_stn) then
	      amax_stn = ff_s(i)
	      amax_stn_id = stn(i)
	   endif
 330	enddo !i
 400	format(1x,i3,':',1x,a3,' at i,j ',2i3,':',3f12.2,f12.0)
	write(6,405) diff_mx, stn_mx
 405	format(1x,' Max difference of ',f12.2,'  at ',a3)
	write(6,406) diff_mn, stn_mn
 406	format(1x,' Min difference of ',f12.2,'  at ',a3)
	write(6,410) ithresh, threshold, spdt
 410	format(1x,' There were ',i4,
     &            ' locations exceeding threshold of ',f6.3,
     &            ' at speeds greater than ',f6.1,' kts.')
c
c.....  If too many stations exceed threshold, or if the max in the 
c.....  background is too much larger than the max in the obs, backgrounds 
c.....  probably bad.  Zero out the wt arrays so they won't be used.
c
	print *,' '
	write(6,420) bksp_mx, ibksp, jbksp
 420	format(1x,' Background field max: ',f12.2,' at ',i3,',',i3)
	write(6,421) amax_stn, amax_stn_id
 421	format(1x,' Max speed at station: ',f12.2,' at ',a3)
c
	if(bksp_mx .ge. 60.) then
	   if(bksp_mx .gt. amax_stn*2.66) ibkthresh = 1
	endif
c
	if(ithresh.gt.2 .or. ibkthresh.gt.0) then
	   write(6,412)
 412	   format(1x,
     &      '  Possible bad wind/pressure backgrounds...skipping.')
	   call zero(wt_u, imax,jmax)
	   call zero(wt_v, imax,jmax)
	   call zero(wt_rp, imax,jmax)
	   call zero(wt_mslp, imax,jmax)
	endif
	print *,' '
c
c
c.....  Now, back to the analysis.
c.....	Convert altimeters to station pressure.
c
 415	do j=1,n_obs_b
	  if(alt_s(j) .le. badflag) then
	    pstn_s(j) = badflag
	  else
	    pstn_s(j) = alt_2_sfc_press(alt_s(j), elev_s(j)) !conv alt to sp
	  endif
	enddo !j
c
c.....	Now reduce station pressures to standard levels...1500 m (for CO) 
c.....  and MSL.  Use background 700 mb and 850 mb data from LGA (or equiv).
c
	call mean_lapse(n_obs_b,elev_s,t_s,td_s,a_t,lapse_t,a_td,
     &                    lapse_td,hbar)
c
	i4time_tol = 21600
c
c.....  Get the 700 temperatures from LGA (or equiv).
c
	call get_2d_field(i4time_cur,i4time_tol,i4time_near,
     &                    'lga','T  ',700,t7, imax,jmax,istatus)
c
	if(istatus .ne. 1) then		! no 700 temps
	  print *,
     &' LGA 700 T not available for P reduction...using const 265K'
	  call constant(t7,265.,imax,jmax)
	endif
c
c.....  Get the 700 heights from LGA (or equiv).
c
	call get_2d_field(i4time_cur,i4time_tol,i4time_near,
     &                    'lga','HT ',700,h7, imax,jmax,istatus)
c
	if(istatus .ne. 1) then
	  print *,
     &' LGA 700 HT not available for P reduction...using const 3000 m'
	  call constant(h7,3000.,imax,jmax)
	endif
c
c.....  Get the 850 temps from LGA (or equiv).
c
	call get_2d_field(i4time_cur,i4time_tol,i4time_near,
     &                    'lga','T  ',850,t8, imax,jmax,istatus)
c
	if(istatus .ne. 1) then		! no 850 temps
	  print *,
     &' LGA 850 T not available for P reduction...using const 280K'
	  call constant(t8,280.,imax,jmax)
	endif
c
c.....  Get the 850 heights from LGA (or equiv).
c
	call get_2d_field(i4time_cur,i4time_tol,i4time_near,
     &                    'lga','HT ',850,h8, imax,jmax,istatus)
c
	if(istatus .ne. 1) then
	  print *,
     &' LGA 850 HT not available for P reduction...using const 1500 m'
	  call constant(h8,1500.,imax,jmax)
	endif
c
c.....  Try some stuff to improve the reductions (off for now 8-31-94 pas)
c
	call conv_k2f(t7,t7,imax,jmax)
	call conv_k2f(t8,t8,imax,jmax)
	do k=1,n_obs_b
	  if(pstn_s(k).le.badflag .or. t_s(k).le.badflag 
     &                           .or. td_s(k).le.badflag) then
	    pred_s(k) = badflag
	    pmsl_s(k) = badflag
	  else
	    iii = ii(k)
	    jjj = jj(k)
	    if(iii .lt. 1) iii = 1
	    if(iii .gt. imax) iii = imax
	    if(jjj .lt. 1) jjj = 1
	    if(jjj .gt. jmax) jjj = jmax
!	    temp = t7(iii,jjj) * (pstn_s(k) / 700.) ** rog
!	    temp = (temp - 273.15) * 1.8 + 32.	! conv deg K to deg F	    
c
c.....	Calculate lapse rate
c
!	    x1 = h8(iii,jjj) - elev_s(k)
!	    del_z = h7(iii,jjj) - elev_s(k)
!	    if(x1 .lt. 50.) then
!	      del_t = t7(iii,jjj) - t_s(k)
!	      if(del_z .lt. 500.) then
!	       pred_s(k) = badflag
!	       pmsl_s(k) = badflag
!	       go to 550
!	      endif
!	      lapse_temp = del_t / del_z
!	    else
!	      x = x1 / del_z
!	      del_t = (1.-x)*(t7(iii,jjj)-t8(iii,jjj)) 
!    &                                       + x*(t8(iii,jjj)-t_s(k))
!	      lapse_temp = del_t / del_z
!	    endif
c
	    call reduce_p(t_s(k),td_s(k),pstn_s(k),elev_s(k),lapse_t,
     &                       lapse_td,pred_s(k),redp_lvl)  ! 1500 m for CO
!	    call reduce_p(t_s(k),td_s(k),pstn_s(k),elev_s(k),lapse_temp,
!     &                       lapse_td,pmsl_s(k),0.)	! MSL
	  endif
550	continue
        enddo !k
c
c.....	Convert visibility to log( vis ) for the analysis.
c
	call viss2log(vis_s,mxstn,n_obs_b,badflag)
c
c.....	READ IN THE BAND 8 BRIGHTNESS TEMPS (deg K)
c
	 lvl_v(1) = 0
	 var_v(1) = 'S8W'	! satellite...band 8, warm pixel (K)
c
	 call get_laps_2dgrid(i4time_cur,970,i4time_nearest,ext_v,var_v,
     &        units_v,comment_v,imax,jmax,tb81,lvl_v,istatus)
c
	if(istatus .ne. 1) then
	  write(6,962) atime
962	  format(1x,' +++ VAS data not available for the ',a24,
     &           ' analysis. +++')
	go to 800
	endif
	ibt = 1
c
c.....  READ IN any other data here
c
800	continue
c
c.....	Put the data on the grids.
c
c.....	Winds:
c
	call put_winds(uu,vv,mxstn,n_obs_b,u1,v1,wwu,wwv,icnt,
     &                 imax,jmax,rii,rjj,ii,jj)
	icnt_t = icnt
c
c.....	Temperatures:
c
	call put_thermo(t_s,mxstn,n_obs_b,t1,wt,icnt,imax,jmax,ii,jj)
c
c.....	Dew points: 
c
	call put_thermo(td_s,mxstn,n_obs_b,td1,wtd,icnt,imax,jmax,ii,jj)
c
c.....	Put the reduced pressure on the grid
c
	call put_thermo(pred_s,mxstn,n_obs_b,rp1,wp,icnt,imax,jmax,ii,jj)
c
c.....	Put the station pressure on the grid
c
	call put_thermo(pstn_s,mxstn,n_obs_b,sp1,wsp,icnt,imax,jmax,ii,jj)
c
c.....	Put the MSL pressure on the grid
c
	call put_thermo(pmsl_s,mxstn,n_obs_b,mslp1,wmslp,icnt,
     &                  imax,jmax,ii,jj)
c
c.....	Ceiling Height:  *** REMOVED 2-24-94 pas ***
c
c
c.....	Visibility:
c
	call put_thermo(vis_s,mxstn,n_obs_b,vis1,wvis,icnt,
     &                  imax,jmax,ii,jj)
c
c.....	Station elevation:
c
	call put_thermo(elev_s,mxstn,n_obs_b,elev1,welev,icnt,
     &                  imax,jmax,ii,jj)
c
c.....	Now find the values at the gridpts.
c
        write(6,1010) icnt_t
1010	FORMAT(1X,'DATA SET 1 INITIALIZED WITH ',I6,' OBSERVATIONS')
        call procar(u1,imax,jmax,wwu,imax,jmax,-1)
        call procar(v1,imax,jmax,wwv,imax,jmax,-1)
        call procar(t1,imax,jmax,wt,imax,jmax,-1)
        call procar(td1,imax,jmax,wtd,imax,jmax,-1)
        call procar(rp1,imax,jmax,wp,imax,jmax,-1)
        call procar(sp1,imax,jmax,wsp,imax,jmax,-1)
        call procar(mslp1,imax,jmax,wmslp,imax,jmax,-1)
        call procar(vis1,imax,jmax,wvis,imax,jmax,-1)
        call procar(elev1,imax,jmax,welev,imax,jmax,-1)
c
c.....	Fill in the boundary of each field with values from a wide-area Barnes.
c
	if(n_sao_g .lt. 10) then
	  print *,
     & ' Limited SAO data...using previous analysis for the boundaries.'
c
	  call back_bounds(u1,imax,jmax,u_bk)
	  call back_bounds(v1,imax,jmax,v_bk)
	  call back_bounds(t1,imax,jmax,t_bk)
	  call back_bounds(td1,imax,jmax,td_bk)
	  call back_bounds(rp1,imax,jmax,rp_bk)
	  call back_bounds(sp1,imax,jmax,stnp_bk)
	  call back_bounds(mslp1,imax,jmax,mslp_bk)
	  call back_bounds(vis1,imax,jmax,vis_bk)
	  call back_bounds(elev1,imax,jmax,topo)
c
	else
c
 1111	  print *,' U:' 
	  call fill_bounds(u1,imax,jmax,ii,jj,uu,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' V:' 
	  call fill_bounds(v1,imax,jmax,ii,jj,vv,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' T:' 
	  call fill_bounds(t1,imax,jmax,ii,jj,t_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' TD:' 
	  call fill_bounds(td1,imax,jmax,ii,jj,td_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' P:' 
	  call fill_bounds(rp1,imax,jmax,ii,jj,pred_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' SFC P:' 
	  call fill_bounds(sp1,imax,jmax,ii,jj,pstn_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' MSL P:' 
	  call fill_bounds(mslp1,imax,jmax,ii,jj,pmsl_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' VIS:' 
	  call fill_bounds(vis1,imax,jmax,ii,jj,vis_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	  print *,' STN ELEV:' 
	  call fill_bounds(elev1,imax,jmax,ii,jj,elev_s,n_obs_b,badflag,
     &                    mxstn,d1,d2)
	endif
c
c.....	Check the brightness temperatures for clouds.
c
	if(ilaps_bk.eq.0 .and. irams_bk.eq.0) then
	 print *,' ++ No previous temperature est for cloud routine ++'
	 go to 720
	endif
	call zero(d4,imax,jmax)
	call conv_f2k(t_bk,d4,imax,jmax)
	call clouds(imax,jmax,topo,d4,badflag,tb81,dtb8,d1,i4time_cur,
     &              laps_cycle_time,lat,lon,1.e37,d2,d3)
c
c.....  Convert tb8 from K to F...watch for 0.0's where clds removed.
c
720	continue
	do j=1,jmax
	do i=1,imax
	   if(tb81(i,j) .gt. 400.) tb81(i,j) = 0.
	   if(tb81(i,j) .ne. 0.) then
	      tb81(i,j) = (1.8 * (tb81(i,j) - 273.15)) + 32.
	   endif
	enddo !i
	enddo !j
c
c..... That's it here....
c
	jstatus(1) = 1		! everything's ok...
	print *,' Normal completion of MDATLAPS'
c
	return
	end
c
c
	subroutine put_winds(u_in,v_in,max_stn,num_sta,u,v,wwu,wwv,icnt,
     &                       ni,nj,rii,rjj,ii,jj)
c
c*******************************************************************************
c
c	Routine to put the u and v wind components on the LAPS grid...properly
c       located on the staggered u- and v- grids.
c
c	Changes:
c		P.A. Stamus	12-01-88  Original (cut from old mdatlaps)
c				03-29-89  Fix for staggered grid.
c                               02-24-94  Change method to use rii,rjj locatns.
c
c	Inputs/Outputs:
c	   Variable     Var Type   I/O   Description
c	  ----------   ---------- ----- -------------
c	   u_in            RA       I    Array of u wind components at stations
c	   v_in            RA       I      "      v  "       "       "     "
c	   max_stn         I        I    Max number of stations (for dimension)
c	   num_sta         I        I    Number of stations in input file
c	   u, v            RA       O    U and V component grids.
c	   wwu             RA       O    Weight grid for U.
c	   wwv             RA       O    Weight grid for V.
c	   icnt            I        O    Number of stations put on grid.
c          rii, rjj        RA       I    i,j locations of stations (real)
c          ii, jj          IA       I    i,j locations of stations (integer)
c
c	User Notes:
c
c*******************************************************************************
c
	real*4 u_in(max_stn), v_in(max_stn), u(ni,nj), v(ni,nj)
	real*4 wwu(ni,nj), wwv(ni,nj)
        real*4 rii(max_stn), rjj(max_stn)
        integer*4 ii(max_stn), jj(max_stn)
c
	badflag = -99.9
	zeros = 1.e-30
c
	do 10 ista=1,num_sta
c
c.....	Find ixx, iyy to put data at proper location at the grid square
c
	  ixxu = ii(ista)
	  iyyu = rjj(ista) + 0.5   ! grid offset for u-grid from major grid
	  ixxv = rii(ista) + 0.5   ! grid offset for v-grid from major grid
	  iyyv = jj(ista)
	  icnt = icnt + 1
c
c.....	Put wind components on the u and v grids
c
	  if(u_in(ista).eq.badflag .or. v_in(ista).eq.badflag) go to 10
	  if(u_in(ista) .eq. 0.) u_in(ista) = zeros
	  if(v_in(ista) .eq. 0.) v_in(ista) = zeros
	  if(ixxu.lt.1 .or. ixxu.gt.ni) go to 15
	  if(iyyu.lt.1 .or. iyyu.gt.nj) go to 15
	  u(ixxu,iyyu) = u_in(ista) + u(ixxu,iyyu)
	  wwu(ixxu,iyyu) = wwu(ixxu,iyyu) + 1.
15	  if(ixxv.lt.1 .or. ixxv.gt.ni) go to 10
	  if(iyyv.lt.1 .or. iyyv.gt.nj) go to 10
	  v(ixxv,iyyv) = v_in(ista) + v(ixxv,iyyv)
	  wwv(ixxv,iyyv) = wwv(ixxv,iyyv) + 1.
10	continue
c
	return
	end
c
c
	subroutine put_thermo(var_in,max_stn,num_sta,x,w,icnt,
     &                        ni,nj,ii,jj)
c
c*******************************************************************************
c
c	Routine to put non-wind variables on the 'major' LAPS grid.
c
c	Changes:
c		P.A. Stamus	12-01-88  Original (cut from old mdatlaps)
c				03-29-89  Fix for staggered grid.
c				04-19-89  Added ii,jj for qc routine.
c				10-30-90  ii,jj now from 'FIND_IJ'.
c                               02-24-94  New ii,jj arrays.
c
c	Inputs/Outputs:
c	   Variable     Var Type   I/O   Description
c	  ----------   ---------- ----- -------------
c	   var_in          RA       I    Array of the station ob. 
c	   max_stn         I        I    Max number of stations (for dimension)
c	   num_sta         I        I    Number of stations in input file
c	   x               RA       O    Grid for the variable. 
c	   w               RA       O    Weight grid.
c	   icnt            I        O    Number of stations put on grid.
c          ii, jj          IA       I    i,j locations of the stations (integer)
c
c	User Notes:
c
c*******************************************************************************
c
	real*4 var_in(max_stn), x(ni,nj), w(ni,nj)
        integer*4 ii(max_stn), jj(max_stn)
c
	badflag = -99.9
	zeros = 1.e-30
        call zero(w,ni,nj)
c
	do 10 ista=1,num_sta
c
	  ixx = ii(ista)
	  iyy = jj(ista)
	  icnt = icnt + 1
c
c.....	Put variable on the LAPS grid
c
          if(ixx.lt.1 .or. ixx.gt.ni) go to 10
          if(iyy.lt.1 .or. iyy.gt.nj) go to 10
	  if(var_in(ista) .eq. badflag) go to 10
	  if(var_in(ista) .eq. 0.) var_in(ista) = zeros
	  x(ixx,iyy) = var_in(ista) + x(ixx,iyy)
	  w(ixx,iyy) = w(ixx,iyy) + 1.
10	continue
c
	return
	end
c
c
        Subroutine procar(a,imax,jmax,b,imax1,jmax1,iproc)
        real*4 a(imax,jmax),b(imax1,jmax1)
        do 2 j=1,jmax
        jj=j
        if(jmax.gt.jmax1) jj=jmax1
        do 2 i=1,imax
        ii=i
        if(imax.gt.imax1) ii=imax1
        if(b(ii,jj)) 3,4,3
    3   a(i,j)=a(i,j)*b(ii,jj)**iproc 
        GO TO 2
!    4   A(I,J)=0.
4	continue
    2   CONTINUE    
        return  
        end
c
c
	subroutine find_ij(lat_s,lon_s,lat,lon,numsta,mxsta,
     &                     ni,nj,ii,jj,rii,rjj)
c
c.....	Routine to find the i,j locations for each station.  Do not "round"
c.....  the ii,jj's "up"...straight truncation puts the ob at the proper
c.....  grid point on the major grid.
c
	real*4 lat_s(mxsta), lon_s(mxsta)
        real*4 lat(ni,nj), lon(ni,nj)
	integer*4 ii(mxsta), jj(mxsta)
        real*4 rii(mxsta), rjj(mxsta)
c
	do ista=1,numsta
          call latlon_to_rlapsgrid(lat_s(ista),lon_s(ista),lat,lon,
     &       ni,nj,rii(ista),rjj(ista),istatus)
	  ii(ista) = rii(ista)
	  jj(ista) = rjj(ista)
	enddo !ista
c
	return
	end
c
c
	subroutine fill_bounds(x,imax,jmax,ii,jj,x_ob,
     &                           n_obs_b,badflag,mxstn,dum,d1)
c
c.....	Routine to fill the boundary of an array with values from a
c.....	wide-area Barnes analysis.
c
	real*4 x(imax,jmax),x_ob(mxstn),dum(imax,jmax),d1(imax,jmax)
	integer ii(mxstn), jj(mxstn)
c
	kdim = 5 	! radius of infl of 0.01 
	npass = 1
	call zero(dum,imax,jmax)
	call zero(d1,imax,jmax)
c
c.....	Call the wide-area Barnes.
c
	rom2 = 0.01
	call dynamic_wts(imax,jmax,0,rom2,d)
	call barnes_wide(dum,imax,jmax,ii,jj,x_ob,n_obs_b,badflag,
     &                   kdim,npass,d1) 
c
c.....	Copy the boundaries from the dummy array to the main array--if--
c.....	there isn't a station there already.
c
	do i=1,imax
	 if(x(i,1).eq.0. .or. x(i,1).eq.badflag) x(i,1) = dum(i,1)
	 if(x(i,jmax).eq.0..or.x(i,jmax).eq.badflag) 
     &                                     x(i,jmax) = dum(i,jmax)
	enddo !i
	do j=1,jmax
	 if(x(1,j).eq.0. .or. x(1,j).eq.badflag) x(1,j) = dum(1,j)
	 if(x(imax,j).eq.0..or.x(imax,j).eq.badflag) 
     &                                     x(imax,j) = dum(imax,j)
	enddo !j
c
	return
	end
c
c
	subroutine back_bounds(x,imax,jmax,dum)
c
c.....	Routine to fill the boundary of an array with values from an
c.....	earlier analysis...for when we have limited data.
c
	real*4 x(imax,jmax), dum(imax,jmax)
        parameter(badflag = -99.9)
c
c.....	Copy the boundaries from the dummy array to the main array--if--
c.....	there isn't a station there already.
c
	do i=1,imax
	 if(x(i,1).eq.0. .or. x(i,1).eq.badflag) x(i,1) = dum(i,1)
	 if(x(i,jmax).eq.0..or.x(i,jmax).eq.badflag) 
     &                                     x(i,jmax) = dum(i,jmax)
	enddo !i
	do j=1,jmax
	 if(x(1,j).eq.0. .or. x(1,j).eq.badflag) x(1,j) = dum(1,j)
	 if(x(imax,j).eq.0..or.x(imax,j).eq.badflag) 
     &                                     x(imax,j) = dum(imax,j)
	enddo !j
c
	return
	end
c
c
      subroutine splie2(x1a,x2a,ya,m,n,y2a)

c	15 May 1991  birkenheuer

      parameter (nn=200)
      dimension x1a(m),x2a(n),ya(m,n),y2a(m,n),ytmp(nn),y2tmp(nn)
      do 13 j=1,m
        do 11 k=1,n
          ytmp(k)=ya(j,k)
11      continue
        call spline_db(x2a,ytmp,n,1.e30,1.e30,y2tmp)
        do 12 k=1,n
          y2a(j,k)=y2tmp(k)
12      continue
13    continue
      return
      end
c
c
      subroutine splin2(x1a,x2a,ya,y2a,m,n,x1,x2,y)

c	15 May 1991 birkenheuer

      parameter (nn=200)
      dimension x1a(m),x2a(n),ya(m,n),y2a(m,n),ytmp(nn),y2tmp(nn),yytmp(
     1nn)
      do 12 j=1,m
        do 11 k=1,n
          ytmp(k)=ya(j,k)
          y2tmp(k)=y2a(j,k)
11      continue
        call splint(x2a,ytmp,y2tmp,n,x2,yytmp(j))
12    continue
      call spline_db(x1a,yytmp,m,1.e30,1.e30,y2tmp)
      call splint(x1a,yytmp,y2tmp,m,x1,y)
      return
      end
c
c
      subroutine spline_db(x,y,n,yp1,ypn,y2)

c	15 may 1991  birkenheuer

      parameter (nmax=200)
      dimension x(n),y(n),y2(n),u(nmax)
      if (yp1.gt..99e30) then
        y2(1)=0.
        u(1)=0.
      else
        y2(1)=-0.5
        u(1)=(3./(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
      endif
      do 11 i=2,n-1
        sig=(x(i)-x(i-1))/(x(i+1)-x(i-1))
        p=sig*y2(i-1)+2.
        y2(i)=(sig-1.)/p
        u(i)=(6.*((y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1))
     1      /(x(i)-x(i-1)))/(x(i+1)-x(i-1))-sig*u(i-1))/p
11    continue
      if (ypn.gt..99e30) then   ! test for overflow condition
        qn=0.
        un=0.
      else
        qn=0.5
        un=(3./(x(n)-x(n-1)))*(ypn-(y(n)-y(n-1))/(x(n)-x(n-1)))
      endif
      y2(n)=(un-qn*u(n-1))/(qn*y2(n-1)+1.)
      do 12 k=n-1,1,-1
        y2(k)=y2(k)*y2(k+1)+u(k)
12    continue
      return
      end
c
c
      subroutine splint(xa,ya,y2a,n,x,y)


c	15 May 1991 Birkenheuer

      dimension xa(n),ya(n),y2a(n)
      klo=1
      khi=n
1     if (khi-klo.gt.1) then
        k=(khi+klo)/2
        if(xa(k).gt.x)then
          khi=k
        else
          klo=k
        endif
      goto 1
      endif
      h=xa(khi)-xa(klo)
      if (h.eq.0.) pause 'bad xa input.'
      a=(xa(khi)-x)/h
      b=(x-xa(klo))/h
      y=a*ya(klo)+b*ya(khi)+
     1      ((a**3-a)*y2a(klo)+(b**3-b)*y2a(khi))*(h**2)/6.
      return
      end
