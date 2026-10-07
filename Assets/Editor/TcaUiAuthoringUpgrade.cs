using System.Linq;
using TCA.UI;
using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace TCA.Editor
{
    public static class TcaUiAuthoringUpgrade
    {
        private const string CardViewPrefabPath = "Assets/Resources/CardViewPrefab.prefab";
        private const string BattleScenePath = "Assets/Scenes/BattlePrototype.scene";
        private const string IntroScenePath = "Assets/Scenes/Intro.scene";
        private const string DefaultFontPath = "Assets/Resources/Fonts & Materials/TCA_CJK SDF.asset";

        [MenuItem("TCA Tools/Upgrade UI Authoring")]
        public static void UpgradeUiAuthoring()
        {
            TcaAddressablesConfigurator.SyncAll();
            UpgradeCardViewPrefab();
            UpgradeBattleScene();
            UpgradeIntroScene();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("TCA UI authoring upgrade complete.");
        }

        public static void RunBatchUpgrade()
        {
            UpgradeUiAuthoring();
        }

        private static void UpgradeCardViewPrefab()
        {
            GameObject prefabRoot = PrefabUtility.LoadPrefabContents(CardViewPrefabPath);
            try
            {
                CardView cardView = prefabRoot.GetComponent<CardView>();
                if (cardView == null)
                {
                    throw new MissingReferenceException("CardViewPrefab is missing CardView.");
                }

                Image chromeImage = prefabRoot.GetComponent<Image>();
                Image artFrameImage = prefabRoot.transform.Find("ArtRoot")?.GetComponent<Image>();
                Image artImage = prefabRoot.transform.Find("ArtRoot/Art")?.GetComponent<Image>();
                Image infoBarImage = prefabRoot.transform.Find("InfoBar")?.GetComponent<Image>();
                Image costBubbleImage = prefabRoot.transform.Find("CostBubble")?.GetComponent<Image>();
                TMP_FontAsset fontAsset = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(DefaultFontPath);

                chromeImage.sprite = LoadSprite("Assets/Resources/UI/frame_card.png");
                chromeImage.type = Image.Type.Sliced;
                artFrameImage.sprite = LoadSprite("Assets/Resources/UI/frame_art.png");
                artFrameImage.type = Image.Type.Sliced;
                infoBarImage.sprite = LoadSprite("Assets/Resources/UI/frame_info.png");
                infoBarImage.type = Image.Type.Sliced;
                costBubbleImage.sprite = LoadSprite("Assets/Resources/UI/bubble_cost.png");
                costBubbleImage.type = Image.Type.Sliced;
                artImage.type = Image.Type.Simple;
                artImage.preserveAspect = true;

                foreach (TextMeshProUGUI text in prefabRoot.GetComponentsInChildren<TextMeshProUGUI>(true))
                {
                    text.font = fontAsset;
                    text.fontSharedMaterial = fontAsset.material;
                }

                SerializedObject serializedCardView = new SerializedObject(cardView);
                serializedCardView.FindProperty("canvasGroup").objectReferenceValue = prefabRoot.GetComponent<CanvasGroup>();
                serializedCardView.FindProperty("layoutElement").objectReferenceValue = prefabRoot.GetComponent<LayoutElement>();
                serializedCardView.FindProperty("outline").objectReferenceValue = prefabRoot.GetComponent<Outline>();
                serializedCardView.FindProperty("shadow").objectReferenceValue = prefabRoot.GetComponent<Shadow>();
                serializedCardView.FindProperty("chromeImage").objectReferenceValue = chromeImage;
                serializedCardView.FindProperty("artFrameImage").objectReferenceValue = artFrameImage;
                serializedCardView.FindProperty("artImage").objectReferenceValue = artImage;
                serializedCardView.FindProperty("infoBarImage").objectReferenceValue = infoBarImage;
                serializedCardView.FindProperty("costBubbleImage").objectReferenceValue = costBubbleImage;
                serializedCardView.FindProperty("artRootRect").objectReferenceValue = prefabRoot.transform.Find("ArtRoot").GetComponent<RectTransform>();
                serializedCardView.FindProperty("infoBarRect").objectReferenceValue = prefabRoot.transform.Find("InfoBar").GetComponent<RectTransform>();
                serializedCardView.FindProperty("titleText").objectReferenceValue = prefabRoot.transform.Find("InfoBar/Title").GetComponent<TextMeshProUGUI>();
                serializedCardView.FindProperty("metaText").objectReferenceValue = prefabRoot.transform.Find("InfoBar/Meta").GetComponent<TextMeshProUGUI>();
                serializedCardView.FindProperty("rulesText").objectReferenceValue = prefabRoot.transform.Find("InfoBar/Rules").GetComponent<TextMeshProUGUI>();
                serializedCardView.FindProperty("costText").objectReferenceValue = prefabRoot.transform.Find("CostBubble/Cost").GetComponent<TextMeshProUGUI>();
                serializedCardView.FindProperty("slotHintText").objectReferenceValue = prefabRoot.transform.Find("SlotHint").GetComponent<TextMeshProUGUI>();
                serializedCardView.ApplyModifiedPropertiesWithoutUndo();

                PrefabUtility.SaveAsPrefabAsset(prefabRoot, CardViewPrefabPath);
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(prefabRoot);
            }
        }

        private static void UpgradeBattleScene()
        {
            Scene scene = EditorSceneManager.OpenScene(BattleScenePath, OpenSceneMode.Single);
            GameObject canvasObject = scene.GetRootGameObjects().First(root => root.name == "BattleCanvas");
            GameObject battleManagerObject = FindChild(canvasObject.transform, "BattleManager").gameObject;
            BattlePrototypeController controller = battleManagerObject.GetComponent<BattlePrototypeController>();
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(CardViewPrefabPath);
            TMP_FontAsset fontAsset = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(DefaultFontPath);

            GameObject reactionLeftHost = FindChild(canvasObject.transform, "ReactionLeft").gameObject;
            GameObject reactionRightHost = FindChild(canvasObject.transform, "ReactionRight").gameObject;
            GameObject inspectCardHost = FindChild(canvasObject.transform, "InspectCard").gameObject;

            CardView reactionLeftView = EnsureHostedCardView(reactionLeftHost.transform, prefab, "ReactionLeftCardView", new Vector2(8f, 8f));
            CardView reactionRightView = EnsureHostedCardView(reactionRightHost.transform, prefab, "ReactionRightCardView", new Vector2(8f, 8f));
            CardView inspectView = EnsureHostedCardView(inspectCardHost.transform, prefab, "InspectCardView", Vector2.zero);

            RemoveShellCardView(reactionLeftHost);
            RemoveShellCardView(reactionRightHost);
            RemoveShellCardView(inspectCardHost);

            ApplyFontToScene(scene, fontAsset);
            StyleBattleSceneImages(canvasObject.transform);
            EnsureEventSystem(scene);

            SerializedObject controllerObject = new SerializedObject(controller);
            controllerObject.FindProperty("cardViewPrefab").objectReferenceValue = prefab.GetComponent<CardView>();
            controllerObject.FindProperty("reactionLeftView").objectReferenceValue = reactionLeftView;
            controllerObject.FindProperty("reactionRightView").objectReferenceValue = reactionRightView;
            controllerObject.FindProperty("inspectView").objectReferenceValue = inspectView;
            controllerObject.ApplyModifiedPropertiesWithoutUndo();

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
        }

        private static void UpgradeIntroScene()
        {
            Scene scene = EditorSceneManager.OpenScene(IntroScenePath, OpenSceneMode.Single);
            TMP_FontAsset fontAsset = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(DefaultFontPath);
            ApplyFontToScene(scene, fontAsset);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
        }

        private static CardView EnsureHostedCardView(Transform host, GameObject prefab, string childName, Vector2 padding)
        {
            Transform existing = host.Find(childName);
            GameObject child;
            if (existing != null)
            {
                child = existing.gameObject;
            }
            else
            {
                child = (GameObject)PrefabUtility.InstantiatePrefab(prefab);
                child.transform.SetParent(host, false);
            }

            child.name = childName;
            RectTransform rect = child.transform as RectTransform;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(padding.x, padding.y);
            rect.offsetMax = new Vector2(-padding.x, -padding.y);
            rect.localScale = Vector3.one;
            return child.GetComponent<CardView>();
        }

        private static void RemoveShellCardView(GameObject host)
        {
            CardView shellCardView = host.GetComponent<CardView>();
            if (shellCardView != null)
            {
                Object.DestroyImmediate(shellCardView, true);
            }
        }

        private static void StyleBattleSceneImages(Transform canvasRoot)
        {
            SetImageSprite(canvasRoot, "TopInfoPanel", "Assets/Resources/UI/panel_top_info.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ArenaPanel", "Assets/Resources/UI/panel_arena.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "HandPanel", "Assets/Resources/UI/panel_hand.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ReactionPanel", "Assets/Resources/UI/panel_reaction.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "LogPanel", "Assets/Resources/UI/panel_log.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "PlayerDropZone", "Assets/Resources/UI/zone_player.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "EnemyDropZone", "Assets/Resources/UI/zone_enemy.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ReactionLeft", "Assets/Resources/UI/frame_slot.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ReactionRight", "Assets/Resources/UI/frame_slot.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ReactButton", "Assets/Resources/UI/btn_react.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "ClearButton", "Assets/Resources/UI/btn_clear.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "EndTurnBtn", "Assets/Resources/UI/btn_end_turn.png", Image.Type.Sliced);
            SetImageSprite(canvasRoot, "CloseBtn", "Assets/Resources/UI/btn_close.png", Image.Type.Sliced);
        }

        private static void SetImageSprite(Transform root, string objectName, string assetPath, Image.Type type)
        {
            Transform target = FindChild(root, objectName);
            if (target == null)
            {
                return;
            }

            Image image = target.GetComponent<Image>();
            if (image == null)
            {
                return;
            }

            image.sprite = LoadSprite(assetPath);
            image.type = type;
            image.preserveAspect = type == Image.Type.Simple;
        }

        private static void ApplyFontToScene(Scene scene, TMP_FontAsset fontAsset)
        {
            foreach (GameObject rootObject in scene.GetRootGameObjects())
            {
                foreach (TextMeshProUGUI text in rootObject.GetComponentsInChildren<TextMeshProUGUI>(true))
                {
                    text.font = fontAsset;
                    text.fontSharedMaterial = fontAsset.material;
                }
            }
        }

        private static void EnsureEventSystem(Scene scene)
        {
            bool hasEventSystem = scene.GetRootGameObjects().Any(root => root.GetComponentInChildren<EventSystem>(true) != null);
            if (hasEventSystem)
            {
                return;
            }

            GameObject eventSystem = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            SceneManager.MoveGameObjectToScene(eventSystem, scene);
        }

        private static Transform FindChild(Transform root, string name)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
            {
                if (child.name == name)
                {
                    return child;
                }
            }

            return null;
        }

        private static Sprite LoadSprite(string assetPath)
        {
            Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(assetPath);
            if (sprite == null)
            {
                throw new MissingReferenceException($"Missing sprite asset: {assetPath}");
            }

            return sprite;
        }
    }
}
