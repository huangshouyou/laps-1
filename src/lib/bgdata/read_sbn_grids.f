      subroutine get_sbn_model_id(filename,cmodel,ivaltimes,ntbg
     &,istatus)

      implicit none
      include 'netcdf.inc'
      character*(*) cmodel
      character*(*) filename
      character*132 model
      integer ntbg,istatus
      integer ivaltimes(ntbg)
      integer nf_fid,nf_vid,nf_status
C
C  Open netcdf File for reading
C
      istatus = 1
      nf_status = NF_OPEN(filename,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN ', filename
        return
      endif

      nf_status = NF_INQ_VARID(nf_fid,'model',nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in var model'
         return
      endif
      nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,model)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
         return
      endif
      nf_status=NF_INQ_VARID(nf_fid,'valtimeMINUSreftime',nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
         return
      endif
      nf_status=NF_GET_VARA_INT(nf_fid,nf_vid,1,ntbg,ivaltimes)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
         return
      endif

      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
        return
      endif

      if(model(1:3).ne.cmodel(1:3))then
         print*,'Mismatch between model and cmodel'
         print*,model,cmodel
      endif

      istatus = 0

      return
      end

      subroutine get_sbn_dims(cdfname,cmodel,mxvars,mxlvls
     +,nvars,nxbg,nybg,nzbg_ht,nzbg_sh,nzbg_uv,nzbg_ww
     +,n_valtimes,istatus)

      implicit none
      include 'netcdf.inc'
      integer slen, nf_status,nf_fid, i, istat
      integer nf_vid
      integer mxlvls
      integer mxvars
      character*(*) cmodel
      character*(*) cdfname

      integer nxbg,nybg
      integer nzbg_ht
      integer nzbg_sh
      integer nzbg_uv
      integer nzbg_ww
      integer ntbg
      integer n_valtimes 
      integer record
      integer nvars
      integer ivaltimes(100)
      integer istatus

C     integer ntp, nvdim, nvs, lenstr, ndsize
c     integer ntp, nvdim, nvs
c     character*31 dummy
      
c     integer id_fields(5), vdims(10)
c     data id_fields/1,4,7,10,13/

      integer ncid,itype,ndims
      integer j,k,kk,lc,nclen,lenc
      integer dimlen
      character*10 cvars(mxvars)

      integer dimids(mxlvls)
      integer idims(mxlvls,mxvars)
      integer nattr
      integer nf_attid,nf_attnum
      character*13 fname9_to_wfo_fname13, fname13
C     Linda Wharton 10/27/98 removed several commented out lines:
c        print *,'ndsize = ', ndsize
C        value ndsize not set anywhere in this subroutine
C
      istatus = 0
      call s_len(cdfname,slen)
C
C Get size of n_valtimes
C
      call get_nvaltimes(cdfname,n_valtimes,ivaltimes,istatus)
      if(istatus.ne.1) then
         print *,'Error: get_nvaltimes '
         return
      endif

C
C
C  Open netcdf File for reading
C

      nf_status = NF_OPEN(cdfname,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN rucsbn'
      endif
C
C Get size of record
C
c     nf_status = NF_INQ_DIMID(nf_fid,'record',nf_vid)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim record'
c       return
c     endif
c     nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,record)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim record'
c       return
c     endif
C
C Get size of x
C
c     nf_status = NF_INQ_DIMID(nf_fid,'x',nf_vid)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim x'
c       return
c     endif
c     nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,nxbg)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim x'
c       return
c     endif
C
C Get size of y
C
c     nf_status = NF_INQ_DIMID(nf_fid,'y',nf_vid)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim y'
c       return
c     endif
c     nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,nybg)
c     if(nf_status.ne.NF_NOERR) then
c       print *, NF_STRERROR(nf_status)
c       print *,'dim y'
c       return
c     endif
C
C Get everything for each variable
C
      call s_len(cmodel,nclen)

      nvars=8
      cvars(1)='gh'
      cvars(2)='rh'
      cvars(3)='t'
      cvars(4)='uw'
      cvars(5)='vw'
      cvars(6)='pvv'
      cvars(7)='p'  !sfc pressure
      if(cmodel(1:nclen).eq.'RUC40_NATIVE')then
         cvars(8)='mmsp'
      elseif(cmodel(1:nclen).eq.'ETA48_CONUS')then
         cvars(8)='emsp'
      endif

      do i=1,nvars

         nf_status = NF_INQ_VARID(nf_fid, cvars(i),nf_vid)
         nf_status = NF_INQ_VAR(nf_fid,nf_vid,cvars(i)
     +,itype,ndims,dimids,nattr)

         do j=1,ndims
            nf_status = NF_INQ_DIMLEN(nf_fid,dimids(j),dimlen)
            idims(j,i)= dimlen
         enddo

c        nf_status = NF_INQ_ATTID(nf_fid,nf_vid,'_n3D',nf_attnum)
c        if(nf_status.ne.NF_NOERR) then
c           print*, NF_STRERROR(nf_status)
c           print*, 'attribute id ', cvars(i)
c           return
c        endif

         nf_status=NF_GET_ATT_INT(nf_fid,nf_vid,'_n3D',idims(3,i))
         if(nf_status.ne.NF_NOERR) then
            print *, NF_STRERROR(nf_status)
            print *,'get attribute ',cvars(i)
            return
         endif


         if(cvars(i).eq.'gh')then
            nxbg = idims(1,i)
            nybg = idims(2,i)
            nzbg_ht=idims(3,i)
         elseif(cvars(i).eq.'rh')then
            nzbg_sh=idims(3,i)
         elseif(cvars(i).eq.'uw')then
            nzbg_uv=idims(3,i)
         elseif(cvars(i).eq.'pvv')then
            nzbg_ww=idims(3,i)
         endif

      enddo

      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
        return
      endif

      istatus = 1
      return 
      end

      subroutine get_nvaltimes(cdfname,nvaltimes,ivaltimes,istatus)

      implicit none

      include 'netcdf.inc'

      integer       nf_fid,nf_status,nf_vid
      integer       nvaltimes
      integer       ivaltimes(100)
      integer       istatus
      character*(*) cdfname

c     logical       l2

      istatus=0

c     l2=.false.
c     inquire(file=cdfname,opened=l2)
c     if(.not.l2)then

      nf_status = NF_OPEN(cdfname,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'NF_OPEN: get_nvaltimes'
      endif

c     endif
         
      nf_status = NF_INQ_DIMID(nf_fid,'n_valtimes',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim n_valtimes'
        return
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,nvaltimes)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim n_valtimes'
        return
      endif
      nf_status=NF_INQ_VARID(nf_fid,'valtimeMINUSreftime',nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
         return
      endif
      nf_status=NF_GET_VARA_INT(nf_fid,nf_vid,1,nvaltimes,ivaltimes)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
         return
      endif

c     if(.not.l2)then

      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'nf_close: get_nvaltimes'
         return
      endif

c     endif

      istatus=1
      return
      end
C
C ------------------------------------------------------------
      subroutine read_sbn_grids(cdfname,af,cmodel,
     .   mxlvls,nxbg,nybg,nzbght,nzbgsh,nzbguv,nzbgww,
     .   prbght,prbgsh,prbguv,prbgww,
     .   ht,tp,sh,uw,vw,ww,
     .   ht_sfc,pr_sfc,uw_sfc,vw_sfc,sh_sfc,tp_sfc,mslp,
     .   ctype,istatus)
c
      implicit none
c
      include 'netcdf.inc'
      include 'bgdata.inc'

      integer mxlvls
c     integer ncid, lenstr, ntp, nvdim, nvs, ndsize
      integer model_out
      integer ncid

c     model_out=1  => lga
c     model_out=2  => dprep

      integer ndims ,dimids(NF_MAX_VAR_DIMS)
      integer itype,nattr

      integer nxbg,nybg
      integer nzbght
      integer nzbgsh
      integer nzbguv
      integer nzbgww
      integer nzsbn
      integer ntbg
      integer rcode
      integer ivaltimes(100)
c
c *** sfc output arrays.
c
      real, intent(out)  :: pr_sfc(nxbg,nybg)
      real, intent(out)  :: uw_sfc(nxbg,nybg)
      real, intent(out)  :: vw_sfc(nxbg,nybg)
      real, intent(out)  :: sh_sfc(nxbg,nybg)
      real, intent(out)  :: tp_sfc(nxbg,nybg)
      real, intent(out)  :: ht_sfc(nxbg,nybg)
      real, intent(out)  ::   mslp(nxbg,nybg)

c *** 3D Output arrays.
c
      real, intent(out)  :: prbght(nxbg,nybg,nzbght)
      real, intent(out)  :: prbgsh(nxbg,nybg,nzbgsh)
      real, intent(out)  :: prbguv(nxbg,nybg,nzbguv)
      real, intent(out)  :: prbgww(nxbg,nybg,nzbgww)
      real, intent(out)  ::     ht(nxbg,nybg,nzbght)
      real, intent(out)  ::     tp(nxbg,nybg,nzbguv)           !nzbgsh) -> mod needed for AVN 
      real, intent(out)  ::     sh(nxbg,nybg,nzbgsh)
      real, intent(out)  ::     uw(nxbg,nybg,nzbguv)
      real, intent(out)  ::     vw(nxbg,nybg,nzbguv)
      real, intent(out)  ::     ww(nxbg,nybg,nzbgww)
c
      real, allocatable ::  prbg_ht(:)
      real, allocatable ::  prbg_sh(:)
      real, allocatable ::  prbg_uv(:)
      real, allocatable ::  prbg_ww(:)

      integer start(10),count(10)
 
      integer i,j,k,n,ip,jp,ii,jj,it
      integer istatus,slen,lent
      integer lskip,kpsk
      integer ibdcnt
c
      character*9   fname,oldfname,model
      character*5 ctype
      character*4   af
      character*2   gproj
      character*(*) cdfname
      character*(*) cmodel
c
      real*4 xe,mrsat
c
c *** Common block variables for Lambert-conformal grid.
c
c     integer nx_lc,ny_lc,nz_lc  !No. of LC domain grid points
c     real*4 lat1,lat2,lon0,       !Lambert-conformal std lat1, lat, lon
c    .       sw(2),ne(2)           !SW lat, lon, NE lat, lon
c     common /lcgrid/nx_lc,ny_lc,nz_lc,lat1,lat2,lon0,sw,ne
c     real*4 lon0_lc
c     real*4 lat1_lc,lat2_lc

      integer nf_vid,nn
      real cp,rcp, factor
      parameter (cp=1004.,rcp=287./cp)
c
ccc      save htn,tpn,rhn,uwn,vwn,prn,oldfname
c_______________________________________________________________________________
c
      interface
        subroutine get_prbg(nf_fid,mxlvls,nlvls,cvar,cmodel
     +,pr_levels_bg)
        integer        mxlvls
        integer        nf_fid
        integer        nlvls
        character*(*)  cvar
        character*(*)  cmodel
        real  ::       pr_levels_bg(:)
        end subroutine
      end interface
c
c -------------------------------------------------------
      istatus = 1
      call get_nvaltimes(cdfname,ntbg,ivaltimes,istatus)
c
c *** Open the netcdf file.
c
      call s_len(cdfname,slen)
      print*,'opening cdf file: ',cdfname(1:slen)

      rcode = NF_OPEN(cdfname,NF_NOWRITE,ncid)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'NF_OPEN ',cdfname(1:slen)
         return
      endif

      read(af,'(i4)') nn

      rcode=NF_INQ_VARID(ncid,'valtimeMINUSreftime',nf_vid)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR: ',cmodel
         return
      endif
      rcode=NF_GET_VARA_INT(ncid,nf_vid,1,ntbg,ivaltimes)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR: ',cmodel
         return
      endif

      n=1
      do while(n.lt.ntbg.and.ivaltimes(n)/3600.ne. nn)
         n=n+1
      enddo
      if(ivaltimes(n)/3600.ne.nn) then

         print*,'ERROR: No record valid at requested time '
         print*,'ntbg/nn/af/n/ivaltimes(n) ',ntbg,' ',nn,' ',af,
     &' ',n,' ',ivaltimes(n)

         rcode= NF_CLOSE(ncid)
         if(rcode.ne.NF_NOERR) then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR: ',cmodel
            return
         endif

         goto 999

      else

         print*,'Found valid record at ivaltime'
         print*,'ntbg/nn/af/n/ivaltimes(n) ',ntbg,' ',nn,' ',af,
     &' ',n,' ',ivaltimes(n) 
         print*
      endif

      if(.not.allocated(prbg_ht))allocate(prbg_ht(mxlvls))
      if(.not.allocated(prbg_sh))allocate(prbg_sh(mxlvls))
      if(.not.allocated(prbg_uv))allocate(prbg_uv(mxlvls))
      if(.not.allocated(prbg_ww))allocate(prbg_ww(mxlvls))
c
c ****** Read netcdf data.
c ****** Statements to fill ht.
c

      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbght
      start(4)=n
      count(4)=1

      print*,'read ht'
      call read_netcdf_real(ncid,'gh',nxbg*nybg*count(3),ht,start
     +     ,count,rcode)
      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (gh): ',cmodel
         else
            print *,'Missing HT data detected: return'
         endif
         print*
         return
      endif
c
c get the pressures for this variable
c
      call get_prbg(ncid,mxlvls,nzbght,'gh',cmodel,prbg_ht)

c
c ****** Statements to fill rh.                           
c

      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbgsh
      start(4)=n
      count(4)=1

      print*,'read rh'
      call read_netcdf_real(ncid,'rh',nxbg*nybg*count(3),sh,start
     +     ,count,rcode)

      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (rh): ',cmodel
         else
            print *,'Missing RH data detected: return'
         endif
         print*
         return

      endif
c
c get the pressures for this variable
c
      call get_prbg(ncid,mxlvls,nzbgsh,'rh',cmodel,prbg_sh)

c
c ****** Statements to fill tp.
c
      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1

      if(cmodel.eq.'AVN_SBN_CYLEQ')then
         count(3)=nzbguv
      else
         count(3)=nzbgsh
      endif

      start(4)=n
      count(4)=1

      print*,'read tp'
      call read_netcdf_real(ncid,'t',nxbg*nybg*count(3),tp,start
     +     ,count,rcode)

      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (t): ',cmodel
         else
            print *,'Missing T data detected: return'
         endif
         print*
         return
      endif
c
c ****** Statements to fill uw. 
c
      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbguv
      start(4)=n
      count(4)=1

      print*,'read uw'
      call read_netcdf_real(ncid,'uw',nxbg*nybg*count(3),uw,start
     +     ,count,rcode)

      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (uw): ',cmodel
         else
            print *,'Missing U data detected: return'
         endif
         print*
         return
      endif
c
c get the pressures for this variable
c
      call get_prbg(ncid,mxlvls,nzbguv,'uw',cmodel,prbg_uv)

c
c ****** Statements to fill vw.                           
c
      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbguv
      start(4)=n
      count(4)=1

      print*,'read vw'
      call read_netcdf_real(ncid,'vw',nxbg*nybg*count(3),vw,start
     +     ,count,rcode)

      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (vw): ',cmodel
         else
            print *,'Missing V data detected: return'
         endif
         print*
         return
      endif
c
c ****** Statements to fill ww.
c
      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbgww
      start(4)=n
      count(4)=1

      print*,'read ww'
      call read_netcdf_real(ncid,'pvv',nxbg*nybg*count(3),ww
     +  ,start,count,rcode)

      if(rcode.ne.NF_NOERR) then
         if(rcode.gt.-61)then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (ww): ',cmodel
         else
            print *,'Missing ww data detected: continue without'
         endif
         print*
      endif

c
c get the pressures for this variable
c
      call get_prbg(ncid,mxlvls,nzbgww,'pvv',cmodel,prbg_ww)

c
c get sfc pressure field
c
      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=1
      start(4)=n
      count(4)=1
      
      call read_netcdf_real(ncid,'p',nxbg*nybg,pr_sfc,start
     +     ,count,rcode)

      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR (pr_sfc): ',cmodel
         return
      endif
c
c get mslp (this field name differs from one model to the other)
c
      if(cmodel.eq.'ETA48_CONUS') then

         call read_netcdf_real(ncid,'emsp',nxbg*nybg,mslp
     +           ,start,count,rcode)
         if(rcode.ne.NF_NOERR) then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (emsp): ',cmodel
            return
         endif

      elseif(cmodel.eq.'RUC40_NATIVE')then

         call read_netcdf_real(ncid,'mmsp',nxbg*nybg,mslp
     +           ,start,count,rcode)
         if(rcode.ne.NF_NOERR) then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (mmsp): ',cmodel
            return
         endif

      elseif(cmodel.eq.'AVN_SBN_CYLEQ')then

         call read_netcdf_real(ncid,'pmsl',nxbg*nybg,mslp
     +           ,start,count,rcode)
         if(rcode.ne.NF_NOERR) then
            print *, NF_STRERROR(rcode)
            print *,'in NF_GET_VAR (pmsl): ',cmodel
            return
         endif

      endif
c
c *** Close netcdf file.
c
      rcode= NF_CLOSE(ncid)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR: ',cmodel
         return
      endif
c
ccc      endif

c
c *** Fill ouput arrays.
c *** Convert rh to sh.
c
      do j=1,nybg
      do i=1,nxbg
         do k=1,nzbgsh
            prbgsh(i,j,k)=prbg_sh(k)
         enddo

         do k=1,nzbght
            prbght(i,j,k)=prbg_ht(k)
         enddo

         do k=1,nzbguv
            prbguv(i,j,k)=prbg_uv(k)
         enddo

         do k=1,nzbgww
            prbgww(i,j,k)=prbg_ww(k)
         enddo
      enddo
      enddo

      deallocate (prbg_ht,prbg_sh,prbg_uv,prbg_ww)
c
c use routine 'sfcprs' (in lga.f) to compute
c laps terrain adjusted sfc p, T and Td.
c
      ibdcnt=0
      do j=1,nybg
      do i=1,nxbg
         if(tp(i,j,1).lt.missingflag.and.
     .tp(i,j,1).gt.150.)             then
            vw_sfc(i,j)=vw(i,j,1)
            uw_sfc(i,j)=uw(i,j,1)
            tp_sfc(i,j)=tp(i,j,1)
            sh_sfc(i,j)=sh(i,j,1)
            ht_sfc(i,j)=ht(i,j,1)
         else
            ibdcnt=ibdcnt+1
         endif
      enddo
      enddo

c for laps-lgb

      call s_len(ctype,lent)

      if(ctype(1:lent).eq.'lapsb')then

         ibdcnt=0
         do j=1,nybg
         do i=1,nxbg
            if(tp(i,j,1).lt.missingflag.and.
     .tp(i,j,1).gt.150.)             then
c
c make sfc q from rh
c
              it=int(tp_sfc(i,j)*100)
              it=min(45000,max(15000,it))
              xe=esat(it)
              mrsat=0.00622*xe/(pr_sfc(i,j)*0.01-xe)
              sh_sfc(i,j)=sh_sfc(i,j)*mrsat
              sh_sfc(i,j)=sh_sfc(i,j)/(1.+sh_sfc(i,j))
            else
              ibdcnt=ibdcnt+1
            endif
         enddo
         enddo

      endif


      if(ibdcnt.gt.0)then
         print*,'Found bad surface data'
         return
      endif

      if(cmodel.eq.'AVN_SBN_CYLEQ')then
         nzsbn=nzbght
         lskip=2
      else
         nzsbn=nzbgsh-1
         lskip=1
      endif

      do i=1,nxbg
      do j=1,nybg

         do k=1,nzsbn              
            kpsk=k+lskip
            if (
     .          ht(i,j,k)   .lt. 99999.       .and.
     .          tp(i,j,kpsk) .gt. 100.        .and.
     .          tp(i,j,kpsk) .lt. missingflag .and. 
     .          abs(uw(i,j,kpsk)) .lt. 500    .and.
     .          abs(vw(i,j,kpsk)) .lt. 500)   then

                   tp(i,j,k)=tp(i,j,kpsk)
                   uw(i,j,k)=uw(i,j,kpsk)
                   vw(i,j,k)=vw(i,j,kpsk)
            else

                ibdcnt=ibdcnt+1

            endif
         enddo
      enddo
      enddo

      if(ibdcnt.gt.0)then
         print*,'Found bad (ht,t,u or v) 3d data'
         print*,'Return to read_bgdata'
         return
      endif

      if(cmodel.eq.'AVN_SBN_CYLEQ')then
         nzsbn=nzbgsh-2
      endif


      if(ctype(1:lent).eq.'lapsb')then
         do i=1,nxbg
         do j=1,nybg
         do k=1,nzsbn
            kpsk=k+lskip
            if (sh(i,j,kpsk) .lt. 200)then

                   it=tp(i,j,k)*100
                   it=min(45000,max(15000,it))
                   xe=esat(it)
                   mrsat=0.00622*xe/(prbgsh(i,j,k)-xe)
                   sh(i,j,k)=sh(i,j,kpsk)*mrsat
                   sh(i,j,k)=sh(i,j,k)/(1.+sh(i,j,k))

            else
                   ibdcnt=ibdcnt+1
            endif
         enddo
         enddo
         enddo

      endif

      if(ibdcnt.gt.0)then
         print*,'Found bad rh 3d data'
         print*,'Return to read_bgdata'
         return
      endif


c this for dprep ... ingnore for now!
c -----------------------------------
      if(.false. .and. model_out.eq.2) then
c
c Compute exner and convert temp to theta
c
         do k=1,nzbght
            do j=1,nybg
               do i=1,nxbg
                  if(tp(i,j,k).ne.missingflag) then
                     factor=(1000./prbght(i,j,k))**rcp
                     tp(i,j,k) = tp(i,j,k)*factor
                     prbght(i,j,k) = cp/factor
                  endif
               enddo
            enddo
         enddo

      endif


c     if(istatus_211 .eq. 0) then
c       print*, 'No valid data found for',fname, af
c       return
c     endif

      istatus = 0

      if(0.eq.1) then
 900     print*,'ERROR: bad dimension specified in netcdf file'
         print*, (count(i),i=1,4)
         istatus=-1
      endif
 999  return
      end

c -----------------------------------------------------------

      subroutine get_prbg(nf_fid,mxlvls,nlvls,cvar,cmodel
     +,pr_levels_bg)

      implicit none

      integer mxlvls
      integer nf_fid
      integer nf_vid
      integer nf_status
      integer nlvls
      integer level
      integer lenc,lc,nclen
      integer k,kk
     
      character      cvar*(*)
      character      cmodel*(*)
      character      clvln10(mxlvls)*10
      character      clvln11(mxlvls)*11
      character      cnewvar*10
      character      ctmp*10
 
      real, intent(out) :: pr_levels_bg(:)

      include 'netcdf.inc'

      call s_len(cvar,lenc)
      cnewvar=cvar(1:lenc)//'Levels'
      nf_status = NF_INQ_VARID(nf_fid,cnewvar,nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in var id: ',cnewvar
         return
      endif

      call s_len(cmodel,nclen)
      if(cmodel(1:nclen).eq.'AVN_SBN_CYLEQ')then
         nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,clvln11)
      else
         nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,clvln10)
         if(nf_status.eq.NF_NOERR)then
            do k=1,nlvls
               clvln11(k)=clvln10(k)
            enddo
         endif
      endif
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in var: ',clvln11
         return
      endif
      pr_levels_bg = 0.0
      kk=0
      do k=1,nlvls
         call s_len(clvln11(k),lc)
         if(clvln11(k)(1:2).eq.'MB')then
            kk=kk+1
            ctmp=TRIM(clvln11(k)(4:10))
            read(ctmp,'(i4.4)')level
            pr_levels_bg(kk)=float(level)
         endif
      enddo

      return
      end
