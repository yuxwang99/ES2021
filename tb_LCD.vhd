library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity tb_LCD is
end tb_LCD;

architecture test of tb_LCD is
	constant PERIOD : time := 50 ns;

	signal reset_n   :  std_logic;
	signal clk	 :  std_logic := '0';

	signal SlaveData :  std_logic_vector(15 downto 0);
	signal InputCtrl :  std_logic;
	signal FIFOData  :  std_logic_vector(31 downto 0):=x"0000_0000";
	signal FIFOempty :  std_logic := '0';
	signal RESET	 :  std_logic;
	
	signal FIFOrdreq :  std_logic := '0';

        signal LCD_ON    :  std_logic;
        signal CSX	 :  std_logic;
        signal D_CX	 :  std_logic;
        signal WRX	 :  std_logic;
        signal RDX	 :  std_logic; -- useless
        signal RESX	 :  std_logic;
        signal D	 :  std_logic_vector(15 downto 0);


begin
    inst_lcd: entity work.lcd_interface
    port map(
	reset_n => reset_n,
	clk => clk,

	SlaveData => SlaveData,
	InputCtrl => InputCtrl,
	FIFOempty => FIFOempty,
	FIFOData  => FIFOData,
	FIFOrdreq => FIFOrdreq,
	RESET	  => RESET,


	LCD_ON    => LCD_ON,
	CSX	  => CSX,
	D_CX  	  => D_CX,
	WRX       => WRX,
	RDX	  => RDX,
	RESX 	  => RESX,
	D	  => D);

    process begin
	clk <= not clk;
	--lvalid <= not lvalid;
	wait for PERIOD/2;
    end process;

    process begin
	if FIFOrdreq = '1' then
	    FIFOData  <= std_logic_vector(to_unsigned(to_integer(unsigned(FIFOdata)) + 1,32));
	end if;
	wait for PERIOD;
    end process;

    process begin
	wait for PERIOD*3;
	reset_n <= '0';
	wait for PERIOD;
	reset_n <= '1';

	InputCtrl <= '1';
	SlaveData <= x"0011";
	wait for PERIOD*10; --write the first frame
	InputCtrl <= '0';
	SlaveData <= x"0000";
	wait for PERIOD*10;

	InputCtrl <= '0';
	SlaveData <= x"0081";
	wait for PERIOD*10;

	InputCtrl <= '1';
	SlaveData <= x"00E8";
	wait for PERIOD*10;

	InputCtrl <= '0';
	SlaveData <= x"0003";
	wait for PERIOD*10;

	InputCtrl <= '1';
	SlaveData <= x"002c";
	wait for PERIOD*10;
	InputCtrl <= '0';
	wait for PERIOD*20;
	FIFOempty <= '1';
	wait for PERIOD*4;
	FIFOempty <= '0';
	wait;
    end process;
end test;

