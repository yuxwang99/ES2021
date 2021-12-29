library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fifo_interface is
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
end fifo_interface;

architecture arch of fifo_interface is
    type FIFOin640x5 is array(0 to 63) of std_logic_vector(4 downto 0); --639

    type row is array(0 to 32-1) of std_logic_vector(15 downto 0); --320
    type frame is array(0 to 24-1) of row; --240

    --type FIFOout160x32 is array(0 to 31) of std_logic_vector(15 downto 0); --639
    type FIFOState IS (Idle, SaveLine, ProcessData);
    type INState IS (Blue, Green);
    type OUTState IS (Empty,transfer, waitACK);

    signal FIFOin : FIFOin640x5;

    signal newframe   : frame;
    signal savedframe : frame;
    signal SM: FIFOState; 
    signal EvenRowS: InState;  --whether blue or green pixel
    signal outfifoS: OUTState ;

    signal processidx : integer := 0;
    signal readvalid  : integer ; --240*320;

    signal almostfull : std_logic := '0';

    signal rowidx : integer;
    signal colidx : integer;

    signal init : std_logic;
    signal start: std_logic;

begin


    enter : process(clk1, lvalid, fvalid) is
	--variable index : integer := 0;
	variable inidx : integer := 0;
    begin
	if reset_n = '0' then
	    SM <= Idle;
	    EvenRowS <= Blue;
	    processidx <= 0;
	    --framenew <= '0';
	    rowidx <= 0;
	    colidx <= 0;
	    --Acqnew <= '1';
	elsif rising_edge(clk1)then
	    case SM is
		when Idle =>
		    Acq_new <= '1';
		    if outfifoS = empty then
		        savedframe <= newframe;
		    end if;
		    SM <= SaveLine;
	    	    EvenRowS <= Blue;
	    	    processidx <= 0;
	    	    rowidx <= 0;
	    	    colidx <= 0;
		when SaveLine =>
		    Acq_new <= '0';
		    colidx <= processidx mod 32; --320;
		    rowidx <= (processidx/32) mod 24;    --320, --240
		    EvenRowS <= Blue;
		    if fvalid = '1' and lvalid='1' then
			
			FIFOin(inidx) <= wrdata(11 downto 7);
			inidx := inidx + 1;
		    end if;
		    if inidx = 64 then -- 640
			SM <= ProcessData;
			inidx := 0;
		    end if;
		when ProcessData =>
		    if fvalid = '1' and lvalid='1' then
			colidx <= processidx mod 32; --320;
			rowidx <= (processidx/32) mod 24;    --320, --240
			case EvenRowS is
			    when Blue =>
				newframe(rowidx)(colidx)(15 downto 11) <= FIFOin(colidx*2+1);--red pixel;
				newframe(rowidx)(colidx)(4 downto 0) <= wrdata(11 downto 7);
				
				EvenRowS <= Green;
			    when Green =>
				newframe(rowidx)(colidx)(10 downto 5) <= std_logic_vector(to_unsigned(
								to_integer(unsigned(FIFOin(colidx*2)))
								+to_integer(unsigned(wrdata(11 downto 7)))
								,6));
				processidx <= (processidx + 1); 
				EvenRowS <= Blue;
			end case;
		    end if;
		    if processidx = 32*24-1 then --320*240
			if EvenRowS = green then
			--savedframe <= newframe;
			--framenew <= '1';
			processidx <= 0;
			SM <= Idle;
			end if;
		    elsif colidx=31 and EvenRowS = blue  then --319
			SM <= SaveLine;
		    end if;
	    end case;
	end if;
	
    end process enter;

    outpixel: process(clk2) is
	variable outrowidx : integer := 0;
	variable outcolidx : integer := 0;
    begin
	if reset_n = '0' then
	    new_data <= '0';
	    readvalid <= 24*32; --24*32
	    outrowidx := 0;
	    outcolidx := 0;
	    framenew <= '0';
	    outfifoS <= Empty;
	elsif rising_edge(clk2) then

	   start <= rdfifo;
	   init <= rdfifo xor start;
	    case outfifoS is
		when Empty =>
		    if processidx = 32*24-1 and readvalid = 24*32 then
			outfifoS  <= transfer;
			readvalid <= 0;
			framenew <= '1';
		    end if;
		when transfer =>
		    if readvalid >= 24*32 then
			outfifoS <= Empty;
		    elsif rdfifo='1' then
		        --if  init = '1' or readvalid = 0 then
			    framenew <= '0';
			    outcolidx := readvalid/24; --240;
			    outrowidx := readvalid mod 24;    --320

			    rddata(31 downto 16) <= savedframe(outrowidx)(outcolidx);
			    rddata(15 downto 0) <= savedframe(outrowidx+1)(outcolidx);
			    new_data <= '1';
			    readvalid <= readvalid + 2;
			    outfifoS <= waitACK;
		        --end if;
		    end if;
		when waitACK =>
		    new_data <= '0';
		    if ack = '1' then
			outfifoS <= transfer;
		    end if;
	    end case;


	end if;
    end process outpixel;


end arch;
