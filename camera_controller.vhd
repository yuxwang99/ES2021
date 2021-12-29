library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity controller is 
  port(
	reset_n		 : in std_logic;
	clk 		 : in std_logic;

	lvalid	 	 : in std_logic;
	fvalid	 	 : in std_logic;
	cameradata	 : in std_logic_vector(11 downto 0);
	cameraclk	 : in std_logic;
	Acq_new		 : out std_logic;
	framenew	 : out std_logic;

	-- avalon
	AS_Adr : in std_logic_vector(1 downto 0);
 	AS_CS 		 : in std_logic;
 	AS_Write 	 : in std_logic;
 	AS_Read 	 : in std_logic;
 	AS_DataWrite     : in std_logic_vector(31 downto 0) ; 
 	AS_DataRead      : out std_logic_vector(31 downto 0) ; 

 	AM_Adr : out std_logic_vector(31 downto 0) ; 
 	AM_ByteEnable : out std_logic_vector(3 downto 0) ; 
 	AM_Write : out std_logic;
 	AM_Read :out std_logic;
 	AM_DataWrite : out std_logic_vector(31 downto 0) ; 
 	AM_DataRead : in std_logic_vector(31 downto 0) ; 
 	AM_WaitRequest : in std_logic
	);
end controller;

architecture controller_arch of controller is 
    component fifo_interface
	port(
	reset_n		 : in std_logic;
	clk1 		 : in std_logic;
	lvalid		 : in std_logic;
	fvalid		 : in std_logic;
	wrdata		 : in std_logic_vector(11 downto 0);

	clk2		 : in std_logic;
	rdfifo		 : in std_logic;

	rddata		 : out std_logic_vector(31 downto 0);
	ack		 : in std_logic;
	new_data	 : out std_logic;
	Acq_new		 : out std_logic;
	framenew	 : out std_logic
	     );
    end component;

    component AcquModule
	port(
 	Clk : in std_logic;
 	Reset_n : in std_logic;

	-- Acquisition 
	DataAcquisition : in std_logic_vector(31 downto 0) ; 
	NewData : in std_logic ; 
 	DataAck : out std_logic;

	-- Avalon Slave : 
 	AS_Adr : in std_logic_vector(1 downto 0);
 	AS_CS : in std_logic;
 	AS_Write : in std_logic;
 	AS_Read : in std_logic;
 	AS_DataWrite : in std_logic_vector(31 downto 0) ; 
 	AS_DataRead : out std_logic_vector(31 downto 0) ; 
	Start	    : out std_logic;

	-- Avalon Master : 		
 	AM_Adr : out std_logic_vector(31 downto 0) ; 
 	AM_ByteEnable : out std_logic_vector(3 downto 0) ; 
 	AM_Write : out std_logic;
 	AM_Read :out std_logic;
 	AM_DataWrite : out std_logic_vector(31 downto 0) ; 
 	AM_DataRead : in std_logic_vector(31 downto 0) ; 
 	AM_WaitRequest : in std_logic
	);
     end component;
     signal ACK, NEWDATA, START : std_logic;
     signal RDATA : std_logic_vector(31 downto 0);
begin
    fifo:fifo_interface
    Port Map(
	reset_n	=> reset_n,
	clk1 	=> clk,
	lvalid	=> lvalid,
	fvalid	=> fvalid,
	wrdata	=> cameradata,

	clk2	=> cameraclk,
	rdfifo	=> START,

	rddata	=> RDATA,
	ack	=> ACK,
	new_data=> NEWDATA,
	Acq_new	=> Acq_new,
	framenew=> framenew
    );

    avalon: AcquModule
    Port Map(
	Clk 		=> clk,
 	Reset_n 	=> reset_n,

	DataAcquisition => RDATA,
	NewData 	=> NEWDATA,
 	DataAck 	=> ACK,

 	AS_Adr 		=> AS_Adr,
 	AS_CS 		=> AS_CS,
 	AS_Write 	=> AS_Write,
 	AS_Read 	=> AS_Read,
 	AS_DataWrite 	=> AS_DataWrite,
 	AS_DataRead     => AS_DataRead,
	Start	    	=> START,

	-- Avalon Master : 		
 	AM_Adr 		=> AM_Adr ,
 	AM_ByteEnable   => AM_ByteEnable ,
 	AM_Write 	=> AM_Write,
 	AM_Read 	=> AM_Read ,
 	AM_DataWrite 	=> AM_DataWrite ,
 	AM_DataRead	=> AM_DataRead,
 	AM_WaitRequest  => AM_WaitRequest
    );
end controller_arch;

