--------------------- RUNGAME ---------------------

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


DO $$ BEGIN PERFORM rungame(); END $$;

--------------------- GO ----------------------------

CREATE OR REPLACE FUNCTION public.go(
	tr integer,
	td "char",
	symbol char DEFAULT 'X'::bpchar)
    RETURNS TABLE(a tictactoe.a%TYPE, b tictactoe.b%TYPE, c tictactoe.c%TYPE) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$ 
DECLARE
	choosen_field char;
BEGIN
    IF ((td != 'a') AND (td != 'b') AND (td != 'c')) THEN
		RAISE EXCEPTION 'No such COLUMN name. Use a, b or c';
	END IF;
	IF (symbol != 'X') AND (symbol != 'O') THEN
		RAISE EXCEPTION 'Use only X or O to go';
	END IF;
	IF (SELECT num FROM tictactoe WHERE num=tr) IS NULL THEN
		RAISE EXCEPTION 'No such ROW number, there are only 3 rows';
	END IF;
	EXECUTE 'SELECT '||quote_ident(td)||' FROM tictactoe WHERE num = $1' USING tr INTO choosen_field;
	IF choosen_field IS NOT NULL THEN
		RAISE EXCEPTION 'THIS FIELD IS NOT EMPTY !!! CHOOSE ANOTHER..';
	END IF;
	EXECUTE 'UPDATE tictactoe SET '||quote_ident(td)||' = $1 WHERE num = $2' USING symbol, tr;
	RETURN QUERY 
	SELECT tictactoe.a, tictactoe.b, tictactoe.c FROM tictactoe ORDER BY num;
END;$BODY$;



--------------------- GO_RANDOM_FIELD -------------

CREATE OR REPLACE FUNCTION public.go_random_field()
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
DECLARE
  chars char[] := '{a,b,c}';
  random_row int;
  random_col "char" := '';
  random_index int;
  valid_value char := 'N';
  curr_value char;
BEGIN

  WHILE valid_value IS NOT NULL LOOP
	SELECT floor(random() * (3) + 1)::int INTO random_index;
	SELECT floor(random() * (3) + 1)::int INTO random_row;
	random_col := chars[random_index];
	EXECUTE 'SELECT '||quote_ident(random_col)||' FROM tictactoe WHERE num='||random_row||'' INTO valid_value;
  END LOOP;

 PERFORM go(random_row, random_col, 'O');
 RETURN;
 
END;
$BODY$;



--------------------- IS_WIN -----------------------

CREATE OR REPLACE FUNCTION public.iswin(symbol character)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	columns character[3] := '{a, b, c}';
	rows integer[3] := '{1, 2, 3}';
	i character;
	j int;
	ver int;
	hor int;
	dig int := 0;
	invertdig int := 0;
	curr char;
BEGIN
	FOREACH i IN ARRAY columns LOOP 	------------  проверка столбцов
		EXECUTE 'SELECT COUNT(*) FROM tictactoe WHERE '||quote_ident(i)||'= $1' USING symbol INTO ver;
		IF ver=3 THEN
		    RAISE INFO '
			
			COLUMN FILLED WITH % :
			>>>>>GAME IS OVER<<<<<
			
			', symbol;
			RETURN TRUE;
	  	END IF;
		  
		FOREACH j IN ARRAY rows LOOP 	------------  проверка 2х диагоналей
		  EXECUTE 'SELECT '||i||' FROM tictactoe WHERE num='||j||'' INTO curr;
			IF curr LIKE symbol THEN 
			  IF (i='a' AND j=1) OR (i='b' AND j=2) OR (i='c' AND j='3') THEN
			   dig := dig + 1;
			  END IF;
			  IF (i='c' AND j=1) OR (i='b' AND j=2) OR (i='a' AND j='3') THEN
			   invertdig := invertdig + 1;
			  END IF;
			END IF;			
	 	END LOOP;
	END LOOP;
	
	IF (dig=3 OR invertdig=3) THEN
	 	RAISE INFO '
	 
	 		DIAGONAL FILLED WITH %: 
			>>>>>GAME IS OVER<<<<<
	 
		', symbol;
		RETURN TRUE;
	END IF;

	FOREACH j IN ARRAY rows LOOP  ------------  проверка строк
		SELECT COUNT(*) INTO hor FROM tictactoe WHERE num=j AND a=symbol AND b=symbol AND c=symbol;
		IF hor=1 THEN
			RAISE INFO '
			  
			 ROW FILLED WITH %:
			 >>>>>GAME IS OVER<<<<<
			  
			', symbol;
			RETURN TRUE;		  
		END IF;
	END LOOP;
	RETURN FALSE;
END;$BODY$;



--------------------- CHECK_FOR_WIN ----------------------

CREATE FUNCTION public.check_for_win()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
AS $BODY$
DECLARE
	x boolean;
	o boolean;
BEGIN
	x := iswin('X');
	o := iswin('O');
	IF (x OR o) THEN
		RAISE EXCEPTION '
		
		THIS GAME IS OVER.
		You can start the new one with SELECT * FROM rungame();
		
		';
		RETURN OLD;
	END IF;
	RETURN NEW;
END;$BODY$;		
--------------------- trigger CHECK_FOR_WIN -------------------------------	
CREATE TRIGGER check_for_win
BEFORE UPDATE 
ON public.tictactoe
FOR EACH ROW
EXECUTE PROCEDURE public.check_for_win();




--------------------- GO_NEXT ------------------------

CREATE FUNCTION public.go_next()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
AS $BODY$
DECLARE
	symbol char;
	win boolean;
	pve_mode boolean;
BEGIN
		pve_mode := (SELECT pve FROM gamemode);
		IF (NEW.a <> OLD.a OR (OLD.a IS NULL AND NEW.a IS NOT NULL)) THEN
			symbol := NEW.a;
		END IF;
		IF (NEW.b <> OLD.b OR (OLD.b IS NULL AND NEW.b IS NOT NULL)) THEN
			symbol := NEW.b;
		END IF;
		IF (NEW.c <> OLD.c OR (OLD.c IS NULL AND NEW.c IS NOT NULL)) THEN
			symbol := NEW.c;
		END IF;
		win := iswin(symbol);
		IF (symbol like 'X' AND NOT win AND pve_mode) THEN
	  		PERFORM go_random_field();
		END IF;
		RETURN NEW;
END;$BODY$;
--------------------- trigger GO_NEXT -------------------	
CREATE TRIGGER go_next
AFTER UPDATE 
ON public.tictactoe
FOR EACH ROW
EXECUTE PROCEDURE public.go_next();
-------------------------------------------------------------------
