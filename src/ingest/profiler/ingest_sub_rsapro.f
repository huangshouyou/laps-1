
        subroutine ingest_rsapro(i4time_sys,NX_L,NY_L,istatus)

        integer cdfid,status,MAX_PROFILES,MAX_LEVELS,file_n_prof       

        parameter (MAX_PROFILES = 1000)
	parameter (MAX_LEVELS = 300)
        parameter (MAX_SUBDIRS = 3)

        real ht_out(max_levels)
        real di_out(max_levels)
        real sp_out(max_levels)

        character*6 prof_name(MAX_PROFILES)

        character*255 prof_subdirs(MAX_SUBDIRS)

        integer i4_mid_window_pr(MAX_PROFILES)
        integer wmo_id(MAX_PROFILES)

        real lat_pr(MAX_PROFILES)
        real lon_pr(MAX_PROFILES)
        real elev_m_pr(MAX_PROFILES)
        real n_lvls_pr(MAX_PROFILES)
        real ht_m_pr(MAX_PROFILES,MAX_LEVELS)
        real dir_dg_pr(MAX_PROFILES,MAX_LEVELS)
        real spd_ms_pr(MAX_PROFILES,MAX_LEVELS)
        real u_std_ms_pr(MAX_PROFILES,MAX_LEVELS)
        real v_std_ms_pr(MAX_PROFILES,MAX_LEVELS)

        integer bad,missing, start(2), count(2), staNamLen
        integer start_time(1), count_time(1)
        parameter (bad = 12)
        parameter (missing = -1)
        character*1 qc_char(3)
        data qc_char/'G','B','M'/
        integer*4 byte_to_i4

        character*200 fnam_in
        character*180 dir_in
        character*255 c_filespec
        integer error_code
        data error_code/1/
        logical l_in_box
        data l_in_box/.true./

        integer varid
        include 'netcdf.inc'
        character*(MAXNCNAM) dimname 

        character*13 a13_time,filename13,cvt_i4time_wfo_fname13,outfile       
        character*9 asc9_tim,a9time_ob

        character*31    ext
        integer*4       len_dir_in

        character*40 c_vars_req
        character*180 c_values_req

        character*9 a9_timeObs
        integer*4 timeObs

        real*4 lat(NX_L,NY_L),lon(NX_L,NY_L)
        real*4 topo(NX_L,NY_L)

        call get_r_missing_data(r_missing_data,istatus)
        if (istatus .ne. 1) then
           write (6,*) 'Error getting r_missing_data'
           return
        endif
 
        r_mspkt = .518

        call get_latlon_perimeter(NX_L,NY_L,1.0
     1                           ,lat,lon,topo
     1                           ,rnorth,south,east,west,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAPS perimeter'
            return
        endif

        outfile = filename13(i4time_sys,'pro')
        asc9_tim = outfile(1:9)

!       dir_in = path_to_raw_blpprofiler

        c_vars_req = 'path_to_raw_blpprofiler'
        call get_static_info(c_vars_req,c_values_req,1,istatus)
        if(istatus .eq. 1)then
            write(6,*)c_vars_req(1:30),' = ',c_values_req
            dir_in = c_values_req
        else
            write(6,*)' Error getting ',c_vars_req
            return
        endif

        call s_len(dir_in,len_dir_in)

        prof_subdirs(1) = '50mhz'
        prof_subdirs(2) = '915mhz'
        prof_subdirs(3) = 'minisodar'

        ext = 'pro'

        i4_prof_window = 1800 ! could be reset to laps_cycle_time

        do idir = 1,MAX_SUBDIRS
            call s_len(prof_subdirs(idir),len_subdir)
 
C           READ IN THE RAW PROFILER DATA
            a13_time = cvt_i4time_wfo_fname13(i4time_sys)
            fnam_in = dir_in(1:len_dir_in)
     1                //prof_subdirs(idir)(1:len_subdir)
     1                //'/netCDF/'//a13_time
            call s_len(fnam_in,len_fnam_in)
            write(6,*)' file = ',fnam_in(1:len_fnam_in)

!           call read_prof_rsa(fnam_in(1:len_fnam_in)                  ! I
!     1                   ,MAX_PROFILES,MAX_LEVELS                     ! I
!     1                   ,n_profiles                                  ! O
!     1                   ,n_lvls_pr                                   ! O
!     1                   ,prof_name,wmo_id                            ! O
!     1                   ,lat_pr,lon_pr,elev_m_pr                     ! O
!     1                   ,ht_m_pr,di_dg_pr,sp_ms_pr                   ! O
!     1                   ,u_std_ms_pr,v_std_ms_pr                     ! O
!     1                   ,i4_mid_window_pr,istatus)                   ! O
!           istatus = 0


            if(idir .eq. 1 .or. idir .eq. 2)then
                call read_rsa_50mhz(i4time_sys,i4_prof_window          ! I
     1                                    ,NX_L,NY_L                   ! I
     1                                    ,ext                         ! I
     1                                    ,fnam_in(1:len_fnam_in)      ! I
     1                                    ,istatus)                    ! O
            endif ! idir

            if(istatus.ne.1)then
                write(6,*)' Warning: bad status on read_rsa_50mhz'
     1                   ,istatus           
                goto980
            endif

 980        continue

        enddo ! idir

        return
        end


