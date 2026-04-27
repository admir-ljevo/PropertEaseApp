using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;

namespace PropertEase.Core.StateMachines
{
  
    public static class PaymentStateMachine
    {
        private static readonly Dictionary<PaymentStatus, HashSet<PaymentStatus>> ValidTransitions = new()
        {
            [PaymentStatus.Pending]   = new() { PaymentStatus.Completed, PaymentStatus.Failed },
            [PaymentStatus.Completed] = new() { PaymentStatus.Refunded },
            [PaymentStatus.Failed]    = new(),
            [PaymentStatus.Refunded]  = new(),
        };

        public static void Transition(Payment payment, PaymentStatus target)
        {
            if (payment.Status == target) return;

            if (!ValidTransitions[payment.Status].Contains(target))
                throw new BusinessException(
                    $"Cannot transition payment from '{payment.Status}' to '{target}'.");

            payment.Status = target;
        }

        public static bool CanTransition(PaymentStatus from, PaymentStatus to)
            => from == to || ValidTransitions[from].Contains(to);
    }
}
