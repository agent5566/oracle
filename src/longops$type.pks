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
     *          longops.tick;        -- Step with default value 1
     *          --longops.tick(123); -- for certain step size
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
