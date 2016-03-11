vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/fifo.vhd
vcom -work work ../components/qrs_detect.vhd
vcom -work work ../components/adc_parse.vhd
vcom -work work ../components/hrv_top.vhd
#vcom -work work hrv_tb.vhd

#vsim +notimingchecks -L work work.hrv_tb -wlf vsim.wlf

#add wave -noupdate -group TEST_BENCH -radix hexadecimal /hrv_tb/*
#add wave -noupdate -expand -group TOP_LEVEL -radix hexadecimal /hrv_tb/top_inst/*
#add wave -noupdate -group INPUT_BUFFER -radix hexadecimal /hrv_tb/top_inst/input_buffer/*
#add wave -noupdate -group INPUT_READ -radix hexadecimal /hrv_tb/top_inst/input_read/*
#add wave -noupdate -group I_BUFFER -radix hexadecimal /hrv_tb/top_inst/i_buffer/*
#add wave -noupdate -group Q_BUFFER -radix hexadecimal /hrv_tb/top_inst/q_buffer/*
#add wave -noupdate -group CHANNEL_FILTER -radix hexadecimal /hrv_tb/top_inst/channel_filter/*
#add wave -noupdate -group I_FILTERED_BUFFER -radix hexadecimal /hrv_tb/top_inst/i_filtered_buffer/*
#add wave -noupdate -group Q_FILTERED_BUFFER -radix hexadecimal /hrv_tb/top_inst/q_filtered_buffer/*
#add wave -noupdate -group DEMODULATOR -radix hexadecimal /hrv_tb/top_inst/demodulator/*
#add wave -noupdate -group DEMODULATOR -radix hexadecimal /hrv_tb/top_inst/demodulator/demod_process/*
#add wave -noupdate -group RIGHT_CHANNEL_BUFFER -radix hexadecimal /hrv_tb/top_inst/right_channel_buffer/*
#add wave -noupdate -group RIGHT_LOW_FILTER -radix hexadecimal /hrv_tb/top_inst/right_low_filter/*
#add wave -noupdate -group RIGHT_LOW_BUFFER -radix hexadecimal /hrv_tb/top_inst/right_low_buffer/*
#add wave -noupdate -group LEFT_CHANNEL_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_channel_buffer/*
#add wave -noupdate -group LEFT_BAND_FILTER -radix hexadecimal /hrv_tb/top_inst/left_band_filter/*
#add wave -noupdate -group LEFT_BAND_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_band_buffer/*
#add wave -noupdate -group PRE_PILOT_BUFFER -radix hexadecimal /hrv_tb/top_inst/pre_pilot_buffer/*
#add wave -noupdate -group PILOT_FILTER -radix hexadecimal /hrv_tb/top_inst/pilot_filter/*
#add wave -noupdate -group PILOT_FILTERED_BUFFER -radix hexadecimal /hrv_tb/top_inst/pilot_filtered_buffer/*
#add wave -noupdate -group SQUARER -radix hexadecimal /hrv_tb/top_inst/squarer/*
#add wave -noupdate -group PILOT_SQUARED_BUFFER -radix hexadecimal /hrv_tb/top_inst/pilot_squared_buffer/*
#add wave -noupdate -group PILOT_SQUARED_FILTER -radix hexadecimal /hrv_tb/top_inst/pilot_squared_filter/*
#add wave -noupdate -group PILOT_BUFFER -radix hexadecimal /hrv_tb/top_inst/pilot_buffer/*
#add wave -noupdate -group MULTIPLIER -radix hexadecimal /hrv_tb/top_inst/multiplier/*
#add wave -noupdate -group LEFT_MULTIPLIED_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_multiplied_buffer/*
#add wave -noupdate -group LEFT_LOW_FILTER -radix hexadecimal /hrv_tb/top_inst/left_low_filter/*
#add wave -noupdate -group LEFT_LOW_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_low_buffer/*
#add wave -noupdate -group ADDER_SUBTRACTOR -radix hexadecimal /hrv_tb/top_inst/adder_subtractor/*
#add wave -noupdate -group LEFT_EMPH_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_emph_buffer/*
#add wave -noupdate -group RIGHT_EMPH_BUFFER -radix hexadecimal /hrv_tb/top_inst/right_emph_buffer/*
#add wave -noupdate -group DEEMPHASIZE_LEFT -radix hexadecimal /hrv_tb/top_inst/deemphasize_left/*
#add wave -noupdate -group LEFT_DEEMPH_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_deemph_buffer/*
#add wave -noupdate -group DEEMPHASIZE_RIGHT -radix hexadecimal /hrv_tb/top_inst/deemphasize_right/*
#add wave -noupdate -group RIGHT_DEEMPH_BUFFER -radix hexadecimal /hrv_tb/top_inst/right_deemph_buffer/*
#add wave -noupdate -group GAIN_LEFT -radix hexadecimal /hrv_tb/top_inst/gain_left/*
#add wave -noupdate -group LEFT_GAIN_BUFFER -radix hexadecimal /hrv_tb/top_inst/left_gain_buffer/*
#add wave -noupdate -group GAIN_RIGHT -radix hexadecimal /hrv_tb/top_inst/gain_right/*
#add wave -noupdate -group RIGHT_GAIN_BUFFER -radix hexadecimal /hrv_tb/top_inst/right_gain_buffer/*
#
##run -all
#run 100 ns
#
#configure wave -namecolwidth 325
#configure wave -valuecolwidth 100
#configure wave -timelineunits ns
#WaveRestoreZoom {0 ns} {80 ns}
