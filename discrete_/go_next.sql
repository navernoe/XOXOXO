-- DROP TRIGGER go_next ON tictactoe;
-- DROP FUNCTION go_next();

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
	
CREATE TRIGGER go_next
AFTER UPDATE 
ON public.tictactoe
FOR EACH ROW
EXECUTE PROCEDURE public.go_next();