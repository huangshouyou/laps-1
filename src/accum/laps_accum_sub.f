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

        subroutine laps_accum(i4time,
     1                        NX_L,NY_L,NZ_L,
     1                        i_diag,
     1                        n_prods,
     1                        iprod_number,
     1                        j_status)

!       1991            Steve Albers
!       1996 May        Steve Albers  Call 'get_laps_cycle_time'
!                                     Use 'ilaps_cycle_time' to calculate
!                                     'precip_reset_thresh'.
!       1997 Mar        Steve Albers  Added calls to 'move' to replace 
!                                     equivalencing.
!       1997 Jun        Ken Dritz     Made NX_L, NY_L, NZ_L dummy arguments,
!                                     making non-dummy arrays dimensioned
!                                     therewith dynamic (automatic).
!       1997 Jun        Ken Dritz     Changed include of lapsparms.for to
!                                     include of laps_static_parameters.inc.

        integer*4  ss_normal,rtsys_bad_prod,rtsys_no_data
     1                                     ,rtsys_abort_prod
        parameter (ss_normal        =1, ! success
     1             rtsys_bad_prod   =2, ! inappropriate data, insufficient data
     1             rtsys_no_data    =3, ! no data
     1             rtsys_abort_prod =4) ! failed to make a prod

        include 'laps_static_parameters.inc'

        integer*4 i4time,i_diag,n_prods

        real*4 lat(NX_L,NY_L),lon(NX_L,NY_L)
        real*4 topo(NX_L,NY_L)

        real*4 snow_2d(NX_L,NY_L)
        real*4 snow_2d_tot(NX_L,NY_L)

        real*4 precip_2d(NX_L,NY_L)
        real*4 precip_2d_tot(NX_L,NY_L)

        real*4 field_2d(NX_L,NY_L,4)

        real*4 precip_type_2d(NX_L,NY_L)

        character*9 filename, filename_start

        character*13 filename13

        character*31  radarext_3d_accum

        character var*3,comment*125,directory*150,ext*31,units*10

        character*125 comment_s,comment_r

        character*80 c80_domain_file

        integer*4 j_status(20),iprod_number(20)

        character*40 c_vars_req
        character*100 c_values_req

        ISTAT = INIT_TIMER()

        write(6,*)' Welcome to the LAPS gridded snow/precip accum analys
     1is'

        c_vars_req = 'radarext_3d_accum'

        call get_static_info(c_vars_req,c_values_req,1,istatus)

        if(istatus .eq. 1)then
            radarext_3d_accum = c_values_req(1:3)
        else
            write(6,*)' Error getting radarext_3d_accum'
            return
        endif

        write(6,*)' radarext_3d_accum = ',radarext_3d_accum

c read in laps lat/lon and topo
        call get_laps_domain(NX_L,NY_L,LAPS_DOMAIN_FILE,lat,lon,topo,ist
     1atus)
        if(istatus .eq. 0)then
            write(6,*)' Error getting LAPS domain'
            return
        endif

        call get_laps_cycle_time(ilaps_cycle_time,istatus)
        if(istatus .eq. 1)then
            write(6,*)' ilaps_cycle_time = ',ilaps_cycle_time
        else
            write(6,*)' Error getting laps_cycle_time'
            return
        endif

        n_prods = 1

        do i = 1,n_prods
            j_status(i) = rtsys_abort_prod
        enddo

        n_l1s = 1

        ext = 'l1s'

        if(ext(1:3) .ne. 'l1s')then
            iprod_number(n_l1s) = 36352 ! L1S
        else
            iprod_number(n_l1s) = 27280 ! S1S
        endif

!       Get Incremental Accumulations from Radar Data & Update Storm Totals
!       i_wait = ilaps_cycle_time / 270
        i_wait = 0

        istatus_inc = 1

        i4time_end = i4time
        i4time_beg = i4time_end - ilaps_cycle_time

        minutes = ilaps_cycle_time / 60

        write(6,*)' Getting Snow/Precip Accumulation over ',minutes,' mi
     1n'
50      call get_precip_accum(i4time_beg,i4time_end,NX_L,NY_L,NZ_L
     1          ,lat,lon,topo,ilaps_cycle_time
     1          ,radarext_3d_accum                     ! Input
     1          ,snow_2d,precip_2d,frac_sum,istatus_inc)

        if(istatus_inc .ne. 1)then ! Decide whether to wait for radar data
            if(i_wait .gt. 0 .and. frac_sum .ge. 0.30)then
                write(6,*)' Waiting 2 min for possible radar data',frac_
     1sum
                call snooze_gg(120.0,istat_snooze)
                i_wait = i_wait - 1
                goto50
            endif
        endif

        comment_r = '           Null Comment'
        comment_s = '           Null Comment'

!       Get storm total from previous analysis cycle
        if(istatus_inc .eq. 1)then
            write(6,*)' Getting Previous Storm Total Accumulations'
            ext = 'l1s'
            var = 'STO'
            call get_laps_2d(i4time-ilaps_cycle_time,ext,var,units
     1                    ,comment_s,NX_L,NY_L,snow_2d_tot,istatus_tot)

            if(istatus_tot .eq. 1)then
                var = 'RTO'
                call get_laps_2d(i4time-ilaps_cycle_time,ext,var,units
     1                  ,comment_r,NX_L,NY_L,precip_2d_tot,istatus_tot)
            endif
        endif

!       Set rate threshold based on length of storm total so far 
        rate_thresh = .0001
        filename_start = comment_r(1:9)

        call i4time_fname_lp(filename_start, i4time_start, istatus)
        if(istatus .ne. 1)then
            write(6,*)' Could not get start time for storm total'
     1                 ,comment_r
            i4_total = ilaps_cycle_time
            istatus_tot = 0

        else ! Valid storm total start time in comment
            i4_total = i4time - i4time_start
            if(i4_total .gt. 48*3600)then
                rate_thresh = .001
            endif
        endif

        write(6,*)i4_total/3600,' hours storm total, rate_thresh = '
     1                                              ,rate_thresh

!       Decide whether to reset Storm Total based on insignificant precip over
!       current cycle time
        i_suff_pcp = 0

        precip_reset_thresh = 
     1                  rate_thresh * float(ilaps_cycle_time) / 3600.

        if(istatus_inc .eq. 1 .and. istatus_tot .eq. 1)then
            precip_max = 0.
            do j = 1,NY_L
            do i = 1,NX_L
                precip_max = max(precip_max,precip_2d(i,j))
                if(precip_2d(i,j) .gt. precip_reset_thresh)then    
                    i_suff_pcp = 1
                endif
            enddo ! i
            enddo ! j
            write(6,*)' Max precip over domain = ',precip_max
            if(i_suff_pcp .eq. 0)then
                write(6,*)' Resetting due to insufficient precip'
            else
                write(6,*)
     1          ' We have sufficient precip to continue storm total'
            endif
        endif


!       Add current hour snow accumulation to storm total
        if(istatus_inc .eq. 1 .and. istatus_tot .eq. 1
     1                        .and. i_suff_pcp  .eq. 1)then
            write(6,*)' Adding latest increment for new Storm Total Accu
     1mulation'
            call add(snow_2d,  snow_2d_tot,  snow_2d_tot,  NX_L,NY_L)
            call add(precip_2d,precip_2d_tot,precip_2d_tot,NX_L,NY_L)

        elseif(istatus_inc .eq. 1)then
            write(6,*)' Resetting Storm Total Accumulations to ',minutes
     1,
     1        ' min values'

!           Put the new reset time in the file header
            call make_fnam_lp(i4time-ilaps_cycle_time,filename,istatus)
            comment_s = filename//' Time that storm total snow begins at
     1.'
            comment_r = filename//' Time that storm total precip begins 
     1at.'

            call move(snow_2d  ,snow_2d_tot  ,NX_L,NY_L)
            call move(precip_2d,precip_2d_tot,NX_L,NY_L)

        endif ! Valid continuation of storm total

        if(istatus_inc .eq. 1)then
            write(6,*)' Writing Incr / Storm Total Accumulations'
            write(6,*)comment_r(1:80)
            write(6,*)comment_s(1:80)
            ext = 'l1s'
            call get_directory(ext,directory,len_dir)
            units = 'M'

            call move(snow_2d,      field_2d(1,1,1),NX_L,NY_L)
            call move(snow_2d_tot,  field_2d(1,1,2),NX_L,NY_L)
            call move(precip_2d,    field_2d(1,1,3),NX_L,NY_L)
            call move(precip_2d_tot,field_2d(1,1,4),NX_L,NY_L)

            call put_precip_2d(i4time,directory,ext,var,units
     1       ,comment_s,comment_r,NX_L,NY_L,field_2d,ilaps_cycle_time
     1       ,istatus)
            if(istatus .eq. 1)j_status(n_l1s) = ss_normal

        else
            write(6,*)' Not Writing Incr / Storm Total Accumulations'
            j_status(n_l1s) = rtsys_no_data

        endif

        I4_elapsed = ishow_timer()

999     continue

        return
        end


        subroutine put_precip_2d(i4time,DIRECTORY,EXT,var,units,
     1                  comment_s,comment_r,imax,jmax,field_2dsnow
     1                                          ,ilaps_cycle_time
     1                                                  ,istatus)

        integer*4 nfields
        parameter (nfields = 4)

        character*(*) DIRECTORY
        character*31 EXT

        character*125 comment_s,comment_r,comment_2d(nfields)
        character*10 units,units_2d(nfields)
        character*3 var,var_2d(nfields)
        integer*4 LVL,LVL_2d(nfields)
        character*4 LVL_COORD,LVL_COORD_2d(nfields)

        real*4 field_2dsnow(imax,jmax,nfields)

        lend = len(directory)
        write(6,11)directory(1:lend),ext(1:5)
11      format(' Writing 2d Snow/Precip ',a<lend>,1x,a5,1x,a3)

        lvl = 0
        lvl_coord = 'MSL'

        var_2d(1) = 'S01'
        var_2d(2) = 'STO'
        var_2d(3) = 'R01'
        var_2d(4) = 'RTO'

        minutes = ilaps_cycle_time/60

        write(comment_2d(1),21)minutes
21      format('LAPS',i3,' Minute Snow Accumulation')

        comment_2d(2) = comment_s

        write(comment_2d(3),22)minutes
22      format('LAPS',i3,' Minute Precip Accumulation')

        comment_2d(4) = comment_r

        do k = 1,nfields
            LVL_2d(k) = LVL
            LVL_Coord_2d(k) = LVL_Coord
            UNITS_2d(k) = 'M'
        enddo

        CALL WRITE_LAPS_DATA(I4TIME,DIRECTORY,EXT,imax,jmax,
     1  nfields,nfields,VAR_2D,LVL_2D,LVL_COORD_2D,UNITS_2D,
     1                     COMMENT_2D,field_2dsnow,ISTATUS)

        return
        end
