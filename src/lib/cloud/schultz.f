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
!--------------------------------------------------------------------------
!Cloud water stays supercooled well below freezing, but there's almost zero
!supercooled water at -20 (253K).  Pristine crystals melt pretty fast above
!freezing.

        Subroutine ConvC2P (maxrate, t, rate)
        Implicit none
        Real*4 maxrate, t, rate
        Real*4 pwr
        data pwr/2./

        rate = 0.

        If (t .lt. 253.) then
         rate = maxrate
         Return
        Else if (t .lt. 267.) then
         rate = maxrate * ((267.-t)/(267.-253.))**pwr
         Return
        Else if (t .lt. 273.15) then
         rate = 0.
         Return
        Else if (t .lt. 278.) then
         rate = -maxrate * (t-273.15)/(278.-273.15)
         Return
        Else
         rate = -maxrate
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!This includes both autoconversion and collision/coalescence (collection).
!Obviously, the former is just a function of cloud water content, but the
!latter is also dependent on the presence of rain.  Note that collection
!can cause the rate to exceed the "maxrate" if there are very high
!concentrations of rain.

        Subroutine ConvC2R (maxrate, qc, qcmin, qr, rate)
        Implicit none
        Real*4 maxrate, qc, qcmin, qr, rate

        rate = 0.

        If (qc .lt. qcmin) then
         Return
        Else if (qc .lt. .0015) then
         rate = maxrate * (qc-qcmin)/(.0015-qcmin) * (1.+qr/.002)
         Return
        Else
         rate = maxrate * (1. + qr/.002)
         Return
        End if

        Return
        End

!-----------------------------------------------------------------------
!This includes both autoconversion and aggregration.  The former is just
!a function of cloud ice content, but the latter is also dependent on the
!presence of snow.  Note that collection can cause the rate to exceed the
!"maxrate" if there are very high concentrations of snow.

        Subroutine ConvP2S (maxrate, qp, qpmin, qs, rate)
        Implicit none
        Real*4 maxrate, qp, qpmin, qs, rate

        rate = 0.

        If (qp .lt. qpmin) then
         Return
        Else if (qp .lt. .0015) then
         rate = maxrate * (qp-qpmin)/(.0015-qpmin) * (1.+qs/.002)
         Return
        Else
         rate = maxrate * (1. + qs/.002)
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!Riming.  Note that the rate can exceed the "maxrate" if there are very high
!concentrations of snow.

        Subroutine ConvC2S (maxrate, qc, qcmin, qs, rate)
        Implicit none
        Real*4 maxrate, qc, qcmin, qs, rate

        rate = 0.
        If (qs .lt. .0000001) Return    ! no autoconversion

        If (qc .lt. qcmin) then
         Return
        Else if (qc .lt. .0015) then
         rate = maxrate * (qc-qcmin)/(.0015-qcmin) * (1.+qs/.002)
         Return
        Else
         rate = maxrate * (1. + qs/.002)
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!Riming of ice particles.  Note that the rate can exceed the "maxrate" if
!there are very high concentrations of ice.

        Subroutine ConvC2I (maxrate, qc, qcmin, qi, rate)
        Implicit none
        Real*4 maxrate, qc, qcmin, qi, rate

        rate = 0.
        If (qi .lt. .0000001) Return    ! no autoconversion

        If (qc .lt. qcmin) then
         Return
        Else if (qc .lt. .0015) then
         rate = maxrate * (qc-qcmin)/(.0015-qcmin) * (1.+qi/.002)
         Return
        Else
         rate = maxrate * (1. + qi/.002)
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!Melting only, since rain does not freeze into snow.

        Subroutine ConvS2R (maxrate, t, rate)
        Implicit none
        Real*4 maxrate, t, rate

        rate = 0.

        If (t .lt. 273.15) then
         Return
        Else if (t .lt. 283.) then
         rate = maxrate * (t-273.15)/(283.-273.15)
         Return
        Else
         rate = maxrate
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!Freezing and melting.  For now, this is the same algorithm as C2P.

        Subroutine ConvR2I (maxrate, t, rate)
        Implicit none
        Real*4 maxrate, t, rate
        Real*4 pwr
        data pwr/2./

        rate = 0.

        If (t .lt. 253.) then
         rate = maxrate
         Return
        Else if (t .lt. 267.) then
         rate = maxrate * ((267.-t)/(267.-253.))**pwr
         Return
        Else if (t .lt. 273.15) then
         rate = 0.
         Return
        Else if (t .lt. 278.) then
         rate = -maxrate * (t-273.15)/(278.-273.15)
         Return
        Else
         rate = -maxrate
         Return
        End if

        Return
        End

!--------------------------------------------------------------------------
!Evaporation of rain; function of vapor deficit only.

        Subroutine ConvR2V (maxrate, rv, rvsatliq, rate)
        Implicit none
        Real*4 maxrate, rv, rvsatliq, rate

        rate = 0.
        If (rv .ge. rvsatliq) Return

        If (rvsatliq .lt. .000001) Return

        rate = maxrate * (rvsatliq-rv)/rvsatliq

        Return
        End

!--------------------------------------------------------------------------
!Evaporation of snow; function of vapor deficit only.

        Subroutine ConvS2V (maxrate, rv, rvsatice, rate)
        Implicit none
        Real*4 maxrate, rv, rvsatice, rate

        rate = 0.
        If (rv .ge. rvsatice) Return

        If (rvsatice .lt. .000001) Return

        rate = maxrate * (rvsatice-rv)/rvsatice

        Return
        End

!--------------------------------------------------------------------------
!Evaporation of precipitating ice (graupel, sleet, hail); function of vapor
!deficit only.  Maybe the vapor deficit should be with respect to water...

        Subroutine ConvI2V (maxrate, rv, rvsatice, rate)
        Implicit none
        Real*4 maxrate, rv, rvsatice, rate

        rate = 0.
        If (rv .ge. rvsatice) Return

        If (rvsatice .lt. .000001) Return

        rate = maxrate * (rvsatice-rv)/rvsatice

        Return
        End
