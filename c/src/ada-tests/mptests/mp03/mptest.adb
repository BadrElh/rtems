--
--  MPTEST / BODY
--
--  DESCRIPTION:
--
--  This package is the implementation for Test 3 of the RTEMS
--  Multiprocessor Test Suite.
--
--  DEPENDENCIES: 
--
--  
--
--  COPYRIGHT (c) 1989, 1990, 1991, 1992, 1993, 1994.
--  On-Line Applications Research Corporation (OAR).
--  All rights assigned to U.S. Government, 1994.
--
--  This material may be reproduced by or for the U.S. Government pursuant
--  to the copyright license under the clause at DFARS 252.227-7013.  This
--  notice must appear in all copies of this file and its derivatives.
--
--  mptest.adb,v 1.3 1995/07/12 19:38:49 joel Exp
--

with INTERFACES; use INTERFACES;
with RTEMS;
with TEST_SUPPORT;
with TEXT_IO;
with UNSIGNED32_IO;

package body MPTEST is

   package body PER_NODE_CONFIGURATION is separate;

--PAGE
--
--  INIT
--

   procedure INIT (
      ARGUMENT : in     RTEMS.TASK_ARGUMENT
   ) is
      STATUS : RTEMS.STATUS_CODES;
   begin

      TEXT_IO.NEW_LINE( 2 );
      TEXT_IO.PUT( "*** TEST 3 -- NODE " );
      UNSIGNED32_IO.PUT(
         MPTEST.MULTIPROCESSING_CONFIGURATION.NODE,
         WIDTH => 1
      );
      TEXT_IO.PUT_LINE( " ***" );
     
      MPTEST.TASK_NAME( 1 ) := RTEMS.BUILD_NAME(  '1', '1', '1', ' ' );
      MPTEST.TASK_NAME( 2 ) := RTEMS.BUILD_NAME(  '2', '2', '2', ' ' );

      TEXT_IO.PUT_LINE( "Creating Test_task (Global)" );
      RTEMS.TASK_CREATE( 
         MPTEST.TASK_NAME( MPTEST.MULTIPROCESSING_CONFIGURATION.NODE ), 
         1, 
         2048, 
         RTEMS.NO_PREEMPT,
         RTEMS.GLOBAL,
         MPTEST.TASK_ID( 1 ),
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_CREATE" );

      TEXT_IO.PUT_LINE( "Starting Test_task (Global)" );
      RTEMS.TASK_START(
         MPTEST.TASK_ID( 1 ),
         MPTEST.TEST_TASK'ACCESS,
         0,
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_START" );

      MPTEST.TIMER_NAME( 1 ) := RTEMS.BUILD_NAME(  'T', 'M', '1', ' ' );

      RTEMS.TIMER_CREATE( 
         MPTEST.TIMER_NAME( 1 ), 
         MPTEST.TIMER_ID( 1 ),
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TIMER_CREATE" );

      TEXT_IO.PUT_LINE( "Deleting initialization task" );
      RTEMS.TASK_DELETE( RTEMS.SELF, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_DELETE OF SELF" );

   end INIT;

--PAGE
--
--  DELAYED_SEND_EVENT
--

   procedure DELAYED_SEND_EVENT (
      IGNORED_ID      : in     RTEMS.ID;
      IGNORED_ADDRESS : in     RTEMS.ADDRESS
   ) is
      STATUS  : RTEMS.STATUS_CODES;
   begin

      RTEMS.EVENT_SEND( MPTEST.TASK_ID( 1 ), RTEMS.EVENT_16, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "EVENT_SEND" );

   end DELAYED_SEND_EVENT;

--PAGE
--
--  TEST_TASK
--

   procedure TEST_TASK (
      ARGUMENT : in     RTEMS.TASK_ARGUMENT
   ) is
      TID         : RTEMS.ID;
      STATUS      : RTEMS.STATUS_CODES;
   begin

      RTEMS.TASK_IDENT( RTEMS.SELF, RTEMS.SEARCH_ALL_NODES, TID, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_IDENT OF SELF" );
   
      TEXT_IO.PUT_LINE( "Getting TID of remote task" );
      if MPTEST.MULTIPROCESSING_CONFIGURATION.NODE = 1 then
         MPTEST.REMOTE_NODE := 2;
      else
         MPTEST.REMOTE_NODE := 1;
      end if;

      TEXT_IO.PUT( "Remote task's name is : " );
      TEST_SUPPORT.PUT_NAME( MPTEST.TASK_NAME( MPTEST.REMOTE_NODE ), TRUE );

      loop

         RTEMS.TASK_IDENT( 
            MPTEST.TASK_NAME( MPTEST.REMOTE_NODE ),
            RTEMS.SEARCH_ALL_NODES,
            MPTEST.REMOTE_TID,
            STATUS
         );

         exit when RTEMS.IS_STATUS_SUCCESSFUL( STATUS );

      end loop;

      RTEMS.TIMER_FIRE_AFTER( 
         MPTEST.TIMER_ID( 1 ), 
         10 * TEST_SUPPORT.TICKS_PER_SECOND, 
         MPTEST.DELAYED_SEND_EVENT'ACCESS,
         RTEMS.NULL_ADDRESS,
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TIMER_FIRE_AFTER" );

      MPTEST.TEST_TASK_SUPPORT( 1 );

      RTEMS.TIMER_FIRE_AFTER( 
         MPTEST.TIMER_ID( 1 ), 
         11 * TEST_SUPPORT.TICKS_PER_SECOND, 
         MPTEST.DELAYED_SEND_EVENT'ACCESS,
         RTEMS.NULL_ADDRESS,
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TIMER_FIRE_AFTER" );

      if MPTEST.MULTIPROCESSING_CONFIGURATION.NODE = 2 then
         
         RTEMS.TASK_WAKE_AFTER( 
            2 * TEST_SUPPORT.TICKS_PER_SECOND,
            STATUS
         );
        TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_WAKE_AFTER" );

      end if;

      MPTEST.TEST_TASK_SUPPORT( 2 );

      TEXT_IO.PUT_LINE( "*** END OF TEST 3 ***" );

      RTEMS.SHUTDOWN_EXECUTIVE( 0 );

   end TEST_TASK;

--PAGE
-- 
--  TEST_TASK_SUPPORT
--


   procedure TEST_TASK_SUPPORT (
      NODE : in    RTEMS.UNSIGNED32
   ) is
      EVENTS : RTEMS.EVENT_SET;
      STATUS : RTEMS.STATUS_CODES;
   begin

      if MPTEST.MULTIPROCESSING_CONFIGURATION.NODE = NODE then

         loop

            RTEMS.EVENT_RECEIVE( 
               RTEMS.EVENT_16,
               RTEMS.NO_WAIT,
               RTEMS.NO_TIMEOUT,
               EVENTS,
               STATUS
            );

            exit when RTEMS.ARE_STATUSES_EQUAL( RTEMS.SUCCESSFUL, STATUS );

            TEST_SUPPORT.FATAL_DIRECTIVE_STATUS( 
               STATUS,
               RTEMS.UNSATISFIED,
               "EVENT_RECEIVE"
            );

            RTEMS.TASK_WAKE_AFTER( 
               2 * TEST_SUPPORT.TICKS_PER_SECOND, 
               STATUS
            );
            TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_WAKE_AFTER" );

            TEST_SUPPORT.PUT_NAME( MPTEST.TASK_NAME( NODE ), FALSE );
            TEXT_IO.PUT_LINE( " - Suspending remote task" );
            RTEMS.TASK_SUSPEND( MPTEST.REMOTE_TID, STATUS );
            TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_SUSPEND" );

            RTEMS.TASK_WAKE_AFTER( 
               2 * TEST_SUPPORT.TICKS_PER_SECOND, 
               STATUS
            );
            TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_WAKE_AFTER" );

            TEST_SUPPORT.PUT_NAME( MPTEST.TASK_NAME( NODE ), FALSE );
            TEXT_IO.PUT_LINE( " - Resuming remote task" );

            RTEMS.TASK_RESUME( MPTEST.REMOTE_TID, STATUS );
            TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_RESUME" );

         end loop;

      else

         loop

            RTEMS.EVENT_RECEIVE( 
               RTEMS.EVENT_16,
               RTEMS.NO_WAIT,
               RTEMS.NO_TIMEOUT,
               EVENTS,
               STATUS
            );

            exit when RTEMS.ARE_STATUSES_EQUAL( RTEMS.SUCCESSFUL, STATUS );

            TEST_SUPPORT.FATAL_DIRECTIVE_STATUS( 
               STATUS,
               RTEMS.UNSATISFIED,
               "EVENT_RECEIVE"
            );

            TEST_SUPPORT.PUT_NAME( MPTEST.TASK_NAME( REMOTE_NODE ), FALSE );
            TEXT_IO.PUT_LINE( " - have I been suspended???" ); 
            RTEMS.TASK_WAKE_AFTER( 
               TEST_SUPPORT.TICKS_PER_SECOND / 2,
               STATUS
            );
            TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_WAKE_AFTER" );

         end loop;

      end if;

   end TEST_TASK_SUPPORT;

end MPTEST;
