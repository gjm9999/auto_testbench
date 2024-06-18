package bypass_fifo_pkg;

    parameter ERROR_DEBUG_CNT = 5;
    parameter DEPTH = 8;
    parameter WIDTH = 128;

    int error_cnt = 0;
    bit check_en  = 1;

    typedef struct{
        bit [WIDTH -1:0] data_in;
        bit  data_in_power;
    } data_in_valid_struct;
    data_in_valid_struct data_in_valid_bus_q[$];

    typedef struct{
        bit [WIDTH -1:0] data_out;
    } data_out_valid_struct;
    data_out_valid_struct rm_q[$];
    data_out_valid_struct data_out_valid_bus_q[$];

endpackage
