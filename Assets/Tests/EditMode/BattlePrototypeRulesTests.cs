using System.Collections.Generic;
using NUnit.Framework;
using TCA.Battle;
using TCA.Data;
using TCA.UI;

namespace TCA.Tests.EditMode
{
    public sealed class BattlePrototypeRulesTests
    {
        [Test]
        public void PlayDamageCard_ConsumesEnergy_AndDamagesEnemy()
        {
            IReadOnlyDictionary<string, CardDefinition> catalog = TcaStarterCatalog.CreateCardCatalog();
            var state = new BattlePrototypeState(new[] { catalog["o"] });
            var rules = new BattlePrototypeRules(catalog, () => catalog["c"]);

            BattleActionResult result = rules.TryPlayCard(state, catalog["o"], DropZoneType.EnemyTarget);

            Assert.That(result.Succeeded, Is.True);
            Assert.That(state.CurrentEnergy, Is.EqualTo(6));
            Assert.That(state.EnemyHp, Is.EqualTo(27));
            Assert.That(state.HandCards.Count, Is.EqualTo(0));
        }

        [Test]
        public void ResolveReaction_CreatesProduct_AndClearsReactionSlots()
        {
            IReadOnlyDictionary<string, CardDefinition> catalog = TcaStarterCatalog.CreateCardCatalog();
            var state = new BattlePrototypeState(new[] { catalog["c"], catalog["o"] });
            var rules = new BattlePrototypeRules(catalog, () => catalog["n"]);

            Assert.That(rules.TryAssignReactionCard(state, catalog["c"], DropZoneType.ReactionLeft).Succeeded, Is.True);
            Assert.That(rules.TryAssignReactionCard(state, catalog["o"], DropZoneType.ReactionRight).Succeeded, Is.True);

            BattleActionResult result = rules.ResolveReaction(state);

            Assert.That(result.Succeeded, Is.True);
            Assert.That(state.ReactionCardLeft, Is.Null);
            Assert.That(state.ReactionCardRight, Is.Null);
            Assert.That(state.HandCards, Has.Some.Matches<CardDefinition>(card => card.id == "co"));
        }

        [Test]
        public void ClearReactionSelection_ReturnsCardsToHand()
        {
            IReadOnlyDictionary<string, CardDefinition> catalog = TcaStarterCatalog.CreateCardCatalog();
            var state = new BattlePrototypeState(new[] { catalog["c"], catalog["n"] });
            var rules = new BattlePrototypeRules(catalog, () => catalog["o"]);

            rules.TryAssignReactionCard(state, catalog["c"], DropZoneType.ReactionLeft);
            rules.TryAssignReactionCard(state, catalog["n"], DropZoneType.ReactionRight);

            BattleActionResult result = rules.ClearReactionSelection(state);

            Assert.That(result.Succeeded, Is.True);
            Assert.That(state.ReactionCardLeft, Is.Null);
            Assert.That(state.ReactionCardRight, Is.Null);
            Assert.That(state.HandCards.Count, Is.EqualTo(2));
        }
    }
}
