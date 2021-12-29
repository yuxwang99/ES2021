library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity tb_avalonlcd is
end tb_avalonlcd;

architecture test_lcd of tb_avalonlcd is 
    	constant PERIOD : time := 50 ns;

 	signal Clk :  std_logic := '0';
 	signal Reset_n :  std_logic;

	-- Avalon Slave : 
 	signal AS_Adr : std_logic_vector(1 downto 0);
 	signal AS_CS :  std_logic;
 	signal AS_Write :  std_logic;
 	signal AS_Read :  std_logic;
 	signal AS_WriteData :  std_logic_vector(31 downto 0) ; 
 	signal AS_DataRead :  std_logic_vector(31 downto 0):=x"0000_0000" ; 
	signal SlaveData :  std_logic_vector(15 downto 0);
	signal InputCtrl :  std_logic;

	signal wrreq	:     std_logic;
	signal data 	:     std_logic_vector(31 downto 0) ; 
	signal reset   :     std_logic;
	-- Avalon Master : 
	signal almost_full :  std_logic;

 	signal AM_readdatavalid :  std_logic; 
 	signal AM_ReadData :  std_logic_vector(31 downto 0) ; 
 	signal AM_waitrequest :  std_logic;

	signal AM_burstcound :  std_logic_vector(3 downto 0) ; 
 	signal AM_Write :  std_logic;
 	signal AM_Read : std_logic;
 	signal AM_DataWrite :  std_logic_vector(31 downto 0);
 	signal AM_Adr :  std_logic_vector(31 downto 0);
	signal masterStart : std_logic;

begin

    instavalon : entity work.RecModule
    port map(
	clk	  => Clk,
	reset_n   => Reset_n,

	-- Avalon Slave : 
	MasterStart => MasterStart,
 	AS_Adr 	  => AS_Adr,
 	AS_CS 	  => AS_CS,
 	AS_Write  => AS_Write,
 	AS_Read   => AS_Read,
 	AS_WriteData => AS_WriteData,
 	AS_DataRead  => AS_DataRead,
	SlaveData    => SlaveData,
	InputCtrl    => InputCtrl,

	wrreq	     => wrreq,
	data 	     => data,
	reset        => reset,
	-- Avalon Master : 
	almost_full  => almost_full,

 	AM_readdatavalid => AM_readdatavalid,
 	AM_ReadData 	 => AM_ReadData,
 	AM_waitrequest   => AM_waitrequest,

	AM_burstcound 	=> AM_burstcound,
 	AM_Write 	=> AM_Write,
 	AM_Read 	=> AM_Read,
 	AM_DataWrite    => AM_DataWrite,
 	AM_Adr 		=> AM_Adr
    );

    process begin
	Clk <= not Clk;
	wait for PERIOD/2;
    end process;

    process begin
	AM_ReadData  <= std_logic_vector(to_unsigned(to_integer(unsigned(AM_ReadData)) + 1,32));
	wait for 4*PERIOD;
    end process;

    process begin
	almost_full <= '1';
	Reset_n <= '1';
	wait for PERIOD*5;
	Reset_n <= '0';
	wait for PERIOD;
	Reset_n <= '1';
	wait for PERIOD*2;

	masterStart <= '1';
	AM_waitrequest <= '0';

	wait for PERIOD*2;
	AM_readdatavalid <= '1';
	wait for PERIOD*2;

	AM_readdatavalid <= '0';
	wait for PERIOD*10;
	AM_readdatavalid <= '1';
	wait for PERIOD*6;
	AM_readdatavalid <= '0';
	wait for PERIOD*4;
	almost_full <= '0';
	wait;
    end process;

end test_lcd;


