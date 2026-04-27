using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;

namespace PropertEase.Core.StateMachines
{
    /// <summary>
    /// Enforces valid state transitions for <see cref="Payment"/>.
    /// <para>
    /// Valid transitions:
    ///   Pending   → Completed | Failed
    ///   Completed → Refunded
    ///   Failed    → (terminal)
    ///   Refunded  → (terminal)
    /// </para>
    /// </summary>
    public static class PaymentStateMachine
    {
        private static readonly Dictionary<PaymentStatus, HashSet<PaymentStatus>> ValidTransitions = new()
        {
            [PaymentStatus.Pending]   = new() { PaymentStatus.Completed, PaymentStatus.Failed },
            [PaymentStatus.Completed] = new() { PaymentStatus.Refunded },
            [PaymentStatus.Failed]    = new(),
            [PaymentStatus.Refunded]  = new(),
        };

        /// <summary>
        /// Transitions <paramref name="payment"/> to <paramref name="target"/>.
        /// No-op when already in target state.
        /// Throws <see cref="InvalidOperationException"/> for any other invalid transition.
        /// </summary>
        public static void Transition(Payment payment, PaymentStatus target)
        {
            if (payment.Status == target) return;

            if (!ValidTransitions[payment.Status].Contains(target))
                throw new BusinessException(
                    $"Cannot transition payment from '{payment.Status}' to '{target}'.");

            payment.Status = target;
        }

        /// <summary>Returns <c>true</c> if the transition from <paramref name="from"/> to <paramref name="to"/> is allowed.</summary>
        public static bool CanTransition(PaymentStatus from, PaymentStatus to)
            => from == to || ValidTransitions[from].Contains(to);
    }
}
