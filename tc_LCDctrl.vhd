library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity tb_lcdctrl is
end tb_lcdctrl;

architecture test_lcdctrl of tb_lcdctrl is
    constant PERIOD : time := 20 ns;

    	signal reset_n   :  std_logic;
	signal clk	  :  std_logic;

	signal FIFOData : std_logic_vector(31 downto 0);
	signal FIFOrdreq :  std_logic;
        signal LCD_ON    :  std_logic;
        signal CSX	:  std_logic;
        signal D_CX 	:  std_logic;
        signal WRX	:  std_logic;
        signal RDX	:  std_logic; -- useless
        signal RESX	:  std_logic;
        signal D	:  std_logic_vector(15 downto 0);

 	signal AS_Adr :  std_logic_vector(1 downto 0);
 	signal AS_CS :  std_logic;
 	signal AS_Write :  std_logic;
 	signal AS_Read :  std_logic;
 	signal AS_WriteData :  std_logic_vector(31 downto 0) ; 
 	signal AS_DataRead :  std_logic_vector(31 downto 0) ; 

	signal wrreq	:    std_logic;
	signal data 	:    std_logic_vector(31 downto 0) ; 

	signal almost_full : std_logic;

 	signal AM_readdatavalid :  std_logic; 
 	signal AM_ReadData : std_logic_vector(31 downto 0) ; 
 	signal AM_waitrequest : std_logic;

	signal AM_burstcound : std_logic_vector(3 downto 0) ; 
 	signal AM_Write :  std_logic;
 	signal AM_Read : std_logic;
 	signal AM_DataWrite : std_logic_vector(31 downto 0);
 	signal AM_Adr : std_logic_vector(31 downto 0)



begin

end test_lcdctrl;