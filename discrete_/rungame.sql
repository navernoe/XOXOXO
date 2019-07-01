-- DROP FUNCTION rungame(boolean);

CREATE OR REPLACE FUNCTION public.rungame(pve_mode boolean DEFAULT TRUE)
    RETURNS TABLE(a char, b char, c char) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$
DECLARE
	description text;
BEGIN

	IF pve_mode THEN
		description := 'Player vs Environment is ON';
	ELSE description := 'Player vs Player is ON';
	END IF;
	
	CREATE TABLE IF NOT EXISTS gamemode(pve boolean, description_mode text);
	IF ((SELECT pve FROM gamemode) IS NULL) THEN
		INSERT INTO gamemode VALUES(pve_mode, description);
	ELSE UPDATE gamemode SET pve=pve_mode, description_mode = description;
	END IF;
	
	CREATE TABLE IF NOT EXISTS tictactoe(num integer, a char, b char, c char);
	DELETE FROM tictactoe;
	FOR i IN 1..3 LOOP
		INSERT INTO tictactoe(num) values(i);
	END LOOP;
	RETURN QUERY SELECT tictactoe.a, tictactoe.b, tictactoe.c FROM tictactoe;
END;$BODY$;
