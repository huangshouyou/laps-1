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
	function os(t,p)
c
c   this function returns the equivalent potential temperature os
c   (celsius) for a parcel of air saturated at temperature t (celsius)
c   and pressure p (millibars).
c
c	baker,schlatter	17-may-1982	original version
c
	data b/2.6518986/
c   b is an empirical constant approximately equal to the latent heat
c   of vaporization for water divided by the specific heat at constant
c   pressure for dry air.
	tk = t+273.16
	osk= tk*((1000./p)**.286)*(exp(b*w(t,p)/tk))
	os= osk-273.16
	return
	end
