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

        subroutine get_laps_domain(ni,nj,grid_fnam,lat,lon,topo,istatus)

!       1992 Steve Albers
c
c  get maps grid information
c
c   lat() contains grid latitudes (degrees north)
c   lon() contains grid longitudes (degrees east; negative=west long.)
c   topo() contains grid elevations (m)
c
        integer*4 ni,nj              ! Input

        real*4 lat(ni,nj)            ! Output
        real*4 lon(ni,nj)            ! Output
        real*4 topo(ni,nj)           ! Output

        character*(*) grid_fnam      ! Input

        character*3 var
        character*50  directory
        character*31  ext
        character*10  units
        character*125 comment

        character*80 grid_fnam_common
        common / grid_fnam_cmn / grid_fnam_common
c
        write(6,*)'    Reading in lat/lon/topo ',grid_fnam

        grid_fnam_common = grid_fnam  ! Used in get_directory to modify
                                      ! extension based on the grid domain

        ext = grid_fnam

!       Get the location of the static grid directory
        call get_directory(ext,directory,len_dir)

!       directory = ''

        var = 'LAT'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                 ,lat,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAT field'
            return
        endif

        var = 'LON'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,lon,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LON field'
            return
        endif

        var = 'AVG'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,topo,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading AVG (topo) field'
            return
        endif

c       write(6,*)' LAT/LON Corner > ',lat(   1,   1),lon(   1,   1)
c       write(6,*)' LAT/LON Corner > ',lat(   1,nj),lon(   1,nj)
c       write(6,*)' LAT/LON Corner > ',lat(ni,   1),lon(ni,   1)
c       write(6,*)' LAT/LON Corner > ',lat(ni,nj),lon(ni,nj)

        call get_laps_config(grid_fnam,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error in get_laps_config'
            return
        endif

        call check_domain(lat,lon,ni,nj,grid_spacing_m,5,istat_chk)
        if(istat_chk .ne. 1)then
            write(6,*)' Warning or Error in check_domain'
        endif

        return

        end


        subroutine get_domain_laps(ni,nj,grid_fnam,lat,lon,topo
     1                             ,grid_spacing_m,istatus)

!       1994 Steve Albers
c
c  get maps grid information
c
c   lat() contains grid latitudes (degrees north)
c   lon() contains grid longitudes (degrees east; negative=west long.)
c   topo() contains grid elevations (m)
c
        integer*4 ni,nj              ! Input

        real*4 lat(ni,nj)            ! Output
        real*4 lon(ni,nj)            ! Output
        real*4 topo(ni,nj)           ! Output

        character*(*) grid_fnam      ! Input

        character*3 var
        character*50  directory
        character*31  ext
        character*10  units
        character*125 comment

        character*80 grid_fnam_common
        common / grid_fnam_cmn / grid_fnam_common

c
        write(6,*)'    Reading in lat/lon/topo ',grid_fnam

        grid_fnam_common = grid_fnam  ! Used in get_directory to modify
                                      ! extension based on the grid domain

        ext = grid_fnam

!       Get the location of the static grid directory
        call get_directory(ext,directory,len_dir)

!       directory = ''

        var = 'LAT'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                 ,lat,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAT field'
            return
        endif

        var = 'LON'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,lon,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LON field'
            return
        endif

        var = 'AVG'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,topo,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading AVG (topo) field'
            return
        endif

c       write(6,*)' LAT/LON Corner > ',lat(   1,   1),lon(   1,   1)
c       write(6,*)' LAT/LON Corner > ',lat(   1,nj),lon(   1,nj)
c       write(6,*)' LAT/LON Corner > ',lat(ni,   1),lon(ni,   1)
c       write(6,*)' LAT/LON Corner > ',lat(ni,nj),lon(ni,nj)

        call get_laps_config(grid_fnam,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error in get_laps_config'
            return
        endif

        call check_domain(lat,lon,ni,nj,grid_spacing_m,5,istat_chk)
        if(istat_chk .ne. 1)then
            write(6,*)' Warning or Error in check_domain'
        endif

        return

        end



        subroutine get_laps_domain_95(ni,nj,grid_fnam,lat,lon,topo
     1            ,rlaps_land_frac,grid_spacing_m,istatus)

!       1994 Steve Albers
c
c  get maps grid information
c
c   lat() contains grid latitudes (degrees north)
c   lon() contains grid longitudes (degrees east; negative=west long.)
c   topo() contains grid elevations (m)
c
        integer*4 ni,nj              ! Input

        real*4 lat(ni,nj)            ! Output
        real*4 lon(ni,nj)            ! Output
        real*4 topo(ni,nj)           ! Output
        real*4 rlaps_land_frac(ni,nj) ! Output

        character*(*) grid_fnam      ! Input

        character*3 var
        character*50  directory
        character*31  ext
        character*10  units
        character*125 comment

        character*80 grid_fnam_common
        common / grid_fnam_cmn / grid_fnam_common
c
        write(6,*)'    Reading in lat/lon/topo/land frac ',grid_fnam

        grid_fnam_common = grid_fnam  ! Used in get_directory to modify
                                      ! extension based on the grid domain

        ext = grid_fnam

!       Get the location of the static grid directory
        call get_directory(ext,directory,len_dir)

!       directory = ''

        var = 'LAT'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                 ,lat,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAT field'
            return
        endif

        var = 'LON'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,lon,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LON field'
            return
        endif

        var = 'AVG'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                                  ,topo,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading AVG (topo) field'
            return
        endif

        var = 'LDF'
        call rd_laps_static(directory,ext,ni,nj,1,var,units,comment
     1                 ,rlaps_land_frac,grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LDF (land fraction) field'
            return
        endif

c       write(6,*)' LAT/LON Corner > ',lat(   1,   1),lon(   1,   1)
c       write(6,*)' LAT/LON Corner > ',lat(   1,nj),lon(   1,nj)
c       write(6,*)' LAT/LON Corner > ',lat(ni,   1),lon(ni,   1)
c       write(6,*)' LAT/LON Corner > ',lat(ni,nj),lon(ni,nj)


        do i = 1,ni
        do j = 1,nj
            if(rlaps_land_frac(i,j) .le. 0.5)then
                rlaps_land_frac(i,j) = 0.           ! Water
            else
                rlaps_land_frac(i,j) = 1.           ! Land
            endif
        enddo
        enddo

        call get_laps_config(grid_fnam,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error in get_laps_config'
            return
        endif

        call check_domain(lat,lon,ni,nj,grid_spacing_m,5,istat_chk)
        if(istat_chk .ne. 1)then
            write(6,*)' Warning or Error in check_domain'
        endif

        return

        end

!********* THE PORTION ABOVE IS THE SAME IN OLDLAPS AND NEWLAPS **************

        subroutine get_laps_config(grid_fnam,istatus)

!       1992 Steve Albers
!       Read in parameters from parameter file

        character*(*) grid_fnam   ! Input (Warning: trailing blanks won't work)
        character*150  directory
        character*31  ext
        character*8 a8
        character*200 tempchar

        character*80 grid_fnam_common
        common / grid_fnam_cmn / grid_fnam_common

        include 'lapsparms.cmn'

        NAMELIST /lapsparms_NL/ iflag_lapsparms_cmn
     1  ,PRESSURE_BOTTOM_L,PRESSURE_INTERVAL_L,PRESSURE_0_L
     1  ,vertical_grid,nk_laps,standard_latitude,standard_latitude2
     1  ,standard_longitude,NX_L_CMN, NY_L_CMN, I_PERIMETER_CMN
     1  ,c50_lowres_directory,c6_maproj
     1  ,l_highres,l_pad1,l_pad2,l_pad3
     1  ,grid_spacing_m_cmn,grid_cen_lat_cmn,grid_cen_lon_cmn
     1  ,laps_cycle_time_cmn
     1  ,i_delta_sat_t_sec_cmn,r_msng_sat_flag_cdf_cmn
     1  ,radarext_3d_cmn,radarext_3d_accum_cmn
     1  ,path_to_raw_pirep_cmn
     1  ,path_to_raw_rass_cmn,path_to_raw_profiler_cmn
     1  ,path_to_raw_blprass_cmn,path_to_raw_blpprofiler_cmn
     1  ,path_to_raw_satellite_cdf_cmn,path_to_raw_satellite_gvr_cmn
     1  ,path_to_ruc_cmn,path_to_ngm_cmn
     1  ,path_to_wsi_2d_radar_cmn,path_to_wsi_3d_radar_cmn
     1  ,path_to_qc_acars_cmn,path_to_raw_raob_cmn
     1  ,path_to_metar_data_cmn,path_to_local_data_cmn
     1  ,r_msng_sat_flag_gvr_cmn,r_msng_sat_flag_asc_cmn
     1  ,path_to_raw_sat_wfo_vis_cmn,path_to_raw_sat_wfo_i39_cmn
     1  ,path_to_raw_sat_wfo_iwv_cmn,path_to_raw_sat_wfo_i11_cmn
     1  ,path_to_raw_sat_wfo_i12_cmn
     1  ,i2_missing_data_cmn, r_missing_data_cmn, MAX_RADARS_CMN
     1  ,ref_base_cmn,ref_base_useable_cmn,maxstns_cmn,N_PIREP_CMN
     1  ,vert_rad_meso_cmn,vert_rad_sao_cmn
     1  ,vert_rad_pirep_cmn,vert_rad_prof_cmn     
     1  ,silavwt_parm_cmn,toptwvl_parm_cmn,c8_project_common
     1  ,laps_background_model_cmn
     1  ,maxstations_cmn,maxobs_cmn
     1  ,c_raddat_type, c80_description


        if(iflag_lapsparms_cmn .eq. 1)goto999

!       While we are here, let's put the grid name into the common area
        grid_fnam_common = grid_fnam  ! Used in get_directory to modify
                                      ! extension based on the grid domain

!       Get the location of the parameter directory
        ext = grid_fnam
        call get_directory(ext,directory,len_dir)
        if(directory(len_dir:len_dir).ne.'/') then
          tempchar = directory(1:len_dir)//'/'//grid_fnam//'.parms'
        else
          tempchar = directory(1:len_dir)//grid_fnam//'.parms'
        endif
        call s_len(tempchar,len_dir)
 
        open(92,file=tempchar(1:len_dir),status='old',err=900)
        inquire(unit=92,read=a8)
        print*, a8
        read(92,lapsparms_nl,err=910)
         print *,'here ',iflag_lapsparms_cmn

1       format(a)
2       format(a6)
3       format(//a)

        if(iflag_lapsparms_cmn .ne. 1)goto910

        PRESSURE_0_L = PRESSURE_BOTTOM_L + PRESSURE_INTERVAL_L

        write(6,*)' get_laps_config - parameters read in OK'

        goto999

900     write(6,*)' Open error in get_laps_config, parameter file not fo
     1und'
        write(6,*)tempchar
        iflag_lapsparms_cmn = 0
        istatus = 0
        close(92)
        return

910     write(6,*)' Read error in get_laps_config'
        write(6,*)' Check runtime parameter file ',tempchar
        close(92)
        iflag_lapsparms_cmn = 0
        istatus = 0
        return

920     write(6,*)' Read error in get_laps_config'
        write(6,*)' Truncated runtime parameter file ',tempchar
        close(92)
        iflag_lapsparms_cmn = 0
        istatus = 0
        return

999     close(92)

!       Obtain standard_latitude and standard_longitude, maproj from static file
!       if(istatus_static .ne. 1)then
!           iflag_lapsparms_cmn = 0
!           istatus = 0
!           return
!       endif

!       c6_maproj = 'plrstr'
!       c6_maproj = 'lmbrt1'

        istatus = 1
        return

        end

c        block data
c        include 'lapsparms.cmn'
c        data iflag_lapsparms_cmn /0/
c        end

!********* THE PORTION BELOW IS THE SAME IN OLDLAPS AND NEWLAPS **************

      subroutine get_standard_longitude(std_lon,istatus)

      include 'lapsparms.cmn' ! standard_longitude

!     This routine accesses the standard_longitude variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      std_lon = standard_longitude

      istatus = 1
      return
      end


      subroutine get_grid_spacing(grid_spacing_m,istatus)

      include 'lapsparms.cmn' ! grid_spacing_m_cmn

!     This routine accesses the standard_longitude variable from the
!     .parms file via the common block.

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      grid_spacing_m = grid_spacing_m_cmn

      istatus = 1
      return
      end


      subroutine get_grid_center(grid_cen_lat,grid_cen_lon,istatus)

      include 'lapsparms.cmn' ! grid_spacing_m_cmn

!     This routine accesses the standard_longitude variable from the
!     .parms file via the common block.

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      grid_cen_lat = grid_cen_lat_cmn
      grid_cen_lon = grid_cen_lon_cmn

      istatus = 1
      return
      end

      subroutine get_standard_latitude(std_lat,istatus)

      include 'lapsparms.cmn' ! standard_latitude

!     This routine accesses the standard_latitude variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      std_lat = standard_latitude

      istatus = 1
      return
      end


      subroutine get_standard_latitudes(std_lat1,std_lat2,istatus)

      include 'lapsparms.cmn' ! standard_latitude, standard_latitude2

!     This routine accesses the standard_latitude variables from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      std_lat1 = standard_latitude
      std_lat2 = standard_latitude2

      istatus = 1
      return
      end


      subroutine get_maxstns(maxstns,istatus)

      include 'lapsparms.cmn' ! maxstns_cmn

!     This routine accesses the maxstns_cmn variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      maxstns = maxstns_cmn

      istatus = 1
      return
      end


      subroutine get_c8_project(c8_project,istatus)

      include 'lapsparms.cmn' ! c8_project

      character*8 c8_project

!     This routine accesses the c8_project_common variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      c8_project = c8_project_common

      istatus = 1
      return
      end


      subroutine get_c6_maproj(c6_maproj_ret,istatus)

      include 'lapsparms.cmn' ! c6_maproj

      character*6 c6_maproj_ret

!     This routine accesses the c6_maproj variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      c6_maproj_ret = c6_maproj

      istatus = 1
      return
      end


      subroutine get_c80_description(c80_description_ret,istatus)

      include 'lapsparms.cmn' ! c80_description

      character*80 c80_description_ret
!     This routine accesses the c80_description variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      c80_description_ret = c80_description

      istatus = 1
      return
      end


      subroutine get_laps_dimensions(nk,istatus)

      include 'lapsparms.cmn'              ! nk_laps

!     This routine accesses the nk variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' get_laps_dimensions: calling get_laps_config'

          call get_laps_config('nest7grid',istatus)
          if(istatus .ne. 1 .or. iflag_lapsparms_cmn .ne. 1)then
              write(6,*)' Error detected in calling get_laps_config'
              istatus = 0
              return
          else
              write(6,*)' Success in calling get_laps_config'
          endif

      endif

      nk = nk_laps

      istatus = 1
      return
      end


      subroutine get_laps_cycle_time(laps_cycle_time,istatus)

      include 'lapsparms.cmn'              ! laps_cycle_time_cmn

!     This routine accesses the laps_cycle_time variable from the
!     .parms file via the common block. Note the variable name in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' get_laps_cycle_time: calling get_laps_config'

          call get_laps_config('nest7grid',istatus)
          if(istatus .ne. 1 .or. iflag_lapsparms_cmn .ne. 1)then
              write(6,*)' Error detected in calling get_laps_config'
              istatus = 0
              return
          else
              write(6,*)' Success in calling get_laps_config'
          endif

      endif

      laps_cycle_time = laps_cycle_time_cmn

      istatus = 1
      return
      end


      subroutine get_grid_dim_xy(NX_L,NY_L,istatus)

      include 'lapsparms.cmn'              ! NX_L_CMN, NY_L_CMN

!     This routine accesses the NX_L and NY_L variables from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' get_grid_dim_xy: calling get_laps_config'

          call get_laps_config('nest7grid',istatus)
          if(istatus .ne. 1 .or. iflag_lapsparms_cmn .ne. 1)then
              write(6,*)' Error detected in calling get_laps_config'
              istatus = 0
              return
          else
              write(6,*)' Success in calling get_laps_config'
          endif

      endif

      NX_L = NX_L_CMN
      NY_L = NY_L_CMN

      istatus = 1
      return
      end

      subroutine get_topo_parms(silavwt_parm,toptwvl_parm,istatus)

      include 'lapsparms.cmn' ! silavwt_cmn, toptwvl_cmn

!     This routine accesses the silavwt_parm and toptwvl_parm
!     variables from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' get_topo_parms: calling get_laps_config'

          call get_laps_config('nest7grid',istatus)
          if(istatus .ne. 1 .or. iflag_lapsparms_cmn .ne. 1)then
              write(6,*)' Error detected in calling get_laps_config'
              istatus = 0
              return
          else
              write(6,*)' Success in calling get_laps_config'
          endif

      endif

      silavwt_parm = silavwt_parm_cmn
      toptwvl_parm = toptwvl_parm_cmn

      istatus = 1
      return
      end

      subroutine get_meso_sao_pirep(n_meso,n_sao,n_pirep,istatus)

      include 'lapsparms.cmn' ! maxstns_cmn, n_pirep_cmn

!     This routine accesses the maxstns and n_pirep
!     variables from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      n_meso  = maxstns_cmn
      n_sao   = maxstns_cmn
      n_pirep = n_pirep_cmn

      istatus = 1
      return
      end

      subroutine get_max_radars (max_radars, istatus)

      include 'lapsparms.cmn' ! max_radars_cmn

!     This routine accesses the max_radars variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      max_radars = max_radars_cmn

      istatus = 1
      return
      end

      subroutine get_max_stations (maxstns, istatus)

      include 'lapsparms.cmn' ! maxstns_cmn

!     This routine accesses the maxstns variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      maxstns = maxstns_cmn

      istatus = 1
      return
      end

      subroutine get_vert_rads (vert_rad_pirep,
     1                          vert_rad_sao,
     1                          vert_rad_meso,
     1                          vert_rad_prof,
     1                          istatus)

      include 'lapsparms.cmn' ! vert_rad_pirep_cmn, etc.

      integer*4 vert_rad_pirep
      integer*4 vert_rad_sao
      integer*4 vert_rad_meso
      integer*4 vert_rad_prof

!     This routine accesses the vert_rad_pirep, etc., variables from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      vert_rad_pirep = vert_rad_pirep_cmn
      vert_rad_sao = vert_rad_sao_cmn
      vert_rad_meso = vert_rad_meso_cmn
      vert_rad_prof = vert_rad_prof_cmn

      istatus = 1
      return
      end

      subroutine get_r_missing_data(r_missing_data, istatus)

      include 'lapsparms.cmn' ! r_missing_data_cmn

!     This routine accesses the r_missing_data variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      r_missing_data = r_missing_data_cmn

      istatus = 1
      return
      end

      subroutine get_i2_missing_data(i2_missing_data, istatus)

      include 'lapsparms.cmn' ! i2_missing_data_cmn

!     This routine accesses the i2_missing_data variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      i2_missing_data = i2_missing_data_cmn

      istatus = 1
      return
      end


      subroutine get_i_perimeter(i_perimeter, istatus)

      include 'lapsparms.cmn' ! i_perimeter_cmn

!     This routine accesses the 'i_perimeter' variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      i_perimeter = i_perimeter_cmn

      istatus = 1
      return
      end


      subroutine get_ref_base(ref_base, istatus)

      include 'lapsparms.cmn' ! ref_base_cmn

!     This routine accesses the 'ref_base' variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      ref_base = ref_base_cmn

      istatus = 1
      return
      end

      subroutine get_ref_base_useable(ref_base_useable, istatus)

      include 'lapsparms.cmn' ! ref_base_useable

!     This routine accesses the 'ref_base_useable' variable from the
!     .parms file via the common block. Note the variable names in the
!     argument list may be different in the calling routine

      if(iflag_lapsparms_cmn .ne. 1)then
          write(6,*)' ERROR, get_laps_config not called'
          istatus = 0
          return
!         stop
      endif

      ref_base_useable = ref_base_useable_cmn

      istatus = 1
      return
      end

      subroutine get_background_info(len,bgpaths,bgmodels)
      integer maxbgmodels,len
      parameter (maxbgmodels=4)
      character*150 nest7grid
      character*150 bgpaths(maxbgmodels)
      integer bgmodels(maxbgmodels), len_dir
      namelist /background_nl/bgpaths,bgmodels

      call get_directory('nest7grid',nest7grid,len_dir)

      nest7grid = nest7grid(1:len_dir)//'/nest7grid.parms'

      open(1,file=nest7grid,status='old',err=900)
      read(1,background_nl,err=901)
      close(1)
      return
 900  print*,'error opening file ',nest7grid
      stop
 901  print*,'error reading background_nl in ',nest7grid
      stop
      end
      subroutine get_satellite_parameters(path_to_raw_sat_wfo_vis,
     +              path_to_raw_sat_wfo_i39,
     +              path_to_raw_sat_wfo_iwv,
     +              path_to_raw_sat_wfo_i11,
     +              path_to_raw_sat_wfo_i12,
     +              path_to_raw_satellite_gvr,
     +              path_to_raw_satellite_cdf,
     +       i_delta_sat_t_sec,r_msng_sat_flag_cdf
     +       ,r_msng_sat_flag_gvr,r_msng_sat_flag_asc
     +       ,max_sat,max_sat_channel, max_images)

      integer len_dir
      character*150 nest7grid
      character*200 path_to_raw_sat_wfo_vis,
     +              path_to_raw_sat_wfo_i39,
     +              path_to_raw_sat_wfo_iwv,
     +              path_to_raw_sat_wfo_i11,
     +              path_to_raw_sat_wfo_i12,
     +              path_to_raw_satellite_gvr,
     +              path_to_raw_satellite_cdf

      integer i_delta_sat_t_sec,r_msng_sat_flag_cdf
     +       ,r_msng_sat_flag_gvr,r_msng_sat_flag_asc
     +       ,max_sat,max_sat_channel, max_images
      namelist /satellite_nl/ path_to_raw_sat_wfo_vis,
     +                        path_to_raw_sat_wfo_i39,
     +                        path_to_raw_sat_wfo_iwv,
     +                        path_to_raw_sat_wfo_i11,
     +                        path_to_raw_sat_wfo_i12,
     +                        path_to_raw_satellite_gvr,
     +                        path_to_raw_satellite_cdf,
     +       i_delta_sat_t_sec,r_msng_sat_flag_cdf
     +       ,r_msng_sat_flag_gvr,r_msng_sat_flag_asc
     +       ,max_sat,max_sat_channel, max_images
 
      call get_directory('nest7grid',nest7grid,len_dir)

      nest7grid = nest7grid(1:len_dir)//'/nest7grid.parms'

      open(1,file=nest7grid,status='old',err=900)
      read(1,satellite_nl,err=901)
      close(1)
      return
 900  print*,'error opening file ',nest7grid
      stop
 901  print*,'error reading satellite_nl in ',nest7grid
      write(*,satellite_nl)
      stop
      end 
