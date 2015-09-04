CREATE OR REPLACE TYPE longops$type AS OBJECT
(
    /*
     * It's wrapper for dealing with v$session_longops
     * Example of usage:
     *
     *   DECLARE
     *       longops longops$type;
     *   BEGIN
     *       -- Lets create new task with name and scale size
     *       longops := longops$type(p_process_name => 'long process test', p_full_count => 100);
     *
     *      -- We should tick progress
     *      FOR i IN 1 .. 100
     *       LOOP
     *          longops.tick;        -- шаг в единицу
     *          --longops.tick(123); --если хотим произвольный шаг
     *      END LOOP;
     *
     *  END;
     */
    l_rindex       NUMBER,
    t              NUMBER,
    l_progress     NUMBER,
    l_fullcnt      NUMBER,
    l_process_name VARCHAR(250),
    l_started      NUMBER,
    MEMBER PROCEDURE assert(condition_in       IN BOOLEAN,

                     message_in         IN VARCHAR2,
                     raise_exception_in IN BOOLEAN := TRUE,
                     exception_code     IN NUMBER := -20001),

    CONSTRUCTOR FUNCTION longops$type(p_process_name VARCHAR,
                                      p_full_count   NUMBER)
        RETURN SELF AS RESULT,
    MEMBER PROCEDURE tick,
    MEMBER PROCEDURE tick(p_step NUMBER)
)
/
CREATE OR REPLACE TYPE BODY longops$type IS

    MEMBER PROCEDURE assert(condition_in       IN BOOLEAN,
                     message_in         IN VARCHAR2,
                     raise_exception_in IN BOOLEAN := TRUE,
                     exception_code     IN NUMBER := -20001) IS
        $IF DBMS_DB_VERSION.version > 10 $THEN
        PRAGMA inline;
        $END
    BEGIN
        IF NOT condition_in
           OR condition_in IS NULL
        THEN

            IF raise_exception_in
            THEN
                raise_application_error(exception_code, message_in);
            END IF;

        END IF;
    END assert;

    CONSTRUCTOR FUNCTION longops$type(p_process_name VARCHAR,
                                      p_full_count   NUMBER)
        RETURN SELF AS RESULT AS
    BEGIN
        assert(p_full_count IS NOT NULL AND p_full_count > 0, 'LONGOPS$TYPE: The scale size must be greater than zero');
        assert(p_process_name IS NOT NULL, 'LONGOPS$TYPE: The task name must be not null');

        l_process_name := p_process_name;
        l_fullcnt      := p_full_count;
        l_progress     := 0;

        l_rindex := dbms_application_info.set_session_longops_nohint;
        dbms_application_info.set_session_longops(l_rindex, t, l_process_name, NULL, 1, l_progress, l_fullcnt, '', '');
        RETURN;
    END;

    MEMBER PROCEDURE tick IS
    BEGIN
        tick(1);
    END tick;

    MEMBER PROCEDURE tick(p_step NUMBER) IS
    BEGIN
        assert(p_step IS NOT NULL AND p_step > 0, 'LONGOPS$TYPE: The step size must be greater than zero');
        assert(p_step <= l_fullcnt, 'LONGOPS$TYPE: The step size must be less than the scale size');

        IF l_progress >= l_fullcnt
        THEN
            RETURN;
        END IF;

        l_progress := l_progress + p_step;

        IF l_progress > l_fullcnt
        THEN
            l_progress := l_fullcnt;
        END IF;

        dbms_application_info.set_session_longops(l_rindex, t, l_process_name, NULL, 1, l_progress, l_fullcnt, '', '');
    END tick;
END;
/
