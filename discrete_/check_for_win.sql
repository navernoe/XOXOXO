-- DROP TRIGGER check_for_win ON tictactoe;
-- DROP FUNCTION check_for_win();

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
	
CREATE TRIGGER check_for_win
BEFORE UPDATE 
ON public.tictactoe
FOR EACH ROW
EXECUTE PROCEDURE public.check_for_win();