library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity AcquModule is 
    Port( 
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
end AcquModule;

architecture comp of AcquModule is 
    TYPE AcqState IS (Idle, WaitData, WriteData, AcqData); 

    Signal AcqAddress: STD_LOGIC_VECTOR(31 downto 0); 
    Signal AcqBurstCount: STD_LOGIC_VECTOR(31 downto 0); 
    signal AS_start : STD_LOGIC;

    Signal CntAddress: STD_LOGIC_VECTOR(31 downto 0); 
    Signal CntBurstCount: integer := 0; 
    Signal SM: AcqState; 

begin
    Start <= AS_start;
	-- Interface Slave
    pAvalon_Slave: Process(Clk, Reset_n) 
    Begin 
    if Reset_n = '0' then 
        AcqAddress <= (others => '0'); 
        AcqBurstCount <= (others => '0'); 
    elsif rising_edge(Clk) then 
        if AS_CS = '1' then 
           if AS_Write = '1' then 
 	     case AS_Adr is 
 	    	when "00" => AcqAddress <= AS_DataWrite; 
 	    	when "01" => AcqBurstCount <= AS_DataWrite;
		when "10" => AS_start <= AS_DataWrite(0); 
 	    	when others => null; 
 	     end case; 
      	   elsif AS_Read = '1' then 
 	      case AS_Adr is 
	  	when "00" => AS_DataRead <= AcqAddress; 
 	  	when "01" => AS_DataRead <= AcqBurstCount; 
		when "10" => AS_DataRead(0) <= AS_start; 
 	  	when others => null; 
 	      end case; 
            end if; 
         end if; 
    end if; 
    End Process pAvalon_Slave;

	-- Acquisition
    pAcquisition: process(Clk, Reset_n)
    begin
	if Reset_n = '0' then
	    DataAck <= '0'; 
	    SM <= Idle; 
	    AM_Write <= '0';
	    AM_Read <= '0'; 
	    AM_ByteEnable <= "0000"; 
	    CntAddress <= (others => '0'); 
	    CntBurstCount <= 0;
	elsif rising_edge(Clk) then
	    AM_Read <= '0';
	    case SM is
		when Idle =>
		    if AcqBurstCount /= x"00000000" then
			SM <= WaitData;
			CntAddress <= AcqAddress;
			CntBurstCount  <= to_integer(unsigned(AcqBurstCount));
		    end if;
		when waitData =>
		    if NewData = '1' then
			SM <= WriteData; 
			AM_Adr <= CntAddress; 
			AM_Write <= '1'; 
			AM_DataWrite <= DataAcquisition;
			AM_ByteEnable <= "0000";
			
		    end if;
		when WriteData =>
		    if AM_WaitRequest = '0' then 
			SM <= AcqData; 
			AM_Write <= '0';
			AM_ByteEnable <= "0000";
			DataAck <= '1';
		    end if;

		when AcqData =>
		    if NewData = '0' then
			SM <= WaitData;
			DataAck <= '0';
			    if CntBurstCount /= 1 then
				CntAddress <= std_logic_vector(to_unsigned(to_integer(unsigned(CntAddress)) + 1,32));
				CntBurstCount <= CntBurstCount - 1; 
			    else
				CntAddress <= AcqAddress; 
				CntBurstCount <= CntBurstCount; 
			    end if;
		    end if;
	    end case;
			
	end if;
    end process pAcquisition;

end comp;



