/**
  *
  * testbench.v
  *
  */

`ifndef BP_SIM_CLK_PERIOD
`define BP_SIM_CLK_PERIOD 10
`endif

module testbench
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 import bp_me_nonsynth_pkg::*;
 #(parameter bp_params_e bp_params_p = BP_CFG_FLOWVAR // Replaced by the flow with a specific bp_cfg
   `declare_bp_proc_params(bp_params_p)

   , parameter cce_trace_p = 0
   , parameter cce_dir_trace_p = 0
   , parameter axe_trace_p = 0
   , parameter instr_count = 1
   , parameter cce_mode_p = 0
   , parameter lce_trace_p = 0
   , parameter lce_tr_trace_p = 0
   , parameter dram_trace_p = 0

   // DRAM parameters
   , parameter dram_type_p                 = BP_DRAM_FLOWVAR // Replaced by the flow with a specific dram_type

   // size of CCE-Memory buffers for cmd/resp messages
   // for this testbench (one LCE, one CCE, one memory) only need enough space to hold as many
   // cmds/responses can be generated for a single LCE request
   // 32 = 4 * 8-beat messages
   , parameter mem_buffer_els_lp         = 32

   // LCE Trace Replay Width
   , localparam lce_opcode_width_lp=$bits(bp_me_nonsynth_lce_opcode_e)
   , localparam tr_ring_width_lp=`bp_me_nonsynth_lce_tr_pkt_width(paddr_width_p, dword_width_gp)
   , localparam tr_rom_addr_width_p = 20

   `declare_bp_bedrock_lce_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce)
   )
  (output bit reset_i);

  export "DPI-C" function get_dram_period;
  export "DPI-C" function get_sim_period;

  function int get_dram_period();
    return (`dram_pkg::tck_ps);
  endfunction

  function int get_sim_period();
    return (`BP_SIM_CLK_PERIOD);
  endfunction

  `declare_bp_cfg_bus_s(hio_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p);
  `declare_bp_bedrock_lce_if(paddr_width_p, cce_block_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce);
  `declare_bp_bedrock_mem_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce);

  // Bit to deal with initial X->0 transition detection
  bit clk_i;
  bit dram_clk_i, dram_reset_i;

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
    #(.cycle_time_p(`BP_SIM_CLK_PERIOD))
    clock_gen
    (.o(clk_i));

  bsg_nonsynth_reset_gen
    #(.num_clocks_p(1)
      ,.reset_cycles_lo_p(0)
      ,.reset_cycles_hi_p(20)
      )
    reset_gen
    (.clk_i(clk_i)
      ,.async_reset_o(reset_i)
      );

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
    #(.cycle_time_p(`dram_pkg::tck_ps))
    dram_clock_gen
    (.o(dram_clk_i));

  bsg_nonsynth_reset_gen
    #(.num_clocks_p(1)
      ,.reset_cycles_lo_p(0)
      ,.reset_cycles_hi_p(10)
      )
    dram_reset_gen
    (.clk_i(dram_clk_i)
      ,.async_reset_o(dram_reset_i)
      );

  // Config bus
  bp_cfg_bus_s             cfg_bus_lo;

  // LCE-CCE IF
  bp_bedrock_lce_req_msg_s  lce_req_lo;
  bp_bedrock_lce_resp_msg_s lce_resp_lo;
  bp_bedrock_lce_cmd_msg_s  lce_cmd_lo, lce_cmd_out_lo;
  logic                     lce_req_v_lo, lce_req_ready_and_li;
  logic                     lce_resp_v_lo, lce_resp_ready_and_li;
  logic                     lce_cmd_v_lo, lce_cmd_ready_and_li;
  logic                     lce_cmd_out_v_lo, lce_cmd_out_ready_and_li;
  assign lce_cmd_out_ready_and_li = '0;

  // Trace Replay for LCE
  logic                        tr_v_li, tr_ready_lo;
  logic [tr_ring_width_lp-1:0] tr_data_li;
  logic                        tr_v_lo, tr_yumi_li;
  logic [tr_ring_width_lp-1:0] tr_data_lo;
  logic tr_done_lo;

  // Trace Replay Driver
  bsg_trace_node_master
   #(.id_p('0)
     ,.ring_width_p(tr_ring_width_lp)
     ,.rom_addr_width_p(tr_rom_addr_width_p)
     )
   trace_replay
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(1'b1)

     ,.v_i(tr_v_li)
     ,.data_i(tr_data_li)
     ,.ready_o(tr_ready_lo)

     ,.v_o(tr_v_lo)
     ,.yumi_i(tr_yumi_li)
     ,.data_o(tr_data_lo)

     ,.done_o(tr_done_lo)
     );

  // Mock LCE
  bp_me_nonsynth_mock_lce
   #(.bp_params_p(bp_params_p)
     ,.axe_trace_p(axe_trace_p)
     ,.skip_init_p(cce_mode_p)
     )
   lce
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.freeze_i(cfg_bus_lo.freeze)

     ,.lce_id_i('0)

     ,.tr_pkt_i(tr_data_lo)
     ,.tr_pkt_v_i(tr_v_lo)
     ,.tr_pkt_yumi_o(tr_yumi_li)

     ,.tr_pkt_v_o(tr_v_li)
     ,.tr_pkt_o(tr_data_li)
     ,.tr_pkt_ready_i(tr_ready_lo)

     ,.lce_req_o(lce_req_lo)
     ,.lce_req_v_o(lce_req_v_lo)
     ,.lce_req_ready_and_i(lce_req_ready_and_li)

     ,.lce_resp_o(lce_resp_lo)
     ,.lce_resp_v_o(lce_resp_v_lo)
     ,.lce_resp_ready_and_i(lce_resp_ready_and_li)

     ,.lce_cmd_i(lce_cmd_lo)
     ,.lce_cmd_v_i(lce_cmd_v_lo)
     ,.lce_cmd_ready_and_o(lce_cmd_ready_and_li)

     ,.lce_cmd_o(lce_cmd_out_lo)
     ,.lce_cmd_v_o(lce_cmd_out_v_lo)
     ,.lce_cmd_ready_and_i(lce_cmd_out_ready_and_li)
     );

  logic cce_ucode_v_li;
  logic cce_ucode_w_li;
  logic [cce_pc_width_p-1:0] cce_ucode_addr_li;
  logic [cce_instr_width_gp-1:0] cce_ucode_data_li;
  logic [cce_instr_width_gp-1:0] cce_ucode_data_lo;

  bp_bedrock_lce_req_msg_header_s lce_req_header;
  bp_bedrock_lce_resp_msg_header_s lce_resp_header;
  bp_bedrock_lce_cmd_msg_header_s lce_cmd_header;
  logic [dword_width_gp-1:0] lce_req_data, lce_resp_data, lce_cmd_data;
  logic lce_req_header_v, lce_req_header_ready_and;
  logic lce_req_data_v, lce_req_data_ready_and;
  logic lce_resp_header_v, lce_resp_header_ready_and;
  logic lce_resp_data_v, lce_resp_data_ready_and;
  logic lce_cmd_header_v, lce_cmd_header_ready_and;
  logic lce_cmd_data_v, lce_cmd_data_ready_and;
  logic lce_req_last, lce_resp_last, lce_cmd_last;
  logic lce_req_has_data, lce_resp_has_data, lce_cmd_has_data;

  bp_bedrock_cce_mem_msg_header_s mem_resp_header, mem_cmd_header;
  logic [dword_width_gp-1:0] mem_cmd_data, mem_resp_data;
  logic mem_resp_v, mem_resp_ready_and;
  logic mem_cmd_v, mem_cmd_ready_and;
  logic mem_cmd_last, mem_resp_last;

  // LCE Request Buffer
  bp_bedrock_lce_req_msg_s lce_req_l2b;
  logic                    lce_req_l2b_v, lce_req_l2b_ready_and;
  bsg_two_fifo
  #(.width_p($bits(bp_bedrock_lce_req_msg_s)))
  lce_req_buffer
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    // from LCE
    ,.v_i(lce_req_v_lo)
    ,.data_i(lce_req_lo)
    ,.ready_o(lce_req_ready_and_li)
    // to lite to burst
    ,.v_o(lce_req_l2b_v)
    ,.data_o(lce_req_l2b)
    ,.yumi_i(lce_req_l2b_v & lce_req_l2b_ready_and)
    );

  // LCE Request
  bp_me_lite_to_burst
   #(.bp_params_p(bp_params_p)
     ,.in_data_width_p(cce_block_width_p)
     ,.out_data_width_p(dword_width_gp)
     ,.payload_width_p(lce_req_payload_width_lp)
     ,.payload_mask_p(lce_req_payload_mask_gp)
     )
   lce_req_lite2burst
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.in_msg_i(lce_req_l2b)
     ,.in_msg_v_i(lce_req_l2b_v)
     ,.in_msg_ready_and_o(lce_req_l2b_ready_and)

     ,.out_msg_header_o(lce_req_header)
     ,.out_msg_header_v_o(lce_req_header_v)
     ,.out_msg_header_ready_and_i(lce_req_header_ready_and)
     ,.out_msg_has_data_o(lce_req_has_data)

     ,.out_msg_data_o(lce_req_data)
     ,.out_msg_data_v_o(lce_req_data_v)
     ,.out_msg_data_ready_and_i(lce_req_data_ready_and)
     ,.out_msg_last_o(lce_req_last)
     );

  // LCE Response Buffer
  bp_bedrock_lce_resp_msg_s lce_resp_l2b;
  logic                    lce_resp_l2b_v, lce_resp_l2b_ready_and;
  bsg_two_fifo
  #(.width_p($bits(bp_bedrock_lce_resp_msg_s)))
  lce_resp_buffer
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    // from LCE
    ,.v_i(lce_resp_v_lo)
    ,.data_i(lce_resp_lo)
    ,.ready_o(lce_resp_ready_and_li)
    // to lite to burst
    ,.v_o(lce_resp_l2b_v)
    ,.data_o(lce_resp_l2b)
    ,.yumi_i(lce_resp_l2b_v & lce_resp_l2b_ready_and)
    );

  // LCE Response
  bp_me_lite_to_burst
   #(.bp_params_p(bp_params_p)
     ,.in_data_width_p(cce_block_width_p)
     ,.out_data_width_p(dword_width_gp)
     ,.payload_width_p(lce_resp_payload_width_lp)
     ,.payload_mask_p(lce_resp_payload_mask_gp)
     )
   lce_resp_lite2burst
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.in_msg_i(lce_resp_l2b)
     ,.in_msg_v_i(lce_resp_l2b_v)
     ,.in_msg_ready_and_o(lce_resp_l2b_ready_and)

     ,.out_msg_header_o(lce_resp_header)
     ,.out_msg_header_v_o(lce_resp_header_v)
     ,.out_msg_header_ready_and_i(lce_resp_header_ready_and)
     ,.out_msg_has_data_o(lce_resp_has_data)

     ,.out_msg_data_o(lce_resp_data)
     ,.out_msg_data_v_o(lce_resp_data_v)
     ,.out_msg_data_ready_and_i(lce_resp_data_ready_and)
     ,.out_msg_last_o(lce_resp_last)
     );

  // LCE Command
  bp_me_burst_to_lite
   #(.bp_params_p(bp_params_p)
     ,.in_data_width_p(dword_width_gp)
     ,.out_data_width_p(cce_block_width_p)
     ,.payload_width_p(lce_cmd_payload_width_lp)
     ,.payload_mask_p(lce_cmd_payload_mask_gp)
     )
   lce_cmd_burst2lite
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.in_msg_header_i(lce_cmd_header)
     ,.in_msg_header_v_i(lce_cmd_header_v)
     ,.in_msg_header_ready_and_o(lce_cmd_header_ready_and)
     ,.in_msg_has_data_i(lce_cmd_has_data)

     ,.in_msg_data_i(lce_cmd_data)
     ,.in_msg_data_v_i(lce_cmd_data_v)
     ,.in_msg_data_ready_and_o(lce_cmd_data_ready_and)
     ,.in_msg_last_i(lce_cmd_last)

     ,.out_msg_o(lce_cmd_lo)
     ,.out_msg_v_o(lce_cmd_v_lo)
     ,.out_msg_ready_and_i(lce_cmd_ready_and_li)
     );

  // CCE
  wrapper
  #(.bp_params_p(bp_params_p)
    ,.cce_trace_p(cce_trace_p)
   )
  wrapper
   (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.cfg_bus_i(cfg_bus_lo)

    ,.ucode_v_i(cce_ucode_v_li)
    ,.ucode_w_i(cce_ucode_w_li)
    ,.ucode_addr_i(cce_ucode_addr_li)
    ,.ucode_data_i(cce_ucode_data_li)
    ,.ucode_data_o(cce_ucode_data_lo)

    // LCE-CCE Interface
    // BedRock Burst protocol: ready&valid
    ,.lce_req_header_i(lce_req_header)
    ,.lce_req_header_v_i(lce_req_header_v)
    ,.lce_req_header_ready_and_o(lce_req_header_ready_and)
    ,.lce_req_has_data_i(lce_req_has_data)
    ,.lce_req_data_i(lce_req_data)
    ,.lce_req_data_v_i(lce_req_data_v)
    ,.lce_req_data_ready_and_o(lce_req_data_ready_and)
    ,.lce_req_last_i(lce_req_last)

    ,.lce_resp_header_i(lce_resp_header)
    ,.lce_resp_header_v_i(lce_resp_header_v)
    ,.lce_resp_header_ready_and_o(lce_resp_header_ready_and)
    ,.lce_resp_has_data_i(lce_resp_has_data)
    ,.lce_resp_data_i(lce_resp_data)
    ,.lce_resp_data_v_i(lce_resp_data_v)
    ,.lce_resp_data_ready_and_o(lce_resp_data_ready_and)
    ,.lce_resp_last_i(lce_resp_last)

    ,.lce_cmd_header_o(lce_cmd_header)
    ,.lce_cmd_header_v_o(lce_cmd_header_v)
    ,.lce_cmd_header_ready_and_i(lce_cmd_header_ready_and)
    ,.lce_cmd_has_data_o(lce_cmd_has_data)
    ,.lce_cmd_data_o(lce_cmd_data)
    ,.lce_cmd_data_v_o(lce_cmd_data_v)
    ,.lce_cmd_data_ready_and_i(lce_cmd_data_ready_and)
    ,.lce_cmd_last_o(lce_cmd_last)

    // CCE-MEM Interface
    // BedRock Stream protocol: ready&valid
    ,.mem_resp_header_i(mem_resp_header)
    ,.mem_resp_data_i(mem_resp_data)
    ,.mem_resp_v_i(mem_resp_v)
    ,.mem_resp_ready_and_o(mem_resp_ready_and)
    ,.mem_resp_last_i(mem_resp_last)

    ,.mem_cmd_header_o(mem_cmd_header)
    ,.mem_cmd_data_o(mem_cmd_data)
    ,.mem_cmd_v_o(mem_cmd_v)
    ,.mem_cmd_ready_and_i(mem_cmd_ready_and)
    ,.mem_cmd_last_o(mem_cmd_last)
  );

  // Memory Command Buffer
  bp_bedrock_cce_mem_msg_header_s mem_cmd_lo;
  logic [dword_width_gp-1:0] mem_cmd_data_lo;
  logic mem_cmd_v_lo, mem_cmd_ready_and_li, mem_cmd_yumi_li, mem_cmd_last_lo;
  bsg_fifo_1r1w_small
  #(.width_p($bits(bp_bedrock_cce_mem_msg_header_s)+dword_width_gp+1)
    ,.els_p(mem_buffer_els_lp)
    )
  mem_cmd_stream_buffer
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    // from CCE
    ,.v_i(mem_cmd_v)
    ,.ready_o(mem_cmd_ready_and)
    ,.data_i({mem_cmd_last, mem_cmd_data, mem_cmd_header})
    // to memory
    ,.v_o(mem_cmd_v_lo)
    ,.yumi_i(mem_cmd_yumi_li)
    ,.data_o({mem_cmd_last_lo, mem_cmd_data_lo, mem_cmd_lo})
    );
  assign mem_cmd_yumi_li = mem_cmd_v_lo & mem_cmd_ready_and_li;

  // Memory Response Buffer
  bp_bedrock_cce_mem_msg_header_s mem_resp_li;
  logic [dword_width_gp-1:0] mem_resp_data_li;
  logic mem_resp_v_li, mem_resp_ready_and_lo, mem_resp_last_li, mem_resp_yumi_lo;
  bsg_fifo_1r1w_small
  #(.width_p($bits(bp_bedrock_cce_mem_msg_header_s)+dword_width_gp+1)
    ,.els_p(mem_buffer_els_lp)
    )
  mem_resp_stream_buffer
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    // from memory
    ,.v_i(mem_resp_v_li)
    ,.ready_o(mem_resp_ready_and_lo)
    ,.data_i({mem_resp_last_li, mem_resp_data_li, mem_resp_li})
    // to CCE
    ,.v_o(mem_resp_v)
    ,.yumi_i(mem_resp_yumi_lo)
    ,.data_o({mem_resp_last, mem_resp_data, mem_resp_header})
    );
  assign mem_resp_yumi_lo = mem_resp_v & mem_resp_ready_and;

  bp_nonsynth_mem
   #(.bp_params_p(bp_params_p)
     ,.preload_mem_p(0)
     ,.dram_type_p(dram_type_p)
     ,.mem_els_p(2**20)
     )
   mem
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.mem_cmd_header_i(mem_cmd_lo)
     ,.mem_cmd_data_i(mem_cmd_data_lo)
     ,.mem_cmd_v_i(mem_cmd_v_lo)
     ,.mem_cmd_ready_and_o(mem_cmd_ready_and_li)
     ,.mem_cmd_last_i(mem_cmd_last_lo)

     ,.mem_resp_header_o(mem_resp_li)
     ,.mem_resp_data_o(mem_resp_data_li)
     ,.mem_resp_v_o(mem_resp_v_li)
     ,.mem_resp_ready_and_i(mem_resp_ready_and_lo)
     ,.mem_resp_last_o(mem_resp_last_li)

     ,.dram_clk_i(dram_clk_i)
     ,.dram_reset_i(dram_reset_i)
     );

  // Tracers and binds

  bp_mem_nonsynth_tracer
   #(.bp_params_p(bp_params_p))
   bp_mem_tracer
    (.clk_i(clk_i & (testbench.dram_trace_p == 1))
     ,.reset_i(reset_i)

     ,.mem_cmd_header_i(mem_cmd_lo)
     ,.mem_cmd_data_i(mem_cmd_data_lo)
     ,.mem_cmd_v_i(mem_cmd_v_lo)
     ,.mem_cmd_ready_and_i(mem_cmd_ready_and_li)
     ,.mem_cmd_last_i(mem_cmd_last_lo)

     ,.mem_resp_header_i(mem_resp_li)
     ,.mem_resp_data_i(mem_resp_data_li)
     ,.mem_resp_v_i(mem_resp_v_li)
     ,.mem_resp_ready_and_i(mem_resp_ready_and_lo)
     ,.mem_resp_last_i(mem_resp_last_li)
     );

  bind bp_me_nonsynth_mock_lce
    bp_me_nonsynth_lce_tracer
      #(.bp_params_p(bp_params_p)
        ,.sets_p(sets_p)
        ,.assoc_p(assoc_p)
        ,.block_width_p(cce_block_width_p)
        )
      lce_tracer
       (.clk_i(clk_i & (testbench.lce_trace_p == 1))
        ,.reset_i(reset_i)
        ,.lce_id_i(lce_id_i)
        ,.lce_req_i(lce_req_o)
        ,.lce_req_v_i(lce_req_v_o)
        ,.lce_req_ready_and_i(lce_req_ready_and_i)
        ,.lce_resp_i(lce_resp_o)
        ,.lce_resp_v_i(lce_resp_v_o)
        ,.lce_resp_ready_and_i(lce_resp_ready_and_i)
        ,.lce_cmd_i(lce_cmd_i)
        ,.lce_cmd_v_i(lce_cmd_v_i)
        ,.lce_cmd_ready_and_i(lce_cmd_ready_and_o)
        ,.lce_cmd_o_i(lce_cmd_o)
        ,.lce_cmd_o_v_i(lce_cmd_v_o)
        ,.lce_cmd_o_ready_and_i(lce_cmd_ready_and_i)
        );

  bind bp_me_nonsynth_mock_lce
    bp_me_nonsynth_lce_tr_tracer
      #(.bp_params_p(bp_params_p)
        ,.sets_p(sets_p)
        ,.block_width_p(cce_block_width_p)
        )
      lce_tr_tracer
       (.clk_i(clk_i & (testbench.lce_tr_trace_p == 1))
        ,.reset_i(reset_i)
        ,.lce_id_i(lce_id_i)
        ,.tr_pkt_i(tr_pkt_i)
        ,.tr_pkt_v_i(tr_pkt_v_i)
        ,.tr_pkt_yumi_i(tr_pkt_yumi_o)
        ,.tr_pkt_o_i(tr_pkt_o)
        ,.tr_pkt_v_o_i(tr_pkt_v_o)
        ,.tr_pkt_ready_i(tr_pkt_ready_i)
        );

  bind bp_cce_wrapper
    bp_me_nonsynth_cce_tracer
      #(.bp_params_p(bp_params_p))
      cce_tracer
       (.clk_i(clk_i & (testbench.cce_trace_p == 1))
        ,.reset_i(reset_i)
        ,.freeze_i(cfg_bus_cast_i.freeze)

        ,.cce_id_i(cfg_bus_cast_i.cce_id)

        // LCE-CCE Interface
        // BedRock Burst protocol: ready&valid
        ,.lce_req_header_i(lce_req_header_i)
        ,.lce_req_header_v_i(lce_req_header_v_i)
        ,.lce_req_header_ready_and_i(lce_req_header_ready_and_o)
        ,.lce_req_data_i(lce_req_data_i)
        ,.lce_req_data_v_i(lce_req_data_v_i)
        ,.lce_req_data_ready_and_i(lce_req_data_ready_and_o)

        ,.lce_resp_header_i(lce_resp_header_i)
        ,.lce_resp_header_v_i(lce_resp_header_v_i)
        ,.lce_resp_header_ready_and_i(lce_resp_header_ready_and_o)
        ,.lce_resp_data_i(lce_resp_data_i)
        ,.lce_resp_data_v_i(lce_resp_data_v_i)
        ,.lce_resp_data_ready_and_i(lce_resp_data_ready_and_o)

        ,.lce_cmd_header_i(lce_cmd_header_o)
        ,.lce_cmd_header_v_i(lce_cmd_header_v_o)
        ,.lce_cmd_header_ready_and_i(lce_cmd_header_ready_and_i)
        ,.lce_cmd_data_i(lce_cmd_data_o)
        ,.lce_cmd_data_v_i(lce_cmd_data_v_o)
        ,.lce_cmd_data_ready_and_i(lce_cmd_data_ready_and_i)

        // CCE-MEM Interface
        // BedRock Burst protocol: ready&valid
        ,.mem_resp_header_i(mem_resp_header_i)
        ,.mem_resp_data_i(mem_resp_data_i)
        ,.mem_resp_v_i(mem_resp_v_i)
        ,.mem_resp_ready_and_i(mem_resp_ready_and_o)
        ,.mem_resp_last_i(mem_resp_last_i)

        ,.mem_cmd_header_i(mem_cmd_header_o)
        ,.mem_cmd_data_i(mem_cmd_data_o)
        ,.mem_cmd_v_i(mem_cmd_v_o)
        ,.mem_cmd_ready_and_i(mem_cmd_ready_and_i)
        ,.mem_cmd_last_i(mem_cmd_last_o)
        );

  bind bp_cce_dir
    bp_me_nonsynth_cce_dir_tracer
      #(.bp_params_p(bp_params_p))
      cce_dir_tracer
       (.clk_i(clk_i & (testbench.cce_dir_trace_p == 1))
        ,.reset_i(reset_i)

        ,.cce_id_i(cce_id_i)
        ,.addr_i(addr_i)
        ,.addr_bypass_i(addr_bypass_i)
        ,.lce_i(lce_i)
        ,.way_i(way_i)
        ,.lru_way_i(lru_way_i)
        ,.coh_state_i(coh_state_i)
        ,.addr_dst_gpr_i(addr_dst_gpr_i)
        ,.cmd_i(cmd_i)
        ,.r_v_i(r_v_i)
        ,.w_v_i(w_v_i)
        ,.busy_i(busy_o)
        ,.sharers_v_i(sharers_v_o)
        ,.sharers_hits_i(sharers_hits_o)
        ,.sharers_ways_i(sharers_ways_o)
        ,.sharers_coh_states_i(sharers_coh_states_o)
        ,.lru_v_i(lru_v_o)
        ,.lru_coh_state_i(lru_coh_state_o)
        ,.lru_addr_i(lru_addr_o)
        ,.addr_v_i(addr_v_o)
        ,.addr_o_i(addr_o)
        ,.addr_dst_gpr_o_i(addr_dst_gpr_o)
        );

  // Config
  bp_bedrock_cce_mem_msg_header_s cfg_mem_cmd_lo;
  logic [dword_width_gp-1:0] cfg_mem_cmd_data_lo;
  logic cfg_mem_cmd_v_lo, cfg_mem_cmd_ready_and_li, cfg_mem_cmd_last_lo;
  logic cfg_mem_resp_v_lo;

  logic cfg_loader_done_lo;
  localparam cce_instr_ram_addr_width_lp = `BSG_SAFE_CLOG2(num_cce_instr_ram_els_p);
  bp_cce_mmio_cfg_loader
    #(.bp_params_p(bp_params_p)
      ,.inst_width_p($bits(bp_cce_inst_s))
      ,.inst_ram_addr_width_p(cce_instr_ram_addr_width_lp)
      ,.inst_ram_els_p(num_cce_instr_ram_els_p)
      ,.skip_ram_init_p(cce_mode_p)
      ,.clear_freeze_p(1'b1)
    )
    cfg_loader
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.lce_id_i('0)

     ,.io_cmd_header_o(cfg_mem_cmd_lo)
     ,.io_cmd_data_o(cfg_mem_cmd_data_lo)
     ,.io_cmd_v_o(cfg_mem_cmd_v_lo)
     ,.io_cmd_yumi_i(cfg_mem_cmd_ready_and_li & cfg_mem_cmd_v_lo)
     ,.io_cmd_last_o(cfg_mem_cmd_last_lo)

     ,.io_resp_header_i('0)
     ,.io_resp_data_i('0)
     ,.io_resp_v_i(cfg_mem_resp_v_lo)
     ,.io_resp_ready_and_o()
     ,.io_resp_last_i('0)

     ,.done_o(cfg_loader_done_lo)
     );

  logic [coh_noc_cord_width_p-1:0] cord_li = {{coh_noc_y_cord_width_p'(1'b1)}, {coh_noc_x_cord_width_p'('0)}};
  bp_me_cfg
   #(.bp_params_p(bp_params_p))
   cfg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.mem_cmd_header_i(cfg_mem_cmd_lo)
     ,.mem_cmd_data_i(cfg_mem_cmd_data_lo)
     ,.mem_cmd_v_i(cfg_mem_cmd_v_lo)
     ,.mem_cmd_ready_and_o(cfg_mem_cmd_ready_and_li)
     ,.mem_cmd_last_i(cfg_mem_cmd_last_lo)

     ,.mem_resp_header_o()
     ,.mem_resp_data_o()
     ,.mem_resp_v_o(cfg_mem_resp_v_lo)
     ,.mem_resp_ready_and_i(cfg_mem_resp_v_lo)
     ,.mem_resp_last_o()

     ,.cfg_bus_o(cfg_bus_lo)
     ,.did_i('0)
     ,.host_did_i('0)
     ,.cord_i(cord_li)

     ,.cce_ucode_v_o(cce_ucode_v_li)
     ,.cce_ucode_w_o(cce_ucode_w_li)
     ,.cce_ucode_addr_o(cce_ucode_addr_li)
     ,.cce_ucode_data_o(cce_ucode_data_li)
     ,.cce_ucode_data_i(cce_ucode_data_lo)
     );

  // Parameter Verification
  bp_nonsynth_if_verif
   #(.bp_params_p(bp_params_p))
   if_verif
    ();

  // Program done info
  localparam max_clock_cnt_lp    = 2**30-1;
  localparam lg_max_clock_cnt_lp = `BSG_SAFE_CLOG2(max_clock_cnt_lp);
  logic [lg_max_clock_cnt_lp-1:0] clock_cnt;

  bsg_counter_clear_up
   #(.max_val_p(max_clock_cnt_lp)
     ,.init_val_p(0)
     )
   clock_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.clear_i(reset_i)
     ,.up_i(1'b1)

     ,.count_o(clock_cnt)
     );

  always_ff @(negedge clk_i) begin
    if (tr_done_lo) begin
      $display("Bytes: %d Clocks: %d mBPC: %d "
               , instr_count*64
               , clock_cnt
               , (instr_count*64*1000) / clock_cnt
               );
      $display("Test PASSed");
      $finish(0);
    end
  end

  `ifndef VERILATOR
    initial
      begin
        $assertoff();
        @(posedge clk_i);
        @(negedge reset_i);
        $asserton();
      end
  `endif

endmodule

