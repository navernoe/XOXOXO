-- DROP FUNCTION public.go_random_field();

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
 
END;$BODY$;
