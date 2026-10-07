using System;
using System.Collections.Generic;
using TCA.Data;
using TCA.UI;
using UnityEngine;

namespace TCA.Battle
{
    public sealed class BattlePrototypeRules
    {
        private readonly IReadOnlyDictionary<string, CardDefinition> cardCatalog;
        private readonly Func<CardDefinition> drawCard;

        public BattlePrototypeRules(IReadOnlyDictionary<string, CardDefinition> cardCatalog, Func<CardDefinition> drawCard)
        {
            this.cardCatalog = cardCatalog ?? throw new ArgumentNullException(nameof(cardCatalog));
            this.drawCard = drawCard ?? throw new ArgumentNullException(nameof(drawCard));
        }

        public bool CanCardBeDroppedInZone(CardDefinition card, DropZoneType zoneType)
        {
            if (card == null)
            {
                return false;
            }

            switch (zoneType)
            {
                case DropZoneType.EnemyTarget:
                    return card.targeting == CardTargeting.Enemy || card.targeting == CardTargeting.Any;
                case DropZoneType.PlayerTarget:
                    return card.targeting == CardTargeting.Self || card.targeting == CardTargeting.Any;
                case DropZoneType.ReactionLeft:
                case DropZoneType.ReactionRight:
                    return card.isElementCard;
                default:
                    return false;
            }
        }

        public int GetReactionCost(BattlePrototypeState state)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            return Mathf.Max(0, TcaStarterCatalog.ReactionEnergyCost - state.NextReactionDiscount);
        }

        public ReactionPreview GetReactionPreview(BattlePrototypeState state)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            return TcaStarterCatalog.GetReactionPreview(state.ReactionCardLeft, state.ReactionCardRight);
        }

        public BattleActionResult TryAssignReactionCard(BattlePrototypeState state, CardDefinition card, DropZoneType zoneType)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            if (card == null)
            {
                return BattleActionResult.Failure("No card selected.");
            }

            if (!CanCardBeDroppedInZone(card, zoneType))
            {
                return BattleActionResult.Failure($"This card cannot be dropped into {ZoneLabel(zoneType)}.");
            }

            if (zoneType == DropZoneType.ReactionLeft && state.ReactionCardLeft != null)
            {
                return BattleActionResult.Failure("Reaction slot A is already occupied.");
            }

            if (zoneType == DropZoneType.ReactionRight && state.ReactionCardRight != null)
            {
                return BattleActionResult.Failure("Reaction slot B is already occupied.");
            }

            state.HandCards.Remove(card);
            if (zoneType == DropZoneType.ReactionLeft)
            {
                state.ReactionCardLeft = card;
            }
            else
            {
                state.ReactionCardRight = card;
            }

            return BattleActionResult.Success(true, $"{card.displayName} moved into {ZoneLabel(zoneType)}.");
        }

        public BattleActionResult TryPlayCard(BattlePrototypeState state, CardDefinition card, DropZoneType zoneType)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            if (card == null)
            {
                return BattleActionResult.Failure("No card selected.");
            }

            if (!CanCardBeDroppedInZone(card, zoneType))
            {
                return BattleActionResult.Failure($"This card cannot be dropped into {ZoneLabel(zoneType)}.");
            }

            if (state.CurrentEnergy < card.energyCost)
            {
                return BattleActionResult.Failure($"Not enough energy to play {card.displayName}.");
            }

            var messages = new List<string>();
            state.CurrentEnergy -= card.energyCost;
            state.HandCards.Remove(card);

            int actualDamage = card.damageValue;
            if (card.cardType == CardType.Damage && !state.FirstDamageCardUsedThisTurn)
            {
                actualDamage += 1;
                state.FirstDamageCardUsedThisTurn = true;
                messages.Add("O passive: first damage card this turn gets +1 damage.");
            }

            if (card.cardType == CardType.Damage && state.NextDamageBonus > 0)
            {
                actualDamage += state.NextDamageBonus;
                messages.Add($"S buff applied: +{state.NextDamageBonus} damage.");
                state.NextDamageBonus = 0;
            }

            switch (card.id)
            {
                case "c":
                    state.NextReactionDiscount = 1;
                    messages.Add("C effect: next reaction costs 1 less energy this turn.");
                    break;
                case "b":
                    state.DrawOnNextReaction = true;
                    messages.Add("B effect: draw 1 card after the next successful reaction.");
                    break;
                case "s":
                    state.NextDamageBonus = 1;
                    messages.Add("S effect: next damage card this turn gets +1 damage.");
                    break;
                case "ar":
                    DrawCard(state, messages, "Ar effect");
                    break;
            }

            if (card.cardType == CardType.Damage)
            {
                if (zoneType == DropZoneType.EnemyTarget)
                {
                    state.EnemyHp = Mathf.Max(0, state.EnemyHp - actualDamage);
                }
                else
                {
                    state.PlayerHp = Mathf.Max(0, state.PlayerHp - actualDamage);
                }

                messages.Add($"{card.displayName} hit {ZoneLabel(zoneType)} for {actualDamage} damage.");
            }
            else
            {
                messages.Add($"{card.displayName} resolved on {ZoneLabel(zoneType)}.");
            }

            return BattleActionResult.Success(true, messages.ToArray());
        }

        public BattleActionResult ResolveReaction(BattlePrototypeState state)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            if (state.ReactionCardLeft == null || state.ReactionCardRight == null)
            {
                return BattleActionResult.Failure("Two element cards are required to resolve a reaction.");
            }

            ReactionPreview preview = GetReactionPreview(state);
            if (!preview.IsValid)
            {
                return BattleActionResult.Failure("This combination does not produce a valid reaction.");
            }

            int reactionCost = GetReactionCost(state);
            if (state.CurrentEnergy < reactionCost)
            {
                return BattleActionResult.Failure($"Not enough energy to resolve the reaction. Required: {reactionCost}.");
            }

            var messages = new List<string>();
            state.CurrentEnergy -= reactionCost;
            state.NextReactionDiscount = 0;

            if (!string.IsNullOrWhiteSpace(preview.ResolvedCardId) && cardCatalog.TryGetValue(preview.ResolvedCardId, out CardDefinition resolvedCard))
            {
                state.HandCards.Add(resolvedCard);
            }

            if (!state.FirstReactionResolvedThisTurn)
            {
                state.FirstReactionResolvedThisTurn = true;
                DrawCard(state, messages, "C passive: first reaction draw");
            }

            if (state.DrawOnNextReaction)
            {
                state.DrawOnNextReaction = false;
                DrawCard(state, messages, "B follow-up draw");
            }

            messages.Add($"Reaction resolved: {preview.PreviewText}");
            state.ReactionCardLeft = null;
            state.ReactionCardRight = null;
            return BattleActionResult.Success(true, messages.ToArray());
        }

        public BattleActionResult ClearReactionSelection(BattlePrototypeState state)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            if (state.ReactionCardLeft == null && state.ReactionCardRight == null)
            {
                return BattleActionResult.Failure("Reaction area is already empty.");
            }

            if (state.ReactionCardLeft != null)
            {
                state.HandCards.Add(state.ReactionCardLeft);
            }

            if (state.ReactionCardRight != null)
            {
                state.HandCards.Add(state.ReactionCardRight);
            }

            state.ReactionCardLeft = null;
            state.ReactionCardRight = null;
            return BattleActionResult.Success(true, "Reaction area cleared.");
        }

        public BattleActionResult EndTurn(BattlePrototypeState state)
        {
            if (state == null)
            {
                throw new ArgumentNullException(nameof(state));
            }

            state.TurnNumber += 1;
            state.FirstDamageCardUsedThisTurn = false;
            state.FirstReactionResolvedThisTurn = false;
            state.NextDamageBonus = 0;
            state.CurrentEnergy = Mathf.Min(state.MaxEnergy, state.CurrentEnergy + TcaStarterCatalog.EnergyRegenPerTurn);
            return BattleActionResult.Success(true, $"Turn ended. Restored {TcaStarterCatalog.EnergyRegenPerTurn} energy.");
        }

        private void DrawCard(BattlePrototypeState state, List<string> messages, string source)
        {
            CardDefinition drawnCard = drawCard();
            state.HandCards.Add(drawnCard);
            messages.Add($"{source}: drew {drawnCard.displayName}");
        }

        private static string ZoneLabel(DropZoneType zoneType)
        {
            switch (zoneType)
            {
                case DropZoneType.EnemyTarget:
                    return "Enemy Target";
                case DropZoneType.PlayerTarget:
                    return "Player Target";
                case DropZoneType.ReactionLeft:
                    return "Reaction A";
                case DropZoneType.ReactionRight:
                    return "Reaction B";
                default:
                    return zoneType.ToString();
            }
        }
    }
}
