using System;

namespace TCA.Assets
{
    public static class TcaAssetKeys
    {
        public const string BattleBackdrop = "battle/backdrop";
        public const string IntroWelcome = "intro/welcome";

        public static string CardArt(string cardId)
        {
            if (string.IsNullOrWhiteSpace(cardId))
            {
                throw new ArgumentException("Card id cannot be empty.", nameof(cardId));
            }

            return $"card-art/{cardId.Trim().ToLowerInvariant()}";
        }

        public static bool TryGetLegacyResourcesPath(string address, out string resourcesPath)
        {
            resourcesPath = null;
            if (string.IsNullOrWhiteSpace(address))
            {
                return false;
            }

            string normalized = address.Trim().ToLowerInvariant();
            if (normalized.StartsWith("card-art/", StringComparison.Ordinal))
            {
                resourcesPath = $"CardArt/{normalized.Substring("card-art/".Length)}";
                return true;
            }

            switch (normalized)
            {
                case IntroWelcome:
                    resourcesPath = "Intro/welcome_intro";
                    return true;
                case BattleBackdrop:
                    resourcesPath = "Battle/battle_background";
                    return true;
            }

            if (normalized.StartsWith("ui/", StringComparison.Ordinal))
            {
                string fileName = normalized.Substring("ui/".Length).Replace('-', '_');
                resourcesPath = $"UI/{fileName}";
                return true;
            }

            if (normalized.StartsWith("battle/", StringComparison.Ordinal))
            {
                string fileName = normalized.Substring("battle/".Length).Replace('-', '_');
                resourcesPath = $"Battle/{fileName}";
                return true;
            }

            if (normalized.StartsWith("intro/", StringComparison.Ordinal))
            {
                string fileName = normalized.Substring("intro/".Length).Replace('-', '_');
                resourcesPath = $"Intro/{fileName}";
                return true;
            }

            return false;
        }

        public static class Ui
        {
            public const string FrameCard = "ui/frame-card";
            public const string FrameArt = "ui/frame-art";
            public const string FrameInfo = "ui/frame-info";
            public const string FrameSlot = "ui/frame-slot";
            public const string BubbleCost = "ui/bubble-cost";
            public const string ButtonReact = "ui/button-react";
            public const string ButtonClear = "ui/button-clear";
            public const string ButtonEndTurn = "ui/button-end-turn";
            public const string ButtonClose = "ui/button-close";
            public const string PanelTopInfo = "ui/panel-top-info";
            public const string PanelArena = "ui/panel-arena";
            public const string PanelHand = "ui/panel-hand";
            public const string PanelReaction = "ui/panel-reaction";
            public const string PanelLog = "ui/panel-log";
            public const string ZoneEnemy = "ui/zone-enemy";
            public const string ZonePlayer = "ui/zone-player";
            public const string DeskPlate = "ui/desk-plate";
            public const string BattleBackdrop = "ui/battle-backdrop";
        }
    }
}
