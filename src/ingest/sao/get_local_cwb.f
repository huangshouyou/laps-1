c
        subroutine get_local_cwb(maxobs,maxsta,i4time_sys,
     &                 path_to_local_data,local_format,
     &                 itime_before,itime_after,
     &                 eastg,westg,anorthg,southg,
     &                 lat,lon,ni,nj,grid_spacing,
     &                 nn,n_obs_g,n_obs_b,stations,
     &                 reptype,atype,weather,wmoid,
     &                 store_1,store_2,store_2ea,
     &                 store_3,store_3ea,store_4,store_4ea,
     &                 store_5,store_5ea,store_6,store_6ea,
     &                 store_7,store_cldht,store_cldamt,
     &                 provider, laps_cycle_time, jstatus)
c
	include 'netcdf.inc'
c
c.....  Input variables/arrays
c
        integer maxobs ! raw data file
        integer maxsta ! processed stations for LSO file
        character*(*) path_to_local_data, local_format
c
c.....  Local variables/arrays
c
	real lat(ni,nj), lon(ni,nj)
	real lats(maxobs), lons(maxobs), elev(maxobs)
        real t(maxobs), td(maxobs), rh(maxobs)
        real dd(maxobs), ff(maxobs)
        real sfcp(maxobs), pcp(maxobs)
        real rtime(maxobs)
        integer    wmoid(maxobs)
        integer*4  i4time_ob_a(maxobs), before, after
        character  provider(maxobs)*11
        character  weather(maxobs)*25
        character  reptype(maxobs)*6, atype(maxobs)*6
        character*9 a9time_before, a9time_after, a9time_a(maxobs)
        logical l_dupe(maxobs)
c
c.....  Output arrays
c
        real  store_1(maxsta,4), 
     &        store_2(maxsta,3), store_2ea(maxsta,3),
     &        store_3(maxsta,4), store_3ea(maxsta,2),
     &        store_4(maxsta,5), store_4ea(maxsta,2),
     &        store_5(maxsta,4), store_5ea(maxsta,4),
     &        store_6(maxsta,5), store_6ea(maxsta,2),
     &        store_7(maxsta,3),
     &        store_cldht(maxsta,5)

        character  stations(maxsta)*20
        character  store_cldamt(maxsta,5)*4
        character stname(maxsta)*5
c
c.....  Start.
c
c
c.....	Set jstatus flag for the local data to bad until we find otherwise.
c
	jstatus = -1

        call get_ibadflag(ibadflag,istatus)
        if(istatus .ne. 1)return

        call get_sfc_badflag(badflag,istatus)
        if(istatus .ne. 1)return

        call get_box_size(box_size,istatus)
        if(istatus .ne. 1)return

c.....  Figure out the size of the "box" in gridpoints.  User defines
c.....  the 'box_size' variable in degrees, then we convert that to an
c.....  average number of gridpoints based on the grid spacing.
c
        box_length = box_size * 111.137 !km/deg lat (close enough for lon)
        ibox_points = box_length / (grid_spacing / 1000.) !in km
c
c.....	Zero out the counters.
c
        n_obs_g = 0	        ! # of local obs in the laps grid
        n_obs_b = 0	        ! # of local obs in the box
c
c.....  Get the mesonet data.
c
        ix = 1
c
c.....  Set up the time window.
c
	before = i4time_sys - itime_before
	after  = i4time_sys + itime_after

!       Ob times contained in each file
        i4_contains_early = 0 
        i4_contains_late = 3599

        call get_filetime_range(before,after                
     1                         ,i4_contains_early,i4_contains_late       
     1                         ,3600                                     
     1                         ,i4time_file_b,i4time_file_a)              

        do i4time_file = i4time_file_a, i4time_file_b, -3600

            call read_tmeso_data(path_to_local_data,maxobs
     1                 ,badflag,ibadflag,i4time_file                     ! I
     1                 ,stname(ix)                                       ! O
     1                 ,lats(ix),lons(ix),elev(ix)                       ! O
     1                 ,i4time_ob_a(ix),t(ix),td(ix),rh(ix)              ! O
     1                 ,pcp(ix),sfcp(ix),dd(ix),ff(ix)                   ! O
     1                 ,num,istatus)                                     ! O

	    if(istatus .ne. 1)then
                write(6,*)
     1          '     Warning: bad status return from READ_LOCAL'       
                n_local_file = 0

            else
                n_local_file = num
                write(6,*)'     n_local_file = ',n_local_file

            endif

            ix = ix + n_local_file

        enddo ! i4time_file

        n_local_all = ix - 1
        write(6,*)' n_local_all = ',n_local_all
c
c
c..................................
c.....	First QC loop over all the obs.
c..................................
c
	do i=1,n_local_all
           l_dupe(i) = .false.
c
c........  Toss the ob if lat/lon/elev or observation time are bad by setting 
c........  lat to badflag (-99.9), which causes the bounds check to think that
c........  the ob is outside the LAPS domain.
	   if( nanf( lats(i) ) .eq. 1 ) lats(i)  = badflag
	   if( nanf( lons(i) ) .eq. 1 ) lats(i)  = badflag
	   if( nanf( elev(i) ) .eq. 1 ) lats(i)  = badflag

	   call make_fnam_lp(i4time_ob_a(i),a9time_a(i),istatus)

           call filter_string(stname(i))

           do k = 1,i-1
             if(       stname(i) .eq. stname(k) 
     1                          .AND.
     1           ( (.not. l_dupe(i)) .and. (.not. l_dupe(k)) )
     1                                                           )then
                 i_diff = abs(i4time_ob_a(i) - i4time_sys)
                 k_diff = abs(i4time_ob_a(k) - i4time_sys)

                 if(i_diff .ge. k_diff)then
                     i_reject = i
                 else
                     i_reject = k
                 endif

                 write(6,51)i,k,stname(i),a9time_a(i),a9time_a(k)
     1                     ,i_reject
 51		 format(' Duplicate detected ',2i6,1x,a6,1x,a9,1x,a9
     1                 ,1x,i6)

                 lats(i_reject) = badflag ! test with this for now

                 l_dupe(i_reject) = .true.
             endif
           enddo ! k
c
c
	   if( nanf( t(i)    ) .eq. 1 ) t(i)     = badflag
	   if( nanf( td(i)   ) .eq. 1 ) td(i)    = badflag
	   if( nanf( dd(i)   ) .eq. 1 ) dd(i)    = badflag
	   if( nanf( ff(i)   ) .eq. 1 ) ff(i)    = badflag
c
	enddo !i
c
c..................................
c.....	Second QC loop over all the obs.
c..................................
c
	jfirst = 1
	box_low = 1. - float(ibox_points)  !buffer on west/south side
	box_idir = float(ni + ibox_points) !buffer on east
	box_jdir = float(nj + ibox_points) !buffer on north

	do i=1,n_local_all
	   if(lats(i) .lt. -90.) go to 125	
	   call latlon_to_rlapsgrid(lats(i),lons(i),lat,lon,
     &                              ni,nj,ri_loc,rj_loc,istatus)
	   if(ri_loc.lt.box_low .or. ri_loc.gt.box_idir) go to 125
	   if(rj_loc.lt.box_low .or. rj_loc.gt.box_jdir) go to 125
c
c.....  Elevation ok?
c
	   if(elev(i) .eq. badflag) go to 125
	   if(elev(i).gt.5200. .or. elev(i).lt.-400.) go to 125
c
c.....  If you want to check the valid time, or if there are more than
c.....  one report from this station, put that here.
c

c          	
	   nn = nn + 1

           if(nn .gt. maxsta)then
              write(6,*)' ERROR in get_local_obs: increase maxsta '
     1                 ,nn,maxsta
              stop
           endif

	   n_obs_b = n_obs_b + 1
c
c.....  Check if its in the LAPS grid.
c
           if(ri_loc.lt.1 .or. ri_loc.gt.float(ni)) go to 151  !off grid
           if(rj_loc.lt.1 .or. rj_loc.gt.float(nj)) go to 151  !off grid
           n_obs_g = n_obs_g + 1                           !on grid...count it
151        continue
c
c.....  Fill expected accuracy arrays...see the 'get_metar_obs' routine for details.
c.....  Note that these values are only guesses based on US mesonet stations.
c
           store_2ea(nn,1) = 3.0             ! temperature (deg F)               
           store_2ea(nn,2) = 3.0             ! Dew point (deg F)               
           store_2ea(nn,3) = 30.0            ! Relative Humidity %
c
c..... Wind direction (deg) and speed (kts)
c
           store_3ea(nn,1) = 15.0            ! wind direction (dir)
           store_3ea(nn,2) = 6.0             ! wind speed (kt)

c..... Pressure and altimeter (mb)
c
           store_4ea(nn,1) = 2.00            ! pressure (mb)
           store_4ea(nn,2) = 0.00            ! altimeter (mb) (don't have)
c
c..... Other stuff (don't report these). 
c 
           store_5ea(nn,1) = 0.0             ! Visibility 
           store_5ea(nn,2) = 0.0             ! solar radiation       
           store_5ea(nn,3) = 0.0             ! soil/water temperature
           store_5ea(nn,4) = 0.0             ! soil moisture
c
           store_6ea(nn,1) = 0.0             ! precipitation (in)
           store_6ea(nn,2) = 0.0             ! snow cover (in) 
c
c
c.....  Clouds get set to zero, since don't have cloud info from these mesonets.
c
	   kkk = 0
c
c.....  Output the data to the storage arrays.
c
!    	  call s_len(stname(i), len)
!         stations(nn)(1:len) = stname(i)(1:len)

 	  call s_len(stname(i), len)
          if(len .ne. 0)then
              stations(nn)(1:len) = stname(i)(1:len) ! station name
          else
              write(6,*)' Warning in get_local_cwb: blank station name.'
     1                 ,' Assigning name ',i
              write(stations(nn),101)i
 101	      format(i5,15x)
          endif
c
	  atype(nn)(1:6) = 'MESONT'
c
	  reptype(nn)(1:6) = 'UNK   '
c
	  weather(nn)(1:25) = 'UNK                     '
	  provider(nn)(1:11) = 'CWB        '
	  wmoid(nn) = ibadflag
c 
	 store_1(nn,1) = lats(i)                ! station latitude
	 store_1(nn,2) = lons(i)                ! station longitude
	 store_1(nn,3) = elev(i)                ! station elevation (m)
	 store_1(nn,4) = rtime(i)               ! observation time
c	
	 store_2(nn,1) = t(i)                   ! temperature (deg F)
	 store_2(nn,1) = td(i)                  ! dew point (deg F)
	 store_2(nn,1) = rh(i)                  ! Relative Humidity
c
         store_3(nn,1) = dd(i)                  ! wind dir (deg)
         store_3(nn,2) = ff(i)                  ! wind speed (kt)
         store_3(nn,3) = badflag                ! wind gust dir (deg)
         store_3(nn,4) = badflag                ! wind gust speed (kt)
c
         store_4(nn,1) = badflag                ! altimeter setting (mb)
         store_4(nn,2) = sfcp(i)                ! station pressure (mb)
         store_4(nn,3) = badflag                ! MSL pressure (mb)
         store_4(nn,4) = badflag                ! 3-h press change character
         store_4(nn,5) = badflag                ! 3-h press change (mb)
c
         store_5(nn,1) = badflag                ! visibility (miles)
         store_5(nn,2) = badflag                ! solar radiation 
         store_5(nn,3) = badflag                ! soil/water temperature
         store_5(nn,4) = badflag                ! soil moisture 
c
         store_6(nn,1) = pcp(i)                 ! 1-h precipitation
         store_6(nn,2) = badflag                ! 3-h precipitation
         store_6(nn,3) = badflag                ! 6-h precipitation
         store_6(nn,4) = badflag                ! 24-h precipitation
         store_6(nn,5) = badflag                ! snow cover
c
         store_7(nn,1) = float(kkk)             ! number of cloud layers
         store_7(nn,2) = badflag                ! 24-h max temperature
         store_7(nn,3) = badflag                ! 24-h min temperature
c
c.....  That's it for this station.
c
 125     continue
       enddo !i
c
c.....  That's it...lets go home.
c
	 print *,' Found ',n_obs_b,' local obs in the LAPS box'
	 print *,' Found ',n_obs_g,' local obs in the LAPS grid'
         print *,' '
         jstatus = 1            ! everything's ok...
         return
c
 990     continue               ! no data available
         jstatus = 0
         print *,' WARNING: No data available from GET_LOCAL_CWB'
         return
c
         end

