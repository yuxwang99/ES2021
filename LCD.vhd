
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


Entity LCD is
    port(
         -- out port for LCD screen
         LCD_ON: out std_logic;
         CSX: out std_logic;
         D_CX: out std_logic;
         WRX: out std_logic;
         RDX: out std_logic; -- useless
         RESX: out std_logic;
         D: out std_logic_vector(15 downto 0);
         
         -- ports for Avalon slave
         clk: in std_logic;
         nReset: in std_logic;
         AS_adr: in std_logic_vector(7 downto 0); --8 bits to represent all the addresses of the read/write registers
         AS_CS: in std_logic;
         AS_write: in std_logic;
         AS_read: in std_logic;
         AS_writedata: in std_logic_vector(31 downto 0);
         AS_readdata: out std_logic_vector(31 downto 0);

         -- ports for Avalon master
         AM_adr: out std_logic_vector(31 downto 0);
         AM_read: out std_logic;
         AM_burstcount: out std_logic_vector(3 downto 0);
         AM_waitreq: in std_logic;
         AM_readdatavalid: in std_logic;
         AM_readdata: in std_logic_vector(31 downto 0)
    
         
    );

end LCD;


architecture comp of LCD_interface is

     --signals for LCD initialization 
     signal initAddr: std_logic_vector(15 downto 0); --00000
     signal initData: std_logic_vector(239 downto 0); --00001-01111
     signal cmdLen: std_logic_vector(3 downto 0); --10000
     signal newCmd: std_logic; --10001
     signal cmdFin: std_logic_vector(3 downto 0); --10010
     signal RESReg: std_logic_vector(3 downto 0); --10011
     signal initDone:  std_logic; --10100
     
     --variable cmdDataCount: integer := 0;
     signal clr_RESReg: std_logic;
     signal clr_newCmd: std_logic;
     
     --states for initialization
     TYPE InitState IS (init_Idle, init_WRaddr, init_WRdata, init_RESET,  init_WR_up1, init_WR_up2, init_wait1, init_wait2, init_wait3, init_wait4, init_wait5);
     signal init_S: InitState;
     
     
     --signals for LCD display
     signal imageDone: std_logic; --10101
     signal oneFIFOread: std_logic_vector(31 downto 0);
     
     --states for LCD display
     TYPE dpState IS (dp_Idle, dp_WRaddr, dp_WRdata1, dp_WRdata2, dp_WR_up1, dp_WR_up2, dp_WR_up3, dp_wait1, dp_wait2, dp_wait3, dp_wait4, dp_wait5, dp_wait6, dp_wait7);
     signal dp_S: dpState;
     
     signal LCD_mode: std_logic; --0: initialization, 1: display
     
     
     
     --signals for Master unit
     signal memAddr: std_logic_vector(31 downto 0); --10110
     signal i_memAddr: std_logic_vector(31 downto 0); 
     signal masterStart: std_logic;
     signal burstFetch: std_logic_vector(4 downto 0);
     signal totalFetch: std_logic_vector(31 downto 0); 

     --variable totalFetch : integer := 0;
     --variable burstFetch : integer := 0;
     signal busdata: std_logic_vector(31 downto 0);
     --states for LCD display
     TYPE MA_State IS (ma_Idle, ma_WRaddr, waitBus, waitData, stData);
     signal ma_S: MA_State;
     
     
     --signals for the camera to write 
     signal newImage: std_logic; --10111
     
     
     --signals to turn on the LCD
     signal lcdON: std_logic; --11000
     signal lcd_status: std_logic := '0'; -- 0: off, 1: on
     
     
     
     
     --FIFO declaration
     COMPONENT scfifo
     GENERIC (
             add_ram_output_register		: STRING;
             almost_empty_value		: NATURAL;
             almost_full_value		: NATURAL;
             intended_device_family		: STRING;
             lpm_numwords		: NATURAL;
             lpm_showahead		: STRING;
             lpm_type		: STRING;
             lpm_width		: NATURAL;
             lpm_widthu		: NATURAL;
             overflow_checking		: STRING;
             underflow_checking		: STRING;
             use_eab		: STRING
	);
	PORT (
			clock	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdreq	: IN STD_LOGIC ;
			wrreq	: IN STD_LOGIC ;
			almost_empty	: OUT STD_LOGIC ;
			almost_full	: OUT STD_LOGIC ;
			empty	: OUT STD_LOGIC ;
			full	: OUT STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			usedw	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END COMPONENT;
    
    -- signals used for FIFO;
    signal almost_empty: std_logic;
    signal almost_full: std_logic;
    signal wrreq: std_logic;
    signal rdreq: std_logic;
    signal q: std_logic_vector(31 downto 0);
    signal data: std_logic_vector(31 downto 0);
    signal empty: std_logic;
    signal full: std_logic;
    signal usedw: std_logic_vector(7 downto 0);


begin
     
    --FIFO instantiation
    scfifo_component : scfifo
	GENERIC MAP (
		add_ram_output_register => "OFF",
		almost_empty_value => 4,
		almost_full_value => 8,
		intended_device_family => "Cyclone V",
		lpm_numwords => 256,
		lpm_showahead => "OFF",
		lpm_type => "scfifo",
		lpm_width => 32,
		lpm_widthu => 8,
		overflow_checking => "ON",
		underflow_checking => "ON",
		use_eab => "ON"
	)
	PORT MAP (
		clock => clk,
		data => data,
		rdreq => rdreq,
		wrreq => wrreq,
		almost_empty => almost_empty,
		almost_full => almost_full,
		empty => empty,
		full => full,
		q => q,
		usedw => usedw
	);

     -- Avalon slave write to registers & clear some registers
    Process (clk, nReset)
    begin
        if nReset = '0' then
            initAddr <= (others => '0');
            initData <= (others => '0');
            cmdFin <= (others => '0');
            cmdLen <= (others => '0');
            RESReg <= (others => '0');
            initDone <= '0';
            newCmd <= '0';
            

            memAddr <= (others => '0');
            newImage <= '0';

        
        elsif rising_edge(clk) then
            if AS_CS = '1' and AS_write = '1' then
                case AS_adr is
                    when "00000" => initAddr <= AS_writedata(15 downto 0); --0000
                    -- put data in different positions in the big InitData register
                    when "00001" => initData(15 downto 0) <= AS_writedata(15 downto 0); 
                    when "00010" => initData(31 downto 16) <= AS_writedata(15 downto 0); 
                    when "00011" => initData(47 downto 32) <= AS_writedata(15 downto 0); 
                    when "00100" => initData(63 downto 48) <= AS_writedata(15 downto 0); 
                    when "00101" => initData(79 downto 64) <= AS_writedata(15 downto 0); 
                    when "00110" => initData(95 downto 80) <= AS_writedata(15 downto 0);
                    when "00111" => initData(111 downto 96) <= AS_writedata(15 downto 0); 
                    when "01000" => initData(127 downto 112) <= AS_writedata(15 downto 0);
                    when "01001" => initData(143 downto 128) <= AS_writedata(15 downto 0);
                    when "01010" => initData(159 downto 144) <= AS_writedata(15 downto 0); 
                    when "01011" => initData(175 downto 160) <= AS_writedata(15 downto 0);
                    when "01100" => initData(191 downto 176) <= AS_writedata(15 downto 0); 
                    when "01101" => initData(207 downto 192) <= AS_writedata(15 downto 0);
                    when "01110" => initData(223 downto 208)<= AS_writedata(15 downto 0); 
                    when "01111" => initData(239 downto 224)<= AS_writedata(15 downto 0);

                    when "10000" => cmdLen <= AS_writedata(3 downto 0);
                    when "10001" => newCmd <= AS_writedata(0);
                    when "10011" => RESReg <= AS_writedata(3 downto 0);
                    when "10100" => initDone <= AS_writedata(0);

                    when "10110" => memAddr <= AS_writedata;
                    when "10111" => newImage <= AS_writedata(0);
                    when "11000" => lcdON <= AS_writedata(0);
                    when others => null;
                end case;
            
            elsif clr_RESReg = '1' then
                RESReg <= (others => '0'); --clear RESReg
            
            elsif clr_newCmd = '1' then
                newCmd <= '0';
            
            end if;
        end if;
    end process;
    
    
    -- Avalon slave read from registers
    process(clk)
    begin
        if rising_edge(clk) then
            AS_readdata <= (others => '0');
            if AS_CS = '1' and AS_read = '1' then
                case AS_adr is
                    when "10010" => AS_readdata <= (31 downto 4 => '0') & cmdFin; --read comFin
                    when "10101" => AS_readdata <= (31 downto 4 => '0') & imageDone; --read imageDone
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
    
        -- a process that turns on the LCD
    Process (clk)
    begin
        if rising_edge(clk) then
            if lcd_status = '0' and lcdON = '1' then
                LCD_ON <= '1';
                lcd_status <= '0';
            end if;
        end if;
    end process;
    
    -- state machines for Initialization
    Process (clk, nReset) is
	variable cmdDataCount: integer := 0;
    begin
        if nReset = '0' then
            Init_S <= init_Idle; -- reset to idle state

        elsif rising_edge(clk) then
            case Init_S is
                when init_Idle => 
                    clr_RESReg <= '0';
                    CSX <= '1';
                    if to_integer(unsigned(RESReg)) /= 0 then --have a reset command
                        Init_S <= init_RESET; --transfer to the RESET state
                
                    elsif to_integer(unsigned(RESReg)) = 0 and newCmd = '1' then --the arrival of a new command
                        clr_newCmd <= '1'; --clear newCmd
                        cmdFin <= (others => '0'); -- the start of a new command
                        Init_S <= init_WRaddr;

                    end if;

                when init_RESET => --at the reset state
                    if to_integer(unsigned(RESReg)) = 1 then --user wants to set the reset signal
                        CSX <= '0'; --LCD screen chip select
                        RESX <= '0';
                    elsif to_integer(unsigned(RESReg)) = 2 then --clear the reset signal
                        CSX <= '0'; --LCD screen chip select
                        RESX <= '1';
                    end if;
                    
                    clr_RESReg <= '1'; --now we want to clear RESReg
                    Init_S <= init_Idle; --back to the idle state, set clr_RESReg(line156) to wait for the next reset signal
  

                when init_WRaddr => -- at the WRaddr state
                    CSX <= '0'; -- chip select
                    D_CX <= '0'; -- we are sending the command
                    WRX <= '0'; -- pull the write signal down
                    D <= initAddr; --send the command address (stored in the register initAddr)
                    clr_newCmd <= '0';
                    Init_S <= init_wait1; -- switch to the next state: wait 2

                when init_wait1 =>
                    Init_S <= init_WR_up1;

                when init_WR_up1 => --at the WR_up1 state
                    WRX <= '1'; --after 2 cycles, the write is done, now we pull up the WRX signal
                    Init_S <= init_wait2;

                when init_wait2 =>
                    cmdDataCount := 0; --clear cmdDataCount because we are about to send data
                    Init_S <= init_WRdata;

                when init_WRdata =>
                    D_CX <= '1';
                    WRX <= '0';
                    D <= initdata(cmdDataCount * 16 + 15 downto cmdDataCount * 16);
                    -- e.g., the first data is in InitData0, which is in the position of (15 downto 0) in the InitData register
                    cmdDataCount := cmdDataCount + 1; -- increment by 1
                    Init_S <= init_wait3;

                when init_wait3 =>
                    Init_S <= init_WR_up2;
            
                when init_WR_up2 => --WR_up2 is almost the same as WR_up1
                    WRX <= '1'; --after 2 cycles, the write is done, now we pull up the WRX signal;

                    if cmdDataCount < to_integer(unsigned(cmdLen)) then
                        Init_S <= init_wait4;
                    else
                        Init_S <= init_wait5;
                    end if;

                when init_wait4 =>
                    Init_S <= init_WRdata;

                when init_wait5 =>
                    --in this state, we write all the data and finish the command
                    cmdFin <= "0001"; --indicate that the command is finished
                    CSX <= '1';
                    init_S <= init_Idle;

                                                          
            end case;
        end if; --end if rising_edge
    end process; --end process
    
    
    
    --a process that switches from LCD initialization to LCD display
    Process (clk, nReset)
    begin
        if nReset = '0' then
            LCD_mode <= '0'; --by default, the LCD stays in the initialization mode
        elsif rising_edge(clk) then
            if initDone = '1' then
                LCD_mode <= '1'; --if the user says the initialization is done,
                                     --then switch to display and run the state machine below  
            end if;
        end if;
    end process;
    
    
    
    --state machine for LCD display
    Process (clk, nReset) IS

     
    begin
        if nReset = '0' then
            dp_S <= dp_Idle; -- reset to idle state
        elsif rising_edge(clk) then
            case dp_S is
                when dp_Idle =>
                    if LCD_mode = '1' then --switch to display mode
                        CSX <= '1'; --finish sending all pixels and return back to Idle: clear CSX
                        
                        if newImage = '1' then --if the camera sends a new image
                            imageDone <= '0'; 
                            dp_S <= dp_WRaddr;
                        end if;
                    end if;
                
                when dp_WRaddr =>
                    CSX <= '0';
                    WRX <= '0';
                    D_CX <= '0';
                    D <= (15 downto 8 => '0') & "00101100"; --0x002C for memory write command

                    dp_S <= dp_wait1;
                
                when dp_wait1 =>
                    dp_S <= dp_WR_up1;
                
                when dp_WR_up1 =>
                    WRX <= '1';
                    dp_S <= dp_wait2;
                
                when dp_wait2 =>
                    if almost_empty = '0' then
                        rdreq <= '1';
                        dp_S <= dp_WRdata1;
                    end if;
                
                when dp_WRdata1 =>
                    rdreq <= '0';
                    oneFIFOread <= q;
                    WRX <= '0';
                    D_CX <= '1'; --send data
                    D <= oneFIFOread(15 downto 0);
                    dp_S <= dp_wait3;
                
                when dp_wait3 =>
                    dp_S <= dp_WR_up2;
                    
                when dp_WR_up2 =>
                    WRX <= '1';
                    dp_S <= dp_wait4;
                    
                when dp_wait4 =>
                    dp_S <= dp_WRdata2;
                    
                when dp_WRdata2 =>
                    WRX <= '1';
                    D_CX <= '1'; --send data
                    D <= oneFIFOread(31 downto 16);
                
                when dp_wait5 =>
                    dp_S <= dp_WR_up3;

                when dp_WR_up3 =>
                    WRX <= '1';
                    if empty = '1' and totalFetch >= 320 * 240 then
                        dp_S <= dp_wait7;
                    else
                        dp_S <= dp_wait6;
                    end if;
                
                when dp_wait6 =>
                    if almost_empty = '0' then
                        dp_S <= dp_WRdata1;
                    end if;
                
                when dp_wait7 =>
                    imageDone <= '1';
                    dp_S <= dp_Idle;
                
            end case;
        end if;
    end process;
    
    
    -- state machine of Master unit
    Process (clk, nReset)
    begin
        if nReset = '0' then
            ma_S <= ma_Idle;
            i_memAddr <= (others => '0');
            burstFetch := 0;
            totalFetch := 0;
            
        elsif rising_edge(clk) then
            case ma_S is
                when ma_Idle =>
                    if masterStart = '1' then
                        totalFetch := 0;
                        i_memAddr <= memAddr;
                        ma_S <= ma_WRaddr;
                    end if;
                    
                when ma_WRaddr =>
                     burstFetch := 0;
                     AM_adr <= i_memAddr;
                     AM_burstcount <= "100";
                     AM_read <= '1';
                     ma_S <= waitBus;
                    
                when waitBus =>
                    if AM_waitreq = '0' then
                        AM_adr <= (others => '0');
                        AM_burstcount <= (others => '0');
                        AM_read <= '0';
                        ma_S <= waitData;
                    end if;
                    
                when waitData =>
                    if AM_readdatavalid = '1' then
                        busdata <= AM_readdata; --bus data: a temporary buffer
                        wrreq <= '1';
                        ma_S <= stData;
                    
                    end if;
                
                when stData =>
                    data <= busdata; --store in the FIFO
                    burstFetch := burstFetch + 1;
                    totalFetch := totalFetch + 2;
                    
                    if burstfetch < 8 and AM_readdatavalid = '1' then --Avalon bus brings more data
                        busdata <= AM_readdata; --store in the temporary buffer
                        ma_S <= stData; --stay in the current state
                        
                    elsif burstfetch < 8 and AM_readdatavalid = '0' then --no more data from the Avalon bus
                        wrreq <= '0'; --stop writing to FIFO 
                        ma_S <= waitData; --go back to waitData
                    
                    elsif burstFetch >= 8 and totalFetch < 240 * 320 and almost_full = '0' then --finish this burstread, not finish all pixels, fifo is not almost full
                        i_memAddr <= std_logic_vector( unsigned(i_memAddr) + 32 ); --each burst read 4 bytes, burstcount = 8
                        ma_S <= ma_WRaddr;
                        
                    elsif burstFetch >= 8 and totalFetch >= 240 * 320 then --storing all pixels in the FIFO
                        ma_S <= ma_Idle;
                    
                    end if;
                
                end case;
                        
            end if;
    end process;
    
    -- a process that orchestartes the camera, the master and the LCD
    Process (clk, nReset)
    begin
        if nReset = '0' then
            masterStart <= '0'; 
        elsif rising_edge(clk) then
            if newImage = '1' then -- newImage set by the camera when sending one image to DDR3:
                masterStart <= '1';
            end if;
        end if;

    end process;
    
    
    

    

end comp;