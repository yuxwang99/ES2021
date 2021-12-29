library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity lcdcontroller is 
  port(
	reset_n   : in std_logic;
	clk	  : in std_logic;

	FIFOrdreq : out std_logic;
	FIFOData : in std_logic_vector(31 downto 0);
        LCD_ON: out std_logic;
        CSX: out std_logic;
        D_CX: out std_logic;
        WRX: out std_logic;
        RDX: out std_logic; -- useless
        RESX: out std_logic;
        D: out std_logic_vector(15 downto 0);

 	AS_Adr : in std_logic_vector(1 downto 0);
 	AS_CS : in std_logic;
 	AS_Write : in std_logic;
 	AS_Read : in std_logic;
 	AS_WriteData : in std_logic_vector(31 downto 0) ; 
 	AS_DataRead : out std_logic_vector(31 downto 0) ; 

	wrreq	:    out std_logic;
	data 	:    out std_logic_vector(31 downto 0) ; 

	almost_full : in std_logic;

 	AM_readdatavalid : in std_logic; 
 	AM_ReadData : in std_logic_vector(31 downto 0) ; 
 	AM_waitrequest : in std_logic;

	AM_burstcound : out std_logic_vector(3 downto 0) ; 
 	AM_Write : out std_logic;
 	AM_Read :out std_logic;
 	AM_DataWrite : out std_logic_vector(31 downto 0);
 	AM_Adr : out std_logic_vector(31 downto 0)

    );

end lcdcontroller;

architecture lcdctrlarch of lcdcontroller is 
    component LCD_interface is
	port (
	reset_n   : in std_logic;
	clk	  : in std_logic;

	SlaveData : in std_logic_vector(15 downto 0);
	InputCtrl : in std_logic;
	FIFOempty : in std_logic;
	FIFOData  : in std_logic_vector(31 downto 0);
	RESET	  : in std_logic;
	
	FIFOrdreq : out std_logic;

        LCD_ON: out std_logic;
        CSX: out std_logic;
        D_CX: out std_logic;
        WRX: out std_logic;
        RDX: out std_logic; -- useless
        RESX: out std_logic;
        D: out std_logic_vector(15 downto 0)	
  	);
    end component;

    component RecModule is
    port(
 	Clk : in std_logic;
 	Reset_n : in std_logic;

	-- Avalon Slave : 
 	AS_Adr : in std_logic_vector(1 downto 0);
 	AS_CS : in std_logic;
 	AS_Write : in std_logic;
 	AS_Read : in std_logic;
 	AS_WriteData : in std_logic_vector(31 downto 0) ; 
 	AS_DataRead : out std_logic_vector(31 downto 0) ; 
	SlaveData : out std_logic_vector(15 downto 0);
	InputCtrl : out std_logic;

	wrreq	:    out std_logic;
	data 	:    out std_logic_vector(31 downto 0) ; 
	reset   :    out std_logic;
	-- Avalon Master : 
	almost_full : in std_logic;

 	AM_readdatavalid : in std_logic; 
 	AM_ReadData : in std_logic_vector(31 downto 0) ; 
 	AM_waitrequest : in std_logic;

	AM_burstcound : out std_logic_vector(3 downto 0) ; 
 	AM_Write : out std_logic;
 	AM_Read :out std_logic;
 	AM_DataWrite : out std_logic_vector(31 downto 0);
 	AM_Adr : out std_logic_vector(31 downto 0)
    );
    end component;
    signal SlaveData:std_logic_vector(15 downto 0);
    signal InputCtrl, FIFOempty, RESET: std_logic;
begin
    interface : LCD_interface 
    Port Map(
	reset_n   => reset_n,
	clk	  => clk,

	SlaveData => SlaveData,
	InputCtrl => InputCtrl,
	FIFOempty => FIFOempty,
	FIFOData  => FIFOData,
	RESET	  => RESET,
	
	FIFOrdreq => FIFOrdreq,

        LCD_ON	  => LCD_ON,
        CSX	  => CSX,
        D_CX	  => D_CX,
        WRX	  => WRX,
        RDX	  => RDX,
        RESX	  => RESX,
        D	  => D
    );

    avalon : RecModule
    Port Map(
	clk	  => clk,
	reset_n   => reset_n,

	-- Avalon Slave : 
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
end lcdctrlarch;