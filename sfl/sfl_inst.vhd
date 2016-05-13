	component sfl is
		port (
			noe_in : in std_logic := 'X'  -- noe
		);
	end component sfl;

	u0 : component sfl
		port map (
			noe_in => CONNECTED_TO_noe_in  -- noe_in.noe
		);

