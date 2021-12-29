library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity tb_fifo is
end tb_fifo;

architecture test of tb_fifo is
    constant PERIOD1 : time := 50 ns;
    constant PERIOD2 : time := 100 ns;
    
    signal reset_n 	 : std_logic;
    signal clk1 	 : std_logic := '0';
    signal lvalid	 : std_logic := '1';
    signal fvalid	 : std_logic;
    signal wrdata	 : std_logic_vector(11 downto 0) := x"000";


    signal clk2		 : std_logic := '1';
    signal rdfifo	 : std_logic := '0';
    signal rddata	 : std_logic_vector(31 downto 0);

    signal ack		 : std_logic;
    signal new_data	 : std_logic;

begin
    inst_fifo: entity work.fifo_interface
    port map(
	reset_n => reset_n,
	clk1 => clk1,
	lvalid => lvalid,
	fvalid	=> fvalid,
	wrdata	=> wrdata,
	clk2		 => clk2,
	rdfifo		 => rdfifo,
	rddata		 => rddata,

	ack		 => ack,
	new_data	 => new_data);

    process begin
	clk1 <= not clk1;
	--lvalid <= not lvalid;
	wait for PERIOD1/2;
    end process;

    process begin
	clk2 <= not clk2;
	if new_data = '1' then
	    ack <= '1';
	else
	    ack <= '0';
	end if;
	wait for PERIOD2/2;
    end process;

    process begin
	wrdata <= not wrdata;
	if to_integer(unsigned(wrdata))=70 then
	    wait for PERIOD2*3;
	else 
	    wait for PERIOD1;
	end if;
    end process;

    process begin
	wait for PERIOD1*3;
	reset_n <= '0';
	wait for PERIOD1;
	reset_n <= '1';

	fvalid <= '1';
	wait for PERIOD1*70; --write the first frame
	fvalid <= '0';
	rdfifo <= '1';
	wait for PERIOD2*2;
	fvalid <= '1';      -- write the first frame, read out

	wait;
    end process;

end test;

