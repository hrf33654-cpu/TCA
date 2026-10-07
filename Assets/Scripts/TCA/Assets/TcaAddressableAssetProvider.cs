using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

namespace TCA.Assets
{
    public sealed class TcaAddressableAssetProvider : ITcaAssetProvider
    {
        private readonly Dictionary<string, AsyncOperationHandle<Sprite>> spriteHandles = new Dictionary<string, AsyncOperationHandle<Sprite>>(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, Sprite> legacySprites = new Dictionary<string, Sprite>(StringComparer.OrdinalIgnoreCase);
        private bool disposed;

        public async Task<Sprite> LoadSpriteAsync(string address, CancellationToken cancellationToken = default)
        {
            if (disposed)
            {
                throw new ObjectDisposedException(nameof(TcaAddressableAssetProvider));
            }

            if (string.IsNullOrWhiteSpace(address))
            {
                throw new ArgumentException("Address cannot be empty.", nameof(address));
            }

            if (spriteHandles.TryGetValue(address, out AsyncOperationHandle<Sprite> cachedHandle))
            {
                return cachedHandle.Result;
            }

            if (legacySprites.TryGetValue(address, out Sprite cachedLegacySprite))
            {
                return cachedLegacySprite;
            }

            AsyncOperationHandle<Sprite> handle = default;
            try
            {
                handle = Addressables.LoadAssetAsync<Sprite>(address);
                spriteHandles[address] = handle;

                while (!handle.IsDone)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    await Task.Yield();
                }

                if (handle.Status != AsyncOperationStatus.Succeeded || handle.Result == null)
                {
                    throw new InvalidOperationException($"Addressables failed to load sprite: {address}");
                }

                return handle.Result;
            }
            catch (Exception exception) when (TryLoadLegacySprite(address, out Sprite legacySprite))
            {
                if (handle.IsValid())
                {
                    Addressables.Release(handle);
                }

                spriteHandles.Remove(address);
                legacySprites[address] = legacySprite;
                Debug.LogWarning($"Addressables fallback used for sprite: {address}\n{exception.Message}");
                return legacySprite;
            }
            catch
            {
                if (handle.IsValid())
                {
                    Addressables.Release(handle);
                }

                spriteHandles.Remove(address);
                throw;
            }
        }

        public async Task PreloadSpritesAsync(IEnumerable<string> addresses, CancellationToken cancellationToken = default)
        {
            if (addresses == null)
            {
                return;
            }

            string[] distinctAddresses = addresses
                .Where(address => !string.IsNullOrWhiteSpace(address))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();

            foreach (string address in distinctAddresses)
            {
                await LoadSpriteAsync(address, cancellationToken);
            }
        }

        public void Dispose()
        {
            if (disposed)
            {
                return;
            }

            disposed = true;

            foreach (KeyValuePair<string, AsyncOperationHandle<Sprite>> pair in spriteHandles)
            {
                Addressables.Release(pair.Value);
            }

            spriteHandles.Clear();
            legacySprites.Clear();
        }

        private static bool TryLoadLegacySprite(string address, out Sprite sprite)
        {
            sprite = null;
            if (!AllowDevelopmentFallback())
            {
                return false;
            }

            if (!TcaAssetKeys.TryGetLegacyResourcesPath(address, out string resourcesPath))
            {
                return false;
            }

            sprite = Resources.Load<Sprite>(resourcesPath);
            return sprite != null;
        }

        private static bool AllowDevelopmentFallback()
        {
#if UNITY_EDITOR
            return true;
#else
            return Debug.isDebugBuild;
#endif
        }
    }
}
