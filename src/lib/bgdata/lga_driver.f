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
c===============================================================================
c
      subroutine lga_driver(nx_laps,ny_laps,nz_laps,
     .     laps_cycle_time,bgmodel,bgpath,cmodel,reject_cnt,
     .     reject_names,bg_names,max_files,accepted_files,
     .     i4time_now,smooth_fields,lga_status)

c
      implicit none
      include 'bgdata.inc'
c
      integer nx_laps,ny_laps,nz_laps,     !LAPS grid dimensions
     .        nx_bg  ,ny_bg,               !Background model grid dimensions
     .        nzbg_ht,nzbg_tp,nzbg_sh,
     .        nzbg_uv,nzbg_ww,
     .        max_files, lga_status,
     .        laps_cycle_time,
     .        bgmodel,nbg,lncf

      integer   ishow_timer
      integer   init_timer
      integer   itstatus(10)
      integer   itstatus_rot
      integer   icnt
      integer   igrx,igry
      integer i_mx, i_mn, j_mx, j_mn, nan_flag
      real diff, diff_mx, diff_mn

      real Lon0,Lat0,Lat1,dlat,dlon
      real sw(2),ne(2)
      real cenlat,cenlon
      real dx,dy

      character*256 bgpath
      character*256 bg_names(max_files)
      character*256 reject_names(max_files)
      character*132 cmodel
      
      integer warncnt
c sfc namelist stuff. for reduced pressure calc
      integer use_lso_qc, skip_internal_qc, itheta
      logical l_require_lso
      real    redp_lvl,del,gam,ak
c
c *** Background model grid data.
c
c
c *** sfc background arrays.
c
      real, allocatable  :: prbg_sfc(:,:)
      real, allocatable  :: uwbg_sfc(:,:)
      real, allocatable  :: vwbg_sfc(:,:)
      real, allocatable  :: shbg_sfc(:,:)
      real, allocatable  :: tpbg_sfc(:,:)
      real, allocatable  :: htbg_sfc(:,:)
      real, allocatable  :: mslpbg(:,:)
c
c *** 3D background arrays.
c
      real, allocatable  :: prbght(:,:,:)    !Pressure (mb) height levels
      real, allocatable  :: prbgsh(:,:,:)    !Pressure (mb) humidity levels
      real, allocatable  :: prbguv(:,:,:)    !Pressure (mb) u/v components
      real, allocatable  :: prbgww(:,:,:)    !Pressure (mb) omega levels
      real, allocatable  :: htbg(:,:,:)      !Background heights (m)
      real, allocatable  :: tpbg(:,:,:)      !Background temps (K)
      real, allocatable  :: shbg(:,:,:)      !Background humidity (gm/m3)
      real, allocatable  :: uwbg(:,:,:)      !Background u component (m/s)
      real, allocatable  :: vwbg(:,:,:)      !Background v component (m/s)
      real, allocatable  :: wwbg(:,:,:)      !Background omega (m/s)
c
c *** Intermediate arrays for background data vertically
c     interpolated to LAPS isobaric levels.
c
      real, allocatable :: htvi(:,:,:)
      real, allocatable :: tpvi(:,:,:)
      real, allocatable :: shvi(:,:,:)
      real, allocatable :: uwvi(:,:,:)
      real, allocatable :: vwvi(:,:,:)
      real, allocatable :: wwvi(:,:,:)

      integer, allocatable :: msgpt(:,:)
c
c *** Background data interpolated to LAPS grid.
c
      real*4    ht(nx_laps,ny_laps,nz_laps), !Height (m)
     .          tp(nx_laps,ny_laps,nz_laps), !Temperature (K)
     .          sh(nx_laps,ny_laps,nz_laps), !Specific humidity (kg/kg)
     .          uw(nx_laps,ny_laps,nz_laps), !!U-wind (m/s)
     .          vw(nx_laps,ny_laps,nz_laps), !V-wind (m/s)
     .          ww(nx_laps,ny_laps,nz_laps), !W-wind (pa/s)
     .          pr(nz_laps),                 !LAPS pressures
     .          lat(nx_laps,ny_laps),        !LAPS lat
     .          lon(nx_laps,ny_laps),        !LAPS lon
     .          topo(nx_laps,ny_laps),       !LAPS avg terrain
     .          grx(nx_laps,ny_laps),        !hinterp factor
     .          gry(nx_laps,ny_laps),         !hinterp factor
     .          ht_sfc(nx_laps,ny_laps),
     .          tp_sfc(nx_laps,ny_laps),
     .          Tdsfc(nx_laps,ny_laps),
     .          sh_sfc(nx_laps,ny_laps),
     .          qsfc(nx_laps,ny_laps),
     .          uw_sfc(nx_laps,ny_laps),
     .          vw_sfc(nx_laps,ny_laps),
     .          pr_sfc(nx_laps,ny_laps),     !Stn pressure
     .          rp_sfc(nx_laps,ny_laps),     !Reduced pressure
     .          mslp(nx_laps,ny_laps)

      real, allocatable :: rp_lvl(:,:)       !Reduced pressure lvl
      real, allocatable :: rp_tp(:,:)        !Reduced pressure temp (holder)
      real, allocatable :: rp_sh(:,:)        !Reduced pressure sh   (holder)
c
      real      ssh2,                        !Function name
     .          shsat,cti,
     .          htave,tpave,shave,uwave,vwave,
     .          rmaxvv,rminvv
c
      integer   ct,  reject_cnt,
     .          ihour,imin,
     .          i4time_now,
     .          lga_files,lga_times(max_files),
     .          lga_valid,
     .          bg_times(max_files),accepted_files, bglen,
     .          i4time_bg_valid(max_files),
     .          bg_valid(max_files),
     .          valid_bg(max_files),time_bg(max_files),
     .          bgvalid,
     .          i,ic,ii,j,jj,k,kk,l,ldl,lf,
     .          istatus

      integer   istatus_prep(max_files)

      integer   i4lgatime(max_files)
      integer   i4bgtime
      integer   nlga
c
      character*256 lgapath
      character*256 lga_names(max_files)
      character*256 names(max_files)
      character*256 fname_bg(max_files)

      character*13  fname13,fname9_to_wfo_fname13
      character*13  cvt_fname13_to_wfo_fname13
      character*13  cvt_wfo_fname13_to_fname13
      character*9   wfo_fname13_to_fname9

      character*6   c6_maproj
      character*2   gproj
      character*1   cgrddef
      character*200 fullname
      character*256 outdir
      character*31  ext
      character*125 comment(nz_laps)
      character*4   af_bg(max_files)
      character*10  c_domain_name
      character*200 c_dataroot
      character*200 cfname

      integer len_dir,ntime, nf
c
      logical llapsfua
      logical linterp
      logical smooth_fields

      data ntime/0/
      data ext/'lga'/

      interface
c
       subroutine read_bgdata(nx_bg,ny_bg
     +,nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv,nzbg_ww,ctype
     +,bgpath,fname_bg,af_bg,fullname,cmodel,bgmodel
     +,prbght,prbgsh,prbguv,prbgww
     +,htbg,tpbg,uwbg,vwbg,shbg,wwbg
     +,htbg_sfc,prbg_sfc,shbg_sfc,tpbg_sfc
     +,uwbg_sfc,vwbg_sfc,mslpbg,istatus)
c
         real  :: prbg_sfc(nx_bg,ny_bg)
         real  :: uwbg_sfc(nx_bg,ny_bg)
         real  :: vwbg_sfc(nx_bg,ny_bg)
         real  :: shbg_sfc(nx_bg,ny_bg)
         real  :: tpbg_sfc(nx_bg,ny_bg)
         real  :: htbg_sfc(nx_bg,ny_bg)
         real  :: mslpbg(nx_bg,ny_bg)
c
         real  :: prbght(nx_bg,ny_bg,nzbg_ht)
         real  :: prbgsh(nx_bg,ny_bg,nzbg_sh)
         real  :: prbguv(nx_bg,ny_bg,nzbg_uv)
         real  :: prbgww(nx_bg,ny_bg,nzbg_ww)
         real  :: htbg(nx_bg,ny_bg,nzbg_ht)
         real  :: tpbg(nx_bg,ny_bg,nzbg_tp)
         real  :: shbg(nx_bg,ny_bg,nzbg_sh)
         real  :: uwbg(nx_bg,ny_bg,nzbg_uv)
         real  :: vwbg(nx_bg,ny_bg,nzbg_uv)
         real  :: wwbg(nx_bg,ny_bg,nzbg_ww)

         character*4   af_bg
         character*5   ctype
         character*132 cmodel
         character*256 bgpath
         character*256 fname_bg
         character*200 fullname
         integer       bgmodel
         integer       nx_bg
         integer       ny_bg
         integer       nzbg_ht
         integer       nzbg_tp
         integer       nzbg_sh
         integer       nzbg_uv
         integer       nzbg_ww
         integer       istatus
       end subroutine

       subroutine vinterp(nz_laps,nx,ny,
     .	nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv,nzbg_ww,
     .  prlaps, prbght,prbgsh,prbguv,prbgww,
     .  htbg,tpbg,shbg,uwbg,vwbg,wwbg,
     .  htvi,tpvi,shvi,uwvi,vwvi,wwvi)

         integer nx,ny
         integer nzbg_ht
         integer nzbg_tp
         integer nzbg_sh
         integer nzbg_uv
         integer nzbg_ww

         integer nz_laps

         real*4  ::  prbght(nx,ny,nzbg_ht)
         real*4  ::  prbgsh(nx,ny,nzbg_sh)
         real*4  ::  prbguv(nx,ny,nzbg_uv)
         real*4  ::  prbgww(nx,ny,nzbg_ww)
         real*4  ::  tpbg(nx,ny,nzbg_tp)
         real*4  ::  htbg(nx,ny,nzbg_ht)
         real*4  ::  shbg(nx,ny,nzbg_sh)
         real*4  ::  uwbg(nx,ny,nzbg_uv)
         real*4  ::  vwbg(nx,ny,nzbg_uv)
         real*4  ::  wwbg(nx,ny,nzbg_ww)


         real*4  ::  tpvi(nx,ny,nz_laps)
         real*4  ::  htvi(nx,ny,nz_laps)
         real*4  ::  shvi(nx,ny,nz_laps)
         real*4  ::  uwvi(nx,ny,nz_laps)
         real*4  ::  vwvi(nx,ny,nz_laps)
         real*4  ::  wwvi(nx,ny,nz_laps)
c
         real*4  ::  prlaps(nz_laps)
 
       end subroutine

       subroutine get_bkgd_mdl_info(bgmodel
     &,cmodel,fullname,nx,ny,nzbg_ht,nzbg_tp
     &,nzbg_sh,nzbg_uv,nzbg_ww
     &,gproj,dlat,dlon,centrallat,centrallon,dx,dy
     &,Lat0,Lat1,Lon0,sw,ne,cgrddef,istatus)

        character*200 fullname
        character*132 cmodel
        character*2   gproj
        character*1   cgrddef
        integer       istatus
        integer       bgmodel
        integer       nx,ny
        integer       nzbg_ht
        integer       nzbg_tp
        integer       nzbg_sh
        integer       nzbg_uv
        integer       nzbg_ww
        real          Lat1
        real          Lat0,Lon0
        real          sw(2),ne(2)
        real          centrallat
        real          centrallon
        real          dx,dy

       end subroutine

       subroutine init_hinterp(nx_bg,ny_bg,nx_laps,ny_laps,gproj,
     .     lat,lon,grx,gry,bgmodel,cmodel)

         character  gproj*2
         character  cmodel*132
         integer nx_bg,ny_bg,nx_laps,ny_laps,bgmodel
         real*4 lat(nx_laps,ny_laps)
     .         ,lon(nx_laps,ny_laps)
     .         ,grx(nx_laps,ny_laps)
     .         ,gry(nx_laps,ny_laps)

       end subroutine

       subroutine hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz
     .,grx,gry,fvi,flaps,bgmodel)

         integer nx_bg,ny_bg,nx_laps,ny_laps,nz,bgmodel
         real*4 fvi(nx_bg,ny_bg,nz)
     .         ,flaps(nx_laps,ny_laps,nz)
     .         ,grx(nx_laps,ny_laps)
     .         ,gry(nx_laps,ny_laps)

       end subroutine

       subroutine filter_2dx(field,ix,iy,iz,smth)
         integer ix,iy,iz
         real field(ix,iy,iz)
         real smth
       end subroutine


      end interface

      warncnt=0 
c_______________________________________________________________________________
c *** Get LAPS lat, lons.
c
      print *,'in lga_sub'
      linterp=.true.
      lga_status=0

      call s_len(cmodel,ic)

      call s_len(bgpath,bglen)
      if(bgpath(bglen:bglen).ne.'/')then
         bglen=bglen+1
         bgpath(bglen:bglen)='/'
      endif
      cfname=bgpath(1:bglen)//bg_names(1)
      call s_len(cfname,lncf)

      call get_bkgd_mdl_info(bgmodel,cmodel,cfname
     &,nx_bg,ny_bg,nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv
     &,nzbg_ww ,gproj,dlat,dlon,cenlat,cenlon,dx,dy
     &,Lat0,Lat1,Lon0,sw,ne,cgrddef,istatus)

      if(istatus.ne.1)then
         print*,'Error getting background model information'
         return
      endif

      llapsfua=.false.
      if(bgmodel.eq.0)then
         if(cmodel(1:ic).eq.'MODEL_FUA'.or.
     &      cmodel(1:ic).eq.'LAPS_FUA')then
            llapsfua=.true.
            if(cmodel(1:ic).eq.'LAPS_FUA')then

               linterp = .false.

               print*,'*************************************'
               print*,'Interpolation to domain not necessary'
               print*,'*************************************'

            endif
         endif
      endif

      call init_gridconv_cmn(gproj,nx_bg,ny_bg,nzbg_ht
     &,dlat,dlon,cenlat,cenlon,Lat0,Lat1,Lon0
     &,sw(1),sw(2),ne(1),ne(2),cgrddef,istatus)

      print *
      print *, ' Background information: '
      print *, '-------------------------'
      print *, 'nx/ny:              ',nx_bg,ny_bg
      print *, 'nz(ht,tp,sh,uv,ww): '
     &,nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv,nzbg_ww
      print *, 'bgpath:             ',bgpath(1:bglen)
      print *, 'bgmodel:            ',bgmodel
      print *, 'cmodel:             ',cmodel(1:ic)
      print *

      call get_directory('static',outdir,len_dir)    

      call find_domain_name(c_dataroot,c_domain_name,istatus)
      if(istatus.ne.1)then
          print*,'Error returned: find_domain_name'
          return
      endif

      call get_laps_domain(nx_laps,ny_laps,c_domain_name
     +,lat,lon,topo,istatus)
      if (istatus.lt.1)then
          print *,'Error reading lat, lon, topo data.'
          stop
      endif
c
c *** Specify model path, extension for write laps routine.
c
      call get_directory('lga',outdir,len_dir)
      print *,'writing to dir ',outdir(1:len_dir)
c
c *** get LAPS pressure levels.  Using pressures.nl
c
c     print*,'get pressures from pressure.nl'
      call get_pres_1d(i4time_now,nz_laps,pr,istatus)
      if(istatus.ne.1)then
         print*,'Error returned from get_pres_1d'
         print*,'Check pressures.nl or nk_laps in nest7grid.parms'
         stop
      endif
      do k = 1,nz_laps
         pr(k)=pr(k)/100.
      enddo
c
c *** Determine which of the "bg_names" has not already been processed
c
      do j=1,max_files
         names(j)=bg_names(j)
      enddo

      do j=1,accepted_files
         call i4time_fname_lp(names(j)(1:9),bg_times(j),istatus)
         if(llapsfua)then
            read(bg_names(j)(10:11),'(i2)')ihour
         else
            read(bg_names(j)(12:13),'(i2)')ihour
         endif
         bg_valid(j)=ihour*3600
         i4time_bg_valid(j)=bg_times(j)+bg_valid(j)
      enddo

      call get_directory('lga',lgapath,ldl)
      call get_file_times(lgapath,max_files,lga_names
     1                      ,lga_times,nlga,istatus)

      if(nlga.gt.0)then
         k=1
         do while (k.le.nlga)

            read(lga_names(k)(ldl+10:ldl+11),'(i2)')ihour
            read(lga_names(k)(ldl+12:ldl+13),'(i2)')imin

            lga_valid=ihour*3600+imin*60

            do j=1,accepted_files

               if(bg_times(j).eq.lga_times(k).and.
     .            bg_valid(j).eq.lga_valid)      then
c
c ok, since we've processed it, lets add it to the reject list
c

c                 reject_cnt=reject_cnt+1
c                 reject_names(reject_cnt)=names(j)
                  names(j)=' '

c                 print*,'reject_cnt/reject_names'
c                 print*,'cnt/time: ',reject_cnt
c    +,reject_names(reject_cnt)

               endif
            enddo
            k=k+1
         enddo
      endif

      nbg=0
      do 33 j=1,accepted_files

         if(names(j).ne.' ')then

          do k=1,reject_cnt
           if(reject_names(k).eq.names(j))goto 33 !then
c             names(j)=' '
c          endif

          enddo

          nbg = nbg+1
          if(bgmodel.eq.4)then
             fname_bg(nbg)=
     1 cvt_fname13_to_wfo_fname13(bg_names(j)(1:13))
          else
             fname_bg(nbg)=bg_names(j)
          endif

          af_bg(nbg)=bg_names(j)(10:13)
          time_bg(nbg)=bg_times(j)
          valid_bg(nbg)=bg_valid(j)

         endif

33    continue

      if(nbg.eq.0)then
         print*,'No new model background to process'
         lga_status = 1
      endif
c
c ****** Read background model data.
c
c     print*,'process new model background'

      do nf=1,nbg
 
c Removal of this loop causes already existing lga files to be overwritten
c possibly with the same data.  However the error frequency on SBN may warrent
c this extra work.  
       if(.false.) then
        do i=1,lga_files
         if (fname_bg(nf) .eq. lga_names(i)(1:9) .and.
     .     af_bg(nf)(3:4) .eq. lga_names(i)(10:11)) then
                  
           print *,i,lga_names(i),':',fname_bg(nf),':',af_bg(nf)
           call get_lga_source(nx_laps,ny_laps,nz_laps
     +                 ,fname_bg(nf),af_bg(nf),comment(1))

           if(cmodel(1:ic) .eq. comment(1)(1:ic)) then
              print *,'LGA file exists, not making one. ',lga_names(i)
c             lga_status=1
           else
              print *,'Overwritting LGA file ',lga_names(i)
     +             ,'from model ',comment(1)(1:i),' with a new '
     +             ,'one from model ',cmodel(1:ic)
           endif
         endif
        enddo          
       endif     

       if(bgpath(bglen:bglen).eq.'/')then
          fullname = bgpath(1:bglen)//fname_bg(nf)
       else
          fullname = bgpath(1:bglen)//'/'//fname_bg(nf)
       endif
       call s_len(fullname,i)
c
       print*
       print*,'Reading - ',fullname(1:i)
       print*


       allocate (htbg(nx_bg,ny_bg,nzbg_ht))
       allocate (tpbg(nx_bg,ny_bg,nzbg_tp))
       allocate (shbg(nx_bg,ny_bg,nzbg_sh))
       allocate (uwbg(nx_bg,ny_bg,nzbg_uv))
       allocate (vwbg(nx_bg,ny_bg,nzbg_uv))
       allocate (wwbg(nx_bg,ny_bg,nzbg_ww))
       allocate (prbght(nx_bg,ny_bg,nzbg_ht))
       allocate (prbguv(nx_bg,ny_bg,nzbg_uv))
       allocate (prbgsh(nx_bg,ny_bg,nzbg_sh))
       allocate (prbgww(nx_bg,ny_bg,nzbg_ww))

       allocate (htbg_sfc(nx_bg,ny_bg))
       allocate (prbg_sfc(nx_bg,ny_bg))
       allocate (shbg_sfc(nx_bg,ny_bg))
       allocate (uwbg_sfc(nx_bg,ny_bg))
       allocate (vwbg_sfc(nx_bg,ny_bg))
       allocate (tpbg_sfc(nx_bg,ny_bg))
       allocate (mslpbg(nx_bg,ny_bg))

       call read_bgdata(nx_bg,ny_bg
     +    ,nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv,nzbg_ww
     +    ,'lapsb',bgpath,fname_bg(nf),af_bg(nf)
     +    ,fullname,cmodel,bgmodel
     +    ,prbght,prbgsh,prbguv,prbgww
     +    ,htbg,tpbg,uwbg,vwbg,shbg,wwbg
     +    ,htbg_sfc,prbg_sfc,shbg_sfc,tpbg_sfc
     +    ,uwbg_sfc,vwbg_sfc,mslpbg,istatus_prep(nf))

           if(.false.)then
           print*,'After read'
           do k=1,nzbg_ww
              rmaxvv=maxval(wwbg(:,:,k))
              rminvv=minval(wwbg(:,:,k))
              print*,'k Max/Min vv ',k,rmaxvv,rminvv
           enddo
           endif

       if (istatus_prep(nf) .ne. 0) then

c           call s_len(fname_bg(nf),lf)
c           call s_len(bgpath,l)
c           if (bgmodel .gt. 1 .and. bgmodel .le. 3) then
c              fname13=fname_bg(nf)(1:lf)//af_bg(nf)
c           elseif (bgmodel .eq. 4) then
c              fname13=fname9_to_wfo_fname13(fname_bg(nf))
c           endif

          print *,'Background model data not returned from ',
     .'read_bgdata: ',bgpath(1:bglen)//fname_bg(nf)
          print *,'Process aborted for this file.'

c         convert to wfo if necessary

          print*
          print*,'Updating reject information: '

          if(bgmodel.eq.4)then
             print*,'WFO Update'
             fname13=wfo_fname13_to_fname9(fname_bg(nf))
             fname13=fname13(1:9)//af_bg(nf)
             do ii=1,accepted_files
                if(fname13.eq.bg_names(ii))then
                   reject_cnt=reject_cnt+1
                   reject_names(reject_cnt)=bg_names(ii)
                   print*,'reject_cnt/reject_names'
                   print*,'cnt/time: ',reject_cnt
     +,reject_names(reject_cnt)

                endif
             enddo
          else
             print*
             do ii=1,accepted_files
                if(fname_bg(nf).eq.bg_names(ii))then
                   reject_cnt=reject_cnt+1
                   reject_names(reject_cnt)=bg_names(ii)

                   print*,'reject_cnt/reject_names'
                   print*,'cnt/time: ',reject_cnt
     +,reject_names(reject_cnt)
                endif
             enddo
          endif
          lga_status= -nf

          deallocate(htbg, tpbg, shbg, uwbg, vwbg, wwbg
     +,prbght, prbguv, prbgsh, prbgww, htbg_sfc, prbg_sfc
     +,shbg_sfc, uwbg_sfc, vwbg_sfc, tpbg_sfc, mslpbg)

 
       else   !processing the file

c        endif
c
c ****** Vertically interpolate background data to LAPS isobaric levels.
c
         if(linterp)then   ! this switch determines if we are going to h/v-interp or not

           itstatus(1)=init_timer()

           allocate( htvi(nx_bg,ny_bg,nz_laps),!Height (m)
     .          tpvi(nx_bg,ny_bg,nz_laps),   !Temperature (K)
     .          shvi(nx_bg,ny_bg,nz_laps),   !Specific humidity (kg/kg)
     .          uwvi(nx_bg,ny_bg,nz_laps),   !U-wind (m/s)
     .          vwvi(nx_bg,ny_bg,nz_laps),   !V-wind (m/s)
     .          wwvi(nx_bg,ny_bg,nz_laps))   !W-wind (pa/s)

           call vinterp(nz_laps,nx_bg,ny_bg
     .       ,nzbg_ht,nzbg_tp,nzbg_sh,nzbg_uv,nzbg_ww
     .       ,pr,prbght,prbgsh,prbguv,prbgww
     .       ,htbg,tpbg,shbg,uwbg,vwbg,wwbg
     .       ,htvi,tpvi,shvi,uwvi,vwvi,wwvi)

           itstatus(1)=ishow_timer()
           print*,' Vinterp elapsed time (sec): ',itstatus(1)

           deallocate (htbg, tpbg, shbg, uwbg, vwbg, wwbg
     +,prbght, prbguv, prbgsh, prbgww )

           allocate (msgpt(nx_bg,ny_bg))
c
c ****** Run 2dx filter on vertically interpolated fields.
c ****** Only run filter on sh up to 300 mb, since the filter may
c           create small neg values when the field is small to begin with.
c ****** If bgmodel=4, there exists missing data.  Don't use these points
c           in the filter.
c
           if (bgmodel .eq. 4 .or. bgmodel .eq. 9) then
            do j=1,ny_bg
            do i=1,nx_bg
               if (htvi(i,j,1) .eq. missingflag) then
                  msgpt(i,j)=0
               else
                  msgpt(i,j)=1
               endif
            enddo
            enddo
c
            do k=1,nz_laps
            do j=2,ny_bg-1
            do i=2,nx_bg-1
               if (max(msgpt(i-1,j-1),
     .                 msgpt(i-1,j  ),
     .                 msgpt(i-1,j+1),
     .                 msgpt(i  ,j-1),
     .                 msgpt(i  ,j  ),
     .                 msgpt(i  ,j+1),
     .                 msgpt(i+1,j-1),
     .                 msgpt(i+1,j  ),
     .                 msgpt(i+1,j+1)) .eq. 1) then
                  ct=0
                  htave=0.
                  tpave=0.
                  shave=0.
                  uwave=0.
                  vwave=0.
                  do jj=j-1,j+1
                  do ii=i-1,i+1
                     if (msgpt(ii,jj) .eq. 1) then
                        ct=ct+1
                        htave=htave+htvi(ii,jj,k)
                        tpave=tpave+tpvi(ii,jj,k)
                        shave=shave+shvi(ii,jj,k)
                        uwave=uwave+uwvi(ii,jj,k)
                        vwave=vwave+vwvi(ii,jj,k)
                     endif
                  enddo
                  enddo
                  cti=1./float(ct)
                  htvi(i,j,k)=htave*cti
                  tpvi(i,j,k)=tpave*cti
                  shvi(i,j,k)=shave*cti
                  uwvi(i,j,k)=uwave*cti
                  vwvi(i,j,k)=vwave*cti
               endif
            enddo
            enddo
            enddo
           endif
c
           do kk=nz_laps,1,-1
            if (pr(kk) .ge. 300.) goto 20
           enddo
20         continue
           if (smooth_fields) THEN
             print*, "SMOOTHING BACKGROUND DATA!"
             call filter_2dx(htvi,nx_bg,ny_bg,nz_laps, 0.5)
             call filter_2dx(htvi,nx_bg,ny_bg,nz_laps,-0.5)
             call filter_2dx(tpvi,nx_bg,ny_bg,nz_laps, 0.5)
             call filter_2dx(tpvi,nx_bg,ny_bg,nz_laps,-0.5)
             call filter_2dx(shvi,nx_bg,ny_bg,kk     , 0.5)
             call filter_2dx(shvi,nx_bg,ny_bg,kk     ,-0.5)
             call filter_2dx(uwvi,nx_bg,ny_bg,nz_laps, 0.5)
             call filter_2dx(uwvi,nx_bg,ny_bg,nz_laps,-0.5)
             call filter_2dx(vwvi,nx_bg,ny_bg,nz_laps, 0.5)
             call filter_2dx(vwvi,nx_bg,ny_bg,nz_laps,-0.5)
             call filter_2dx(wwvi,nx_bg,ny_bg,nz_laps, 0.5)
             call filter_2dx(wwvi,nx_bg,ny_bg,nz_laps,-0.5)
           endif
c
           if (bgmodel .eq. 4) then
            do j=1,ny_bg
            do i=1,nx_bg
               if (msgpt(i,j) .eq. 0) then
                  do k=1,nz_laps
                     htvi(i,j,k)=missingflag
                     tpvi(i,j,k)=missingflag
                     shvi(i,j,k)=missingflag
                     uwvi(i,j,k)=missingflag
                     vwvi(i,j,k)=missingflag
                  enddo
               endif
            enddo
            enddo
           endif
c
c ****** Horizontally interpolate background data to LAPS grid points.
c
           itstatus(2)=init_timer()

           call init_hinterp(nx_bg,ny_bg,nx_laps,ny_laps,gproj,
     .        lat,lon,grx,gry,bgmodel,cmodel)
           call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .        grx,gry,htvi,ht,bgmodel)
           call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .        grx,gry,uwvi,uw,bgmodel)
           call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .        grx,gry,vwvi,vw,bgmodel)
           call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .        grx,gry,tpvi,tp,bgmodel)


           if(bgmodel.eq.2.and.cmodel(1:ic).eq.'ORSM_HKO'.and.
     .       .false.)then
              print*,'use bilinear interp for ',cmodel(1:ic)
              do k=1,nz_laps
              do j=1,ny_laps
              do i=1,nx_laps
                 call bilinear_laps(grx(i,j),gry(i,j),nx_bg,ny_bg
     .                             ,shvi(1,1,k),sh(i,j,k)) 
                 call bilinear_laps(grx(i,j),gry(i,j),nx_bg,ny_bg
     .                             ,wwvi(1,1,k),ww(i,j,k))
              enddo
              enddo
              enddo
           else
              call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .           grx,gry,shvi,sh,bgmodel)
              call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,nz_laps,
     .           grx,gry,wwvi,ww,bgmodel)
           endif

           itstatus(2)=ishow_timer()
           print*,'Hinterp (3D) elapsed time (sec): ',itstatus(2)
           print*
c
c ****** Check for missing value flag in any of the fields.
c ****** Check for NaN's in any of the fields.
c
           deallocate(htvi,   !Height (m)
     .              tpvi,   !Temperature (K)
     .              shvi,   !Specific humidity (kg/kg)
     .              uwvi,   !U-wind (m/s)
     .              vwvi,   !V-wind (m/s)
     .              wwvi,   !W-wind (pa/s)
     .              msgpt)

           do k=1,nz_laps
            do j=1,ny_laps
               do i=1,nx_laps
                  if((abs(ht(i,j,k)) .gt. 100000.) .or.
     +                   (ht(i,j,k)  .lt.-3000)  .or.
     +                   (tp(i,j,k)  .gt. 1000.) .or.
     +                   (tp(i,j,k)  .le. 0.) .or.
     +               (abs(sh(i,j,k)) .gt. 1.) .or.
     +               (abs(uw(i,j,k)) .gt. 150.) .or.
     +               (abs(vw(i,j,k)) .gt. 150.) )then
c    +             .or.(abs(ww(i,j,k)) .gt. 10.) )then
c
c ww may be missing from some models! Don't stop just because of that.
c                  if (max(ht(i,j,k),tp(i,j,k),sh(i,j,k),
c     .                 uw(i,j,k),vw(i,j,k)) .ge. missingflag) then

               print*,'ERROR: Missing or bad value detected: ',i,j,k
               print*,'ht/tp/sh/uw/vw/ww: ',ht(i,j,k),tp(i,j,k)
     +                  ,sh(i,j,k), uw(i,j,k),vw(i,j,k),ww(i,j,k)

                     reject_cnt=reject_cnt+1
                     reject_names(reject_cnt)=bg_names(ii)

                     print*,'reject_cnt/reject_names'
                     print*,'cnt/time: ',reject_cnt
     +,reject_names(reject_cnt)

                     lga_status = -nf

                     deallocate (htbg_sfc
     +                          ,prbg_sfc
     +                          ,shbg_sfc
     +                          ,uwbg_sfc
     +                          ,vwbg_sfc
     +                          ,tpbg_sfc
     +                          ,mslpbg)

                     return

                  endif
c-----------------------------------
cc            if (ht(i,j,k) .ne. ht(i,j,k) .or. 
cc     .           tp(i,j,k) .ne. tp(i,j,k) .or.
cc     .           sh(i,j,k) .ne. sh(i,j,k) .or. 
cc     .           uw(i,j,k) .ne. uw(i,j,k) .or.
cc     .           vw(i,j,k) .ne. vw(i,j,k)) then
cc               print *,'ERROR: NaN detected:',i,j,k
cc               lga_status = -nf
cc               return
cc            endif
c-----------------------------------
               enddo
            enddo
           enddo
c
           call checknan_3d(ht,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array ht'
            lga_status = -nf
            return
           endif
c
           call checknan_3d(tp,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array tp'
            lga_status = -nf
            return
           endif
c
           call checknan_3d(sh,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array sh'
            lga_status = -nf
            return
           endif
c
           call checknan_3d(uw,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array uw'
            lga_status = -nf
            return
           endif
c
           call checknan_3d(vw,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array vw'
            lga_status = -nf
            return
           endif
           call checknan_3d(ww,nx_laps,ny_laps,nz_laps,nan_flag)
           if(nan_flag .ne. 1) then
            print *,' ERROR: NaN found in array vw'
            lga_status = -nf
            return
           endif
c
c ****** Horizontally interpolate background surface data to LAPS grid points.
c
           itstatus(3)=init_timer()

           if(bgmodel.ne.1.and.bgmodel.ne.9)then

           if(bgmodel.ne.3)then

            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,htbg_sfc,ht_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,tpbg_sfc,tp_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,shbg_sfc,sh_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,uwbg_sfc,uw_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,vwbg_sfc,vw_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,prbg_sfc,pr_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .        grx,gry,mslpbg,mslp,bgmodel)
c
c check for T > Td before sfc p computation. Due to large scale
c interpolation we can have slightly larger (fractional) Td than T.
c
            call tdcheck(nx_laps,ny_laps,sh_sfc,tp_sfc,
     &icnt,i_mx,j_mx,i_mn,j_mn,diff_mx,diff_mn)

            print *,' Dewpoint check (before call sfcbkgd):'
            print *,'     Dewpt greater than temp at ',icnt,' points.'

            if(icnt .gt. 0) then
               print*,'Max diff of ',diff_mx,' at ',i_mx,',',j_mx
               print*,'Min diff of ',diff_mn,' at ',i_mn,',',j_mn
            endif

           else

            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .                  grx,gry,prbg_sfc,pr_sfc,bgmodel)
            call hinterp_field(nx_bg,ny_bg,nx_laps,ny_laps,1,
     .                  grx,gry,mslpbg,mslp,bgmodel)

           endif
           endif

           deallocate (htbg_sfc)
           deallocate (prbg_sfc)
           deallocate (shbg_sfc)
           deallocate (uwbg_sfc)
           deallocate (vwbg_sfc)
           deallocate (tpbg_sfc)
           deallocate (mslpbg)
c
c... Do the temp, moisture (sh_sfc returns with Td), and pressures
c
           call sfcbkgd(bgmodel,tp,sh,ht,tp_sfc,sh_sfc,topo,pr,
     .            nx_laps, ny_laps, nz_laps, pr_sfc)

           call tdcheck(nx_laps,ny_laps,sh_sfc,tp_sfc,
     &icnt,i_mx,j_mx,i_mn,j_mn,diff_mx,diff_mn)

           print *,' Dewpoint check (after call sfcbkgd):'
           print *,'     Dewpt greater than temp at ',icnt,' points.'

           if(icnt .gt. 0) then
            print*,'Max diff of ',diff_mx,' at ',i_mx,',',j_mx
            print*,'Min diff of ',diff_mn,' at ',i_mn,',',j_mn
c
c fix sfc Td to not be greater than T at points determined above
            where(sh_sfc .gt. tp_sfc)sh_sfc=tp_sfc
           endif
c
c..... Do the winds
c
           call interp_to_sfc(topo,uw,ht,nx_laps,ny_laps,
     &                         nz_laps,missingflag,uw_sfc)
           call interp_to_sfc(topo,vw,ht,nx_laps,ny_laps,
     &                         nz_laps,missingflag,vw_sfc)
c
c..... Compute reduced pressure using reduced pressure level from
c      surface namelist file
c
           call read_sfc_nl(use_lso_qc,skip_internal_qc 
     1,itheta, redp_lvl, del, gam, ak, l_require_lso)

           allocate (rp_lvl(nx_laps,ny_laps)
     1,rp_tp(nx_laps,ny_laps),rp_sh(nx_laps,ny_laps))

           do j=1,ny_laps
           do i=1,nx_laps
              rp_lvl(i,j)=redp_lvl
              rp_tp(i,j)=tp_sfc(i,j)
              rp_sh(i,j)=sh_sfc(i,j)
           enddo
           enddo

           call sfcbkgd(0,tp,sh,ht,rp_tp,rp_sh,rp_lvl,pr,
     1nx_laps, ny_laps, nz_laps, rp_sfc)

           deallocate (rp_lvl,rp_tp,rp_sh)
c
c ****** Eliminate any supersaturations or negative sh generated 
c           through interpolation (set min sh to 1.e-6).
c
           icnt=0
           do k=1,nz_laps
           do j=1,ny_laps
           do i=1,nx_laps
            if(tp(i,j,k).gt.100.0)then
               shsat=ssh2(pr(k),tp(i,j,k)-273.15,
     .             tp(i,j,k)-273.15,-132.0)*0.001
               sh(i,j,k)=max(1.0e-6,min(sh(i,j,k),shsat))
            else
               icnt=icnt+1
            endif
           enddo
           enddo
           enddo
           print*
           if(icnt.gt.0)then
            print*,'Warning: found ',icnt,' 3D points when'
            print*,'         checking for supersaturations'
           endif
c
           itstatus(3)=ishow_timer()
           print*,'Hinterp (2D) elapsed time (sec): ',itstatus(3)
           print*
c
c the wind components are still on the native grid projection;
c rotate them to the LAPS (output) domain as necessary.

           itstatus_rot=ishow_timer()

           call rotate_background_uv(nx_laps,ny_laps,nz_laps,lon
     &,bgmodel,cmodel,fullname(1:i),gproj,lon0,lat0,lat1,uw,vw
     &,uw_sfc,vw_sfc,istatus)
           if(istatus.ne.1)then
              print*,'Error in rotate_background_uv '
              return
           endif

           itstatus_rot=ishow_timer()
           print*,'After rotation: elapsed time (sec): ',itstatus_rot
           print*

         else

c this is a grid compatible fua file

           ht=htbg
           tp=tpbg
           sh=shbg
           uw=uwbg
           vw=vwbg
           ww=wwbg
           pr_sfc=prbg_sfc
           mslp=mslpbg
           tp_sfc=tpbg_sfc
           ht_sfc=htbg_sfc
           sh_sfc=shbg_sfc
           uw_sfc=uwbg_sfc
           vw_sfc=vwbg_sfc
c
c LAPS_FUA doesnt require interp but we will recompute
c pr_sfc, tp_sfc and sh_sfc using high res terrain
c
           call sfcbkgd(bgmodel,tp,sh,ht,tp_sfc,sh_sfc,topo
     &           ,pr,nx_laps, ny_laps, nz_laps, pr_sfc)

           call tdcheck(nx_laps,ny_laps,sh_sfc,tp_sfc,
     &icnt,i_mx,j_mx,i_mn,j_mn,diff_mx,diff_mn)

           print *,' Td check (after call sfcbkgd - MODEL_FUA):'
           print *,' Td greater than T at ',icnt,' points.'
           if(icnt .gt. 0) then
              print*,'Max diff = ',diff_mx,' at ',i_mx,',',j_mx
              print*,'Min diff = ',diff_mn,' at ',i_mn,',',j_mn
c
c fix sfc Td to not be greater than T at points determined above
c
              where(sh_sfc .gt. tp_sfc)sh_sfc=tp_sfc
           endif

c
c..... Do the winds
c
           call interp_to_sfc(topo,uw,ht,nx_laps,ny_laps,
     &                         nz_laps,missingflag,uw_sfc)
           call interp_to_sfc(topo,vw,ht,nx_laps,ny_laps,
     &                         nz_laps,missingflag,vw_sfc)

           deallocate (htbg, tpbg, shbg, uwbg, vwbg, wwbg
     +                ,prbght, prbguv, prbgsh, prbgww )
           deallocate (htbg_sfc,prbg_sfc,shbg_sfc,uwbg_sfc
     +                ,vwbg_sfc,tpbg_sfc,mslpbg)

         endif !(linterp)
c
c Write LGA
c ---------
        itstatus(4)=init_timer()

        bgvalid=time_bg(nf)+valid_bg(nf)
        call write_lga(nx_laps,ny_laps,nz_laps,time_bg(nf),
     .bgvalid,cmodel,missingflag,pr,ht,tp,sh,uw,vw,ww,istatus)
        if(istatus.ne.1)then
         print*,'Error writing lga - returning to main'
         return
        endif
c         
c Write LGB
c ---------

        if(bgmodel.ne.7)then
 
         do j=1,ny_laps
         do i=1,nx_laps
            if(pr_sfc(i,j) .lt. missingflag) then
               qsfc(i,j)=ssh2(pr_sfc(i,j)*0.01,
     +                   tp_sfc(i,j)-273.15,
     +                   sh_sfc(i,j)-273.15,-132.)*0.001
c              sfcgrid(i,j,kk+4)=qsfc(i,j)
            else
               qsfc(i,j) = missingflag
c              sfcgrid(i,j,kk+4)=missingflag
            endif
         enddo
         enddo

         call write_lgb(nx_laps,ny_laps,time_bg(nf),bgvalid
     .,cmodel,missingflag,uw_sfc,vw_sfc,tp_sfc,qsfc,pr_sfc,mslp
     .,sh_sfc,rp_sfc,istatus)
         if(istatus.ne.1)then
            print*,'Error writing lgb - returning to main'
            return
         endif

         itstatus(4)=ishow_timer()
         print*,'Elapsed time - write grids (sec): ',itstatus(4)
         print*

        endif

        lga_status = 1
c
       endif !if the background file was properly read in in read_bgdata

      enddo  !Main loop through two model backgrounds

c time interpolate between existing lga (bg) files.
c-------------------------------------------------------------------------------
c
      if(lga_status.eq.1)then
       itstatus(5)=init_timer()
       do i=1,nbg
          call s_len(bg_names(i),j)
          print*,'bg_name: ',i,bg_names(i)(1:j)
       enddo
c
c *** Determine if new file needs to (can) be created and perform
c        linear time interpolation.
c
       if(accepted_files.gt.1)then

         i=accepted_files
c        if(accepted_files.gt.2)then
c           i=2
c        endif

         print*,i,bg_times(i),bg_times(i-1),
     +     bg_valid(i),bg_valid(i-1),laps_cycle_time,
     +     i4time_bg_valid(i),i4time_bg_valid(i-1)

         if(i4time_bg_valid(i-1) .gt.i4time_now   .and.
     +      i4time_bg_valid(i)   .lt.i4time_now  )then
            ext = 'lga'
            call get_directory(ext,outdir,len_dir) 
            print*,outdir,ext,nz_laps

c interp 3D fields
            call time_interp(outdir,ext,
     +           nx_laps,ny_laps,nz_laps,6,pr,
     +           i4time_bg_valid(i),i4time_bg_valid(i-1),
     +           i4time_now,bg_times(i-1),bg_valid(i-1),
     +           bg_times(i  ),bg_valid(i  ))

            if(bgmodel.ne.1.or.bgmodel.ne.7)then
               ext = 'lgb'
               call get_directory(ext,outdir,len_dir) 
               print*,outdir,ext

c interp 2D fields
               call time_interp(outdir,ext,
     +           nx_laps,ny_laps,1,8,pr(1),
     +           i4time_bg_valid(i),i4time_bg_valid(i-1),
     +           i4time_now,bg_times(i-1),bg_valid(i-1),
     +           bg_times(i  ),bg_valid(i  ))
            endif
         else
            print*,'Time Interpolation Not Necessary!'
         endif

         itstatus(5)=ishow_timer()
         print*,'Elapsed time - interp grids (sec): ',itstatus(5)
         print*

       elseif(accepted_files.eq.1)then

c code isn't ready to go yet.
c        if(i4time_bg_valid(i).gt.i4time_now)then
c           do k=1,nlga
c              lgadiff=i4time_bg_valid(i)-lga_times(k)
c           enddo
c        endif 

         print*,'Determine if existing lga plus the new one ',
     .          'can be used for time interpolation'
         print*
         print*,'Software does not exist yet. You lose.'

       else
         print*,'No time interp when accepted_files = 0'
         print*
       endif

      elseif(lga_status.eq.0 .and. nbg.eq.0)then
       print*,'bkgd files already exists; no new ones to proc'
c      lga_status = 1
      else
       print*,'No time interp when bad data found'
       print*
      endif

      print*,'Total time elapsed lga: '
      print*,'(sec) :',itstatus(1)+itstatus(2)+itstatus(3)
     &+itstatus(4)+itstatus(5)

      return
      end
c
c=========================================================
c
      subroutine get_lga_source(nx,ny,nz,fname,af,source)
      character*9 fname
      character*4 af
      character*10 dumb1
      character*125 comment
      character*12 source
      integer ihour, bgtime, nx,ny,nz
      real dumb2(nx,ny,nz)

      call i4time_fname_lp(fname,bgtime,istatus)
      read(af,'(i4)') ihour
      call get_lapsdata_3d(bgtime,bgtime+ihour*3600,nx,ny,
     +        nz,'lga ','HT ',dumb1,comment,dumb2,istatus)
      if(istatus.lt.1) then
         stop 'error returned from get_lapsdata_3d'
      endif


      source = comment(1:12)
      return
      end
