using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;

namespace PropertEase.Core.StateMachines
{
    /// <summary>
    /// Enforces valid state transitions for <see cref="PropertyReservation"/>.
    /// <para>
    /// Valid transitions:
    ///   Pending   → Confirmed | Cancelled
    ///   Confirmed → Completed | Cancelled
    ///   Completed → (terminal)
    ///   Cancelled → (terminal)
    /// </para>
    /// Also writes the audit trail (who acted, when, cancellation reason).
    /// </summary>
    public static class ReservationStateMachine
    {
        private static readonly Dictionary<ReservationStatus, HashSet<ReservationStatus>> ValidTransitions = new()
        {
            [ReservationStatus.Pending]   = new() { ReservationStatus.Confirmed, ReservationStatus.Cancelled },
            [ReservationStatus.Confirmed] = new() { ReservationStatus.Completed, ReservationStatus.Cancelled },
            [ReservationStatus.Completed] = new(),
            [ReservationStatus.Cancelled] = new(),
        };

        /// <summary>
        /// Transitions <paramref name="reservation"/> to <paramref name="target"/>, writing the audit trail.
        /// No-op when already in target state.
        /// Throws <see cref="InvalidOperationException"/> for any other invalid transition.
        /// </summary>
        /// <param name="actorId">UserId of the person triggering the transition (null = system).</param>
        /// <param name="reason">Cancellation reason — required when <paramref name="target"/> is Cancelled.</param>
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

        /// <summary>
        /// Validates that the transition from <paramref name="from"/> to <paramref name="to"/> is allowed
        /// without modifying any entity. Throws <see cref="InvalidOperationException"/> if invalid.
        /// </summary>
        public static void ValidateTransition(ReservationStatus from, ReservationStatus to)
        {
            if (from != to && !ValidTransitions[from].Contains(to))
                throw new BusinessException(
                    $"Cannot transition reservation from '{from}' to '{to}'.");
        }

        /// <summary>Returns <c>true</c> if the transition from <paramref name="from"/> to <paramref name="to"/> is allowed.</summary>
        public static bool CanTransition(ReservationStatus from, ReservationStatus to)
            => from == to || ValidTransitions[from].Contains(to);
    }
}
