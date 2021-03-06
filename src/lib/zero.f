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
        subroutine zero(a,imax,jmax)
c
c.....  routine to set an array to zero.
c
        real a(imax,jmax)
c
        do j=1,jmax
        do i=1,imax
          a(i,j) = 0.
        enddo !i
        enddo !j
c
        return
        end
c
c===============================================================================
c
      subroutine zero3d(a,nx,ny,nz)
c
      implicit none
c
      integer   nx,ny,nz,i,j,k
c
      real a(nx,ny,nz)
c_______________________________________________________________________________
c
      do k=1,nz
      do j=1,ny
      do i=1,nx
         a(i,j,k)=0.
      enddo
      enddo
      enddo
c
      return
      end

