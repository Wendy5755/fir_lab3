module fir 
#(  parameter pADDR_WIDTH = 12,
           parameter pDATA_WIDTH = 32,
           parameter Tape_Num    = 11
  )
  (
       output  wire                     awready,
       output  wire                     wready,
       input   wire                     awvalid,
       input   wire [(pADDR_WIDTH-1):0] awaddr,
       input   wire                     wvalid,
       input   wire [(pDATA_WIDTH-1):0] wdata,
       output  wire                     arready,
       input   wire                     rready,
       input   wire                     arvalid,
       input   wire [(pADDR_WIDTH-1):0] araddr,
       output  wire                     rvalid,
       output  wire [(pDATA_WIDTH-1):0] rdata,
       input   wire                     ss_tvalid,
       input   wire [(pDATA_WIDTH-1):0] ss_tdata,
       input   wire                     ss_tlast,
       output  wire                     ss_tready,
       input   wire                     sm_tready,
       output  wire                     sm_tvalid,
       output  wire [(pDATA_WIDTH-1):0] sm_tdata,
       output  wire                     sm_tlast,

       // bram for tap RAM
       output  wire           [3:0]     tap_WE,
       output  wire                     tap_EN,
       output  wire [(pDATA_WIDTH-1):0] tap_Di,
       output  wire [(pADDR_WIDTH-1):0] tap_A,
       input   wire [(pDATA_WIDTH-1):0] tap_Do,

       // bram for data RAM
       output  wire            [3:0]    data_WE,
       output  wire                     data_EN,
       output  wire [(pDATA_WIDTH-1):0] data_Di,
       output  wire [(pADDR_WIDTH-1):0] data_A,
       input   wire [(pDATA_WIDTH-1):0] data_Do,

       input   wire                     axis_clk,
       input   wire                     axis_rst_n
   );

//fir EN
wire firEN;
reg firEN_temp;
assign firEN = firEN_temp;

wire ftap_ready, ftap_valid;
assign firEN = ftap_valid & ftap_ready;
reg ftap_ready_temp;

reg ftap_valid_temp; 
assign ftap_valid = ftap_valid_temp;

reg [pADDR_WIDTH-1:0]fd_addr_temp; 
reg [pADDR_WIDTH-1:0]ft_addr_temp;
assign fd_addr = fd_addr_temp;
assign ft_addr = ft_addr_temp;

wire [3:0] firc;
reg[3:0] firc_temp;
assign firc = firc_temp;

reg [pADDR_WIDTH-1:0]ftlast_addr_temp;

always@(posedge axis_clk) begin
    if (!axis_rst_n) begin
        fd_addr_temp <= 0;
        ft_addr_temp <= 0;
        firEN_temp <= 0;
        ftap_valid_temp <= 0;
        firc_temp <= 0;
    end
    else if(firEN) begin
		if(firc == Tape_Num)begin
			ftap_valid_temp <= 0;
			fd_addr_temp <= 0;
			firc_temp <= 0;
			ft_addr_temp=ftlast_addr_temp;					
		end
		else if(ft_addr_temp==0)
			ft_addr_temp=12'd40;
				
		else if(firc == 0 && !ft_addr == 12'd40)
			ft_addr_temp <= ft_addr_temp+4;
		else if(firc == 0 && ft_addr == 12'd40)
			ftlast_addr_temp <= 0;
		else begin
			ftap_valid_temp <= 1;
			fd_addr_temp <= fd_addr_temp+4;
			ft_addr_temp <= ft_addr_temp-4;
			ftlast_addr_temp <= ftlast_addr_temp;
			firc_temp <= firc_temp+1;

		end

        firc_temp <= 1;
    end
    else begin
        ftap_valid_temp <= 1;
        firc_temp <= 0;
    end
end

//Stream_w

wire [pADDR_WIDTH-1:0] data_wa;
reg [pADDR_WIDTH-1:0] data_wa_temp;
assign data_wa = data_wa_temp;

reg [pDATA_WIDTH-1:0] data_Di_temp;
reg [3:0]             data_WE_temp;
assign data_WE = data_WE_temp ;

assign data_Di = data_Di_temp;//
reg [3:0]   counts_temp;

reg ss_tready_temp;
assign ss_tready = ss_tready_temp;

wire [3:0]counts;
assign counts = counts_temp;

reg EN_swrite,EN_sread ,EN_read;

reg spre_temp;
wire spre;
assign spre = spre_temp;

wire    sread_valid;
reg     sread_valid_temp;
assign  sread_valid = sread_valid_temp;

wire    swrite_valid;
assign swrite_valid = ~ sread_valid;

always @( posedge axis_clk ) begin
    if ( !axis_rst_n ) begin
        ss_tready_temp<= 0;
        data_wa_temp <= 0;
        counts_temp <= 0;
        spre_temp <= 0;

        sread_valid_temp <= 0;
    end
    else begin
        if (!ss_tready && ss_tvalid) begin
           
              //prepare  
              if((counts <= 10) && !spre) begin
                       data_WE_temp <= 4'b1111;
                       
		       if(counts == 0) 
				data_wa_temp <= 0;
		       else
				data_wa_temp <= data_wa_temp + 4;
		       data_Di_temp <= 0;
                       counts_temp <= counts_temp + 1;
                       EN_swrite <= 1;

              end
              else begin
                       spre_temp <= 1;
                       counts_temp <= 10;
		       data_WE_temp <= 0;
                       EN_swrite <= 0;                      
              end

              //start  
              if(swrite_valid) begin
		      
                       ss_tready_temp <= 1;
                       data_WE_temp <= 4'b1111;//we
                       
		       if(counts == 10)begin
			 	data_wa_temp <=0;
				counts_temp <= 0;
		       end
		       else begin
				data_wa_temp <= data_wa_temp+4;
		       		counts_temp <= counts_temp+1;
		       end
                       data_Di_temp <= ss_tdata;
		       sread_valid_temp <= 1;
		       EN_swrite <= 1;

              end
              else if (sm_tvalid)
                       sread_valid_temp <= 0;
              else begin
                       ss_tready_temp <= 0;
                       data_WE_temp <= 0;
		       spre_temp <= 1;

              end
              
        end
        else begin

            data_WE_temp <= 4'b0;
            EN_swrite <= 0;
            ss_tready_temp <= 0;
        end

    end

end

//Lite_w
reg awready_temp, wready_temp;
assign awready = awready_temp;
assign wready = wready_temp;

wire [pADDR_WIDTH-1:0] tap_wa;
reg [pADDR_WIDTH-1:0] tap_wa_temp;
reg [pDATA_WIDTH-1:0] tap_Di_temp;
assign tap_wa = tap_wa_temp;
assign tap_Di = tap_Di_temp;
reg ap_start_on;

always @( posedge axis_clk ) begin
    if ( !axis_rst_n ) begin
        awready_temp <= 0;
        wready_temp <= 0;
        ap_start_on <= 0;
    end
    else begin
        if (!awready && awvalid) begin
            if(awaddr>=12'h20 && awaddr<=12'h60) 
		begin
                  awready_temp <= 1;
                  tap_wa_temp <= awaddr-12'h20;//>20
                end
            else
                awready_temp <= 0;
        end
        else 
            awready_temp <= 0;
        

        if (!wready && wvalid) begin
            wready_temp <= 1;
	    if(awaddr==0 && wdata==1)
                ap_start_on <= 1;
            else if(awaddr>=12'h20 && awaddr<=12'h60)//12~60
                tap_Di_temp <= wdata;
            

        end
        else begin
            wready_temp <= 0;
            ap_start_on <= 0;
        end

    end
end

//Stream_r
reg tap_EN_sread,tap_EN_read ;
reg [pADDR_WIDTH-1:0] tRA_lite, tRA_stream;
wire [pADDR_WIDTH-1:0] tap_ra;
assign tap_ra = (tap_EN_sread) ? tRA_stream : tRA_lite;

assign data_EN = EN_swrite | EN_read;//

always@(posedge axis_clk) 
    EN_read <= EN_sread;

wire [pADDR_WIDTH-1:0] data_RA;
reg [pADDR_WIDTH-1:0] data_RA_temp;
assign data_RA = data_RA_temp;//

assign data_A =(EN_swrite) ? data_wa :
       (EN_sread) ? data_RA : 0;//

reg sm_tvalid_temp;
assign sm_tvalid = sm_tvalid_temp;//

//cof
reg  [pDATA_WIDTH-1:0]  sm_tdata_temp;
assign  sm_tdata = sm_tdata_temp;//
reg     sm_tlast_temp;
assign  sm_tlast = sm_tlast_temp;//


always @( posedge axis_clk ) begin
    if ( !axis_rst_n ) begin
        sm_tvalid_temp <= 0;
        EN_sread <= 0;
        tap_EN_sread <= 0;
    end
    else begin
        if (sm_tready && !sm_tvalid) begin//
           
                if(sread_valid&&ftap_valid ) begin
                      sm_tvalid_temp <= 0;
                      EN_sread <= 1;
                      tap_EN_sread <= 1;

                      data_RA_temp <= fd_addr;
                      tRA_stream <= ft_addr;
		      ftap_ready_temp <= 1;

                end
                else 
                      sm_tvalid_temp <= 1;
		      ftap_ready_temp <= 0;
           
        end
    
    end
end

//Lite_r
reg arready_temp, rvalid_temp;
assign arready = arready_temp;//
assign rvalid = rvalid_temp;//

assign tap_EN = {awready & wready} | tap_EN_read ;//

always @( posedge axis_clk ) begin
    tap_EN_read <= {arvalid & arready} | tap_EN_sread;
end

assign tap_A = ({awready & wready}) ? tap_wa :
       ({arvalid & arready} | tap_EN_sread) ? tap_ra : 0;//

always @( posedge axis_clk ) begin
    if ( !axis_rst_n ) begin
        arready_temp <= 0;
        rvalid_temp <= 0;
    end
    else begin
        if(!arready && arvalid && !rvalid) begin
            if(araddr>=12'h20 && araddr<=12'h60) begin
                arready_temp <= 1;
                tRA_lite <= araddr-12'h20;
            end
            else if(araddr==0) begin
                arready_temp <= 1;
            end
            else
                arready_temp <= 0;

        end
        else if(arready && arvalid && !rvalid) begin
            arready_temp <= 0;
            rvalid_temp <= 1;
        end
        else begin
            arready_temp <= 0;
            rvalid_temp <= 0;
        end
    end
end
reg [pDATA_WIDTH-1:0] data_in_temp;
assign data_in = data_in_temp ;

always@(*) begin
      		//pre
            if(araddr==0 && rvalid)
                data_in_temp =32'h00;
            else if(araddr==0 && rvalid && ap_start_on)
                data_in_temp =32'h01;//at wa[1]
            else
                data_in_temp = tap_Do;
      		//start
            if(araddr==0 && rvalid)
                data_in_temp =32'h00;//at wa[0]
            else
                data_in_temp = tap_Do;

        	//done
            if(araddr==0 && rvalid)
                data_in_temp =32'h06;//at wa[6]
            else
                data_in_temp = tap_Do;
    
end

//cau fir
wire  [pDATA_WIDTH-1:0] ramd, cofd;

reg [pDATA_WIDTH-1:0] last_ramd_temp; 
reg [pDATA_WIDTH-1:0] last_cofd_temp;
wire [pDATA_WIDTH-1:0] last_ramd, last_cofd;
assign last_ramd = last_ramd_temp;
assign last_cofd = last_cofd_temp;
wire [pDATA_WIDTH-1:0] next_ramd, next_cofd;
assign next_ramd = data_Do;
assign next_cofd = tap_Do;

always@(posedge axis_clk) begin
    if(firEN) begin
        last_ramd_temp <= next_ramd;
        last_cofd_temp <= next_cofd;
    end
end

assign ramd = ~firEN ?  last_ramd : next_ramd;
assign cofd = ~firEN ?  last_cofd : next_cofd;

always@(posedge axis_clk) begin
    if(!axis_rst_n)
        sm_tdata_temp<=0;
    else if(sm_tvalid)
        sm_tdata_temp<=0;
    else if(firEN)
        sm_tdata_temp <= sm_tdata_temp +(ramd*cofd);

end
endmodule



