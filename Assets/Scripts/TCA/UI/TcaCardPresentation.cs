using TCA.Data;
using UnityEngine;

namespace TCA.UI
{
    public static class TcaCardPresentation
    {
        public static Color GetCardAccentColor(CardDefinition card)
        {
            return AccentForSymbol(card?.elementSymbol ?? card?.id);
        }

        public static string GetCompactCardPrimaryText(CardDefinition card)
        {
            if (card == null)
            {
                return string.Empty;
            }

            if (card.isElementCard)
            {
                return card.elementSymbol;
            }

            switch ((card.id ?? string.Empty).ToLowerInvariant())
            {
                case "co":
                    return "CO";
                case "no2":
                    return "NO2";
                case "h2o2":
                    return "H2O2";
                case "cl2":
                    return "Cl2";
                default:
                    return card.elementSymbol;
            }
        }

        public static string GetCompactCardTopRightText(CardDefinition card)
        {
            if (card == null)
            {
                return string.Empty;
            }

            if (!card.isElementCard)
            {
                switch (card.cardType)
                {
                    case CardType.Damage:
                        return "DMG";
                    case CardType.Buff:
                        return "BUFF";
                    case CardType.Solvent:
                        return "SOLV";
                    default:
                        return card.cardType.ToString().ToUpperInvariant();
                }
            }

            switch ((card.id ?? string.Empty).ToLowerInvariant())
            {
                case "h":
                    return "I A";
                case "li":
                case "na":
                    return "I A";
                case "b":
                case "al":
                    return "III A";
                case "c":
                case "si":
                    return "IV A";
                case "n":
                case "p":
                    return "V A";
                case "o":
                case "s":
                    return "VI A";
                case "f":
                case "cl":
                    return "VII A";
                case "ar":
                    return "VIII A";
                default:
                    return string.Empty;
            }
        }

        public static string GetCompactCardBottomText(CardDefinition card)
        {
            if (card == null)
            {
                return string.Empty;
            }

            if (!card.isElementCard)
            {
                return $"Cost {card.energyCost}";
            }

            switch ((card.id ?? string.Empty).ToLowerInvariant())
            {
                case "h":
                    return "-1, +1";
                case "li":
                case "na":
                    return "+1";
                case "b":
                case "al":
                    return "+3";
                case "c":
                    return "-4, +2, +4";
                case "n":
                    return "-3, +3, +5";
                case "o":
                    return "-2";
                case "f":
                    return "-1";
                case "si":
                    return "-4, +4";
                case "p":
                    return "-3, +3, +5";
                case "s":
                    return "-2, +4, +6";
                case "cl":
                    return "-1, +1, +5, +7";
                case "ar":
                    return "0";
                default:
                    return card.displayName;
            }
        }

        private static Color AccentForSymbol(string symbol)
        {
            switch ((symbol ?? string.Empty).ToLowerInvariant())
            {
                case "c":
                    return new Color(0.26f, 0.28f, 0.32f, 1f);
                case "o":
                    return new Color(0.28f, 0.74f, 0.97f, 1f);
                case "cl":
                case "f":
                    return new Color(0.71f, 0.96f, 0.16f, 1f);
                case "n":
                    return new Color(0.65f, 0.72f, 0.86f, 1f);
                case "s":
                    return new Color(0.95f, 0.80f, 0.34f, 1f);
                case "p":
                    return new Color(0.95f, 0.58f, 0.48f, 1f);
                case "li":
                case "na":
                    return new Color(0.96f, 0.58f, 0.34f, 1f);
                case "al":
                case "si":
                case "ar":
                    return new Color(0.76f, 0.82f, 0.88f, 1f);
                case "b":
                    return new Color(0.72f, 0.83f, 0.62f, 1f);
                default:
                    return new Color(0.78f, 0.68f, 0.30f, 1f);
            }
        }
    }
}
