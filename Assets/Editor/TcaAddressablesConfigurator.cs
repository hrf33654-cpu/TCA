using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using TCA.Assets;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;
using UnityEditor.AddressableAssets.Settings.GroupSchemas;

namespace TCA.Editor
{
    public static class TcaAddressablesConfigurator
    {
        [MenuItem("TCA Tools/Sync Addressables")]
        public static void SyncAddressables()
        {
            SyncAll();
            AssetDatabase.SaveAssets();
            UnityEngine.Debug.Log("TCA Addressables sync complete.");
        }

        public static void RunBatchSync()
        {
            SyncAll();
            AssetDatabase.SaveAssets();
        }

        internal static void SyncAll()
        {
            AddressableAssetSettings settings = EnsureSettings();
            AddressableAssetGroup uiGroup = EnsureGroup(settings, "TCA UI");
            AddressableAssetGroup cardArtGroup = EnsureGroup(settings, "TCA Card Art");
            AddressableAssetGroup introGroup = EnsureGroup(settings, "TCA Intro");
            AddressableAssetGroup battleGroup = EnsureGroup(settings, "TCA Battle");

            string[] folders =
            {
                "Assets/Resources/UI",
                "Assets/Resources/CardArt",
                "Assets/Resources/Intro",
                "Assets/Resources/Battle"
            };

            SyncFolderSprites(settings, uiGroup, folders[0], BuildUiAddress, "tca-ui");
            SyncFolderSprites(settings, cardArtGroup, folders[1], BuildCardAddress, "tca-card-art");
            SyncFolderSprites(settings, introGroup, folders[2], BuildIntroAddress, "tca-intro");
            SyncFolderSprites(settings, battleGroup, folders[3], BuildBattleAddress, "tca-battle");

            var validGuids = new HashSet<string>(folders
                .Where(AssetDatabase.IsValidFolder)
                .SelectMany(folder => AssetDatabase.FindAssets("t:Sprite", new[] { folder })));

            RemoveOrphanEntries(validGuids, uiGroup, cardArtGroup, introGroup, battleGroup);
            EditorUtility.SetDirty(settings);
        }

        private static AddressableAssetSettings EnsureSettings()
        {
            return AddressableAssetSettingsDefaultObject.GetSettings(true);
        }

        private static AddressableAssetGroup EnsureGroup(AddressableAssetSettings settings, string groupName)
        {
            AddressableAssetGroup group = settings.FindGroup(groupName);
            if (group != null)
            {
                return group;
            }

            group = settings.CreateGroup(groupName, false, false, false, null, typeof(BundledAssetGroupSchema), typeof(ContentUpdateGroupSchema));
            BundledAssetGroupSchema bundledSchema = group.GetSchema<BundledAssetGroupSchema>();
            if (bundledSchema != null)
            {
                bundledSchema.BuildPath.SetVariableByName(settings, AddressableAssetSettings.kLocalBuildPath);
                bundledSchema.LoadPath.SetVariableByName(settings, AddressableAssetSettings.kLocalLoadPath);
            }

            return group;
        }

        private static void SyncFolderSprites(AddressableAssetSettings settings, AddressableAssetGroup group, string folderPath, Func<string, string> addressFactory, string label)
        {
            if (!AssetDatabase.IsValidFolder(folderPath))
            {
                return;
            }

            string[] spriteGuids = AssetDatabase.FindAssets("t:Sprite", new[] { folderPath });
            foreach (string guid in spriteGuids)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guid);
                string address = addressFactory(assetPath);
                AddressableAssetEntry entry = settings.CreateOrMoveEntry(guid, group);
                entry.address = address;
                entry.SetLabel(label, true, true);
                EditorUtility.SetDirty(entry.parentGroup);
            }
        }

        private static void RemoveOrphanEntries(ISet<string> validGuids, params AddressableAssetGroup[] groups)
        {
            foreach (AddressableAssetGroup group in groups.Where(candidate => candidate != null))
            {
                List<AddressableAssetEntry> entries = group.entries.ToList();
                foreach (AddressableAssetEntry entry in entries)
                {
                    if (!validGuids.Contains(entry.guid))
                    {
                        group.RemoveAssetEntry(entry);
                    }
                }
            }
        }

        private static string BuildUiAddress(string assetPath)
        {
            string fileName = Path.GetFileNameWithoutExtension(assetPath);
            switch (fileName)
            {
                case "frame_card":
                    return TcaAssetKeys.Ui.FrameCard;
                case "frame_art":
                    return TcaAssetKeys.Ui.FrameArt;
                case "frame_info":
                    return TcaAssetKeys.Ui.FrameInfo;
                case "frame_slot":
                    return TcaAssetKeys.Ui.FrameSlot;
                case "bubble_cost":
                    return TcaAssetKeys.Ui.BubbleCost;
                case "btn_react":
                    return TcaAssetKeys.Ui.ButtonReact;
                case "btn_clear":
                    return TcaAssetKeys.Ui.ButtonClear;
                case "btn_end_turn":
                    return TcaAssetKeys.Ui.ButtonEndTurn;
                case "btn_close":
                    return TcaAssetKeys.Ui.ButtonClose;
                case "panel_top_info":
                    return TcaAssetKeys.Ui.PanelTopInfo;
                case "panel_arena":
                    return TcaAssetKeys.Ui.PanelArena;
                case "panel_hand":
                    return TcaAssetKeys.Ui.PanelHand;
                case "panel_reaction":
                    return TcaAssetKeys.Ui.PanelReaction;
                case "panel_log":
                    return TcaAssetKeys.Ui.PanelLog;
                case "zone_enemy":
                    return TcaAssetKeys.Ui.ZoneEnemy;
                case "zone_player":
                    return TcaAssetKeys.Ui.ZonePlayer;
                case "desk_plate":
                    return TcaAssetKeys.Ui.DeskPlate;
                case "battle_backdrop":
                    return TcaAssetKeys.Ui.BattleBackdrop;
                default:
                    return $"ui/{fileName.Replace('_', '-')}";
            }
        }

        private static string BuildCardAddress(string assetPath)
        {
            return TcaAssetKeys.CardArt(Path.GetFileNameWithoutExtension(assetPath));
        }

        private static string BuildIntroAddress(string assetPath)
        {
            string fileName = Path.GetFileNameWithoutExtension(assetPath).ToLowerInvariant();
            return fileName == "welcome_intro" ? TcaAssetKeys.IntroWelcome : $"intro/{fileName}";
        }

        private static string BuildBattleAddress(string assetPath)
        {
            string fileName = Path.GetFileNameWithoutExtension(assetPath).ToLowerInvariant();
            return fileName == "battle_background" ? TcaAssetKeys.BattleBackdrop : $"battle/{fileName.Replace('_', '-')}";
        }
    }
}
