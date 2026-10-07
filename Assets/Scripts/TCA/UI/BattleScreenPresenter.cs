using System;
using System.Collections.Generic;
using TMPro;
using TCA.Assets;
using TCA.Battle;
using TCA.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TCA.UI
{
    public sealed class BattleScreenPresenter
    {
        private readonly Canvas canvas;
        private readonly CardView cardViewPrefab;
        private readonly RectTransform handContent;
        private readonly CardView reactionLeftView;
        private readonly CardView reactionRightView;
        private readonly CardView inspectView;
        private readonly TextMeshProUGUI enemyInfoText;
        private readonly TextMeshProUGUI playerInfoText;
        private readonly TextMeshProUGUI logText;
        private readonly TextMeshProUGUI turnText;
        private readonly TextMeshProUGUI reactionPreviewText;
        private readonly Button reactButton;
        private readonly Button clearReactionButton;
        private readonly Button endTurnButton;
        private readonly Button closeInspectButton;
        private readonly GameObject inspectPanel;
        private readonly ITcaAssetProvider assetProvider;
        private readonly List<CardView> liveHandViews = new List<CardView>();

        public BattleScreenPresenter(
            Canvas canvas,
            CardView cardViewPrefab,
            RectTransform handContent,
            CardView reactionLeftView,
            CardView reactionRightView,
            CardView inspectView,
            TextMeshProUGUI enemyInfoText,
            TextMeshProUGUI playerInfoText,
            TextMeshProUGUI logText,
            TextMeshProUGUI turnText,
            TextMeshProUGUI reactionPreviewText,
            Button reactButton,
            Button clearReactionButton,
            Button endTurnButton,
            Button closeInspectButton,
            GameObject inspectPanel,
            ITcaAssetProvider assetProvider)
        {
            this.canvas = canvas;
            this.cardViewPrefab = cardViewPrefab;
            this.handContent = handContent;
            this.reactionLeftView = reactionLeftView;
            this.reactionRightView = reactionRightView;
            this.inspectView = inspectView;
            this.enemyInfoText = enemyInfoText;
            this.playerInfoText = playerInfoText;
            this.logText = logText;
            this.turnText = turnText;
            this.reactionPreviewText = reactionPreviewText;
            this.reactButton = reactButton;
            this.clearReactionButton = clearReactionButton;
            this.endTurnButton = endTurnButton;
            this.closeInspectButton = closeInspectButton;
            this.inspectPanel = inspectPanel;
            this.assetProvider = assetProvider;
        }

        public void WireButtons(Action onResolveReaction, Action onClearReaction, Action onEndTurn, Action onCloseInspect)
        {
            reactButton.onClick.RemoveAllListeners();
            reactButton.onClick.AddListener(() => onResolveReaction?.Invoke());

            clearReactionButton.onClick.RemoveAllListeners();
            clearReactionButton.onClick.AddListener(() => onClearReaction?.Invoke());

            endTurnButton.onClick.RemoveAllListeners();
            endTurnButton.onClick.AddListener(() => onEndTurn?.Invoke());

            closeInspectButton.onClick.RemoveAllListeners();
            closeInspectButton.onClick.AddListener(() => onCloseInspect?.Invoke());
        }

        public void InitializeStaticViews()
        {
            reactionLeftView.Initialize(null, CardViewMode.ReactionSlot, canvas, assetProvider);
            reactionRightView.Initialize(null, CardViewMode.ReactionSlot, canvas, assetProvider);
            inspectView.Initialize(null, CardViewMode.InspectFull, canvas, assetProvider);
            inspectPanel.SetActive(false);
        }

        public void RebuildHand(IReadOnlyList<CardDefinition> handCards, Action<CardView> onClicked, Action<CardView> onBeginDrag, Action<CardView, PointerEventData> onEndDrag)
        {
            foreach (CardView view in liveHandViews)
            {
                if (view != null)
                {
                    UnityEngine.Object.Destroy(view.gameObject);
                }
            }

            liveHandViews.Clear();

            foreach (CardDefinition card in handCards)
            {
                CardView cardView = UnityEngine.Object.Instantiate(cardViewPrefab, handContent);
                cardView.Initialize(card, CardViewMode.HandCompact, canvas, assetProvider);
                cardView.ConfigureInteraction(onClicked, onBeginDrag, onEndDrag);
                liveHandViews.Add(cardView);
            }
        }

        public void ShowInspect(CardDefinition card)
        {
            inspectPanel.SetActive(true);
            inspectView.SetCard(card, CardViewMode.InspectFull);
        }

        public void HideInspect()
        {
            inspectPanel.SetActive(false);
        }

        public void SetDropZoneHighlight(CardDropZone zone, bool active)
        {
            zone?.SetHighlighted(active);
        }

        public void Render(BattlePrototypeState state, ReactionPreview preview, int reactionCost, bool reactEnabled, bool clearEnabled)
        {
            reactionLeftView.SetCard(state.ReactionCardLeft, CardViewMode.ReactionSlot);
            reactionRightView.SetCard(state.ReactionCardRight, CardViewMode.ReactionSlot);

            enemyInfoText.text = $"Enemy\nHP {state.EnemyHp} | Hand {state.EnemyHandCount}";
            playerInfoText.text = $"Player\nHP {state.PlayerHp}\nEnergy {state.CurrentEnergy}/{state.MaxEnergy} | Hand {state.HandCards.Count}";
            turnText.text = $"TURN {state.TurnNumber}\nReaction Phase";

            if (state.ReactionCardLeft == null && state.ReactionCardRight == null)
            {
                reactionPreviewText.text = "Choose two element cards\nto start a reaction.";
            }
            else if (preview.IsValid)
            {
                reactionPreviewText.text = $"{preview.PreviewText}\nCost {reactionCost}";
            }
            else
            {
                reactionPreviewText.text = $"No stable product\nCost {reactionCost}";
            }

            reactButton.interactable = reactEnabled;
            clearReactionButton.interactable = clearEnabled;
        }

        public void ShowLatestLog(IReadOnlyList<string> messages)
        {
            if (messages == null || messages.Count == 0)
            {
                return;
            }

            logText.text = messages[messages.Count - 1];
        }
    }
}
