using System.Collections.Generic;

namespace TCA.Battle
{
    public sealed class BattleActionResult
    {
        private BattleActionResult(bool succeeded, bool stateChanged, IReadOnlyList<string> messages)
        {
            Succeeded = succeeded;
            StateChanged = stateChanged;
            Messages = messages;
        }

        public bool Succeeded { get; }
        public bool StateChanged { get; }
        public IReadOnlyList<string> Messages { get; }

        public static BattleActionResult Success(bool stateChanged, params string[] messages)
        {
            return new BattleActionResult(true, stateChanged, messages);
        }

        public static BattleActionResult Failure(params string[] messages)
        {
            return new BattleActionResult(false, false, messages);
        }
    }
}
