library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;

entity fir is
    generic
    (
        TAPS : natural := 20
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        coeffs : in quant_array (0 to TAPS - 1);
        in_empty : in std_logic;
        out_full : in std_logic;
        in_rd_en : out std_logic;
        dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        out_wr_en : out std_logic
    );
end entity;

architecture behavioral of fir is
    signal state, next_state : standard_state_type := init;
    signal data_buffer, data_buffer_c : quant_array (0 to TAPS - 1);
begin

    filter_process : process (state, data_buffer, din, in_empty, out_full, coeffs)
        variable sum : signed (WORD_SIZE - 1 downto 0) := (others => '0');
        variable data_buffer_v : quant_array (0 to TAPS - 1);
    begin
        next_state <= state;
        data_buffer_c <= data_buffer;

        in_rd_en <= '0';
        out_wr_en <= '0';
        dout <= (others => '0');

        sum := (others => '0');

        case (state) is
            when init =>
                if (in_empty = '0') then
                    next_state <= exec;
                   -- in_rd_en <= '1';
                   -- data_buffer_c(0) <= din;
                end if;

            when exec =>
                if (in_empty = '0' and out_full = '0') then
                    in_rd_en <= '1';
                    for i in TAPS - 1 downto 1 loop
                        -- shift buffer
                        data_buffer_v(i) := data_buffer(i - 1);
                    end loop;
                    data_buffer_v(0) := din;
                    data_buffer_c <= data_buffer_v;
                    for i in 0 to TAPS - 1 loop
                        sum := sum + signed(DEQUANTIZE(signed(coeffs(TAPS - 1 - i)) * signed(data_buffer_v(i))));
                    end loop;
                    dout <= std_logic_vector(sum);
                    out_wr_en <= '1';
                    next_state <= exec;
                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            data_buffer <= (others => (others => '0'));
        elsif (rising_edge(clock)) then
            state <= next_state;
            data_buffer <= data_buffer_c;
        end if;
    end process;

end architecture;
