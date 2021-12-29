library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity tb_camctrl is
end tb_camctrl;

architecture test of tb_camctrl is
    constant PERIOD : time := 50 ns;
 
    signal Clk : std_logic := '0';
    signal Reset_n : std_logic;

    signal lvalid	 : std_logic;
    signal fvalid	 : std_logic;
    signal cameradata	 : std_logic_vector(11 downto 0):= x"000";
    signal cameraclk	 : std_logic;
    signal Acq_new	 : std_logic;

	-- avalon
    signal AS_Adr  	 : std_logic_vector(1 downto 0);
    signal AS_CS 	 : std_logic:= '1';
    signal AS_Write 	 : std_logic;
    signal AS_Read 	 : std_logic;
    signal AS_DataWrite  : std_logic_vector(31 downto 0) ; 
    signal AS_DataRead   : std_logic_vector(31 downto 0) ; 

    signal AM_Adr 	 : std_logic_vector(31 downto 0) ; 
    signal AM_ByteEnable : std_logic_vector(3 downto 0) ; 
    signal AM_Write      : std_logic;
    signal AM_Read 	 : std_logic;
    signal AM_DataWrite  : std_logic_vector(31 downto 0) ; 
    signal AM_DataRead   : std_logic_vector(31 downto 0) ; 
    signal AM_WaitRequest: std_logic:= '0';

begin

    inst_ctrl : entity work.controller
    port map(
	Clk => Clk,
	Reset_n => Reset_n,

	lvalid 		 => lvalid,
	fvalid		 => fvalid,
	cameradata	 => cameradata,
	cameraclk	 => cameraclk,
	Acq_new		 => Acq_new,

 	AS_Adr 		=> AS_Adr,
 	AS_CS 		=> AS_CS,
 	AS_Write 	=> AS_Write,
 	AS_Read 	=> AS_Read,
 	AS_DataWrite 	=> AS_DataWrite,
 	AS_DataRead     => AS_DataRead,

	AM_Adr 		=> AM_Adr,
	AM_ByteEnable   => AM_ByteEnable,
	AM_Write 	=> AM_Write,
	AM_Read 	=> AM_Read,
	AM_DataWrite    => AM_DataWrite,
	AM_DataRead 	=> AM_DataRead,
	AM_WaitRequest  => AM_WaitRequest);

    process begin
	Clk <= not Clk;
	cameraclk <= Clk;
	wait for PERIOD/2;
	--cameraclk <= '0';
    end process;

    process begin
	cameradata <= not cameradata;
	wait for PERIOD;
    end process;

    process begin
	wait for PERIOD/2;
	
	wait for PERIOD*3;
	reset_n <= '0';
	wait for PERIOD*2;
	reset_n <= '1';

	fvalid <= '1';
	lvalid <= '1';
	wait for PERIOD*3200; --write the first frame
	fvalid <= '0';
	lvalid <= '0';
	wait for PERIOD*5;
	
	AS_Write <= '1';
	As_Adr <= "00";
	As_DataWrite <= x"0000_0400";
	wait for PERIOD;
	AS_Adr <= "01";
	AS_DataWrite <= x"0010_1010";
	wait for PERIOD;
	AS_Adr <= "10";
	AS_DataWrite <= x"0000_0001";
	wait for PERIOD;
	AS_Write <= '0';
	wait;

    end process;

end test;
