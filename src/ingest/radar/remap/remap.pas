Module remap;

	%include	'[Radar]RtRadbox.Pas/List'


{ -- Procedures included in this module are:
{
{	           Name				    Type
{	----------------------------		------------
{	remap					Program
{}


   include  eh_global_types,
	    pg_global_defs,
	    pg_context_routines,
            bd_access_routines,
	    return_status_codes,
	    logfile_routines,
	    output_status_text;


   Procedure  lut_gen; External;

{  Procedure  laps_grid; External;
{}
   Procedure  remap_process( 
		var i_scan_index		: integer;		{ i }
		var i_last_scan			: integer;		{ i }
		var i_first_scan		: integer;		{ i }
		var i_volume_i4time		: integer;		{ i }
		var i_product_numbers		: t_eh_prod_int_array;	{ i }

		var i_num_finished_products	: integer;		{ o }
		var i_product_statuses		: t_eh_prod_int_array;	{ o }
		var i_status			: integer ); external;	{ o }




   Program remap;


{	History:
{      
{	     Name          Date                     Description
{	--------------	-----------	----------------------------------
{	Bob Lipschutz	29-Oct-1986	Original version (after PPI shell).
{	Chris Windsor	22-Jan-1987	Renamed seg_cen, removed all mes
{	B.L.&SteveAlbers 7-Dec-1988	Mods for REMAP
{}



      Var
	 v30_routine		: varying_string( 30 ) := 'REMAP > ';
	 v50_msg		: varying_string( 50 );


      	 i_num_finished_products: integer;
	 i_product_numbers	: t_eh_prod_int_array;
	 i_product_statuses	: t_eh_prod_int_array;
	 i_product_ancinfo	: t_eh_prod_ancinfo_array;

	 i_product_number	: integer;	{ id of data/product to be used }
      	 i_product_i4time	: integer;

	 i_job_ancillary_info	: t_eh_ancillary_info;

	 i_vol_index		: integer;
	 i_scan_index		: integer;
	 i_scan_flags		: integer;
	 i_last_scan		: integer;
	 i_first_scan		: integer;
	 i_status		: integer;

	 b_prodgen_complete	: boolean;

	 Li_current_time,
	 li_start_time		: large_integer;
	 li_end_time		: large_integer;

         Li_Time_to_Wait	: Large_Integer;


      Begin  { remap }


{      ... Establish ports for communicating with the Event Handler.
{}
	 establish_job_context(	'REMAP', 			{ i }
				i_status );			{ o }

	 if not odd( i_status ) then begin
	    v50_msg := 'Error in setting up prodgen port info.';
	    goto error_exit;
	 end;

         Li_Time_to_Wait := Time_Value(	'0 00:00:2.0');



{      ... Setup remap-specific stuff.
{}
         connect_to_basedata(i_status);
{	 laps_grid;
{}
	 lut_gen;


{      ... Notify the Event Handler that remap setup is done.
{}
	 b_prodgen_complete  := true;    { --> so prodgen_job_id is sent. }
	 i_num_finished_products  := 0;	 { --> no products available yet. }

	 send_event_message( 	b_prodgen_complete,
				i_product_i4time,
				i_job_ancillary_info,
				i_num_finished_products,
				i_product_numbers,
				i_product_statuses,
				i_product_ancinfo,
				i_status );

         if not odd( i_status ) then begin
	    v50_msg	:= 'Unable to send setup-done msg to Evnt Hndlr.';
	    output_status_text( v30_routine + v50_msg, i_status );
	    goto error_exit;
         end;


	 writeln( v30_routine +
		'Successful setup-done MESSAGE TRANSMISSION to event handler');



{      ... Specify product numbers of products generated by SegCen.
{}
	 i_product_numbers[ 1 ]  := 41160;  { VRC -> Vel, Radial Component }

         i_first_scan := 999 ;

	 writeln( v30_routine, 'Starting main loop V890630... ' );


{			*************************
{				MAIN LOOP
{			*************************
{}

	 while true do begin


{         ... Wait here for message from Event Handler.
{}
	    receive_prodgen_parameters(	i_product_number,    { of data/product to work on. }
					i_product_i4time,
					i_job_ancillary_info,
					i_status );	

            if not odd( i_status ) then begin
	       v50_msg	:= 'Unable to receive prodgen job message.';
	       output_status_text( v30_routine + v50_msg, i_status );
	       goto ABORT_Current_Loop_Iteration;
            end;



{>>>>>	    writeln( v30_routine,
{			'Successful MESSAGE RECEIPT from event handler');
{}


{	  ... Extract data buffer indexes from ancillary info.
{}
	    i_vol_index   := i_job_ancillary_info[ 1 ];
	    i_scan_index  := i_job_ancillary_info[ 2 ];
	    i_scan_flags  := i_job_ancillary_info[ 3 ];

	    i_last_scan   := 0;
	    if i_scan_flags >= 256 then i_last_scan := 1;

{>>>>>	    writeln( v30_routine, 'i4time, scanindex, lastscan: ', 
{			i_product_i4time:10, i_scan_index:3, i_last_scan:3 );
{}

	    if i_scan_flags >= 256 then i_last_scan := 1;


{	  ... Create the products.
{}
	    get_time( li_start_time );

	    remap_process(	i_scan_index,			{ i }
				i_last_scan,			{ i }
				i_first_scan,			{ i }
				i_product_i4time,		{ i }
				i_product_numbers,		{ i }
				i_num_finished_products,	{ o }
				i_product_statuses,		{ o }
				i_status );			{ o }

	    get_time( li_end_time );
	    writeln( v30_routine, 
			'  #prods= ', i_num_finished_products:3,
			'  LastScan= ', odd( i_last_scan ),
			'  dt= ',
			time_string( li_start_time - li_end_time ) );



{		NOTE:  If bad status, send event message anyway.
{}
            if not odd( i_status ) then begin
	       v50_msg	:= 'Unable to create remap products.';
	       output_status_text( v30_routine + v50_msg, i_status );
            end;


{         ... Notify the Event Handler that the products are done.
{}
	    b_prodgen_complete  := true;    { --> so prodgen_job_id is sent. }

	    send_event_message( 
		b_prodgen_complete,
		i_product_i4time,
		i_job_ancillary_info,
		i_num_finished_products,
		i_product_numbers,
		i_product_statuses,
		i_product_ancinfo,
		i_status);

            if not odd( i_status ) then begin
	       v50_msg	:= 'Unable to send event_message to Event Handler.';
	       output_status_text( v30_routine + v50_msg, i_status );
	       goto ABORT_Current_Loop_Iteration;
            end;


	    writeln( v30_routine +
			'Successful MESSAGE TRANSMISSION to event handler');

         ABORT_Current_Loop_Iteration: ;

         End;  { while true }

      error_exit:
	 output_status_text( v30_routine + v50_msg, i_status );
	 writeln( v30_routine, '*** Program has CRASHED! ***' );

      End;   { remap }
End.   { -- Module remap -- }
