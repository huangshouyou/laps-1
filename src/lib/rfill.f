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
        subroutine ref_fill_vert(ref_3d_io,ni,nj,nk
     1           ,l_low_fill,l_high_fill
     1           ,lat,lon,topo,heights_3d,rlat_radar,rlon_radar
     1           ,rheight_radar,istatus)

!       Called from read_radar_3dref, hence from (cloud/deriv/accum/lplot - 
!       if NOWRAD data is unavailable). Operates on V0x, but not VRC files.
!       This Routine Fills in the gaps in a 3D radar volume that has been
!       stored as a sparse array. A linear interpolation in the vertical
!       direction is used. An additional option 'l_low_fill' can be set to
!       .true.. This will fill in low level echoes that might have been
!       missed because the grid points are below the radar horizon or too
!       close to the terrain. This is done if radar echo is detected not
!       too far above such grid points. 
!
!       If the input column is entirely missing, so is the output column.
!       If there are QC flags set anywhere in the column, then the entire
!       output column is set to 'ref_base'. This implies that we are in the
!       zone of radar coverage and that "no echoes" is a good enough
!       characterization of the column.

!       Steve Albers            1990
!       Steve Albers            1992          Declare l_low_fill,l_high_fill
!       Steve Albers            1994          Set msg data to ref_base
!       Steve Albers            1998          Read in ref_base, r_missing_data
!            "              Feb 1998          Allows output of missing data

!       ni,nj,nk are input LAPS grid dimensions
!       rlat_radar,rlon_radar,rheight_radar are input radar coordinates

        real*4 ref_3d_io(ni,nj,nk)               ! I/O   3D reflctvy grid
        real*4 heights_3d(ni,nj,nk)              ! I
        real*4 lat(ni,nj),lon(ni,nj),topo(ni,nj) ! I     2D grids

        real*4 ref_3d(ni,nj,nk)                  ! Local 3D reflctvy grid
        integer*4 isum_ref_2d(ni,nj)             ! Local array

        logical l_low_fill, l_high_fill, l_test, l_nonmissing(ni,nj)       

        call get_r_missing_data(r_missing_data,istatus)
        if(istatus .ne. 1)then
            write(6,*)' ref_fill_vert: Error reading r_missing_data'       
            return
        endif

        call get_ref_base(ref_base,istatus)
        if(istatus .ne. 1)then
            write(6,*)' ref_fill_vert: Error reading ref_base'
            return
        endif

!       Set missing values to ref_base for internal & external processing
!       write(6,*)' ref_fill_vert: Setting r_missing_data/qc values to '
!    1             ,ref_base

        do k = 1,nk
        do j = 1,nj
        do i = 1,ni
            if(     ref_3d_io(i,j,k) .eq. -101.                 ! QC flags
     1         .or. ref_3d_io(i,j,k) .eq. -102.           )then
                ref_3d_io(i,j,k) = ref_base
            endif

            if(     ref_3d_io(i,j,k) .eq. r_missing_data  )then
                ref_3d(i,j,k) = ref_base
            else
                ref_3d(i,j,k) = ref_3d_io(i,j,k)
            endif
        enddo
        enddo
        enddo


        write(6,*)
     1       ' ref_fill_vert: Interpolating vertically through gaps'      

        n_low_fill = 0

        isum_test = nint(ref_base) * nk

        do j = 1,nj
        do i = 1,ni
            isum_ref_2d(i,j) = 0
        enddo
        enddo

        do i = 1,ni
        do j = 1,nj
            l_nonmissing(i,j) = .false.
            do k = 1,nk
                isum_ref_2d(i,j) = isum_ref_2d(i,j) 
     1                           + nint(ref_3d(i,j,k))
                if(ref_3d_io(i,j,k) .ne. r_missing_data)then
                    l_nonmissing(i,j) = .true.
                endif
            enddo
        enddo
        enddo

        if(l_low_fill)then
          if(lat(1,1) .eq. 0. .or. lon(1,1)  .eq. 0.
     1                        .or. topo(1,1) .eq. r_missing_data)then
            write(6,*)' Error in ref_fill_vert:'
     1               ,' lat/lon/topo has invalid value'
            istatus = 0
            return
          endif
        endif

        do j = 1,nj
c       write(6,*)' Doing Column ',j

        do i = 1,ni

          if(isum_ref_2d(i,j) .ne. isum_test)then ! Test for presence of echo

            call latlon_to_radar(lat(i,j),lon(i,j),topo(i,j)
     1                  ,azimuth,slant_range,elev_topo
     1                  ,rlat_radar,rlon_radar,rheight_radar)

            if(l_high_fill)then ! Fill in between high level echoes
                k = 1

!               Test for presence of top
15              l_test = .false.
                ref_below = ref_3d(i,j,k)

                do while (k .lt. nk .and. (.not. l_test))
                    ref_above = ref_3d(i,j,k+1)

                    if(ref_below .gt. ref_base
     1         .and. ref_above .eq. ref_base)then
                        k_top = k
                        l_test = .true.
                    endif

                    k = k + 1
                    ref_below = ref_above

                enddo

                if(.not. l_test)goto100 ! No Top exists

!               Top exists, Search for next bottom
                l_test = .false.
                ref_below = ref_3d(i,j,k)

                do while(k .lt. nk .and. (.not. l_test))
                    k = k + 1
                    ref_above = ref_3d(i,j,k)

                    if(ref_above .gt. ref_base
     1           .and. ref_below .eq. ref_base)then
                        k_bottom = k
                        l_test = .true.
                    endif

                    ref_below = ref_above

                enddo

                if(.not. l_test)goto100 ! No Bottom exists

!               Fill in gap if it exists and is small enough
                gap_thresh = 2000.
                if(heights_3d(i,j,k_bottom) .lt.
     1                    heights_3d(i,j,k_top) + gap_thresh)then

!               if(k_bottom .le. k_top+5)then ! Fill gaps smaller than const-1

c                   write(6,*)' Filling gap between',i,j,k_bottom,k_top
c                   write(6,101)(nint(max(ref_3d(i,j,kwrt),ref_base)),kwrt=1,nk)
101                 format(1x,17i4)

                    do k_bet = k_top+1,k_bottom-1
                        frac = float(k_bet-k_bottom)
     1                        /float(k_top-k_bottom)
                        ref_3d(i,j,k_bet) =
     1                              ref_3d(i,j,k_bottom)*(1.-frac)
     1                            + ref_3d(i,j,k_top)*(frac)
                    enddo ! k

c                   write(6,101)(nint(max(ref_3d(i,j,kwrt),ref_base)),kwrt=1,nk)

                endif

                if(k .le. nk-2)then ! Look for another gap
                    goto15
                endif

            endif ! l_high_fill

100         if(l_low_fill)then ! Fill below low level echoes

!               Search for bottom
                k_bottom = 0
                l_test = .false.

                k = 2

                ref_below = ref_3d(i,j,1)

                do while((.not. l_test) .and. k .le. nk)
                    ref_above = ref_3d(i,j,k)

                    if(ref_above .gt. ref_base
     1           .and. ref_below .eq. ref_base)then
                        k_bottom = k
                        dbz_bottom = ref_above
                        l_test = .true.
                    endif

                    k = k + 1
                    ref_below = ref_above

                enddo

                istatus = 1

                k_topo = max(int(height_to_zcoord(topo(i,j),istatus)),1)

                topo_buffer = topo(i,j) + 800.
                k_topo_buffer =
     1              max(int(height_to_zcoord(topo_buffer,istatus)),1)

                if(istatus .ne. 1)then
                    write(6,*)' ERROR return in ref_fill_vert'
                    return
                endif

                if(k_bottom .gt. k_topo)then ! Echo above ground

                    height_bottom = height_of_level(k_bottom)

                    call latlon_to_radar(lat(i,j),lon(i,j),height_bottom
     1                  ,azimuth,slant_range,elev_bottom
     1                  ,rlat_radar,rlon_radar,rheight_radar)

                    if(k_bottom .le. k_topo_buffer ! Echo base near ground
!    1       .or. elev_bottom .lt. (elev_topo + 1.5) ! Echo below radar horizon
     1                 .or. elev_bottom .lt. 1.5 ! Echo base near radar horizon
     1                                                          )then ! Fill in
                        do k = k_topo,k_bottom ! -1
                            ref_3d(i,j,k) = ref_3d(i,j,k_bottom)
                        enddo ! k

!                       write(6,211)i,j,k_topo,k_bottom,elev_topo,elev_bottom
!       1                       ,slant_range,ref_3d(i,j,k_bottom)
211                     format(' low fill ',4i5,2f6.1,2f8.0)

                        n_low_fill = n_low_fill + 1

                    endif ! Fill in from ground to bottom of echo

                endif ! Bottom of radar echo above ground

            endif ! l_low_fill


          endif ! echo present

!         Return valid ref values to io array
          if(l_nonmissing(i,j))then 
              do k = 1,nk
                  ref_3d_io(i,j,k) = ref_3d(i,j,k)
              enddo ! k
          endif ! We have non-missing reflectivity values in the column

        enddo ! i
        enddo ! j

        write(6,*)' n_low_fill = ',n_low_fill

        istatus = 1
        return

!       This section is under construction - new formulation
        i_low_fill = 0
        if(slant_range .lt. 24000.)then ! find nearest level containing data
            do kdelt = 0,nk
            do i_sign = -1,+1,2
                k = k_topo_buffer + i_sign*kdelt
                if(k .ge. k_topo .and. k .le. nk .and.
     1             ref_3d(i,j,k) .ne. ref_base            )then
                    k_bottom = k
                    i_low_fill = 1
                    go to 200
                endif
            enddo ! i_sign
            enddo ! kdelt

 200        continue

        else ! slant_range > 24000.
             ! Pick lowest altitude > 500m agl having ref > 0 dbz 
             ! and elev_angle < 2.0 deg (0.5 or 1.5)

        endif

        return
        end

