using System;
using System.Collections.Generic;
using UnityEngine;
using TCA.Assets;

namespace TCA.Data
{
    public enum CardType
    {
        Damage,
        Buff,
        Solvent
    }

    public enum CardTargeting
    {
        Enemy,
        Self,
        Any
    }

    [Serializable]
    public sealed class CardDefinition
    {
        public string id;
        public string displayName;
        public string elementSymbol;
        public CardType cardType;
        public int energyCost;
        public int damageValue;
        public string rulesText;
        public string artAddress;
        public bool isDirectDamageOnly;
        public bool isElementCard;
        public CardTargeting targeting;

        public void Validate()
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new InvalidOperationException("CardDefinition.id 不能为空。");
            }

            if (string.IsNullOrWhiteSpace(displayName))
            {
                throw new InvalidOperationException($"CardDefinition.displayName 不能为空：{id}");
            }

            if (string.IsNullOrWhiteSpace(artAddress))
            {
                throw new InvalidOperationException($"CardDefinition.artAddress 不能为空：{id}");
            }

            if (cardType == CardType.Damage)
            {
                if (!isDirectDamageOnly)
                {
                    throw new InvalidOperationException($"伤害牌必须标记为直接伤害：{id}");
                }

                if (damageValue <= 0)
                {
                    throw new InvalidOperationException($"伤害牌必须有正数伤害：{id}");
                }

                string expected = $"造成 {damageValue} 点伤害";
                if (!string.Equals(rulesText, expected, StringComparison.Ordinal))
                {
                    throw new InvalidOperationException(
                        $"伤害牌文本不合法：{id}。应为“{expected}”，实际为“{rulesText}”。");
                }
            }
            else
            {
                if (isDirectDamageOnly)
                {
                    throw new InvalidOperationException($"非伤害牌不能标记为直接伤害：{id}");
                }

                if (damageValue > 0 && string.Equals(rulesText, $"造成 {damageValue} 点伤害", StringComparison.Ordinal))
                {
                    throw new InvalidOperationException($"非伤害牌不能使用纯伤害文本：{id}");
                }
            }
        }
    }

    [Serializable]
    public sealed class CharacterDefinition
    {
        public string elementId;
        public string displayName;
        public int hp;
        public int energy;
        public string passiveText;
        public string signatureCardId;
        public List<string> deckList = new List<string>();
    }

    [Serializable]
    public sealed class BattleUiState
    {
        public int playerHp;
        public int enemyHp;
        public int playerHandCount;
        public int enemyHandCount;
        public int currentEnergy;
        public int maxEnergy;
        public List<string> selectedReactionCardIds = new List<string>();
    }

    public sealed class ReactionPreview
    {
        public ReactionPreview(string previewText, string resolvedCardId, bool isValid)
        {
            PreviewText = previewText;
            ResolvedCardId = resolvedCardId;
            IsValid = isValid;
        }

        public string PreviewText { get; }
        public string ResolvedCardId { get; }
        public bool IsValid { get; }
    }

    public static class TcaStarterCatalog
    {
        public const int EnergyRegenPerTurn = 2;
        public const int ReactionEnergyCost = 2;

        public static Dictionary<string, CardDefinition> CreateCardCatalog()
        {
            var cards = new Dictionary<string, CardDefinition>(StringComparer.OrdinalIgnoreCase)
            {
                ["c"] = CreateCard("c", "碳 C", "C", CardType.Buff, 1, 0, "本回合下一次合成少消耗 1 点能量", false, true, CardTargeting.Self),
                ["n"] = CreateCard("n", "氮 N", "N", CardType.Buff, 1, 0, "本回合你下一次受到的伤害 -1", false, true, CardTargeting.Self),
                ["o"] = CreateCard("o", "氧 O", "O", CardType.Damage, 2, 2, "造成 2 点伤害", true, true, CardTargeting.Enemy),
                ["cl"] = CreateCard("cl", "氯 Cl", "Cl", CardType.Damage, 2, 3, "造成 3 点伤害", true, true, CardTargeting.Enemy),
                ["b"] = CreateCard("b", "硼 B", "B", CardType.Buff, 1, 0, "你下一次合成成功后，抽 1 张牌", false, true, CardTargeting.Self),
                ["f"] = CreateCard("f", "氟 F", "F", CardType.Damage, 2, 3, "造成 3 点伤害", true, true, CardTargeting.Enemy),
                ["s"] = CreateCard("s", "硫 S", "S", CardType.Buff, 1, 0, "你本回合下一张伤害牌额外造成 1 点伤害", false, true, CardTargeting.Self),
                ["ar"] = CreateCard("ar", "氩 Ar", "Ar", CardType.Solvent, 2, 0, "抽 1 张牌", false, true, CardTargeting.Self),
                ["co"] = CreateCard("co", "一氧化碳 CO", "C", CardType.Damage, 2, 3, "造成 3 点伤害", true, false, CardTargeting.Enemy),
                ["no2"] = CreateCard("no2", "二氧化氮 NO₂", "N", CardType.Damage, 2, 3, "造成 3 点伤害", true, false, CardTargeting.Enemy),
                ["h2o2"] = CreateCard("h2o2", "过氧化氢 H₂O₂", "O", CardType.Damage, 2, 4, "造成 4 点伤害", true, false, CardTargeting.Enemy),
                ["cl2"] = CreateCard("cl2", "氯气 Cl₂", "Cl", CardType.Damage, 2, 4, "造成 4 点伤害", true, false, CardTargeting.Enemy)
            };

            return cards;
        }

        public static Dictionary<string, CharacterDefinition> CreateCharacters()
        {
            return new Dictionary<string, CharacterDefinition>(StringComparer.OrdinalIgnoreCase)
            {
                ["c"] = new CharacterDefinition
                {
                    elementId = "c",
                    displayName = "碳·构键者",
                    hp = 28,
                    energy = 2,
                    passiveText = "每回合第一次合成成功后，抽 1 张牌",
                    signatureCardId = "co",
                    deckList = new List<string> { "c", "c", "c", "c", "b", "b", "n", "n", "co", "co" }
                },
                ["n"] = new CharacterDefinition
                {
                    elementId = "n",
                    displayName = "氮·稳态者",
                    hp = 27,
                    energy = 2,
                    passiveText = "每回合第一次成为敌方非伤害牌目标时，取消该效果",
                    signatureCardId = "no2",
                    deckList = new List<string> { "n", "n", "n", "n", "c", "c", "o", "o", "no2", "no2" }
                },
                ["o"] = new CharacterDefinition
                {
                    elementId = "o",
                    displayName = "氧·氧化使",
                    hp = 22,
                    energy = 2,
                    passiveText = "每回合打出的第一张伤害牌额外造成 1 点伤害",
                    signatureCardId = "h2o2",
                    deckList = new List<string> { "o", "o", "o", "o", "n", "n", "f", "f", "h2o2", "h2o2" }
                },
                ["cl"] = new CharacterDefinition
                {
                    elementId = "cl",
                    displayName = "氯·腐蚀者",
                    hp = 24,
                    energy = 2,
                    passiveText = "每回合第一次对敌方使用非伤害牌后，对方下回合打出的第一张牌多消耗 1 点能量",
                    signatureCardId = "cl2",
                    deckList = new List<string> { "cl", "cl", "cl", "cl", "s", "s", "ar", "ar", "cl2", "cl2" }
                }
            };
        }

        public static List<CardDefinition> CreatePrototypeHand(IReadOnlyDictionary<string, CardDefinition> catalog)
        {
            return new List<CardDefinition>
            {
                catalog["c"],
                catalog["n"],
                catalog["o"],
                catalog["cl"],
                catalog["b"],
                catalog["s"],
                catalog["ar"],
                catalog["co"],
                catalog["no2"],
                catalog["h2o2"]
            };
        }

        public static BattleUiState CreatePrototypeState(int handCount)
        {
            return new BattleUiState
            {
                playerHp = 30,
                enemyHp = 30,
                playerHandCount = handCount,
                enemyHandCount = 10,
                currentEnergy = 8,
                maxEnergy = 8,
                selectedReactionCardIds = new List<string>()
            };
        }

        public static void ValidateAll(IReadOnlyDictionary<string, CardDefinition> catalog)
        {
            foreach (var pair in catalog)
            {
                pair.Value.Validate();
            }
        }

        public static ReactionPreview GetReactionPreview(CardDefinition first, CardDefinition second)
        {
            if (first == null || second == null)
            {
                return new ReactionPreview("放入两张元素牌后显示产物", null, false);
            }

            string left = first.id.ToLowerInvariant();
            string right = second.id.ToLowerInvariant();
            string key = string.CompareOrdinal(left, right) <= 0 ? $"{left}+{right}" : $"{right}+{left}";

            switch (key)
            {
                case "c+o":
                    return new ReactionPreview("CO / CO₂（原型默认产出 CO）", "co", true);
                case "n+o":
                    return new ReactionPreview("NO / NO₂（原型默认产出 NO₂）", "no2", true);
                case "cl+cl":
                    return new ReactionPreview("Cl₂", "cl2", true);
                case "c+c":
                    return new ReactionPreview("C（单质）", null, true);
                case "n+n":
                    return new ReactionPreview("N₂", null, true);
                case "o+o":
                    return new ReactionPreview("O₂", null, true);
                default:
                    return new ReactionPreview("当前首发原型暂不支持该组合", null, false);
            }
        }

        public static CardDefinition DrawRandomPrototypeCard(IReadOnlyDictionary<string, CardDefinition> catalog)
        {
            string[] pool = { "c", "n", "o", "cl", "b", "f", "s", "ar", "co", "no2", "h2o2", "cl2" };
            int index = UnityEngine.Random.Range(0, pool.Length);
            return catalog[pool[index]];
        }

        private static CardDefinition CreateCard(
            string id,
            string displayName,
            string elementSymbol,
            CardType cardType,
            int energyCost,
            int damageValue,
            string rulesText,
            bool isDirectDamageOnly,
            bool isElementCard,
            CardTargeting targeting)
        {
            return new CardDefinition
            {
                id = id,
                displayName = displayName,
                elementSymbol = elementSymbol,
                cardType = cardType,
                energyCost = energyCost,
                damageValue = damageValue,
                rulesText = rulesText,
                artAddress = TcaAssetKeys.CardArt(id),
                isDirectDamageOnly = isDirectDamageOnly,
                isElementCard = isElementCard,
                targeting = targeting
            };
        }
    }
}

