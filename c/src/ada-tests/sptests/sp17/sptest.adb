--
--  SPTEST / BODY
--
--  DESCRIPTION:
--
--  This package is the implementation of Test 17 of the RTEMS
--  Single Processor Test Suite.
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
--  sptest.adb,v 1.3 1995/07/12 19:42:14 joel Exp
--

with INTERFACES; use INTERFACES;
with RTEMS;
with TEST_SUPPORT;
with TEXT_IO;

package body SPTEST is

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
      TEXT_IO.PUT_LINE( "*** TEST 17 ***" );

      SPTEST.TASK_NAME( 1 ) := RTEMS.BUILD_NAME(  'T', 'A', '1', ' ' );
      SPTEST.TASK_NAME( 2 ) := RTEMS.BUILD_NAME(  'T', 'A', '2', ' ' );

      SPTEST.TASK_2_PREEMPTED := FALSE;

      RTEMS.TASK_CREATE( 
         SPTEST.TASK_NAME( 1 ), 
         2, 
         2048, 
         RTEMS.DEFAULT_MODES,
         RTEMS.DEFAULT_ATTRIBUTES,
         SPTEST.TASK_ID( 1 ),
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_CREATE OF TA1" );

      RTEMS.TASK_CREATE( 
         SPTEST.TASK_NAME( 2 ), 
         1, 
         2048, 
         RTEMS.DEFAULT_MODES,
         RTEMS.DEFAULT_ATTRIBUTES,
         SPTEST.TASK_ID( 2 ),
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_CREATE OF TA2" );

      RTEMS.TASK_START(
         SPTEST.TASK_ID( 1 ),
         SPTEST.TASK_1'ACCESS,
         0,
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_START OF TA1" );

      RTEMS.TASK_START(
         SPTEST.TASK_ID( 2 ),
         SPTEST.TASK_2'ACCESS,
         0,
         STATUS
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_START OF TA2" );

      RTEMS.TASK_DELETE( RTEMS.SELF, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_DELETE OF SELF" );

   end INIT;

--PAGE
-- 
--  PROCESS_ASR
--

   procedure PROCESS_ASR (
      SIGNALS : in     RTEMS.SIGNAL_SET
   ) is
      STATUS : RTEMS.STATUS_CODES;
   begin

      RTEMS.TASK_RESUME( SPTEST.TASK_ID( 2 ), STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "ASR - TASK_RESUME OF TA2" );

   end PROCESS_ASR;

--PAGE
-- 
--  TASK_1
--

   procedure TASK_1 (
      ARGUMENT : in     RTEMS.TASK_ARGUMENT
   ) is
      STATUS : RTEMS.STATUS_CODES;
   begin

      TEXT_IO.PUT_LINE( "TA1 - signal_catch: initializing signal catcher" );
      RTEMS.SIGNAL_CATCH( 
         SPTEST.PROCESS_ASR'ACCESS, 
         RTEMS.NO_ASR + RTEMS.NO_PREEMPT,
         STATUS 
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "SIGNAL_CATCH" );

      TEXT_IO.PUT_LINE( "TA1 - Sending signal to self" );
      RTEMS.SIGNAL_SEND( 
         SPTEST.TASK_ID( 1 ),
         RTEMS.SIGNAL_16,
         STATUS 
      );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "SIGNAL_SEND" );

      if SPTEST.TASK_2_PREEMPTED = TRUE then
         TEXT_IO.PUT_LINE( "TA1 - TA2 correctly preempted me" );
      end if;

      TEXT_IO.PUT_LINE( "TA1 - Got Back!!!" );
     
      TEXT_IO.PUT_LINE( "*** END OF TEST 17 ***" );
      RTEMS.SHUTDOWN_EXECUTIVE( 0 );
   
   end TASK_1;

--PAGE
-- 
--  TASK_2
--

   procedure TASK_2 (
      ARGUMENT : in     RTEMS.TASK_ARGUMENT
   ) is
      STATUS : RTEMS.STATUS_CODES;
   begin

      SPTEST.TASK_2_PREEMPTED := FALSE;

      TEXT_IO.PUT_LINE( "TA2 - Suspending self" );
      RTEMS.TASK_SUSPEND( RTEMS.SELF, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_SUSPEND OF TA2" );

      TEXT_IO.PUT_LINE( "TA2 - signal_return preempted correctly" );

      SPTEST.TASK_2_PREEMPTED := TRUE;

      RTEMS.TASK_SUSPEND( RTEMS.SELF, STATUS );
      TEST_SUPPORT.DIRECTIVE_FAILED( STATUS, "TASK_SUSPEND OF TA2" );

   end TASK_2;

end SPTEST;
