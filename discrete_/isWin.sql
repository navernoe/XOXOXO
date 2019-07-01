-- DROP FUNCTION public.iswin(character);

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