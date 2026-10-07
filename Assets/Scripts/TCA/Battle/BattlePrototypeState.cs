using System.Collections.Generic;
using TCA.Data;

namespace TCA.Battle
{
    public sealed class BattlePrototypeState
    {
        private readonly List<CardDefinition> handCards = new List<CardDefinition>();

        public BattlePrototypeState(IEnumerable<CardDefinition> startingHand)
        {
            if (startingHand != null)
            {
                handCards.AddRange(startingHand);
            }

            PlayerHp = 30;
            EnemyHp = 30;
            EnemyHandCount = 10;
            CurrentEnergy = 8;
            MaxEnergy = 8;
            TurnNumber = 1;
        }

        public int PlayerHp { get; set; }
        public int EnemyHp { get; set; }
        public int EnemyHandCount { get; set; }
        public int CurrentEnergy { get; set; }
        public int MaxEnergy { get; set; }
        public int TurnNumber { get; set; }
        public int NextReactionDiscount { get; set; }
        public int NextDamageBonus { get; set; }
        public bool DrawOnNextReaction { get; set; }
        public bool FirstDamageCardUsedThisTurn { get; set; }
        public bool FirstReactionResolvedThisTurn { get; set; }
        public CardDefinition ReactionCardLeft { get; set; }
        public CardDefinition ReactionCardRight { get; set; }

        public IList<CardDefinition> HandCards => handCards;
    }
}
