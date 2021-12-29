library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity LCD_interface is
  port(
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
end LCD_interface;

architecture interface of LCD_interface is
    type LCDState is (INIT, CONFIGURE, DISPLAY);
    type WRState is (START, STARTWAIT, CONTINUE, CONTINUEWAIT);
    type pixelx2 is array(0 to 1) of std_logic_vector(15 downto 0); 

    signal LCDS : LCDState;
    signal TransDATA : WRState;
    signal pixels  : pixelx2;
    signal outidx  : integer := 0;
    signal ConfigD : std_logic_vector(15 downto 0);
    signal diffD   : std_logic_vector(15 downto 0);

begin
    LCD_ON <= '1';
    pixels(0) <= FIFOData(31 downto 16);
    pixels(1) <= FIFOData(15 downto 0);

    master : process(clk) is
    begin
	if reset_n = '0' then
	    LCDS <= INIT;
	    --ConfigD <= x"0000";
	    TransData <= START;
	    RESX <= '0';
	    CSX <= '1';

	elsif rising_edge(clk) then 
    	    ConfigD <= SlaveData;
    	    diffD   <= ConfigD xor SlaveData;
            if RESET = '1' then
                RESX <= '0';
            else
                RESX <= '1';
            end if;
	    case LCDS is
		when INIT =>

		    
		    if diffD = x"0000" then
			LCDS <= INIT;
		    else
			LCDS <= CONFIGURE;
		    end if;
		    CSX <= '1';
		when CONFIGURE =>
		    CSX <= '0';
		    case TransDATA is
			when START =>
			    WRX <= '0';
			    D_CX <= InputCtrl;
		    	    D <= SlaveData;
			    TransData <= STARTWAIT;
			when STARTWAIT => 
			    WRX <= '0';
			    TransData <= CONTINUE;
			when CONTINUE =>
			    WRX <= '1';
			    TransData <= CONTINUEWAIT;
			when CONTINUEWAIT =>
			    WRX <= '1';
		    
	    	    	    if InputCtrl = '1' and  SlaveData = x"002C" then --input address
				LCDS <= DISPLAY;
				outidx <= 1;
			    else
			        TransData <= START;	
			        LCDS <= INIT;	
		    	    end if;
		    end case;
		when DISPLAY =>
		    CSX <= '0';		
		    case TransDATA is
			when START =>
			    WRX <= '1';
			    D_CX <= '1';

			    if FIFOempty = '0' then
				if outidx = 1 then
			            FIFOrdreq <= '1'; -- get data from fifo
				end if;
			        outidx <= (outidx + 1) mod 2;
			        TransData <= STARTWAIT;
			    else
				TransData <= START;
				   
			    end if;


			when STARTWAIT => 
			    FIFOrdreq <= '0';
			    WRX <= '0';
		    	    D <= pixels(outidx);
			    TransData <= CONTINUE;
			when CONTINUE =>
			    WRX <= '0';
			    TransData <= CONTINUEWAIT;
			when CONTINUEWAIT =>
			    WRX <= '1';
			    TransData <= START;					    

		    end case;	
	    end case;
	end if;
    end process master;
    
end interface;
