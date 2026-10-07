using System.Collections.Generic;
using System.Linq;
using TCA.Assets;
using TCA.Data;
using TCA.UI;
using TMPro;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;
using UnityEditor.Build;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace TCA.Editor
{
    public static class TcaUiProjectValidator
    {
        [MenuItem("TCA Tools/Validate UI Setup")]
        public static void ValidateUiSetup()
        {
            List<string> failures = CollectFailures();
            if (failures.Count == 0)
            {
                Debug.Log("TCA UI validation passed.");
                return;
            }

            foreach (string failure in failures)
            {
                Debug.LogError(failure);
            }

            throw new BuildFailedException($"TCA UI validation failed with {failures.Count} issues.");
        }

        public static void RunBatchValidate()
        {
            ValidateUiSetup();
        }

        private static List<string> CollectFailures()
        {
            var failures = new List<string>();
            ValidateAddressables(failures);
            ValidateCardViewPrefab(failures);
            ValidateBattleScene(failures);
            ValidateIntroScene(failures);
            return failures;
        }

        private static void ValidateAddressables(List<string> failures)
        {
            AddressableAssetSettings settings = AddressableAssetSettingsDefaultObject.Settings;
            if (settings == null)
            {
                failures.Add("Addressables settings are missing. Run TCA Tools/Sync Addressables first.");
                return;
            }

            IReadOnlyDictionary<string, CardDefinition> catalog = TcaStarterCatalog.CreateCardCatalog();
            foreach (CardDefinition card in catalog.Values)
            {
                if (!HasAddress(settings, card.artAddress))
                {
                    failures.Add($"Missing Addressables card entry: {card.artAddress}");
                }
            }

            string[] requiredUiAddresses =
            {
                TcaAssetKeys.Ui.FrameCard,
                TcaAssetKeys.Ui.FrameArt,
                TcaAssetKeys.Ui.FrameInfo,
                TcaAssetKeys.Ui.FrameSlot,
                TcaAssetKeys.Ui.BubbleCost,
                TcaAssetKeys.Ui.ButtonReact,
                TcaAssetKeys.Ui.ButtonClear,
                TcaAssetKeys.Ui.ButtonEndTurn,
                TcaAssetKeys.Ui.ButtonClose,
                TcaAssetKeys.Ui.PanelTopInfo,
                TcaAssetKeys.Ui.PanelArena,
                TcaAssetKeys.Ui.PanelHand,
                TcaAssetKeys.Ui.PanelReaction,
                TcaAssetKeys.Ui.PanelLog,
                TcaAssetKeys.Ui.ZoneEnemy,
                TcaAssetKeys.Ui.ZonePlayer,
                TcaAssetKeys.BattleBackdrop,
                TcaAssetKeys.IntroWelcome
            };

            foreach (string address in requiredUiAddresses)
            {
                if (!HasAddress(settings, address))
                {
                    failures.Add($"Missing Addressables UI entry: {address}");
                }
            }
        }

        private static bool HasAddress(AddressableAssetSettings settings, string address)
        {
            return settings.groups
                .Where(group => group != null)
                .SelectMany(group => group.entries)
                .Any(entry => entry.address == address);
        }

        private static void ValidateCardViewPrefab(List<string> failures)
        {
            CardView prefab = AssetDatabase.LoadAssetAtPath<CardView>("Assets/Resources/CardViewPrefab.prefab");
            if (prefab == null)
            {
                failures.Add("CardViewPrefab.prefab is missing or has no CardView.");
                return;
            }

            ValidateCardViewBindings(prefab, failures, "CardViewPrefab");
        }

        private static void ValidateBattleScene(List<string> failures)
        {
            var scene = EditorSceneManager.OpenScene("Assets/Scenes/BattlePrototype.scene", OpenSceneMode.Single);
            GameObject battleManagerObject = scene.GetRootGameObjects()
                .SelectMany(root => root.GetComponentsInChildren<Transform>(true))
                .FirstOrDefault(transform => transform.name == "BattleManager")
                ?.gameObject;

            if (battleManagerObject == null)
            {
                failures.Add("BattlePrototype.scene is missing BattleManager.");
                return;
            }

            BattlePrototypeController controller = battleManagerObject.GetComponent<BattlePrototypeController>();
            if (controller == null)
            {
                failures.Add("BattleManager is missing BattlePrototypeController.");
            }
            else
            {
                ValidateControllerBindings(controller, failures);
            }

            bool hasEventSystem = scene.GetRootGameObjects().Any(root => root.GetComponentInChildren<UnityEngine.EventSystems.EventSystem>(true) != null);
            if (!hasEventSystem)
            {
                failures.Add("BattlePrototype.scene is missing EventSystem.");
            }

            TMP_Text[] texts = scene.GetRootGameObjects().SelectMany(root => root.GetComponentsInChildren<TMP_Text>(true)).ToArray();
            if (texts.Any(text => text.font == null))
            {
                failures.Add("BattlePrototype.scene contains TMP text without a font.");
            }

            foreach (CardView cardView in scene.GetRootGameObjects().SelectMany(root => root.GetComponentsInChildren<CardView>(true)))
            {
                ValidateCardViewBindings(cardView, failures, $"BattlePrototype.scene/{cardView.name}");
            }
        }

        private static void ValidateIntroScene(List<string> failures)
        {
            var scene = EditorSceneManager.OpenScene("Assets/Scenes/Intro.scene", OpenSceneMode.Single);
            TMP_Text[] texts = scene.GetRootGameObjects().SelectMany(root => root.GetComponentsInChildren<TMP_Text>(true)).ToArray();
            if (texts.Any(text => text.font == null))
            {
                failures.Add("Intro.scene contains TMP text without a font.");
            }
        }

        private static void ValidateControllerBindings(BattlePrototypeController controller, List<string> failures)
        {
            SerializedObject serializedController = new SerializedObject(controller);
            string[] properties =
            {
                "cardViewPrefab",
                "canvas",
                "handContent",
                "reactionLeftView",
                "reactionRightView",
                "reactionLeftZone",
                "reactionRightZone",
                "inspectView",
                "enemyInfoText",
                "playerInfoText",
                "logText",
                "turnText",
                "reactionPreviewText",
                "reactButton",
                "clearReactionButton",
                "endTurnButton",
                "closeInspectButton",
                "inspectPanel"
            };

            foreach (string propertyName in properties)
            {
                SerializedProperty property = serializedController.FindProperty(propertyName);
                if (property == null || property.objectReferenceValue == null)
                {
                    failures.Add($"BattlePrototypeController is missing binding: {propertyName}");
                }
            }

            SerializedProperty dropZonesProperty = serializedController.FindProperty("dropZones");
            if (dropZonesProperty == null || dropZonesProperty.arraySize == 0)
            {
                failures.Add("BattlePrototypeController is missing dropZones.");
            }
        }

        private static void ValidateCardViewBindings(CardView cardView, List<string> failures, string context)
        {
            SerializedObject serializedCardView = new SerializedObject(cardView);
            string[] properties =
            {
                "canvasGroup",
                "layoutElement",
                "outline",
                "shadow",
                "chromeImage",
                "artFrameImage",
                "artImage",
                "infoBarImage",
                "costBubbleImage",
                "artRootRect",
                "infoBarRect",
                "titleText",
                "metaText",
                "rulesText",
                "costText",
                "slotHintText"
            };

            foreach (string propertyName in properties)
            {
                SerializedProperty property = serializedCardView.FindProperty(propertyName);
                if (property == null || property.objectReferenceValue == null)
                {
                    failures.Add($"{context} is missing binding: {propertyName}");
                }
            }
        }
    }
}
