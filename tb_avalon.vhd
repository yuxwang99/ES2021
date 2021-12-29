library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity tb_avalon is
end tb_avalon;

architecture test of tb_avalon is
    constant PERIOD : time := 100 ns;
 
    signal Clk : std_logic := '0';
    signal Reset_n : std_logic;

	-- Acquisition 
    signal DataAcquisition : std_logic_vector(31 downto 0):= x"0000_0000" ; 
    signal NewData : std_logic := '0' ; 
    signal DataAck : std_logic;

	-- Avalon Slave : 
    signal AS_Adr : std_logic_vector(1 downto 0);
    signal AS_CS : std_logic := '1';
    signal AS_Write : std_logic;
    signal AS_Read : std_logic;
    signal AS_DataWrite : std_logic_vector(31 downto 0) ; 
    signal AS_DataRead : std_logic_vector(31 downto 0) ; 
    signal Start : std_logic;

	-- Avalon Master : 
    signal AM_Adr : std_logic_vector(31 downto 0) ; 
    signal AM_ByteEnable : std_logic_vector(3 downto 0) ; 
    signal AM_Write : std_logic;
    signal AM_Read :std_logic;
    signal AM_DataWrite : std_logic_vector(31 downto 0) ; 
    signal AM_DataRead :  std_logic_vector(31 downto 0) ; 
    signal AM_WaitRequest : std_logic := '0';

begin
    inst_avalon: entity work.AcquModule
    port map(
	Clk => Clk,
	Reset_n => Reset_n,

	DataAcquisition => DataAcquisition,
	NewData => NewData,
	DataAck => DataAck,

	AS_Adr => AS_Adr,
	AS_CS => AS_CS,
	AS_Write => AS_Write,
	AS_Read => AS_Read,
	AS_DataWrite => AS_DataWrite,
	AS_DataRead => AS_DataRead,
	Start => Start,

	AM_Adr => AM_Adr,
	AM_ByteEnable => AM_ByteEnable,
	AM_Write => AM_Write,
	AM_Read => AM_Read,
	AM_DataWrite => AM_DataWrite,
	AM_DataRead => AM_DataRead,
	AM_WaitRequest => AM_WaitRequest);

    process begin
	Clk <= not Clk;
	wait for PERIOD/2;
    end process;

    process begin
	DataAcquisition  <= std_logic_vector(to_unsigned(to_integer(unsigned(DataAcquisition)) + 1,32));
	Newdata <= not Newdata;
	wait for 4*PERIOD;
    end process;

    process begin
	Reset_n <= '1';
	wait for PERIOD*5;
	Reset_n <= '0';
	wait for PERIOD;
	Reset_n <= '1';
	AS_Write <= '1';
	As_Adr <= "00";
	As_DataWrite <= x"0000_0400";
	wait for PERIOD;
	AS_Adr <= "01";
	AS_DataWrite <= x"0010_1010";
	wait for PERIOD;
	AS_Write <= '0';
	wait;
    end process;
	



end test;