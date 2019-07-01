-- DROP FUNCTION public.go(integer, "char", character);

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
