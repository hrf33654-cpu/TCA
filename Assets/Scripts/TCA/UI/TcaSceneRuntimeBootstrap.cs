using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TMPro;
using TCA.Assets;
using TCA.Battle;
using TCA.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace TCA.UI
{
    public static class TcaSceneRuntimeBootstrap
    {
        private static bool subscribed;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Register()
        {
            if (subscribed)
            {
                return;
            }

            subscribed = true;
            SceneManager.sceneLoaded += OnSceneLoaded;
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void BootstrapActiveScene()
        {
            Bootstrap(SceneManager.GetActiveScene());
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            Bootstrap(scene);
        }

        private static void Bootstrap(Scene scene)
        {
            ApplyLandscapeOnlyOrientation();

            if (scene.name == "SampleScene")
            {
                SceneManager.LoadScene("Intro");
            }
        }

        private static void ApplyLandscapeOnlyOrientation()
        {
            Screen.orientation = ScreenOrientation.AutoRotation;
            Screen.autorotateToPortrait = false;
            Screen.autorotateToPortraitUpsideDown = false;
            Screen.autorotateToLandscapeLeft = true;
            Screen.autorotateToLandscapeRight = true;
        }
    }

    public sealed class IntroScreenController : MonoBehaviour
    {
        [SerializeField] private TextMeshProUGUI continueText;
        [SerializeField] private Button tapOverlay;

        private float pulseTimer;

        private void Start()
        {
            if (continueText == null)
            {
                throw new MissingReferenceException("IntroScreenController is missing continueText.");
            }

            if (tapOverlay == null)
            {
                throw new MissingReferenceException("IntroScreenController is missing tapOverlay.");
            }

            tapOverlay.onClick.AddListener(ContinueToBattle);
        }

        private void Update()
        {
            pulseTimer += Time.unscaledDeltaTime;
            Color color = continueText.color;
            color.a = 0.65f + (Mathf.Sin(pulseTimer * 2.2f) * 0.20f);
            continueText.color = color;
        }

        private void ContinueToBattle()
        {
            SceneManager.LoadScene("BattlePrototype");
        }
    }

    public sealed class BattlePrototypeController : MonoBehaviour
    {
        [Header("Prefabs")]
        [SerializeField] private CardView cardViewPrefab;

        [Header("UI References")]
        [SerializeField] private Canvas canvas;
        [SerializeField] private RectTransform handContent;
        [SerializeField] private CardView reactionLeftView;
        [SerializeField] private CardView reactionRightView;
        [SerializeField] private CardDropZone reactionLeftZone;
        [SerializeField] private CardDropZone reactionRightZone;
        [SerializeField] private CardView inspectView;
        [SerializeField] private TextMeshProUGUI enemyInfoText;
        [SerializeField] private TextMeshProUGUI playerInfoText;
        [SerializeField] private TextMeshProUGUI logText;
        [SerializeField] private TextMeshProUGUI turnText;
        [SerializeField] private TextMeshProUGUI reactionPreviewText;
        [SerializeField] private Button reactButton;
        [SerializeField] private Button clearReactionButton;
        [SerializeField] private Button endTurnButton;
        [SerializeField] private Button closeInspectButton;
        [SerializeField] private GameObject inspectPanel;
        [SerializeField] private List<CardDropZone> dropZones = new List<CardDropZone>();

        private IReadOnlyDictionary<string, CardDefinition> cardCatalog;
        private BattlePrototypeState state;
        private BattlePrototypeRules rules;
        private BattleScreenPresenter presenter;
        private ITcaAssetProvider assetProvider;

        private async void Start()
        {
            ValidateSceneBindings();
            RepairLegacySceneBindingsIfNeeded();
            InitializeDropZones();

            cardCatalog = TcaStarterCatalog.CreateCardCatalog();
            TcaStarterCatalog.ValidateAll(cardCatalog);

            assetProvider = new TcaAddressableAssetProvider();
            state = new BattlePrototypeState(TcaStarterCatalog.CreatePrototypeHand(cardCatalog));
            rules = new BattlePrototypeRules(cardCatalog, () => TcaStarterCatalog.DrawRandomPrototypeCard(cardCatalog));

            presenter = new BattleScreenPresenter(
                canvas,
                cardViewPrefab,
                handContent,
                reactionLeftView,
                reactionRightView,
                inspectView,
                enemyInfoText,
                playerInfoText,
                logText,
                turnText,
                reactionPreviewText,
                reactButton,
                clearReactionButton,
                endTurnButton,
                closeInspectButton,
                inspectPanel,
                assetProvider);

            presenter.WireButtons(ResolveReaction, ClearReactionSelection, EndTurn, HideInspect);
            presenter.InitializeStaticViews();

            RebuildHand();
            RenderAll();
            ShowMessages(new[] { "Battle ready. Drag element cards into reaction slots or target zones." });

            await WarmUpInitialArtAsync();
        }

        private void OnDestroy()
        {
            assetProvider?.Dispose();
        }

        private void RebuildHand()
        {
            presenter.RebuildHand(state.HandCards.ToList(), ShowInspect, HandleDragStarted, HandleDragEnded);
        }

        private void ShowInspect(CardView cardView)
        {
            if (cardView?.Definition == null)
            {
                return;
            }

            presenter.ShowInspect(cardView.Definition);
        }

        private void HideInspect()
        {
            presenter.HideInspect();
        }

        private void HandleDragStarted(CardView cardView)
        {
            foreach (CardDropZone zone in dropZones)
            {
                presenter.SetDropZoneHighlight(zone, rules.CanCardBeDroppedInZone(cardView.Definition, zone.ZoneType));
            }
        }

        private void HandleDragEnded(CardView cardView, PointerEventData eventData)
        {
            foreach (CardDropZone zone in dropZones)
            {
                presenter.SetDropZoneHighlight(zone, false);
            }

            CardDropZone targetZone = ResolveDropZone(eventData);
            if (targetZone == null)
            {
                ShowMessages(new[] { $"No valid drop zone hit: {cardView.Definition.displayName}" });
                return;
            }

            BattleActionResult result;
            switch (targetZone.ZoneType)
            {
                case DropZoneType.EnemyTarget:
                case DropZoneType.PlayerTarget:
                    result = rules.TryPlayCard(state, cardView.Definition, targetZone.ZoneType);
                    break;
                case DropZoneType.ReactionLeft:
                case DropZoneType.ReactionRight:
                    result = rules.TryAssignReactionCard(state, cardView.Definition, targetZone.ZoneType);
                    break;
                default:
                    result = BattleActionResult.Failure("Unknown drop zone.");
                    break;
            }

            HandleActionResult(result);
        }

        private CardDropZone ResolveDropZone(PointerEventData eventData)
        {
            var results = new List<RaycastResult>();
            EventSystem.current.RaycastAll(eventData, results);
            foreach (RaycastResult result in results)
            {
                CardDropZone zone = result.gameObject.GetComponentInParent<CardDropZone>();
                if (zone != null)
                {
                    return zone;
                }
            }

            return null;
        }

        private void ResolveReaction()
        {
            HandleActionResult(rules.ResolveReaction(state));
        }

        private void ClearReactionSelection()
        {
            HandleActionResult(rules.ClearReactionSelection(state));
        }

        private void EndTurn()
        {
            HandleActionResult(rules.EndTurn(state));
        }

        private void HandleActionResult(BattleActionResult result)
        {
            ShowMessages(result.Messages);
            if (!result.StateChanged)
            {
                return;
            }

            RebuildHand();
            RenderAll();
        }

        private void RenderAll()
        {
            ReactionPreview preview = rules.GetReactionPreview(state);
            int reactionCost = rules.GetReactionCost(state);
            bool reactEnabled = state.ReactionCardLeft != null &&
                                state.ReactionCardRight != null &&
                                preview.IsValid &&
                                state.CurrentEnergy >= reactionCost;
            bool clearEnabled = state.ReactionCardLeft != null || state.ReactionCardRight != null;

            presenter.Render(state, preview, reactionCost, reactEnabled, clearEnabled);
        }

        private void ShowMessages(IReadOnlyList<string> messages)
        {
            presenter.ShowLatestLog(messages);
        }

        private void ValidateSceneBindings()
        {
            ValidateReference(cardViewPrefab, nameof(cardViewPrefab));
            ValidateReference(canvas, nameof(canvas));
            ValidateReference(handContent, nameof(handContent));
            ValidateReference(reactionLeftView, nameof(reactionLeftView));
            ValidateReference(reactionRightView, nameof(reactionRightView));
            ValidateReference(reactionLeftZone, nameof(reactionLeftZone));
            ValidateReference(reactionRightZone, nameof(reactionRightZone));
            ValidateReference(inspectView, nameof(inspectView));
            ValidateReference(enemyInfoText, nameof(enemyInfoText));
            ValidateReference(playerInfoText, nameof(playerInfoText));
            ValidateReference(logText, nameof(logText));
            ValidateReference(turnText, nameof(turnText));
            ValidateReference(reactionPreviewText, nameof(reactionPreviewText));
            ValidateReference(reactButton, nameof(reactButton));
            ValidateReference(clearReactionButton, nameof(clearReactionButton));
            ValidateReference(endTurnButton, nameof(endTurnButton));
            ValidateReference(closeInspectButton, nameof(closeInspectButton));
            ValidateReference(inspectPanel, nameof(inspectPanel));

            if (dropZones == null || dropZones.Count == 0)
            {
                throw new MissingReferenceException("BattlePrototypeController is missing dropZones.");
            }
        }

        private void RepairLegacySceneBindingsIfNeeded()
        {
            reactionLeftView = EnsureHostedCardView(reactionLeftView, "ReactionLeftCardView", new Vector2(8f, 8f));
            reactionRightView = EnsureHostedCardView(reactionRightView, "ReactionRightCardView", new Vector2(8f, 8f));
            inspectView = EnsureHostedCardView(inspectView, "InspectCardView", Vector2.zero);
        }

        private CardView EnsureHostedCardView(CardView assignedView, string childName, Vector2 padding)
        {
            if (assignedView == null)
            {
                return null;
            }

            if (assignedView.HasVisualBindings)
            {
                return assignedView;
            }

            Transform host = assignedView.transform;
            CardView hostedView = host
                .GetComponentsInChildren<CardView>(true)
                .FirstOrDefault(view => view != assignedView && view.HasVisualBindings);

            if (hostedView == null)
            {
                hostedView = Instantiate(cardViewPrefab, host);
                hostedView.name = childName;
                RectTransform rect = hostedView.transform as RectTransform;
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = new Vector2(padding.x, padding.y);
                rect.offsetMax = new Vector2(-padding.x, -padding.y);
                rect.localScale = Vector3.one;
            }

            PrepareLegacyCardHost(host, assignedView, hostedView);
            return hostedView;
        }

        private async Task WarmUpInitialArtAsync()
        {
            try
            {
                await assetProvider.PreloadSpritesAsync(state.HandCards.Select(card => card.artAddress));
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"TCA art warmup failed. UI will continue with deferred loading.\n{exception}");
            }
        }

        private static void PrepareLegacyCardHost(Transform host, CardView shellView, CardView hostedView)
        {
            if (host == null || hostedView == null)
            {
                return;
            }

            shellView.enabled = false;

            RectTransform hostRect = host as RectTransform;
            if (hostRect != null)
            {
                hostRect.pivot = new Vector2(0.5f, 0.5f);
            }

            Image hostImage = host.GetComponent<Image>();
            if (hostImage != null && host.GetComponent<CardDropZone>() == null)
            {
                hostImage.color = new Color(hostImage.color.r, hostImage.color.g, hostImage.color.b, 0f);
                hostImage.raycastTarget = false;
            }

            hostedView.transform.SetAsLastSibling();
        }

        private void InitializeDropZones()
        {
            InitializeZone(reactionLeftZone, DropZoneType.ReactionLeft);
            InitializeZone(reactionRightZone, DropZoneType.ReactionRight);

            foreach (CardDropZone zone in dropZones)
            {
                if (zone == null || zone == reactionLeftZone || zone == reactionRightZone)
                {
                    continue;
                }

                string zoneName = zone.name.ToLowerInvariant();
                DropZoneType zoneType = zoneName.Contains("enemy") ? DropZoneType.EnemyTarget : DropZoneType.PlayerTarget;
                InitializeZone(zone, zoneType);
            }
        }

        private static void InitializeZone(CardDropZone zone, DropZoneType zoneType)
        {
            if (zone == null)
            {
                return;
            }

            zone.Initialize(zoneType, zone.GetComponent<Image>());
        }

        private void ValidateReference(UnityEngine.Object target, string fieldName)
        {
            if (target == null)
            {
                throw new MissingReferenceException($"BattlePrototypeController is missing {fieldName}.");
            }
        }
    }

    public enum DropZoneType
    {
        EnemyTarget,
        PlayerTarget,
        ReactionLeft,
        ReactionRight
    }

    public sealed class CardDropZone : MonoBehaviour
    {
        private Image image;
        private Color baseColor;

        public DropZoneType ZoneType { get; private set; }

        public string ZoneTypeLabel
        {
            get
            {
                switch (ZoneType)
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
                        return ZoneType.ToString();
                }
            }
        }

        public void Initialize(DropZoneType zoneType, Image targetImage)
        {
            ZoneType = zoneType;
            image = targetImage;
            baseColor = targetImage != null ? targetImage.color : Color.white;
        }

        public Image TargetImage
        {
            get
            {
                if (image == null)
                {
                    image = GetComponent<Image>();
                    if (image != null)
                    {
                        baseColor = image.color;
                    }
                }

                return image;
            }
        }

        public void SetHighlighted(bool active)
        {
            Image targetImage = TargetImage;
            if (targetImage == null)
            {
                return;
            }

            targetImage.color = active
                ? Color.Lerp(baseColor, new Color(0.67f, 0.78f, 0.96f, 0.28f), 0.82f)
                : baseColor;
        }
    }
}
