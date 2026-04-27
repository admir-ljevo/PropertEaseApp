using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;

namespace PropertEase.Core.StateMachines
{
 
    public static class ReservationStateMachine
    {
        private static readonly Dictionary<ReservationStatus, HashSet<ReservationStatus>> ValidTransitions = new()
        {
            [ReservationStatus.Pending]   = new() { ReservationStatus.Confirmed, ReservationStatus.Cancelled },
            [ReservationStatus.Confirmed] = new() { ReservationStatus.Completed, ReservationStatus.Cancelled },
            [ReservationStatus.Completed] = new(),
            [ReservationStatus.Cancelled] = new(),
        };

        public static void Transition(
            PropertyReservation reservation,
            ReservationStatus target,
            int? actorId = null,
            string? reason = null)
        {
            if (reservation.Status == target) return;

            if (!ValidTransitions[reservation.Status].Contains(target))
                throw new BusinessException(
                    $"Cannot transition reservation from '{reservation.Status}' to '{target}'.");

            var now = DateTime.UtcNow;
            reservation.Status = target;

            if (target == ReservationStatus.Confirmed)
            {
                reservation.ConfirmedById = actorId;
                reservation.ConfirmedAt   = now;
            }
            else if (target == ReservationStatus.Cancelled)
            {
                if (string.IsNullOrWhiteSpace(reason))
                    throw new BusinessException("Cancellation reason is required.");

                reservation.CancelledById      = actorId;
                reservation.CancelledAt        = now;
                reservation.CancellationReason = reason;
            }
        }

        public static void ValidateTransition(ReservationStatus from, ReservationStatus to)
        {
            if (from != to && !ValidTransitions[from].Contains(to))
                throw new BusinessException(
                    $"Cannot transition reservation from '{from}' to '{to}'.");
        }

        public static bool CanTransition(ReservationStatus from, ReservationStatus to)
            => from == to || ValidTransitions[from].Contains(to);
    }
}
