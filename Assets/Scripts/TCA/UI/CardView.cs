using System;
using System.Threading.Tasks;
using TMPro;
using TCA.Assets;
using TCA.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TCA.UI
{
    public enum CardViewMode
    {
        HandCompact,
        InspectFull,
        ReactionSlot
    }

    public sealed class CardView : MonoBehaviour, IPointerClickHandler, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private Action<CardView> clickHandler;
        private Action<CardView> beginDragHandler;
        private Action<CardView, PointerEventData> endDragHandler;
        private Canvas rootCanvas;
        private GameObject dragGhost;
        private bool interactable = true;
        private bool isDragging;
        private ITcaAssetProvider assetProvider;
        private int artVersion;

        [Header("UI Components")]
        [SerializeField] private CanvasGroup canvasGroup;
        [SerializeField] private LayoutElement layoutElement;
        [SerializeField] private Outline outline;
        [SerializeField] private Shadow shadow;
        [SerializeField] private Image chromeImage;
        [SerializeField] private Image artFrameImage;
        [SerializeField] private Image artImage;
        [SerializeField] private Image infoBarImage;
        [SerializeField] private Image costBubbleImage;
        [SerializeField] private RectTransform artRootRect;
        [SerializeField] private RectTransform infoBarRect;
        [SerializeField] private TextMeshProUGUI titleText;
        [SerializeField] private TextMeshProUGUI metaText;
        [SerializeField] private TextMeshProUGUI rulesText;
        [SerializeField] private TextMeshProUGUI costText;
        [SerializeField] private TextMeshProUGUI slotHintText;

        public CardDefinition Definition { get; private set; }
        public CardViewMode Mode { get; private set; }

        internal bool HasVisualBindings =>
            canvasGroup != null &&
            layoutElement != null &&
            outline != null &&
            shadow != null &&
            chromeImage != null &&
            artFrameImage != null &&
            artImage != null &&
            infoBarImage != null &&
            costBubbleImage != null &&
            artRootRect != null &&
            infoBarRect != null &&
            titleText != null &&
            metaText != null &&
            rulesText != null &&
            costText != null &&
            slotHintText != null;

        public void Initialize(CardDefinition definition, CardViewMode mode, Canvas canvas, ITcaAssetProvider provider)
        {
            if (!HasVisualBindings)
            {
                throw new InvalidOperationException($"{name} is missing complete CardView bindings. Run the TCA UI upgrade/validator first.");
            }

            Definition = definition;
            Mode = mode;
            rootCanvas = canvas;
            assetProvider = provider;
            ApplyMode();
            ApplyCard();
        }

        public void ConfigureInteraction(Action<CardView> onClicked, Action<CardView> onBeginDrag, Action<CardView, PointerEventData> onEndDrag)
        {
            clickHandler = onClicked;
            beginDragHandler = onBeginDrag;
            endDragHandler = onEndDrag;
        }

        public void SetInteractable(bool value)
        {
            interactable = value;
            canvasGroup.interactable = value;
        }

        public void SetCard(CardDefinition definition, CardViewMode mode)
        {
            if (!HasVisualBindings)
            {
                throw new InvalidOperationException($"{name} is missing complete CardView bindings.");
            }

            Definition = definition;
            Mode = mode;
            ApplyMode();
            ApplyCard();
        }

        public void SetHighlighted(bool highlighted)
        {
            outline.effectColor = highlighted
                ? new Color(0.91f, 0.68f, 0.18f, 0.95f)
                : new Color(0.18f, 0.16f, 0.14f, 0.44f);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (!interactable || isDragging || Definition == null)
            {
                return;
            }

            clickHandler?.Invoke(this);
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!interactable || Definition == null || rootCanvas == null)
            {
                return;
            }

            isDragging = true;
            beginDragHandler?.Invoke(this);
            canvasGroup.alpha = 0.40f;
            canvasGroup.blocksRaycasts = false;
            dragGhost = CreateGhost(rootCanvas.transform);
            UpdateGhostPosition(eventData.position);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (!isDragging || dragGhost == null)
            {
                return;
            }

            UpdateGhostPosition(eventData.position);
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (!isDragging)
            {
                return;
            }

            isDragging = false;
            if (dragGhost != null)
            {
                Destroy(dragGhost);
            }

            canvasGroup.alpha = 1f;
            canvasGroup.blocksRaycasts = true;
            endDragHandler?.Invoke(this, eventData);
        }

        private void ApplyCard()
        {
            if (Definition == null)
            {
                ApplyEmptyCard();
                return;
            }

            switch (Mode)
            {
                case CardViewMode.HandCompact:
                    ApplyHandCompactCard();
                    break;
                case CardViewMode.ReactionSlot:
                    ApplyReactionCard();
                    break;
                case CardViewMode.InspectFull:
                    ApplyInspectCard();
                    break;
            }

            _ = RefreshArtAsync(Definition, ++artVersion);
        }

        private void ApplyMode()
        {
            switch (Mode)
            {
                case CardViewMode.HandCompact:
                    ApplyHandCompactMode();
                    break;
                case CardViewMode.ReactionSlot:
                    ApplyReactionSlotMode();
                    break;
                case CardViewMode.InspectFull:
                    ApplyInspectMode();
                    break;
            }
        }

        private void ApplyHandCompactMode()
        {
            layoutElement.preferredWidth = 132f;
            layoutElement.preferredHeight = 188f;
            costBubbleImage.gameObject.SetActive(false);

            SetRect(artRootRect, new Vector2(0.08f, 0.18f), new Vector2(0.92f, 0.62f), Vector2.zero, Vector2.zero);
            SetRect(infoBarRect, new Vector2(0.05f, 0.05f), new Vector2(0.95f, 0.95f), Vector2.zero, Vector2.zero);
            SetRect(titleText.rectTransform, new Vector2(0f, 0.62f), new Vector2(0.58f, 1f), new Vector2(4f, 0f), new Vector2(-4f, 0f));
            SetRect(metaText.rectTransform, new Vector2(0.42f, 0.72f), new Vector2(1f, 1f), Vector2.zero, new Vector2(-2f, 0f));
            SetRect(rulesText.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0.18f), new Vector2(2f, 0f), new Vector2(-2f, 0f));

            titleText.fontSize = 34f;
            titleText.fontStyle = FontStyles.Bold;
            titleText.alignment = TextAlignmentOptions.TopLeft;
            metaText.fontSize = 13f;
            metaText.alignment = TextAlignmentOptions.TopRight;
            rulesText.fontSize = 10f;
            rulesText.alignment = TextAlignmentOptions.BottomLeft;
            rulesText.enableWordWrapping = true;
            slotHintText.fontSize = 15f;
        }

        private void ApplyReactionSlotMode()
        {
            layoutElement.preferredWidth = 116f;
            layoutElement.preferredHeight = 152f;
            costBubbleImage.gameObject.SetActive(false);

            SetRect(artRootRect, new Vector2(0.12f, 0.22f), new Vector2(0.88f, 0.54f), Vector2.zero, Vector2.zero);
            SetRect(infoBarRect, new Vector2(0.08f, 0.08f), new Vector2(0.92f, 0.92f), Vector2.zero, Vector2.zero);
            SetRect(titleText.rectTransform, new Vector2(0f, 0.52f), new Vector2(1f, 1f), Vector2.zero, Vector2.zero);
            SetRect(metaText.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0.22f), Vector2.zero, Vector2.zero);
            SetRect(rulesText.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), Vector2.zero, Vector2.zero);

            titleText.fontSize = 30f;
            titleText.fontStyle = FontStyles.Bold;
            titleText.alignment = TextAlignmentOptions.Top;
            metaText.fontSize = 11f;
            metaText.alignment = TextAlignmentOptions.Center;
            rulesText.fontSize = 12f;
            rulesText.alignment = TextAlignmentOptions.Center;
            rulesText.enableWordWrapping = false;
            slotHintText.fontSize = 14f;
        }

        private void ApplyInspectMode()
        {
            layoutElement.preferredWidth = 392f;
            layoutElement.preferredHeight = 580f;
            costBubbleImage.gameObject.SetActive(true);

            SetRect(artRootRect, new Vector2(0.03f, 0.03f), new Vector2(0.97f, 0.97f), Vector2.zero, Vector2.zero);
            SetRect(infoBarRect, new Vector2(0.06f, 0.04f), new Vector2(0.94f, 0.31f), Vector2.zero, Vector2.zero);
            SetRect(costBubbleImage.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(16f, -82f), new Vector2(90f, -16f));
            SetRect(titleText.rectTransform, new Vector2(0f, 0.72f), new Vector2(1f, 1f), new Vector2(18f, 0f), new Vector2(-18f, 0f));
            SetRect(metaText.rectTransform, new Vector2(0f, 0.48f), new Vector2(1f, 0.76f), new Vector2(18f, 0f), new Vector2(-18f, 0f));
            SetRect(rulesText.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0.50f), new Vector2(18f, 18f), new Vector2(-18f, -12f));

            titleText.fontSize = 34f;
            titleText.fontStyle = FontStyles.Bold;
            titleText.alignment = TextAlignmentOptions.TopLeft;
            metaText.fontSize = 20f;
            metaText.alignment = TextAlignmentOptions.TopLeft;
            rulesText.fontSize = 22f;
            rulesText.alignment = TextAlignmentOptions.TopLeft;
            rulesText.enableWordWrapping = true;
            slotHintText.fontSize = 24f;
        }

        private void ApplyHandCompactCard()
        {
            Color accent = TcaCardPresentation.GetCardAccentColor(Definition);
            chromeImage.color = Color.Lerp(new Color(0.96f, 0.95f, 0.90f, 0.98f), accent, 0.10f);
            artFrameImage.color = Color.Lerp(new Color(1f, 1f, 1f, 0.98f), accent, 0.10f);
            titleText.text = TcaCardPresentation.GetCompactCardPrimaryText(Definition);
            metaText.text = TcaCardPresentation.GetCompactCardTopRightText(Definition);
            rulesText.text = $"{Definition.displayName}\n{TcaCardPresentation.GetCompactCardBottomText(Definition)}";
            slotHintText.gameObject.SetActive(false);
        }

        private void ApplyReactionCard()
        {
            Color accent = TcaCardPresentation.GetCardAccentColor(Definition);
            chromeImage.color = Color.Lerp(new Color(0.97f, 0.95f, 0.90f, 0.98f), accent, 0.10f);
            artFrameImage.color = Color.Lerp(new Color(1f, 1f, 1f, 0.98f), accent, 0.14f);
            titleText.text = TcaCardPresentation.GetCompactCardPrimaryText(Definition);
            metaText.text = Definition.displayName;
            rulesText.text = string.Empty;
            slotHintText.gameObject.SetActive(false);
        }

        private void ApplyInspectCard()
        {
            titleText.text = Definition.displayName;
            metaText.text = $"{CardTypeLabel(Definition.cardType)} | Energy {Definition.energyCost}";
            rulesText.text = Definition.rulesText;
            costText.text = Definition.energyCost.ToString();
            slotHintText.gameObject.SetActive(false);
        }

        private void ApplyEmptyCard()
        {
            artVersion++;
            artImage.sprite = null;
            artImage.color = new Color(1f, 1f, 1f, 0f);
            titleText.text = string.Empty;
            metaText.text = string.Empty;
            rulesText.text = string.Empty;
            costText.text = "-";

            switch (Mode)
            {
                case CardViewMode.ReactionSlot:
                    slotHintText.text = "DROP\nELEMENT";
                    break;
                case CardViewMode.HandCompact:
                    slotHintText.text = "DRAW PILE";
                    break;
                default:
                    slotHintText.text = "NO CARD";
                    break;
            }

            slotHintText.gameObject.SetActive(true);
        }

        private async Task RefreshArtAsync(CardDefinition definition, int version)
        {
            if (definition == null || assetProvider == null)
            {
                return;
            }

            try
            {
                Sprite sprite = await assetProvider.LoadSpriteAsync(definition.artAddress);
                if (version != artVersion || artImage == null)
                {
                    return;
                }

                artImage.sprite = sprite;
                artImage.color = Color.white;
                artImage.preserveAspect = true;
            }
            catch (Exception exception)
            {
                Debug.LogError($"CardView failed to load art: {definition.displayName} / {definition.artAddress}\n{exception}");
            }
        }

        private GameObject CreateGhost(Transform parent)
        {
            var go = new GameObject($"{name}_Ghost", typeof(RectTransform), typeof(CanvasGroup), typeof(Image), typeof(Outline), typeof(Shadow));
            go.transform.SetParent(parent, false);

            RectTransform rectTransform = go.GetComponent<RectTransform>();
            rectTransform.sizeDelta = ((RectTransform)transform).rect.size;

            Image image = go.GetComponent<Image>();
            image.sprite = chromeImage.sprite;
            image.type = chromeImage.type;
            image.color = chromeImage.color;

            Outline ghostOutline = go.GetComponent<Outline>();
            ghostOutline.useGraphicAlpha = false;
            ghostOutline.effectColor = new Color(1f, 1f, 1f, 0.16f);
            ghostOutline.effectDistance = new Vector2(1f, -1f);

            Shadow ghostShadow = go.GetComponent<Shadow>();
            ghostShadow.useGraphicAlpha = false;
            ghostShadow.effectColor = new Color(0f, 0f, 0f, 0.24f);
            ghostShadow.effectDistance = new Vector2(10f, -10f);

            CanvasGroup ghostCanvasGroup = go.GetComponent<CanvasGroup>();
            ghostCanvasGroup.blocksRaycasts = false;

            GameObject artGhostObject = new GameObject("GhostArt", typeof(RectTransform), typeof(Image));
            artGhostObject.transform.SetParent(go.transform, false);
            RectTransform artRect = artGhostObject.GetComponent<RectTransform>();
            Stretch(artRect, 14f, 14f, 64f, 14f);
            Image artGhost = artGhostObject.GetComponent<Image>();
            artGhost.sprite = artImage.sprite;
            artGhost.preserveAspect = true;
            artGhost.color = Color.white;

            GameObject textObject = new GameObject("GhostTitle", typeof(RectTransform), typeof(TextMeshProUGUI));
            textObject.transform.SetParent(go.transform, false);
            TextMeshProUGUI text = textObject.GetComponent<TextMeshProUGUI>();
            text.text = Definition.displayName;
            text.font = titleText.font;
            text.fontSharedMaterial = titleText.fontSharedMaterial;
            text.fontSize = 20f;
            text.alignment = TextAlignmentOptions.BottomLeft;
            text.color = new Color(0.94f, 0.97f, 1f, 1f);
            RectTransform textRect = text.rectTransform;
            textRect.anchorMin = new Vector2(0f, 0f);
            textRect.anchorMax = new Vector2(1f, 0f);
            textRect.pivot = new Vector2(0.5f, 0f);
            textRect.sizeDelta = new Vector2(-20f, 52f);
            textRect.anchoredPosition = new Vector2(0f, 8f);

            return go;
        }

        private void UpdateGhostPosition(Vector2 screenPosition)
        {
            RectTransform ghostTransform = dragGhost.transform as RectTransform;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rootCanvas.transform as RectTransform, screenPosition, null, out Vector2 localPoint);
            ghostTransform.anchoredPosition = localPoint;
        }

        private static void SetRect(RectTransform rectTransform, Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
        {
            rectTransform.anchorMin = anchorMin;
            rectTransform.anchorMax = anchorMax;
            rectTransform.offsetMin = offsetMin;
            rectTransform.offsetMax = offsetMax;
        }

        private static void Stretch(RectTransform rectTransform, float left, float right, float top, float bottom)
        {
            rectTransform.anchorMin = Vector2.zero;
            rectTransform.anchorMax = Vector2.one;
            rectTransform.offsetMin = new Vector2(left, bottom);
            rectTransform.offsetMax = new Vector2(-right, -top);
        }

        private static string CardTypeLabel(CardType cardType)
        {
            switch (cardType)
            {
                case CardType.Damage:
                    return "Damage";
                case CardType.Buff:
                    return "Buff";
                case CardType.Solvent:
                    return "Solvent";
                default:
                    return cardType.ToString();
            }
        }
    }
}
