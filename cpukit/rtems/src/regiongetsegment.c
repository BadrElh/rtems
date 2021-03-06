/**
 *  @file
 *
 *  @brief RTEMS Get Region Segment
 *  @ingroup ClassicRegion
 */

/*
 *  COPYRIGHT (c) 1989-2007.
 *  On-Line Applications Research Corporation (OAR).
 *
 *  The license and distribution terms for this file may be
 *  found in the file LICENSE in this distribution or at
 *  http://www.rtems.org/license/LICENSE.
 */

#if HAVE_CONFIG_H
#include "config.h"
#endif

#include <rtems/rtems/regionimpl.h>
#include <rtems/rtems/optionsimpl.h>
#include <rtems/score/apimutex.h>
#include <rtems/score/threadqimpl.h>
#include <rtems/score/statesimpl.h>

rtems_status_code rtems_region_get_segment(
  rtems_id           id,
  uintptr_t          size,
  rtems_option       option_set,
  rtems_interval     timeout,
  void              **segment
)
{
  Thread_Control     *executing;
  Objects_Locations   location;
  rtems_status_code   return_status;
  Region_Control     *the_region;
  void               *the_segment;

  if ( !segment )
    return RTEMS_INVALID_ADDRESS;

  *segment = NULL;

  if ( size == 0 )
    return RTEMS_INVALID_SIZE;

  _RTEMS_Lock_allocator();

    executing  = _Thread_Get_executing();
    the_region = _Region_Get( id, &location );
    switch ( location ) {

      case OBJECTS_LOCAL:
        if ( size > the_region->maximum_segment_size )
          return_status = RTEMS_INVALID_SIZE;

        else {
          the_segment = _Region_Allocate_segment( the_region, size );

          if ( the_segment ) {
            the_region->number_of_used_blocks += 1;
            *segment = the_segment;
            return_status = RTEMS_SUCCESSFUL;
          } else if ( _Options_Is_no_wait( option_set ) ) {
            return_status = RTEMS_UNSATISFIED;
          } else {
            /*
             *  Switch from using the memory allocation mutex to using a
             *  dispatching disabled critical section.  We have to do this
             *  because this thread is going to block.
             */
            /* FIXME: Lock order reversal */
            _Thread_Disable_dispatch();
            _RTEMS_Unlock_allocator();

            executing->Wait.id              = id;
            executing->Wait.count           = size;
            executing->Wait.return_argument = segment;

            _Thread_queue_Enqueue(
              &the_region->Wait_queue,
              executing,
              STATES_WAITING_FOR_SEGMENT,
              timeout,
              RTEMS_TIMEOUT
            );

            _Objects_Put( &the_region->Object );

            return (rtems_status_code) executing->Wait.return_code;
          }
        }
        break;

#if defined(RTEMS_MULTIPROCESSING)
      case OBJECTS_REMOTE:        /* this error cannot be returned */
#endif

      case OBJECTS_ERROR:
      default:
        return_status = RTEMS_INVALID_ID;
        break;
    }

  _RTEMS_Unlock_allocator();

  return return_status;
}
