      subroutine get_ruc2_dims(filename,NX,NY,NZ,istatus)
      implicit none
      include 'netcdf.inc'
      integer  NX, NY, NZ, nf_fid, nf_vid, nf_status
      character*(*) filename
      integer istatus

C
C  Open netcdf File for reading
C
      nf_status = NF_OPEN(filename,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN ', filename
        istatus = 0
        return
      endif
C
C  Fill all dimension values
C
C
C Get size of record
C
c      nf_status = NF_INQ_DIMID(nf_fid,'record',nf_vid)
c      if(nf_status.ne.NF_NOERR) then
c        print *, NF_STRERROR(nf_status)
c        print *,'dim record'
c      endif
c      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,record)
c      if(nf_status.ne.NF_NOERR) then
c        print *, NF_STRERROR(nf_status)
c        print *,'dim record'
c      endif
C
C Get size of x
C
      nf_status = NF_INQ_DIMID(nf_fid,'x',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim x'
              istatus = 0
        return
      endif

      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,NX)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim x'
              istatus = 0
        return
      endif

C
C Get size of y
C
      nf_status = NF_INQ_DIMID(nf_fid,'y',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim y'
              istatus = 0
        return
      endif

      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,NY)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim y'
              istatus = 0
        return
      endif

C
C Get size of z
C
      nf_status = NF_INQ_DIMID(nf_fid,'z',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim z'
              istatus = 0
        return
      endif

      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,NZ)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim z'
              istatus = 0
        return
      endif


      nf_status = NF_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close ruc2'
              istatus = 0
        return
      endif

      
      return
      end
C
C
C
C  Subroutine to read the file "Hybrid-B 40km Rapid Update Cycle" 
C
      subroutine read_ruc2_hybb(filename, NX, NY, NZ, mmsp
     +     ,hgt, p, qv, u, v, vpt, w,istatus)
      implicit none
      include 'netcdf.inc'
C     integer NX, NY, NZ, nf_fid, nf_vid, nf_status,istatus
      integer NX, NY, NZ, nf_fid, nf_status,istatus
      character*(*) filename
      integer nxny,nxnynz
      real mmsp(nx,ny), hgt( NX,  NY,  NZ), 
     +     p( NX,  NY,  NZ), qv( NX,  NY,  NZ), 
     +     u( NX,  NY,  NZ), v( NX,  NY,  NZ), 
     +     vpt( NX,  NY,  NZ), w( NX,  NY,  NZ)

      nxny=nx*ny
      nxnynz=nx*ny*nz

C
C  Open netcdf File for reading
C
      nf_status = NF_OPEN(filename,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN ', filename
              istatus = 0
        return
      endif
      print*,'Reading - ',filename

C
C     Variable        NETCDF Long Name
C      MMSP         "MAPS mean sea level pressure" 
C
      call read_netcdf_real(nf_fid,'MMSP',nxny,mmsp,0,0,nf_status)

C
C     Variable        NETCDF Long Name
C      hgt          "geopotential height" 
C
      call read_netcdf_real(nf_fid,'hgt',nxnynz,hgt,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
         print*, 'A substantial portion of the height field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif


C
C     Variable        NETCDF Long Name
C      p            "pressure" 
C
      call read_netcdf_real(nf_fid,'p',nxnynz,p,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
      print*, 'A substantial portion of the pressure field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif
C
C     Variable        NETCDF Long Name
C      qv           "water vapor mixing ratio" 
C
      call read_netcdf_real(nf_fid,'qv',nxnynz,qv,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
      print*,'A substantial portion of the water vapor field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif

C
C     Variable        NETCDF Long Name
C      u            "u-component of wind" 
C
      call read_netcdf_real(nf_fid,'u',nxnynz,u,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
         print*, 'A substantial portion of the u-wind field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif

C
C     Variable        NETCDF Long Name
C      v            "v-component of wind" 
C
      call read_netcdf_real(nf_fid,'v',nxnynz,v,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
         print*, 'A substantial portion of the v-wind field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif

C
C     Variable        NETCDF Long Name
C      vpt          "virtual potential temperature" 
C
      call read_netcdf_real(nf_fid,'vpt',nxnynz,vpt,0,0,nf_status)

      if(nf_status.lt.-0.5*nxnynz) then
         print*, 'A substantial portion of the vpt field is missing'
         print*, 'ABORTING file processing for ruc2 file ',filename
         istatus=0
         return
      endif

C
C     Variable        NETCDF Long Name
C      w            "vertical velocity" 
C
      call read_netcdf_real(nf_fid,'w',nxnynz,w,0,0,nf_status)


      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
        istatus = 0
        return
      endif

      istatus = 1
      return
      end
